package com.example.moneymanager

import android.app.Notification
import android.content.Context
import android.os.Handler
import android.os.Looper
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import okhttp3.*
import org.json.JSONArray
import org.json.JSONObject
import java.io.IOException
import java.time.ZoneId
import java.time.ZonedDateTime
import java.time.format.DateTimeFormatter
import java.util.*
import kotlin.math.abs
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.RequestBody.Companion.toRequestBody

class MyNotificationListener : NotificationListenerService() {

    companion object {
        private const val PREFS_NAME = "moneymanager_prefs"
        private const val KEY_DEVICE_UUID = "device_uuid"
    }

    private val deviceUuid: String by lazy {
        val prefs = applicationContext
            .getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        var id = prefs.getString(KEY_DEVICE_UUID, null)
        if (id.isNullOrBlank()) {
            id = UUID.randomUUID().toString()
            prefs.edit().putString(KEY_DEVICE_UUID, id).apply()
        }
        id
    }

    private val client = OkHttpClient()
    private val openAiKey = "gpt api key" // gpt api key
//    private val serverUrl = "https://webhook.site/de0cdb7a-2e11-426a-8a88-5219a3d7e20a"
    private val serverUrl = "https://8257c5eb-a596-4cff-830a-9f9d274ae206.mock.pstmn.io/category"
    private val jsonMediaType = "application/json; charset=utf-8".toMediaType()

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        val text = sbn.notification.extras
            .getCharSequence(Notification.EXTRA_TEXT)
            ?.toString()?.trim() ?: return

        // 금액 포함 알림만
        if (!Regex("""\d{1,3}(,\d{3})*원""").containsMatchIn(text)) return

        // 서울 시간
        val nowSeoul = ZonedDateTime.now(ZoneId.of("Asia/Seoul"))
        val dateFmt = DateTimeFormatter.ofPattern("yyyy-MM-dd", Locale.KOREA)
        val timeFmt = DateTimeFormatter.ofPattern("HH:mm", Locale.KOREA)
        val localDate = nowSeoul.format(dateFmt)
        val localTime = nowSeoul.format(timeFmt)

        // GPT 요청 준비 (생략…)
        val systemPrompt = """
            You are a payment-notification parser.
            Given raw notification text, return EXACTLY a JSON object with keys:
            date (YYYY-MM-DD), time (HH:MM), amount (float), description (string), type (string).
            If the type is "지출", amount should be negative. Do NOT include extra keys.
        """.trimIndent()
        val userPrompt = JSONObject().put("notification", text).toString()
        val messages = JSONArray().apply {
            put(JSONObject().put("role","system").put("content", systemPrompt))
            put(JSONObject().put("role","user").put("content", userPrompt))
        }
        val gptPayload = JSONObject().apply {
            put("model","gpt-3.5-turbo")
            put("messages", messages)
            put("temperature", 0.0)
        }.toString()

        client.newCall(
            Request.Builder()
                .url("https://api.openai.com/v1/chat/completions")
                .header("Authorization","Bearer $openAiKey")
                .post(gptPayload.toRequestBody(jsonMediaType))
                .build()
        ).enqueue(object: Callback {
            override fun onFailure(call: Call, e: IOException) {
                Log.e("PaymentListener","GPT 호출 실패", e)
            }
            override fun onResponse(call: Call, response: Response) {
                response.use {
                    if (!it.isSuccessful) {
                        Log.e("PaymentListener","GPT 에러 코드: ${it.code}")
                        return
                    }
                    try {
                        val env = JSONObject(it.body?.string().orEmpty())
                        val parsed = env
                            .getJSONArray("choices")
                            .getJSONObject(0)
                            .getJSONObject("message")
                            .getString("content")
                            .let { JSONObject(it.trim()) }

                        // GPT 결과
                        val amount   = parsed.optDouble("amount", 0.0)
                        val desc     = parsed.optString("description","")
                        val type     = parsed.optString("type","지출")

                        // 서버로 보낼 JSON (category 제외)
                        val serverJson = JSONObject().apply {
                            put("uuid", deviceUuid)
                            put("date", localDate)
                            put("time", localTime)
                            put("amount", abs(amount))
                            put("description", desc)
                        }.toString()

                        // 서버 호출
                        postToServer(serverJson, localDate, localTime, amount, desc, type)
                    } catch(e: Exception) {
                        Log.e("PaymentListener","GPT 파싱 실패", e)
                    }
                }
            }
        })
    }

    private fun postToServer(
        payload: String,
        date: String,
        time: String,
        amount: Double,
        desc: String,
        type: String
    ) {
        client.newCall(
            Request.Builder()
                .url(serverUrl)
                .header("Content-Type","application/json")
                .post(payload.toRequestBody(jsonMediaType))
                .build()
        ).enqueue(object: Callback {
            override fun onFailure(call: Call, e: IOException) {
                Log.e("PaymentListener","서버 전송 실패", e)
            }
            override fun onResponse(call: Call, response: Response) {
                response.use {
                    Log.d("PaymentListener","서버 응답 코드: ${it.code}")
                    try {
                        // 서버 응답에서 category 파싱
                        val resp = JSONObject(it.body?.string().orEmpty())
                        val category = resp.optString("category","")

                        // Flutter 로 보낼 최종 JSON
                        val flutterJson = JSONObject().apply {
                            put("date", date)
                            put("time", time)
                            put("amount", amount)
                            put("description", desc)
                            put("type", type)
                            put("category", category)
                        }.toString()

                        // 한 번만 전송
                        Handler(Looper.getMainLooper()).post {
                            MainActivity.eventSink?.let { sink ->
                                Log.d("PaymentListener","▶ Sending to Flutter: $flutterJson")
                                sink.success(flutterJson)
                            }
                        }
                    } catch(e: Exception) {
                        Log.e("PaymentListener","서버 응답 파싱 실패", e)
                    }
                }
            }
        })
    }
}
