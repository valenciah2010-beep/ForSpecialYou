package com.forspecialyou.careportal;

import android.app.DatePickerDialog;
import android.content.Intent;
import android.graphics.Bitmap;
import android.graphics.Color;
import android.net.Uri;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.EditText;
import android.widget.GridLayout;
import android.widget.HorizontalScrollView;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;
import java.util.Calendar;

final class TherapyScreens {

    private final MainActivity host;

    TherapyScreens(MainActivity host) {
        this.host = host;
    }

    View therapyView() {
        LinearLayout screen = Ui.screen(host);
        LinearLayout header = Ui.v(host, 0);
        LinearLayout titleRow = Ui.h(host, 0);
        ImageView icon = host.therapyIconView("therapySession", AppColors.PANEL, AppColors.ACCENT, 48, 11);
        titleRow.addView(icon, Ui.fixed(host, 48, 48));
        TextView title = Ui.title(host, host.i18n.t("Therapy"));
        LinearLayout.LayoutParams titleParams = new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1);
        titleParams.leftMargin = Ui.dp(host, 12);
        titleRow.addView(title, titleParams);
        header.addView(titleRow, Ui.matchWrap());
        Ui.addSpacer(host, header, 6);
        header.addView(Ui.muted(host, "Schedule and review therapy sessions."), Ui.matchWrap());
        screen.addView(header, Ui.matchWrap());
        Ui.addSpacer(host, screen, 18);

