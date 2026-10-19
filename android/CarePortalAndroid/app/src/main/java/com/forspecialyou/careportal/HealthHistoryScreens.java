package com.forspecialyou.careportal;

import android.graphics.Color;
import android.view.Gravity;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;
import java.util.Calendar;
import java.util.Date;
import java.util.Locale;

final class HealthHistoryScreens {

    private final MainActivity host;

    HealthHistoryScreens(MainActivity host) {
        this.host = host;
    }

    void addHealthEntry(String id, String title, String type, String value, String notes, Calendar timestamp) {
        host.addHealthEntry(id, title, type, value, notes, timestamp, "");
    }

    void addHealthEntry(String id, String title, String type, String value, String notes, Calendar timestamp, String imageData) {
        JSONArray entries = host.storage.getArray(host.storage.key("health", host.currentUser.id, "logData"));
        JSONObject entry = new JSONObject();
        try {
            entry.put("id", "android-" + System.currentTimeMillis());
            entry.put("type", type);
            entry.put("categoryID", id);
            entry.put("title", title);
            entry.put("value", value);
            entry.put("notes", notes);
            entry.put("timestamp", host.formatIso(timestamp));
            if (imageData != null && !imageData.isEmpty()) {
                entry.put("imageData", imageData);
            }
        } catch (JSONException ignored) {
        }
        entries.put(entry);
        host.storage.putArray(host.storage.key("health", host.currentUser.id, "logData"), entries);
        host.syncHealth(entries);
    }

    void showNotificationsToday() {
        host.showMessageSheet(host.i18n.t("Notifications Today"), host.i18n.t("No notifications received today."));
    }

    boolean isHealthHistoryPage() {
        return host.selectedTab == 1 && !host.healthHistoryType.isEmpty();
    }

    void clearHealthHistoryPage() {
        host.healthHistoryType = "";
        host.healthHistoryCategoryId = "";
        host.healthHistoryCategoryTitle = "";
    }

    void showHealthHistory(String filterType) {
        host.healthHistoryType = "snapshot".equals(filterType) ? "snapshot" : "quickLog";
        host.healthHistoryCategoryId = "";
        host.healthHistoryCategoryTitle = "";
        host.render();
    }

    View healthHistoryPage() {
        JSONArray entries = host.storage.getArray(host.storage.key("health", host.currentUser.id, "logData"));
        LinearLayout screen = Ui.screen(host);
        screen.setPadding(Ui.dp(host, 22), Ui.dp(host, 22), Ui.dp(host, 22), Ui.dp(host, 24));
        LinearLayout header = Ui.h(host, 0);
        header.setGravity(Gravity.CENTER_VERTICAL);
        TextView back = host.iconCircle("‹", AppColors.TEXT, AppColors.PANEL, 58);
        back.setTextSize(36);
        back.setOnClickListener(v -> {
            if (!host.healthHistoryCategoryId.isEmpty()) {
                host.healthHistoryCategoryId = "";
                host.healthHistoryCategoryTitle = "";
            } else {
                host.clearHealthHistoryPage();
            }
            host.render();
        });
        header.addView(back, Ui.fixed(host, 58, 58));
        header.addView(new View(host), new LinearLayout.LayoutParams(0, 1, 1));
        screen.addView(header, Ui.matchWrap());
        Ui.addSpacer(host, screen, 22);
        if (!host.healthHistoryCategoryId.isEmpty()) {
            host.addHealthHistoryDetailPage(screen, entries);
        } else {
            host.addHealthHistoryCategoryPage(screen, entries);
        }
        return Ui.scroll(host, screen);
    }

    void addHealthHistoryCategoryPage(LinearLayout screen, JSONArray entries) {
        String title = "snapshot".equals(host.healthHistoryType) ? "Daily Snapshot History" : "Quick-log History";
        screen.addView(Ui.title(host, host.i18n.t(title)), Ui.matchWrap());
        Ui.addSpacer(host, screen, 18);
        String[][] categories = "snapshot".equals(host.healthHistoryType) ? host.SNAPSHOTS : host.QUICK_LOGS;
        for (String[] category : categories) {
            screen.addView(host.healthHistoryCategoryRow(host.healthHistoryType, category[0], category[1], entries), Ui.matchWrap());
            Ui.addSpacer(host, screen, 12);
        }
    }

    void addHealthHistoryDetailPage(LinearLayout screen, JSONArray entries) {
        screen.addView(Ui.title(host, host.i18n.t(host.healthHistoryCategoryTitle)), Ui.matchWrap());
        Ui.addSpacer(host, screen, 16);
        int shown = 0;
        for (int i = entries.length() - 1; i >= 0; i--) {
            JSONObject item = entries.optJSONObject(i);
            if (item == null)
                continue;
            if (!host.healthHistoryType.equals(item.optString("type")))
                continue;
            if (!host.healthHistoryCategoryId.equals(item.optString("categoryID")))
                continue;
            View row = host.healthHistoryRow(item);
            row.setOnClickListener(v -> host.showHealthEntryDetail(item));
            screen.addView(row, Ui.matchWrap());
            Ui.addSpacer(host, screen, 8);
            shown++;
        }
        if (shown == 0) {
            LinearLayout empty = Ui.panel(host);
            empty.addView(Ui.muted(host, host.i18n.t("No records yet.")), Ui.matchWrap());
            screen.addView(empty, Ui.matchWrap());
        }
    }

