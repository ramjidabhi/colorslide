package com.godot.game;

import android.app.Activity;
import android.os.Bundle;
import android.util.Log;

import androidx.annotation.NonNull;

import com.google.firebase.analytics.FirebaseAnalytics;

import org.godotengine.godot.Dictionary;
import org.godotengine.godot.Godot;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.SignalInfo;
import org.godotengine.godot.plugin.UsedByGodot;

import java.util.Collections;
import java.util.Map;
import java.util.Set;

/**
 * Production Firebase Analytics Godot Android Plugin.
 * Automatically tracks Daily Active Users (DAU), engagement time, sessions,
 * retention, and custom gameplay events (level completion, hints, ads, boosters).
 */
public class FirebaseAnalyticsPlugin extends GodotPlugin {
    private static final String TAG = "FirebaseAnalyticsPlugin";

    private FirebaseAnalytics firebaseAnalytics;

    public FirebaseAnalyticsPlugin(Godot godot) {
        super(godot);
        Activity activity = getActivity();
        if (activity != null) {
            try {
                firebaseAnalytics = FirebaseAnalytics.getInstance(activity);
                Log.i(TAG, "Firebase Analytics initialized successfully for package: " + activity.getPackageName());
            } catch (Exception e) {
                Log.e(TAG, "Failed to initialize Firebase Analytics", e);
            }
        }
    }

    @NonNull
    @Override
    public String getPluginName() {
        return "FirebaseAnalytics";
    }

    @NonNull
    @Override
    public Set<SignalInfo> getPluginSignals() {
        return Collections.emptySet();
    }

    @UsedByGodot
    public void log_event(final String eventName, final Dictionary params) {
        Activity activity = getActivity();
        if (activity == null) return;

        activity.runOnUiThread(() -> {
            try {
                if (firebaseAnalytics == null) {
                    firebaseAnalytics = FirebaseAnalytics.getInstance(activity);
                }

                Bundle bundle = new Bundle();
                if (params != null && !params.isEmpty()) {
                    for (Map.Entry<String, Object> entry : params.entrySet()) {
                        String key = entry.getKey();
                        Object val = entry.getValue();
                        if (val == null) continue;

                        if (val instanceof Integer) {
                            bundle.putInt(key, (Integer) val);
                        } else if (val instanceof Long) {
                            bundle.putLong(key, (Long) val);
                        } else if (val instanceof Double) {
                            bundle.putDouble(key, (Double) val);
                        } else if (val instanceof Float) {
                            bundle.putFloat(key, (Float) val);
                        } else if (val instanceof Boolean) {
                            bundle.putBoolean(key, (Boolean) val);
                        } else {
                            bundle.putString(key, String.valueOf(val));
                        }
                    }
                }

                // Sanitize event name (lowercase alphanumeric and underscores only, max 40 chars)
                String sanitizedName = eventName.replaceAll("[^a-zA-Z0-9_]", "_");
                if (sanitizedName.length() > 40) {
                    sanitizedName = sanitizedName.substring(0, 40);
                }

                firebaseAnalytics.logEvent(sanitizedName, bundle);
                Log.d(TAG, "Logged event: " + sanitizedName + " with " + bundle.size() + " parameters");
            } catch (Exception e) {
                Log.w(TAG, "Failed to log event: " + eventName, e);
            }
        });
    }

    @UsedByGodot
    public void set_user_property(final String name, final String value) {
        Activity activity = getActivity();
        if (activity == null) return;

        activity.runOnUiThread(() -> {
            try {
                if (firebaseAnalytics == null) {
                    firebaseAnalytics = FirebaseAnalytics.getInstance(activity);
                }
                firebaseAnalytics.setUserProperty(name, value);
                Log.d(TAG, "Set user property: " + name + " = " + value);
            } catch (Exception e) {
                Log.w(TAG, "Failed to set user property: " + name, e);
            }
        });
    }

    @UsedByGodot
    public void set_user_id(final String userId) {
        Activity activity = getActivity();
        if (activity == null) return;

        activity.runOnUiThread(() -> {
            try {
                if (firebaseAnalytics == null) {
                    firebaseAnalytics = FirebaseAnalytics.getInstance(activity);
                }
                firebaseAnalytics.setUserId(userId);
                Log.d(TAG, "Set user ID: " + userId);
            } catch (Exception e) {
                Log.w(TAG, "Failed to set user ID", e);
            }
        });
    }

    @UsedByGodot
    public void reset_analytics_data() {
        Activity activity = getActivity();
        if (activity == null) return;

        activity.runOnUiThread(() -> {
            try {
                if (firebaseAnalytics != null) {
                    firebaseAnalytics.resetAnalyticsData();
                }
            } catch (Exception e) {
                Log.w(TAG, "Failed to reset analytics data", e);
            }
        });
    }
}
