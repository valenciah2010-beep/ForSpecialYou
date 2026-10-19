package com.forspecialyou.careportal;

import android.app.DatePickerDialog;
import android.app.TimePickerDialog;
import android.graphics.Color;
import android.view.Gravity;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.EditText;
import android.widget.LinearLayout;
import android.widget.TextView;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.Date;
import java.util.List;

final class SleepForms {

    private final MainActivity host;

    SleepForms(MainActivity host) {
        this.host = host;
    }

    void showSleepLogDialog(String title) {
        LinearLayout content = Ui.v(host, 0);
        content.setPadding(Ui.dp(host, 12), 0, Ui.dp(host, 12), 0);
        Calendar date = Calendar.getInstance();
        Calendar fellAsleep = Calendar.getInstance();
        fellAsleep.add(Calendar.HOUR_OF_DAY, -9);
        Calendar wokeUp = Calendar.getInstance();
        final String[] quality = { "Normal" };
        final int[] wakeups = { 0 };
        content.addView(host.sleepTimeCard(date, fellAsleep, wokeUp), Ui.matchWrap());
        Ui.addSpacer(host, content, 12);
        content.addView(host.sleepQualityCard(quality), Ui.matchWrap());
        Ui.addSpacer(host, content, 12);
        content.addView(host.wakeCounterCard(wakeups), Ui.matchWrap());
        Ui.addSpacer(host, content, 12);
        EditText notes = Ui.multi(host, host.i18n.t("Nap, bedtime routine, night waking, comfort item, etc."));
        content.addView(Ui.fieldGroup(host, host.i18n.t("Notes"), notes), Ui.matchWrap());
        Ui.dialog(host, "🌙 " + host.i18n.t(title), content, host.i18n.t("Save"), () -> {
            int minutes = host.minutesBetween(fellAsleep, wokeUp);
            String value = host.formatSleepDuration(minutes) + " · " + host.i18n.t(quality[0]) + " · " + wakeups[0] + " " + host.i18n.t("wake-ups");
            host.addHealthEntry("sleep", title, "snapshot", value, notes.getText().toString().trim(), wokeUp);
            host.render();
        });
    }

    LinearLayout sleepTimeCard(Calendar date, Calendar fellAsleep, Calendar wokeUp) {
        LinearLayout panel = Ui.panel(host);
        panel.setPadding(Ui.dp(host, 18), Ui.dp(host, 18), Ui.dp(host, 18), Ui.dp(host, 18));
        panel.setBackground(Ui.stroke(AppColors.PANEL, Ui.withAlpha(AppColors.BORDER, 90), Ui.dp(host, 22)));
        panel.addView(Ui.text(host, "🌙 " + host.i18n.t("Sleep Times"), 18, AppColors.TEXT, android.graphics.Typeface.BOLD), Ui.matchWrap());
        Ui.addSpacer(host, panel, 16);
        Button dateButton = host.sleepDateButton(date, fellAsleep, wokeUp);
        Button sleepButton = host.sleepTimeButton(fellAsleep);
        Button wakeButton = host.sleepTimeButton(wokeUp);
        panel.addView(host.sleepTimeRow(host.i18n.t("Date"), dateButton), Ui.matchWrap());
        Ui.addSpacer(host, panel, 12);
        panel.addView(host.sleepTimeRow(host.i18n.t("Fell asleep at"), sleepButton), Ui.matchWrap());
        Ui.addSpacer(host, panel, 12);
        panel.addView(host.sleepTimeRow(host.i18n.t("Woke up at"), wakeButton), Ui.matchWrap());
        return panel;
    }