    void showHealthHistoryDialog(String filterType) {
        JSONArray entries = host.storage.getArray(host.storage.key("health", host.currentUser.id, "logData"));
        LinearLayout content = Ui.v(host, 0);
        content.setPadding(Ui.dp(host, 12), 0, Ui.dp(host, 12), 0);
        String type = "snapshot".equals(filterType) ? "snapshot" : "quickLog";
        String[][] categories = "snapshot".equals(type) ? host.SNAPSHOTS : host.QUICK_LOGS;
        for (String[] category : categories) {
            content.addView(host.healthHistoryCategoryRow(type, category[0], category[1], entries), Ui.matchWrap());
            Ui.addSpacer(host, content, 10);
        }
        Ui.dialog(host, host.i18n.t("snapshot".equals(type) ? "Daily Snapshot History" : "Quick-log History"), content, host.i18n.t("Done"), null);
    }

    Button historyFilterButton(String title, boolean selected, Runnable action) {
        Button button = Ui.secondary(host, title);
        button.setTextSize(12);
        if (selected) {
            button.setTextColor(AppColors.PANEL);
            button.setBackground(Ui.stroke(AppColors.ACCENT, AppColors.ACCENT, Ui.dp(host, 12)));
        }
        button.setOnClickListener(v -> {
            if (action != null)
                action.run();
        });
        return button;
    }

