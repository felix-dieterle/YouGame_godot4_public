package com.yougame.savegamewidget;

import android.app.PendingIntent;
import android.appwidget.AppWidgetManager;
import android.appwidget.AppWidgetProvider;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.widget.RemoteViews;

import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Locale;

/**
 * SaveGameWidgetProvider - Android Widget displaying savegame metrics and metadata
 * 
 * This widget displays key information from the game's save file:
 * - Last save timestamp
 * - Current day count
 * - Player health
 * - Torch inventory count
 * - Player position
 * 
 * The data is stored in SharedPreferences by the SaveGameMetadataExporter
 * singleton in the Godot game.
 */
public class SaveGameWidgetProvider extends AppWidgetProvider {
    
    private static final String PREFS_NAME = "YouGameSaveData";
    private static final String ACTION_UPDATE = "com.yougame.savegamewidget.UPDATE_WIDGET";
    
    @Override
    public void onUpdate(Context context, AppWidgetManager appWidgetManager, int[] appWidgetIds) {
        // Update all instances of the widget
        for (int appWidgetId : appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId);
        }
    }
    
    @Override
    public void onReceive(Context context, Intent intent) {
        super.onReceive(context, intent);
        
        if (ACTION_UPDATE.equals(intent.getAction())) {
            // Manual update trigger from the game
            AppWidgetManager appWidgetManager = AppWidgetManager.getInstance(context);
            ComponentName thisWidget = new ComponentName(context, SaveGameWidgetProvider.class);
            int[] appWidgetIds = appWidgetManager.getAppWidgetIds(thisWidget);
            onUpdate(context, appWidgetManager, appWidgetIds);
        }
    }
    
    private static void updateAppWidget(Context context, AppWidgetManager appWidgetManager,
                                       int appWidgetId) {
        // Create RemoteViews object
        RemoteViews views = new RemoteViews(context.getPackageName(), R.layout.savegame_widget_layout);
        
        // Read save data from SharedPreferences
        SharedPreferences prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE);
        
        // Check if save data exists
        long timestamp = prefs.getLong("timestamp", 0);
        
        if (timestamp > 0) {
            // Format timestamp
            Date saveDate = new Date(timestamp * 1000); // Convert from Unix timestamp
            SimpleDateFormat sdf = new SimpleDateFormat("MMM dd, HH:mm", Locale.getDefault());
            String formattedDate = sdf.format(saveDate);
            views.setTextViewText(R.id.widget_save_time, "Last saved: " + formattedDate);
            
            // Day count
            int dayCount = prefs.getInt("day_count", 1);
            views.setTextViewText(R.id.widget_day_value, String.valueOf(dayCount));
            
            // Health
            float health = prefs.getFloat("current_health", 100.0f);
            views.setTextViewText(R.id.widget_health_value, String.format(Locale.US, "%.0f%%", health));
            
            // Torches
            int torches = prefs.getInt("torch_count", 0);
            views.setTextViewText(R.id.widget_torches_value, String.valueOf(torches));
            
            // Position
            float posX = prefs.getFloat("position_x", 0.0f);
            float posZ = prefs.getFloat("position_z", 0.0f);
            String position = String.format(Locale.US, "%.0f, %.0f", posX, posZ);
            views.setTextViewText(R.id.widget_position_value, position);
            
        } else {
            // No save data available
            views.setTextViewText(R.id.widget_save_time, context.getString(R.string.no_save_data));
            views.setTextViewText(R.id.widget_day_value, "--");
            views.setTextViewText(R.id.widget_health_value, "--");
            views.setTextViewText(R.id.widget_torches_value, "--");
            views.setTextViewText(R.id.widget_position_value, "--");
        }
        
        // Set up click handler to launch the game
        Intent launchIntent = context.getPackageManager().getLaunchIntentForPackage(context.getPackageName());
        if (launchIntent != null) {
            PendingIntent pendingIntent = PendingIntent.getActivity(context, 0, launchIntent, 
                PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);
            views.setOnClickPendingIntent(R.id.widget_title, pendingIntent);
        }
        
        // Update the widget
        appWidgetManager.updateAppWidget(appWidgetId, views);
    }
    
    /**
     * Trigger an update of all widget instances
     * This can be called from the Godot plugin
     */
    public static void requestWidgetUpdate(Context context) {
        Intent intent = new Intent(context, SaveGameWidgetProvider.class);
        intent.setAction(ACTION_UPDATE);
        context.sendBroadcast(intent);
    }
}
