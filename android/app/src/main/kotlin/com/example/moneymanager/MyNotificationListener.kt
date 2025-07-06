package com.example.moneymanager

import android.app.Notification
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import okhttp3.Call
import okhttp3.Callback
import okhttp3.Response
import java.io.IOException

class MyNotificationListener : NotificationListenerService() {

    private val client = OkHttpClient()

    override fun onCreate() {
        super.onCreate()
        Log.d("🔔Notification", "✅ MyNotificationListener 서비스 시작됨")
    }

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        // ✅ 그룹 요약 알림은 무시
        if (sbn.isGroup && sbn.notification.flags and Notification.FLAG_GROUP_SUMMARY != 0) {
            Log.d("Notification", "요약 알림 무시됨 (그룹 summary)")
            return
        }

        val extras = sbn.notification.extras

        val title = extras.getCharSequence("android.title")?.toString()?.trim() ?: "제목 없음"
        val text = extras.getCharSequence("android.text")?.toString()?.trim() ?: "내용 없음"
        val bigText = extras.getCharSequence("android.bigText")?.toString()?.trim()
        val subText = extras.getCharSequence("android.subText")?.toString()?.trim()
        val packageName = sbn.packageName

        // ✅ 디버그 로그 출력
        Log.d("🔔Notification", "앱: $packageName")
        Log.d("🔔Notification", "제목: $title")
        Log.d("🔔Notification", "내용: $text")
        Log.d("🔔Notification", "bigText: $bigText")
        Log.d("🔔Notification", "subText: $subText")

        // ✅ 조건 추가: 실제 알림일 경우만 전송 (제목 + 내용 필수)
        if (title.isBlank() && text.isBlank()) {
            Log.d("Notification", "제목과 내용이 모두 비어 있어 전송하지 않음")
            return
        }

        // ✅ 전송할 JSON 데이터 구성
        val json = """
            {
              "package": "$packageName",
              "title": "$title",
              "text": "$text"
            }
        """.trimIndent()

        val mediaType = "application/json; charset=utf-8".toMediaType()
        val requestBody = json.toRequestBody(mediaType)

        val request = Request.Builder()
            .url("https://webhook.site/94144b96-26e1-4022-9cda-a212f1b9f7d3")
            .post(requestBody)
            .build()

        client.newCall(request).enqueue(object : Callback {
            override fun onFailure(call: Call, e: IOException) {
                Log.e("HTTP", "전송 실패: ${e.message}")
            }

            override fun onResponse(call: Call, response: Response) {
                val code = response.code
                val body = response.body?.string()
                Log.d("HTTP", "응답 코드: $code, 본문: $body")
            }
        })
    }
}
