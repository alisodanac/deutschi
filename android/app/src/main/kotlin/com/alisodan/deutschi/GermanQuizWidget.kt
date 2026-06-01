package com.alisodan.deutschi

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.BitmapFactory
import android.graphics.Color
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Interactive der/die/das quiz widget. Reads its state from the SharedPreferences
 * written by the Flutter [WidgetService]. All button taps go through
 * home_widget's background intent, which runs the Dart callback.
 */
class GermanQuizWidget : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.german_quiz_widget)

            val empty = widgetData.getString("empty", "true") == "true"
            val revealed = widgetData.getString("revealed", "false") == "true"
            val imagePath = widgetData.getString("image", "") ?: ""
            val word = widgetData.getString("word", "") ?: ""
            val feedback = widgetData.getString("feedback", "") ?: ""
            val feedbackColor = widgetData.getString("feedback_color", "#FFFFFF") ?: "#FFFFFF"

            // Photo
            val bitmap = if (imagePath.isNotEmpty()) BitmapFactory.decodeFile(imagePath) else null
            if (bitmap != null) {
                views.setImageViewBitmap(R.id.iv_photo, bitmap)
                views.setViewVisibility(R.id.iv_photo, View.VISIBLE)
            } else {
                views.setViewVisibility(R.id.iv_photo, View.GONE)
            }

            // Word label (revealed only)
            views.setTextViewText(R.id.tv_word, word)
            views.setViewVisibility(R.id.tv_word, if (word.isNotEmpty()) View.VISIBLE else View.GONE)

            // Feedback
            views.setTextViewText(R.id.tv_feedback, feedback)
            views.setViewVisibility(R.id.tv_feedback, if (feedback.isNotEmpty()) View.VISIBLE else View.GONE)
            try {
                views.setTextColor(R.id.tv_feedback, Color.parseColor(feedbackColor))
            } catch (_: IllegalArgumentException) {
            }

            // Buttons: article row before answering, Next after
            val showAnswerRow = !empty && !revealed
            views.setViewVisibility(R.id.row_articles, if (showAnswerRow) View.VISIBLE else View.GONE)
            views.setViewVisibility(R.id.btn_next, if (!empty && revealed) View.VISIBLE else View.GONE)

            if (showAnswerRow) {
                views.setOnClickPendingIntent(R.id.btn_der, answerIntent(context, "Der"))
                views.setOnClickPendingIntent(R.id.btn_die, answerIntent(context, "Die"))
                views.setOnClickPendingIntent(R.id.btn_das, answerIntent(context, "Das"))
            }
            views.setOnClickPendingIntent(
                R.id.btn_next,
                HomeWidgetBackgroundIntent.getBroadcast(context, Uri.parse("homeWidget://next")),
            )

            // Tapping the photo opens the app
            views.setOnClickPendingIntent(
                R.id.iv_photo,
                HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
            )

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    private fun answerIntent(context: Context, article: String) =
        HomeWidgetBackgroundIntent.getBroadcast(context, Uri.parse("homeWidget://answer?choice=$article"))
}