        LinearLayout schedule = Ui.panel(host);
        LinearLayout scheduleHeader = Ui.h(host, 0);
        scheduleHeader.addView(Ui.sectionTitle(host, "Therapy Schedule"), new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1));
        TextView add = host.iconCircle("+", AppColors.PANEL, AppColors.ACCENT, 42);
        add.setOnClickListener(v -> showTherapySessionDialog(host.THERAPY_CATEGORIES[0]));
        scheduleHeader.addView(add, Ui.fixed(host, 42, 42));
        schedule.addView(scheduleHeader, Ui.matchWrap());
        JSONArray sessions = host.storage.getArray(host.storage.key("therapy", host.currentUser.id, "sessionData"));
        if (sessions.length() == 0) {
            Ui.addSpacer(host, schedule, 8);
            schedule.addView(Ui.muted(host, "No therapy sessions scheduled yet."), Ui.matchWrap());
        } else {
            for (int i = Math.max(0, sessions.length() - 3); i < sessions.length(); i++) {
                JSONObject session = sessions.optJSONObject(i);
                if (session == null) continue;
                Ui.addSpacer(host, schedule, 10);
                schedule.addView(Ui.cardRow(host, session.optString("title"), host.displayDateTime(session.optString("date")), host.therapyIcon(session.optString("categoryID"))), Ui.matchWrap());
            }
        }
        screen.addView(schedule, Ui.matchWrap());
        Ui.addSpacer(host, screen, 22);
        screen.addView(Ui.sectionTitle(host, "Add Therapy Session"), Ui.matchWrap());
        Ui.addSpacer(host, screen, 12);
        GridLayout categories = Ui.grid(host, 2);
        for (String[] category : host.THERAPY_CATEGORIES) {
            View button = therapySessionButton(category);
            button.setOnClickListener(v -> showTherapySessionDialog(category));
            Ui.addGridChildFixedHeight(host, categories, button, 88);
        }
        screen.addView(categories, Ui.matchWrap());
        return Ui.scroll(host, screen);
    }

    View milestonesView() {
        LinearLayout screen = Ui.screen(host);
        screen.addView(host.therapyHeader(), Ui.matchWrap());
        Ui.addSpacer(host, screen, 16);
        JSONArray milestones = host.storage.getArray(host.storage.key("therapy", host.currentUser.id, "milestoneData"));

        LinearLayout recent = Ui.panel(host);
        LinearLayout recentHeader = Ui.h(host, 0);
        recentHeader.addView(Ui.sectionTitle(host, host.i18n.t("Recent Milestones")), new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1));
        Button history = Ui.secondary(host, host.i18n.t("History"));
        host.setButtonSymbol(history, R.drawable.ios_icon_chart_line_uptrend, AppColors.ACCENT, 18);
        history.setOnClickListener(v -> host.showMilestoneHistory());
        recentHeader.addView(history, Ui.wrapWrap());
        recent.addView(recentHeader, Ui.matchWrap());
        Ui.addSpacer(host, recent, 12);
        if (milestones.length() == 0) {
            recent.addView(Ui.muted(host, host.i18n.t("No milestones logged yet.")), Ui.matchWrap());
        } else {
            JSONObject latest = milestones.optJSONObject(milestones.length() - 1);
            if (latest != null) {
                View card = recentMilestoneCard(latest);
                card.setOnClickListener(v -> host.showMilestoneDetail(latest));
                recent.addView(card, Ui.matchWrap());
            }
        }
        screen.addView(recent, Ui.matchWrap());
        Ui.addSpacer(host, screen, 22);

        screen.addView(Ui.sectionTitle(host, host.i18n.t("Log a Milestone!")), Ui.matchWrap());
        Ui.addSpacer(host, screen, 12);
        HorizontalScrollView scroller = new HorizontalScrollView(host);
        scroller.setHorizontalScrollBarEnabled(true);
        scroller.setScrollbarFadingEnabled(false);
        LinearLayout categories = Ui.h(host, 0);
        for (String[] category : host.THERAPY_CATEGORIES) {
            LinearLayout card = milestoneCategoryCard(category);
            card.setOnClickListener(v -> host.showMilestoneDialog(category));
            LinearLayout.LayoutParams cardParams = Ui.fixed(host, 188, 186);
            cardParams.rightMargin = Ui.dp(host, 12);
            categories.addView(card, cardParams);
        }
        scroller.addView(categories, new HorizontalScrollView.LayoutParams(ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT));
        screen.addView(scroller, Ui.matchWrap());
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

    private void showTherapySessionDialog(String[] category) {
        LinearLayout content = Ui.v(host, 0);
        content.setPadding(Ui.dp(host, 12), 0, Ui.dp(host, 12), 0);
        Calendar date = Calendar.getInstance();
        EditText name = Ui.edit(host, "Session name");
        content.addView(Ui.fieldGroup(host, "Session", name), Ui.matchWrap());
        Ui.addSpacer(host, content, 12);
        content.addView(Ui.text(host, "Therapy Type", 14, AppColors.TEXT, android.graphics.Typeface.BOLD), Ui.matchWrap());
        Ui.addSpacer(host, content, 8);
        content.addView(Ui.text(host, host.i18n.t(category[1]), 18, host.therapyColor(category[0]), android.graphics.Typeface.BOLD), Ui.matchWrap());
        Ui.addSpacer(host, content, 12);
        Button dateButton = Ui.secondary(host, host.formatDisplayDate(date));
        dateButton.setOnClickListener(v -> new DatePickerDialog(host, (view, year, month, day) -> {
            date.set(Calendar.YEAR, year);
            date.set(Calendar.MONTH, month);
            date.set(Calendar.DAY_OF_MONTH, day);
            dateButton.setText(host.formatDisplayDate(date));
        }, date.get(Calendar.YEAR), date.get(Calendar.MONTH), date.get(Calendar.DAY_OF_MONTH)).show());
        content.addView(Ui.text(host, host.i18n.t("Date"), 14, AppColors.TEXT, android.graphics.Typeface.BOLD), Ui.matchWrap());
        Ui.addSpacer(host, content, 8);
        content.addView(dateButton, Ui.matchWrap());
        Ui.dialog(host, "Add Therapy Session", content, host.i18n.t("Save"), () -> {
            String cleanName = name.getText().toString().trim();
            if (cleanName.isEmpty()) return;
            JSONArray sessions = host.storage.getArray(host.storage.key("therapy", host.currentUser.id, "sessionData"));
            JSONObject item = new JSONObject();
            try {
                item.put("id", "android-session-" + System.currentTimeMillis());
                item.put("title", cleanName);
                item.put("categoryID", category[0]);
                item.put("date", host.formatIso(date));
            } catch (JSONException ignored) {
            }
            sessions.put(item);
            host.storage.putArray(host.storage.key("therapy", host.currentUser.id, "sessionData"), sessions);
            host.render();
        });
    }

    LinearLayout milestoneCategoryCard(String[] category) {
        int color = host.therapyColor(category[0]);
        LinearLayout card = Ui.v(host, 0);
        card.setPadding(Ui.dp(host, 16), Ui.dp(host, 16), Ui.dp(host, 16), Ui.dp(host, 16));
        card.setMinimumHeight(Ui.dp(host, 186));
        card.setClickable(true);
        card.setFocusable(true);
        card.setBackground(Ui.stroke(Ui.withAlpha(color, 34), Ui.withAlpha(color, 78), Ui.dp(host, 14)));
        LinearLayout top = Ui.h(host, 0);
        ImageView icon = host.therapyIconView(category[0], AppColors.PANEL, color, 48, 12);
        top.addView(icon, Ui.fixed(host, 48, 48));
        card.addView(top, Ui.matchWrap());
        Ui.addSpacer(host, card, 20);
        card.addView(Ui.text(host, host.i18n.t(category[1]), 20, AppColors.TEXT, android.graphics.Typeface.BOLD), Ui.matchWrap());
        Ui.addSpacer(host, card, 10);
        card.addView(Ui.muted(host, host.i18n.t(category[2])), Ui.matchWrap());
        return card;
    }

    LinearLayout therapyCard(String[] category, int ignoredCount) {
        return milestoneCategoryCard(category);
    }

    LinearLayout therapyHeader() {
        LinearLayout header = Ui.v(host, 0);
        LinearLayout row = Ui.h(host, 0);
        TextView icon = Ui.text(host, "★", 40, AppColors.ACCENT, android.graphics.Typeface.BOLD);
        icon.setGravity(android.view.Gravity.CENTER);
        row.addView(icon, Ui.fixed(host, 48, 48));
        TextView title = Ui.title(host, host.i18n.t("Milestones"));
        LinearLayout.LayoutParams titleParams = new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1);
        titleParams.leftMargin = Ui.dp(host, 12);
        row.addView(title, titleParams);
        header.addView(row, Ui.matchWrap());
        Ui.addSpacer(host, header, 6);
        header.addView(Ui.muted(host, host.i18n.t("Log milestones and wins to see your child's progress over time.")), Ui.matchWrap());
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
            case "other":
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
            case "other":
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
            case "other":
                return Color.rgb(119, 190, 120);
            default:
                return AppColors.ACCENT;
        }
    }

    void showMilestoneDialog(String[] category) {
        LinearLayout content = Ui.v(host, 0);
        content.setPadding(Ui.dp(host, 12), 0, Ui.dp(host, 12), 0);
        Calendar date = Calendar.getInstance();
        Button dateButton = Ui.secondary(host, host.formatDisplayDate(date));
        dateButton.setOnClickListener(v -> new DatePickerDialog(host, (view, year, month, day) -> {
            date.set(Calendar.YEAR, year);
            date.set(Calendar.MONTH, month);
            date.set(Calendar.DAY_OF_MONTH, day);
            dateButton.setText(host.formatDisplayDate(date));
        }, date.get(Calendar.YEAR), date.get(Calendar.MONTH), date.get(Calendar.DAY_OF_MONTH)).show());
        content.addView(Ui.text(host, host.i18n.t("Date"), 14, AppColors.TEXT, android.graphics.Typeface.BOLD), Ui.matchWrap());
        Ui.addSpacer(host, content, 8);
        content.addView(dateButton, Ui.matchWrap());
        Ui.addSpacer(host, content, 12);
        EditText milestone = Ui.multi(host, host.i18n.t("Example: Rode a scooter for the first time!"));
        content.addView(Ui.fieldGroup(host, host.i18n.t("Milestone or Achievement!"), milestone), Ui.matchWrap());
        Ui.addSpacer(host, content, 12);
        String[] photoData = { "" };
        String[] videoUri = { "" };
        TextView attachmentStatus = Ui.muted(host, host.i18n.t("Add a photo or video (videos: up to 30 seconds and 100 MB)."));
        Button attachment = Ui.secondary(host, host.i18n.t("Add Photo or Video"));
        attachment.setOnClickListener(v -> host.chooseMilestoneMedia(new MainActivity.MilestoneMediaCallback() {
            @Override public void onPhoto(String dataUrl) {
                photoData[0] = dataUrl;
                videoUri[0] = "";
                attachmentStatus.setText(host.i18n.t("Photo selected"));
            }
            @Override public void onVideo(String uri) {
                photoData[0] = "";
                videoUri[0] = uri;
                attachmentStatus.setText(host.i18n.t("Video selected"));
            }
            @Override public void onError(String message) {
                attachmentStatus.setText(message);
            }
        }));
        content.addView(attachment, Ui.matchWrap());
        Ui.addSpacer(host, content, 8);
        content.addView(attachmentStatus, Ui.matchWrap());
        Ui.dialog(host, host.i18n.t("Log a Milestone!"), content, host.i18n.t("Save"), () -> {
            String clean = milestone.getText().toString().trim();
            if (clean.isEmpty())
                return;
            JSONArray milestones = host.storage.getArray(host.storage.key("therapy", host.currentUser.id, "milestoneData"));
            JSONObject item = new JSONObject();
            try {
                item.put("id", "android-" + System.currentTimeMillis());
                item.put("categoryID", category[0]);
                item.put("categoryTitle", category[1]);
                item.put("date", host.formatIso(date));
                item.put("milestone", clean);
                item.put("achievement", clean);
                if (!photoData[0].isEmpty()) item.put("imageData", photoData[0]);
                if (!videoUri[0].isEmpty()) item.put("videoUri", videoUri[0]);
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
                View row = Ui.cardRow(host, milestoneText(item), detail, host.therapyIcon(item.optString("categoryID")));
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
        if (!item.optString("imageData").isEmpty()) {
            Ui.addSpacer(host, content, 8);
            ImageView image = new ImageView(host);
            image.setImageBitmap(host.bitmapFromDataUrl(item.optString("imageData")));
            image.setScaleType(ImageView.ScaleType.CENTER_CROP);
            image.setBackground(Ui.round(AppColors.FIELD, Ui.dp(host, 14)));
            content.addView(image, Ui.fixed(host, 240, 180));
        } else if (!item.optString("videoUri").isEmpty()) {
            Ui.addSpacer(host, content, 8);
            Button video = Ui.secondary(host, host.i18n.t("Play attached video"));
            video.setOnClickListener(v -> {
                Intent intent = new Intent(Intent.ACTION_VIEW, Uri.parse(item.optString("videoUri")));
                intent.setDataAndType(Uri.parse(item.optString("videoUri")), "video/*");
                try { host.startActivity(intent); } catch (Exception ignored) { }
            });
            content.addView(video, Ui.matchWrap());
        }
        Ui.dialog(host, host.therapyIcon(item.optString("categoryID")) + " " + milestoneText(item), content, host.i18n.t("Done"), null);
    }

    private String milestoneText(JSONObject item) {
        return item.optString("achievement", item.optString("milestone"));
    }

    private LinearLayout recentMilestoneCard(JSONObject item) {
        LinearLayout row = Ui.h(host, 0);
        row.setGravity(android.view.Gravity.CENTER_VERTICAL);
        row.setPadding(Ui.dp(host, 12), Ui.dp(host, 12), Ui.dp(host, 12), Ui.dp(host, 12));
        row.setBackground(Ui.round(AppColors.FIELD, Ui.dp(host, 12)));
        if (!item.optString("imageData").isEmpty()) {
            ImageView image = new ImageView(host);
            image.setImageBitmap(host.bitmapFromDataUrl(item.optString("imageData")));
            image.setScaleType(ImageView.ScaleType.CENTER_CROP);
            image.setBackground(Ui.round(Ui.withAlpha(host.therapyColor(item.optString("categoryID")), 28), Ui.dp(host, 26)));
            row.addView(image, Ui.fixed(host, 52, 52));
        } else {
            String icon = item.optString("videoUri").isEmpty() ? host.therapyIcon(item.optString("categoryID")) : "▶";
            row.addView(host.iconCircle(icon, host.therapyColor(item.optString("categoryID")), Ui.withAlpha(host.therapyColor(item.optString("categoryID")), 28), 52), Ui.fixed(host, 52, 52));
        }
        LinearLayout text = Ui.v(host, 0);
        TextView category = Ui.text(host, host.i18n.t(item.optString("categoryTitle")), 13, host.therapyColor(item.optString("categoryID")), android.graphics.Typeface.BOLD);
        text.addView(category, Ui.matchWrap());
        TextView title = Ui.text(host, milestoneText(item), 16, AppColors.TEXT, android.graphics.Typeface.BOLD);
        title.setMaxLines(2);
        text.addView(title, Ui.matchWrap());
        LinearLayout.LayoutParams textParams = new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1);
        textParams.leftMargin = Ui.dp(host, 12);
        row.addView(text, textParams);
        TextView date = Ui.muted(host, host.displayDateTime(item.optString("date")));
        date.setGravity(android.view.Gravity.END);
        row.addView(date, Ui.wrapWrap());
        return row;
    }
}
