package com.nousen.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetProvider

class NousenAppWidgetProvider : HomeWidgetProvider() {
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
            val statusBadge = widgetData.getString("widget_status_badge", "Standby")
            views.setTextViewText(R.id.widget_status_badge, statusBadge)

            if (mode == "active") {
                // Tampilkan Active View, sembunyikan Idle View
                views.setViewVisibility(R.id.widget_active_view, View.VISIBLE)
                views.setViewVisibility(R.id.widget_idle_view, View.GONE)

                val activeTitle = widgetData.getString("widget_active_title", "Jadwal Aktif")
                val activeTime = widgetData.getString("widget_active_time", "")
                val activeDone = widgetData.getBoolean("widget_active_done", false)
                val activeUri = widgetData.getString("widget_active_uri", "")

                views.setTextViewText(R.id.widget_active_title, activeTitle)
                views.setTextViewText(R.id.widget_active_time, activeTime)
                views.setImageViewResource(
                    R.id.widget_active_main_check,
                    if (activeDone) R.drawable.ic_widget_check_done else R.drawable.ic_widget_check_empty
                )

                if (!activeUri.isNullOrEmpty()) {
                    val togglePendingIntent = HomeWidgetBackgroundIntent.getBroadcast(
                        context,
                        Uri.parse(activeUri)
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
                        views.setImageViewResource(
                            subChecks[i],
                            if (subDone) R.drawable.ic_widget_check_done else R.drawable.ic_widget_check_empty
                        )

                        if (!subUri.isNullOrEmpty()) {
                            val subTogglePendingIntent = HomeWidgetBackgroundIntent.getBroadcast(
                                context,
                                Uri.parse(subUri)
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

                if (itemCount == 0) {
                    views.setViewVisibility(R.id.widget_idle_empty, View.VISIBLE)
                } else {
                    views.setViewVisibility(R.id.widget_idle_empty, View.GONE)
                }

                for (i in 0 until 4) {
                    if (i < itemCount) {
                        val title = widgetData.getString("widget_idle_item_${i}_title", "")
                        val time = widgetData.getString("widget_idle_item_${i}_time", "")
                        val isDone = widgetData.getBoolean("widget_idle_item_${i}_done", false)
                        val uri = widgetData.getString("widget_idle_item_${i}_uri", "")

                        views.setViewVisibility(itemContainers[i], View.VISIBLE)
                        views.setTextViewText(itemTitles[i], title)
                        views.setTextViewText(itemTimes[i], time)
                        views.setImageViewResource(
                            itemChecks[i],
                            if (isDone) R.drawable.ic_widget_check_done else R.drawable.ic_widget_check_empty
                        )

                        if (!uri.isNullOrEmpty()) {
                            val togglePendingIntent = HomeWidgetBackgroundIntent.getBroadcast(
                                context,
                                Uri.parse(uri)
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
}
