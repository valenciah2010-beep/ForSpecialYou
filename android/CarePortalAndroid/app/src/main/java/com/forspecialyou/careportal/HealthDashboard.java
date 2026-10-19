package com.forspecialyou.careportal;

import android.graphics.Color;
import android.graphics.drawable.Drawable;
import android.os.Handler;
import android.os.Looper;
import android.view.Gravity;
import android.view.MotionEvent;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.GridLayout;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;
import org.json.JSONArray;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Locale;
import java.util.Set;

final class HealthDashboard {

    private final MainActivity host;

    HealthDashboard(MainActivity host) {
        this.host = host;
    }

    View healthView() {
        LinearLayout screen = Ui.screen(host);
        LinearLayout header = Ui.h(host, 0);
        header.setPadding(Ui.dp(host, 14), Ui.dp(host, 12), Ui.dp(host, 14), Ui.dp(host, 12));
        header.setBackground(Ui.round(Color.rgb(209, 244, 241), Ui.dp(host, 18)));
        View avatar = host.childAvatarView(52);
        avatar.setOnClickListener(v -> {
            host.selectedTab = 4;
            host.render();
        });
        header.addView(avatar, Ui.fixed(host, 52, 52));
        LinearLayout childTexts = Ui.v(host, 0);
        childTexts.addView(Ui.text(host, String.format(Locale.US, host.i18n.t("%s's Day"), host.childName()), 21, AppColors.TEXT, android.graphics.Typeface.BOLD), Ui.matchWrap());
        childTexts.addView(Ui.text(host, String.format(Locale.US, host.i18n.t("Monitored by %s"), host.currentUser.nickname), 14, AppColors.MUTED, android.graphics.Typeface.BOLD), Ui.matchWrap());
        LinearLayout.LayoutParams childParams = new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1);
        childParams.leftMargin = Ui.dp(host, 12);
        header.addView(childTexts, childParams);
        TextView bell = Ui.text(host, "🔔", 26, AppColors.TEXT, android.graphics.Typeface.BOLD);
        bell.setGravity(Gravity.CENTER);
        bell.setOnClickListener(v -> host.showNotificationsToday());
        header.addView(bell, Ui.fixed(host, 42, 42));
        screen.addView(header, Ui.matchWrap());
        Ui.addSpacer(host, screen, 16);
        LinearLayout quickHeader = Ui.h(host, 0);
        quickHeader.addView(Ui.sectionTitle(host, host.i18n.t("Quick-log buttons")), Ui.wrapWrap());
        Ui.addSpacerHorizontal(host, quickHeader, 8);
        LinearLayout quickHistory = host.roundHistoryButton();
        quickHistory.setOnClickListener(v -> host.showHealthHistory("quickLog"));
        quickHeader.addView(quickHistory, Ui.wrapWrap());
        quickHeader.addView(new View(host), new LinearLayout.LayoutParams(0, 1, 1));
        TextView choose = host.iconCircle("≛", AppColors.ACCENT, Color.WHITE, 54);
        choose.setOnClickListener(v -> host.showQuickLogPicker());
        quickHeader.addView(choose, Ui.fixed(host, 54, 54));
        screen.addView(quickHeader, Ui.matchWrap());
        Ui.addSpacer(host, screen, 14);
        String selected = host.storage.getString(host.storage.key("health", host.currentUser.id, "quickLogSelection"), "");
        if (selected.isEmpty()) {
            LinearLayout empty = Ui.h(host, 0);
            empty.setGravity(Gravity.CENTER);
            empty.setPadding(Ui.dp(host, 14), Ui.dp(host, 12), Ui.dp(host, 14), Ui.dp(host, 12));
            empty.setBackground(Ui.round(Ui.withAlpha(AppColors.ACCENT, 24), Ui.dp(host, 12)));
            TextView emptyIcon = Ui.text(host, "☷", 18, AppColors.ACCENT, android.graphics.Typeface.BOLD);
            empty.addView(emptyIcon, Ui.wrapWrap());
            TextView emptyText = Ui.text(host, "  " + host.i18n.t("Choose quick-log buttons"), 16, AppColors.ACCENT, android.graphics.Typeface.BOLD);
            empty.addView(emptyText, Ui.wrapWrap());
            empty.setOnClickListener(v -> host.showQuickLogPicker());
            screen.addView(empty, Ui.matchWrap());
        } else {
            GridLayout grid = Ui.grid(host, 3);
            for (String[] option : host.orderedQuickLogs(selected)) {
                View chip = host.quickLogCard(option[0], option[1]);
                chip.setOnClickListener(v -> host.showHealthLogDialog(option[0], option[1], "quickLog"));
                host.enableQuickLogDrag(chip, option[0]);
                Ui.addGridChildFixedHeight(host, grid, chip, 116);
            }
            screen.addView(grid, Ui.matchWrap());
        }
        Ui.addSpacer(host, screen, 26);
        LinearLayout snapshotHeader = Ui.h(host, 0);
        snapshotHeader.addView(Ui.sectionTitle(host, host.i18n.t("Daily Snapshot")), Ui.wrapWrap());
        Ui.addSpacerHorizontal(host, snapshotHeader, 8);
        LinearLayout snapshotHistory = host.roundHistoryButton();
        snapshotHistory.setOnClickListener(v -> host.showHealthHistory("snapshot"));
        snapshotHeader.addView(snapshotHistory, Ui.wrapWrap());
        screen.addView(snapshotHeader, Ui.matchWrap());
        Ui.addSpacer(host, screen, 14);
        GridLayout snapshotGrid = Ui.grid(host, 2);
        for (String[] option : host.SNAPSHOTS) {
            if ("height".equals(option[0]) || "weight".equals(option[0])) {
                continue;
            }
            View button = host.snapshotCard(option[0], option[1], false);
            button.setOnClickListener(v -> host.showHealthLogDialog(option[0], option[1], "snapshot"));
            Ui.addGridChild(host, snapshotGrid, button, 2);
        }
        screen.addView(snapshotGrid, Ui.matchWrap());
        Ui.addSpacer(host, screen, 8);
        LinearLayout measurements = Ui.h(host, 0);
        for (String[] option : host.SNAPSHOTS) {
            if (!"height".equals(option[0]) && !"weight".equals(option[0])) {
                continue;
            }
            View button = host.snapshotCard(option[0], option[1], true);
            button.setOnClickListener(v -> host.showHealthLogDialog(option[0], option[1], "snapshot"));
            LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1);
            params.setMargins(Ui.dp(host, 5), Ui.dp(host, 4), Ui.dp(host, 5), Ui.dp(host, 4));
            measurements.addView(button, params);
        }
        screen.addView(measurements, Ui.matchWrap());
        Ui.addSpacer(host, screen, 16);
        LinearLayout insights = Ui.panel(host);
        insights.addView(Ui.sectionTitle(host, host.i18n.t("Insights & Alerts")), Ui.matchWrap());
        Ui.addSpacer(host, insights, 8);
        JSONArray logs = host.storage.getArray(host.storage.key("health", host.currentUser.id, "logData"));
        if (logs.length() == 0) {
            insights.addView(Ui.muted(host, host.i18n.t("No records yet.")), Ui.matchWrap());
        } else {
            insights.addView(Ui.muted(host, logs.length() + " local health records saved."), Ui.matchWrap());
            Button refresh = Ui.secondary(host, host.i18n.t("Refresh insights"));
            refresh.setOnClickListener(v -> host.loadHealthInsights());
            insights.addView(refresh, Ui.matchWrap());
        }
        screen.addView(insights, Ui.matchWrap());
        return Ui.scroll(host, screen);
    }

    View quickLogCard(String id, String title) {
        int color = host.quickLogColor(id);
        LinearLayout card = Ui.v(host, 0);
        card.setGravity(Gravity.CENTER);
        card.setPadding(Ui.dp(host, 8), Ui.dp(host, 14), Ui.dp(host, 8), Ui.dp(host, 14));
        card.setMinimumHeight(Ui.dp(host, 116));
        card.setClickable(true);
        card.setFocusable(true);
        card.setBackground(Ui.stroke(Ui.withAlpha(color, 224), Ui.withAlpha(color, 255), Ui.dp(host, 12)));
        ImageView icon = host.quickLogIconView(id);
        card.addView(icon, Ui.fixed(host, 52, 48));
        Ui.addSpacer(host, card, 10);
        TextView label = Ui.text(host, host.i18n.t(title), 13, AppColors.TEXT, android.graphics.Typeface.BOLD);
        label.setGravity(Gravity.CENTER);
        label.setSingleLine(true);
        card.addView(label, Ui.matchWrap());
        return card;
    }

    void enableQuickLogDrag(View card, String id) {
        card.setTag(id);
        Handler dragHandler = new Handler(Looper.getMainLooper());
        final boolean[] dragging = { false };
        final boolean[] waitingForLongPress = { false };
        final float[] startRawX = { 0f };
        final float[] startRawY = { 0f };
        Runnable startDrag = () -> {
            waitingForLongPress[0] = false;
            dragging[0] = true;
            card.setPressed(false);
            card.setAlpha(0.76f);
            card.setScaleX(0.96f);
            card.setScaleY(0.96f);
            card.bringToFront();
            host.disallowParentIntercept(card, true);
        };
        card.setOnTouchListener((v, event) -> {
            switch(event.getActionMasked()) {
                case MotionEvent.ACTION_DOWN:
                    startRawX[0] = event.getRawX();
                    startRawY[0] = event.getRawY();
                    waitingForLongPress[0] = true;
                    dragging[0] = false;
                    dragHandler.postDelayed(startDrag, 260);
                    return false;
                case MotionEvent.ACTION_MOVE:
                    float dx = event.getRawX() - startRawX[0];
                    float dy = event.getRawY() - startRawY[0];
                    if (waitingForLongPress[0] && Math.hypot(dx, dy) > Ui.dp(host, 8)) {
                        waitingForLongPress[0] = false;
                        dragHandler.removeCallbacks(startDrag);
                    }
                    if (!dragging[0]) {
                        return false;
                    }
                    v.setTranslationX(dx);
                    v.setTranslationY(dy);
                    host.disallowParentIntercept(v, true);
                    return true;
                case MotionEvent.ACTION_UP:
                case MotionEvent.ACTION_CANCEL:
                    dragHandler.removeCallbacks(startDrag);
                    boolean didDrag = dragging[0];
                    waitingForLongPress[0] = false;
                    dragging[0] = false;
                    String targetId = didDrag ? host.quickLogTargetAt(host.getWindow().getDecorView(), event.getRawX(), event.getRawY(), id) : null;
                    v.setAlpha(1f);
                    v.setScaleX(1f);
                    v.setScaleY(1f);
                    v.setTranslationX(0f);
                    v.setTranslationY(0f);
                    host.disallowParentIntercept(v, false);
                    if (didDrag && targetId != null) {
                        host.moveQuickLogButton(id, targetId);
                    }
                    return didDrag;
                default:
                    return false;
            }
        });
    }

    void disallowParentIntercept(View view, boolean disallow) {
        android.view.ViewParent parent = view.getParent();
        while (parent != null) {
            parent.requestDisallowInterceptTouchEvent(disallow);
            parent = parent.getParent();
        }
    }

    String quickLogTargetAt(View view, float rawX, float rawY, String draggedId) {
        if (view == null || view.getVisibility() != View.VISIBLE) {
            return null;
        }
        if (view instanceof ViewGroup) {
            ViewGroup group = (ViewGroup) view;
            for (int i = group.getChildCount() - 1; i >= 0; i--) {
                String childTarget = host.quickLogTargetAt(group.getChildAt(i), rawX, rawY, draggedId);
                if (childTarget != null) {
                    return childTarget;
                }
            }
        }
        Object tag = view.getTag();
        if (!(tag instanceof String)) {
            return null;
        }
        String targetId = (String) tag;
        if (targetId.equals(draggedId) || host.quickLogOption(targetId) == null) {
            return null;
        }
        int[] location = new int[2];
        view.getLocationOnScreen(location);
        return rawX >= location[0] && rawX <= location[0] + view.getWidth() && rawY >= location[1] && rawY <= location[1] + view.getHeight() ? targetId : null;
    }

    void moveQuickLogButton(String draggedId, String targetId) {
        if (draggedId.equals(targetId))
            return;
        String key = host.storage.key("health", host.currentUser.id, "quickLogSelection");
        List<String> ids = host.orderedQuickLogIds(host.storage.getString(key, ""));
        int from = ids.indexOf(draggedId);
        int to = ids.indexOf(targetId);
        if (from < 0 || to < 0)
            return;
        ids.remove(from);
        if (from < to)
            to--;
        ids.add(to, draggedId);
        host.storage.putString(key, host.joinIds(ids));
        host.render();
    }

    List<String[]> orderedQuickLogs(String raw) {
        List<String[]> ordered = new ArrayList<>();
        for (String id : host.orderedQuickLogIds(raw)) {
            String[] option = host.quickLogOption(id);
            if (option != null)
                ordered.add(option);
        }
        return ordered;
    }

    List<String> orderedQuickLogIds(String raw) {
        List<String> ids = new ArrayList<>();
        Set<String> seen = new HashSet<>();
        if (raw != null && !raw.trim().isEmpty()) {
            for (String part : raw.split(",")) {
                String id = part.trim();
                if (!id.isEmpty() && host.quickLogOption(id) != null && !seen.contains(id)) {
                    ids.add(id);
                    seen.add(id);
                }
            }
        }
        return ids;
    }

    String[] quickLogOption(String id) {
        for (String[] option : host.QUICK_LOGS) {
            if (option[0].equals(id))
                return option;
        }
        return null;
    }

    String joinIds(List<String> ids) {
        StringBuilder builder = new StringBuilder();
        for (String id : ids) {
            if (builder.length() > 0)
                builder.append(",");
            builder.append(id);
        }
        return builder.toString();
    }

    ImageView quickLogIconView(String id) {
        ImageView icon = new ImageView(host);
        icon.setImageResource(host.quickLogIconRes(id));
        icon.setColorFilter(AppColors.TEXT);
        icon.setScaleType(ImageView.ScaleType.FIT_CENTER);
        icon.setAdjustViewBounds(false);
        icon.setPadding(Ui.dp(host, 5), Ui.dp(host, 4), Ui.dp(host, 5), Ui.dp(host, 4));
        return icon;
    }

    ImageView symbolIcon(int resId, int tintColor, int backgroundColor, int sizeDp, int paddingDp) {
        ImageView icon = new ImageView(host);
        icon.setImageResource(resId);
        icon.setColorFilter(tintColor);
        icon.setScaleType(ImageView.ScaleType.FIT_CENTER);
        icon.setAdjustViewBounds(false);
        if (backgroundColor != Color.TRANSPARENT) {
            icon.setBackground(Ui.round(backgroundColor, Ui.dp(host, sizeDp / 2)));
        }
        icon.setPadding(Ui.dp(host, paddingDp), Ui.dp(host, paddingDp), Ui.dp(host, paddingDp), Ui.dp(host, paddingDp));
        return icon;
    }

    void setButtonSymbol(Button button, int resId, int tintColor, int sizeDp) {
        Drawable icon = host.getDrawable(resId);
        if (icon == null) {
            return;
        }
        icon = icon.mutate();
        icon.setTint(tintColor);
        int size = Ui.dp(host, sizeDp);
        icon.setBounds(0, 0, size, size);
        button.setCompoundDrawables(icon, null, null, null);
        button.setCompoundDrawablePadding(Ui.dp(host, 8));
        button.setGravity(Gravity.CENTER);
    }

    void setTextSymbol(TextView view, int resId, int tintColor, int sizeDp) {
        Drawable icon = host.getDrawable(resId);
        if (icon == null) {
            return;
        }
        icon = icon.mutate();
        icon.setTint(tintColor);
        int size = Ui.dp(host, sizeDp);
        icon.setBounds(0, 0, size, size);
        view.setCompoundDrawables(icon, null, null, null);
        view.setCompoundDrawablePadding(Ui.dp(host, 7));
    }

    int quickLogIconRes(String id) {
        switch(id) {
            case "seizure":
                return R.drawable.ios_qlog_timer;
            case "meltdown":
                return R.drawable.ios_qlog_warning_triangle;
            case "stimming":
                return R.drawable.ios_qlog_waveform;
            case "accident":
                return R.drawable.ios_qlog_drop_triangle;
            case "deescalation":
                return R.drawable.ios_qlog_hand;
            case "allergy":
                return R.drawable.ios_qlog_allergens;
            case "pain":
                return R.drawable.ios_qlog_cross_case;
            case "skin":
                return R.drawable.ios_qlog_bandage;
            case "medsFood":
                return R.drawable.ios_qlog_pills;
            case "cyclicVomiting":
                return R.drawable.ios_qlog_cycle;
            case "discomfort":
                return R.drawable.ios_qlog_thermometer;
            default:
                return R.drawable.ios_qlog_warning_triangle;
        }
    }

    View snapshotCard(String id, String title, boolean compact) {
        int color = host.snapshotColor(id);
        LinearLayout card = compact ? Ui.h(host, 0) : Ui.v(host, 0);
        card.setGravity(Gravity.CENTER);
        card.setPadding(Ui.dp(host, compact ? 14 : 10), compact ? Ui.dp(host, 12) : Ui.dp(host, 18), Ui.dp(host, compact ? 14 : 10), compact ? Ui.dp(host, 12) : Ui.dp(host, 18));
        card.setMinimumHeight(Ui.dp(host, compact ? 78 : 138));
        card.setClickable(true);
        card.setFocusable(true);
        card.setBackground(Ui.stroke(compact ? AppColors.PANEL : Ui.withAlpha(color, 42), Ui.withAlpha(color, compact ? 60 : 100), Ui.dp(host, compact ? 16 : 12)));
        ImageView icon = host.snapshotIconView(id, color, compact);
        if (compact) {
            card.addView(icon, Ui.fixed(host, 48, 48));
            Ui.addSpacerHorizontal(host, card, 12);
            TextView label = Ui.text(host, host.i18n.t(host.snapshotTitle(id, title)), 18, AppColors.TEXT, android.graphics.Typeface.BOLD);
            card.addView(label, new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1));
        } else {
            card.addView(icon, Ui.fixed(host, 62, 62));
            Ui.addSpacer(host, card, 10);
            TextView label = Ui.text(host, host.i18n.t(host.snapshotTitle(id, title)), 20, AppColors.TEXT, android.graphics.Typeface.BOLD);
            label.setGravity(Gravity.CENTER);
            label.setMaxLines(2);
            card.addView(label, Ui.matchWrap());
        }
        return card;
    }

    ImageView snapshotIconView(String id, int color, boolean compact) {
        int fill = compact ? Ui.withAlpha(color, 28) : Color.TRANSPARENT;
        return host.symbolIcon(host.snapshotIconRes(id), color, fill, compact ? 48 : 62, compact ? 12 : 6);
    }

    int snapshotIconRes(String id) {
        switch(id) {
            case "sleep":
                return R.drawable.ios_snapshot_moon_zzz;
            case "digestion":
                return R.drawable.ios_snapshot_digestion;
            case "nutrition":
                return R.drawable.ios_icon_checkmark_circle;
            case "mood":
                return R.drawable.ios_snapshot_face_smiling;
            case "height":
                return R.drawable.ios_snapshot_ruler;
            case "weight":
                return R.drawable.ios_snapshot_scalemass;
            default:
                return R.drawable.ios_icon_checkmark_circle;
        }
    }

    String quickLogIcon(String id) {
        switch(id) {
            case "seizure":
                return "⏱︎";
            case "meltdown":
                return "⚠︎";
            case "stimming":
                return "∿";
            case "accident":
                return "◭";
            case "deescalation":
                return "✋︎";
            case "allergy":
                return "✤";
            case "pain":
                return "✚";
            case "skin":
                return "▱";
            case "medsFood":
                return "◖◗";
            case "mood":
                return "🙂";
            case "discomfort":
                return "♨︎";
            case "cyclicVomiting":
                return "↻";
            default:
                return "＋";
        }
    }

    int quickLogColor(String id) {
        switch(id) {
            case "seizure":
                return Color.rgb(242, 103, 102);
            case "meltdown":
                return Color.rgb(248, 195, 74);
            case "stimming":
                return Color.rgb(134, 181, 238);
            case "accident":
                return Color.rgb(184, 161, 226);
            case "deescalation":
                return Color.rgb(130, 206, 164);
            case "allergy":
                return Color.rgb(245, 148, 110);
            case "pain":
                return Color.rgb(232, 126, 145);
            case "skin":
                return Color.rgb(241, 194, 120);
            case "medsFood":
                return Color.rgb(116, 199, 151);
            case "mood":
                return Color.rgb(248, 224, 118);
            case "discomfort":
                return Color.rgb(224, 184, 115);
            case "cyclicVomiting":
                return Color.rgb(102, 199, 196);
            default:
                return AppColors.ACCENT;
        }
    }

    String snapshotIcon(String id) {
        switch(id) {
            case "sleep":
                return "🌙ᶻᶻ";
            case "digestion":
                return "🛌";
            case "nutrition":
                return "✓";
            case "mood":
                return "☺";
            case "height":
                return "📏";
            case "weight":
                return "⚖";
            default:
                return "•";
        }
    }

    int snapshotColor(String id) {
        switch(id) {
            case "sleep":
                return Color.rgb(83, 172, 225);
            case "digestion":
                return Color.rgb(105, 199, 142);
            case "nutrition":
                return Color.rgb(93, 196, 151);
            case "mood":
                return Color.rgb(247, 205, 83);
            case "height":
                return Color.rgb(87, 170, 214);
            case "weight":
                return Color.rgb(110, 190, 134);
            default:
                return AppColors.ACCENT;
        }
    }

    String snapshotTitle(String id, String fallback) {
        switch(id) {
            case "sleep":
                return "Sleep";
            case "digestion":
                return "Bowel Movement";
            default:
                return fallback;
        }
    }
}
