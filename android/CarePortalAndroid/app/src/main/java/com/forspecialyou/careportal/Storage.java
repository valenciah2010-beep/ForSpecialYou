package com.forspecialyou.careportal;

import android.content.Context;
import android.content.SharedPreferences;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

final class Storage {
    private static final String PREFS = "care_portal_android";
    private static final String SAVED_USER = "auth.savedCarePortalUser";

    private final SharedPreferences prefs;

    Storage(Context context) {
        prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE);
    }

    String getString(String key, String fallback) {
        return prefs.getString(key, fallback);
    }

    void putString(String key, String value) {
        prefs.edit().putString(key, value == null ? "" : value).apply();
    }

    int getInt(String key, int fallback) {
        return prefs.getInt(key, fallback);
    }

    void putInt(String key, int value) {
        prefs.edit().putInt(key, value).apply();
    }

    JSONArray getArray(String key) {
        String raw = prefs.getString(key, "[]");
        try {
            return new JSONArray(raw);
        } catch (JSONException e) {
            return new JSONArray();
        }
    }

    void putArray(String key, JSONArray array) {
        prefs.edit().putString(key, array == null ? "[]" : array.toString()).apply();
    }

    JSONObject getObject(String key) {
        String raw = prefs.getString(key, "{}");
        try {
            return new JSONObject(raw);
        } catch (JSONException e) {
            return new JSONObject();
        }
    }

    void putObject(String key, JSONObject object) {
        prefs.edit().putString(key, object == null ? "{}" : object.toString()).apply();
    }

    CarePortalUser getSavedUser() {
        String raw = prefs.getString(SAVED_USER, "");
        if (raw == null || raw.isEmpty()) {
            return null;
        }
        try {
            return CarePortalUser.fromJson(new JSONObject(raw));
        } catch (JSONException e) {
            clearSavedUser();
            return null;
        }
    }

    void saveUser(CarePortalUser user) {
        try {
            prefs.edit().putString(SAVED_USER, user.toJson().toString()).apply();
        } catch (JSONException ignored) {
        }
    }

    void clearSavedUser() {
        prefs.edit().remove(SAVED_USER).apply();
    }

    String key(String area, int userId, String name) {
        return area + "." + userId + "." + name;
    }
}