    LinearLayout sleepTimeRow(String label, Button button) {
        LinearLayout row = Ui.h(host, 0);
        row.setGravity(Gravity.CENTER_VERTICAL);
        row.addView(Ui.text(host, label, 15, AppColors.TEXT, android.graphics.Typeface.BOLD), new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1));
        row.addView(button, Ui.fixed(host, 132, 58));
        return row;
    }

    Button sleepDateButton(Calendar date, Calendar... linked) {
        Button button = host.sleepPickerButton(host.formatDisplayDate(date));
        button.setOnClickListener(v -> new DatePickerDialog(host, (view, year, month, day) -> {
            date.set(Calendar.YEAR, year);
            date.set(Calendar.MONTH, month);
            date.set(Calendar.DAY_OF_MONTH, day);
            for (Calendar calendar : linked) {
                calendar.set(Calendar.YEAR, year);
                calendar.set(Calendar.MONTH, month);
                calendar.set(Calendar.DAY_OF_MONTH, day);
            }
            button.setText(host.formatDisplayDate(date));
        }, date.get(Calendar.YEAR), date.get(Calendar.MONTH), date.get(Calendar.DAY_OF_MONTH)).show());
        return button;
    }

    Button sleepTimeButton(Calendar calendar) {
        Button button = host.sleepPickerButton(host.formatDisplayTime(calendar));
        button.setOnClickListener(v -> new TimePickerDialog(host, (view, hourOfDay, minute) -> {
            calendar.set(Calendar.HOUR_OF_DAY, hourOfDay);
            calendar.set(Calendar.MINUTE, minute);
            button.setText(host.formatDisplayTime(calendar));
        }, calendar.get(Calendar.HOUR_OF_DAY), calendar.get(Calendar.MINUTE), false).show());
        return button;
    }

    Button sleepPickerButton(String text) {
        Button button = Ui.secondary(host, text);
        button.setTextSize(17);
        button.setTextColor(AppColors.ACCENT);
        button.setTypeface(android.graphics.Typeface.DEFAULT, android.graphics.Typeface.BOLD);
        button.setPadding(Ui.dp(host, 8), 0, Ui.dp(host, 8), 0);
        button.setMinHeight(Ui.dp(host, 58));
        button.setBackground(Ui.stroke(Color.rgb(226, 237, 233), Ui.withAlpha(AppColors.ACCENT, 70), Ui.dp(host, 16)));
        return button;
    }

    LinearLayout sleepQualityCard(String[] selectedQuality) {
        LinearLayout panel = Ui.panel(host);
        panel.setPadding(Ui.dp(host, 18), Ui.dp(host, 18), Ui.dp(host, 18), Ui.dp(host, 18));
        panel.setBackground(Ui.stroke(AppColors.PANEL, Ui.withAlpha(AppColors.BORDER, 90), Ui.dp(host, 22)));
        panel.addView(Ui.text(host, host.i18n.t("Rest Quality"), 20, AppColors.TEXT, android.graphics.Typeface.BOLD), Ui.matchWrap());
        Ui.addSpacer(host, panel, 14);
        LinearLayout row = Ui.h(host, 0);
        row.setGravity(Gravity.CENTER);
        String[][] options = { { "😣", "Restless" }, { "😴", "Normal" }, { "🌙", "Deep" } };
        List<LinearLayout> cards = new ArrayList<>();
        for (String[] option : options) {
            LinearLayout card = host.sleepQualityOption(option[0], option[1], option[1].equals(selectedQuality[0]));
            cards.add(card);
            card.setOnClickListener(v -> {
                selectedQuality[0] = option[1];
                for (int index = 0; index < cards.size(); index++) {
                    host.styleSleepQualityOption(cards.get(index), options[index][1].equals(selectedQuality[0]));
                }
            });
            LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(0, Ui.dp(host, 92), 1);
            params.leftMargin = Ui.dp(host, 5);
            params.rightMargin = Ui.dp(host, 5);
            row.addView(card, params);
        }
        panel.addView(row, Ui.matchWrap());
        return panel;
    }

    LinearLayout sleepQualityOption(String icon, String label, boolean selected) {
        LinearLayout card = Ui.v(host, 0);
        card.setGravity(Gravity.CENTER);
        card.setPadding(Ui.dp(host, 8), Ui.dp(host, 10), Ui.dp(host, 8), Ui.dp(host, 10));
        TextView iconView = Ui.text(host, icon, 26, AppColors.TEXT, android.graphics.Typeface.BOLD);
        iconView.setGravity(Gravity.CENTER);
        card.addView(iconView, Ui.matchWrap());
        TextView labelView = Ui.text(host, host.i18n.t(label), 15, AppColors.TEXT, android.graphics.Typeface.BOLD);
        labelView.setGravity(Gravity.CENTER);
        card.addView(labelView, Ui.matchWrap());
        host.styleSleepQualityOption(card, selected);
        return card;
    }

    void styleSleepQualityOption(LinearLayout card, boolean selected) {
        int fill = selected ? Color.rgb(222, 240, 252) : AppColors.FIELD;
        int border = selected ? Color.rgb(82, 169, 225) : Color.TRANSPARENT;
        card.setBackground(Ui.stroke(fill, border, Ui.dp(host, 16)));
    }

    LinearLayout wakeCounterCard(int[] wakeups) {
        LinearLayout panel = Ui.panel(host);
        panel.setPadding(Ui.dp(host, 18), Ui.dp(host, 18), Ui.dp(host, 18), Ui.dp(host, 18));
        panel.setBackground(Ui.stroke(AppColors.PANEL, Ui.withAlpha(AppColors.BORDER, 90), Ui.dp(host, 22)));
        panel.addView(Ui.text(host, host.i18n.t("Waking Counter"), 20, AppColors.TEXT, android.graphics.Typeface.BOLD), Ui.matchWrap());
        Ui.addSpacer(host, panel, 16);
        LinearLayout row = Ui.h(host, 0);
        row.setGravity(Gravity.CENTER_VERTICAL);
        TextView minus = host.sleepCounterButton("-", Color.rgb(221, 235, 247), Color.rgb(82, 169, 225));
        TextView count = Ui.text(host, String.valueOf(wakeups[0]), 28, AppColors.TEXT, android.graphics.Typeface.BOLD);
        count.setGravity(Gravity.CENTER);
        TextView plus = host.sleepCounterButton("+", Color.rgb(82, 169, 225), AppColors.PANEL);
        TextView suffix = Ui.text(host, host.i18n.t("wake-ups"), 17, AppColors.MUTED, android.graphics.Typeface.BOLD);
        suffix.setGravity(Gravity.CENTER_VERTICAL);
        minus.setOnClickListener(v -> {
            wakeups[0] = Math.max(0, wakeups[0] - 1);
            count.setText(String.valueOf(wakeups[0]));
        });
        plus.setOnClickListener(v -> {
            wakeups[0] += 1;
            count.setText(String.valueOf(wakeups[0]));
        });
        row.addView(minus, Ui.fixed(host, 72, 72));
        Ui.addSpacerHorizontal(host, row, 24);
        row.addView(count, Ui.fixed(host, 54, 72));
        Ui.addSpacerHorizontal(host, row, 24);
        row.addView(plus, Ui.fixed(host, 72, 72));
        Ui.addSpacerHorizontal(host, row, 18);
        row.addView(suffix, new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1));
        panel.addView(row, Ui.matchWrap());
        return panel;
    }

    TextView sleepCounterButton(String text, int fill, int textColor) {
        TextView button = Ui.text(host, text, 28, textColor, android.graphics.Typeface.BOLD);
        button.setGravity(Gravity.CENTER);
        button.setBackground(Ui.round(fill, Ui.dp(host, 36)));
        return button;
    }

    LinearLayout timestampCard(Calendar timestamp) {
        LinearLayout panel = Ui.panel(host);
        panel.setPadding(Ui.dp(host, 14), Ui.dp(host, 14), Ui.dp(host, 14), Ui.dp(host, 14));
        panel.setBackground(Ui.stroke(AppColors.PANEL, Ui.withAlpha(AppColors.BORDER, 150), Ui.dp(host, 20)));
        LinearLayout row = Ui.h(host, 0);
        row.setGravity(Gravity.CENTER_VERTICAL);
        TextView icon = Ui.text(host, "🗓", 18, AppColors.ACCENT, android.graphics.Typeface.BOLD);
        icon.setGravity(Gravity.CENTER);
        icon.setBackground(Ui.round(Ui.withAlpha(AppColors.ACCENT, 24), Ui.dp(host, 17)));
        row.addView(icon, Ui.fixed(host, 34, 34));
        Ui.addSpacerHorizontal(host, row, 8);
        TextView label = Ui.text(host, host.i18n.t("Timestamp"), 15, AppColors.TEXT, android.graphics.Typeface.BOLD);
        row.addView(label, new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1));
        Ui.addSpacerHorizontal(host, row, 8);
        Button date = host.dateButton(timestamp);
        Button time = host.timeButton(timestamp);
        host.styleTimestampButton(date);
        host.styleTimestampButton(time);
        row.addView(date, Ui.fixed(host, 128, 42));
        Ui.addSpacerHorizontal(host, row, 8);
        row.addView(time, Ui.fixed(host, 92, 42));
        panel.addView(row, Ui.matchWrap());
        return panel;
    }

    void styleTimestampButton(Button button) {
        button.setTextSize(15);
        button.setTextColor(AppColors.ACCENT);
        button.setMinWidth(0);
        button.setMinHeight(Ui.dp(host, 42));
        button.setPadding(Ui.dp(host, 8), 0, Ui.dp(host, 8), 0);
        button.setBackground(Ui.round(Color.rgb(238, 239, 238), Ui.dp(host, 18)));
    }

    LinearLayout dateOnlyRow(String label, Calendar date, Calendar... linked) {
        LinearLayout row = Ui.h(host, 0);
        row.addView(Ui.text(host, label, 14, AppColors.TEXT, android.graphics.Typeface.BOLD), new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1));
        Button button = Ui.secondary(host, host.formatDisplayDate(date));
        button.setOnClickListener(v -> new DatePickerDialog(host, (view, year, month, day) -> {
            date.set(Calendar.YEAR, year);
            date.set(Calendar.MONTH, month);
            date.set(Calendar.DAY_OF_MONTH, day);
            for (Calendar calendar : linked) {
                calendar.set(Calendar.YEAR, year);
                calendar.set(Calendar.MONTH, month);
                calendar.set(Calendar.DAY_OF_MONTH, day);
            }
            button.setText(host.formatDisplayDate(date));
        }, date.get(Calendar.YEAR), date.get(Calendar.MONTH), date.get(Calendar.DAY_OF_MONTH)).show());
        row.addView(button, Ui.wrapWrap());
        return row;
    }

    LinearLayout timeOnlyRow(String label, Calendar calendar) {
        LinearLayout row = Ui.h(host, 0);
        row.addView(Ui.text(host, label, 14, AppColors.TEXT, android.graphics.Typeface.BOLD), new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1));
        row.addView(host.timeButton(calendar), Ui.wrapWrap());
        return row;
    }

    Button dateButton(Calendar calendar) {
        Button button = Ui.secondary(host, host.formatDisplayDate(calendar));
        button.setOnClickListener(v -> new DatePickerDialog(host, (view, year, month, day) -> {
            calendar.set(Calendar.YEAR, year);
            calendar.set(Calendar.MONTH, month);
            calendar.set(Calendar.DAY_OF_MONTH, day);
            button.setText(host.formatDisplayDate(calendar));
        }, calendar.get(Calendar.YEAR), calendar.get(Calendar.MONTH), calendar.get(Calendar.DAY_OF_MONTH)).show());
        return button;
    }

    Button timeButton(Calendar calendar) {
        Button button = Ui.secondary(host, host.formatDisplayTime(calendar));
        button.setOnClickListener(v -> new TimePickerDialog(host, (view, hourOfDay, minute) -> {
            calendar.set(Calendar.HOUR_OF_DAY, hourOfDay);
            calendar.set(Calendar.MINUTE, minute);
            button.setText(host.formatDisplayTime(calendar));
        }, calendar.get(Calendar.HOUR_OF_DAY), calendar.get(Calendar.MINUTE), false).show());
        return button;
    }
}
