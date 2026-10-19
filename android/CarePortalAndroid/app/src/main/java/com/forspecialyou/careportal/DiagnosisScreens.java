package com.forspecialyou.careportal;

import android.app.Dialog;
import android.graphics.Color;
import android.text.Editable;
import android.text.TextWatcher;
import android.view.Gravity;
import android.view.MotionEvent;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.CheckBox;
import android.widget.EditText;
import android.widget.FrameLayout;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;
import java.util.ArrayList;
import java.util.Date;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;

final class DiagnosisScreens {

    private final MainActivity host;

    DiagnosisScreens(MainActivity host) {
        this.host = host;
    }

    View diagnosisView() {
        LinearLayout screen = Ui.screen(host);
        LinearLayout header = Ui.h(host, 0);
        ImageView diagnosisIcon = host.symbolIcon(R.drawable.ios_tab_diagnosis, AppColors.ACCENT, Color.TRANSPARENT, 42, 0);
        header.addView(diagnosisIcon, Ui.fixed(host, 42, 42));
        TextView diagnosisTitle = Ui.title(host, host.i18n.t("Diagnosis"));
        diagnosisTitle.setTextSize(34);
        LinearLayout.LayoutParams diagnosisTitleParams = new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1);
        diagnosisTitleParams.leftMargin = Ui.dp(host, 10);
        header.addView(diagnosisTitle, diagnosisTitleParams);
        TextView edit = Ui.text(host, host.i18n.t("Edit"), 16, AppColors.ACCENT, android.graphics.Typeface.BOLD);
        edit.setGravity(Gravity.CENTER);
        edit.setPadding(Ui.dp(host, 22), Ui.dp(host, 13), Ui.dp(host, 22), Ui.dp(host, 13));
        edit.setBackground(Ui.round(Ui.withAlpha(AppColors.ACCENT, 22), Ui.dp(host, 28)));
        edit.setClickable(true);
        edit.setFocusable(true);
        edit.setOnClickListener(v -> host.showDiagnosisCategoryDialog());
        header.addView(edit, Ui.wrapWrap());
        screen.addView(header, Ui.matchWrap());
        Ui.addSpacer(host, screen, 24);
        LinearLayout titleRow = Ui.h(host, 0);
        titleRow.setGravity(Gravity.CENTER_VERTICAL);
        TextView conditionsTitle = Ui.sectionTitle(host, host.i18n.t("Conditions"));
        conditionsTitle.setTextSize(24);
        titleRow.addView(conditionsTitle, new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1));
        TextView add = Ui.text(host, "+", 27, AppColors.ACCENT, android.graphics.Typeface.BOLD);
        add.setGravity(Gravity.CENTER);
        add.setBackground(Ui.round(Ui.withAlpha(AppColors.ACCENT, 22), Ui.dp(host, 23)));
        add.setClickable(true);
        add.setFocusable(true);
        add.setOnClickListener(v -> host.showConditionDialog(null, -1));
        titleRow.addView(add, Ui.fixed(host, 46, 46));
        screen.addView(titleRow, Ui.matchWrap());
        Ui.addSpacer(host, screen, 12);
        JSONArray conditions = host.storage.getArray(host.storage.key("diagnosis", host.currentUser.id, "conditions"));
        if (conditions.length() == 0) {
            screen.addView(Ui.muted(host, host.i18n.t("No conditions added yet.")), Ui.matchWrap());
        } else {
            for (int i = 0; i < conditions.length(); i++) {
                JSONObject item = conditions.optJSONObject(i);
                if (item == null)
                    continue;
                final int index = i;
                View row = host.diagnosisConditionSwipeRow(item, index);
                screen.addView(row, Ui.matchWrap());
                Ui.addSpacer(host, screen, 10);
            }
        }
        Ui.addSpacer(host, screen, 12);
        LinearLayout visit = host.diagnosisDoctorVisitButton();
        visit.setOnClickListener(v -> host.showDoctorVisitDialog());
        screen.addView(visit, Ui.matchWrap());
        Ui.addSpacer(host, screen, 16);
        host.addSelectedDiagnosis(screen);
        return Ui.scroll(host, screen);
    }

    FrameLayout diagnosisConditionSwipeRow(JSONObject item, int index) {
        FrameLayout container = new FrameLayout(host);
        container.setMinimumHeight(Ui.dp(host, 82));
        int actionButtonWidth = Ui.dp(host, 82);
        int actionGap = Ui.dp(host, 8);
        int actionWidth = actionButtonWidth * 2 + actionGap;
        LinearLayout actions = Ui.h(host, 0);
        actions.setGravity(Gravity.RIGHT | Gravity.CENTER_VERTICAL);
        actions.addView(host.conditionSwipeAction(host.i18n.t("Edit"), R.drawable.ic_swipe_edit, AppColors.ACCENT, () -> host.showConditionDialog(item, index)), Ui.fixed(host, 82, 82));
        Ui.addSpacerHorizontal(host, actions, 8);
        actions.addView(host.conditionSwipeAction(host.i18n.t("Delete"), R.drawable.ic_swipe_delete, Color.rgb(255, 55, 64), () -> host.deleteCondition(index)), Ui.fixed(host, 82, 82));
        FrameLayout.LayoutParams actionParams = new FrameLayout.LayoutParams(actionWidth, Ui.dp(host, 82), Gravity.RIGHT | Gravity.CENTER_VERTICAL);
        container.addView(actions, actionParams);
        LinearLayout card = host.diagnosisConditionCard(item);
        card.setOnClickListener(v -> host.showConditionDialog(item, index));
        FrameLayout.LayoutParams cardParams = new FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        container.addView(card, cardParams);
        host.enableSwipeReveal(card, actionWidth);
        return container;
    }

    LinearLayout conditionSwipeAction(String title, int iconRes, int color, Runnable action) {
        LinearLayout button = Ui.v(host, 0);
        button.setGravity(Gravity.CENTER);
        button.setPadding(Ui.dp(host, 8), Ui.dp(host, 9), Ui.dp(host, 8), Ui.dp(host, 9));
        button.setBackground(Ui.round(color, Ui.dp(host, 18)));
        button.setClickable(true);
        button.setFocusable(true);
        ImageView iconView = new ImageView(host);
        iconView.setImageResource(iconRes);
        iconView.setColorFilter(Color.WHITE);
        iconView.setAdjustViewBounds(true);
        button.addView(iconView, Ui.fixed(host, 28, 28));
        Ui.addSpacer(host, button, 4);
        TextView titleText = Ui.text(host, title, 15, Color.WHITE, android.graphics.Typeface.BOLD);
        titleText.setGravity(Gravity.CENTER);
        button.addView(titleText, Ui.matchWrap());
        button.setOnClickListener(v -> action.run());
        return button;
    }

    void enableSwipeReveal(View card, int actionWidth) {
        final float[] downX = { 0f };
        final float[] downY = { 0f };
        final float[] startTranslation = { 0f };
        final boolean[] swiping = { false };
        card.setOnTouchListener((v, event) -> {
            switch(event.getActionMasked()) {
                case MotionEvent.ACTION_DOWN:
                    downX[0] = event.getRawX();
                    downY[0] = event.getRawY();
                    startTranslation[0] = v.getTranslationX();
                    swiping[0] = false;
                    host.disallowParentIntercept(v, false);
                    return true;
                case MotionEvent.ACTION_MOVE:
                    float dx = event.getRawX() - downX[0];
                    float dy = event.getRawY() - downY[0];
                    if (!swiping[0] && Math.abs(dy) > Math.abs(dx) && Math.abs(dy) > Ui.dp(host, 8)) {
                        host.disallowParentIntercept(v, false);
                        return false;
                    }
                    if (Math.abs(dx) > Ui.dp(host, 6)) {
                        swiping[0] = true;
                        host.disallowParentIntercept(v, true);
                    }
                    if (swiping[0]) {
                        float next = startTranslation[0] + dx;
                        next = Math.min(0f, Math.max(-actionWidth, next));
                        v.setTranslationX(next);
                        return true;
                    }
                    return true;
                case MotionEvent.ACTION_UP:
                case MotionEvent.ACTION_CANCEL:
                    host.disallowParentIntercept(v, false);
                    if (!swiping[0]) {
                        if (event.getActionMasked() == MotionEvent.ACTION_UP && Math.abs(v.getTranslationX()) < 1f) {
                            v.performClick();
                        }
                        return true;
                    }
                    float target = v.getTranslationX() <= -actionWidth * 0.42f ? -actionWidth : 0f;
                    v.animate().translationX(target).setDuration(160).start();
                    return true;
                default:
                    return false;
            }
        });
    }

    void deleteCondition(int index) {
        JSONArray conditions = host.storage.getArray(host.storage.key("diagnosis", host.currentUser.id, "conditions"));
        if (index >= 0 && index < conditions.length()) {
            conditions.remove(index);
            host.storage.putArray(host.storage.key("diagnosis", host.currentUser.id, "conditions"), conditions);
            host.render();
        }
    }

    void addSelectedDiagnosis(LinearLayout screen) {
        String selected = host.storage.getString(host.storage.key("diagnosis", host.currentUser.id, "selectedOptions"), "");
        if (selected.trim().isEmpty()) {
            return;
        }
        Set<String> ids = host.commaSet(selected);
        for (String[] option : host.DIAGNOSIS_OPTIONS) {
            if (ids.contains(option[0])) {
                screen.addView(host.diagnosisCategoryCard(option), Ui.matchWrap());
                Ui.addSpacer(host, screen, 10);
            }
        }
        Ui.addSpacer(host, screen, 16);
    }

    LinearLayout diagnosisConditionCard(JSONObject item) {
        LinearLayout card = Ui.v(host, 0);
        card.setPadding(Ui.dp(host, 22), Ui.dp(host, 18), Ui.dp(host, 22), Ui.dp(host, 18));
        card.setMinimumHeight(Ui.dp(host, 82));
        card.setGravity(Gravity.CENTER_VERTICAL);
        card.setBackground(Ui.round(AppColors.PANEL, Ui.dp(host, 16)));
        card.setClickable(true);
        card.setFocusable(true);
        String category = host.conditionCategoryNames(item);
        if (!category.isEmpty()) {
            TextView categoryText = Ui.text(host, category, 13, AppColors.MUTED, android.graphics.Typeface.BOLD);
            categoryText.setAllCaps(true);
            card.addView(categoryText, Ui.matchWrap());
            Ui.addSpacer(host, card, 6);
        }
        TextView name = Ui.text(host, item.optString("name", "--"), 19, AppColors.TEXT, android.graphics.Typeface.BOLD);
        card.addView(name, Ui.matchWrap());
        return card;
    }

    String conditionCategoryNames(JSONObject item) {
        Set<String> ids = host.conditionCategoryIds(item);
        if (ids.isEmpty())
            return "";
        List<String> labels = new ArrayList<>();
        for (String[] option : host.DIAGNOSIS_OPTIONS) {
            if (ids.contains(option[0]))
                labels.add(host.i18n.t(option[1]));
        }
        StringBuilder builder = new StringBuilder();
        for (String label : labels) {
            if (builder.length() > 0)
                builder.append(", ");
            builder.append(label);
        }
        return builder.toString();
    }

    LinearLayout diagnosisDoctorVisitButton() {
        int blue = Color.rgb(51, 132, 216);
        LinearLayout row = Ui.h(host, 0);
        row.setGravity(Gravity.CENTER);
        row.setPadding(Ui.dp(host, 18), Ui.dp(host, 16), Ui.dp(host, 18), Ui.dp(host, 16));
        row.setBackground(Ui.round(Color.rgb(214, 231, 242), Ui.dp(host, 14)));
        row.setClickable(true);
        row.setFocusable(true);
        row.addView(Ui.text(host, "+", 22, blue, android.graphics.Typeface.BOLD), Ui.wrapWrap());
        Ui.addSpacerHorizontal(host, row, 8);
        row.addView(host.symbolIcon(R.drawable.ios_tab_diagnosis, blue, Color.TRANSPARENT, 26, 2), Ui.fixed(host, 28, 28));
        Ui.addSpacerHorizontal(host, row, 8);
        row.addView(Ui.text(host, host.i18n.t("Doctor Visit"), 18, blue, android.graphics.Typeface.BOLD), Ui.wrapWrap());
        return row;
    }

    LinearLayout diagnosisCategoryCard(String[] option) {
        int color = host.diagnosisColor(option[0]);
        LinearLayout row = Ui.h(host, 0);
        row.setPadding(Ui.dp(host, 14), Ui.dp(host, 14), Ui.dp(host, 14), Ui.dp(host, 14));
        row.setBackground(Ui.stroke(AppColors.PANEL, Ui.withAlpha(color, 70), Ui.dp(host, 14)));
        TextView icon = Ui.text(host, host.diagnosisIcon(option[0]), 24, color, android.graphics.Typeface.BOLD);
        icon.setGravity(Gravity.CENTER);
        icon.setBackground(Ui.round(Ui.withAlpha(color, 30), Ui.dp(host, 24)));
        row.addView(icon, Ui.fixed(host, 48, 48));
        TextView label = Ui.text(host, host.i18n.t(option[1]), 17, AppColors.TEXT, android.graphics.Typeface.BOLD);
        LinearLayout.LayoutParams labelParams = new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1);
        labelParams.leftMargin = Ui.dp(host, 12);
        row.addView(label, labelParams);
        row.addView(Ui.text(host, "›", 28, AppColors.MUTED, android.graphics.Typeface.BOLD), Ui.wrapWrap());
        return row;
    }

    String diagnosisIcon(String id) {
        switch(id) {
            case "genetics":
                return "🧬";
            case "pediatricHealthClinic":
                return "🩺";
            case "developmentalBehavioral":
                return "🧩";
            case "childPsychiatryPsychology":
                return "🧠";
            case "neurology":
                return "⚡";
            case "rehabilitationInterventions":
                return "🏃";
            case "gastroenterology":
                return "🍽️";
            case "oralRelated":
                return "🦷";
            case "dermatology":
                return "🩹";
            case "orthopedics":
                return "🦴";
            case "stomatology":
                return "👂";
            case "neurosurgery":
                return "🧠";
            case "ophthalmology":
                return "👁";
            case "traditionalChineseMedicine":
                return "🌿";
            case "nutrition":
                return "🍃";
            case "autismSpecialist":
                return "♾";
            default:
                return "＋";
        }
    }

    int diagnosisColor(String id) {
        switch(id) {
            case "genetics":
            case "childPsychiatryPsychology":
            case "neurosurgery":
                return Color.rgb(140, 124, 224);
            case "pediatricHealthClinic":
            case "rehabilitationInterventions":
                return Color.rgb(90, 173, 215);
            case "gastroenterology":
            case "nutrition":
            case "traditionalChineseMedicine":
                return Color.rgb(93, 185, 130);
            case "dermatology":
            case "oralRelated":
            case "stomatology":
                return Color.rgb(232, 150, 120);
            default:
                return AppColors.ACCENT;
        }
    }

    void addDoctorVisits(LinearLayout screen) {
        JSONArray visits = host.storage.getArray(host.storage.key("diagnosis", host.currentUser.id, "doctorVisits"));
        LinearLayout panel = Ui.panel(host);
        panel.addView(Ui.sectionTitle(host, host.i18n.t("Doctor Visit")), Ui.matchWrap());
        Ui.addSpacer(host, panel, 10);
        if (visits.length() == 0) {
            panel.addView(Ui.muted(host, host.i18n.t("No records yet.")), Ui.matchWrap());
        } else {
            for (int i = 0; i < visits.length(); i++) {
                JSONObject visit = visits.optJSONObject(i);
                if (visit == null)
                    continue;
                panel.addView(Ui.cardRow(host, visit.optString("clinic"), visit.optString("date") + "  " + visit.optString("notes"), "MD"), Ui.matchWrap());
                Ui.addSpacer(host, panel, 8);
            }
        }
        screen.addView(panel, Ui.matchWrap());
    }

    void showDiagnosisCategoryDialog() {
        String key = host.storage.key("diagnosis", host.currentUser.id, "selectedOptions");
        Set<String> selected = host.commaSet(host.storage.getString(key, ""));
        boolean[] checked = new boolean[host.DIAGNOSIS_OPTIONS.length];
        LinearLayout content = Ui.v(host, 0);
        content.setPadding(Ui.dp(host, 12), 0, Ui.dp(host, 12), 0);
        for (int i = 0; i < host.DIAGNOSIS_OPTIONS.length; i++) {
            checked[i] = selected.contains(host.DIAGNOSIS_OPTIONS[i][0]);
            final int index = i;
            LinearLayout row = Ui.h(host, 0);
            row.setGravity(Gravity.CENTER_VERTICAL);
            row.setPadding(Ui.dp(host, 14), Ui.dp(host, 12), Ui.dp(host, 14), Ui.dp(host, 12));
            row.setBackground(Ui.stroke(checked[i] ? Ui.withAlpha(AppColors.ACCENT, 28) : AppColors.PANEL, AppColors.BORDER, Ui.dp(host, 14)));
            row.setClickable(true);
            row.setFocusable(true);
            CheckBox box = new CheckBox(host);
            box.setChecked(checked[i]);
            box.setClickable(false);
            box.setButtonTintList(android.content.res.ColorStateList.valueOf(AppColors.ACCENT));
            row.addView(box, Ui.fixed(host, 42, 42));
            String labelText = host.diagnosisIcon(host.DIAGNOSIS_OPTIONS[i][0]) + "  " + host.i18n.t(host.DIAGNOSIS_OPTIONS[i][1]);
            row.addView(Ui.text(host, labelText, 16, AppColors.TEXT, android.graphics.Typeface.BOLD), new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1));
            row.setOnClickListener(v -> {
                checked[index] = !checked[index];
                box.setChecked(checked[index]);
                row.setBackground(Ui.stroke(checked[index] ? Ui.withAlpha(AppColors.ACCENT, 28) : AppColors.PANEL, AppColors.BORDER, Ui.dp(host, 14)));
            });
            content.addView(row, Ui.matchWrap());
            Ui.addSpacer(host, content, 8);
        }
        Ui.dialogWithTopAction(host, host.i18n.t("Category"), content, host.i18n.t("Done"), () -> {
            StringBuilder builder = new StringBuilder();
            for (int i = 0; i < checked.length; i++) {
                if (checked[i]) {
                    if (builder.length() > 0)
                        builder.append(",");
                    builder.append(host.DIAGNOSIS_OPTIONS[i][0]);
                }
            }
            host.storage.putString(key, builder.toString());
            host.render();
        });
    }

    void showConditionActions(int index) {
        host.showChoiceSheet(host.i18n.t("Condition"), new String[] { host.i18n.t("Edit"), host.i18n.t("Delete") }, (which, sheet) -> {
            sheet.dismiss();
            JSONArray conditions = host.storage.getArray(host.storage.key("diagnosis", host.currentUser.id, "conditions"));
            JSONObject item = conditions.optJSONObject(index);
            if (which == 0 && item != null) {
                host.showConditionDialog(item, index);
            } else if (which == 1) {
                conditions.remove(index);
                host.storage.putArray(host.storage.key("diagnosis", host.currentUser.id, "conditions"), conditions);
                host.render();
            }
        });
    }

    void showConditionDialog(JSONObject existing, int index) {
        LinearLayout content = Ui.v(host, 0);
        content.setPadding(Ui.dp(host, 6), 0, Ui.dp(host, 6), Ui.dp(host, 8));
        Set<String> selectedCategories = host.conditionCategoryIds(existing);
        EditText name = Ui.edit(host, host.i18n.t("Enter condition name"));
        EditText notes = Ui.multi(host, host.i18n.t("Add notes"));
        String[] photoData = { existing == null ? "" : existing.optString("imageData") };
        if (existing != null) {
            name.setText(existing.optString("name"));
            notes.setText(existing.optString("notes"));
        }
        Button save = Ui.primary(host, host.i18n.t("Save"));
        Runnable updateSave = () -> host.updateConditionSaveButton(save, name);
        host.addConditionTextWatcher(name, updateSave);
        host.addConditionTextWatcher(notes, updateSave);
        boolean[] categoryExpanded = { false };
        LinearLayout categoryHost = Ui.v(host, 0);
        Runnable[] refreshCategory = new Runnable[1];
        refreshCategory[0] = () -> {
            categoryHost.removeAllViews();
            categoryHost.addView(host.conditionCategoryDropdownCard(selectedCategories, categoryExpanded[0], () -> {
                categoryExpanded[0] = !categoryExpanded[0];
                refreshCategory[0].run();
            }, () -> {
                updateSave.run();
                refreshCategory[0].run();
            }), Ui.matchWrap());
        };
        refreshCategory[0].run();
        content.addView(categoryHost, Ui.matchWrap());
        Ui.addSpacer(host, content, 14);
        content.addView(host.conditionInputCard(host.i18n.t("Condition Name"), name), Ui.matchWrap());
        Ui.addSpacer(host, content, 14);
        content.addView(host.conditionInputCard(host.i18n.t("Notes"), notes), Ui.matchWrap());
        Ui.addSpacer(host, content, 14);
        content.addView(host.conditionPhotoCard(photoData, updateSave), Ui.matchWrap());
        final Dialog[] dialogRef = new Dialog[1];
        save.setOnClickListener(v -> {
            String cleanName = name.getText().toString().trim();
            if (cleanName.isEmpty())
                return;
            JSONArray conditions = host.storage.getArray(host.storage.key("diagnosis", host.currentUser.id, "conditions"));
            JSONObject item = new JSONObject();
            try {
                JSONArray categoryIds = new JSONArray();
                for (String id : selectedCategories) categoryIds.put(id);
                item.put("categoryIDs", categoryIds);
                if (!selectedCategories.isEmpty()) {
                    item.put("categoryID", selectedCategories.iterator().next());
                }
                item.put("name", cleanName);
                item.put("notes", notes.getText().toString().trim());
                item.put("createdAt", existing == null ? host.nowIso() : existing.optString("createdAt", host.nowIso()));
                item.put("updatedAt", host.nowIso());
                if (!photoData[0].isEmpty())
                    item.put("imageData", photoData[0]);
            } catch (JSONException ignored) {
            }
            if (index >= 0) {
                try {
                    conditions.put(index, item);
                } catch (JSONException ignored) {
                }
            } else {
                conditions.put(item);
            }
            host.storage.putArray(host.storage.key("diagnosis", host.currentUser.id, "conditions"), conditions);
            host.mergeDiagnosisSelections(selectedCategories);
            host.render();
            if (dialogRef[0] != null)
                dialogRef[0].dismiss();
        });
        LinearLayout.LayoutParams saveParams = Ui.matchWrap();
        saveParams.topMargin = Ui.dp(host, 18);
        content.addView(save, saveParams);
        updateSave.run();
        dialogRef[0] = Ui.bottomSheet(host, host.i18n.t(existing == null ? "New Condition" : "Edit Condition"), content, null, null);
        dialogRef[0].show();
    }

    Set<String> conditionCategoryIds(JSONObject existing) {
        Set<String> selected = new LinkedHashSet<>();
        if (existing == null)
            return selected;
        JSONArray ids = existing.optJSONArray("categoryIDs");
        if (ids != null) {
            for (int i = 0; i < ids.length(); i++) {
                String id = ids.optString(i, "").trim();
                if (!id.isEmpty())
                    selected.add(id);
            }
        } else {
            selected.addAll(host.commaSet(existing.optString("categoryIDs", "")));
        }
        String single = existing.optString("categoryID", "").trim();
        if (!single.isEmpty())
            selected.add(single);
        return selected;
    }

    LinearLayout conditionFormCard() {
        LinearLayout card = Ui.v(host, 0);
        card.setPadding(Ui.dp(host, 16), Ui.dp(host, 16), Ui.dp(host, 16), Ui.dp(host, 16));
        card.setBackground(Ui.round(AppColors.PANEL, Ui.dp(host, 20)));
        return card;
    }

    LinearLayout conditionCategoryDropdownCard(Set<String> selected, boolean expanded, Runnable onToggle, Runnable onChanged) {
        LinearLayout card = host.conditionFormCard();
        LinearLayout inner = Ui.h(host, 0);
        inner.setGravity(Gravity.CENTER_VERTICAL);
        inner.setPadding(Ui.dp(host, 12), Ui.dp(host, 12), Ui.dp(host, 12), Ui.dp(host, 12));
        inner.setBackground(Ui.round(host.conditionFieldColor(), Ui.dp(host, 14)));
        inner.setClickable(true);
        inner.setFocusable(true);
        LinearLayout textStack = Ui.v(host, 2);
        textStack.addView(Ui.text(host, host.i18n.t("Select category"), 14, AppColors.MUTED, android.graphics.Typeface.BOLD), Ui.matchWrap());
        TextView value = Ui.text(host, host.conditionCategorySummary(selected), 20, AppColors.TEXT, android.graphics.Typeface.BOLD);
        value.setSingleLine(false);
        textStack.addView(value, Ui.matchWrap());
        inner.addView(textStack, new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1));
        inner.addView(Ui.text(host, expanded ? "⌃" : "⌄", 30, AppColors.MUTED, android.graphics.Typeface.BOLD), Ui.wrapWrap());
        inner.setOnClickListener(v -> onToggle.run());
        card.addView(inner, Ui.matchWrap());
        if (expanded) {
            Ui.addSpacer(host, card, 16);
            for (String[] option : host.DIAGNOSIS_OPTIONS) {
                card.addView(host.conditionCategoryOptionRow(option, selected, onChanged), Ui.matchWrap());
                Ui.addSpacer(host, card, 8);
            }
        }
        return card;
    }

    LinearLayout conditionCategoryOptionRow(String[] option, Set<String> selected, Runnable onChanged) {
        String id = option[0];
        boolean isSelected = selected.contains(id);
        LinearLayout row = Ui.h(host, 0);
        row.setGravity(Gravity.CENTER_VERTICAL);
        row.setPadding(Ui.dp(host, 12), Ui.dp(host, 11), Ui.dp(host, 12), Ui.dp(host, 11));
        row.setBackground(Ui.stroke(isSelected ? Ui.withAlpha(AppColors.ACCENT, 24) : AppColors.PANEL, AppColors.BORDER, Ui.dp(host, 14)));
        row.setClickable(true);
        row.setFocusable(true);
        CheckBox box = new CheckBox(host);
        box.setChecked(isSelected);
        box.setClickable(false);
        box.setButtonTintList(android.content.res.ColorStateList.valueOf(isSelected ? AppColors.ACCENT : AppColors.MUTED));
        row.addView(box, Ui.fixed(host, 38, 38));
        TextView icon = Ui.text(host, host.diagnosisIcon(id), 22, AppColors.TEXT, android.graphics.Typeface.NORMAL);
        icon.setGravity(Gravity.CENTER);
        row.addView(icon, Ui.fixed(host, 36, 36));
        TextView label = Ui.text(host, host.i18n.t(option[1]), 16, AppColors.TEXT, android.graphics.Typeface.BOLD);
        LinearLayout.LayoutParams labelParams = new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1);
        labelParams.leftMargin = Ui.dp(host, 8);
        row.addView(label, labelParams);
        row.setOnClickListener(v -> {
            if (selected.contains(id))
                selected.remove(id);
            else
                selected.add(id);
            if (onChanged != null)
                onChanged.run();
        });
        return row;
    }

    LinearLayout conditionInputCard(String title, EditText input) {
        LinearLayout card = host.conditionFormCard();
        card.addView(Ui.text(host, title, 19, AppColors.TEXT, android.graphics.Typeface.BOLD), Ui.matchWrap());
        Ui.addSpacer(host, card, 12);
        host.styleConditionInput(input);
        card.addView(input, Ui.matchWrap());
        return card;
    }

    LinearLayout conditionPhotoCard(String[] photoData, Runnable onPhotoChanged) {
        LinearLayout card = host.conditionFormCard();
        card.addView(Ui.text(host, host.i18n.t("Photos"), 19, AppColors.TEXT, android.graphics.Typeface.BOLD), Ui.matchWrap());
        Ui.addSpacer(host, card, 12);
        TextView status = Ui.muted(host, host.i18n.t("Photo selected"));
        status.setVisibility(photoData[0].isEmpty() ? View.GONE : View.VISIBLE);
        card.addView(status, Ui.matchWrap());
        if (!photoData[0].isEmpty())
            Ui.addSpacer(host, card, 10);
        LinearLayout row = Ui.h(host, 0);
        View camera = host.conditionPhotoAction(R.drawable.ios_icon_camera_fill, host.i18n.t("Take Photo"));
        View upload = host.conditionPhotoAction(R.drawable.ios_icon_photo_stack, host.i18n.t("Upload Photo"));
        camera.setOnClickListener(v -> {
            host.takeGenericPhoto(photoData, status);
            if (onPhotoChanged != null)
                onPhotoChanged.run();
        });
        upload.setOnClickListener(v -> {
            host.chooseGenericPhoto(photoData, status);
            if (onPhotoChanged != null)
                onPhotoChanged.run();
        });
        LinearLayout.LayoutParams left = new LinearLayout.LayoutParams(0, Ui.dp(host, 92), 1);
        left.rightMargin = Ui.dp(host, 10);
        row.addView(camera, left);
        row.addView(upload, new LinearLayout.LayoutParams(0, Ui.dp(host, 92), 1));
        card.addView(row, Ui.matchWrap());
        return card;
    }

    View conditionPhotoAction(int iconRes, String title) {
        LinearLayout action = Ui.v(host, 7);
        action.setGravity(Gravity.CENTER);
        action.setBackground(Ui.round(Ui.withAlpha(AppColors.ACCENT, 18), Ui.dp(host, 14)));
        action.setClickable(true);
        action.setFocusable(true);
        action.addView(host.symbolIcon(iconRes, AppColors.ACCENT, Color.TRANSPARENT, 32, 3), Ui.fixed(host, 34, 34));
        action.addView(Ui.text(host, title, 15, AppColors.ACCENT, android.graphics.Typeface.BOLD), Ui.wrapWrap());
        return action;
    }

    int conditionFieldColor() {
        return Color.rgb(246, 248, 246);
    }

    void styleConditionInput(EditText input) {
        input.setTextColor(AppColors.TEXT);
        input.setHintTextColor(Ui.withAlpha(AppColors.MUTED, 135));
        input.setTextSize(18);
        boolean multiline = input.getMinLines() > 1;
        input.setPadding(Ui.dp(host, 16), multiline ? Ui.dp(host, 14) : 0, Ui.dp(host, 16), multiline ? Ui.dp(host, 14) : 0);
        input.setMinHeight(Ui.dp(host, multiline ? 150 : 62));
        input.setBackground(Ui.round(host.conditionFieldColor(), Ui.dp(host, 14)));
    }

    void addConditionTextWatcher(EditText input, Runnable afterChange) {
        input.addTextChangedListener(new TextWatcher() {

            @Override
            public void beforeTextChanged(CharSequence s, int start, int count, int after) {
            }

            @Override
            public void onTextChanged(CharSequence s, int start, int before, int count) {
                if (afterChange != null)
                    afterChange.run();
            }

            @Override
            public void afterTextChanged(Editable s) {
            }
        });
    }

    void updateConditionSaveButton(Button save, EditText name) {
        boolean enabled = !name.getText().toString().trim().isEmpty();
        save.setEnabled(enabled);
        save.setTextColor(AppColors.PANEL);
        save.setBackground(Ui.stroke(enabled ? AppColors.ACCENT : Color.rgb(205, 211, 207), enabled ? AppColors.ACCENT : Color.rgb(205, 211, 207), Ui.dp(host, 12)));
        save.setAlpha(enabled ? 1.0f : 0.75f);
    }

    void showConditionCategoryDialog(Set<String> selected, Runnable onChanged) {
        boolean[] checked = new boolean[host.DIAGNOSIS_OPTIONS.length];
        LinearLayout content = Ui.v(host, 0);
        content.setPadding(Ui.dp(host, 6), 0, Ui.dp(host, 6), 0);
        for (int i = 0; i < host.DIAGNOSIS_OPTIONS.length; i++) {
            checked[i] = selected.contains(host.DIAGNOSIS_OPTIONS[i][0]);
            final int index = i;
            LinearLayout row = Ui.h(host, 0);
            row.setGravity(Gravity.CENTER_VERTICAL);
            row.setPadding(Ui.dp(host, 14), Ui.dp(host, 12), Ui.dp(host, 14), Ui.dp(host, 12));
            row.setBackground(Ui.stroke(checked[i] ? Ui.withAlpha(AppColors.ACCENT, 28) : AppColors.PANEL, AppColors.BORDER, Ui.dp(host, 14)));
            row.setClickable(true);
            row.setFocusable(true);
            CheckBox box = new CheckBox(host);
            box.setChecked(checked[i]);
            box.setClickable(false);
            box.setButtonTintList(android.content.res.ColorStateList.valueOf(AppColors.ACCENT));
            row.addView(box, Ui.fixed(host, 42, 42));
            String labelText = host.diagnosisIcon(host.DIAGNOSIS_OPTIONS[i][0]) + "  " + host.i18n.t(host.DIAGNOSIS_OPTIONS[i][1]);
            row.addView(Ui.text(host, labelText, 16, AppColors.TEXT, android.graphics.Typeface.BOLD), new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1));
            row.setOnClickListener(v -> {
                checked[index] = !checked[index];
                box.setChecked(checked[index]);
                row.setBackground(Ui.stroke(checked[index] ? Ui.withAlpha(AppColors.ACCENT, 28) : AppColors.PANEL, AppColors.BORDER, Ui.dp(host, 14)));
            });
            content.addView(row, Ui.matchWrap());
            Ui.addSpacer(host, content, 8);
        }
        Ui.dialog(host, host.i18n.t("Select category"), content, host.i18n.t("Done"), () -> {
            selected.clear();
            for (int i = 0; i < checked.length; i++) {
                if (checked[i])
                    selected.add(host.DIAGNOSIS_OPTIONS[i][0]);
            }
            if (onChanged != null)
                onChanged.run();
        });
    }

    String conditionCategorySummary(Set<String> selected) {
        List<String> labels = new ArrayList<>();
        for (String[] option : host.DIAGNOSIS_OPTIONS) {
            if (selected.contains(option[0])) {
                labels.add(host.diagnosisIcon(option[0]) + " " + host.i18n.t(option[1]));
            }
        }
        if (labels.isEmpty())
            return host.i18n.t("Select category");
        StringBuilder builder = new StringBuilder();
        for (String label : labels) {
            if (builder.length() > 0)
                builder.append(", ");
            builder.append(label);
        }
        return builder.toString();
    }

    void mergeDiagnosisSelections(Set<String> ids) {
        if (ids.isEmpty())
            return;
        String key = host.storage.key("diagnosis", host.currentUser.id, "selectedOptions");
        Set<String> merged = new LinkedHashSet<>(host.commaSet(host.storage.getString(key, "")));
        merged.addAll(ids);
        List<String> ordered = new ArrayList<>();
        for (String[] option : host.DIAGNOSIS_OPTIONS) {
            if (merged.contains(option[0]))
                ordered.add(option[0]);
        }
        host.storage.putString(key, host.joinIds(ordered));
    }

    void showDoctorVisitDialog() {
        LinearLayout content = Ui.v(host, 0);
        content.setPadding(Ui.dp(host, 12), 0, Ui.dp(host, 12), 0);
        EditText clinic = Ui.edit(host, "Clinic / Doctor");
        EditText date = Ui.edit(host, "Date");
        date.setText(host.todayKey());
        EditText notes = Ui.multi(host, "Notes");
        String[] photoData = { "" };
        content.addView(Ui.fieldGroup(host, "Clinic / Doctor", clinic), Ui.matchWrap());
        Ui.addSpacer(host, content, 12);
        content.addView(Ui.fieldGroup(host, "Date", date), Ui.matchWrap());
        Ui.addSpacer(host, content, 12);
        content.addView(Ui.fieldGroup(host, "Notes", notes), Ui.matchWrap());
        Ui.addSpacer(host, content, 12);
        content.addView(host.photoControls("Documents / Photos", photoData), Ui.matchWrap());
        Ui.dialog(host, host.i18n.t("Doctor Visit"), content, host.i18n.t("Save"), () -> {
            JSONArray visits = host.storage.getArray(host.storage.key("diagnosis", host.currentUser.id, "doctorVisits"));
            JSONObject visit = new JSONObject();
            try {
                visit.put("clinic", clinic.getText().toString().trim());
                visit.put("date", date.getText().toString().trim());
                visit.put("notes", notes.getText().toString().trim());
                if (!photoData[0].isEmpty())
                    visit.put("imageData", photoData[0]);
            } catch (JSONException ignored) {
            }
            visits.put(visit);
            host.storage.putArray(host.storage.key("diagnosis", host.currentUser.id, "doctorVisits"), visits);
            host.render();
        });
    }
}
