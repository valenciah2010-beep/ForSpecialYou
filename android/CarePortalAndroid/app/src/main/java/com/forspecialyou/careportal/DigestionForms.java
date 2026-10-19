package com.forspecialyou.careportal;

import android.graphics.Color;
import android.view.Gravity;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.GridLayout;
import android.widget.HorizontalScrollView;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;
import java.util.Calendar;

final class DigestionForms {

    private final MainActivity host;

    DigestionForms(MainActivity host) {
        this.host = host;
    }

    void showDigestionLogDialog(String title) {
        int tint = host.snapshotColor("digestion");
        Calendar movementTime = Calendar.getInstance();
        LinearLayout content = host.quickFormContent();
        content.addView(host.movementTimeCard(movementTime), Ui.matchWrap());
        Ui.addSpacer(host, content, 12);
        int[] stoolType = { 4 };
        content.addView(host.bristolConsistencySection(stoolType, tint), Ui.matchWrap());
        Ui.addSpacer(host, content, 12);
        String[] volume = { "Medium" };
        content.addView(host.singleChoiceSection(host.i18n.t("Volume"), new String[] { "Small", "Medium", "Large" }, volume, tint), Ui.matchWrap());
        Ui.addSpacer(host, content, 12);
        String[] stoolColor = { "Brown" };
        content.addView(host.stoolColorSection(stoolColor, tint), Ui.matchWrap());
        Ui.addSpacer(host, content, 12);
        String[] straining = { "" };
        String[] gas = { "" };
        String[] undigested = { "" };
        LinearLayout painCard = host.sectionCard(host.i18n.t("Pain & Strain"));
        painCard.addView(host.digestionYesNoRow("Straining/Discomfort during the movement?", straining, tint), Ui.matchWrap());
        Ui.addSpacer(host, painCard, 10);
        painCard.addView(host.digestionYesNoRow("Excessive gas or bloating noticed afterward?", gas, tint), Ui.matchWrap());
        Ui.addSpacer(host, painCard, 10);
        painCard.addView(host.digestionYesNoRow("Visible undigested food in the stool?", undigested, tint), Ui.matchWrap());
        content.addView(painCard, Ui.matchWrap());
        host.showQuickLogForm(host.i18n.t("Gut & Digestion"), content, () -> {
            String group = host.bristolGroup(stoolType[0]);
            String description = host.bristolDescription(stoolType[0]);
            String value = host.i18n.t("Type") + " " + stoolType[0] + " · " + host.i18n.t(group);
            String detail = host.joinNotes(host.noteLine(host.i18n.t("Time"), host.formatDisplayTime(movementTime)), host.noteLine(host.i18n.t("Consistency"), host.i18n.t("Type") + " " + stoolType[0] + " - " + host.i18n.t(description)), host.noteLine(host.i18n.t("Volume"), host.i18n.t(volume[0])), host.noteLine(host.i18n.t("Color"), host.i18n.t(stoolColor[0])), host.noteLine(host.i18n.t("Straining/Discomfort"), host.digestionAnswer(straining[0])), host.noteLine(host.i18n.t("Gas/Bloating"), host.digestionAnswer(gas[0])), host.noteLine(host.i18n.t("Undigested Food"), host.digestionAnswer(undigested[0])));
            host.addHealthEntry("digestion", title, "snapshot", value, detail, movementTime);
            host.render();
        });
    }

