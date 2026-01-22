package com.yougame.savegamewidget;

import android.app.Activity;
import android.content.Context;
import android.content.SharedPreferences;

import androidx.annotation.NonNull;
import androidx.collection.ArraySet;

import org.godotengine.godot.Godot;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.SignalInfo;

import java.util.Set;

/**
 * SaveGameWidgetPlugin - Godot plugin for updating Android widget with save data
 * 
 * This plugin allows the Godot game to export save data to SharedPreferences
 * which the widget can then read and display.
 */
public class SaveGameWidgetPlugin extends GodotPlugin {
    
    private static final String PREFS_NAME = "YouGameSaveData";
    
    public SaveGameWidgetPlugin(Godot godot) {
        super(godot);
    }
    
    @NonNull
    @Override
    public String getPluginName() {
        return "SaveGameWidget";
    }
    
    /**
     * Export save data to SharedPreferences for the widget to read
     * 
     * @param timestamp Unix timestamp of the save
     * @param dayCount Current day count
     * @param currentHealth Player's current health (0-100)
     * @param torchCount Number of torches in inventory
     * @param positionX Player's X position
     * @param positionY Player's Y position
     * @param positionZ Player's Z position
     */
    public void exportSaveData(long timestamp, int dayCount, float currentHealth, 
                              int torchCount, float positionX, float positionY, float positionZ) {
        Activity activity = getActivity();
        if (activity == null) {
            return;
        }
        
        SharedPreferences prefs = activity.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE);
        SharedPreferences.Editor editor = prefs.edit();
        
        editor.putLong("timestamp", timestamp);
        editor.putInt("day_count", dayCount);
        editor.putFloat("current_health", currentHealth);
        editor.putInt("torch_count", torchCount);
        editor.putFloat("position_x", positionX);
        editor.putFloat("position_y", positionY);
        editor.putFloat("position_z", positionZ);
        
        editor.apply();
        
        // Trigger widget update
        SaveGameWidgetProvider.requestWidgetUpdate(activity);
    }
    
    /**
     * Clear saved widget data
     */
    public void clearSaveData() {
        Activity activity = getActivity();
        if (activity == null) {
            return;
        }
        
        SharedPreferences prefs = activity.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE);
        prefs.edit().clear().apply();
        
        // Trigger widget update to show "no data"
        SaveGameWidgetProvider.requestWidgetUpdate(activity);
    }
}
