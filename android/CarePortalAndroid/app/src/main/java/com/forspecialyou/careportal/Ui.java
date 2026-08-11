package com.forspecialyou.careportal;

import android.app.Dialog;
import android.content.Context;
import android.graphics.Color;
import android.graphics.Typeface;
import android.graphics.drawable.ColorDrawable;
import android.graphics.drawable.GradientDrawable;
import android.text.InputType;
import android.view.Gravity;
import android.view.MotionEvent;
import android.view.View;
import android.view.ViewGroup;
import android.view.Window;
import android.view.WindowManager;
import android.widget.Button;
import android.widget.CheckBox;
import android.widget.EditText;
import android.widget.FrameLayout;
import android.widget.GridLayout;
import android.widget.ImageButton;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;

final class Ui {
    private Ui() {
    }

    static int dp(Context context, int value) {
        return Math.round(value * context.getResources().getDisplayMetrics().density);
    }

    static TextView text(Context context, String text, int sp, int color, int style) {
        TextView view = new TextView(context);
        view.setText(text);
        view.setTextSize(sp);
        view.setTextColor(color);
        view.setTypeface(Typeface.DEFAULT, style);
        view.setIncludeFontPadding(true);
        return view;
    }

    static TextView title(Context context, String text) {
        return text(context, text, 30, AppColors.TEXT, Typeface.BOLD);
    }

    static TextView sectionTitle(Context context, String text) {
        return text(context, text, 20, AppColors.TEXT, Typeface.BOLD);
    }

    static TextView muted(Context context, String text) {
        TextView view = text(context, text, 14, AppColors.MUTED, Typeface.NORMAL);
        view.setLineSpacing(dp(context, 2), 1.0f);
        return view;
    }

    static LinearLayout v(Context context, int spacingDp) {
        LinearLayout layout = new LinearLayout(context);
        layout.setOrientation(LinearLayout.VERTICAL);
        layout.setShowDividers(LinearLayout.SHOW_DIVIDER_NONE);
        layout.setPadding(0, 0, 0, 0);
        return layout;
    }

    static LinearLayout h(Context context, int spacingDp) {
        LinearLayout layout = new LinearLayout(context);
        layout.setOrientation(LinearLayout.HORIZONTAL);
        layout.setGravity(Gravity.CENTER_VERTICAL);
        return layout;
    }

    static ScrollView scroll(Context context, View child) {
        ScrollView scrollView = new ScrollView(context);
        scrollView.setFillViewport(false);
        scrollView.setBackgroundColor(AppColors.BACKGROUND);
        scrollView.addView(child, matchWrap());
        return scrollView;
    }

    static LinearLayout screen(Context context) {
        LinearLayout root = v(context, 0);
        root.setPadding(dp(context, 20), dp(context, 58), dp(context, 20), dp(context, 28));
        root.setBackgroundColor(AppColors.BACKGROUND);
        return root;
    }

    static LinearLayout panel(Context context) {
        LinearLayout panel = v(context, 0);
        panel.setPadding(dp(context, 16), dp(context, 16), dp(context, 16), dp(context, 16));
        panel.setBackground(stroke(AppColors.PANEL, AppColors.BORDER, dp(context, 18)));
        return panel;
    }

    static LinearLayout fieldGroup(Context context, String label, EditText input) {
        LinearLayout group = v(context, 0);
        group.addView(text(context, label, 14, AppColors.TEXT, Typeface.BOLD), matchWrap());
        addSpacer(context, group, 8);
        input.setTextColor(AppColors.TEXT);
        input.setTextSize(16);
        input.setPadding(dp(context, 14), 0, dp(context, 14), 0);
        input.setMinHeight(dp(context, 48));
        input.setBackground(stroke(AppColors.FIELD, AppColors.BORDER, dp(context, 12)));
        group.addView(input, matchWrap());
        return group;
    }