    LinearLayout movementTimeCard(Calendar movementTime) {
        LinearLayout card = Ui.h(host, 0);
        card.setGravity(Gravity.CENTER_VERTICAL);
        card.setPadding(Ui.dp(host, 16), Ui.dp(host, 14), Ui.dp(host, 16), Ui.dp(host, 14));
        card.setBackground(Ui.stroke(AppColors.PANEL, Ui.withAlpha(AppColors.BORDER, 150), Ui.dp(host, 20)));
        TextView label = Ui.text(host, host.i18n.t("Movement time"), 17, AppColors.TEXT, android.graphics.Typeface.BOLD);
        label.setSingleLine(true);
        card.addView(label, new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1));
        Button time = host.timeButton(movementTime);
        host.styleTimestampButton(time);
        card.addView(time, Ui.fixed(host, 104, 42));
        return card;
    }

    LinearLayout bristolConsistencySection(int[] selectedType, int tint) {
        LinearLayout card = host.sectionCard("");
        card.removeAllViews();
        LinearLayout header = Ui.h(host, 0);
        header.setGravity(Gravity.CENTER_VERTICAL);
        LinearLayout textStack = Ui.v(host, 0);
        textStack.addView(Ui.text(host, host.i18n.t("Consistency"), 18, AppColors.TEXT, android.graphics.Typeface.BOLD), Ui.matchWrap());
        textStack.addView(Ui.text(host, host.i18n.t("The Bristol Stool Chart"), 13, AppColors.MUTED, android.graphics.Typeface.BOLD), Ui.matchWrap());
        header.addView(textStack, new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1));
        Button info = Ui.secondary(host, "i");
        info.setTextSize(16);
        info.setTextColor(Color.WHITE);
        info.setMinWidth(0);
        info.setMinHeight(Ui.dp(host, 38));
        info.setBackground(Ui.round(tint, Ui.dp(host, 19)));
        info.setOnClickListener(v -> host.showBristolInfoSheet(tint));
        header.addView(info, Ui.fixed(host, 38, 38));
        card.addView(header, Ui.matchWrap());
        Ui.addSpacer(host, card, 14);
        HorizontalScrollView scroll = new HorizontalScrollView(host);
        scroll.setHorizontalScrollBarEnabled(false);
        LinearLayout row = Ui.h(host, 0);
        View[] tiles = new View[8];
        for (int type = 1; type <= 7; type++) {
            LinearLayout tile = host.stoolTypeTile(type, selectedType[0] == type, tint);
            final int finalType = type;
            tile.setOnClickListener(v -> {
                selectedType[0] = finalType;
                for (int i = 1; i <= 7; i++) {
                    host.styleStoolTypeTile(tiles[i], selectedType[0] == i, tint);
                }
            });
            tiles[type] = tile;
            row.addView(tile, Ui.fixed(host, 120, 132));
            Ui.addSpacerHorizontal(host, row, 10);
        }
        scroll.addView(row, Ui.wrapWrap());
        card.addView(scroll, Ui.matchWrap());
        return card;
    }

    LinearLayout stoolTypeTile(int type, boolean selected, int tint) {
        LinearLayout tile = Ui.v(host, 0);
        tile.setGravity(Gravity.CENTER);
        tile.setPadding(Ui.dp(host, 10), Ui.dp(host, 10), Ui.dp(host, 10), Ui.dp(host, 10));
        ImageView image = new ImageView(host);
        image.setImageResource(host.bristolDrawable(type));
        image.setAdjustViewBounds(true);
        image.setScaleType(ImageView.ScaleType.FIT_CENTER);
        tile.addView(image, Ui.fixed(host, 92, 58));
        Ui.addSpacer(host, tile, 8);
        TextView typeLabel = Ui.text(host, host.i18n.t("Type") + " " + type, 13, AppColors.TEXT, android.graphics.Typeface.BOLD);
        typeLabel.setGravity(Gravity.CENTER);
        tile.addView(typeLabel, Ui.matchWrap());
        TextView group = Ui.text(host, host.i18n.t(host.bristolGroup(type)), 12, AppColors.MUTED, android.graphics.Typeface.BOLD);
        group.setGravity(Gravity.CENTER);
        group.setSingleLine(true);
        tile.addView(group, Ui.matchWrap());
        host.styleStoolTypeTile(tile, selected, tint);
        return tile;
    }

    void styleStoolTypeTile(View tile, boolean selected, int tint) {
        if (tile == null)
            return;
        tile.setBackground(Ui.stroke(selected ? Ui.withAlpha(tint, 42) : AppColors.FIELD, selected ? tint : Color.TRANSPARENT, Ui.dp(host, 14)));
    }

    int bristolDrawable(int type) {
        switch(type) {
            case 1:
                return R.drawable.bristol_stool_type_1;
            case 2:
                return R.drawable.bristol_stool_type_2;
            case 3:
                return R.drawable.bristol_stool_type_3;
            case 4:
                return R.drawable.bristol_stool_type_4;
            case 5:
                return R.drawable.bristol_stool_type_5;
            case 6:
                return R.drawable.bristol_stool_type_6;
            default:
                return R.drawable.bristol_stool_type_7;
        }
    }

    String bristolGroup(int type) {
        if (type <= 2)
            return "Constipation";
        if (type <= 4)
            return "Optimal";
        return "Diarrhea/Intolerance";
    }

    String bristolDescription(int type) {
        switch(type) {
            case 1:
                return "Separate hard lumps, like little pebbles.";
            case 2:
                return "Hard and lumpy, starting to resemble a sausage.";
            case 3:
                return "Sausage-shaped with cracks on the surface.";
            case 4:
                return "Smooth and soft, snake-like.";
            case 5:
                return "Soft blobs with clear-cut edges.";
            case 6:
                return "Fluffy, mushy pieces with ragged edges.";
            default:
                return "Watery with no solid pieces.";
        }
    }

    LinearLayout stoolColorSection(String[] selected, int tint) {
        LinearLayout card = host.sectionCard(host.i18n.t("Color Check"));
        GridLayout grid = Ui.grid(host, 5);
        String[][] colors = { { "Brown", "#7A4021" }, { "Green", "#478C40" }, { "Clay/White", "#E6DBB8" }, { "Black", "#141210" }, { "Red", "#BA1F1C" } };
        View[] tiles = new View[colors.length];
        for (int i = 0; i < colors.length; i++) {
            String name = colors[i][0];
            int swatch = Color.parseColor(colors[i][1]);
            LinearLayout tile = host.stoolColorTile(name, swatch, name.equals(selected[0]), tint);
            final int index = i;
            tile.setOnClickListener(v -> {
                selected[0] = colors[index][0];
                for (int j = 0; j < tiles.length; j++) {
                    host.styleStoolColorTile(tiles[j], colors[j][0].equals(selected[0]), tint);
                }
            });
            tiles[i] = tile;
            Ui.addGridChild(host, grid, tile, 5);
        }
        card.addView(grid, Ui.matchWrap());
        return card;
    }

    LinearLayout stoolColorTile(String name, int swatch, boolean selected, int tint) {
        LinearLayout tile = Ui.v(host, 0);
        tile.setGravity(Gravity.CENTER);
        tile.setPadding(Ui.dp(host, 6), Ui.dp(host, 8), Ui.dp(host, 6), Ui.dp(host, 8));
        TextView circle = Ui.text(host, "●", 34, swatch, android.graphics.Typeface.BOLD);
        circle.setGravity(Gravity.CENTER);
        tile.addView(circle, Ui.matchWrap());
        TextView label = Ui.text(host, host.i18n.t(name), 10, AppColors.TEXT, android.graphics.Typeface.BOLD);
        label.setGravity(Gravity.CENTER);
        label.setSingleLine(true);
        tile.addView(label, Ui.matchWrap());
        host.styleStoolColorTile(tile, selected, tint);
        return tile;
    }

    void styleStoolColorTile(View tile, boolean selected, int tint) {
        if (tile == null)
            return;
        tile.setBackground(Ui.stroke(selected ? Ui.withAlpha(tint, 30) : AppColors.FIELD, selected ? tint : Color.TRANSPARENT, Ui.dp(host, 12)));
    }

    LinearLayout digestionYesNoRow(String title, String[] selected, int tint) {
        LinearLayout row = Ui.v(host, 0);
        row.addView(Ui.text(host, host.i18n.t(title), 14, AppColors.TEXT, android.graphics.Typeface.BOLD), Ui.matchWrap());
        Ui.addSpacer(host, row, 8);
        LinearLayout buttons = Ui.h(host, 0);
        Button yes = Ui.secondary(host, host.i18n.t("Yes"));
        Button no = Ui.secondary(host, host.i18n.t("No"));
        Runnable update = () -> {
            host.styleToggleButton(yes, "Yes".equals(selected[0]), tint);
            host.styleToggleButton(no, "No".equals(selected[0]), tint);
        };
        yes.setOnClickListener(v -> {
            selected[0] = "Yes".equals(selected[0]) ? "" : "Yes";
            update.run();
        });
        no.setOnClickListener(v -> {
            selected[0] = "No".equals(selected[0]) ? "" : "No";
            update.run();
        });
        update.run();
        buttons.addView(yes, new LinearLayout.LayoutParams(0, Ui.dp(host, 44), 1));
        Ui.addSpacerHorizontal(host, buttons, 10);
        buttons.addView(no, new LinearLayout.LayoutParams(0, Ui.dp(host, 44), 1));
        row.addView(buttons, Ui.matchWrap());
        return row;
    }

    void styleToggleButton(Button button, boolean selected, int tint) {
        button.setTextColor(selected ? Color.WHITE : AppColors.TEXT);
        button.setBackground(Ui.stroke(selected ? tint : AppColors.FIELD, selected ? tint : Color.TRANSPARENT, Ui.dp(host, 12)));
    }

    String digestionAnswer(String value) {
        return value == null || value.isEmpty() ? "--" : host.i18n.t(value);
    }

    void showBristolInfoSheet(int tint) {
        LinearLayout content = host.quickFormContent();
        for (int type = 1; type <= 7; type++) {
            LinearLayout row = Ui.h(host, 0);
            row.setGravity(Gravity.CENTER_VERTICAL);
            row.setPadding(Ui.dp(host, 12), Ui.dp(host, 12), Ui.dp(host, 12), Ui.dp(host, 12));
            row.setBackground(Ui.stroke(AppColors.PANEL, Ui.withAlpha(AppColors.BORDER, 130), Ui.dp(host, 14)));
            ImageView image = new ImageView(host);
            image.setImageResource(host.bristolDrawable(type));
            image.setScaleType(ImageView.ScaleType.FIT_CENTER);
            image.setBackground(Ui.round(Ui.withAlpha(tint, 20), Ui.dp(host, 12)));
            image.setPadding(Ui.dp(host, 8), Ui.dp(host, 8), Ui.dp(host, 8), Ui.dp(host, 8));
            row.addView(image, Ui.fixed(host, 92, 66));
            Ui.addSpacerHorizontal(host, row, 12);
            LinearLayout texts = Ui.v(host, 0);
            texts.addView(Ui.text(host, host.i18n.t("Type") + " " + type, 16, AppColors.TEXT, android.graphics.Typeface.BOLD), Ui.matchWrap());
            texts.addView(Ui.text(host, host.i18n.t(host.bristolGroup(type)), 12, tint, android.graphics.Typeface.BOLD), Ui.matchWrap());
            texts.addView(Ui.muted(host, host.i18n.t(host.bristolDescription(type))), Ui.matchWrap());
            row.addView(texts, new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1));
            content.addView(row, Ui.matchWrap());
            Ui.addSpacer(host, content, 10);
        }
        Ui.dialog(host, host.i18n.t("Bristol Stool Chart"), content, host.i18n.t("Done"), null);
    }
}
