package com.forspecialyou.careportal;

import android.os.Handler;
import android.content.Context;
import android.app.AlertDialog;
import android.util.Base64;
import java.security.MessageDigest;
import java.util.Arrays;
import android.os.Looper;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.io.OutputStreamWriter;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

final class AuthApi {
    interface Callback<T> {
        void onSuccess(T value);

        void onError(String message);
    }

    private final Context context;
    private final SessionStore session;
    private Runnable sessionExpiredListener;
    private String consentToken = "";
    private final String baseUrl;
    private final I18n i18n;
    private final ExecutorService executor = Executors.newSingleThreadExecutor();
    private final Handler mainHandler = new Handler(Looper.getMainLooper());

    AuthApi(Context context, I18n i18n) {
        this.context = context;
        this.session = new SessionStore(context);
        this.baseUrl = BuildConfig.API_BASE_URL;
        this.i18n = i18n;
    }

    boolean hasSession() { return !session.token().isEmpty(); }

    void onSessionExpired(Runnable listener) { sessionExpiredListener = listener; }

    void login(String username, String password, Callback<CarePortalUser> callback) {
        JSONObject body = new JSONObject();
        try {
            body.put("username", username);
            body.put("password", password);
        } catch (JSONException ignored) {
        }
        postAsync("/api/login", body, new Callback<JSONObject>() {
            @Override
            public void onSuccess(JSONObject value) {
                JSONObject userJson = value.optJSONObject("user");
                if (userJson == null) {
                    callback.onError(i18n.t("The server sent an unexpected response."));
                    return;
                }
                try {
                    callback.onSuccess(CarePortalUser.fromJson(userJson));
                } catch (JSONException e) {
                    callback.onError(i18n.t("The server sent an unexpected response."));
                }
            }

            @Override
            public void onError(String message) {
                callback.onError(message);
            }
        });
    }

    void signup(String nickname, String email, String password, String verifyPassword, Callback<String> callback) {
        JSONObject body = new JSONObject();
        try {
            body.put("nickname", nickname);
            body.put("username", nickname);
            body.put("email", email);
            body.put("password", password);
            body.put("verifyPassword", verifyPassword);
            body.put("role", "parent");
        } catch (JSONException ignored) {
        }
        postAsync("/api/signup", body, new Callback<JSONObject>() {
            @Override
            public void onSuccess(JSONObject value) {
                callback.onSuccess(value.optString("message"));
            }

            @Override
            public void onError(String message) {
                callback.onError(message);
            }
        });
    }

    void validateSavedSession(int userId, Callback<CarePortalUser> callback) {
        JSONObject body = new JSONObject();
        try {
            body.put("userId", userId);
        } catch (JSONException ignored) {
        }
        postAsync("/api/app-session", body, new Callback<JSONObject>() {
            @Override
            public void onSuccess(JSONObject value) {
                JSONObject userJson = value.optJSONObject("user");
                if (userJson == null) {
                    callback.onError(i18n.t("The server sent an unexpected response."));
                    return;
                }
                try {
                    callback.onSuccess(CarePortalUser.fromJson(userJson));
                } catch (JSONException e) {
                    callback.onError(i18n.t("The server sent an unexpected response."));
                }
            }

            @Override
            public void onError(String message) {
                callback.onError(message);
            }
        });
    }

    void loadAppData(int userId, Callback<JSONObject> callback) {
        JSONObject body = new JSONObject();
        try {
            body.put("userId", userId);
        } catch (JSONException ignored) {
        }
        postAsync("/api/app-data/load", body, callback);
    }

    void syncAppData(int userId, JSONObject childProfile, JSONArray healthLogs, JSONArray savedMeals, JSONObject nutrientDailyUsage) {
        JSONObject body = new JSONObject();
        try {
            body.put("userId", userId);
            body.put("childProfile", childProfile == null ? JSONObject.NULL : childProfile);
            body.put("healthLogs", healthLogs == null ? JSONObject.NULL : healthLogs);
            body.put("savedMeals", savedMeals == null ? JSONObject.NULL : savedMeals);
            body.put("nutrientDailyUsage", nutrientDailyUsage == null ? JSONObject.NULL : nutrientDailyUsage);
        } catch (JSONException ignored) {
        }
        postAsync("/api/app-data", body, new Callback<JSONObject>() {
            @Override
            public void onSuccess(JSONObject value) {
            }

            @Override
            public void onError(String message) {
            }
        });
    }