    static EditText edit(Context context, String hint) {
        EditText input = new EditText(context);
        input.setHint(hint);
        input.setInputType(InputType.TYPE_CLASS_TEXT | InputType.TYPE_TEXT_FLAG_CAP_SENTENCES);
        input.setSingleLine(true);
        return input;
    }

    static EditText multi(Context context, String hint) {
        EditText input = edit(context, hint);
        input.setSingleLine(false);
        input.setMinLines(3);
        input.setGravity(Gravity.TOP | Gravity.START);
        return input;
    }

    static EditText password(Context context, String hint) {
        EditText input = edit(context, hint);
        input.setInputType(InputType.TYPE_CLASS_TEXT | InputType.TYPE_TEXT_VARIATION_PASSWORD);
        return input;
    }

    static Button primary(Context context, String text) {
        Button button = new Button(context);
        button.setText(text);
        button.setTextColor(AppColors.PANEL);
        button.setTextSize(16);
        button.setTypeface(Typeface.DEFAULT, Typeface.BOLD);
        button.setAllCaps(false);
        button.setMinHeight(dp(context, 52));
        button.setBackground(stroke(AppColors.ACCENT, AppColors.ACCENT, dp(context, 12)));
        return button;
    }

    static Button secondary(Context context, String text) {
        Button button = new Button(context);
        button.setText(text);
        button.setTextColor(AppColors.ACCENT);
        button.setTextSize(16);
        button.setTypeface(Typeface.DEFAULT, Typeface.BOLD);
        button.setAllCaps(false);
        button.setMinHeight(dp(context, 48));
        button.setBackground(stroke(withAlpha(AppColors.ACCENT, 28), withAlpha(AppColors.ACCENT, 86), dp(context, 12)));
        return button;
    }

    static Button danger(Context context, String text) {
        Button button = secondary(context, text);
        button.setTextColor(AppColors.DANGER);
        button.setBackground(stroke(withAlpha(AppColors.DANGER, 24), withAlpha(AppColors.DANGER, 86), dp(context, 12)));
        return button;
    }

    static ImageButton iconButton(Context context, int resId) {
        ImageButton button = new ImageButton(context);
        button.setImageResource(resId);
        button.setBackground(round(withAlpha(AppColors.ACCENT, 24), dp(context, 21)));
        button.setColorFilter(AppColors.ACCENT);
        button.setPadding(dp(context, 10), dp(context, 10), dp(context, 10), dp(context, 10));
        button.setScaleType(ImageView.ScaleType.CENTER);
        return button;
    }

    static TextView message(Context context, String message, boolean isError) {
        TextView view = text(context, message, 14, isError ? AppColors.DANGER : AppColors.ACCENT, Typeface.BOLD);
        view.setPadding(dp(context, 12), dp(context, 10), dp(context, 12), dp(context, 10));
        view.setBackground(round(withAlpha(isError ? AppColors.DANGER : AppColors.ACCENT, 24), dp(context, 12)));
        return view;
    }

    static TextView chip(Context context, String text, int color, boolean selected) {
        TextView view = text(context, text, 13, selected ? AppColors.PANEL : color, Typeface.BOLD);
        view.setGravity(Gravity.CENTER);
        view.setPadding(dp(context, 12), dp(context, 8), dp(context, 12), dp(context, 8));
        view.setBackground(round(selected ? color : withAlpha(color, 28), dp(context, 22)));
        return view;
    }

