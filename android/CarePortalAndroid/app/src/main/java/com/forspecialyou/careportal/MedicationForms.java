package com.forspecialyou.careportal;

import android.app.Dialog;
import android.graphics.Color;
import android.text.InputType;
import android.view.Gravity;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ArrayAdapter;
import android.widget.Button;
import android.widget.CheckBox;
import android.widget.EditText;
import android.widget.GridLayout;
import android.widget.LinearLayout;
import android.widget.SeekBar;
import android.widget.Spinner;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.Collections;
import java.util.Date;
import java.util.HashSet;
import java.util.List;
import java.util.Locale;
import java.util.Set;

final class MedicationForms {

    private final MainActivity host;

    MedicationForms(MainActivity host) {
        this.host = host;
    }

    Calendar defaultDoseTime(int index) {
        Calendar calendar = Calendar.getInstance();
        calendar.set(Calendar.MINUTE, 0);
        int[] hours = { 8, 12, 18 };
        calendar.set(Calendar.HOUR_OF_DAY, index < hours.length ? hours[index] : Math.min(22, 8 + index * 2));
        return calendar;
    }

    void rebuildMedicineDoseTimes(LinearLayout container, List<Calendar> times) {
        container.removeAllViews();
        for (int i = 0; i < times.size(); i++) {
            container.addView(host.timeOnlyRow(host.i18n.t("Dose") + " " + (i + 1), times.get(i)), Ui.matchWrap());
            Ui.addSpacer(host, container, 8);
        }
    }

    List<JSONObject> medicineDoseRows(JSONArray meds) {
        List<JSONObject> rows = new ArrayList<>();
        for (int i = 0; i < meds.length(); i++) {
            JSONObject med = meds.optJSONObject(i);
            if (med == null)
                continue;
            JSONArray times = med.optJSONArray("times");
            if (times == null || times.length() == 0) {
                times = new JSONArray();
                times.put(med.optString("time", ""));
            }
            for (int t = 0; t < times.length(); t++) {
                JSONObject row = new JSONObject();
                try {
                    String medId = med.optString("id", "med-" + i);
                    row.put("id", medId + ":" + t);
                    row.put("medicineId", medId);
                    row.put("name", med.optString("name"));
                    row.put("dose", med.optString("dose"));
                    row.put("time", times.optString(t));
                    row.put("frequency", med.optString("frequency"));
                } catch (JSONException ignored) {
                }
                rows.add(row);
            }
        }
        Collections.sort(rows, (left, right) -> Integer.compare(host.timeSortValue(left.optString("time")), host.timeSortValue(right.optString("time"))));
        return rows;
    }

    String medicineDoseLabel(JSONObject row) {
        String dose = row.optString("dose", "").trim();
        return row.optString("name", host.i18n.t("Medicine")) + (dose.isEmpty() ? "" : " " + dose);
    }

    int timeSortValue(String time) {
        try {
            Date date = new SimpleDateFormat("h:mm a", Locale.getDefault()).parse(time);
            Calendar calendar = Calendar.getInstance();
            if (date != null)
                calendar.setTime(date);
            return calendar.get(Calendar.HOUR_OF_DAY) * 60 + calendar.get(Calendar.MINUTE);
        } catch (Exception ignored) {
            return 24 * 60;
        }
    }