    void appSettings(int userId, Callback<JSONObject> callback) {
        JSONObject body = new JSONObject();
        try {
            body.put("userId", userId);
        } catch (JSONException ignored) {
        }
        postAsync("/api/app-settings", body, callback);
    }

    void analyzeMeal(String imageDataUrl, String language, Callback<JSONObject> callback) {
        JSONObject body = new JSONObject();
        try {
            body.put("imageData", imageDataUrl);
            body.put("language", language);
        } catch (JSONException ignored) {
        }
        postAsync("/api/analyze-meal", body, callback);
    }

    void healthInsights(String childName, JSONArray quickLogTitles, JSONArray snapshotTitles, JSONArray logs, String language, Callback<JSONArray> callback) {
        JSONObject body = new JSONObject();
        try {
            body.put("childName", childName);
            body.put("quickLogTitles", quickLogTitles);
            body.put("snapshotTitles", snapshotTitles);
            body.put("logs", logs);
            body.put("language", language);
        } catch (JSONException ignored) {
        }
        postAsync("/api/health-insights", body, new Callback<JSONObject>() {
            @Override
            public void onSuccess(JSONObject value) {
                callback.onSuccess(value.optJSONArray("insights") == null ? new JSONArray() : value.optJSONArray("insights"));
            }

            @Override
            public void onError(String message) {
                callback.onError(message);
            }
        });
    }

    private void postAsync(String path, JSONObject body, Callback<JSONObject> callback) {
        if ((path.equals("/api/analyze-meal") || path.equals("/api/health-insights")) && !session.token().equals(consentToken)) {
            new AlertDialog.Builder(context).setTitle(i18n.t("AI analysis"))
                .setMessage(i18n.t("Selected photos and structured health records will be sent to OpenAI. Continue?"))
                .setNegativeButton(i18n.t("Cancel"), (dialog, which) -> callback.onError(i18n.t("Cancelled")))
                .setPositiveButton(i18n.t("Continue"), (dialog, which) -> { consentToken = session.token(); postAsync(path, body, callback); }).show();
            return;
        }
        executor.execute(() -> {
            try {
                JSONObject requestBody = body;
                if (path.equals("/api/analyze-meal") || path.equals("/api/health-insights")) body.put("aiConsent", true);
                if (path.equals("/api/analyze-meal")) {
                    requestBody = new JSONObject(body.toString());
                    requestBody.put("imageId", upload(body.getString("imageData")));
                    requestBody.remove("imageData");
                }
                JSONObject result = post(path, requestBody);
                if (path.equals("/api/login")) {
                    String token = result.optString("token");
                    if (token.isEmpty()) throw new ApiException("Please log in again.");
                    session.save(token);
                }
                mainHandler.post(() -> callback.onSuccess(result));
            } catch (ApiException e) {
                mainHandler.post(() -> callback.onError(i18n.server(e.getMessage())));
            } catch (Exception e) {
                mainHandler.post(() -> callback.onError(i18n.t("Unable to reach the server.")));
            }
        });
    }

    void logout() {
        final String token = session.token(); session.clear(); consentToken = "";
        executor.execute(() -> { try { request("/api/app-logout", new JSONObject(), "POST", token); } catch (Exception ignored) {} });
    }

