package com.yougame.widget;

import android.app.PendingIntent;
import android.appwidget.AppWidgetManager;
import android.appwidget.AppWidgetProvider;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.widget.RemoteViews;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Locale;

/**
 * SaveGameWidgetProvider - Android widget that displays YouGame save data
 * 
 * This widget reads save game data from a shared file written by the main game APK.
 * The data is stored in a world-readable location that both APKs can access.
 */
public class SaveGameWidgetProvider extends AppWidgetProvider {
    
    // Shared file path - accessible by both main game and widget
    // Using external storage directory which is accessible across apps with same signature
    private static final String WIDGET_DATA_DIR = "YouGame";
    private static final String WIDGET_DATA_FILE = "widget_data.txt";
    
    @Override
    public void onUpdate(Context context, AppWidgetManager appWidgetManager, int[] appWidgetIds) {
        // Update all active widgets
        for (int appWidgetId : appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId);
        }
    }
    
    @Override
    public void onEnabled(Context context) {
        // Called when the first widget is created
    }
    
    @Override
    public void onDisabled(Context context) {
        // Called when the last widget is removed
    }
    
    /**
     * Update a single widget instance
     */
    static void updateAppWidget(Context context, AppWidgetManager appWidgetManager, int appWidgetId) {
        RemoteViews views = new RemoteViews(context.getPackageName(), R.layout.widget_layout);
        
        // Read save data from shared file
        SaveData data = readSaveData(context);
        
        if (data != null && data.timestamp > 0) {
            // Format timestamp
            SimpleDateFormat sdf = new SimpleDateFormat("MMM dd, HH:mm", Locale.getDefault());
            String formattedTime = sdf.format(new Date(data.timestamp));
            views.setTextViewText(R.id.widget_timestamp, 
                context.getString(R.string.last_saved, formattedTime));
            
            // Update game stats
            views.setTextViewText(R.id.widget_day, "Day: " + data.dayCount);
            views.setTextViewText(R.id.widget_health, 
                String.format(Locale.getDefault(), "Health: %.0f%%", data.currentHealth));
            views.setTextViewText(R.id.widget_torches, "Torches: " + data.torchCount);
            views.setTextViewText(R.id.widget_position, 
                String.format(Locale.getDefault(), "Pos: %.0f, %.0f", data.positionX, data.positionZ));
        } else {
            // No save data available
            views.setTextViewText(R.id.widget_timestamp, context.getString(R.string.no_save_data));
            views.setTextViewText(R.id.widget_day, context.getString(R.string.day_label));
            views.setTextViewText(R.id.widget_health, context.getString(R.string.health_label));
            views.setTextViewText(R.id.widget_torches, context.getString(R.string.torches_label));
            views.setTextViewText(R.id.widget_position, context.getString(R.string.position_label));
        }
        
        // Update the widget
        appWidgetManager.updateAppWidget(appWidgetId, views);
    }
    
    /**
     * Read save data from shared file
     */
    private static SaveData readSaveData(Context context) {
        BufferedReader reader = null;
        try {
            // The main game (com.yougame.godot4) writes to its external files directory
            // Path: /storage/emulated/0/Android/data/com.yougame.godot4/files/widget_data.txt
            File gameDataDir = new File("/storage/emulated/0/Android/data/com.yougame.godot4/files");
            File dataFile = new File(gameDataDir, WIDGET_DATA_FILE);
            
            if (!dataFile.exists() || !dataFile.canRead()) {
                return null;
            }
            
            reader = new BufferedReader(new FileReader(dataFile));
            SaveData data = new SaveData();
            
            String line;
            while ((line = reader.readLine()) != null) {
                String[] parts = line.split("=", 2);
                if (parts.length == 2) {
                    String key = parts[0].trim();
                    String value = parts[1].trim();
                    
                    switch (key) {
                        case "timestamp":
                            data.timestamp = Long.parseLong(value);
                            break;
                        case "day_count":
                            data.dayCount = Integer.parseInt(value);
                            break;
                        case "current_health":
                            data.currentHealth = Float.parseFloat(value);
                            break;
                        case "torch_count":
                            data.torchCount = Integer.parseInt(value);
                            break;
                        case "position_x":
                            data.positionX = Float.parseFloat(value);
                            break;
                        case "position_z":
                            data.positionZ = Float.parseFloat(value);
                            break;
                    }
                }
            }
            
            return data;
        } catch (Exception e) {
            e.printStackTrace();
            return null;
        } finally {
            // Ensure reader is closed even if exception occurs
            if (reader != null) {
                try {
                    reader.close();
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }
        }
    }
    
    /**
     * Request widget update from external source (e.g., main game)
     */
    public static void requestWidgetUpdate(Context context) {
        Intent intent = new Intent(context, SaveGameWidgetProvider.class);
        intent.setAction(AppWidgetManager.ACTION_APPWIDGET_UPDATE);
        
        AppWidgetManager appWidgetManager = AppWidgetManager.getInstance(context);
        int[] ids = appWidgetManager.getAppWidgetIds(
            new ComponentName(context, SaveGameWidgetProvider.class));
        intent.putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids);
        
        context.sendBroadcast(intent);
    }
    
    /**
     * Save data container
     */
    private static class SaveData {
        long timestamp = 0;
        int dayCount = 0;
        float currentHealth = 0.0f;
        int torchCount = 0;
        float positionX = 0.0f;
        float positionZ = 0.0f;
    }
}