    static LinearLayout cardRow(Context context, String title, String detail, String leading) {
        LinearLayout row = h(context, 0);
        row.setPadding(dp(context, 14), dp(context, 12), dp(context, 14), dp(context, 12));
        row.setBackground(round(AppColors.FIELD, dp(context, 12)));

        TextView icon = text(context, leading, 20, AppColors.ACCENT, Typeface.BOLD);
        icon.setGravity(Gravity.CENTER);
        row.addView(icon, fixed(context, 40, 40));

        LinearLayout texts = v(context, 0);
        texts.addView(text(context, title, 15, AppColors.TEXT, Typeface.BOLD), matchWrap());
        if (detail != null && !detail.isEmpty()) {
            texts.addView(muted(context, detail), matchWrap());
        }
        LinearLayout.LayoutParams textParams = new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1);
        textParams.leftMargin = dp(context, 10);
        row.addView(texts, textParams);
        return row;
    }

    static GridLayout grid(Context context, int columns) {
        GridLayout grid = new GridLayout(context);
        grid.setColumnCount(columns);
        grid.setUseDefaultMargins(false);
        return grid;
    }

    static void addGridChild(Context context, GridLayout grid, View child, int columns) {
        GridLayout.LayoutParams params = new GridLayout.LayoutParams();
        params.width = 0;
        params.height = ViewGroup.LayoutParams.WRAP_CONTENT;
        params.columnSpec = GridLayout.spec(GridLayout.UNDEFINED, 1f);
        params.setMargins(dp(context, 5), dp(context, 5), dp(context, 5), dp(context, 5));
        grid.addView(child, params);
    }

    static void addGridChildFixedHeight(Context context, GridLayout grid, View child, int heightDp) {
        GridLayout.LayoutParams params = new GridLayout.LayoutParams();
        params.width = 0;
        params.height = dp(context, heightDp);
        params.columnSpec = GridLayout.spec(GridLayout.UNDEFINED, 1f);
        params.setMargins(dp(context, 5), dp(context, 5), dp(context, 5), dp(context, 5));
        grid.addView(child, params);
    }

    static CheckBox check(Context context, String text) {
        CheckBox checkBox = new CheckBox(context);
        checkBox.setText(text);
        checkBox.setTextColor(AppColors.MUTED);
        checkBox.setTextSize(13);
        checkBox.setButtonTintList(android.content.res.ColorStateList.valueOf(AppColors.ACCENT));
        checkBox.setPadding(dp(context, 8), dp(context, 6), dp(context, 8), dp(context, 6));
        checkBox.setBackground(round(AppColors.FIELD, dp(context, 12)));
        return checkBox;
    }

    static void addSpacer(Context context, LinearLayout layout, int heightDp) {
        View spacer = new View(context);
        layout.addView(spacer, new LinearLayout.LayoutParams(1, dp(context, heightDp)));
    }

    static void addSpacerHorizontal(Context context, LinearLayout layout, int widthDp) {
        View spacer = new View(context);
        layout.addView(spacer, new LinearLayout.LayoutParams(dp(context, widthDp), 1));
    }

    static LinearLayout.LayoutParams matchWrap() {
        return new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT);
    }

    static LinearLayout.LayoutParams wrapWrap() {
        return new LinearLayout.LayoutParams(ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT);
    }

    static LinearLayout.LayoutParams fixed(Context context, int widthDp, int heightDp) {
        return new LinearLayout.LayoutParams(dp(context, widthDp), dp(context, heightDp));
    }

    static FrameLayout.LayoutParams frameMatch() {
        return new FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT);
    }

    static GradientDrawable round(int color, int radiusPx) {
        GradientDrawable drawable = new GradientDrawable();
        drawable.setColor(color);
        drawable.setCornerRadius(radiusPx);
        return drawable;
    }

    static GradientDrawable roundTop(int color, int radiusPx) {
        GradientDrawable drawable = new GradientDrawable();
        drawable.setColor(color);
        drawable.setCornerRadii(new float[]{
                radiusPx, radiusPx,
                radiusPx, radiusPx,
                0, 0,
                0, 0
        });
        return drawable;
    }

    static GradientDrawable stroke(int fill, int stroke, int radiusPx) {
        GradientDrawable drawable = round(fill, radiusPx);
        drawable.setStroke(1, stroke);
        return drawable;
    }

    static int withAlpha(int color, int alpha) {
        return (color & 0x00FFFFFF) | (alpha << 24);
    }

    static Dialog dialog(Context context, String title, View content, String positive, Runnable onPositive) {
        Dialog dialog = bottomSheet(context, title, content, positive, onPositive);
        dialog.show();
        return dialog;
    }

    static Dialog dialogWithTopAction(Context context, String title, View content, String action, Runnable onAction) {
        Dialog dialog = new Dialog(context);
        dialog.requestWindowFeature(Window.FEATURE_NO_TITLE);
        dialog.setCanceledOnTouchOutside(true);

        LinearLayout sheet = v(context, 0);
        sheet.setPadding(dp(context, 18), dp(context, 10), dp(context, 18), dp(context, 16));
        sheet.setBackground(roundTop(AppColors.BACKGROUND, dp(context, 30)));
        sheet.setMinimumHeight(bottomSheetHeight(context));

        View handle = new View(context);
        handle.setBackground(round(withAlpha(AppColors.MUTED, 115), dp(context, 3)));
        LinearLayout.LayoutParams handleParams = new LinearLayout.LayoutParams(dp(context, 42), dp(context, 4));
        handleParams.gravity = Gravity.CENTER_HORIZONTAL;
        handleParams.bottomMargin = dp(context, 12);
        sheet.addView(handle, handleParams);

        LinearLayout header = h(context, 0);
        header.setPadding(0, 0, 0, dp(context, 12));
        TextView titleView = text(context, title, 24, AppColors.TEXT, Typeface.BOLD);
        titleView.setGravity(Gravity.CENTER_VERTICAL | Gravity.START);
        titleView.setSingleLine(false);
        header.addView(titleView, new LinearLayout.LayoutParams(0, dp(context, 58), 1));

        TextView done = text(context, action, 18, AppColors.ACCENT, Typeface.BOLD);
        done.setGravity(Gravity.CENTER);
        done.setBackground(round(AppColors.PANEL, dp(context, 28)));
        done.setOnClickListener(v -> {
            if (onAction != null) {
                onAction.run();
            }
            dialog.dismiss();
        });
        LinearLayout.LayoutParams doneParams = fixed(context, 96, 56);
        doneParams.leftMargin = dp(context, 10);
        header.addView(done, doneParams);
        sheet.addView(header, matchWrap());

        ScrollView scroll = new ScrollView(context);
        scroll.setFillViewport(false);
        scroll.setBackgroundColor(Color.TRANSPARENT);
        scroll.addView(content, matchWrap());
        sheet.addView(scroll, new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, 0, 1));

        final float[] startY = {0};
        View.OnTouchListener dismissDrag = (view, event) -> {
            if (event.getAction() == MotionEvent.ACTION_DOWN) {
                startY[0] = event.getRawY();
                return true;
            }
            if (event.getAction() == MotionEvent.ACTION_UP) {
                if (event.getRawY() - startY[0] > dp(context, 70)) {
                    dialog.dismiss();
                }
                return true;
            }
            return true;
        };
        handle.setOnTouchListener(dismissDrag);

        dialog.setContentView(sheet);
        configureBottomSheetWindow(context, dialog);
        dialog.setOnShowListener(d -> configureBottomSheetWindow(context, dialog));
        dialog.show();
        return dialog;
    }

    static Dialog bottomSheet(Context context, String title, View content, String positive, Runnable onPositive) {
        Dialog dialog = new Dialog(context);
        dialog.requestWindowFeature(Window.FEATURE_NO_TITLE);
        dialog.setCanceledOnTouchOutside(true);

        LinearLayout sheet = v(context, 0);
        sheet.setPadding(dp(context, 18), dp(context, 10), dp(context, 18), dp(context, 16));
        sheet.setBackground(roundTop(AppColors.BACKGROUND, dp(context, 30)));
        sheet.setMinimumHeight(bottomSheetHeight(context));

        View handle = new View(context);
        handle.setBackground(round(withAlpha(AppColors.MUTED, 115), dp(context, 3)));
        LinearLayout.LayoutParams handleParams = new LinearLayout.LayoutParams(dp(context, 42), dp(context, 4));
        handleParams.gravity = Gravity.CENTER_HORIZONTAL;
        handleParams.bottomMargin = dp(context, 12);
        sheet.addView(handle, handleParams);

        LinearLayout header = h(context, 0);
        header.setPadding(0, 0, 0, dp(context, 12));
        TextView titleView = text(context, title, 24, AppColors.TEXT, Typeface.BOLD);
        titleView.setGravity(Gravity.CENTER_VERTICAL | Gravity.START);
        titleView.setSingleLine(false);
        header.addView(titleView, new LinearLayout.LayoutParams(0, dp(context, 58), 1));
        TextView close = text(context, "×", 32, AppColors.ACCENT, Typeface.BOLD);
        close.setGravity(Gravity.CENTER);
        close.setBackground(round(withAlpha(AppColors.ACCENT, 18), dp(context, 28)));
        close.setOnClickListener(v -> dialog.dismiss());
        header.addView(close, fixed(context, 56, 56));
        sheet.addView(header, matchWrap());

        ScrollView scroll = new ScrollView(context);
        scroll.setFillViewport(false);
        scroll.setBackgroundColor(Color.TRANSPARENT);
        scroll.addView(content, matchWrap());
        LinearLayout.LayoutParams scrollParams = new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                0,
                1
        );
        sheet.addView(scroll, scrollParams);

        if (positive != null && !positive.isEmpty()) {
            Button save = primary(context, positive);
            LinearLayout.LayoutParams saveParams = matchWrap();
            saveParams.topMargin = dp(context, 14);
            sheet.addView(save, saveParams);
            save.setOnClickListener(v -> {
                if (onPositive != null) {
                    onPositive.run();
                }
                dialog.dismiss();
            });
        }

        final float[] startY = {0};
        View.OnTouchListener dismissDrag = (view, event) -> {
            if (event.getAction() == MotionEvent.ACTION_DOWN) {
                startY[0] = event.getRawY();
                return true;
            }
            if (event.getAction() == MotionEvent.ACTION_UP) {
                if (event.getRawY() - startY[0] > dp(context, 70)) {
                    dialog.dismiss();
                }
                return true;
            }
            return true;
        };
        handle.setOnTouchListener(dismissDrag);
        header.setOnTouchListener(dismissDrag);

        dialog.setContentView(sheet);
        configureBottomSheetWindow(context, dialog);
        dialog.setOnShowListener(d -> {
            configureBottomSheetWindow(context, dialog);
        });
        return dialog;
    }

    private static int bottomSheetHeight(Context context) {
        return Math.round(context.getResources().getDisplayMetrics().heightPixels * 0.92f);
    }

    private static void configureBottomSheetWindow(Context context, Dialog dialog) {
        Window window = dialog.getWindow();
        if (window == null) return;
        window.setBackgroundDrawable(new ColorDrawable(Color.TRANSPARENT));
        window.setDimAmount(0.55f);
        window.addFlags(WindowManager.LayoutParams.FLAG_DIM_BEHIND);
        window.setGravity(Gravity.BOTTOM | Gravity.CENTER_HORIZONTAL);
        window.setWindowAnimations(R.style.BottomSheetAnimation);
        window.getDecorView().setPadding(0, 0, 0, 0);
        WindowManager.LayoutParams attrs = window.getAttributes();
        attrs.width = ViewGroup.LayoutParams.MATCH_PARENT;
        attrs.height = bottomSheetHeight(context);
        attrs.gravity = Gravity.BOTTOM | Gravity.CENTER_HORIZONTAL;
        attrs.x = 0;
        attrs.y = 0;
        attrs.horizontalMargin = 0;
        attrs.verticalMargin = 0;
        window.setAttributes(attrs);
    }
}
