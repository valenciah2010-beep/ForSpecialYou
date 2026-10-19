package com.forspecialyou.careportal;

import android.app.Dialog;
import android.graphics.Color;
import android.os.Handler;
import android.os.Looper;
import android.text.InputType;
import android.view.Gravity;
import android.view.MotionEvent;
import android.view.View;
import android.view.ViewGroup;
import android.widget.AdapterView;
import android.widget.Button;
import android.widget.CheckBox;
import android.widget.EditText;
import android.widget.FrameLayout;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.SeekBar;
import android.widget.Spinner;
import android.widget.TextView;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.HashSet;
import java.util.List;
import java.util.Locale;
import java.util.Set;

final class QuickLogForms {

    private final MainActivity host;

    QuickLogForms(MainActivity host) {
        this.host = host;
    }

    void showQuickLogPicker() {
        String key = host.storage.key("health", host.currentUser.id, "quickLogSelection");
        Set<String> selected = host.commaSet(host.storage.getString(key, ""));
        boolean[] checked = new boolean[host.QUICK_LOGS.length];
        LinearLayout content = Ui.v(host, 0);
        content.setPadding(Ui.dp(host, 12), 0, Ui.dp(host, 12), 0);
        for (int i = 0; i < host.QUICK_LOGS.length; i++) {
            checked[i] = selected.contains(host.QUICK_LOGS[i][0]);
            final int index = i;
            LinearLayout row = Ui.h(host, 0);
            row.setGravity(Gravity.CENTER_VERTICAL);
            row.setPadding(Ui.dp(host, 14), Ui.dp(host, 12), Ui.dp(host, 14), Ui.dp(host, 12));
            row.setBackground(Ui.stroke(checked[i] ? Ui.withAlpha(AppColors.ACCENT, 28) : AppColors.PANEL, AppColors.BORDER, Ui.dp(host, 14)));
            row.setClickable(true);
            row.setFocusable(true);
            ImageView icon = host.symbolIcon(host.quickLogIconRes(host.QUICK_LOGS[i][0]), AppColors.TEXT, Color.TRANSPARENT, 34, 4);
            row.addView(icon, Ui.fixed(host, 40, 40));
            TextView label = Ui.text(host, host.i18n.t(host.QUICK_LOGS[i][1]), 16, AppColors.TEXT, android.graphics.Typeface.BOLD);
            LinearLayout.LayoutParams labelParams = new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1);
            labelParams.leftMargin = Ui.dp(host, 10);
            row.addView(label, labelParams);
            CheckBox box = new CheckBox(host);
            box.setChecked(checked[i]);
            box.setClickable(false);
            box.setButtonTintList(android.content.res.ColorStateList.valueOf(AppColors.ACCENT));
            row.addView(box, Ui.fixed(host, 42, 42));
            row.setOnClickListener(v -> {
                checked[index] = !checked[index];
                box.setChecked(checked[index]);
                row.setBackground(Ui.stroke(checked[index] ? Ui.withAlpha(AppColors.ACCENT, 28) : AppColors.PANEL, AppColors.BORDER, Ui.dp(host, 14)));
            });
            content.addView(row, Ui.matchWrap());
            Ui.addSpacer(host, content, 8);
        }
        Ui.dialog(host, host.i18n.t("Choose quick-log buttons"), content, host.i18n.t("Save"), () -> {
            List<String> ordered = host.orderedQuickLogIds(host.storage.getString(key, ""));
            List<String> updated = new ArrayList<>();
            Set<String> added = new HashSet<>();
            for (String id : ordered) {
                int optionIndex = host.quickLogIndex(id);
                if (optionIndex >= 0 && checked[optionIndex]) {
                    updated.add(id);
                    added.add(id);
                }
            }
            for (int i = 0; i < checked.length; i++) {
                String id = host.QUICK_LOGS[i][0];
                if (checked[i] && !added.contains(id)) {
                    updated.add(id);
                }
            }
            host.storage.putString(key, host.joinIds(updated));
            host.render();
        });
    }

    int quickLogIndex(String id) {
        for (int i = 0; i < host.QUICK_LOGS.length; i++) {
            if (host.QUICK_LOGS[i][0].equals(id))
                return i;
        }
        return -1;
    }

    void showHealthLogDialog(String id, String title, String type) {
        if ("sleep".equals(id)) {
            host.showSleepLogDialog(title);
            return;
        }
        if ("digestion".equals(id)) {
            host.showDigestionLogDialog(title);
            return;
        }
        if ("quickLog".equals(type)) {
            switch(id) {
                case "seizure":
                    host.showSeizureTimerDialog(title);
                    return;
                case "meltdown":
                    host.showMeltdownDialog(title);
                    return;
                case "stimming":
                    host.showStimmingDialog(title);
                    return;
                case "accident":
                    host.showAccidentDialog(title);
                    return;
                case "deescalation":
                    host.showDeescalationDialog(title);
                    return;
                case "allergy":
                    host.showAllergyDialog(title);
                    return;
                case "pain":
                    host.showPainDialog(title);
                    return;
                case "skin":
                    host.showSkinDialog(title);
                    return;
                case "discomfort":
                    host.showDiscomfortDialog(title);
                    return;
                case "medsFood":
                    host.showMedicineDialog(title);
                    return;
                case "cyclicVomiting":
                    host.showCyclicVomitingDialog(title);
                    return;
                default:
                    break;
            }
        }
        LinearLayout content = Ui.v(host, 0);
        content.setPadding(Ui.dp(host, 12), 0, Ui.dp(host, 12), 0);
        Calendar timestamp = Calendar.getInstance();
        content.addView(host.timestampCard(timestamp), Ui.matchWrap());
        Ui.addSpacer(host, content, 12);
        EditText value = Ui.edit(host, host.i18n.t(title));
        if ("height".equals(id) || "weight".equals(id)) {
            value.setInputType(InputType.TYPE_CLASS_NUMBER | InputType.TYPE_NUMBER_FLAG_DECIMAL);
        }
        EditText notes = Ui.multi(host, "Notes");
        content.addView(Ui.fieldGroup(host, host.i18n.t(title), value), Ui.matchWrap());
        Ui.addSpacer(host, content, 12);
        content.addView(Ui.fieldGroup(host, "Notes", notes), Ui.matchWrap());
        Ui.dialog(host, host.i18n.t(title), content, host.i18n.t("Save"), () -> {
            String cleanValue = value.getText().toString().trim();
            host.addHealthEntry(id, title, type, cleanValue.isEmpty() ? host.i18n.t(title) : cleanValue, notes.getText().toString().trim(), timestamp);
            host.render();
        });
    }

    void showSeizureTimerDialog(String title) {
        Calendar timestamp = Calendar.getInstance();
        LinearLayout content = host.quickFormContent();
        int seizureRed = Color.rgb(248, 82, 82);
        LinearLayout timerCard = Ui.panel(host);
        timerCard.setPadding(Ui.dp(host, 18), Ui.dp(host, 26), Ui.dp(host, 18), Ui.dp(host, 22));
        timerCard.setBackground(Ui.stroke(AppColors.PANEL, Ui.withAlpha(AppColors.BORDER, 150), Ui.dp(host, 20)));
        TextView timerIcon = Ui.text(host, "↻", 44, seizureRed, android.graphics.Typeface.BOLD);
        timerIcon.setGravity(Gravity.CENTER);
        timerIcon.setBackground(Ui.round(Ui.withAlpha(seizureRed, 32), Ui.dp(host, 48)));
        LinearLayout.LayoutParams timerIconParams = Ui.fixed(host, 96, 96);
        timerIconParams.gravity = Gravity.CENTER_HORIZONTAL;
        timerCard.addView(timerIcon, timerIconParams);
        Ui.addSpacer(host, timerCard, 14);
        TextView timerText = Ui.text(host, "00:00", 48, AppColors.TEXT, android.graphics.Typeface.BOLD);
        timerText.setGravity(Gravity.CENTER);
        timerCard.addView(timerText, Ui.matchWrap());
        TextView timerStatus = Ui.text(host, host.i18n.t("Timer running"), 16, AppColors.MUTED, android.graphics.Typeface.BOLD);
        timerStatus.setGravity(Gravity.CENTER);
        timerCard.addView(timerStatus, Ui.matchWrap());
        Ui.addSpacer(host, timerCard, 18);
        LinearLayout controls = Ui.h(host, 0);
        Button pause = Ui.secondary(host, host.i18n.t("Pause"));
        Button stop = Ui.secondary(host, host.i18n.t("Stop"));
        stop.setTextColor(AppColors.PANEL);
        stop.setBackground(Ui.stroke(Color.rgb(255, 54, 64), Color.rgb(255, 54, 64), Ui.dp(host, 14)));
        Button skip = Ui.secondary(host, host.i18n.t("Skip"));
        LinearLayout.LayoutParams leftControlParams = new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1);
        leftControlParams.setMargins(0, 0, Ui.dp(host, 6), 0);
        LinearLayout.LayoutParams rightControlParams = new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1);
        rightControlParams.setMargins(Ui.dp(host, 6), 0, 0, 0);
        controls.addView(pause, leftControlParams);
        controls.addView(stop, rightControlParams);
        timerCard.addView(controls, Ui.matchWrap());
        Ui.addSpacer(host, timerCard, 8);
        skip.setBackground(Ui.stroke(AppColors.PANEL, Ui.withAlpha(AppColors.BORDER, 110), Ui.dp(host, 14)));
        timerCard.addView(skip, Ui.matchWrap());
        content.addView(timerCard, Ui.matchWrap());
        Ui.addSpacer(host, content, 12);
        LinearLayout details = Ui.v(host, 0);
        details.setVisibility(View.GONE);
        details.addView(host.timestampCard(timestamp), Ui.matchWrap());
        Ui.addSpacer(host, details, 12);
        LinearLayout durationCard = host.sectionCard(host.i18n.t("Edit Duration"));
        LinearLayout editRow = Ui.h(host, 0);
        EditText minutes = Ui.edit(host, host.i18n.t("Minutes"));
        minutes.setInputType(InputType.TYPE_CLASS_NUMBER);
        minutes.setText("0");
        EditText seconds = Ui.edit(host, host.i18n.t("Seconds"));
        seconds.setInputType(InputType.TYPE_CLASS_NUMBER);
        seconds.setText("0");
        LinearLayout.LayoutParams durationLeft = new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1);
        durationLeft.setMargins(0, 0, Ui.dp(host, 6), 0);
        LinearLayout.LayoutParams durationRight = new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1);
        durationRight.setMargins(Ui.dp(host, 6), 0, 0, 0);
        editRow.addView(Ui.fieldGroup(host, host.i18n.t("Minutes"), minutes), durationLeft);
        editRow.addView(Ui.fieldGroup(host, host.i18n.t("Seconds"), seconds), durationRight);
        durationCard.addView(editRow, Ui.matchWrap());
        details.addView(durationCard, Ui.matchWrap());
        Ui.addSpacer(host, details, 12);
        String[] seizureTypes = { host.i18n.t("Seizure Type"), "Tonic-clonic", "Absence", "Focal", "Atonic", "Myoclonic", host.i18n.t("Other") };
        Spinner typeSpinner = host.spinner(seizureTypes);
        details.addView(host.fieldCard(host.i18n.t("Seizure Type"), typeSpinner), Ui.matchWrap());
        Ui.addSpacer(host, details, 12);
        EditText triggers = Ui.multi(host, host.i18n.t("flashing lights, missed sleep, heat, illness, etc."));
        details.addView(Ui.fieldGroup(host, host.i18n.t("Triggers"), triggers), Ui.matchWrap());
        Ui.addSpacer(host, details, 12);
        EditText postNotes = Ui.multi(host, host.i18n.t("Post-event notes"));
        details.addView(Ui.fieldGroup(host, host.i18n.t("Post-event notes"), postNotes), Ui.matchWrap());
        content.addView(details, Ui.matchWrap());
        Handler handler = new Handler(Looper.getMainLooper());
        int[] elapsed = { 0 };
        boolean[] running = { true };
        Runnable[] tick = new Runnable[1];
        tick[0] = () -> {
            if (running[0]) {
                elapsed[0] += 1;
                minutes.setText(String.valueOf(elapsed[0] / 60));
                seconds.setText(String.valueOf(elapsed[0] % 60));
                timerText.setText(host.durationClock(elapsed[0]));
            }
            handler.postDelayed(tick[0], 1000);
        };
        Dialog dialog = host.showQuickLogForm(host.i18n.t(title), content, () -> {
            int totalSeconds = host.safeInt(minutes.getText().toString()) * 60 + host.safeInt(seconds.getText().toString());
            String type = String.valueOf(typeSpinner.getSelectedItem());
            String value = host.durationText(totalSeconds);
            if (!type.equals(host.i18n.t("Seizure Type"))) {
                value += " · " + type;
            }
            String notes = host.joinNotes(host.noteLine(host.i18n.t("Triggers"), triggers.getText().toString()), host.noteLine(host.i18n.t("Post-event notes"), postNotes.getText().toString()));
            host.addHealthEntry("seizure", title, "quickLog", value, notes, timestamp);
            host.render();
        });
        Runnable revealDetails = () -> {
            if (details.getVisibility() != View.VISIBLE) {
                details.setVisibility(View.VISIBLE);
            }
        };
        pause.setOnClickListener(v -> {
            revealDetails.run();
            running[0] = !running[0];
            pause.setText(host.i18n.t(running[0] ? "Pause" : "Resume"));
            timerStatus.setText(host.i18n.t(running[0] ? "Timer running" : "Timer paused"));
        });
        stop.setOnClickListener(v -> {
            revealDetails.run();
            running[0] = false;
            timerStatus.setText(host.i18n.t("Timer stopped"));
            pause.setText(host.i18n.t("Resume"));
        });
        skip.setOnClickListener(v -> {
            revealDetails.run();
            running[0] = false;
            elapsed[0] = 0;
            minutes.setText("0");
            seconds.setText("0");
            timerText.setText("00:00");
            timerStatus.setText(host.i18n.t("Skipped timer"));
            pause.setText(host.i18n.t("Resume"));
        });
        dialog.setOnDismissListener(d -> handler.removeCallbacks(tick[0]));
        handler.postDelayed(tick[0], 1000);
    }

    void showMeltdownDialog(String title) {
        Calendar timestamp = Calendar.getInstance();
        int tint = host.quickLogColor("meltdown");
        LinearLayout content = host.quickFormContent();
        content.addView(host.timestampCard(timestamp), Ui.matchWrap());
        Ui.addSpacer(host, content, 12);
        int[] intensity = { 3 };
        TextView badge = Ui.text(host, "3/5", 16, Color.rgb(220, 145, 26), android.graphics.Typeface.BOLD);
        TextView label = Ui.text(host, host.i18n.t("Moderate Meltdown"), 14, Color.rgb(220, 145, 26), android.graphics.Typeface.BOLD);
        SeekBar seek = new SeekBar(host);
        seek.setMax(4);
        seek.setProgress(2);
        seek.setOnSeekBarChangeListener(new MainActivity.SimpleSeekListener(progress -> {
            intensity[0] = progress + 1;
            badge.setText(intensity[0] + "/5");
            label.setText(host.meltdownIntensityText(intensity[0]));
        }));
        host.tintSeekBar(seek, Color.rgb(247, 190, 54));
        LinearLayout intensityCard = host.sectionCard("〰 " + host.i18n.t("Intensity"));
        LinearLayout promptRow = Ui.h(host, 0);
        promptRow.setGravity(Gravity.CENTER_VERTICAL);
        promptRow.addView(Ui.text(host, host.i18n.t("How intense was it?"), 15, AppColors.MUTED, android.graphics.Typeface.BOLD), new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1));
        badge.setGravity(Gravity.CENTER);
        badge.setBackground(Ui.stroke(Ui.withAlpha(Color.rgb(247, 190, 54), 28), Color.rgb(247, 190, 54), Ui.dp(host, 18)));
        badge.setPadding(Ui.dp(host, 12), Ui.dp(host, 6), Ui.dp(host, 12), Ui.dp(host, 6));
        promptRow.addView(badge, Ui.wrapWrap());
        intensityCard.addView(promptRow, Ui.matchWrap());
        Ui.addSpacer(host, intensityCard, 12);
        intensityCard.addView(seek, Ui.matchWrap());
        Ui.addSpacer(host, intensityCard, 8);
        label.setGravity(Gravity.CENTER);
        label.setBackground(Ui.round(Ui.withAlpha(Color.rgb(247, 190, 54), 24), Ui.dp(host, 18)));
        label.setPadding(Ui.dp(host, 12), Ui.dp(host, 6), Ui.dp(host, 12), Ui.dp(host, 6));
        intensityCard.addView(label, Ui.matchWrap());
        content.addView(intensityCard, Ui.matchWrap());
        Ui.addSpacer(host, content, 12);
        Set<String> triggers = new HashSet<>();
        content.addView(host.chipSection(host.i18n.t("Triggers"), new String[] { "🔊 Loud Noise", "👥 Crowds", "🔄 Transitioning", "🍽 Hunger", "🌙 Fatigue", "❔ Unknown" }, triggers, tint), Ui.matchWrap());
        Ui.addSpacer(host, content, 12);
        String[] duration = { "" };
        content.addView(host.singleChoiceSection(host.i18n.t("Duration"), new String[] { "<5 mins", "5-15 mins", "15-30 mins", "30+ mins" }, duration, tint), Ui.matchWrap());
        Ui.addSpacer(host, content, 12);
        Set<String> calming = new HashSet<>();
        content.addView(host.chipSection(host.i18n.t("Calming Tools Tried"), new String[] { "🫶 Deep Pressure", "🎧 Headphones", "💡 Dim Lights", "🛏 Weighted Blanket", "↩ Redirection" }, calming, tint), Ui.matchWrap());
        Ui.addSpacer(host, content, 12);
        EditText notes = Ui.multi(host, host.i18n.t("Notes"));
        content.addView(Ui.fieldGroup(host, host.i18n.t("Notes"), notes), Ui.matchWrap());
        host.showQuickLogForm(host.i18n.t("Log Meltdown"), content, () -> {
            String value = intensity[0] + "/5 · " + host.meltdownIntensityText(intensity[0]);
            if (!duration[0].isEmpty())
                value += " · " + duration[0];
            String detail = host.joinNotes(host.noteLine(host.i18n.t("Triggers"), host.joinChoices(triggers)), host.noteLine(host.i18n.t("Calming Tools Tried"), host.joinChoices(calming)), notes.getText().toString().trim());
            host.addHealthEntry("meltdown", title, "quickLog", value, detail, timestamp);
            host.render();
        });
    }

    void showStimmingDialog(String title) {
        Calendar timestamp = Calendar.getInstance();
        int tint = host.quickLogColor("stimming");
        LinearLayout content = host.quickFormContent();
        content.addView(host.timestampCard(timestamp), Ui.matchWrap());
        Ui.addSpacer(host, content, 12);
        Set<String> behaviors = new HashSet<>();
        content.addView(host.chipSection(host.i18n.t("Behavior Type"), new String[] { "👋 Hand Flapping", "🔊 Vocal Tics/Sounds", "↔ Rocking", "🚶 Pacing", "👁 Eye Blinking", "🙂 Head Shaking", "💬 Repetitive Phrases" }, behaviors, tint), Ui.matchWrap());
        Ui.addSpacer(host, content, 12);
        String[] frequency = { "" };
        content.addView(host.singleChoiceSection(host.i18n.t("Frequency"), new String[] { "Low (Occasional)", "Medium (Frequent)", "High (Constant)" }, frequency, tint), Ui.matchWrap());
        Ui.addSpacer(host, content, 12);
        String[] state = { "" };
        content.addView(host.singleChoiceSection(host.i18n.t("Apparent State"), new String[] { "Joyful/Regulating", "Anxious/Stressed" }, state, tint), Ui.matchWrap());
        Ui.addSpacer(host, content, 12);
        Set<String> context = new HashSet<>();
        content.addView(host.chipSection(host.i18n.t("Context / Setting"), new String[] { "🏫 School/Therapy", "📱 Screen Time", "🔄 Transitioning", "🏙 Public Place", "🏠 Relaxing at Home" }, context, tint), Ui.matchWrap());
        Ui.addSpacer(host, content, 12);
        EditText notes = Ui.multi(host, host.i18n.t("Notes"));
        content.addView(Ui.fieldGroup(host, host.i18n.t("Notes"), notes), Ui.matchWrap());
        host.showQuickLogForm(host.i18n.t(title), content, () -> {
            String value = (frequency[0].isEmpty() ? host.i18n.t("Stimming/Tics") : frequency[0]) + (state[0].isEmpty() ? "" : " · " + state[0]);
            String detail = host.joinNotes(host.noteLine(host.i18n.t("Behavior Type"), host.joinChoices(behaviors)), host.noteLine(host.i18n.t("Context / Setting"), host.joinChoices(context)), notes.getText().toString().trim());
            host.addHealthEntry("stimming", title, "quickLog", value, detail, timestamp);
            host.render();
        });
    }

    void showAccidentDialog(String title) {
        Calendar timestamp = Calendar.getInstance();
        int tint = host.quickLogColor("accident");
        LinearLayout content = host.quickFormContent();
        content.addView(host.timestampCard(timestamp), Ui.matchWrap());
        Ui.addSpacer(host, content, 12);
        String[] accidentType = { "" };
        content.addView(host.singleChoiceSection(host.i18n.t("Accident Type"), new String[] { "Urine", "Stool", "Both" }, accidentType, tint), Ui.matchWrap());
        Ui.addSpacer(host, content, 12);
        Set<String> context = new HashSet<>();
        content.addView(host.chipSection(host.i18n.t("Context / Setting"), new String[] { "🎯 Deep in Play", "🚌 On the Bus/Transition", "🏫 School/Therapy", "🛌 During Sleep" }, context, tint), Ui.matchWrap());
        Ui.addSpacer(host, content, 12);
        String[] signaled = { "" };
        content.addView(host.singleChoiceSection(host.i18n.t("Did they signal or try to go?"), new String[] { "Yes", "No" }, signaled, tint), Ui.matchWrap());
        Ui.addSpacer(host, content, 12);
        EditText notes = Ui.multi(host, host.i18n.t("Notes"));
        content.addView(Ui.fieldGroup(host, host.i18n.t("Notes"), notes), Ui.matchWrap());
        host.showQuickLogForm(host.i18n.t(title), content, () -> {
            String value = accidentType[0].isEmpty() ? host.i18n.t("Accident") : accidentType[0];
            String detail = host.joinNotes(host.noteLine(host.i18n.t("Context / Setting"), host.joinChoices(context)), host.noteLine(host.i18n.t("Signaled Beforehand?"), signaled[0]), notes.getText().toString().trim());
            host.addHealthEntry("accident", title, "quickLog", value, detail, timestamp);
            host.render();
        });
    }

    void showDeescalationDialog(String title) {
        Calendar timestamp = Calendar.getInstance();
        int tint = host.quickLogColor("deescalation");
        LinearLayout content = host.quickFormContent();
        content.addView(host.timestampCard(timestamp), Ui.matchWrap());
        Ui.addSpacer(host, content, 12);
        Set<String> tools = new HashSet<>();
        content.addView(host.chipSection(host.i18n.t("Tools Used"), new String[] { "🎧 Headphones", "🧱 Deep Pressure", "💡 Dimmed Lights", "🛏 Weighted Blanket", "🔄 Redirection/Distraction", "🧘 Quiet Space" }, tools, tint), Ui.matchWrap());
        Ui.addSpacer(host, content, 12);
        String[] effectiveness = { "" };
        content.addView(host.singleChoiceSection(host.i18n.t("Effectiveness"), new String[] { "Not Effective", "Somewhat Effective", "Highly Effective" }, effectiveness, tint), Ui.matchWrap());
        Ui.addSpacer(host, content, 12);
        String[] baseline = { "" };
        content.addView(host.singleChoiceSection(host.i18n.t("Time to Baseline"), new String[] { "<5 mins", "5-15 mins", "15-30 mins", "30+ mins" }, baseline, tint), Ui.matchWrap());
        Ui.addSpacer(host, content, 12);
        EditText notes = Ui.multi(host, host.i18n.t("Notes"));
        content.addView(Ui.fieldGroup(host, host.i18n.t("Notes"), notes), Ui.matchWrap());
        host.showQuickLogForm(host.i18n.t(title), content, () -> {
            String value = effectiveness[0].isEmpty() ? host.i18n.t("De-escalation") : effectiveness[0];
            if (!baseline[0].isEmpty())
                value += " · " + baseline[0];
            String detail = host.joinNotes(host.noteLine(host.i18n.t("Tools Used"), host.joinChoices(tools)), notes.getText().toString().trim());
            host.addHealthEntry("deescalation", title, "quickLog", value, detail, timestamp);
            host.render();
        });
    }

    void showAllergyDialog(String title) {
        Calendar timestamp = Calendar.getInstance();
        int tint = host.quickLogColor("allergy");
        LinearLayout content = host.quickFormContent();
        content.addView(host.timestampCard(timestamp), Ui.matchWrap());
        Ui.addSpacer(host, content, 12);
        String[] severity = { "" };
        content.addView(host.singleChoiceSection(host.i18n.t("Severity Level"), new String[] { "Mild", "Moderate", "Severe" }, severity, tint), Ui.matchWrap());
        Ui.addSpacer(host, content, 12);
        Set<String> triggers = new HashSet<>();
        content.addView(host.chipSection(host.i18n.t("Suspected Trigger"), new String[] { "🥣 New Food", "💊 Medication", "🌿 Environmental/Outdoor", "🧼 Detergent/Soap", "🐝 Insect Bite", "❔ Unknown" }, triggers, tint), Ui.matchWrap());
        Ui.addSpacer(host, content, 12);
        Set<String> symptoms = new HashSet<>();
        content.addView(host.chipSection(host.i18n.t("Symptoms"), new String[] { "🩹 Hives/Rash", "😣 Itching", "💢 Swelling", "🤢 Vomiting", "😮‍💨 Trouble Breathing", "😢 Irritation/Crying" }, symptoms, tint), Ui.matchWrap());
        Ui.addSpacer(host, content, 12);
        EditText notes = Ui.multi(host, host.i18n.t("Notes"));
        content.addView(Ui.fieldGroup(host, host.i18n.t("Notes"), notes), Ui.matchWrap());
        host.showQuickLogForm(host.i18n.t(title), content, () -> {
            String value = severity[0].isEmpty() ? host.i18n.t("Allergic Reaction") : severity[0];
            if (!symptoms.isEmpty())
                value += " · " + host.joinChoices(symptoms);
            String detail = host.joinNotes(host.noteLine(host.i18n.t("Suspected Trigger"), host.joinChoices(triggers)), notes.getText().toString().trim());
            host.addHealthEntry("allergy", title, "quickLog", value, detail, timestamp);
            if ("Severe".equals(severity[0]) || host.joinChoices(symptoms).contains("Trouble Breathing")) {
                host.showMessageSheet(host.i18n.t("Seek immediate medical attention"), host.i18n.t("Severe allergic symptoms can require urgent care or an EpiPen if prescribed."));
            }
            host.render();
        });
    }

    void showPainDialog(String title) {
        Calendar timestamp = Calendar.getInstance();
        int tint = host.quickLogColor("pain");
        LinearLayout content = host.quickFormContent();
        content.addView(host.timestampCard(timestamp), Ui.matchWrap());
        Ui.addSpacer(host, content, 12);
        int[] severity = { 3 };
        TextView badge = Ui.text(host, "3/5", 16, AppColors.ACCENT, android.graphics.Typeface.BOLD);
        SeekBar seek = new SeekBar(host);
        seek.setMax(4);
        seek.setProgress(2);
        seek.setOnSeekBarChangeListener(new MainActivity.SimpleSeekListener(progress -> {
            severity[0] = progress + 1;
            badge.setText(severity[0] + "/5");
        }));
        LinearLayout severityCard = host.sectionCard("✚ " + host.i18n.t("Severity"));
        severityCard.addView(badge, Ui.wrapWrap());
        severityCard.addView(seek, Ui.matchWrap());
        content.addView(severityCard, Ui.matchWrap());
        Ui.addSpacer(host, content, 12);
        List<String> locations = new ArrayList<>();
        content.addView(host.painLocationMap(locations), Ui.matchWrap());
        Ui.addSpacer(host, content, 12);
        EditText indicators = Ui.multi(host, host.i18n.t("crying, holding head, aggression"));
        content.addView(Ui.fieldGroup(host, host.i18n.t("Indicators"), indicators), Ui.matchWrap());
        Ui.addSpacer(host, content, 12);
        EditText comments = Ui.multi(host, host.i18n.t("Short comment"));
        content.addView(Ui.fieldGroup(host, host.i18n.t("Short comment"), comments), Ui.matchWrap());
        host.showQuickLogForm(host.i18n.t(title), content, () -> {
            String value = severity[0] + "/5 · " + (locations.isEmpty() ? host.i18n.t("Pain") : host.joinLocationPoints(locations));
            String detail = host.joinNotes(host.noteLine(host.i18n.t("Indicators"), indicators.getText().toString()), comments.getText().toString().trim());
            host.addHealthEntry("pain", title, "quickLog", value, detail, timestamp);
            host.render();
        });
    }

    LinearLayout painLocationMap(List<String> points) {
        LinearLayout card = host.sectionCard(host.i18n.t("Pain Location"));
        FrameLayout map = new FrameLayout(host);
        map.setBackground(Ui.round(AppColors.BACKGROUND, Ui.dp(host, 14)));
        ImageView image = new ImageView(host);
        image.setImageResource(R.drawable.pain_location_body);
        image.setScaleType(ImageView.ScaleType.FIT_CENTER);
        image.setAdjustViewBounds(true);
        map.addView(image, new FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, Ui.dp(host, 330), Gravity.CENTER));
        map.setOnTouchListener((view, event) -> {
            if (event.getAction() != MotionEvent.ACTION_UP)
                return true;
            float x = event.getX();
            float y = event.getY();
            int hitIndex = host.nearestPainPoint(points, x, y);
            if (hitIndex >= 0) {
                points.remove(hitIndex);
                host.redrawPainDots(map, points);
                return true;
            }
            if (points.size() >= 5 || !host.isInsidePainBodyArea(map, x, y))
                return true;
            points.add(Math.round(x) + "," + Math.round(y));
            host.redrawPainDots(map, points);
            return true;
        });
        card.addView(map, Ui.matchWrap());
        return card;
    }

    int nearestPainPoint(List<String> points, float x, float y) {
        for (int i = 0; i < points.size(); i++) {
            String[] parts = points.get(i).split(",");
            if (parts.length != 2)
                continue;
            float px = host.safeInt(parts[0]);
            float py = host.safeInt(parts[1]);
            double distance = Math.hypot(px - x, py - y);
            if (distance <= Ui.dp(host, 22))
                return i;
        }
        return -1;
    }

    boolean isInsidePainBodyArea(FrameLayout map, float x, float y) {
        int width = Math.max(1, map.getWidth());
        int height = Math.max(1, map.getHeight());
        float nx = x / width;
        float ny = y / height;
        return nx > 0.18f && nx < 0.82f && ny > 0.04f && ny < 0.96f;
    }

    void redrawPainDots(FrameLayout map, List<String> points) {
        while (map.getChildCount() > 1) {
            map.removeViewAt(1);
        }
        for (String point : points) {
            String[] parts = point.split(",");
            if (parts.length != 2)
                continue;
            TextView dot = Ui.text(host, "", 1, Color.WHITE, android.graphics.Typeface.BOLD);
            dot.setBackground(Ui.round(host.quickLogColor("pain"), Ui.dp(host, 8)));
            FrameLayout.LayoutParams params = new FrameLayout.LayoutParams(Ui.dp(host, 16), Ui.dp(host, 16));
            params.leftMargin = host.safeInt(parts[0]) - Ui.dp(host, 8);
            params.topMargin = host.safeInt(parts[1]) - Ui.dp(host, 8);
            map.addView(dot, params);
        }
    }

    String joinLocationPoints(List<String> points) {
        StringBuilder builder = new StringBuilder();
        for (int i = 0; i < points.size(); i++) {
            if (builder.length() > 0)
                builder.append(", ");
            builder.append(host.i18n.t("Point")).append(" ").append(i + 1);
        }
        return builder.toString();
    }

    void showDiscomfortDialog(String title) {
        Calendar timestamp = Calendar.getInstance();
        int tint = host.quickLogColor("discomfort");
        LinearLayout content = host.quickFormContent();
        content.addView(host.timestampCard(timestamp), Ui.matchWrap());
        Ui.addSpacer(host, content, 12);
        int[] severity = { 3 };
        TextView badge = Ui.text(host, "3/5", 16, tint, android.graphics.Typeface.BOLD);
        SeekBar seek = new SeekBar(host);
        seek.setMax(4);
        seek.setProgress(2);
        seek.setOnSeekBarChangeListener(new MainActivity.SimpleSeekListener(progress -> {
            severity[0] = progress + 1;
            badge.setText(severity[0] + "/5");
        }));
        LinearLayout severityCard = host.sectionCard("🌡 " + host.i18n.t("Severity"));
        severityCard.addView(badge, Ui.wrapWrap());
        severityCard.addView(seek, Ui.matchWrap());
        content.addView(severityCard, Ui.matchWrap());
        Ui.addSpacer(host, content, 12);
        Set<String> signs = new HashSet<>();
        content.addView(host.chipSection(host.i18n.t("Signs"), new String[] { "😢 Crying", "🫱 Guarding body", "😠 Irritable", "😣 Restless", "🍽 Reduced appetite", "🌙 Sleepy" }, signs, tint), Ui.matchWrap());
        Ui.addSpacer(host, content, 12);
        Set<String> possibleCauses = new HashSet<>();
        content.addView(host.chipSection(host.i18n.t("Possible Cause"), new String[] { "🍽 Hunger", "🌙 Fatigue", "🚽 Constipation", "🤒 Illness", "🔥 Heat", "❔ Unknown" }, possibleCauses, tint), Ui.matchWrap());
        Ui.addSpacer(host, content, 12);
        EditText notes = Ui.multi(host, host.i18n.t("Notes"));
        content.addView(Ui.fieldGroup(host, host.i18n.t("Notes"), notes), Ui.matchWrap());
        host.showQuickLogForm(host.i18n.t(title), content, () -> {
            String value = severity[0] + "/5";
            if (!signs.isEmpty())
                value += " · " + host.joinChoices(signs);
            String detail = host.joinNotes(host.noteLine(host.i18n.t("Possible Cause"), host.joinChoices(possibleCauses)), notes.getText().toString().trim());
            host.addHealthEntry("discomfort", title, "quickLog", value, detail, timestamp);
            host.render();
        });
    }

    void showSkinDialog(String title) {
        Calendar timestamp = Calendar.getInstance();
        int tint = host.quickLogColor("skin");
        String[] photoData = { "" };
        LinearLayout content = host.quickFormContent();
        content.addView(host.photoControls("Skin Photo", photoData), Ui.matchWrap());
        Ui.addSpacer(host, content, 12);
        content.addView(host.timestampCard(timestamp), Ui.matchWrap());
        Ui.addSpacer(host, content, 12);
        String[] severity = { "" };
        content.addView(host.skinSeveritySection(severity), Ui.matchWrap());
        Ui.addSpacer(host, content, 12);
        Set<String> locations = new HashSet<>();
        content.addView(host.chipSection(host.i18n.t("Location"), new String[] { "Face/Neck", "Torso", "Arms", "Legs", "Full Body" }, locations, tint), Ui.matchWrap());
        Ui.addSpacer(host, content, 12);
        Set<String> triggers = new HashSet<>();
        content.addView(host.chipSection(host.i18n.t("Suspected Trigger"), new String[] { "New Food", "Medication", "Environmental/Outdoor", "Detergent/Soap", "Unknown" }, triggers, tint), Ui.matchWrap());
        Ui.addSpacer(host, content, 12);
        Set<String> symptoms = new HashSet<>();
        content.addView(host.chipSection(host.i18n.t("Symptom Tags"), new String[] { "Itching/Scratching", "Heat/Feverish skin", "Swelling", "Irritation/Crying" }, symptoms, tint), Ui.matchWrap());
        Ui.addSpacer(host, content, 12);
        EditText notes = Ui.multi(host, host.i18n.t("Notes"));
        content.addView(Ui.fieldGroup(host, host.i18n.t("Notes"), notes), Ui.matchWrap());
        host.showQuickLogForm(host.i18n.t(title), content, () -> {
            String value = severity[0].isEmpty() ? host.i18n.t("Skin") : severity[0];
            if (!locations.isEmpty())
                value += " · " + host.joinChoices(locations);
            String detail = host.joinNotes(host.noteLine(host.i18n.t("Suspected Trigger"), host.joinChoices(triggers)), host.noteLine(host.i18n.t("Symptom Tags"), host.joinChoices(symptoms)), photoData[0].isEmpty() ? "" : host.i18n.t("Photo attached"), notes.getText().toString().trim());
            host.addHealthEntry("skin", title, "quickLog", value, detail, timestamp, photoData[0]);
            if ("Severe".equals(severity[0])) {
                host.showMessageSheet(host.i18n.t("Seek immediate medical attention"), host.i18n.t("Severe skin symptoms can require urgent care or an EpiPen if prescribed."));
            }
            host.render();
        });
    }

    LinearLayout skinSeveritySection(String[] selected) {
        LinearLayout card = host.sectionCard(host.i18n.t("Severity Level"));
        LinearLayout rows = Ui.v(host, 0);
        String[][] options = { { "Mild", "Localized redness, slight itch, isolated spots", String.valueOf(Color.rgb(103, 199, 137)) }, { "Moderate", "Spreading hives, widespread rash, significant scratching", String.valueOf(Color.rgb(247, 181, 57)) }, { "Severe", "Rapidly spreading, swelling of face/lips", String.valueOf(Color.rgb(239, 58, 58)) } };
        List<LinearLayout> rowViews = new ArrayList<>();
        for (String[] option : options) {
            LinearLayout row = Ui.h(host, 0);
            row.setGravity(Gravity.CENTER_VERTICAL);
            row.setPadding(Ui.dp(host, 14), Ui.dp(host, 12), Ui.dp(host, 14), Ui.dp(host, 12));
            row.setBackground(Ui.round(AppColors.FIELD, Ui.dp(host, 18)));
            TextView dot = Ui.text(host, "", 1, Color.WHITE, android.graphics.Typeface.BOLD);
            dot.setBackground(Ui.round(Integer.parseInt(option[2]), Ui.dp(host, 6)));
            row.addView(dot, Ui.fixed(host, 12, 12));
            Ui.addSpacerHorizontal(host, row, 12);
            LinearLayout copy = Ui.v(host, 0);
            copy.addView(Ui.text(host, host.i18n.t(option[0]), 17, AppColors.TEXT, android.graphics.Typeface.BOLD), Ui.matchWrap());
            copy.addView(Ui.text(host, host.i18n.t(option[1]), 13, AppColors.MUTED, android.graphics.Typeface.BOLD), Ui.matchWrap());
            row.addView(copy, new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1));
            TextView radio = Ui.text(host, "○", 26, AppColors.MUTED, android.graphics.Typeface.BOLD);
            radio.setGravity(Gravity.CENTER);
            row.addView(radio, Ui.fixed(host, 34, 34));
            row.setOnClickListener(v -> {
                selected[0] = option[0].equals(selected[0]) ? "" : option[0];
                for (LinearLayout rowView : rowViews) {
                    String[] meta = (String[]) rowView.getTag();
                    String value = meta[0];
                    int rowColor = Integer.parseInt(meta[1]);
                    boolean isSelected = value.equals(selected[0]);
                    rowView.setBackground(Ui.stroke(isSelected ? Ui.withAlpha(rowColor, 28) : AppColors.FIELD, isSelected ? rowColor : AppColors.FIELD, Ui.dp(host, 18)));
                    TextView mark = (TextView) rowView.getChildAt(3);
                    mark.setText(isSelected ? "●" : "○");
                    mark.setTextColor(isSelected ? rowColor : AppColors.MUTED);
                }
            });
            row.setTag(new String[] { option[0], option[2] });
            rowViews.add(row);
            rows.addView(row, Ui.matchWrap());
            Ui.addSpacer(host, rows, 10);
        }
        card.addView(rows, Ui.matchWrap());
        return card;
    }

    void showMedicineDialog(String title) {
        Calendar timestamp = Calendar.getInstance();
        LinearLayout content = host.quickFormContent();
        TextView date = Ui.text(host, new SimpleDateFormat("EEEE, MMM d, yyyy", Locale.getDefault()).format(timestamp.getTime()), 16, AppColors.TEXT, android.graphics.Typeface.BOLD);
        content.addView(date, Ui.matchWrap());
        Ui.addSpacer(host, content, 12);
        Button add = Ui.secondary(host, "+ " + host.i18n.t("Add Medicine"));
        content.addView(add, Ui.matchWrap());
        Ui.addSpacer(host, content, 12);
        JSONArray meds = host.storage.getArray(host.storage.key("health", host.currentUser.id, "androidMedicines"));
        Set<String> checked = new HashSet<>();
        LinearLayout list = Ui.v(host, 0);
        if (meds.length() == 0) {
            list.addView(Ui.muted(host, host.i18n.t("None")), Ui.matchWrap());
        } else {
            List<JSONObject> rows = host.medicineDoseRows(meds);
            for (JSONObject row : rows) {
                String doseId = row.optString("id");
                CheckBox box = Ui.check(host, row.optString("time", "") + "  " + host.medicineDoseLabel(row));
                box.setOnCheckedChangeListener((buttonView, isChecked) -> {
                    if (isChecked)
                        checked.add(doseId);
                    else
                        checked.remove(doseId);
                });
                list.addView(box, Ui.matchWrap());
                Ui.addSpacer(host, list, 8);
            }
        }
        content.addView(host.sectionCardWithChild(host.i18n.t("Today's Medicines"), list), Ui.matchWrap());
        add.setOnClickListener(v -> host.showAddMedicineDialog(() -> {
            host.showMedicineDialog(title);
        }));
        host.showQuickLogForm(host.i18n.t(title), content, () -> {
            JSONArray currentMeds = host.storage.getArray(host.storage.key("health", host.currentUser.id, "androidMedicines"));
            StringBuilder value = new StringBuilder();
            List<JSONObject> rows = host.medicineDoseRows(currentMeds);
            for (JSONObject row : rows) {
                String doseId = row.optString("id");
                if (value.length() > 0)
                    value.append("\n");
                value.append(checked.contains(doseId) ? "Checked - " : "Not checked - ");
                value.append(row.optString("time", "")).append(" ").append(host.medicineDoseLabel(row));
            }
            host.addHealthEntry("medsFood", title, "quickLog", value.length() == 0 ? host.i18n.t("None") : value.toString(), "", timestamp);
            host.render();
        });
    }

    void showAddMedicineDialog(Runnable afterSave) {
        LinearLayout content = host.quickFormContent();
        EditText name = Ui.edit(host, host.i18n.t("Medicine Name"));
        EditText dose = Ui.edit(host, host.i18n.t("Dose"));
        content.addView(Ui.fieldGroup(host, host.i18n.t("Medicine Name"), name), Ui.matchWrap());
        Ui.addSpacer(host, content, 12);
        content.addView(Ui.fieldGroup(host, host.i18n.t("Dose"), dose), Ui.matchWrap());
        Ui.addSpacer(host, content, 12);
        Spinner frequency = host.spinner(new String[] { host.i18n.t("Frequency"), host.i18n.t("Daily"), host.i18n.t("Every X days"), host.i18n.t("Certain days of the week") });
        content.addView(host.fieldCard(host.i18n.t("Frequency"), frequency), Ui.matchWrap());
        Ui.addSpacer(host, content, 12);
        EditText everyDays = Ui.edit(host, host.i18n.t("Every how many days?"));
        everyDays.setInputType(InputType.TYPE_CLASS_NUMBER);
        View everyDaysCard = Ui.fieldGroup(host, host.i18n.t("Every how many days?"), everyDays);
        everyDaysCard.setVisibility(View.GONE);
        content.addView(everyDaysCard, Ui.matchWrap());
        Ui.addSpacer(host, content, 12);
        Set<String> selectedDays = new HashSet<>();
        View daysCard = host.chipSection(host.i18n.t("Days of the week"), new String[] { "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat" }, selectedDays, AppColors.ACCENT);
        daysCard.setVisibility(View.GONE);
        content.addView(daysCard, Ui.matchWrap());
        Ui.addSpacer(host, content, 12);
        Spinner timesPerDay = host.spinner(new String[] { host.i18n.t("What Time?"), host.i18n.t("Once a day"), host.i18n.t("Twice a day"), host.i18n.t("Three times a day"), host.i18n.t("Multiple times a day") });
        content.addView(host.fieldCard(host.i18n.t("What Time?"), timesPerDay), Ui.matchWrap());
        Ui.addSpacer(host, content, 12);
        LinearLayout doseTimes = Ui.v(host, 0);
        List<Calendar> times = new ArrayList<>();
        times.add(host.defaultDoseTime(0));
        host.rebuildMedicineDoseTimes(doseTimes, times);
        content.addView(doseTimes, Ui.matchWrap());
        Ui.addSpacer(host, content, 8);
        TextView maxMessage = Ui.text(host, "", 13, AppColors.DANGER, android.graphics.Typeface.BOLD);
        maxMessage.setVisibility(View.GONE);
        Button addDose = Ui.secondary(host, "+ " + host.i18n.t("Dose"));
        addDose.setVisibility(View.GONE);
        content.addView(addDose, Ui.matchWrap());
        content.addView(maxMessage, Ui.matchWrap());
        frequency.setOnItemSelectedListener(new AdapterView.OnItemSelectedListener() {

            @Override
            public void onItemSelected(AdapterView<?> parent, View view, int position, long id) {
                String value = String.valueOf(frequency.getSelectedItem());
                everyDaysCard.setVisibility(value.equals(host.i18n.t("Every X days")) ? View.VISIBLE : View.GONE);
                daysCard.setVisibility(value.equals(host.i18n.t("Certain days of the week")) ? View.VISIBLE : View.GONE);
            }

            @Override
            public void onNothingSelected(AdapterView<?> parent) {
            }
        });
        timesPerDay.setOnItemSelectedListener(new AdapterView.OnItemSelectedListener() {

            @Override
            public void onItemSelected(AdapterView<?> parent, View view, int position, long id) {
                int desired = 1;
                boolean multiple = false;
                if (position == 2)
                    desired = 2;
                if (position == 3)
                    desired = 3;
                if (position == 4) {
                    desired = Math.max(times.size(), 3);
                    multiple = true;
                }
                while (times.size() < desired) times.add(host.defaultDoseTime(times.size()));
                while (times.size() > desired && !multiple) times.remove(times.size() - 1);
                addDose.setVisibility(multiple ? View.VISIBLE : View.GONE);
                maxMessage.setVisibility(View.GONE);
                host.rebuildMedicineDoseTimes(doseTimes, times);
            }

            @Override
            public void onNothingSelected(AdapterView<?> parent) {
            }
        });
        addDose.setOnClickListener(v -> {
            if (times.size() >= 10) {
                maxMessage.setText(host.i18n.t("You hit the max."));
                maxMessage.setVisibility(View.VISIBLE);
                return;
            }
            times.add(host.defaultDoseTime(times.size()));
            maxMessage.setVisibility(View.GONE);
            host.rebuildMedicineDoseTimes(doseTimes, times);
        });
        host.showQuickLogForm(host.i18n.t("Add Medicine"), content, () -> {
            JSONArray meds = host.storage.getArray(host.storage.key("health", host.currentUser.id, "androidMedicines"));
            JSONObject med = new JSONObject();
            try {
                med.put("id", "med-" + System.currentTimeMillis());
                med.put("name", name.getText().toString().trim().isEmpty() ? host.i18n.t("Medicine") : name.getText().toString().trim());
                med.put("dose", dose.getText().toString().trim());
                med.put("frequency", String.valueOf(frequency.getSelectedItem()));
                med.put("everyDays", everyDays.getText().toString().trim());
                med.put("days", new JSONArray(selectedDays));
                JSONArray storedTimes = new JSONArray();
                for (Calendar calendar : times) {
                    storedTimes.put(host.formatDisplayTime(calendar));
                }
                med.put("times", storedTimes);
                med.put("time", storedTimes.length() > 0 ? storedTimes.optString(0) : "");
            } catch (JSONException ignored) {
            }
            meds.put(med);
            host.storage.putArray(host.storage.key("health", host.currentUser.id, "androidMedicines"), meds);
            if (afterSave != null)
                afterSave.run();
        });
    }
}
