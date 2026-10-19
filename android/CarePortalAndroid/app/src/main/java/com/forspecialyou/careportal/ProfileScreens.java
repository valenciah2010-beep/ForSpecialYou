package com.forspecialyou.careportal;

import android.app.Dialog;
import android.content.Intent;
import android.graphics.Bitmap;
import android.graphics.BitmapShader;
import android.graphics.BitmapFactory;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.Shader;
import android.provider.MediaStore;
import android.util.Base64;
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

final class ProfileScreens {

    private final MainActivity host;

    ProfileScreens(MainActivity host) {
        this.host = host;
    }

    View profileView() {
        LinearLayout screen = Ui.screen(host);
        LinearLayout header = Ui.v(host, 0);
        header.setGravity(Gravity.CENTER_HORIZONTAL);
        header.setPadding(0, Ui.dp(host, 10), 0, Ui.dp(host, 6));
        View avatar = host.profileAvatarButton();
        LinearLayout.LayoutParams avatarParams = Ui.fixed(host, 112, 112);
        avatarParams.gravity = Gravity.CENTER_HORIZONTAL;
        header.addView(avatar, avatarParams);
        Ui.addSpacer(host, header, 12);
        LinearLayout nameRow = Ui.h(host, 0);
        nameRow.setGravity(Gravity.CENTER);
        nameRow.setClickable(true);
        nameRow.setFocusable(true);
        nameRow.setOnClickListener(v -> host.showBasicInfoDialog());
        TextView name = Ui.text(host, host.currentUser.nickname, 30, AppColors.TEXT, android.graphics.Typeface.BOLD);
        nameRow.addView(name, Ui.wrapWrap());
        Ui.addSpacerHorizontal(host, nameRow, 8);
        nameRow.addView(host.symbolIcon(R.drawable.ios_icon_chevron_right, AppColors.MUTED, Color.TRANSPARENT, 24, 4), Ui.fixed(host, 24, 24));
        header.addView(nameRow, Ui.matchWrap());
        TextView sub = Ui.muted(host, host.i18n.t("Parent account for your child's care."));
        sub.setGravity(Gravity.CENTER);
        header.addView(sub, Ui.matchWrap());
        screen.addView(header, Ui.matchWrap());
        Ui.addSpacer(host, screen, 20);
        LinearLayout account = Ui.panel(host);
        account.addView(Ui.sectionTitle(host, host.i18n.t("Parent Account")), Ui.matchWrap());
        Ui.addSpacer(host, account, 10);
        account.addView(host.infoRow(host.i18n.t("Parent Username"), host.currentUser.nickname), Ui.matchWrap());
        account.addView(host.infoRow(host.i18n.t("Parent Email"), host.currentUser.email), Ui.matchWrap());
        account.addView(host.infoRow(host.i18n.t("Account Type"), host.i18n.t("Parent")), Ui.matchWrap());
        screen.addView(account, Ui.matchWrap());
        Ui.addSpacer(host, screen, 14);
        screen.addView(host.profileNavRow(host.i18n.t("Settings"), () -> host.showLanguageDialog()), Ui.matchWrap());
        Ui.addSpacer(host, screen, 10);
        Button logout = Ui.danger(host, host.i18n.t("Log Out"));
        logout.setOnClickListener(v -> host.logout());
        screen.addView(logout, Ui.matchWrap());
        return Ui.scroll(host, screen);
    }