    View healthHistoryCategoryRow(String type, String id, String title, JSONArray entries) {
        int color = "snapshot".equals(type) ? host.snapshotColor(id) : host.quickLogColor(id);
        String displayTitle = "snapshot".equals(type) ? host.snapshotTitle(id, title) : title;
        LinearLayout row = Ui.h(host, 0);
        row.setGravity(Gravity.CENTER_VERTICAL);
        row.setClickable(true);
        row.setFocusable(true);
        row.setPadding(Ui.dp(host, 14), Ui.dp(host, 14), Ui.dp(host, 12), Ui.dp(host, 14));
        row.setBackground(Ui.stroke(AppColors.PANEL, Ui.withAlpha(color, 50), Ui.dp(host, 16)));
        int iconRes = "snapshot".equals(type) ? host.snapshotIconRes(id) : host.quickLogIconRes(id);
        ImageView icon = host.symbolIcon(iconRes, color, Ui.withAlpha(color, 28), 58, 12);
        row.addView(icon, Ui.fixed(host, 58, 58));
        LinearLayout texts = Ui.v(host, 0);
        TextView name = Ui.text(host, host.i18n.t(displayTitle), 19, AppColors.TEXT, android.graphics.Typeface.BOLD);
        texts.addView(name, Ui.matchWrap());
        Ui.addSpacer(host, texts, 2);
        texts.addView(Ui.muted(host, host.healthCategorySummary(entries, type, id)), Ui.matchWrap());
        LinearLayout.LayoutParams textParams = new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1);
        textParams.leftMargin = Ui.dp(host, 14);
        row.addView(texts, textParams);
        ImageView chevron = host.symbolIcon(R.drawable.ios_icon_chevron_right, AppColors.MUTED, Color.TRANSPARENT, 28, 4);
        row.addView(chevron, Ui.fixed(host, 28, 28));
        row.setOnClickListener(v -> {
            host.healthHistoryType = type;
            host.healthHistoryCategoryId = id;
            host.healthHistoryCategoryTitle = displayTitle;
            host.render();
        });
        return row;
    }

    String healthCategorySummary(JSONArray entries, String type, String categoryId) {
        int count = 0;
        double severityTotal = 0;
        int severityCount = 0;
        JSONObject latest = null;
        for (int i = entries.length() - 1; i >= 0; i--) {
            JSONObject item = entries.optJSONObject(i);
            if (item == null)
                continue;
            if (!type.equals(item.optString("type")))
                continue;
            if (!categoryId.equals(item.optString("categoryID")))
                continue;
            count++;
            if (latest == null)
                latest = item;
            double score = host.fivePointScore(item.optString("value"));
            if (score > 0) {
                severityTotal += score;
                severityCount++;
            }
        }
        if (count == 0)
            return host.i18n.t("0 entries");
        StringBuilder summary = new StringBuilder();
        summary.append(count).append(" ").append(host.i18n.t(count == 1 ? "entry" : "entries"));
        if (severityCount > 0) {
            summary.append(" · ").append(host.i18n.t("Avg")).append(" ");
            summary.append(String.format(Locale.US, "%.1f/5", severityTotal / severityCount));
        } else if (latest != null && !latest.optString("value").isEmpty()) {
            summary.append(" · ").append(host.notesPreview(latest.optString("value")).replace("\n", " "));
        }
        return summary.toString();
    }

    double fivePointScore(String value) {
        if (value == null)
            return 0;
        int slash = value.indexOf("/5");
        if (slash <= 0)
            return 0;
        int start = slash - 1;
        while (start >= 0 && (Character.isDigit(value.charAt(start)) || value.charAt(start) == '.')) {
            start--;
        }
        try {
            return Double.parseDouble(value.substring(start + 1, slash));
        } catch (NumberFormatException ignored) {
            return 0;
        }
    }

    void showHealthCategoryDetail(String type, String categoryId, String title) {
        JSONArray entries = host.storage.getArray(host.storage.key("health", host.currentUser.id, "logData"));
        LinearLayout content = Ui.v(host, 0);
        content.setPadding(Ui.dp(host, 12), 0, Ui.dp(host, 12), 0);
        int shown = 0;
        for (int i = entries.length() - 1; i >= 0; i--) {
            JSONObject item = entries.optJSONObject(i);
            if (item == null)
                continue;
            if (!type.equals(item.optString("type")))
                continue;
            if (!categoryId.equals(item.optString("categoryID")))
                continue;
            View row = host.healthHistoryRow(item);
            row.setOnClickListener(v -> host.showHealthEntryDetail(item));
            content.addView(row, Ui.matchWrap());
            Ui.addSpacer(host, content, 8);
            shown++;
        }
        if (shown == 0) {
            content.addView(Ui.muted(host, host.i18n.t("No records yet.")), Ui.matchWrap());
        }
        Ui.dialog(host, host.i18n.t(title), content, host.i18n.t("Done"), null);
    }

    View healthHistoryRow(JSONObject item) {
        String categoryId = item.optString("categoryID");
        String icon = "quickLog".equals(item.optString("type")) ? host.quickLogIcon(categoryId) : host.snapshotIcon(categoryId);
        String detail = host.displayDateTime(item.optString("timestamp")) + "\n" + item.optString("value");
        String notes = item.optString("notes");
        if (!notes.isEmpty())
            detail += "\n" + host.notesPreview(notes);
        if (!item.optString("imageData").isEmpty())
            detail += "\n" + host.i18n.t("Photo attached");
        return Ui.cardRow(host, host.i18n.t(item.optString("title")), detail, icon);
    }

    void showHealthEntryDetail(JSONObject item) {
        LinearLayout content = Ui.v(host, 0);
        content.setPadding(Ui.dp(host, 12), 0, Ui.dp(host, 12), 0);
        content.addView(Ui.cardRow(host, host.i18n.t("Date"), host.displayDateTime(item.optString("timestamp")), "🗓"), Ui.matchWrap());
        Ui.addSpacer(host, content, 8);
        content.addView(Ui.cardRow(host, host.i18n.t("Log"), item.optString("value"), "✓"), Ui.matchWrap());
        if (!item.optString("notes").isEmpty()) {
            Ui.addSpacer(host, content, 8);
            content.addView(Ui.cardRow(host, host.i18n.t("Notes"), item.optString("notes"), "📝"), Ui.matchWrap());
        }
        if (!item.optString("imageData").isEmpty()) {
            Ui.addSpacer(host, content, 8);
            content.addView(Ui.cardRow(host, host.i18n.t("Photo"), host.i18n.t("Photo attached"), "📷"), Ui.matchWrap());
        }
        Ui.dialog(host, ("quickLog".equals(item.optString("type")) ? host.quickLogIcon(item.optString("categoryID")) : host.snapshotIcon(item.optString("categoryID"))) + " " + host.i18n.t(item.optString("title")), content, host.i18n.t("Done"), null);
    }

    void loadHealthInsights() {
        JSONArray quick = new JSONArray();
        for (String[] option : host.QUICK_LOGS) quick.put(host.i18n.t(option[1]));
        JSONArray snaps = new JSONArray();
        for (String[] option : host.SNAPSHOTS) snaps.put(host.i18n.t(option[1]));
        JSONArray logs = host.storage.getArray(host.storage.key("health", host.currentUser.id, "logData"));
        host.api.healthInsights(host.childName(), quick, snaps, logs, host.i18n.apiLanguageName(), new AuthApi.Callback<JSONArray>() {

            @Override
            public void onSuccess(JSONArray value) {
                String insight = value.length() > 0 ? value.optJSONObject(0).optString("message") : "No insight available.";
                host.showMessageSheet(host.i18n.t("Insights & Alerts"), insight);
            }

            @Override
            public void onError(String msg) {
                host.showMessageSheet(host.i18n.t("Insights & Alerts"), msg);
            }
        });
    }
}