    private String upload(String image) throws Exception {
        byte[] bytes = Base64.decode(image.substring(image.indexOf(',') + 1), Base64.DEFAULT);
        if (bytes.length > 20 * 1024 * 1024) throw new ApiException("Image is too large.");
        StringBuilder digest = new StringBuilder();
        for (byte part : MessageDigest.getInstance("SHA-256").digest(bytes)) digest.append(String.format(java.util.Locale.ROOT, "%02x", part & 0xff));
        android.content.SharedPreferences progress = context.getSharedPreferences("upload_progress", Context.MODE_PRIVATE);
        String owner = Integer.toHexString(session.token().hashCode());
        String cacheKey = owner + ":" + digest;
        String id = progress.getString(cacheKey, "");
        java.util.Set<Integer> received = new java.util.HashSet<>();
        if (!id.isEmpty()) {
            try {
                JSONObject status = request("/api/uploads/" + id, new JSONObject(), "GET", session.token());
                if (status.optBoolean("completed")) return id;
                JSONArray chunks = status.optJSONArray("chunks");
                if (chunks != null) for (int i=0;i<chunks.length();i++) received.add(chunks.getInt(i));
            } catch (Exception error) { id = ""; }
        }
        if (id.isEmpty()) {
            JSONObject init = new JSONObject().put("size", bytes.length).put("checksum", digest.toString());
            id = post("/api/uploads", init).getString("id");
            progress.edit().putString(cacheKey, id).apply();
        }
        int chunkBytes = 512 * 1024;
        for (int offset=0;offset<bytes.length;offset+=chunkBytes) {
            int index=offset/chunkBytes;
            if (received.contains(index)) continue;
            JSONObject chunk = new JSONObject().put("data", Base64.encodeToString(Arrays.copyOfRange(bytes, offset, Math.min(offset+chunkBytes,bytes.length)),Base64.NO_WRAP));
            request("/api/uploads/"+id+"/chunks/"+index, chunk, "PUT", session.token());
        }
        post("/api/uploads/"+id+"/complete", new JSONObject());
        return id;
    }

    private JSONObject post(String path, JSONObject body) throws IOException, JSONException, ApiException {
        return request(path, body, "POST", session.token());
    }

    private JSONObject request(String path, JSONObject body, String method, String token) throws IOException, JSONException, ApiException {
        URL url = new URL(baseUrl + path);
        HttpURLConnection connection = (HttpURLConnection) url.openConnection();
        connection.setRequestMethod(method);
        connection.setConnectTimeout(12000);
        connection.setReadTimeout(60000);
        connection.setDoOutput(!method.equals("GET"));
        if (!token.isEmpty()) connection.setRequestProperty("Authorization", "Bearer " + token);
        connection.setRequestProperty("Content-Type", "application/json");

        try {
        if (!method.equals("GET")) try (OutputStream output = connection.getOutputStream();
             BufferedWriter writer = new BufferedWriter(new OutputStreamWriter(output, StandardCharsets.UTF_8))) {
            writer.write(body.toString());
        }

        int status = connection.getResponseCode();
        String response = read(status >= 200 && status < 300 ? connection.getInputStream() : connection.getErrorStream());
        if (status == 401) {
            if (!token.isEmpty() && token.equals(session.token())) {
                session.clear();
                mainHandler.post(() -> {
                    if (!hasSession() && sessionExpiredListener != null) sessionExpiredListener.run();
                });
            }
            throw new ApiException("Please log in again.");
        }
        if (status >= 200 && status < 300) {
            return response.isEmpty() ? new JSONObject() : new JSONObject(response);
        }

        try {
            JSONObject error = new JSONObject(response);
            throw new ApiException(error.optString("message", "Request failed with status " + status));
        } catch (JSONException e) {
            throw new ApiException("Request failed with status " + status);
        }
        } finally { connection.disconnect(); }
    }

    private String read(InputStream input) throws IOException {
        if (input == null) {
            return "";
        }
        StringBuilder builder = new StringBuilder();
        try (BufferedReader reader = new BufferedReader(new InputStreamReader(input, StandardCharsets.UTF_8))) {
            String line;
            while ((line = reader.readLine()) != null) {
                builder.append(line);
            }
        }
        return builder.toString();
    }

    private static final class ApiException extends Exception {
        ApiException(String message) {
            super(message);
        }
    }
}