    View profileAvatarButton() {
        FrameLayout frame = new FrameLayout(host);
        String image = host.storage.getString(host.storage.key("profile", host.currentUser.id, "profileImageData"), "");
        if (image.isEmpty() && host.currentUser.profileImage != null) {
            image = host.currentUser.profileImage;
        }
        Bitmap bitmap = host.bitmapFromDataUrl(image);
        View main;
        if (bitmap != null) {
            ImageView photo = new ImageView(host);
            photo.setImageBitmap(host.circleBitmap(bitmap));
            photo.setScaleType(ImageView.ScaleType.CENTER_CROP);
            main = photo;
        } else {
            TextView fallback = Ui.text(host, host.initials(host.currentUser.nickname), 30, AppColors.ACCENT, android.graphics.Typeface.BOLD);
            fallback.setGravity(Gravity.CENTER);
            fallback.setBackground(Ui.round(Ui.withAlpha(AppColors.ACCENT, 24), Ui.dp(host, 54)));
            main = fallback;
        }
        FrameLayout.LayoutParams mainParams = new FrameLayout.LayoutParams(Ui.dp(host, 108), Ui.dp(host, 108), Gravity.CENTER);
        frame.addView(main, mainParams);
        ImageView camera = host.symbolIcon(R.drawable.ios_icon_camera_fill, AppColors.PANEL, AppColors.ACCENT, 34, 8);
        camera.setBackground(Ui.stroke(AppColors.ACCENT, AppColors.PANEL, Ui.dp(host, 17)));
        FrameLayout.LayoutParams cameraParams = new FrameLayout.LayoutParams(Ui.dp(host, 34), Ui.dp(host, 34), Gravity.BOTTOM | Gravity.RIGHT);
        cameraParams.setMargins(0, 0, Ui.dp(host, 4), Ui.dp(host, 4));
        frame.addView(camera, cameraParams);
        frame.setClickable(true);
        frame.setFocusable(true);
        frame.setOnClickListener(v -> host.showProfilePhotoDialog());
        return frame;
    }

