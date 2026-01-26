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
        WidgetErrorLogger.logInfo(context, "Widget enabled - first instance created");
        WidgetErrorLogger.logInfo(context, "Error log location: " + 
            WidgetErrorLogger.getLogFilePath(context));
    }
    
    @Override
    public void onDisabled(Context context) {
        // Called when the last widget is removed
        WidgetErrorLogger.logInfo(context, "Widget disabled - last instance removed");
    }
    
    /**
     * Update a single widget instance
     */
    static void updateAppWidget(Context context, AppWidgetManager appWidgetManager, int appWidgetId) {
        RemoteViews views = new RemoteViews(context.getPackageName(), R.layout.widget_layout);
        
        // Log widget update attempt
        WidgetErrorLogger.logInfo(context, "Widget update started");
        
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
            
            // Update log stats
            views.setTextViewText(R.id.widget_error_count, "Errors: " + data.errorCount);
            views.setTextViewText(R.id.widget_total_logs, "Logs: " + data.totalLogCount);
            
            // Update last error message
            if (data.errorCount > 0 && data.lastError != null && !data.lastError.isEmpty()) {
                views.setTextViewText(R.id.widget_last_error, data.lastError);
            } else {
                views.setTextViewText(R.id.widget_last_error, context.getString(R.string.no_errors));
            }
            
            // Clear any widget initialization errors on successful load
            WidgetErrorLogger.logInfo(context, "Widget data loaded successfully");
        } else {
            // No save data available - check for widget errors
            String widgetError = WidgetErrorLogger.getLastError(context);
            
            if (widgetError != null && !widgetError.isEmpty()) {
                // Show widget initialization error
                views.setTextViewText(R.id.widget_timestamp, context.getString(R.string.widget_error));
                views.setTextViewText(R.id.widget_last_error, widgetError);
            } else {
                // No errors, just no data yet
                views.setTextViewText(R.id.widget_timestamp, context.getString(R.string.no_save_data));
                views.setTextViewText(R.id.widget_last_error, context.getString(R.string.no_errors));
            }
            
            views.setTextViewText(R.id.widget_day, context.getString(R.string.day_label));
            views.setTextViewText(R.id.widget_health, context.getString(R.string.health_label));
            views.setTextViewText(R.id.widget_torches, context.getString(R.string.torches_label));
            views.setTextViewText(R.id.widget_position, context.getString(R.string.position_label));
            views.setTextViewText(R.id.widget_error_count, context.getString(R.string.errors_label));
            views.setTextViewText(R.id.widget_total_logs, context.getString(R.string.logs_label));
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
            
            if (!dataFile.exists()) {
                WidgetErrorLogger.logError(context, 
                    "Save data file not found. Main game may not be installed or no save yet. Path: " + dataFile.getAbsolutePath(), 
                    null);
                return null;
            }
            
            if (!dataFile.canRead()) {
                WidgetErrorLogger.logError(context, 
                    "Cannot read save data file. Permission denied. Check storage permissions. Path: " + dataFile.getAbsolutePath(), 
                    null);
                return null;
            }
            
            reader = new BufferedReader(new FileReader(dataFile));
            SaveData data = new SaveData();
            
            String line;
            int lineCount = 0;
            while ((line = reader.readLine()) != null) {
                String[] parts = line.split("=", 2);
                if (parts.length == 2) {
                    String key = parts[0].trim();
                    String value = parts[1].trim();
                    
                    try {
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
                            case "position_x":
                                data.positionX = Float.parseFloat(value);
                                break;
                            case "position_z":
                                data.positionZ = Float.parseFloat(value);
                                break;
                            case "error_count":
                                data.errorCount = Integer.parseInt(value);
                                break;
                            case "total_log_count":
                                data.totalLogCount = Integer.parseInt(value);
                                break;
                            case "last_error":
                                data.lastError = value;
                                break;
                        }
                    } catch (NumberFormatException nfe) {
                        WidgetErrorLogger.logError(context,
                            "Invalid data format in save file. Line " + (lineCount + 1) + ": " + line,
                            nfe);
                    }
                }
                lineCount++;
            }
            
            WidgetErrorLogger.logInfo(context, 
                "Successfully read " + lineCount + " lines from save data file");
            return data;
        } catch (java.io.FileNotFoundException fnfe) {
            WidgetErrorLogger.logError(context, 
                "Save data file not found: " + fnfe.getMessage(), 
                fnfe);
            return null;
        } catch (java.io.IOException ioe) {
            WidgetErrorLogger.logError(context, 
                "Error reading save data file: " + ioe.getMessage(), 
                ioe);
            return null;
        } catch (Exception e) {
            WidgetErrorLogger.logError(context, 
                "Unexpected error reading save data: " + e.getMessage(), 
                e);
            return null;
        } finally {
            // Ensure reader is closed even if exception occurs
            if (reader != null) {
                try {
                    reader.close();
                } catch (Exception e) {
                    WidgetErrorLogger.logError(context, 
                        "Error closing file reader: " + e.getMessage(), 
                        e);
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
        int errorCount = 0;
        int totalLogCount = 0;
        String lastError = "No errors";
    }
}
