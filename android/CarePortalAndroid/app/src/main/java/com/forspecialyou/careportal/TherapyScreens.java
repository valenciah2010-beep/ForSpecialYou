package com.forspecialyou.careportal;

import android.graphics.Color;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.EditText;
import android.widget.GridLayout;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;
import java.util.Date;

final class TherapyScreens {

    private final MainActivity host;

    TherapyScreens(MainActivity host) {
        this.host = host;
    }

    View therapyView() {
        LinearLayout screen = Ui.screen(host);
        screen.addView(host.therapyHeader(), Ui.matchWrap());
        Ui.addSpacer(host, screen, 16);
        JSONArray milestones = host.storage.getArray(host.storage.key("therapy", host.currentUser.id, "milestoneData"));
        String[] therapySession = host.THERAPY_CATEGORIES[0];
        View sessionButton = host.therapySessionButton(therapySession);
        sessionButton.setOnClickListener(v -> host.showMilestoneDialog(therapySession));
        screen.addView(sessionButton, Ui.matchWrap());
        Ui.addSpacer(host, screen, 16);
        GridLayout grid = Ui.grid(host, 2);
        for (String[] category : host.THERAPY_CATEGORIES) {
            if ("therapySession".equals(category[0])) {
                continue;
            }
            int count = host.countBy(milestones, "categoryID", category[0]);
            LinearLayout card = host.therapyCard(category, count);
            card.setOnClickListener(v -> host.showMilestoneDialog(category));
            Ui.addGridChild(host, grid, card, 2);
        }
        screen.addView(grid, Ui.matchWrap());
        Ui.addSpacer(host, screen, 16);
        LinearLayout recent = Ui.panel(host);
        LinearLayout row = Ui.h(host, 0);
        row.addView(Ui.sectionTitle(host, host.i18n.t("Recent Milestones")), new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1));
        Button hist = Ui.secondary(host, host.i18n.t("History"));
        host.setButtonSymbol(hist, R.drawable.ios_icon_chart_line_uptrend, AppColors.ACCENT, 18);
        hist.setOnClickListener(v -> host.showMilestoneHistory());
        row.addView(hist, Ui.wrapWrap());
        recent.addView(row, Ui.matchWrap());
        Ui.addSpacer(host, recent, 12);
        if (milestones.length() == 0) {
            recent.addView(Ui.muted(host, host.i18n.t("No milestones logged yet.")), Ui.matchWrap());
        } else {
            for (int i = milestones.length() - 1; i >= Math.max(0, milestones.length() - 5); i--) {
                JSONObject item = milestones.optJSONObject(i);
                if (item == null)
                    continue;
                View milestoneRow = Ui.cardRow(host, item.optString("milestone"), host.i18n.t(item.optString("categoryTitle")) + " · " + item.optString("supportLevel"), host.therapyIcon(item.optString("categoryID")));
                milestoneRow.setOnClickListener(v -> host.showMilestoneDetail(item));
                recent.addView(milestoneRow, Ui.matchWrap());
                Ui.addSpacer(host, recent, 8);
            }
        }
        screen.addView(recent, Ui.matchWrap());
        return Ui.scroll(host, screen);
    }

    View therapySessionButton(String[] category) {
        int color = host.therapyColor(category[0]);
        LinearLayout row = Ui.h(host, 0);
        row.setPadding(Ui.dp(host, 18), Ui.dp(host, 16), Ui.dp(host, 18), Ui.dp(host, 16));
        row.setMinimumHeight(Ui.dp(host, 88));
        row.setClickable(true);
        row.setFocusable(true);
        row.setBackground(Ui.stroke(AppColors.PANEL, Ui.withAlpha(Color.rgb(120, 190, 230), 80), Ui.dp(host, 18)));
        ImageView icon = host.therapyIconView(category[0], color, Ui.withAlpha(color, 26), 52, 12);
        row.addView(icon, Ui.fixed(host, 52, 52));
        Ui.addSpacerHorizontal(host, row, 18);
        row.addView(Ui.text(host, host.i18n.t(category[1]), 22, AppColors.TEXT, android.graphics.Typeface.BOLD), new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1));
        row.addView(Ui.text(host, "+", 30, AppColors.ACCENT, android.graphics.Typeface.BOLD), Ui.wrapWrap());
        return row;
    }

    LinearLayout therapyCard(String[] category, int count) {
        int color = host.therapyColor(category[0]);
        LinearLayout card = Ui.v(host, 0);
        card.setPadding(Ui.dp(host, 16), Ui.dp(host, 16), Ui.dp(host, 16), Ui.dp(host, 16));
        card.setMinimumHeight(Ui.dp(host, 176));
        card.setClickable(true);
        card.setFocusable(true);
        card.setBackground(Ui.stroke(Ui.withAlpha(color, 34), Ui.withAlpha(color, 78), Ui.dp(host, 14)));
        LinearLayout top = Ui.h(host, 0);
        ImageView icon = host.therapyIconView(category[0], AppColors.PANEL, color, 48, 12);
        top.addView(icon, Ui.fixed(host, 48, 48));
        TextView countBadge = Ui.chip(host, String.valueOf(count), color, false);
        countBadge.setTextSize(15);
        LinearLayout.LayoutParams badgeParams = new LinearLayout.LayoutParams(ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        badgeParams.leftMargin = Ui.dp(host, 8);
        top.addView(new View(host), new LinearLayout.LayoutParams(0, 1, 1));
        top.addView(countBadge, badgeParams);
        card.addView(top, Ui.matchWrap());
        Ui.addSpacer(host, card, 20);
        card.addView(Ui.text(host, host.i18n.t(category[1]), 20, AppColors.TEXT, android.graphics.Typeface.BOLD), Ui.matchWrap());
        Ui.addSpacer(host, card, 10);
        card.addView(Ui.muted(host, host.i18n.t(category[2])), Ui.matchWrap());
        return card;
    }

    LinearLayout therapyHeader() {
        LinearLayout header = Ui.v(host, 0);
        LinearLayout row = Ui.h(host, 0);
        ImageView icon = new ImageView(host);
        icon.setImageResource(R.drawable.ios_therapy_session);
        icon.setColorFilter(AppColors.ACCENT);
        icon.setPadding(0, 0, 0, 0);
        row.addView(icon, Ui.fixed(host, 48, 48));
        TextView title = Ui.title(host, host.i18n.t("Therapy Tracking"));
        LinearLayout.LayoutParams titleParams = new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1);
        titleParams.leftMargin = Ui.dp(host, 12);
        row.addView(title, titleParams);
        header.addView(row, Ui.matchWrap());
        Ui.addSpacer(host, header, 6);
        header.addView(Ui.muted(host, host.i18n.t("Log milestones and therapy wins to see your child's progress over time.")), Ui.matchWrap());
        return header;
    }

    ImageView therapyIconView(String id, int tintColor, int backgroundColor, int sizeDp, int paddingDp) {
        ImageView icon = new ImageView(host);
        icon.setImageResource(host.therapyIconRes(id));
        icon.setColorFilter(tintColor);
        icon.setBackground(Ui.round(backgroundColor, Ui.dp(host, sizeDp / 2)));
        icon.setPadding(Ui.dp(host, paddingDp), Ui.dp(host, paddingDp), Ui.dp(host, paddingDp), Ui.dp(host, paddingDp));
        icon.setScaleType(ImageView.ScaleType.CENTER_INSIDE);
        return icon;
    }

    int therapyIconRes(String id) {
        switch(id) {
            case "physical":
                return R.drawable.ios_therapy_physical;
            case "occupational":
                return R.drawable.ios_therapy_occupational;
            case "speech":
                return R.drawable.ios_therapy_speech;
            case "behavioral":
                return R.drawable.ios_therapy_behavioral;
            case "social":
                return R.drawable.ios_therapy_social;
            case "feeding":
                return R.drawable.ios_therapy_feeding;
            case "therapySession":
            default:
                return R.drawable.ios_therapy_session;
        }
    }

    String therapyIcon(String id) {
        switch(id) {
            case "therapySession":
                return "🧘";
            case "physical":
                return "🚶";
            case "occupational":
                return "✋";
            case "speech":
                return "💬";
            case "behavioral":
                return "🧠";
            case "social":
                return "👥";
            case "feeding":
                return "🍴";
            default:
                return "✓";
        }
    }

    int therapyColor(String id) {
        switch(id) {
            case "therapySession":
                return Color.rgb(95, 172, 225);
            case "physical":
                return Color.rgb(236, 164, 82);
            case "occupational":
                return Color.rgb(105, 190, 160);
            case "speech":
                return Color.rgb(95, 157, 226);
            case "behavioral":
                return Color.rgb(211, 108, 164);
            case "social":
                return Color.rgb(145, 124, 224);
            case "feeding":
                return Color.rgb(119, 190, 120);
            default:
                return AppColors.ACCENT;
        }
    }

    void showMilestoneDialog(String[] category) {
        LinearLayout content = Ui.v(host, 0);
        content.setPadding(Ui.dp(host, 12), 0, Ui.dp(host, 12), 0);
        EditText milestone = Ui.edit(host, "Example: Used two-word request");
        EditText support = Ui.edit(host, host.i18n.t("Support level"));
        support.setText("With some support");
        EditText notes = Ui.multi(host, "Notes");
        content.addView(Ui.fieldGroup(host, host.i18n.t("Milestone"), milestone), Ui.matchWrap());
        Ui.addSpacer(host, content, 12);
        content.addView(Ui.fieldGroup(host, host.i18n.t("Support level"), support), Ui.matchWrap());
        Ui.addSpacer(host, content, 12);
        content.addView(Ui.fieldGroup(host, "Notes", notes), Ui.matchWrap());
        Ui.dialog(host, host.i18n.t(category[1]), content, host.i18n.t("Save"), () -> {
            String clean = milestone.getText().toString().trim();
            if (clean.isEmpty())
                return;
            JSONArray milestones = host.storage.getArray(host.storage.key("therapy", host.currentUser.id, "milestoneData"));
            JSONObject item = new JSONObject();
            try {
                item.put("id", "android-" + System.currentTimeMillis());
                item.put("categoryID", category[0]);
                item.put("categoryTitle", category[1]);
                item.put("date", host.nowIso());
                item.put("milestone", clean);
                item.put("supportLevel", support.getText().toString().trim());
                item.put("notes", notes.getText().toString().trim());
            } catch (JSONException ignored) {
            }
            milestones.put(item);
            host.storage.putArray(host.storage.key("therapy", host.currentUser.id, "milestoneData"), milestones);
            host.render();
        });
    }

    void showMilestoneHistory() {
        JSONArray milestones = host.storage.getArray(host.storage.key("therapy", host.currentUser.id, "milestoneData"));
        LinearLayout content = Ui.v(host, 0);
        content.setPadding(Ui.dp(host, 12), 0, Ui.dp(host, 12), 0);
        if (milestones.length() == 0) {
            content.addView(Ui.muted(host, host.i18n.t("No milestones logged yet.")), Ui.matchWrap());
        } else {
            for (int i = milestones.length() - 1; i >= 0; i--) {
                JSONObject item = milestones.optJSONObject(i);
                if (item == null)
                    continue;
                String detail = host.i18n.t(item.optString("categoryTitle")) + "\n" + host.displayDateTime(item.optString("date"));
                if (!item.optString("supportLevel").isEmpty()) {
                    detail += "\n" + item.optString("supportLevel");
                }
                View row = Ui.cardRow(host, item.optString("milestone"), detail, host.therapyIcon(item.optString("categoryID")));
                row.setOnClickListener(v -> host.showMilestoneDetail(item));
                content.addView(row, Ui.matchWrap());
                Ui.addSpacer(host, content, 8);
            }
        }
        Ui.dialog(host, host.i18n.t("History"), content, host.i18n.t("Done"), null);
    }

    void showMilestoneDetail(JSONObject item) {
        LinearLayout content = Ui.v(host, 0);
        content.setPadding(Ui.dp(host, 12), 0, Ui.dp(host, 12), 0);
        content.addView(Ui.cardRow(host, host.i18n.t("Date"), host.displayDateTime(item.optString("date")), "🗓"), Ui.matchWrap());
        Ui.addSpacer(host, content, 8);
        content.addView(Ui.cardRow(host, host.i18n.t("Therapy"), host.i18n.t(item.optString("categoryTitle")), host.therapyIcon(item.optString("categoryID"))), Ui.matchWrap());
        if (!item.optString("supportLevel").isEmpty()) {
            Ui.addSpacer(host, content, 8);
            content.addView(Ui.cardRow(host, host.i18n.t("Support level"), item.optString("supportLevel"), "✓"), Ui.matchWrap());
        }
        if (!item.optString("notes").isEmpty()) {
            Ui.addSpacer(host, content, 8);
            content.addView(Ui.cardRow(host, host.i18n.t("Notes"), item.optString("notes"), "📝"), Ui.matchWrap());
        }
        Ui.dialog(host, host.therapyIcon(item.optString("categoryID")) + " " + item.optString("milestone"), content, host.i18n.t("Done"), null);
    }
}
