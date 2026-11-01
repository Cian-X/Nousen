package com.nousen.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.os.Build
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundReceiver
import es.antonborri.home_widget.HomeWidgetProvider

class NousenAppWidgetProvider : HomeWidgetProvider() {

    companion object {
        private const val BACKGROUND_ACTION = "es.antonborri.home_widget.action.BACKGROUND"

        /**
         * Buat PendingIntent dengan requestCode unik.
         * Library home_widget selalu pakai requestCode=0 + FLAG_UPDATE_CURRENT,
         * sehingga semua PendingIntent saling timpa. Solusi: buat sendiri
         * dengan requestCode berbeda per checkbox.
         */
        fun getUniqueBroadcast(context: Context, uri: Uri, requestCode: Int): PendingIntent {
            val intent = Intent(context, HomeWidgetBackgroundReceiver::class.java).apply {
                data = uri
                action = BACKGROUND_ACTION
            }
            var flags = PendingIntent.FLAG_UPDATE_CURRENT
            if (Build.VERSION.SDK_INT >= 23) {
                flags = flags or PendingIntent.FLAG_IMMUTABLE
            }
            return PendingIntent.getBroadcast(context, requestCode, intent, flags)
        }
    }
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.nousen_widget)

            // Intent untuk buka aplikasi saat tap judul / area non-checkbox
            val openAppIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val openAppPendingIntent = PendingIntent.getActivity(
                context,
                0,
                openAppIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_app_label, openAppPendingIntent)

            val mode = widgetData.getString("widget_mode", "idle")
            val headerInfo = widgetData.getString("widget_header_info", "")
            views.setTextViewText(R.id.widget_header_info, headerInfo)

            if (mode == "active") {
                // Tampilkan Active View, sembunyikan Idle View
                views.setViewVisibility(R.id.widget_active_view, View.VISIBLE)
                views.setViewVisibility(R.id.widget_idle_view, View.GONE)

                val activeTitle = widgetData.getString("widget_active_title", "Jadwal Aktif")
                val activeSubtitle = widgetData.getString("widget_active_subtitle", "")
                val activeTime = widgetData.getString("widget_active_time", "")
                val activeDone = widgetData.getBoolean("widget_active_done", false)
                val activeUri = widgetData.getString("widget_active_uri", "")

                views.setTextViewText(R.id.widget_active_title, activeTitle)
                views.setTextViewText(R.id.widget_active_subtitle, activeSubtitle)
                views.setTextViewText(R.id.widget_active_time, activeTime)
                views.setImageViewResource(
                    R.id.widget_active_main_check,
                    if (activeDone) R.drawable.ic_widget_check_done else R.drawable.ic_widget_check_empty
                )

                if (!activeUri.isNullOrEmpty()) {
                    val togglePendingIntent = getUniqueBroadcast(
                        context,
                        Uri.parse(activeUri),
                        1000 // requestCode unik: active main
                    )
                    views.setOnClickPendingIntent(R.id.widget_active_main_check, togglePendingIntent)
                }
                views.setOnClickPendingIntent(R.id.widget_active_title, openAppPendingIntent)

                // Subtasks (hingga 3)
                val subCount = widgetData.getInt("widget_active_sub_count", 0)
                val subContainers = listOf(
                    R.id.widget_active_sub_1,
                    R.id.widget_active_sub_2,
                    R.id.widget_active_sub_3
                )
                val subChecks = listOf(
                    R.id.widget_active_sub_check_1,
                    R.id.widget_active_sub_check_2,
                    R.id.widget_active_sub_check_3
                )
                val subTitles = listOf(
                    R.id.widget_active_sub_title_1,
                    R.id.widget_active_sub_title_2,
                    R.id.widget_active_sub_title_3
                )

                for (i in 0 until 3) {
                    if (i < subCount) {
                        val subTitle = widgetData.getString("widget_active_sub_${i}_title", "")
                        val subDone = widgetData.getBoolean("widget_active_sub_${i}_done", false)
                        val subUri = widgetData.getString("widget_active_sub_${i}_uri", "")

                        views.setViewVisibility(subContainers[i], View.VISIBLE)
                        views.setTextViewText(subTitles[i], subTitle)
                        // Sub checkbox selalu indikator amber tanpa centang.
                        // Status selesai tetap tersimpan dan sinkron, hanya tidak
                        // divisualkan sebagai centang pada widget.
                        views.setImageViewResource(
                            subChecks[i],
                            R.drawable.ic_widget_check_empty
                        )

                        if (!subUri.isNullOrEmpty()) {
                            val subTogglePendingIntent = getUniqueBroadcast(
                                context,
                                Uri.parse(subUri),
                                1001 + i // requestCode unik: active sub 0/1/2
                            )
                            views.setOnClickPendingIntent(subChecks[i], subTogglePendingIntent)
                        }
                    } else {
                        views.setViewVisibility(subContainers[i], View.GONE)
                    }
                }
            } else {
                // Tampilkan Idle View, sembunyikan Active View
                views.setViewVisibility(R.id.widget_active_view, View.GONE)
                views.setViewVisibility(R.id.widget_idle_view, View.VISIBLE)

                val itemCount = widgetData.getInt("widget_idle_item_count", 0)

                val itemContainers = listOf(
                    R.id.widget_idle_item_1,
                    R.id.widget_idle_item_2,
                    R.id.widget_idle_item_3,
                    R.id.widget_idle_item_4
                )
                val itemChecks = listOf(
                    R.id.widget_idle_check_1,
                    R.id.widget_idle_check_2,
                    R.id.widget_idle_check_3,
                    R.id.widget_idle_check_4
                )
                val itemTitles = listOf(
                    R.id.widget_idle_title_1,
                    R.id.widget_idle_title_2,
                    R.id.widget_idle_title_3,
                    R.id.widget_idle_title_4
                )
                val itemTimes = listOf(
                    R.id.widget_idle_time_1,
                    R.id.widget_idle_time_2,
                    R.id.widget_idle_time_3,
                    R.id.widget_idle_time_4
                )

                val itemSubtitles = listOf(
                    R.id.widget_idle_subtitle_1,
                    R.id.widget_idle_subtitle_2,
                    R.id.widget_idle_subtitle_3,
                    R.id.widget_idle_subtitle_4
                )

                if (itemCount == 0) {
                    views.setViewVisibility(R.id.widget_idle_empty, View.VISIBLE)
                    views.setViewVisibility(R.id.widget_idle_agenda_header, View.GONE)
                    for (hdr in listOf(R.id.widget_idle_activity_header_0, R.id.widget_idle_activity_header_1, R.id.widget_idle_activity_header_2, R.id.widget_idle_activity_header_3)) {
                        views.setViewVisibility(hdr, View.GONE)
                    }
                } else {
                    views.setViewVisibility(R.id.widget_idle_empty, View.GONE)

                    // Section headers
                    val agendaCount = widgetData.getInt("widget_idle_agenda_count", 0)
                    val activityCount = widgetData.getInt("widget_idle_activity_count", 0)

                    if (agendaCount > 0) {
                        views.setViewVisibility(R.id.widget_idle_agenda_header, View.VISIBLE)
                        views.setTextViewText(R.id.widget_idle_agenda_header, "Agenda ($agendaCount)")
                    } else {
                        views.setViewVisibility(R.id.widget_idle_agenda_header, View.GONE)
                    }

                    // Find the first activity slot to place the activity header
                    val activityHeaders = listOf(R.id.widget_idle_activity_header_0, R.id.widget_idle_activity_header_1, R.id.widget_idle_activity_header_2, R.id.widget_idle_activity_header_3)
                    // Hide all activity headers first
                    for (hdr in activityHeaders) {
                        views.setViewVisibility(hdr, View.GONE)
                    }
                    // Show the one before the first activity item
                    if (activityCount > 0) {
                        for (i in 0 until itemCount) {
                            val itemType = widgetData.getString("widget_idle_item_${i}_type", "")
                            if (itemType == "activity") {
                                views.setViewVisibility(activityHeaders[i], View.VISIBLE)
                                views.setTextViewText(activityHeaders[i], "Aktivitas Harian ($activityCount)")
                                break
                            }
                        }
                    }
                }

                for (i in 0 until 4) {
                    if (i < itemCount) {
                        val title = widgetData.getString("widget_idle_item_${i}_title", "")
                        val time = widgetData.getString("widget_idle_item_${i}_time", "")
                        val subtitle = widgetData.getString("widget_idle_item_${i}_subtitle", "")
                        val isDone = widgetData.getBoolean("widget_idle_item_${i}_done", false)
                        val uri = widgetData.getString("widget_idle_item_${i}_uri", "")

                        views.setViewVisibility(itemContainers[i], View.VISIBLE)
                        views.setTextViewText(itemTitles[i], title)
                        views.setTextViewText(itemTimes[i], time)
                        views.setTextViewText(itemSubtitles[i], subtitle)
                        views.setImageViewResource(
                            itemChecks[i],
                            if (isDone) R.drawable.ic_widget_check_done else R.drawable.ic_widget_check_empty
                        )

                        if (!uri.isNullOrEmpty()) {
                            val togglePendingIntent = getUniqueBroadcast(
                                context,
                                Uri.parse(uri),
                                2000 + i // requestCode unik: idle item 0/1/2/3
                            )
                            views.setOnClickPendingIntent(itemChecks[i], togglePendingIntent)
                        }
                        views.setOnClickPendingIntent(itemTitles[i], openAppPendingIntent)
                    } else {
                        views.setViewVisibility(itemContainers[i], View.GONE)
                    }
                }
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        val action = intent.action
        if (action == Intent.ACTION_DATE_CHANGED ||
            action == Intent.ACTION_TIMEZONE_CHANGED ||
            action == Intent.ACTION_TIME_CHANGED ||
            action == Intent.ACTION_BOOT_COMPLETED ||
            action == "android.intent.action.TIME_SET"
        ) {
            try {
                val refreshIntent = getUniqueBroadcast(
                    context,
                    Uri.parse("nousen://widget_action?action=refresh"),
                    9999 // requestCode unik: midnight refresh
                )
                refreshIntent.send()
            } catch (_: Exception) {
            }
        }
    }
}
