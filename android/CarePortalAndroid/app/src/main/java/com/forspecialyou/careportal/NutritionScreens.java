package com.forspecialyou.careportal;

import android.content.Intent;
import android.graphics.Bitmap;
import android.graphics.Color;
import android.provider.MediaStore;
import android.text.InputType;
import android.view.Gravity;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.EditText;
import android.widget.FrameLayout;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;
import java.util.Date;
import java.util.Locale;

final class NutritionScreens {

    private final MainActivity host;

    NutritionScreens(MainActivity host) {
        this.host = host;
    }

    View nutrientView() {
        LinearLayout screen = Ui.screen(host);
        LinearLayout nutrientHeader = Ui.v(host, 0);
        LinearLayout titleRow = Ui.h(host, 0);
        ImageView nutrientIcon = host.symbolIcon(R.drawable.ios_icon_leaf, AppColors.ACCENT, Color.TRANSPARENT, 44, 0);
        titleRow.addView(nutrientIcon, Ui.fixed(host, 44, 44));
        TextView nutrientTitle = Ui.title(host, host.i18n.t("Nutrient"));
        LinearLayout.LayoutParams nutrientTitleParams = new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1);
        nutrientTitleParams.leftMargin = Ui.dp(host, 10);
        titleRow.addView(nutrientTitle, nutrientTitleParams);
        FrameLayout topHistory = new FrameLayout(host);
        topHistory.setBackground(Ui.round(Ui.withAlpha(AppColors.ACCENT, 22), Ui.dp(host, 16)));
        topHistory.setClickable(true);
        topHistory.setFocusable(true);
        topHistory.addView(host.symbolIcon(R.drawable.ios_icon_clock_arrow, AppColors.ACCENT, Color.TRANSPARENT, 25, 2), new FrameLayout.LayoutParams(Ui.dp(host, 34), Ui.dp(host, 34), Gravity.CENTER));
        topHistory.setOnClickListener(v -> host.showMealHistory());
        titleRow.addView(topHistory, Ui.fixed(host, 56, 50));
        nutrientHeader.addView(titleRow, Ui.matchWrap());
        Ui.addSpacer(host, nutrientHeader, 6);
        nutrientHeader.addView(Ui.muted(host, host.i18n.t("Estimate meals, hydration, safe foods, and feeding patterns.")), Ui.matchWrap());
        screen.addView(nutrientHeader, Ui.matchWrap());
        Ui.addSpacer(host, screen, 14);
        LinearLayout manual = Ui.h(host, 0);
        manual.setPadding(Ui.dp(host, 16), Ui.dp(host, 14), Ui.dp(host, 16), Ui.dp(host, 14));
        manual.setBackground(Ui.round(AppColors.PANEL, Ui.dp(host, 14)));
        ImageView manualIcon = host.symbolIcon(R.drawable.ios_icon_square_pencil, AppColors.PANEL, AppColors.ACCENT, 48, 12);
        manual.addView(manualIcon, Ui.fixed(host, 48, 48));
        TextView manualLabel = Ui.text(host, host.i18n.t("Add Meal Manually"), 18, AppColors.TEXT, android.graphics.Typeface.BOLD);
        LinearLayout.LayoutParams manualLabelParams = new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1);
        manualLabelParams.leftMargin = Ui.dp(host, 12);
        manual.addView(manualLabel, manualLabelParams);
        manual.addView(host.symbolIcon(R.drawable.ios_icon_chevron_right, AppColors.MUTED, Color.TRANSPARENT, 26, 2), Ui.fixed(host, 26, 26));
        manual.setOnClickListener(v -> host.showManualMealDialog());
        screen.addView(manual, Ui.matchWrap());
        Ui.addSpacer(host, screen, 14);
        LinearLayout panel = Ui.panel(host);
        JSONObject usage = host.dailyUsage();
        int limit = host.storage.getInt(host.storage.key("nutrient", host.currentUser.id, "dailyEstimateLimit"), 3);
        int left = Math.max(0, limit - usage.optInt("estimateCount"));
        panel.addView(host.nutrientQuotaPill(left, limit), Ui.matchWrap());
        Ui.addSpacer(host, panel, 22);
        LinearLayout goals = host.nutrientGoalsRow();
        panel.addView(goals, Ui.matchWrap());
        Ui.addSpacer(host, panel, 24);
        panel.addView(host.mealPhotoUploadCard(), Ui.matchWrap());
        Ui.addSpacer(host, panel, 14);
        boolean canEstimate = !host.selectedMealPhotoDataUrl.isEmpty() && usage.optInt("estimateCount") < limit && !host.isLoading;
        LinearLayout estimate = host.nutrientActionButton(host.isLoading ? host.i18n.t("Estimating...") : host.i18n.t("Estimate Nutrients"), R.drawable.ios_icon_sparkles, AppColors.ACCENT, AppColors.PANEL, true);
        estimate.setEnabled(canEstimate);
        estimate.setAlpha(canEstimate ? 1f : 0.46f);
        estimate.setOnClickListener(canEstimate ? v -> host.estimateMeal() : null);
        panel.addView(estimate, Ui.matchWrap());
        Ui.addSpacer(host, panel, 14);
        host.addMessage(panel);
        panel.addView(host.nutrientSummaryView(), Ui.matchWrap());
        if (host.currentMealEstimate != null) {
            Ui.addSpacer(host, panel, 14);
            Button save = Ui.primary(host, host.hasSavedCurrentMeal ? host.i18n.t("Saved") : host.i18n.t("Save Meal"));
            save.setEnabled(!host.hasSavedCurrentMeal);
            save.setOnClickListener(v -> host.saveCurrentMeal());
            panel.addView(save, Ui.matchWrap());
            Ui.addSpacer(host, panel, 10);
            panel.addView(host.mealEstimateView(host.currentMealEstimate), Ui.matchWrap());
        }
        screen.addView(panel, Ui.matchWrap());
        return Ui.scroll(host, screen);
    }

    LinearLayout nutrientQuotaPill(int left, int limit) {
        int color = left == 0 ? AppColors.DANGER : AppColors.ACCENT;
        int fill = left == 0 ? Color.rgb(255, 224, 229) : (left == limit ? Color.rgb(224, 240, 232) : Color.rgb(255, 239, 204));
        LinearLayout pill = Ui.h(host, 0);
        pill.setGravity(Gravity.CENTER);
        pill.setPadding(Ui.dp(host, 18), Ui.dp(host, 9), Ui.dp(host, 18), Ui.dp(host, 9));
        pill.setBackground(Ui.round(fill, Ui.dp(host, 22)));
        ImageView icon = host.symbolIcon(R.drawable.ios_icon_sparkles, color, Color.TRANSPARENT, 18, 1);
        pill.addView(icon, Ui.fixed(host, 20, 20));
        Ui.addSpacerHorizontal(host, pill, 8);
        pill.addView(Ui.text(host, host.i18n.t("Estimates Left Today") + "  " + left + "/" + limit, 14, color, android.graphics.Typeface.BOLD), Ui.wrapWrap());
        return pill;
    }

    LinearLayout nutrientGoalsRow() {
        LinearLayout row = Ui.h(host, 0);
        row.setGravity(Gravity.CENTER_VERTICAL);
        row.setPadding(Ui.dp(host, 2), Ui.dp(host, 8), Ui.dp(host, 0), Ui.dp(host, 8));
        row.setClickable(true);
        row.setFocusable(true);
        row.setOnClickListener(v -> host.showMessageSheet(host.i18n.t("Nutrition Goals"), host.i18n.t("Nutrition goals can be reviewed here.")));
        TextView label = Ui.text(host, host.i18n.t("View Nutrition Goals"), 20, AppColors.ACCENT, android.graphics.Typeface.BOLD);
        row.addView(label, new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1));
        row.addView(host.symbolIcon(R.drawable.ios_icon_chevron_right, AppColors.MUTED, Color.TRANSPARENT, 32, 3), Ui.fixed(host, 32, 32));
        return row;
    }

    View mealPhotoUploadCard() {
        FrameLayout card = new FrameLayout(host);
        card.setMinimumHeight(Ui.dp(host, 248));
        card.setBackground(Ui.round(AppColors.FIELD, Ui.dp(host, 18)));
        card.setClickable(true);
        card.setFocusable(true);
        card.setOnClickListener(v -> host.chooseMealPhoto());
        Bitmap bitmap = host.bitmapFromDataUrl(host.selectedMealPhotoDataUrl);
        if (bitmap != null) {
            ImageView image = new ImageView(host);
            image.setImageBitmap(bitmap);
            image.setScaleType(ImageView.ScaleType.CENTER_CROP);
            card.addView(image, new FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, Ui.dp(host, 248), Gravity.CENTER));
        } else {
            LinearLayout empty = Ui.v(host, 0);
            empty.setGravity(Gravity.CENTER);
            ImageView camera = host.symbolIcon(R.drawable.ios_icon_camera_viewfinder, AppColors.ACCENT, Color.TRANSPARENT, 58, 6);
            empty.addView(camera, Ui.fixed(host, 58, 58));
            Ui.addSpacer(host, empty, 10);
            TextView title = Ui.text(host, host.i18n.t("Upload Meal Photo"), 20, AppColors.TEXT, android.graphics.Typeface.BOLD);
            title.setGravity(Gravity.CENTER);
            empty.addView(title, Ui.matchWrap());
            Ui.addSpacer(host, empty, 8);
            TextView subtitle = Ui.text(host, host.i18n.t("Breakfast, lunch, dinner, or snack"), 14, AppColors.MUTED, android.graphics.Typeface.BOLD);
            subtitle.setGravity(Gravity.CENTER);
            empty.addView(subtitle, Ui.matchWrap());
            card.addView(empty, new FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, Ui.dp(host, 248), Gravity.CENTER));
        }
        ImageView add = host.symbolIcon(host.selectedMealPhotoDataUrl.isEmpty() ? R.drawable.ios_icon_plus : R.drawable.ios_icon_camera_fill, AppColors.PANEL, AppColors.ACCENT, 48, 13);
        FrameLayout.LayoutParams addParams = new FrameLayout.LayoutParams(Ui.dp(host, 48), Ui.dp(host, 48), Gravity.BOTTOM | Gravity.RIGHT);
        addParams.setMargins(0, 0, Ui.dp(host, 18), Ui.dp(host, 18));
        card.addView(add, addParams);
        LinearLayout.LayoutParams cardParams = Ui.matchWrap();
        cardParams.height = Ui.dp(host, 248);
        card.setLayoutParams(cardParams);
        return card;
    }

    LinearLayout nutrientActionButton(String title, int iconRes, int fillColor, int textColor, boolean primary) {
        LinearLayout button = Ui.h(host, 0);
        button.setGravity(Gravity.CENTER);
        button.setPadding(Ui.dp(host, 18), Ui.dp(host, 17), Ui.dp(host, 18), Ui.dp(host, 17));
        button.setBackground(primary ? Ui.round(fillColor, Ui.dp(host, 12)) : Ui.stroke(fillColor, AppColors.BORDER, Ui.dp(host, 12)));
        button.setClickable(true);
        button.setFocusable(true);
        ImageView icon = host.symbolIcon(iconRes, textColor, Color.TRANSPARENT, 22, 2);
        button.addView(icon, Ui.fixed(host, 24, 24));
        Ui.addSpacerHorizontal(host, button, 10);
        button.addView(Ui.text(host, title, 18, textColor, android.graphics.Typeface.BOLD), Ui.wrapWrap());
        return button;
    }

    LinearLayout nutrientSummaryView() {
        JSONArray meals = host.storage.getArray(host.storage.key("nutrient", host.currentUser.id, "savedMealHistoryData"));
        JSONObject latestEstimate = null;
        for (int i = meals.length() - 1; i >= 0; i--) {
            JSONObject meal = meals.optJSONObject(i);
            if (meal == null)
                continue;
            latestEstimate = meal.optJSONObject("estimate");
            if (latestEstimate != null)
                break;
        }
        LinearLayout summary = Ui.v(host, 0);
        summary.setPadding(Ui.dp(host, 2), Ui.dp(host, 4), Ui.dp(host, 2), Ui.dp(host, 2));
        String mealCount = meals.length() + " " + host.i18n.t("analyzed");
        String calories = latestEstimate == null ? "--" : host.nutrientValue(latestEstimate.optString("calories", "--"), "kcal");
        String macros = "--";
        if (latestEstimate != null) {
            String protein = host.nutrientValue(latestEstimate.optString("protein", "--"), "g");
            String carbs = host.nutrientValue(latestEstimate.optString("carbs", "--"), "g");
            String fats = host.nutrientValue(latestEstimate.optString("fats", latestEstimate.optString("fat", "--")), "g");
            macros = "P " + protein + " · C " + carbs + " · F " + fats;
        }
        summary.addView(host.nutrientSummaryRow(R.drawable.ios_icon_fork_knife, "--", mealCount), Ui.matchWrap());
        Ui.addSpacer(host, summary, 8);
        summary.addView(host.nutrientSummaryRow(R.drawable.ios_icon_flame, "--", calories), Ui.matchWrap());
        Ui.addSpacer(host, summary, 8);
        summary.addView(host.nutrientSummaryRow(R.drawable.ios_icon_chart_pie, "--", macros), Ui.matchWrap());
        return summary;
    }

    LinearLayout nutrientSummaryRow(int iconRes, String label, String value) {
        LinearLayout row = Ui.h(host, 0);
        row.setGravity(Gravity.CENTER_VERTICAL);
        row.setPadding(Ui.dp(host, 6), Ui.dp(host, 2), Ui.dp(host, 6), Ui.dp(host, 2));
        ImageView icon = host.symbolIcon(iconRes, AppColors.ACCENT, Color.TRANSPARENT, 28, 1);
        row.addView(icon, Ui.fixed(host, 32, 32));
        Ui.addSpacerHorizontal(host, row, 16);
        TextView title = Ui.text(host, label, 20, AppColors.TEXT, android.graphics.Typeface.BOLD);
        row.addView(title, new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1));
        TextView val = Ui.text(host, value, 20, AppColors.MUTED, android.graphics.Typeface.NORMAL);
        val.setGravity(Gravity.RIGHT);
        row.addView(val, new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1));
        return row;
    }

    String nutrientValue(String raw, String unit) {
        if (raw == null)
            return "--";
        String value = raw.trim();
        if (value.isEmpty() || value.equals("--"))
            return "--";
        String lower = value.toLowerCase(Locale.US);
        if (lower.contains(unit.toLowerCase(Locale.US)))
            return value;
        return value + " " + unit;
    }

    void chooseMealPhoto() {
        host.showChoiceSheet(host.i18n.t("Meal Photo"), new String[] { host.i18n.t("Choose Photo"), host.i18n.t("Take Photo") }, (which, sheet) -> {
            sheet.dismiss();
            if (which == 0) {
                host.chooseMealPhotoFromLibrary();
            } else {
                host.takeMealPhoto();
            }
        });
    }

    void chooseMealPhotoFromLibrary() {
        Intent intent = new Intent(Intent.ACTION_GET_CONTENT);
        intent.setType("image/*");
        host.startActivityForResult(Intent.createChooser(intent, host.i18n.t("Choose Photo")), host.REQUEST_MEAL_PHOTO);
    }

    void takeMealPhoto() {
        try {
            Intent intent = new Intent(MediaStore.ACTION_IMAGE_CAPTURE);
            host.startActivityForResult(intent, host.REQUEST_MEAL_CAMERA);
        } catch (Exception e) {
            host.showError(host.i18n.t("Camera is not available."));
            host.render();
        }
    }

    void refreshNutrientQuota() {
        if (host.currentUser == null)
            return;
        final int userId = host.currentUser.id;
        host.api.appSettings(userId, new AuthApi.Callback<JSONObject>() {

            @Override
            public void onSuccess(JSONObject result) {
                host.storage.putInt(host.storage.key("nutrient", userId, "dailyEstimateLimit"), result.optInt("nutrientDailyLimit", 3));
                JSONObject usage = result.optJSONObject("nutrientDailyUsage");
                if (usage != null)
                    host.storage.putObject(host.storage.key("nutrient", userId, "dailyUsageData"), usage);
                if (host.currentUser != null && host.currentUser.id == userId)
                    host.render();
            }

            @Override
            public void onError(String message) {
                host.showError(message);
            }
        });
    }

    void estimateMeal() {
        int limit = host.storage.getInt(host.storage.key("nutrient", host.currentUser.id, "dailyEstimateLimit"), 3);
        JSONObject usage = host.dailyUsage();
        if (usage.optInt("estimateCount") >= limit) {
            host.showError(String.format(Locale.US, host.i18n.t("Daily nutrient estimate limit reached with limit %s."), String.valueOf(limit)));
            host.render();
            return;
        }
        host.isLoading = true;
        host.clearMessage();
        host.render();
        host.api.analyzeMeal(host.selectedMealPhotoDataUrl, host.i18n.apiLanguageName(), new AuthApi.Callback<JSONObject>() {

            @Override
            public void onSuccess(JSONObject value) {
                host.isLoading = false;
                host.currentMealEstimate = value;
                host.refreshNutrientQuota();
                host.hasSavedCurrentMeal = false;
                host.render();
            }

            @Override
            public void onError(String msg) {
                host.isLoading = false;
                host.refreshNutrientQuota();
                host.showError(msg);
                host.render();
            }
        });
    }

    LinearLayout mealEstimateView(JSONObject estimate) {
        LinearLayout panel = Ui.panel(host);
        panel.setBackground(Ui.round(AppColors.FIELD, Ui.dp(host, 12)));
        panel.addView(Ui.sectionTitle(host, estimate.optString("mealName", "Meal")), Ui.matchWrap());
        Ui.addSpacer(host, panel, 8);
        panel.addView(host.infoRow("Calories", estimate.optString("calories", "--")), Ui.matchWrap());
        panel.addView(host.infoRow("Protein", estimate.optString("protein", "--")), Ui.matchWrap());
        panel.addView(host.infoRow("Carbs", estimate.optString("carbs", "--")), Ui.matchWrap());
        panel.addView(host.infoRow("Fats", estimate.optString("fats", estimate.optString("fat", "--"))), Ui.matchWrap());
        JSONArray notes = estimate.optJSONArray("notes");
        if (notes != null) {
            for (int i = 0; i < notes.length(); i++) {
                panel.addView(Ui.muted(host, "- " + notes.optString(i)), Ui.matchWrap());
            }
        }
        return panel;
    }

    void saveCurrentMeal() {
        if (host.currentMealEstimate == null)
            return;
        JSONArray meals = host.storage.getArray(host.storage.key("nutrient", host.currentUser.id, "savedMealHistoryData"));
        JSONObject meal = new JSONObject();
        try {
            meal.put("id", "android-" + System.currentTimeMillis());
            meal.put("savedAt", host.nowIso());
            meal.put("imageData", host.selectedMealPhotoDataUrl);
            meal.put("estimate", host.currentMealEstimate);
        } catch (JSONException ignored) {
        }
        meals.put(meal);
        host.storage.putArray(host.storage.key("nutrient", host.currentUser.id, "savedMealHistoryData"), meals);
        JSONArray backendMeals = new JSONArray();
        for (int i = 0; i < meals.length(); i++) {
            JSONObject copy = meals.optJSONObject(i);
            if (copy == null)
                continue;
            JSONObject safe = new JSONObject();
            try {
                safe.put("id", copy.optString("id"));
                safe.put("savedAt", copy.optString("savedAt"));
                safe.put("imageData", "");
                safe.put("estimate", copy.optJSONObject("estimate"));
            } catch (JSONException ignored) {
            }
            backendMeals.put(safe);
        }
        host.api.syncAppData(host.currentUser.id, null, null, backendMeals, null);
        host.selectedMealPhotoDataUrl = "";
        host.currentMealEstimate = null;
        host.hasSavedCurrentMeal = true;
        host.message = host.i18n.t("Meal saved to history.");
        host.isError = false;
        host.render();
    }

    void showManualMealDialog() {
        LinearLayout content = Ui.v(host, 0);
        content.setPadding(Ui.dp(host, 12), 0, Ui.dp(host, 12), 0);
        String[] photoData = { "" };
        EditText name = Ui.edit(host, "Meal");
        EditText calories = Ui.edit(host, "Calories");
        calories.setInputType(InputType.TYPE_CLASS_NUMBER);
        EditText protein = Ui.edit(host, "Protein");
        EditText carbs = Ui.edit(host, "Carbs");
        EditText fats = Ui.edit(host, "Fats");
        content.addView(Ui.fieldGroup(host, "Meal", name), Ui.matchWrap());
        Ui.addSpacer(host, content, 10);
        content.addView(Ui.fieldGroup(host, "Calories", calories), Ui.matchWrap());
        Ui.addSpacer(host, content, 10);
        content.addView(Ui.fieldGroup(host, "Protein", protein), Ui.matchWrap());
        Ui.addSpacer(host, content, 10);
        content.addView(Ui.fieldGroup(host, "Carbs", carbs), Ui.matchWrap());
        Ui.addSpacer(host, content, 10);
        content.addView(Ui.fieldGroup(host, "Fats", fats), Ui.matchWrap());
        Ui.addSpacer(host, content, 10);
        content.addView(host.photoControls("Meal Photo", photoData), Ui.matchWrap());
        Ui.dialog(host, host.i18n.t("Add Meal Manually"), content, host.i18n.t("Save"), () -> {
            JSONObject estimate = new JSONObject();
            try {
                estimate.put("mealName", name.getText().toString().trim());
                estimate.put("calories", calories.getText().toString().trim());
                estimate.put("protein", protein.getText().toString().trim());
                estimate.put("carbs", carbs.getText().toString().trim());
                estimate.put("fats", fats.getText().toString().trim());
            } catch (JSONException ignored) {
            }
            host.currentMealEstimate = estimate;
            host.selectedMealPhotoDataUrl = photoData[0];
            host.saveCurrentMeal();
            host.message = host.i18n.t("Manual meal saved to history.");
            host.isError = false;
            host.render();
        });
    }

    void showMealHistory() {
        JSONArray meals = host.storage.getArray(host.storage.key("nutrient", host.currentUser.id, "savedMealHistoryData"));
        LinearLayout content = Ui.v(host, 0);
        content.setPadding(Ui.dp(host, 12), 0, Ui.dp(host, 12), 0);
        if (meals.length() == 0) {
            content.addView(Ui.muted(host, host.i18n.t("No records yet.")), Ui.matchWrap());
        } else {
            for (int i = meals.length() - 1; i >= 0; i--) {
                JSONObject meal = meals.optJSONObject(i);
                if (meal == null)
                    continue;
                JSONObject estimate = meal.optJSONObject("estimate");
                String title = estimate == null ? host.i18n.t("Meal") : estimate.optString("mealName", host.i18n.t("Meal"));
                String detail = host.displayDateTime(meal.optString("savedAt"));
                if (estimate != null) {
                    detail += "\n" + host.i18n.t("Calories") + ": " + estimate.optString("calories", "--");
                    detail += " · " + host.i18n.t("Protein") + ": " + estimate.optString("protein", "--");
                }
                if (!meal.optString("imageData").isEmpty()) {
                    detail += "\n" + host.i18n.t("Photo attached");
                }
                View row = Ui.cardRow(host, title, detail, "🍽");
                row.setOnClickListener(v -> host.showMealDetail(meal));
                content.addView(row, Ui.matchWrap());
                Ui.addSpacer(host, content, 8);
            }
        }
        Ui.dialog(host, host.i18n.t("Meal history"), content, host.i18n.t("Done"), null);
    }

    void showMealDetail(JSONObject meal) {
        JSONObject estimate = meal.optJSONObject("estimate");
        LinearLayout content = Ui.v(host, 0);
        content.setPadding(Ui.dp(host, 12), 0, Ui.dp(host, 12), 0);
        content.addView(Ui.cardRow(host, host.i18n.t("Date"), host.displayDateTime(meal.optString("savedAt")), "🗓"), Ui.matchWrap());
        Ui.addSpacer(host, content, 8);
        if (!meal.optString("imageData").isEmpty()) {
            content.addView(Ui.cardRow(host, host.i18n.t("Photo"), host.i18n.t("Photo attached"), "📷"), Ui.matchWrap());
            Ui.addSpacer(host, content, 8);
        }
        if (estimate != null) {
            content.addView(host.mealEstimateView(estimate), Ui.matchWrap());
        }
        String title = estimate == null ? host.i18n.t("Meal Details") : estimate.optString("mealName", host.i18n.t("Meal Details"));
        Ui.dialog(host, "🍽 " + title, content, host.i18n.t("Done"), null);
    }
}
