package com.yougame.widget;

import android.content.Context;
import android.os.Environment;
import android.util.Log;

import java.io.File;
import java.io.FileWriter;
import java.io.BufferedWriter;
import java.io.IOException;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Locale;

/**
 * WidgetErrorLogger - Logs widget errors to both logcat and a persistent file
 * 
 * This class provides error logging capabilities for the widget, making it easier
 * to diagnose issues when the widget fails to initialize or load data.
 * 
 * Error logs are written to:
 * - Android logcat (for developers with ADB access)
 * - External storage file (accessible via file manager or App Info)
 */
public class WidgetErrorLogger {
    
    private static final String TAG = "YouGameWidget";
    private static final String LOG_DIR = "YouGame";
    private static final String LOG_FILE = "widget_errors.log";
    private static final int MAX_LOG_SIZE = 50000; // 50KB max log file size
    
    /**
     * Log an error with detailed context
     */
    public static void logError(Context context, String message, Exception exception) {
        // Log to Android logcat
        if (exception != null) {
            Log.e(TAG, message, exception);
        } else {
            Log.e(TAG, message);
        }
        
        // Log to file for user access
        writeToLogFile(context, "ERROR", message, exception);
    }
    
    /**
     * Log an informational message
     */
    public static void logInfo(Context context, String message) {
        Log.i(TAG, message);
        writeToLogFile(context, "INFO", message, null);
    }
    
    /**
     * Get the last error message from the log file
     * Returns null if no error log exists or can't be read
     */
    public static String getLastError(Context context) {
        try {
            File logFile = getLogFile(context);
            if (!logFile.exists() || !logFile.canRead()) {
                return null;
            }
            
            // Read the file and get the last error line
            java.io.BufferedReader reader = new java.io.BufferedReader(
                new java.io.FileReader(logFile));
            String lastError = null;
            String line;
            while ((line = reader.readLine()) != null) {
                if (line.contains("[ERROR]")) {
                    lastError = line;
                }
            }
            reader.close();
            
            if (lastError != null) {
                // Extract just the message part (after timestamp and level)
                int messageStart = lastError.indexOf("]", lastError.indexOf("]") + 1);
                if (messageStart > 0 && messageStart < lastError.length() - 1) {
                    return lastError.substring(messageStart + 2).trim();
                }
            }
            return null;
        } catch (Exception e) {
            Log.e(TAG, "Failed to read last error from log file", e);
            return null;
        }
    }
    
    /**
     * Get the log file path for display to users
     */
    public static String getLogFilePath(Context context) {
        return getLogFile(context).getAbsolutePath();
    }
    
    /**
     * Write a log entry to the persistent log file
     */
    private static void writeToLogFile(Context context, String level, String message, Exception exception) {
        BufferedWriter writer = null;
        try {
            File logFile = getLogFile(context);
            
            // Create parent directories if they don't exist
            File parentDir = logFile.getParentFile();
            if (parentDir != null && !parentDir.exists()) {
                parentDir.mkdirs();
            }
            
            // Check file size and truncate if necessary
            if (logFile.exists() && logFile.length() > MAX_LOG_SIZE) {
                truncateLogFile(logFile);
            }
            
            // Append to log file
            writer = new BufferedWriter(new FileWriter(logFile, true));
            
            // Format: [timestamp] [LEVEL] message
            SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.getDefault());
            String timestamp = sdf.format(new Date());
            
            writer.write(String.format("[%s] [%s] %s\n", timestamp, level, message));
            
            // Add exception stack trace if present
            if (exception != null) {
                writer.write(String.format("  Exception: %s\n", exception.getClass().getName()));
                writer.write(String.format("  Message: %s\n", exception.getMessage()));
                
                // Write first few lines of stack trace
                StackTraceElement[] stackTrace = exception.getStackTrace();
                int linesToWrite = Math.min(5, stackTrace.length);
                for (int i = 0; i < linesToWrite; i++) {
                    writer.write(String.format("    at %s\n", stackTrace[i].toString()));
                }
            }
            
            writer.flush();
        } catch (IOException e) {
            // Can't log to file, but we already logged to logcat
            Log.e(TAG, "Failed to write to log file", e);
        } finally {
            if (writer != null) {
                try {
                    writer.close();
                } catch (IOException e) {
                    // Ignore close errors
                }
            }
        }
    }
    
    /**
     * Get the log file location
     * Uses external storage so it's accessible via file manager
     */
    private static File getLogFile(Context context) {
        // Try to use external storage first (accessible to user)
        File externalDir = context.getExternalFilesDir(null);
        if (externalDir != null) {
            return new File(externalDir, LOG_FILE);
        }
        
        // Fallback to internal storage if external is not available
        return new File(context.getFilesDir(), LOG_FILE);
    }
    
    /**
     * Truncate log file to keep only the most recent entries
     */
    private static void truncateLogFile(File logFile) {
        try {
            // Read all lines
            java.io.BufferedReader reader = new java.io.BufferedReader(
                new java.io.FileReader(logFile));
            java.util.ArrayList<String> lines = new java.util.ArrayList<>();
            String line;
            while ((line = reader.readLine()) != null) {
                lines.add(line);
            }
            reader.close();
            
            // Keep only the last 50% of lines
            int keepFrom = lines.size() / 2;
            
            // Write back the kept lines
            BufferedWriter writer = new BufferedWriter(new FileWriter(logFile, false));
            for (int i = keepFrom; i < lines.size(); i++) {
                writer.write(lines.get(i));
                writer.write("\n");
            }
            writer.close();
        } catch (Exception e) {
            // If truncation fails, delete the file
            logFile.delete();
        }
    }
}