    void showCyclicVomitingDialog(String title) {
        Calendar start = Calendar.getInstance();
        Calendar end = Calendar.getInstance();
        int tint = host.quickLogColor("cyclicVomiting");
        LinearLayout content = host.quickFormContent();
        LinearLayout nav = Ui.h(host, 0);
        Button background = Ui.secondary(host, host.i18n.t("Background"));
        Button patterns = Ui.secondary(host, host.i18n.t("Vomiting Patterns"));
        nav.addView(background, new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1));
        nav.addView(patterns, new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1));
        content.addView(nav, Ui.matchWrap());
        Ui.addSpacer(host, content, 12);
        background.setOnClickListener(v -> host.showCyclicVomitingBackgroundDialog());
        patterns.setOnClickListener(v -> host.showCyclicVomitingPatternsDialog());
        LinearLayout timeCard = host.sectionCard("⏱ " + host.i18n.t("Time Tracking"));
        timeCard.addView(host.timeOnlyRow(host.i18n.t("Vomiting Start Time"), start), Ui.matchWrap());
        Ui.addSpacer(host, timeCard, 8);
        timeCard.addView(host.timeOnlyRow(host.i18n.t("Vomiting End Time"), end), Ui.matchWrap());
        Ui.addSpacer(host, timeCard, 8);
        String[] hospitalized = { "" };
        timeCard.addView(host.singleChoiceSection(host.i18n.t("Hospitalized for this episode?"), new String[] { "Yes", "No" }, hospitalized, tint), Ui.matchWrap());
        content.addView(timeCard, Ui.matchWrap());
        Ui.addSpacer(host, content, 12);
        Set<String> triggers = new HashSet<>();
        content.addView(host.chipSection(host.i18n.t("Triggers before this vomiting episode"), new String[] { "Post-respiratory tract infection", "Post-improper diet", "After riding in a car or other vehicles", "Post-emotional stress/stimulation", "Menstrual period", "None of the above triggers", "Other" }, triggers, tint), Ui.matchWrap());
        Ui.addSpacer(host, content, 12);
        Set<String> before = new HashSet<>();
        content.addView(host.chipSection(host.i18n.t("Symptoms before this vomiting episode started"), new String[] { "Nausea", "Pallor", "Sweating", "Lethargy/Somnolence", "Hot flashes", "Headache", "Abdominal pain", "None of the above symptoms", "Other" }, before, tint), Ui.matchWrap());
        Ui.addSpacer(host, content, 12);
        Set<String> during = new HashSet<>();
        content.addView(host.chipSection(host.i18n.t("Symptoms during this vomiting episode"), new String[] { "Nausea", "Abdominal pain", "Diarrhea", "Anorexia", "Headache", "Photophobia", "Phonophobia", "Vertigo", "None of the above symptoms", "Other" }, during, tint), Ui.matchWrap());
        Ui.addSpacer(host, content, 12);
        Set<String> recovery = new HashSet<>();
        content.addView(host.chipSection(host.i18n.t("Symptoms after vomiting stopped"), new String[] { "Drowsiness", "Deep sleep", "Abdominal pain", "Nausea", "Headache", "Dizziness", "None of the above symptoms", "Other" }, recovery, tint), Ui.matchWrap());
        Ui.addSpacer(host, content, 12);
        EditText acts = Ui.edit(host, host.i18n.t("Times per Day"));
        acts.setInputType(InputType.TYPE_CLASS_NUMBER);
        content.addView(Ui.fieldGroup(host, host.i18n.t("Times per Day"), acts), Ui.matchWrap());
        Ui.addSpacer(host, content, 12);
        Set<String> meds = new HashSet<>();
        content.addView(host.chipSection(host.i18n.t("Current medications in use"), new String[] { "Cyproheptadine", "Amitriptyline", "Propranolol", "Aprepitant", "Sodium valproate", "Phenobarbital", "Topiramate", "Coenzyme Q10", "L-carnitine", "Omeprazole", "Other", "None" }, meds, tint), Ui.matchWrap());
        Ui.addSpacer(host, content, 12);
        EditText notes = Ui.multi(host, host.i18n.t("Notes"));
        content.addView(Ui.fieldGroup(host, host.i18n.t("Notes"), notes), Ui.matchWrap());
        host.showQuickLogForm(host.i18n.t(title), content, () -> {
            String value = host.i18n.t("Vomiting") + " · " + (acts.getText().toString().trim().isEmpty() ? "--" : acts.getText().toString().trim()) + " " + host.i18n.t("Times per Day");
            if (!hospitalized[0].isEmpty())
                value += " · " + host.i18n.t("Hospitalized") + ": " + hospitalized[0];
            String detail = host.joinNotes(host.noteLine(host.i18n.t("Triggers"), host.joinChoices(triggers)), host.noteLine(host.i18n.t("Before"), host.joinChoices(before)), host.noteLine(host.i18n.t("During"), host.joinChoices(during)), host.noteLine(host.i18n.t("Recovery"), host.joinChoices(recovery)), host.noteLine(host.i18n.t("Current medications in use"), host.joinChoices(meds)), notes.getText().toString().trim());
            host.addHealthEntry("cyclicVomiting", title, "quickLog", value, detail, start);
            host.render();
        });
    }

    void showCyclicVomitingBackgroundDialog() {
        int tint = host.quickLogColor("cyclicVomiting");
        String key = host.storage.key("health", host.currentUser.id, "cyclicVomitingBackground");
        JSONObject existing = host.storage.getObject(key);
        LinearLayout content = host.quickFormContent();
        Set<String> family = host.jsonArrayToSet(existing.optJSONArray("familyHistory"));
        content.addView(host.chipSection(host.i18n.t("Family History") + " · " + host.i18n.t("Parents, grandparents, siblings etc with following conditions"), new String[] { "Migraine", "Abdominal migraine", "Recurrent vomiting", "Motion sickness", "Functional abdominal pain", "None" }, family, tint), Ui.matchWrap());
        Ui.addSpacer(host, content, 12);
        Set<String> surgeries = host.jsonArrayToSet(existing.optJSONArray("surgicalHistory"));
        content.addView(host.chipSection(host.i18n.t("Surgical History"), new String[] { "Post-tracheoesophageal fistula surgery", "Post-esophageal hiatal hernia surgery", "Post-congenital heart disease surgery", "Post-tethered cord syndrome surgery", "Post-fundoplication", "Post-Hirschsprung's disease surgery", "Other", "None" }, surgeries, tint), Ui.matchWrap());
        Ui.addSpacer(host, content, 12);
        LinearLayout onset = host.sectionCard(host.i18n.t("Onset Time of Recurrent Vomiting"));
        EditText year = Ui.edit(host, host.i18n.t("Year"));
        year.setInputType(InputType.TYPE_CLASS_NUMBER);
        year.setText(existing.optString("onsetYear"));
        EditText month = Ui.edit(host, host.i18n.t("Month"));
        month.setInputType(InputType.TYPE_CLASS_NUMBER);
        month.setText(existing.optString("onsetMonth"));
        LinearLayout onsetRow = Ui.h(host, 0);
        onsetRow.addView(year, new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1));
        onsetRow.addView(month, new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1));
        onset.addView(onsetRow, Ui.matchWrap());
        content.addView(onset, Ui.matchWrap());
        Ui.addSpacer(host, content, 12);
        Set<String> comorbidities = host.jsonArrayToSet(existing.optJSONArray("comorbidities"));
        content.addView(host.chipSection(host.i18n.t("Comorbidities") + " · " + host.i18n.t("Other co-existing conditions") + " · " + host.i18n.t("Multiple choice"), new String[] { "Epilepsy", "Tourette syndrome", "Coffin-Siris syndrome", "Klinefelter 综合征", "Inborn errors of metabolism", "Celiac disease", "Inflammatory bowel disease", "Other", "None of the above" }, comorbidities, tint), Ui.matchWrap());
        Ui.addSpacer(host, content, 12);
        String[] hospitalized = { existing.optString("hospitalizedAtBeijingHospital") };
        content.addView(host.singleChoiceSection(host.i18n.t("Have you ever been hospitalized at Beijing Tsinghua Changgung Hospital?"), new String[] { "Yes", "No" }, hospitalized, tint), Ui.matchWrap());
        Ui.addSpacer(host, content, 12);
        Set<String> currentMeds = host.jsonArrayToSet(existing.optJSONArray("currentMedications"));
        content.addView(host.chipSection(host.i18n.t("Current medications in use"), host.cyclicVomitingMedicineOptions(), currentMeds, tint), Ui.matchWrap());
        Ui.addSpacer(host, content, 12);
        EditText adverse = Ui.multi(host, host.i18n.t("Adverse drug reactions"));
        adverse.setText(existing.optString("adverseDrugReactionDetails"));
        content.addView(Ui.fieldGroup(host, host.i18n.t("Adverse drug reactions"), adverse), Ui.matchWrap());
        Ui.addSpacer(host, content, 12);
        Set<String> pastMeds = host.jsonArrayToSet(existing.optJSONArray("pastMedications"));
        content.addView(host.chipSection(host.i18n.t("Past medications used"), host.cyclicVomitingMedicineOptions(), pastMeds, tint), Ui.matchWrap());
        host.showQuickLogForm(host.i18n.t("Background"), content, () -> {
            JSONObject data = new JSONObject();
            try {
                data.put("familyHistory", new JSONArray(family));
                data.put("surgicalHistory", new JSONArray(surgeries));
                data.put("onsetYear", year.getText().toString().trim());
                data.put("onsetMonth", month.getText().toString().trim());
                data.put("comorbidities", new JSONArray(comorbidities));
                data.put("hospitalizedAtBeijingHospital", hospitalized[0]);
                data.put("currentMedications", new JSONArray(currentMeds));
                data.put("adverseDrugReactionDetails", adverse.getText().toString().trim());
                data.put("pastMedications", new JSONArray(pastMeds));
            } catch (JSONException ignored) {
            }
            host.storage.putObject(key, data);
        });
    }

    void showCyclicVomitingPatternsDialog() {
        int tint = host.quickLogColor("cyclicVomiting");
        String key = host.storage.key("health", host.currentUser.id, "cyclicVomitingPatterns");
        JSONObject existing = host.storage.getObject(key);
        LinearLayout content = host.quickFormContent();
        String[] episodes = { existing.optString("episodesPastYear") };
        content.addView(host.singleChoiceSection(host.i18n.t("Number of vomiting episodes in the past year"), new String[] { "< 4 times/year", "≥ 4 times/year", "No episodes" }, episodes, tint), Ui.matchWrap());
        Ui.addSpacer(host, content, 12);
        String[] interval = { existing.optString("episodeInterval") };
        content.addView(host.singleChoiceSection(host.i18n.t("Interval between vomiting episodes"), new String[] { "> 2 months", "≤ 2 months" }, interval, tint), Ui.matchWrap());
        Ui.addSpacer(host, content, 12);
        String[] duration = { existing.optString("episodeDuration") };
        content.addView(host.singleChoiceSection(host.i18n.t("Duration of each vomiting episode"), new String[] { "≤ 2 days", "> 2 days" }, duration, tint), Ui.matchWrap());
        Ui.addSpacer(host, content, 12);
        Set<String> triggers = host.jsonArrayToSet(existing.optJSONArray("historicalTriggers"));
        content.addView(host.chipSection(host.i18n.t("Historical triggers before each vomiting episode"), new String[] { "Post-respiratory tract infection", "Post-improper diet", "After riding in a car or other vehicles", "Post-emotional stress/stimulation", "Menstrual period", "None of the above triggers", "Other" }, triggers, tint), Ui.matchWrap());
        Ui.addSpacer(host, content, 12);
        Set<String> prodrome = host.jsonArrayToSet(existing.optJSONArray("prodromalSymptoms"));
        content.addView(host.chipSection(host.i18n.t("Prodromal Symptoms"), new String[] { "Nausea", "Pallor", "Sweating", "Lethargy/Somnolence", "Hot flashes", "Headache", "Abdominal pain", "None of the above symptoms", "Other" }, prodrome, tint), Ui.matchWrap());
        Ui.addSpacer(host, content, 12);
        Set<String> during = host.jsonArrayToSet(existing.optJSONArray("episodeSymptoms"));
        content.addView(host.chipSection(host.i18n.t("Symptoms during each vomiting episode"), new String[] { "Nausea", "Abdominal pain", "Diarrhea", "Anorexia", "Headache", "Photophobia", "Phonophobia", "Vertigo", "None of the above symptoms", "Other" }, during, tint), Ui.matchWrap());
        Ui.addSpacer(host, content, 12);
        Set<String> post = host.jsonArrayToSet(existing.optJSONArray("postdromalSymptoms"));
        content.addView(host.chipSection(host.i18n.t("Postdromal Symptoms"), new String[] { "Drowsiness", "Deep sleep", "Abdominal pain", "Nausea", "Headache", "Dizziness", "None of the above symptoms", "Other" }, post, tint), Ui.matchWrap());
        Ui.addSpacer(host, content, 12);
        LinearLayout growth = host.sectionCard(host.i18n.t("Growth"));
        EditText height = Ui.edit(host, "cm");
        height.setInputType(InputType.TYPE_CLASS_NUMBER | InputType.TYPE_NUMBER_FLAG_DECIMAL);
        height.setText(existing.optString("heightCm"));
        EditText weight = Ui.edit(host, "Kg");
        weight.setInputType(InputType.TYPE_CLASS_NUMBER | InputType.TYPE_NUMBER_FLAG_DECIMAL);
        weight.setText(existing.optString("weightKg"));
        LinearLayout row = Ui.h(host, 0);
        row.addView(height, new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1));
        row.addView(weight, new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1));
        growth.addView(row, Ui.matchWrap());
        content.addView(growth, Ui.matchWrap());
        Ui.addSpacer(host, content, 12);
        String[] age = { existing.optString("qualityOfLifeAgeGroup") };
        content.addView(host.singleChoiceSection(host.i18n.t("Current Quality of Life Status"), new String[] { "13–18 years old", "8–12 years old", "5–7 years old", "2–4 years old", "1–12 months" }, age, tint), Ui.matchWrap());
        host.showQuickLogForm(host.i18n.t("Vomiting Patterns"), content, () -> {
            JSONObject data = new JSONObject();
            try {
                data.put("episodesPastYear", episodes[0]);
                data.put("episodeInterval", interval[0]);
                data.put("episodeDuration", duration[0]);
                data.put("historicalTriggers", new JSONArray(triggers));
                data.put("prodromalSymptoms", new JSONArray(prodrome));
                data.put("episodeSymptoms", new JSONArray(during));
                data.put("postdromalSymptoms", new JSONArray(post));
                data.put("heightCm", height.getText().toString().trim());
                data.put("weightKg", weight.getText().toString().trim());
                data.put("qualityOfLifeAgeGroup", age[0]);
            } catch (JSONException ignored) {
            }
            host.storage.putObject(key, data);
        });
    }

    String[] cyclicVomitingMedicineOptions() {
        return new String[] { "Cyproheptadine", "Amitriptyline", "Propranolol", "Aprepitant", "Sodium valproate", "Phenobarbital", "Topiramate", "Coenzyme Q10", "L-carnitine", "Omeprazole", "Other", "None" };
    }

    Set<String> jsonArrayToSet(JSONArray array) {
        Set<String> set = new HashSet<>();
        if (array == null)
            return set;
        for (int i = 0; i < array.length(); i++) {
            String value = array.optString(i);
            if (!value.isEmpty())
                set.add(value);
        }
        return set;
    }

    LinearLayout quickFormContent() {
        LinearLayout content = Ui.v(host, 0);
        content.setPadding(Ui.dp(host, 6), 0, Ui.dp(host, 6), Ui.dp(host, 8));
        return content;
    }

    LinearLayout sectionCard(String title) {
        LinearLayout card = Ui.panel(host);
        card.setPadding(Ui.dp(host, 16), Ui.dp(host, 16), Ui.dp(host, 16), Ui.dp(host, 16));
        card.setBackground(Ui.stroke(AppColors.PANEL, Ui.withAlpha(AppColors.BORDER, 150), Ui.dp(host, 20)));
        card.addView(Ui.text(host, title, 18, AppColors.TEXT, android.graphics.Typeface.BOLD), Ui.matchWrap());
        Ui.addSpacer(host, card, 12);
        return card;
    }

    LinearLayout sectionCardWithChild(String title, View child) {
        LinearLayout card = host.sectionCard(title);
        card.addView(child, Ui.matchWrap());
        return card;
    }

    LinearLayout fieldCard(String title, View child) {
        LinearLayout card = host.sectionCard(title);
        card.addView(child, Ui.matchWrap());
        return card;
    }

    Spinner spinner(String[] values) {
        Spinner spinner = new Spinner(host);
        ArrayAdapter<String> adapter = new ArrayAdapter<>(host, android.R.layout.simple_spinner_item, values);
        adapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
        spinner.setAdapter(adapter);
        spinner.setMinimumHeight(Ui.dp(host, 50));
        spinner.setBackground(Ui.stroke(AppColors.FIELD, AppColors.BORDER, Ui.dp(host, 12)));
        return spinner;
    }

    LinearLayout chipSection(String title, String[] options, Set<String> selected) {
        return host.chipSection(title, options, selected, AppColors.ACCENT);
    }

    LinearLayout chipSection(String title, String[] options, Set<String> selected, int color) {
        LinearLayout card = host.sectionCard(title);
        GridLayout grid = Ui.grid(host, 2);
        for (String option : options) {
            CheckBox chip = Ui.check(host, option);
            chip.setTag(option);
            host.prepareChoiceChip(chip);
            chip.setOnCheckedChangeListener((buttonView, isChecked) -> {
                if (isChecked)
                    selected.add(option);
                else
                    selected.remove(option);
                host.styleChoice(chip, isChecked, color);
            });
            host.styleChoice(chip, false, color);
            Ui.addGridChild(host, grid, chip, 2);
        }
        card.addView(grid, Ui.matchWrap());
        return card;
    }

    LinearLayout singleChoiceSection(String title, String[] options, String[] selected) {
        return host.singleChoiceSection(title, options, selected, AppColors.ACCENT);
    }

    LinearLayout singleChoiceSection(String title, String[] options, String[] selected, int color) {
        LinearLayout card = host.sectionCard(title);
        int columns = host.i18n.t("Frequency").equals(title) ? 1 : Math.min(3, options.length);
        GridLayout grid = Ui.grid(host, columns);
        CheckBox[] boxes = new CheckBox[options.length];
        boolean[] updating = { false };
        for (int i = 0; i < options.length; i++) {
            String option = options[i];
            CheckBox chip = Ui.check(host, option);
            chip.setTag(option);
            host.prepareChoiceChip(chip);
            boxes[i] = chip;
            int index = i;
            chip.setOnCheckedChangeListener((buttonView, isChecked) -> {
                if (updating[0])
                    return;
                updating[0] = true;
                if (isChecked) {
                    selected[0] = option;
                    for (int j = 0; j < boxes.length; j++) {
                        if (j != index)
                            boxes[j].setChecked(false);
                        host.styleChoice(boxes[j], j == index, color);
                    }
                } else if (option.equals(selected[0])) {
                    selected[0] = "";
                    host.styleChoice(chip, false, color);
                }
                updating[0] = false;
            });
            host.styleChoice(chip, false, color);
            Ui.addGridChild(host, grid, chip, columns);
        }
        card.addView(grid, Ui.matchWrap());
        return card;
    }

    void prepareChoiceChip(CheckBox chip) {
        chip.setButtonDrawable(null);
        chip.setGravity(Gravity.CENTER);
        chip.setMinHeight(Ui.dp(host, 44));
        chip.setTextSize(14);
        chip.setSingleLine(false);
        chip.setMaxLines(2);
        chip.setPadding(Ui.dp(host, 10), 0, Ui.dp(host, 10), 0);
    }

    void styleChoice(CheckBox chip, boolean selected, int color) {
        String label = chip.getTag() instanceof String ? (String) chip.getTag() : chip.getText().toString().replace("✓ ", "");
        chip.setText(selected ? "✓ " + label : label);
        int selectedText = host.isLightColor(color) ? host.darkerChoiceColor(color) : color;
        chip.setTextColor(selected ? selectedText : AppColors.TEXT);
        chip.setTypeface(android.graphics.Typeface.DEFAULT, selected ? android.graphics.Typeface.BOLD : android.graphics.Typeface.NORMAL);
        chip.setBackground(Ui.stroke(selected ? Ui.withAlpha(color, 38) : Color.WHITE, selected ? color : Ui.withAlpha(AppColors.BORDER, 150), Ui.dp(host, 18)));
    }

    int darkerChoiceColor(int color) {
        return Color.rgb(Math.max(0, (int) (Color.red(color) * 0.72)), Math.max(0, (int) (Color.green(color) * 0.72)), Math.max(0, (int) (Color.blue(color) * 0.72)));
    }

    void tintSeekBar(SeekBar seekBar, int color) {
        seekBar.setProgressTintList(android.content.res.ColorStateList.valueOf(color));
        seekBar.setThumbTintList(android.content.res.ColorStateList.valueOf(Color.WHITE));
        seekBar.setProgressBackgroundTintList(android.content.res.ColorStateList.valueOf(Color.rgb(226, 226, 226)));
    }

    boolean isLightColor(int color) {
        double luminance = 0.299 * Color.red(color) + 0.587 * Color.green(color) + 0.114 * Color.blue(color);
        return luminance > 175;
    }

    Dialog showQuickLogForm(String title, LinearLayout content, Runnable onSave) {
        return Ui.dialog(host, title, content, host.i18n.t("Save Log"), onSave);
    }

    String joinChoices(Set<String> selected) {
        if (selected == null || selected.isEmpty())
            return "";
        StringBuilder builder = new StringBuilder();
        for (String value : selected) {
            if (builder.length() > 0)
                builder.append(", ");
            builder.append(value);
        }
        return builder.toString();
    }

    String noteLine(String label, String value) {
        if (value == null || value.trim().isEmpty())
            return "";
        return label + ": " + value.trim();
    }

    String joinNotes(String... parts) {
        StringBuilder builder = new StringBuilder();
        for (String part : parts) {
            if (part == null || part.trim().isEmpty())
                continue;
            if (builder.length() > 0)
                builder.append("\n");
            builder.append(part.trim());
        }
        return builder.toString();
    }

    int safeInt(String value) {
        try {
            return Integer.parseInt(value.trim());
        } catch (Exception ignored) {
            return 0;
        }
    }

    String durationClock(int seconds) {
        return String.format(Locale.getDefault(), "%02d:%02d", seconds / 60, seconds % 60);
    }

    String durationText(int seconds) {
        if (seconds <= 0)
            return "0 min 0 sec";
        return (seconds / 60) + " min " + (seconds % 60) + " sec";
    }

    String meltdownIntensityText(int value) {
        if (value <= 1)
            return host.i18n.t("Mild Agitation/Crying");
        if (value <= 2)
            return host.i18n.t("Mild Meltdown");
        if (value == 3)
            return host.i18n.t("Moderate Meltdown");
        if (value == 4)
            return host.i18n.t("Strong Meltdown");
        return host.i18n.t("Severe Meltdown/Safety Risk");
    }
}
