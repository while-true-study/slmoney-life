package com.example.moneymanager

import android.app.Notification
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import okhttp3.Call
import okhttp3.Callback
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import okhttp3.Response
import java.io.IOException
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class MyNotificationListener : NotificationListenerService() {

    private val client = OkHttpClient()

    // [Web]발신 [서비스명] … 금액원
    private val bracketRegex = Regex(
        // [Web]발신 또는 [Web발신] → \[\s*Web\s*]\s*(?:발신)?
        // 그 뒤 [서비스명] → \[\s*([^\]\r\n]+?)\]
        // 그리고 임의 텍스트, 마지막에 금액원 캡처
        """\[\s*Web\s*]\s*(?:발신)?\s*\[\s*([^\]\r\n]+?)\s*].*?(\d{1,3}(?:,\d{3})*)원""",
        setOf(RegexOption.IGNORE_CASE, RegexOption.DOT_MATCHES_ALL)
    )

    // “지에스25 … 잔액 1,000원” 패턴 (내역 앞에서 잔액 키워드 전까지)
    private val balanceRegex = Regex(
        """([^|\r\n]+?)\s*잔액\s*(\d{1,3}(?:,\d{3})*)원""",
        setOf(RegexOption.IGNORE_CASE)
    )

    // “결제 일시 … / 결제 금액 … / 상품명 …” 멀티라인 패턴
    private val multiLineRegex = Regex(
        """결제\s*일시\s*([0-9]{4}[/-][0-9]{2}[/-]?[0-9]{2})\s*([0-9]{2}:[0-9]{2})[\s\S]*?""" +
                """결제\s*금액\s*(\d{1,3}(?:,\d{3})*)원[\s\S]*?상품명\s*([^\r\n]+)""",
        setOf(RegexOption.IGNORE_CASE)
    )

    // 날짜/시간 포함 일반 결제 패턴
    private val fullRegex = Regex(
        """(\d{4}[/-]\d{2}[/-]\d{2})\s*(\d{2}:\d{2})?.*?""" +
                """(\d{1,3}(?:,\d{3})*)원\s*결[제재]\w*(?:\s*([^|\r\n]+))?""",
        setOf(RegexOption.IGNORE_CASE, RegexOption.DOT_MATCHES_ALL)
    )

    // “금액원 결제 | 내역” 간단 패턴, 내역에서 ' 잔액' 뒤는 잘라냄
    private val simpleRegex = Regex(
        // (\d원) → 금액
        // \s*([^|\r\n]+?)\s*결제\w* → 금액 다음에 내역(‘원스토어 주식회사’)이 나오고, 그 뒤 ‘결제…’
        """(\d{1,3}(?:,\d{3})*)원\s*([^|\r\n]+?)\s*결제\w*""",
        setOf(RegexOption.IGNORE_CASE)
    )

    override fun onCreate() {
        super.onCreate()
        Log.d("PaymentListener", "서비스 시작")
    }

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        val text = sbn.notification.extras
            .getCharSequence(Notification.EXTRA_TEXT)
            ?.toString()
            ?.trim()
            ?: return

        Log.d("PaymentListener", "원본 알림 → $text")

        // 1) [Web]발신 [...] 패턴
        bracketRegex.find(text)?.let { m ->
            val desc   = m.groupValues[1].trim()
            val amount = m.groupValues[2]
            dispatchCurrentDate(amount, desc)
            return
        }

        // 2) 잔액 패턴
        balanceRegex.find(text)?.let { m ->
            val desc   = m.groupValues[1].trim()
            val amount = m.groupValues[2]
            dispatchCurrentDate(amount, desc)
            return
        }

        // 3) 멀티라인 패턴
        multiLineRegex.find(text)?.let { m ->
            val datePart = m.groupValues[1].replace('/', '-')
            val timePart = m.groupValues[2]
            val amount   = m.groupValues[3]
            val desc     = m.groupValues[4].trim()
            dispatchParsedDateTime("$datePart $timePart", amount, desc)
            return
        }

        // 4) 날짜/시간 포함 일반 패턴
        fullRegex.find(text)?.let { m ->
            val g        = m.groupValues
            val datePart = g[1].replace('/', '-')
            val timePart = g[2].ifBlank { "" }
            val dt       = if (timePart.isNotEmpty()) "$datePart $timePart" else datePart
            val amount   = g[3]
            val desc     = g.getOrNull(4).orEmpty().trim()
            dispatchParsedDateTime(dt, amount, desc)
            return
        }

        // 5) 간단 패턴
        simpleRegex.find(text)?.let { m ->
            val amount = m.groupValues[1]
            val desc   = m.groupValues[2].trim()
            dispatchCurrentDate(amount, desc)
            return
        }

        Log.d("PaymentListener", "파싱 불가, 무시 → $text")
    }

    private fun dispatchCurrentDate(amount: String, desc: String) {
        val now = SimpleDateFormat("yyyy-MM-dd HH:mm", Locale.getDefault())
            .format(Date())
        val (date, time) = now.split(" ")
        logAndPost(date, time, amount, desc)
    }

    private fun dispatchParsedDateTime(dateTime: String, amount: String, desc: String) {
        val (date, time) = dateTime.split(" ")
        logAndPost(date, time, amount, desc)
    }

    private fun logAndPost(date: String, time: String, amount: String, desc: String) {
        val message = """
            날짜: $date
            시간: $time
            금액: $amount
            내역: $desc
        """.trimIndent()
        Log.d("PaymentListener", "Formatted →\n$message")

        val json = """
            {
              "date":"$date",
              "time":"$time",
              "amount":${amount.replace(",", "")},
              "description":"$desc"
            }
        """.trimIndent()

        val body = json.toRequestBody("application/json; charset=utf-8".toMediaType())
        val request = Request.Builder()
            .url("https://webhook.site/7e4de40a-135d-4b45-9d60-9bddac6f81e6")
            .post(body)
            .build()

        client.newCall(request).enqueue(object : Callback {
            override fun onFailure(call: Call, e: IOException) {
                Log.e("PaymentListener", "전송 실패", e)
            }
            override fun onResponse(call: Call, response: Response) {
                Log.d("PaymentListener", "전송 완료: ${response.code}")
            }
        })
    }
}