    Bitmap circleBitmap(Bitmap source) {
        int size = Math.min(source.getWidth(), source.getHeight());
        int x = (source.getWidth() - size) / 2;
        int y = (source.getHeight() - size) / 2;
        Bitmap squared = Bitmap.createBitmap(source, x, y, size, size);
        Bitmap output = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888);
        Canvas canvas = new Canvas(output);
        Paint paint = new Paint(Paint.ANTI_ALIAS_FLAG);
        paint.setShader(new BitmapShader(squared, Shader.TileMode.CLAMP, Shader.TileMode.CLAMP));
        float radius = size / 2f;
        canvas.drawCircle(radius, radius, radius, paint);
        return output;
    }

    LinearLayout profileNavRow(String title, Runnable action) {
        LinearLayout row = Ui.h(host, 0);
        row.setGravity(Gravity.CENTER_VERTICAL);
        row.setPadding(Ui.dp(host, 18), Ui.dp(host, 16), Ui.dp(host, 14), Ui.dp(host, 16));
        row.setBackground(Ui.round(Ui.withAlpha(AppColors.ACCENT, 22), Ui.dp(host, 12)));
        row.setClickable(true);
        row.setFocusable(true);
        row.setOnClickListener(v -> {
            if (action != null)
                action.run();
        });
        TextView label = Ui.text(host, title, 18, AppColors.ACCENT, android.graphics.Typeface.BOLD);
        label.setGravity(Gravity.CENTER);
        row.addView(label, new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1));
        row.addView(host.symbolIcon(R.drawable.ios_icon_chevron_right, AppColors.ACCENT, Color.TRANSPARENT, 26, 4), Ui.fixed(host, 26, 26));
        return row;
    }

    void showProfilePhotoDialog() {
        host.showChoiceSheet(host.i18n.t("Change child profile picture"), new String[] { host.i18n.t("Choose Photo"), host.i18n.t("Take Photo") }, (which, sheet) -> {
            sheet.dismiss();
            if (which == 0)
                host.chooseProfilePhoto();
            else
                host.takeProfilePhoto();
        });
    }

    void showChoiceSheet(String title, String[] choices, MainActivity.SheetChoiceHandler handler) {
        LinearLayout content = Ui.v(host, 0);
        content.setPadding(Ui.dp(host, 12), 0, Ui.dp(host, 12), 0);
        final Dialog[] holder = new Dialog[1];
        for (int i = 0; i < choices.length; i++) {
            final int index = i;
            LinearLayout row = Ui.h(host, 0);
            row.setGravity(Gravity.CENTER_VERTICAL);
            row.setPadding(Ui.dp(host, 16), Ui.dp(host, 16), Ui.dp(host, 16), Ui.dp(host, 16));
            row.setBackground(Ui.stroke(AppColors.PANEL, AppColors.BORDER, Ui.dp(host, 16)));
            row.setClickable(true);
            row.setFocusable(true);
            TextView label = Ui.text(host, choices[i], 18, AppColors.TEXT, android.graphics.Typeface.BOLD);
            row.addView(label, new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1));
            row.addView(host.symbolIcon(R.drawable.ios_icon_chevron_right, AppColors.MUTED, Color.TRANSPARENT, 24, 4), Ui.fixed(host, 24, 24));
            row.setOnClickListener(v -> {
                if (handler != null)
                    handler.onChoice(index, holder[0]);
            });
            content.addView(row, Ui.matchWrap());
            Ui.addSpacer(host, content, 10);
        }
        holder[0] = Ui.bottomSheet(host, title, content, "", null);
        holder[0].show();
    }

    void showMessageSheet(String title, String message) {
        LinearLayout content = Ui.v(host, 0);
        content.setPadding(Ui.dp(host, 12), 0, Ui.dp(host, 12), 0);
        content.addView(Ui.muted(host, message), Ui.matchWrap());
        Ui.dialog(host, title, content, host.i18n.t("Done"), null);
    }

    void chooseProfilePhoto() {
        host.pendingPhotoCallback = dataUrl -> {
            if (!dataUrl.isEmpty()) {
                host.storage.putString(host.storage.key("profile", host.currentUser.id, "profileImageData"), dataUrl);
                host.render();
            }
        };
        Intent intent = new Intent(Intent.ACTION_GET_CONTENT);
        intent.setType("image/*");
        host.startActivityForResult(Intent.createChooser(intent, host.i18n.t("Choose Photo")), host.REQUEST_GENERIC_PHOTO_LIBRARY);
    }

    void takeProfilePhoto() {
        host.pendingPhotoCallback = dataUrl -> {
            if (!dataUrl.isEmpty()) {
                host.storage.putString(host.storage.key("profile", host.currentUser.id, "profileImageData"), dataUrl);
                host.render();
            }
        };
        try {
            Intent intent = new Intent(MediaStore.ACTION_IMAGE_CAPTURE);
            host.startActivityForResult(intent, host.REQUEST_GENERIC_PHOTO_CAMERA);
        } catch (Exception e) {
            host.pendingPhotoCallback = null;
            host.showMessageSheet(host.i18n.t("Camera is not available."), "");
        }
    }

    LinearLayout pageHeader(String title, String subtitle) {
        return host.pageHeader(title, subtitle, "");
    }

    LinearLayout pageHeader(String title, String subtitle, String iconText) {
        LinearLayout header = Ui.v(host, 0);
        if (iconText == null || iconText.isEmpty()) {
            header.addView(Ui.title(host, title), Ui.matchWrap());
        } else {
            LinearLayout row = Ui.h(host, 0);
            TextView icon = Ui.text(host, iconText, 32, AppColors.ACCENT, android.graphics.Typeface.BOLD);
            row.addView(icon, Ui.wrapWrap());
            TextView heading = Ui.title(host, title);
            LinearLayout.LayoutParams titleParams = new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1);
            titleParams.leftMargin = Ui.dp(host, 10);
            row.addView(heading, titleParams);
            header.addView(row, Ui.matchWrap());
        }
        Ui.addSpacer(host, header, 6);
        header.addView(Ui.muted(host, subtitle), Ui.matchWrap());
        return header;
    }

    View childAvatarView(int sizeDp) {
        String image = host.storage.getString(host.storage.key("profile", host.currentUser.id, "profileImageData"), "");
        if (image.isEmpty() && host.currentUser.profileImage != null) {
            image = host.currentUser.profileImage;
        }
        Bitmap bitmap = host.bitmapFromDataUrl(image);
        if (bitmap != null) {
            ImageView view = new ImageView(host);
            view.setImageBitmap(bitmap);
            view.setScaleType(ImageView.ScaleType.CENTER_CROP);
            view.setBackground(Ui.stroke(AppColors.PANEL, AppColors.PANEL, Ui.dp(host, sizeDp / 2)));
            view.setPadding(Ui.dp(host, 2), Ui.dp(host, 2), Ui.dp(host, 2), Ui.dp(host, 2));
            view.setClickable(true);
            return view;
        }
        TextView avatar = Ui.text(host, host.initials(host.childName()), 16, AppColors.PANEL, android.graphics.Typeface.BOLD);
        avatar.setGravity(Gravity.CENTER);
        avatar.setBackground(Ui.round(AppColors.ACCENT, Ui.dp(host, sizeDp / 2)));
        avatar.setClickable(true);
        return avatar;
    }

    LinearLayout roundHistoryButton() {
        LinearLayout row = Ui.h(host, 0);
        row.setGravity(Gravity.CENTER_VERTICAL);
        row.setClickable(true);
        row.setFocusable(true);
        ImageView icon = host.symbolIcon(R.drawable.ios_icon_chart_line_uptrend, AppColors.PANEL, AppColors.ACCENT, 42, 9);
        icon.setClickable(false);
        icon.setFocusable(false);
        row.addView(icon, Ui.fixed(host, 42, 42));
        Ui.addSpacerHorizontal(host, row, 8);
        row.addView(Ui.text(host, host.i18n.t("History"), 16, AppColors.ACCENT, android.graphics.Typeface.BOLD), Ui.wrapWrap());
        return row;
    }

    TextView iconCircle(String text, int textColor, int fillColor, int sizeDp) {
        TextView view = Ui.text(host, text, 22, textColor, android.graphics.Typeface.BOLD);
        view.setGravity(Gravity.CENTER);
        view.setBackground(Ui.round(fillColor, Ui.dp(host, sizeDp / 2)));
        view.setClickable(true);
        view.setFocusable(true);
        return view;
    }

    Bitmap bitmapFromDataUrl(String dataUrl) {
        if (dataUrl == null || dataUrl.trim().isEmpty()) {
            return null;
        }
        try {
            String raw = dataUrl;
            int comma = raw.indexOf(',');
            if (comma >= 0) {
                raw = raw.substring(comma + 1);
            }
            byte[] bytes = Base64.decode(raw, Base64.DEFAULT);
            return BitmapFactory.decodeByteArray(bytes, 0, bytes.length);
        } catch (Exception ignored) {
            return null;
        }
    }

    LinearLayout infoRow(String title, String value) {
        LinearLayout row = Ui.h(host, 0);
        row.setPadding(0, Ui.dp(host, 8), 0, Ui.dp(host, 8));
        row.addView(Ui.muted(host, title), new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1));
        TextView val = Ui.text(host, value == null ? "" : value, 14, AppColors.TEXT, android.graphics.Typeface.BOLD);
        val.setGravity(Gravity.END);
        row.addView(val, new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1));
        return row;
    }

    void showBasicInfoDialog() {
        LinearLayout content = Ui.v(host, 0);
        content.setPadding(Ui.dp(host, 12), 0, Ui.dp(host, 12), 0);
        EditText fullName = Ui.edit(host, host.i18n.t("Child Name"));
        EditText birthDate = Ui.edit(host, host.i18n.t("Date of Birth"));
        EditText supportNeeds = Ui.multi(host, host.i18n.t("Support Needs"));
        EditText homeSchool = Ui.multi(host, host.i18n.t("Home / School Notes"));
        EditText emergency = Ui.edit(host, host.i18n.t("Emergency Contact"));
        EditText notes = Ui.multi(host, host.i18n.t("Care Notes"));
        fullName.setText(host.storage.getString(host.storage.key("profile", host.currentUser.id, "fullName"), ""));
        birthDate.setText(host.storage.getString(host.storage.key("profile", host.currentUser.id, "birthDate"), ""));
        supportNeeds.setText(host.storage.getString(host.storage.key("profile", host.currentUser.id, "phone"), ""));
        homeSchool.setText(host.storage.getString(host.storage.key("profile", host.currentUser.id, "address"), ""));
        emergency.setText(host.storage.getString(host.storage.key("profile", host.currentUser.id, "emergencyContact"), ""));
        notes.setText(host.storage.getString(host.storage.key("profile", host.currentUser.id, "medicalNotes"), ""));
        content.addView(Ui.fieldGroup(host, host.i18n.t("Child Name"), fullName), Ui.matchWrap());
        Ui.addSpacer(host, content, 10);
        content.addView(Ui.fieldGroup(host, host.i18n.t("Date of Birth"), birthDate), Ui.matchWrap());
        Ui.addSpacer(host, content, 10);
        content.addView(Ui.fieldGroup(host, host.i18n.t("Support Needs"), supportNeeds), Ui.matchWrap());
        Ui.addSpacer(host, content, 10);
        content.addView(Ui.fieldGroup(host, host.i18n.t("Home / School Notes"), homeSchool), Ui.matchWrap());
        Ui.addSpacer(host, content, 10);
        content.addView(Ui.fieldGroup(host, host.i18n.t("Emergency Contact"), emergency), Ui.matchWrap());
        Ui.addSpacer(host, content, 10);
        content.addView(Ui.fieldGroup(host, host.i18n.t("Care Notes"), notes), Ui.matchWrap());
        Ui.dialog(host, host.i18n.t("Child Profile"), content, host.i18n.t("Save"), () -> {
            host.storage.putString(host.storage.key("profile", host.currentUser.id, "fullName"), fullName.getText().toString().trim());
            host.storage.putString(host.storage.key("profile", host.currentUser.id, "birthDate"), birthDate.getText().toString().trim());
            host.storage.putString(host.storage.key("profile", host.currentUser.id, "phone"), supportNeeds.getText().toString().trim());
            host.storage.putString(host.storage.key("profile", host.currentUser.id, "address"), homeSchool.getText().toString().trim());
            host.storage.putString(host.storage.key("profile", host.currentUser.id, "emergencyContact"), emergency.getText().toString().trim());
            host.storage.putString(host.storage.key("profile", host.currentUser.id, "medicalNotes"), notes.getText().toString().trim());
            host.syncProfile();
            host.render();
        });
    }

    void syncProfile() {
        JSONObject profile = new JSONObject();
        try {
            profile.put("fullName", host.storage.getString(host.storage.key("profile", host.currentUser.id, "fullName"), ""));
            profile.put("birthDate", host.storage.getString(host.storage.key("profile", host.currentUser.id, "birthDate"), ""));
            profile.put("supportNeeds", host.storage.getString(host.storage.key("profile", host.currentUser.id, "phone"), ""));
            profile.put("homeSchoolNotes", host.storage.getString(host.storage.key("profile", host.currentUser.id, "address"), ""));
            profile.put("emergencyContact", host.storage.getString(host.storage.key("profile", host.currentUser.id, "emergencyContact"), ""));
            profile.put("careNotes", host.storage.getString(host.storage.key("profile", host.currentUser.id, "medicalNotes"), ""));
        } catch (JSONException ignored) {
        }
        host.api.syncAppData(host.currentUser.id, profile, null, null, null);
    }

    void syncHealth(JSONArray entries) {
        host.syncProfile();
        host.api.syncAppData(host.currentUser.id, host.childProfileJson(), entries, null, null);
    }

    JSONObject childProfileJson() {
        JSONObject profile = new JSONObject();
        try {
            profile.put("fullName", host.storage.getString(host.storage.key("profile", host.currentUser.id, "fullName"), ""));
            profile.put("birthDate", host.storage.getString(host.storage.key("profile", host.currentUser.id, "birthDate"), ""));
            profile.put("supportNeeds", host.storage.getString(host.storage.key("profile", host.currentUser.id, "phone"), ""));
            profile.put("homeSchoolNotes", host.storage.getString(host.storage.key("profile", host.currentUser.id, "address"), ""));
            profile.put("emergencyContact", host.storage.getString(host.storage.key("profile", host.currentUser.id, "emergencyContact"), ""));
            profile.put("careNotes", host.storage.getString(host.storage.key("profile", host.currentUser.id, "medicalNotes"), ""));
        } catch (JSONException ignored) {
        }
        return profile;
    }

    void showLanguageDialog() {
        host.showChoiceSheet(host.i18n.t("Language"), new String[] { "English", "中文" }, (which, sheet) -> {
            sheet.dismiss();
            host.i18n.setLanguage(which == 0 ? I18n.EN : I18n.ZH);
            host.render();
        });
    }

    void showTermsDialog() {
        String text = "1. Acceptance of Terms\n\n" + "By using Care Portal, you agree to use this app responsibly for family care tracking.\n\n" + "2. Medical Disclaimer\n\n" + "Care Portal is not a medical provider and does not replace professional medical advice.\n\n" + "3. Privacy and Data\n\n" + "Keep your account secure and avoid entering information you do not have permission to store.";
        LinearLayout content = host.quickFormContent();
        TextView body = Ui.muted(host, text);
        body.setTextSize(15);
        body.setLineSpacing(Ui.dp(host, 4), 1.0f);
        content.addView(body, Ui.matchWrap());
        Ui.dialog(host, host.i18n.t("Terms of Use"), content, host.i18n.t("Done"), null);
    }
}
