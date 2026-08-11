package com.forspecialyou.careportal;

import android.app.Activity;
import android.app.DatePickerDialog;
import android.app.Dialog;
import android.app.TimePickerDialog;
import android.content.Intent;
import android.graphics.Bitmap;
import android.graphics.BitmapShader;
import android.graphics.BitmapFactory;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.Shader;
import android.graphics.drawable.Drawable;
import android.net.Uri;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.provider.MediaStore;
import android.text.Editable;
import android.text.InputType;
import android.text.TextWatcher;
import android.util.Base64;
import android.view.Gravity;
import android.view.MotionEvent;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ArrayAdapter;
import android.widget.AdapterView;
import android.widget.Button;
import android.widget.CheckBox;
import android.widget.EditText;
import android.widget.FrameLayout;
import android.widget.GridLayout;
import android.widget.HorizontalScrollView;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.SeekBar;
import android.widget.Spinner;
import android.widget.TextView;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.ByteArrayOutputStream;
import java.io.InputStream;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.Collections;
import java.util.Date;
import java.util.HashSet;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Random;
import java.util.Set;

public final class MainActivity extends Activity {
    private interface SheetChoiceHandler {
        void onChoice(int index, Dialog sheet);
    }

    private static final int REQUEST_MEAL_PHOTO = 101;
    private static final int REQUEST_MEAL_CAMERA = 102;
    private static final int REQUEST_GENERIC_PHOTO_LIBRARY = 103;
    private static final int REQUEST_GENERIC_PHOTO_CAMERA = 104;

    private static final String[][] DIAGNOSIS_OPTIONS = {
            {"genetics", "Genetics"},
            {"pediatricHealthClinic", "Pediatric Health Clinic (Early Screening)"},
            {"developmentalBehavioral", "Developmental-Behavioral Pediatrics"},
            {"childPsychiatryPsychology", "Child Psychiatry/Psychology"},
            {"neurology", "Neurology"},
            {"rehabilitationInterventions", "Rehabilitation / Interventions"},
            {"gastroenterology", "Gastroenterology"},
            {"oralRelated", "Oral Related (Stomatology)"},
            {"dermatology", "Dermatology"},
            {"orthopedics", "Orthopedics"},
            {"stomatology", "Otolaryngology (ENT)"},
            {"neurosurgery", "Neurosurgery"},
            {"ophthalmology", "Ophthalmology"},
            {"traditionalChineseMedicine", "Traditional Chinese Medicine"},
            {"nutrition", "Nutrition"},
            {"autismSpecialist", "Autism Specialist"},
            {"other", "Other"}
    };

    private static final String[][] QUICK_LOGS = {
            {"seizure", "Seizure Track"},
            {"meltdown", "Meltdown"},
            {"stimming", "Stimming/Tics"},
            {"accident", "Accident"},
            {"deescalation", "De-escalation"},
            {"allergy", "Allergic Reaction"},
            {"pain", "Pain"},
            {"skin", "Skin"},
            {"cyclicVomiting", "Cyclic Vomiting"},
            {"discomfort", "Discomfort"},
            {"medsFood", "Medicine"}
    };

    private static final String[][] SNAPSHOTS = {
            {"sleep", "Sleep / Rest"},
            {"digestion", "Digestion"},
            {"nutrition", "Nutrition"},
            {"mood", "Mood"},
            {"height", "Height"},
            {"weight", "Weight"}
    };

    private static final String[][] THERAPY_CATEGORIES = {
            {"therapySession", "Therapy Session", "Appointments, exercises, notes"},
            {"physical", "Physical", "Balance, strength, stairs, movement"},
            {"occupational", "Occupational", "Fine motor, sensory, dressing, daily skills"},
            {"speech", "Speech", "Words, AAC, requests, social communication"},
            {"behavioral", "Behavioral/RDI", "Transitions, regulation, coping, routines"},
            {"social", "Social", "Play, turn-taking, peer interaction"},
            {"feeding", "Feeding", "Textures, chewing, new foods, hydration"}
    };

    private Storage storage;
    private I18n i18n;
    private AuthApi api;
    private CarePortalUser currentUser;
    private String authScreen = "home";
    private String message = "";
    private boolean isError = false;
    private boolean isLoading = false;
    private int selectedTab = 0;
    private int failedLoginAttempts = 0;
    private boolean captchaRequired = false;
    private String captchaCode = makeCaptchaCode();
    private String captchaInput = "";
    private String loginNickname = "";
    private String signupNickname = "";
    private String selectedMealPhotoDataUrl = "";
    private PhotoCallback pendingPhotoCallback;
    private JSONObject currentMealEstimate;
    private boolean hasSavedCurrentMeal = false;
    private String healthHistoryType = "";
    private String healthHistoryCategoryId = "";
    private String healthHistoryCategoryTitle = "";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        storage = new Storage(this);
        i18n = new I18n(storage);
        api = new AuthApi(i18n);
        currentUser = storage.getSavedUser();
        render();
        validateSavedSession();
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode == REQUEST_MEAL_PHOTO && resultCode == RESULT_OK && data != null && data.getData() != null) {
            selectedMealPhotoDataUrl = loadImageDataUrl(data.getData());
            currentMealEstimate = null;
            hasSavedCurrentMeal = false;
            message = selectedMealPhotoDataUrl.isEmpty() ? i18n.t("Unable to reach the server.") : "";
            isError = !message.isEmpty();
            render();
        } else if (requestCode == REQUEST_MEAL_CAMERA && resultCode == RESULT_OK) {
            selectedMealPhotoDataUrl = imageDataUrlFromCameraResult(data);
            currentMealEstimate = null;
            hasSavedCurrentMeal = false;
            message = selectedMealPhotoDataUrl.isEmpty() ? i18n.t("Unable to reach the server.") : "";
            isError = !message.isEmpty();
            render();
        } else if (requestCode == REQUEST_GENERIC_PHOTO_LIBRARY && resultCode == RESULT_OK && data != null && data.getData() != null) {
            finishPendingPhoto(loadImageDataUrl(data.getData()));
        } else if (requestCode == REQUEST_GENERIC_PHOTO_CAMERA && resultCode == RESULT_OK) {
            finishPendingPhoto(imageDataUrlFromCameraResult(data));
        }
    }

    private void render() {
        if (currentUser == null) {
            renderAuth();
        } else {
            renderApp();
        }
    }

    private void renderAuth() {
        LinearLayout screen = Ui.screen(this);
        LinearLayout panel = Ui.panel(this);
        screen.addView(panel, Ui.matchWrap());

        if ("login".equals(authScreen)) {
            renderLogin(panel);
        } else if ("signup".equals(authScreen)) {
            renderSignup(panel);
        } else {
            renderHome(panel);
        }

        setContentView(Ui.scroll(this, screen));
    }

    private void renderHome(LinearLayout panel) {
        LinearLayout top = Ui.h(this, 0);
        TextView spacer = new TextView(this);
        top.addView(spacer, new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1));
        Button language = Ui.secondary(this, i18n.languageDisplayName());
        language.setOnClickListener(v -> showLanguageDialog());
        top.addView(language, Ui.wrapWrap());
        panel.addView(top, Ui.matchWrap());
        Ui.addSpacer(this, panel, 18);

        ImageView logo = new ImageView(this);
        logo.setImageResource(R.drawable.care_portal_logo);
        logo.setAdjustViewBounds(true);
        logo.setScaleType(ImageView.ScaleType.FIT_CENTER);
        LinearLayout.LayoutParams logoParams = Ui.fixed(this, 120, 120);
        logoParams.gravity = Gravity.CENTER_HORIZONTAL;
        panel.addView(logo, logoParams);
        Ui.addSpacer(this, panel, 16);

        TextView brand = Ui.title(this, i18n.t("Care Portal"));
        brand.setGravity(Gravity.CENTER);
        panel.addView(brand, Ui.matchWrap());
        Ui.addSpacer(this, panel, 20);

        TextView offer = Ui.text(this, i18n.t("For Special You"), 24, AppColors.TEXT, android.graphics.Typeface.BOLD);
        offer.setGravity(Gravity.CENTER);
        panel.addView(offer, Ui.matchWrap());
        Ui.addSpacer(this, panel, 8);

        TextView intro = Ui.muted(this, i18n.t("A parent-run care space for tracking your child's health, routines, and support needs."));
        intro.setGravity(Gravity.CENTER);
        panel.addView(intro, Ui.matchWrap());
        Ui.addSpacer(this, panel, 22);

        Button login = Ui.primary(this, i18n.t("Log In"));
        login.setOnClickListener(v -> {
            authScreen = "login";
            clearMessage();
            render();
        });
        panel.addView(login, Ui.matchWrap());
        Ui.addSpacer(this, panel, 12);

        Button signup = Ui.secondary(this, i18n.t("Create Parent Account"));
        signup.setOnClickListener(v -> {
            authScreen = "signup";
            clearMessage();
            render();
        });
        panel.addView(signup, Ui.matchWrap());
    }

    private void renderLogin(LinearLayout panel) {
        Button home = Ui.secondary(this, "< " + i18n.t("Home"));
        home.setOnClickListener(v -> {
            authScreen = "home";
            clearMessage();
            render();
        });
        panel.addView(home, Ui.wrapWrap());
        Ui.addSpacer(this, panel, 16);
        panel.addView(Ui.sectionTitle(this, i18n.t("Welcome Back")), Ui.matchWrap());
        Ui.addSpacer(this, panel, 16);

        EditText username = Ui.edit(this, i18n.t("Parent Username"));
        username.setText(loginNickname);
        panel.addView(Ui.fieldGroup(this, i18n.t("Parent Username"), username), Ui.matchWrap());
        Ui.addSpacer(this, panel, 14);

        EditText password = Ui.password(this, i18n.t("Password"));
        password.setEnabled(!captchaRequired);
        panel.addView(Ui.fieldGroup(this, i18n.t("Password"), password), Ui.matchWrap());
        Ui.addSpacer(this, panel, 14);

        EditText captcha = null;
        if (captchaRequired) {
            LinearLayout challenge = Ui.panel(this);
            challenge.setBackground(Ui.round(Ui.withAlpha(AppColors.ACCENT, 20), Ui.dp(this, 12)));
            LinearLayout row = Ui.h(this, 0);
            TextView code = Ui.text(this, captchaCode, 18, AppColors.TEXT, android.graphics.Typeface.BOLD);
            code.setGravity(Gravity.CENTER);
            code.setLetterSpacing(0.12f);
            code.setBackground(Ui.stroke(AppColors.FIELD, Ui.withAlpha(AppColors.ACCENT, 60), Ui.dp(this, 9)));
            row.addView(code, Ui.fixed(this, 98, 40));
            EditText captchaEdit = Ui.edit(this, "Code");
            captchaEdit.setInputType(InputType.TYPE_CLASS_TEXT | InputType.TYPE_TEXT_FLAG_CAP_CHARACTERS);
            LinearLayout.LayoutParams capParams = new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1);
            capParams.leftMargin = Ui.dp(this, 10);
            row.addView(captchaEdit, capParams);
            Button refresh = Ui.secondary(this, "Refresh");
            refresh.setOnClickListener(v -> {
                captchaCode = makeCaptchaCode();
                captchaInput = "";
                render();
            });
            LinearLayout.LayoutParams refreshParams = Ui.wrapWrap();
            refreshParams.leftMargin = Ui.dp(this, 8);
            row.addView(refresh, refreshParams);
            challenge.addView(row, Ui.matchWrap());
            panel.addView(challenge, Ui.matchWrap());
            Ui.addSpacer(this, panel, 14);
            captcha = captchaEdit;
        }

        addMessage(panel);

        CheckBox terms = Ui.check(this, i18n.t("I agree to the Terms and Conditions before using this app."));
        terms.setOnLongClickListener(v -> {
            showTermsDialog();
            return true;
        });
        terms.setOnClickListener(v -> {
            if (!terms.isChecked()) {
                return;
            }
        });
        terms.setOnCheckedChangeListener((buttonView, isChecked) -> {
            if (isChecked) {
                showTermsDialog();
            }
        });
        panel.addView(terms, Ui.matchWrap());
        Ui.addSpacer(this, panel, 14);

        Button submit = Ui.primary(this, isLoading ? i18n.t("Logging In...") : (captchaRequired ? i18n.t("Verify Code") : i18n.t("Log In")));
        EditText finalCaptcha = captcha;
        submit.setOnClickListener(v -> {
            if (!terms.isChecked()) {
                showError(i18n.t("I agree to the Terms and Conditions before using this app."));
                render();
                return;
            }
            loginNickname = username.getText().toString();
            if (captchaRequired) {
                captchaInput = finalCaptcha == null ? "" : finalCaptcha.getText().toString();
                completeCaptchaChallenge();
            } else {
                login(loginNickname, password.getText().toString());
            }
        });
        panel.addView(submit, Ui.matchWrap());
        Ui.addSpacer(this, panel, 10);

        Button signup = Ui.secondary(this, i18n.t("Need an account? Sign up"));
        signup.setOnClickListener(v -> {
            authScreen = "signup";
            clearMessage();
            render();
        });
        panel.addView(signup, Ui.matchWrap());
    }

    private void renderSignup(LinearLayout panel) {
        Button home = Ui.secondary(this, "< " + i18n.t("Home"));
        home.setOnClickListener(v -> {
            authScreen = "home";
            clearMessage();
            render();
        });
        panel.addView(home, Ui.wrapWrap());
        Ui.addSpacer(this, panel, 16);

        panel.addView(Ui.sectionTitle(this, i18n.t("Create Parent Account")), Ui.matchWrap());
        Ui.addSpacer(this, panel, 4);
        panel.addView(Ui.muted(this, i18n.t("Set up a parent login to track your child's care.")), Ui.matchWrap());
        Ui.addSpacer(this, panel, 16);

        EditText nickname = Ui.edit(this, i18n.t("Parent Username"));
        nickname.setText(signupNickname);
        EditText email = Ui.edit(this, i18n.t("Email"));
        email.setInputType(InputType.TYPE_CLASS_TEXT | InputType.TYPE_TEXT_VARIATION_EMAIL_ADDRESS);
        EditText password = Ui.password(this, i18n.t("Password"));
        EditText verify = Ui.password(this, i18n.t("Verify Password"));

        panel.addView(Ui.fieldGroup(this, i18n.t("Parent Username"), nickname), Ui.matchWrap());
        Ui.addSpacer(this, panel, 14);
        panel.addView(Ui.fieldGroup(this, i18n.t("Email"), email), Ui.matchWrap());
        Ui.addSpacer(this, panel, 14);
        panel.addView(Ui.fieldGroup(this, i18n.t("Password"), password), Ui.matchWrap());
        Ui.addSpacer(this, panel, 14);
        panel.addView(Ui.fieldGroup(this, i18n.t("Verify Password"), verify), Ui.matchWrap());
        Ui.addSpacer(this, panel, 14);

        addMessage(panel);

        CheckBox terms = Ui.check(this, i18n.t("I agree to the Terms and Conditions before using this app."));
        terms.setOnCheckedChangeListener((buttonView, isChecked) -> {
            if (isChecked) {
                showTermsDialog();
            }
        });
        panel.addView(terms, Ui.matchWrap());
        Ui.addSpacer(this, panel, 14);

        Button submit = Ui.primary(this, isLoading ? i18n.t("Creating Account...") : i18n.t("Create Parent Account"));
        submit.setOnClickListener(v -> {
            if (!terms.isChecked()) {
                showError(i18n.t("I agree to the Terms and Conditions before using this app."));
                render();
                return;
            }
            signupNickname = nickname.getText().toString();
            signup(signupNickname, email.getText().toString(), password.getText().toString(), verify.getText().toString());
        });
        panel.addView(submit, Ui.matchWrap());
        Ui.addSpacer(this, panel, 10);

        Button login = Ui.secondary(this, i18n.t("Already have an account? Log in"));
        login.setOnClickListener(v -> {
            authScreen = "login";
            clearMessage();
            render();
        });
        panel.addView(login, Ui.matchWrap());
    }

    private void renderApp() {
        LinearLayout shell = new LinearLayout(this);
        shell.setOrientation(LinearLayout.VERTICAL);
        shell.setBackgroundColor(AppColors.BACKGROUND);

        FrameLayout content = new FrameLayout(this);
        shell.addView(content, new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, 0, 1));
        content.addView(tabContent(), Ui.frameMatch());
        if (!isHealthHistoryPage()) {
            shell.addView(bottomNav(), new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, Ui.dp(this, 108)));
        }
        setContentView(shell);
    }

    private View tabContent() {
        if (selectedTab == 0) {
            return diagnosisView();
        } else if (selectedTab == 1) {
            if (isHealthHistoryPage()) {
                return healthHistoryPage();
            }
            return healthView();
        } else if (selectedTab == 2) {
            return therapyView();
        } else if (selectedTab == 3) {
            return nutrientView();
        }
        return profileView();
    }

    private View bottomNav() {
        FrameLayout holder = new FrameLayout(this);
        holder.setPadding(0, Ui.dp(this, 2), 0, Ui.dp(this, 14));
        holder.setBackgroundColor(Color.TRANSPARENT);
        holder.setClipToPadding(false);

        LinearLayout nav = Ui.h(this, 0);
        nav.setGravity(Gravity.CENTER);
        nav.setPadding(Ui.dp(this, 8), Ui.dp(this, 8), Ui.dp(this, 8), Ui.dp(this, 8));
        nav.setBackground(Ui.round(AppColors.PANEL, Ui.dp(this, 44)));
        nav.setElevation(Ui.dp(this, 10));
        nav.setClipToOutline(false);
        String[] labels = {i18n.t("Diagnosis"), i18n.t("Health"), i18n.t("Therapy"), i18n.t("Nutrient"), i18n.t("Profile")};
        int[] icons = {
                R.drawable.ios_tab_diagnosis,
                R.drawable.ios_tab_health,
                R.drawable.ios_therapy_session,
                R.drawable.ios_icon_leaf,
                R.drawable.ios_tab_profile
        };
        int navDark = Color.rgb(5, 8, 7);
        for (int i = 0; i < labels.length; i++) {
            final int index = i;
            boolean selected = index == selectedTab;
            int color = selected ? AppColors.ACCENT : navDark;
            LinearLayout item = Ui.v(this, 3);
            item.setGravity(Gravity.CENTER);
            item.setPadding(Ui.dp(this, 1), Ui.dp(this, 7), Ui.dp(this, 1), Ui.dp(this, 7));
            item.setMinimumHeight(Ui.dp(this, 68));
            item.setBackground(Ui.round(selected ? Ui.withAlpha(AppColors.ACCENT, 20) : Color.TRANSPARENT, Ui.dp(this, 34)));
            ImageView icon = symbolIcon(icons[i], color, Color.TRANSPARENT, 40, 1);
            item.addView(icon, Ui.fixed(this, 40, 40));
            TextView label = Ui.text(this, labels[i], 14, color, android.graphics.Typeface.BOLD);
            label.setGravity(Gravity.CENTER);
            label.setIncludeFontPadding(false);
            item.addView(label, Ui.matchWrap());
            item.setOnClickListener(v -> {
                selectedTab = index;
                clearHealthHistoryPage();
                clearMessage();
                render();
            });
            LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.MATCH_PARENT, 1);
            params.setMargins(Ui.dp(this, 1), 0, Ui.dp(this, 1), 0);
            nav.addView(item, params);
        }
        FrameLayout.LayoutParams navParams = new FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, Ui.dp(this, 86), Gravity.BOTTOM | Gravity.CENTER_HORIZONTAL);
        navParams.setMargins(Ui.dp(this, 20), 0, Ui.dp(this, 20), Ui.dp(this, 8));
        holder.addView(nav, navParams);
        return holder;
    }

    private View diagnosisView() {
        LinearLayout screen = Ui.screen(this);
        LinearLayout header = Ui.h(this, 0);
        ImageView diagnosisIcon = symbolIcon(R.drawable.ios_tab_diagnosis, AppColors.ACCENT, Color.TRANSPARENT, 42, 0);
        header.addView(diagnosisIcon, Ui.fixed(this, 42, 42));
        TextView diagnosisTitle = Ui.title(this, i18n.t("Diagnosis"));
        diagnosisTitle.setTextSize(34);
        LinearLayout.LayoutParams diagnosisTitleParams = new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1);
        diagnosisTitleParams.leftMargin = Ui.dp(this, 10);
        header.addView(diagnosisTitle, diagnosisTitleParams);
        TextView edit = Ui.text(this, i18n.t("Edit"), 16, AppColors.ACCENT, android.graphics.Typeface.BOLD);
        edit.setGravity(Gravity.CENTER);
        edit.setPadding(Ui.dp(this, 22), Ui.dp(this, 13), Ui.dp(this, 22), Ui.dp(this, 13));
        edit.setBackground(Ui.round(Ui.withAlpha(AppColors.ACCENT, 22), Ui.dp(this, 28)));
        edit.setClickable(true);
        edit.setFocusable(true);
        edit.setOnClickListener(v -> showDiagnosisCategoryDialog());
        header.addView(edit, Ui.wrapWrap());
        screen.addView(header, Ui.matchWrap());
        Ui.addSpacer(this, screen, 24);

        LinearLayout titleRow = Ui.h(this, 0);
        titleRow.setGravity(Gravity.CENTER_VERTICAL);
        TextView conditionsTitle = Ui.sectionTitle(this, i18n.t("Conditions"));
        conditionsTitle.setTextSize(24);
        titleRow.addView(conditionsTitle, new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1));
        TextView add = Ui.text(this, "+", 27, AppColors.ACCENT, android.graphics.Typeface.BOLD);
        add.setGravity(Gravity.CENTER);
        add.setBackground(Ui.round(Ui.withAlpha(AppColors.ACCENT, 22), Ui.dp(this, 23)));
        add.setClickable(true);
        add.setFocusable(true);
        add.setOnClickListener(v -> showConditionDialog(null, -1));
        titleRow.addView(add, Ui.fixed(this, 46, 46));
        screen.addView(titleRow, Ui.matchWrap());
        Ui.addSpacer(this, screen, 12);

        JSONArray conditions = storage.getArray(storage.key("diagnosis", currentUser.id, "conditions"));
        if (conditions.length() == 0) {
            screen.addView(Ui.muted(this, i18n.t("No conditions added yet.")), Ui.matchWrap());
        } else {
            for (int i = 0; i < conditions.length(); i++) {
                JSONObject item = conditions.optJSONObject(i);
                if (item == null) continue;
                final int index = i;
                View row = diagnosisConditionSwipeRow(item, index);
                screen.addView(row, Ui.matchWrap());
                Ui.addSpacer(this, screen, 10);
            }
        }
        Ui.addSpacer(this, screen, 12);
        LinearLayout visit = diagnosisDoctorVisitButton();
        visit.setOnClickListener(v -> showDoctorVisitDialog());
        screen.addView(visit, Ui.matchWrap());
        Ui.addSpacer(this, screen, 16);

        addSelectedDiagnosis(screen);
        return Ui.scroll(this, screen);
    }

    private FrameLayout diagnosisConditionSwipeRow(JSONObject item, int index) {
        FrameLayout container = new FrameLayout(this);
        container.setMinimumHeight(Ui.dp(this, 82));

        int actionButtonWidth = Ui.dp(this, 82);
        int actionGap = Ui.dp(this, 8);
        int actionWidth = actionButtonWidth * 2 + actionGap;

        LinearLayout actions = Ui.h(this, 0);
        actions.setGravity(Gravity.RIGHT | Gravity.CENTER_VERTICAL);
        actions.addView(conditionSwipeAction(i18n.t("Edit"), R.drawable.ic_swipe_edit, AppColors.ACCENT, () -> showConditionDialog(item, index)),
                Ui.fixed(this, 82, 82));
        Ui.addSpacerHorizontal(this, actions, 8);
        actions.addView(conditionSwipeAction(i18n.t("Delete"), R.drawable.ic_swipe_delete, Color.rgb(255, 55, 64), () -> deleteCondition(index)),
                Ui.fixed(this, 82, 82));
        FrameLayout.LayoutParams actionParams = new FrameLayout.LayoutParams(actionWidth, Ui.dp(this, 82), Gravity.RIGHT | Gravity.CENTER_VERTICAL);
        container.addView(actions, actionParams);

        LinearLayout card = diagnosisConditionCard(item);
        card.setOnClickListener(v -> showConditionDialog(item, index));
        FrameLayout.LayoutParams cardParams = new FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        container.addView(card, cardParams);
        enableSwipeReveal(card, actionWidth);
        return container;
    }

    private LinearLayout conditionSwipeAction(String title, int iconRes, int color, Runnable action) {
        LinearLayout button = Ui.v(this, 0);
        button.setGravity(Gravity.CENTER);
        button.setPadding(Ui.dp(this, 8), Ui.dp(this, 9), Ui.dp(this, 8), Ui.dp(this, 9));
        button.setBackground(Ui.round(color, Ui.dp(this, 18)));
        button.setClickable(true);
        button.setFocusable(true);
        ImageView iconView = new ImageView(this);
        iconView.setImageResource(iconRes);
        iconView.setColorFilter(Color.WHITE);
        iconView.setAdjustViewBounds(true);
        button.addView(iconView, Ui.fixed(this, 28, 28));
        Ui.addSpacer(this, button, 4);
        TextView titleText = Ui.text(this, title, 15, Color.WHITE, android.graphics.Typeface.BOLD);
        titleText.setGravity(Gravity.CENTER);
        button.addView(titleText, Ui.matchWrap());
        button.setOnClickListener(v -> action.run());
        return button;
    }

    private void enableSwipeReveal(View card, int actionWidth) {
        final float[] downX = {0f};
        final float[] downY = {0f};
        final float[] startTranslation = {0f};
        final boolean[] swiping = {false};

        card.setOnTouchListener((v, event) -> {
            switch (event.getActionMasked()) {
                case MotionEvent.ACTION_DOWN:
                    downX[0] = event.getRawX();
                    downY[0] = event.getRawY();
                    startTranslation[0] = v.getTranslationX();
                    swiping[0] = false;
                    disallowParentIntercept(v, false);
                    return true;
                case MotionEvent.ACTION_MOVE:
                    float dx = event.getRawX() - downX[0];
                    float dy = event.getRawY() - downY[0];
                    if (!swiping[0] && Math.abs(dy) > Math.abs(dx) && Math.abs(dy) > Ui.dp(this, 8)) {
                        disallowParentIntercept(v, false);
                        return false;
                    }
                    if (Math.abs(dx) > Ui.dp(this, 6)) {
                        swiping[0] = true;
                        disallowParentIntercept(v, true);
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
                    disallowParentIntercept(v, false);
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

    private void deleteCondition(int index) {
        JSONArray conditions = storage.getArray(storage.key("diagnosis", currentUser.id, "conditions"));
        if (index >= 0 && index < conditions.length()) {
            conditions.remove(index);
            storage.putArray(storage.key("diagnosis", currentUser.id, "conditions"), conditions);
            render();
        }
    }

    private void addSelectedDiagnosis(LinearLayout screen) {
        String selected = storage.getString(storage.key("diagnosis", currentUser.id, "selectedOptions"), "");
        if (selected.trim().isEmpty()) {
            return;
        }
        Set<String> ids = commaSet(selected);
        for (String[] option : DIAGNOSIS_OPTIONS) {
            if (ids.contains(option[0])) {
                screen.addView(diagnosisCategoryCard(option), Ui.matchWrap());
                Ui.addSpacer(this, screen, 10);
            }
        }
        Ui.addSpacer(this, screen, 16);
    }

    private LinearLayout diagnosisConditionCard(JSONObject item) {
        LinearLayout card = Ui.v(this, 0);
        card.setPadding(Ui.dp(this, 22), Ui.dp(this, 18), Ui.dp(this, 22), Ui.dp(this, 18));
        card.setMinimumHeight(Ui.dp(this, 82));
        card.setGravity(Gravity.CENTER_VERTICAL);
        card.setBackground(Ui.round(AppColors.PANEL, Ui.dp(this, 16)));
        card.setClickable(true);
        card.setFocusable(true);

        String category = conditionCategoryNames(item);
        if (!category.isEmpty()) {
            TextView categoryText = Ui.text(this, category, 13, AppColors.MUTED, android.graphics.Typeface.BOLD);
            categoryText.setAllCaps(true);
            card.addView(categoryText, Ui.matchWrap());
            Ui.addSpacer(this, card, 6);
        }

        TextView name = Ui.text(this, item.optString("name", "--"), 19, AppColors.TEXT, android.graphics.Typeface.BOLD);
        card.addView(name, Ui.matchWrap());
        return card;
    }

    private String conditionCategoryNames(JSONObject item) {
        Set<String> ids = conditionCategoryIds(item);
        if (ids.isEmpty()) return "";
        List<String> labels = new ArrayList<>();
        for (String[] option : DIAGNOSIS_OPTIONS) {
            if (ids.contains(option[0])) labels.add(i18n.t(option[1]));
        }
        StringBuilder builder = new StringBuilder();
        for (String label : labels) {
            if (builder.length() > 0) builder.append(", ");
            builder.append(label);
        }
        return builder.toString();
    }

    private LinearLayout diagnosisDoctorVisitButton() {
        int blue = Color.rgb(51, 132, 216);
        LinearLayout row = Ui.h(this, 0);
        row.setGravity(Gravity.CENTER);
        row.setPadding(Ui.dp(this, 18), Ui.dp(this, 16), Ui.dp(this, 18), Ui.dp(this, 16));
        row.setBackground(Ui.round(Color.rgb(214, 231, 242), Ui.dp(this, 14)));
        row.setClickable(true);
        row.setFocusable(true);
        row.addView(Ui.text(this, "+", 22, blue, android.graphics.Typeface.BOLD), Ui.wrapWrap());
        Ui.addSpacerHorizontal(this, row, 8);
        row.addView(symbolIcon(R.drawable.ios_tab_diagnosis, blue, Color.TRANSPARENT, 26, 2), Ui.fixed(this, 28, 28));
        Ui.addSpacerHorizontal(this, row, 8);
        row.addView(Ui.text(this, i18n.t("Doctor Visit"), 18, blue, android.graphics.Typeface.BOLD), Ui.wrapWrap());
        return row;
    }

    private LinearLayout diagnosisCategoryCard(String[] option) {
        int color = diagnosisColor(option[0]);
        LinearLayout row = Ui.h(this, 0);
        row.setPadding(Ui.dp(this, 14), Ui.dp(this, 14), Ui.dp(this, 14), Ui.dp(this, 14));
        row.setBackground(Ui.stroke(AppColors.PANEL, Ui.withAlpha(color, 70), Ui.dp(this, 14)));
        TextView icon = Ui.text(this, diagnosisIcon(option[0]), 24, color, android.graphics.Typeface.BOLD);
        icon.setGravity(Gravity.CENTER);
        icon.setBackground(Ui.round(Ui.withAlpha(color, 30), Ui.dp(this, 24)));
        row.addView(icon, Ui.fixed(this, 48, 48));
        TextView label = Ui.text(this, i18n.t(option[1]), 17, AppColors.TEXT, android.graphics.Typeface.BOLD);
        LinearLayout.LayoutParams labelParams = new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1);
        labelParams.leftMargin = Ui.dp(this, 12);
        row.addView(label, labelParams);
        row.addView(Ui.text(this, "›", 28, AppColors.MUTED, android.graphics.Typeface.BOLD), Ui.wrapWrap());
        return row;
    }

    private String diagnosisIcon(String id) {
        switch (id) {
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

    private int diagnosisColor(String id) {
        switch (id) {
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

    private void addDoctorVisits(LinearLayout screen) {
        JSONArray visits = storage.getArray(storage.key("diagnosis", currentUser.id, "doctorVisits"));
        LinearLayout panel = Ui.panel(this);
        panel.addView(Ui.sectionTitle(this, i18n.t("Doctor Visit")), Ui.matchWrap());
        Ui.addSpacer(this, panel, 10);
        if (visits.length() == 0) {
            panel.addView(Ui.muted(this, i18n.t("No records yet.")), Ui.matchWrap());
        } else {
            for (int i = 0; i < visits.length(); i++) {
                JSONObject visit = visits.optJSONObject(i);
                if (visit == null) continue;
                panel.addView(Ui.cardRow(this, visit.optString("clinic"), visit.optString("date") + "  " + visit.optString("notes"), "MD"), Ui.matchWrap());
                Ui.addSpacer(this, panel, 8);
            }
        }
        screen.addView(panel, Ui.matchWrap());
    }

    private View healthView() {
        LinearLayout screen = Ui.screen(this);
        LinearLayout header = Ui.h(this, 0);
        header.setPadding(Ui.dp(this, 14), Ui.dp(this, 12), Ui.dp(this, 14), Ui.dp(this, 12));
        header.setBackground(Ui.round(Color.rgb(209, 244, 241), Ui.dp(this, 18)));
        View avatar = childAvatarView(52);
        avatar.setOnClickListener(v -> {
            selectedTab = 4;
            render();
        });
        header.addView(avatar, Ui.fixed(this, 52, 52));
        LinearLayout childTexts = Ui.v(this, 0);
        childTexts.addView(Ui.text(this, String.format(Locale.US, i18n.t("%s's Day"), childName()), 21, AppColors.TEXT, android.graphics.Typeface.BOLD), Ui.matchWrap());
        childTexts.addView(Ui.text(this, String.format(Locale.US, i18n.t("Monitored by %s"), currentUser.nickname), 14, AppColors.MUTED, android.graphics.Typeface.BOLD), Ui.matchWrap());
        LinearLayout.LayoutParams childParams = new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1);
        childParams.leftMargin = Ui.dp(this, 12);
        header.addView(childTexts, childParams);
        TextView bell = Ui.text(this, "🔔", 26, AppColors.TEXT, android.graphics.Typeface.BOLD);
        bell.setGravity(Gravity.CENTER);
        bell.setOnClickListener(v -> showNotificationsToday());
        header.addView(bell, Ui.fixed(this, 42, 42));
        screen.addView(header, Ui.matchWrap());
        Ui.addSpacer(this, screen, 16);

        LinearLayout quickHeader = Ui.h(this, 0);
        quickHeader.addView(Ui.sectionTitle(this, i18n.t("Quick-log buttons")), Ui.wrapWrap());
        Ui.addSpacerHorizontal(this, quickHeader, 8);
        LinearLayout quickHistory = roundHistoryButton();
        quickHistory.setOnClickListener(v -> showHealthHistory("quickLog"));
        quickHeader.addView(quickHistory, Ui.wrapWrap());
        quickHeader.addView(new View(this), new LinearLayout.LayoutParams(0, 1, 1));
        TextView choose = iconCircle("≛", AppColors.ACCENT, Color.WHITE, 54);
        choose.setOnClickListener(v -> showQuickLogPicker());
        quickHeader.addView(choose, Ui.fixed(this, 54, 54));
        screen.addView(quickHeader, Ui.matchWrap());
        Ui.addSpacer(this, screen, 14);

        String selected = storage.getString(storage.key("health", currentUser.id, "quickLogSelection"), "");
        if (selected.isEmpty()) {
            LinearLayout empty = Ui.h(this, 0);
            empty.setGravity(Gravity.CENTER);
            empty.setPadding(Ui.dp(this, 14), Ui.dp(this, 12), Ui.dp(this, 14), Ui.dp(this, 12));
            empty.setBackground(Ui.round(Ui.withAlpha(AppColors.ACCENT, 24), Ui.dp(this, 12)));
            TextView emptyIcon = Ui.text(this, "☷", 18, AppColors.ACCENT, android.graphics.Typeface.BOLD);
            empty.addView(emptyIcon, Ui.wrapWrap());
            TextView emptyText = Ui.text(this, "  " + i18n.t("Choose quick-log buttons"), 16, AppColors.ACCENT, android.graphics.Typeface.BOLD);
            empty.addView(emptyText, Ui.wrapWrap());
            empty.setOnClickListener(v -> showQuickLogPicker());
            screen.addView(empty, Ui.matchWrap());
        } else {
            GridLayout grid = Ui.grid(this, 3);
            for (String[] option : orderedQuickLogs(selected)) {
                View chip = quickLogCard(option[0], option[1]);
                chip.setOnClickListener(v -> showHealthLogDialog(option[0], option[1], "quickLog"));
                enableQuickLogDrag(chip, option[0]);
                Ui.addGridChildFixedHeight(this, grid, chip, 116);
            }
            screen.addView(grid, Ui.matchWrap());
        }
        Ui.addSpacer(this, screen, 26);

        LinearLayout snapshotHeader = Ui.h(this, 0);
        snapshotHeader.addView(Ui.sectionTitle(this, i18n.t("Daily Snapshot")), Ui.wrapWrap());
        Ui.addSpacerHorizontal(this, snapshotHeader, 8);
        LinearLayout snapshotHistory = roundHistoryButton();
        snapshotHistory.setOnClickListener(v -> showHealthHistory("snapshot"));
        snapshotHeader.addView(snapshotHistory, Ui.wrapWrap());
        screen.addView(snapshotHeader, Ui.matchWrap());
        Ui.addSpacer(this, screen, 14);
        GridLayout snapshotGrid = Ui.grid(this, 2);
        for (String[] option : SNAPSHOTS) {
            if ("height".equals(option[0]) || "weight".equals(option[0])) {
                continue;
            }
            View button = snapshotCard(option[0], option[1], false);
            button.setOnClickListener(v -> showHealthLogDialog(option[0], option[1], "snapshot"));
            Ui.addGridChild(this, snapshotGrid, button, 2);
        }
        screen.addView(snapshotGrid, Ui.matchWrap());
        Ui.addSpacer(this, screen, 8);
        LinearLayout measurements = Ui.h(this, 0);
        for (String[] option : SNAPSHOTS) {
            if (!"height".equals(option[0]) && !"weight".equals(option[0])) {
                continue;
            }
            View button = snapshotCard(option[0], option[1], true);
            button.setOnClickListener(v -> showHealthLogDialog(option[0], option[1], "snapshot"));
            LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1);
            params.setMargins(Ui.dp(this, 5), Ui.dp(this, 4), Ui.dp(this, 5), Ui.dp(this, 4));
            measurements.addView(button, params);
        }
        screen.addView(measurements, Ui.matchWrap());
        Ui.addSpacer(this, screen, 16);

        LinearLayout insights = Ui.panel(this);
        insights.addView(Ui.sectionTitle(this, i18n.t("Insights & Alerts")), Ui.matchWrap());
        Ui.addSpacer(this, insights, 8);
        JSONArray logs = storage.getArray(storage.key("health", currentUser.id, "logData"));
        if (logs.length() == 0) {
            insights.addView(Ui.muted(this, i18n.t("No records yet.")), Ui.matchWrap());
        } else {
            insights.addView(Ui.muted(this, logs.length() + " local health records saved."), Ui.matchWrap());
            Button refresh = Ui.secondary(this, i18n.t("Refresh insights"));
            refresh.setOnClickListener(v -> loadHealthInsights());
            insights.addView(refresh, Ui.matchWrap());
        }
        screen.addView(insights, Ui.matchWrap());
        return Ui.scroll(this, screen);
    }

    private View quickLogCard(String id, String title) {
        int color = quickLogColor(id);
        LinearLayout card = Ui.v(this, 0);
        card.setGravity(Gravity.CENTER);
        card.setPadding(Ui.dp(this, 8), Ui.dp(this, 14), Ui.dp(this, 8), Ui.dp(this, 14));
        card.setMinimumHeight(Ui.dp(this, 116));
        card.setClickable(true);
        card.setFocusable(true);
        card.setBackground(Ui.stroke(Ui.withAlpha(color, 224), Ui.withAlpha(color, 255), Ui.dp(this, 12)));

        ImageView icon = quickLogIconView(id);
        card.addView(icon, Ui.fixed(this, 52, 48));
        Ui.addSpacer(this, card, 10);
        TextView label = Ui.text(this, i18n.t(title), 13, AppColors.TEXT, android.graphics.Typeface.BOLD);
        label.setGravity(Gravity.CENTER);
        label.setSingleLine(true);
        card.addView(label, Ui.matchWrap());
        return card;
    }

    private void enableQuickLogDrag(View card, String id) {
        card.setTag(id);
        Handler dragHandler = new Handler(Looper.getMainLooper());
        final boolean[] dragging = {false};
        final boolean[] waitingForLongPress = {false};
        final float[] startRawX = {0f};
        final float[] startRawY = {0f};

        Runnable startDrag = () -> {
            waitingForLongPress[0] = false;
            dragging[0] = true;
            card.setPressed(false);
            card.setAlpha(0.76f);
            card.setScaleX(0.96f);
            card.setScaleY(0.96f);
            card.bringToFront();
            disallowParentIntercept(card, true);
        };

        card.setOnTouchListener((v, event) -> {
            switch (event.getActionMasked()) {
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
                    if (waitingForLongPress[0] && Math.hypot(dx, dy) > Ui.dp(this, 8)) {
                        waitingForLongPress[0] = false;
                        dragHandler.removeCallbacks(startDrag);
                    }
                    if (!dragging[0]) {
                        return false;
                    }
                    v.setTranslationX(dx);
                    v.setTranslationY(dy);
                    disallowParentIntercept(v, true);
                    return true;
                case MotionEvent.ACTION_UP:
                case MotionEvent.ACTION_CANCEL:
                    dragHandler.removeCallbacks(startDrag);
                    boolean didDrag = dragging[0];
                    waitingForLongPress[0] = false;
                    dragging[0] = false;
                    String targetId = didDrag ? quickLogTargetAt(getWindow().getDecorView(), event.getRawX(), event.getRawY(), id) : null;
                    v.setAlpha(1f);
                    v.setScaleX(1f);
                    v.setScaleY(1f);
                    v.setTranslationX(0f);
                    v.setTranslationY(0f);
                    disallowParentIntercept(v, false);
                    if (didDrag && targetId != null) {
                        moveQuickLogButton(id, targetId);
                    }
                    return didDrag;
                default:
                    return false;
            }
        });
    }

    private void disallowParentIntercept(View view, boolean disallow) {
        android.view.ViewParent parent = view.getParent();
        while (parent != null) {
            parent.requestDisallowInterceptTouchEvent(disallow);
            parent = parent.getParent();
        }
    }

    private String quickLogTargetAt(View view, float rawX, float rawY, String draggedId) {
        if (view == null || view.getVisibility() != View.VISIBLE) {
            return null;
        }
        if (view instanceof ViewGroup) {
            ViewGroup group = (ViewGroup) view;
            for (int i = group.getChildCount() - 1; i >= 0; i--) {
                String childTarget = quickLogTargetAt(group.getChildAt(i), rawX, rawY, draggedId);
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
        if (targetId.equals(draggedId) || quickLogOption(targetId) == null) {
            return null;
        }
        int[] location = new int[2];
        view.getLocationOnScreen(location);
        return rawX >= location[0]
                && rawX <= location[0] + view.getWidth()
                && rawY >= location[1]
                && rawY <= location[1] + view.getHeight()
                ? targetId
                : null;
    }

    private void moveQuickLogButton(String draggedId, String targetId) {
        if (draggedId.equals(targetId)) return;
        String key = storage.key("health", currentUser.id, "quickLogSelection");
        List<String> ids = orderedQuickLogIds(storage.getString(key, ""));
        int from = ids.indexOf(draggedId);
        int to = ids.indexOf(targetId);
        if (from < 0 || to < 0) return;
        ids.remove(from);
        if (from < to) to--;
        ids.add(to, draggedId);
        storage.putString(key, joinIds(ids));
        render();
    }

    private List<String[]> orderedQuickLogs(String raw) {
        List<String[]> ordered = new ArrayList<>();
        for (String id : orderedQuickLogIds(raw)) {
            String[] option = quickLogOption(id);
            if (option != null) ordered.add(option);
        }
        return ordered;
    }

    private List<String> orderedQuickLogIds(String raw) {
        List<String> ids = new ArrayList<>();
        Set<String> seen = new HashSet<>();
        if (raw != null && !raw.trim().isEmpty()) {
            for (String part : raw.split(",")) {
                String id = part.trim();
                if (!id.isEmpty() && quickLogOption(id) != null && !seen.contains(id)) {
                    ids.add(id);
                    seen.add(id);
                }
            }
        }
        return ids;
    }

    private String[] quickLogOption(String id) {
        for (String[] option : QUICK_LOGS) {
            if (option[0].equals(id)) return option;
        }
        return null;
    }

    private String joinIds(List<String> ids) {
        StringBuilder builder = new StringBuilder();
        for (String id : ids) {
            if (builder.length() > 0) builder.append(",");
            builder.append(id);
        }
        return builder.toString();
    }

    private ImageView quickLogIconView(String id) {
        ImageView icon = new ImageView(this);
        icon.setImageResource(quickLogIconRes(id));
        icon.setColorFilter(AppColors.TEXT);
        icon.setScaleType(ImageView.ScaleType.FIT_CENTER);
        icon.setAdjustViewBounds(false);
        icon.setPadding(Ui.dp(this, 5), Ui.dp(this, 4), Ui.dp(this, 5), Ui.dp(this, 4));
        return icon;
    }

    private ImageView symbolIcon(int resId, int tintColor, int backgroundColor, int sizeDp, int paddingDp) {
        ImageView icon = new ImageView(this);
        icon.setImageResource(resId);
        icon.setColorFilter(tintColor);
        icon.setScaleType(ImageView.ScaleType.FIT_CENTER);
        icon.setAdjustViewBounds(false);
        if (backgroundColor != Color.TRANSPARENT) {
            icon.setBackground(Ui.round(backgroundColor, Ui.dp(this, sizeDp / 2)));
        }
        icon.setPadding(Ui.dp(this, paddingDp), Ui.dp(this, paddingDp), Ui.dp(this, paddingDp), Ui.dp(this, paddingDp));
        return icon;
    }

    private void setButtonSymbol(Button button, int resId, int tintColor, int sizeDp) {
        Drawable icon = getDrawable(resId);
        if (icon == null) {
            return;
        }
        icon = icon.mutate();
        icon.setTint(tintColor);
        int size = Ui.dp(this, sizeDp);
        icon.setBounds(0, 0, size, size);
        button.setCompoundDrawables(icon, null, null, null);
        button.setCompoundDrawablePadding(Ui.dp(this, 8));
        button.setGravity(Gravity.CENTER);
    }

    private void setTextSymbol(TextView view, int resId, int tintColor, int sizeDp) {
        Drawable icon = getDrawable(resId);
        if (icon == null) {
            return;
        }
        icon = icon.mutate();
        icon.setTint(tintColor);
        int size = Ui.dp(this, sizeDp);
        icon.setBounds(0, 0, size, size);
        view.setCompoundDrawables(icon, null, null, null);
        view.setCompoundDrawablePadding(Ui.dp(this, 7));
    }

    private int quickLogIconRes(String id) {
        switch (id) {
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

    private View snapshotCard(String id, String title, boolean compact) {
        int color = snapshotColor(id);
        LinearLayout card = compact ? Ui.h(this, 0) : Ui.v(this, 0);
        card.setGravity(Gravity.CENTER);
        card.setPadding(Ui.dp(this, compact ? 14 : 10), compact ? Ui.dp(this, 12) : Ui.dp(this, 18), Ui.dp(this, compact ? 14 : 10), compact ? Ui.dp(this, 12) : Ui.dp(this, 18));
        card.setMinimumHeight(Ui.dp(this, compact ? 78 : 138));
        card.setClickable(true);
        card.setFocusable(true);
        card.setBackground(Ui.stroke(compact ? AppColors.PANEL : Ui.withAlpha(color, 42), Ui.withAlpha(color, compact ? 60 : 100), Ui.dp(this, compact ? 16 : 12)));

        ImageView icon = snapshotIconView(id, color, compact);
        if (compact) {
            card.addView(icon, Ui.fixed(this, 48, 48));
            Ui.addSpacerHorizontal(this, card, 12);
            TextView label = Ui.text(this, i18n.t(snapshotTitle(id, title)), 18, AppColors.TEXT, android.graphics.Typeface.BOLD);
            card.addView(label, new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1));
        } else {
            card.addView(icon, Ui.fixed(this, 62, 62));
            Ui.addSpacer(this, card, 10);
            TextView label = Ui.text(this, i18n.t(snapshotTitle(id, title)), 20, AppColors.TEXT, android.graphics.Typeface.BOLD);
            label.setGravity(Gravity.CENTER);
            label.setMaxLines(2);
            card.addView(label, Ui.matchWrap());
        }
        return card;
    }

    private ImageView snapshotIconView(String id, int color, boolean compact) {
        int fill = compact ? Ui.withAlpha(color, 28) : Color.TRANSPARENT;
        return symbolIcon(snapshotIconRes(id), color, fill, compact ? 48 : 62, compact ? 12 : 6);
    }

    private int snapshotIconRes(String id) {
        switch (id) {
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

    private String quickLogIcon(String id) {
        switch (id) {
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

    private int quickLogColor(String id) {
        switch (id) {
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

    private String snapshotIcon(String id) {
        switch (id) {
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

    private int snapshotColor(String id) {
        switch (id) {
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

    private String snapshotTitle(String id, String fallback) {
        switch (id) {
            case "sleep":
                return "Sleep";
            case "digestion":
                return "Bowel Movement";
            default:
                return fallback;
        }
    }

    private View therapyView() {
        LinearLayout screen = Ui.screen(this);
        screen.addView(therapyHeader(), Ui.matchWrap());
        Ui.addSpacer(this, screen, 16);

        JSONArray milestones = storage.getArray(storage.key("therapy", currentUser.id, "milestoneData"));
        String[] therapySession = THERAPY_CATEGORIES[0];
        View sessionButton = therapySessionButton(therapySession);
        sessionButton.setOnClickListener(v -> showMilestoneDialog(therapySession));
        screen.addView(sessionButton, Ui.matchWrap());
        Ui.addSpacer(this, screen, 16);

        GridLayout grid = Ui.grid(this, 2);
        for (String[] category : THERAPY_CATEGORIES) {
            if ("therapySession".equals(category[0])) {
                continue;
            }
            int count = countBy(milestones, "categoryID", category[0]);
            LinearLayout card = therapyCard(category, count);
            card.setOnClickListener(v -> showMilestoneDialog(category));
            Ui.addGridChild(this, grid, card, 2);
        }
        screen.addView(grid, Ui.matchWrap());
        Ui.addSpacer(this, screen, 16);

        LinearLayout recent = Ui.panel(this);
        LinearLayout row = Ui.h(this, 0);
        row.addView(Ui.sectionTitle(this, i18n.t("Recent Milestones")), new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1));
        Button hist = Ui.secondary(this, i18n.t("History"));
        setButtonSymbol(hist, R.drawable.ios_icon_chart_line_uptrend, AppColors.ACCENT, 18);
        hist.setOnClickListener(v -> showMilestoneHistory());
        row.addView(hist, Ui.wrapWrap());
        recent.addView(row, Ui.matchWrap());
        Ui.addSpacer(this, recent, 12);
        if (milestones.length() == 0) {
            recent.addView(Ui.muted(this, i18n.t("No milestones logged yet.")), Ui.matchWrap());
        } else {
            for (int i = milestones.length() - 1; i >= Math.max(0, milestones.length() - 5); i--) {
                JSONObject item = milestones.optJSONObject(i);
                if (item == null) continue;
                View milestoneRow = Ui.cardRow(this, item.optString("milestone"), i18n.t(item.optString("categoryTitle")) + " · " + item.optString("supportLevel"), therapyIcon(item.optString("categoryID")));
                milestoneRow.setOnClickListener(v -> showMilestoneDetail(item));
                recent.addView(milestoneRow, Ui.matchWrap());
                Ui.addSpacer(this, recent, 8);
            }
        }
        screen.addView(recent, Ui.matchWrap());
        return Ui.scroll(this, screen);
    }

    private View therapySessionButton(String[] category) {
        int color = therapyColor(category[0]);
        LinearLayout row = Ui.h(this, 0);
        row.setPadding(Ui.dp(this, 18), Ui.dp(this, 16), Ui.dp(this, 18), Ui.dp(this, 16));
        row.setMinimumHeight(Ui.dp(this, 88));
        row.setClickable(true);
        row.setFocusable(true);
        row.setBackground(Ui.stroke(AppColors.PANEL, Ui.withAlpha(Color.rgb(120, 190, 230), 80), Ui.dp(this, 18)));

        ImageView icon = therapyIconView(category[0], color, Ui.withAlpha(color, 26), 52, 12);
        row.addView(icon, Ui.fixed(this, 52, 52));
        Ui.addSpacerHorizontal(this, row, 18);
        row.addView(Ui.text(this, i18n.t(category[1]), 22, AppColors.TEXT, android.graphics.Typeface.BOLD), new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1));
        row.addView(Ui.text(this, "+", 30, AppColors.ACCENT, android.graphics.Typeface.BOLD), Ui.wrapWrap());
        return row;
    }

    private LinearLayout therapyCard(String[] category, int count) {
        int color = therapyColor(category[0]);
        LinearLayout card = Ui.v(this, 0);
        card.setPadding(Ui.dp(this, 16), Ui.dp(this, 16), Ui.dp(this, 16), Ui.dp(this, 16));
        card.setMinimumHeight(Ui.dp(this, 176));
        card.setClickable(true);
        card.setFocusable(true);
        card.setBackground(Ui.stroke(Ui.withAlpha(color, 34), Ui.withAlpha(color, 78), Ui.dp(this, 14)));

        LinearLayout top = Ui.h(this, 0);
        ImageView icon = therapyIconView(category[0], AppColors.PANEL, color, 48, 12);
        top.addView(icon, Ui.fixed(this, 48, 48));
        TextView countBadge = Ui.chip(this, String.valueOf(count), color, false);
        countBadge.setTextSize(15);
        LinearLayout.LayoutParams badgeParams = new LinearLayout.LayoutParams(ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        badgeParams.leftMargin = Ui.dp(this, 8);
        top.addView(new View(this), new LinearLayout.LayoutParams(0, 1, 1));
        top.addView(countBadge, badgeParams);
        card.addView(top, Ui.matchWrap());
        Ui.addSpacer(this, card, 20);
        card.addView(Ui.text(this, i18n.t(category[1]), 20, AppColors.TEXT, android.graphics.Typeface.BOLD), Ui.matchWrap());
        Ui.addSpacer(this, card, 10);
        card.addView(Ui.muted(this, i18n.t(category[2])), Ui.matchWrap());
        return card;
    }

    private LinearLayout therapyHeader() {
        LinearLayout header = Ui.v(this, 0);
        LinearLayout row = Ui.h(this, 0);
        ImageView icon = new ImageView(this);
        icon.setImageResource(R.drawable.ios_therapy_session);
        icon.setColorFilter(AppColors.ACCENT);
        icon.setPadding(0, 0, 0, 0);
        row.addView(icon, Ui.fixed(this, 48, 48));
        TextView title = Ui.title(this, i18n.t("Therapy Tracking"));
        LinearLayout.LayoutParams titleParams = new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1);
        titleParams.leftMargin = Ui.dp(this, 12);
        row.addView(title, titleParams);
        header.addView(row, Ui.matchWrap());
        Ui.addSpacer(this, header, 6);
        header.addView(Ui.muted(this, i18n.t("Log milestones and therapy wins to see your child's progress over time.")), Ui.matchWrap());
        return header;
    }

    private ImageView therapyIconView(String id, int tintColor, int backgroundColor, int sizeDp, int paddingDp) {
        ImageView icon = new ImageView(this);
        icon.setImageResource(therapyIconRes(id));
        icon.setColorFilter(tintColor);
        icon.setBackground(Ui.round(backgroundColor, Ui.dp(this, sizeDp / 2)));
        icon.setPadding(Ui.dp(this, paddingDp), Ui.dp(this, paddingDp), Ui.dp(this, paddingDp), Ui.dp(this, paddingDp));
        icon.setScaleType(ImageView.ScaleType.CENTER_INSIDE);
        return icon;
    }

    private int therapyIconRes(String id) {
        switch (id) {
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
                return R.drawable.ios_therapy_feeding;
            case "therapySession":
            default:
                return R.drawable.ios_therapy_session;
        }
    }

    private String therapyIcon(String id) {
        switch (id) {
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
                return "🍴";
            default:
                return "✓";
        }
    }

    private int therapyColor(String id) {
        switch (id) {
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
                return Color.rgb(119, 190, 120);
            default:
                return AppColors.ACCENT;
        }
    }

    private View nutrientView() {
        LinearLayout screen = Ui.screen(this);
        LinearLayout nutrientHeader = Ui.v(this, 0);
        LinearLayout titleRow = Ui.h(this, 0);
        ImageView nutrientIcon = symbolIcon(R.drawable.ios_icon_leaf, AppColors.ACCENT, Color.TRANSPARENT, 44, 0);
        titleRow.addView(nutrientIcon, Ui.fixed(this, 44, 44));
        TextView nutrientTitle = Ui.title(this, i18n.t("Nutrient"));
        LinearLayout.LayoutParams nutrientTitleParams = new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1);
        nutrientTitleParams.leftMargin = Ui.dp(this, 10);
        titleRow.addView(nutrientTitle, nutrientTitleParams);
        FrameLayout topHistory = new FrameLayout(this);
        topHistory.setBackground(Ui.round(Ui.withAlpha(AppColors.ACCENT, 22), Ui.dp(this, 16)));
        topHistory.setClickable(true);
        topHistory.setFocusable(true);
        topHistory.addView(symbolIcon(R.drawable.ios_icon_clock_arrow, AppColors.ACCENT, Color.TRANSPARENT, 25, 2),
                new FrameLayout.LayoutParams(Ui.dp(this, 34), Ui.dp(this, 34), Gravity.CENTER));
        topHistory.setOnClickListener(v -> showMealHistory());
        titleRow.addView(topHistory, Ui.fixed(this, 56, 50));
        nutrientHeader.addView(titleRow, Ui.matchWrap());
        Ui.addSpacer(this, nutrientHeader, 6);
        nutrientHeader.addView(Ui.muted(this, i18n.t("Estimate meals, hydration, safe foods, and feeding patterns.")), Ui.matchWrap());
        screen.addView(nutrientHeader, Ui.matchWrap());
        Ui.addSpacer(this, screen, 14);

        LinearLayout manual = Ui.h(this, 0);
        manual.setPadding(Ui.dp(this, 16), Ui.dp(this, 14), Ui.dp(this, 16), Ui.dp(this, 14));
        manual.setBackground(Ui.round(AppColors.PANEL, Ui.dp(this, 14)));
        ImageView manualIcon = symbolIcon(R.drawable.ios_icon_square_pencil, AppColors.PANEL, AppColors.ACCENT, 48, 12);
        manual.addView(manualIcon, Ui.fixed(this, 48, 48));
        TextView manualLabel = Ui.text(this, i18n.t("Add Meal Manually"), 18, AppColors.TEXT, android.graphics.Typeface.BOLD);
        LinearLayout.LayoutParams manualLabelParams = new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1);
        manualLabelParams.leftMargin = Ui.dp(this, 12);
        manual.addView(manualLabel, manualLabelParams);
        manual.addView(symbolIcon(R.drawable.ios_icon_chevron_right, AppColors.MUTED, Color.TRANSPARENT, 26, 2), Ui.fixed(this, 26, 26));
        manual.setOnClickListener(v -> showManualMealDialog());
        screen.addView(manual, Ui.matchWrap());
        Ui.addSpacer(this, screen, 14);

        LinearLayout panel = Ui.panel(this);
        JSONObject usage = dailyUsage();
        int limit = storage.getInt(storage.key("nutrient", currentUser.id, "dailyEstimateLimit"), 3);
        int left = Math.max(0, limit - usage.optInt("estimateCount"));
        panel.addView(nutrientQuotaPill(left, limit), Ui.matchWrap());
        Ui.addSpacer(this, panel, 22);

        LinearLayout goals = nutrientGoalsRow();
        panel.addView(goals, Ui.matchWrap());
        Ui.addSpacer(this, panel, 24);

        panel.addView(mealPhotoUploadCard(), Ui.matchWrap());
        Ui.addSpacer(this, panel, 14);

        boolean canEstimate = !selectedMealPhotoDataUrl.isEmpty() && usage.optInt("estimateCount") < limit && !isLoading;
        LinearLayout estimate = nutrientActionButton(isLoading ? i18n.t("Estimating...") : i18n.t("Estimate Nutrients"),
                R.drawable.ios_icon_sparkles, AppColors.ACCENT, AppColors.PANEL, true);
        estimate.setEnabled(canEstimate);
        estimate.setAlpha(canEstimate ? 1f : 0.46f);
        estimate.setOnClickListener(canEstimate ? v -> estimateMeal() : null);
        panel.addView(estimate, Ui.matchWrap());
        Ui.addSpacer(this, panel, 14);

        addMessage(panel);
        panel.addView(nutrientSummaryView(), Ui.matchWrap());

        if (currentMealEstimate != null) {
            Ui.addSpacer(this, panel, 14);
            Button save = Ui.primary(this, hasSavedCurrentMeal ? i18n.t("Saved") : i18n.t("Save Meal"));
            save.setEnabled(!hasSavedCurrentMeal);
            save.setOnClickListener(v -> saveCurrentMeal());
            panel.addView(save, Ui.matchWrap());
            Ui.addSpacer(this, panel, 10);
            panel.addView(mealEstimateView(currentMealEstimate), Ui.matchWrap());
        }
        screen.addView(panel, Ui.matchWrap());
        return Ui.scroll(this, screen);
    }

    private LinearLayout nutrientQuotaPill(int left, int limit) {
        int color = left == 0 ? AppColors.DANGER : AppColors.ACCENT;
        int fill = left == 0 ? Color.rgb(255, 224, 229) : (left == limit ? Color.rgb(224, 240, 232) : Color.rgb(255, 239, 204));
        LinearLayout pill = Ui.h(this, 0);
        pill.setGravity(Gravity.CENTER);
        pill.setPadding(Ui.dp(this, 18), Ui.dp(this, 9), Ui.dp(this, 18), Ui.dp(this, 9));
        pill.setBackground(Ui.round(fill, Ui.dp(this, 22)));
        ImageView icon = symbolIcon(R.drawable.ios_icon_sparkles, color, Color.TRANSPARENT, 18, 1);
        pill.addView(icon, Ui.fixed(this, 20, 20));
        Ui.addSpacerHorizontal(this, pill, 8);
        pill.addView(Ui.text(this, i18n.t("Estimates Left Today") + "  " + left + "/" + limit, 14, color, android.graphics.Typeface.BOLD), Ui.wrapWrap());
        return pill;
    }

    private LinearLayout nutrientGoalsRow() {
        LinearLayout row = Ui.h(this, 0);
        row.setGravity(Gravity.CENTER_VERTICAL);
        row.setPadding(Ui.dp(this, 2), Ui.dp(this, 8), Ui.dp(this, 0), Ui.dp(this, 8));
        row.setClickable(true);
        row.setFocusable(true);
        row.setOnClickListener(v -> showMessageSheet(i18n.t("Nutrition Goals"), i18n.t("Nutrition goals can be reviewed here.")));
        TextView label = Ui.text(this, i18n.t("View Nutrition Goals"), 20, AppColors.ACCENT, android.graphics.Typeface.BOLD);
        row.addView(label, new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1));
        row.addView(symbolIcon(R.drawable.ios_icon_chevron_right, AppColors.MUTED, Color.TRANSPARENT, 32, 3), Ui.fixed(this, 32, 32));
        return row;
    }

    private View mealPhotoUploadCard() {
        FrameLayout card = new FrameLayout(this);
        card.setMinimumHeight(Ui.dp(this, 248));
        card.setBackground(Ui.round(AppColors.FIELD, Ui.dp(this, 18)));
        card.setClickable(true);
        card.setFocusable(true);
        card.setOnClickListener(v -> chooseMealPhoto());

        Bitmap bitmap = bitmapFromDataUrl(selectedMealPhotoDataUrl);
        if (bitmap != null) {
            ImageView image = new ImageView(this);
            image.setImageBitmap(bitmap);
            image.setScaleType(ImageView.ScaleType.CENTER_CROP);
            card.addView(image, new FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, Ui.dp(this, 248), Gravity.CENTER));
        } else {
            LinearLayout empty = Ui.v(this, 0);
            empty.setGravity(Gravity.CENTER);
            ImageView camera = symbolIcon(R.drawable.ios_icon_camera_viewfinder, AppColors.ACCENT, Color.TRANSPARENT, 58, 6);
            empty.addView(camera, Ui.fixed(this, 58, 58));
            Ui.addSpacer(this, empty, 10);
            TextView title = Ui.text(this, i18n.t("Upload Meal Photo"), 20, AppColors.TEXT, android.graphics.Typeface.BOLD);
            title.setGravity(Gravity.CENTER);
            empty.addView(title, Ui.matchWrap());
            Ui.addSpacer(this, empty, 8);
            TextView subtitle = Ui.text(this, i18n.t("Breakfast, lunch, dinner, or snack"), 14, AppColors.MUTED, android.graphics.Typeface.BOLD);
            subtitle.setGravity(Gravity.CENTER);
            empty.addView(subtitle, Ui.matchWrap());
            card.addView(empty, new FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, Ui.dp(this, 248), Gravity.CENTER));
        }

        ImageView add = symbolIcon(selectedMealPhotoDataUrl.isEmpty() ? R.drawable.ios_icon_plus : R.drawable.ios_icon_camera_fill,
                AppColors.PANEL, AppColors.ACCENT, 48, 13);
        FrameLayout.LayoutParams addParams = new FrameLayout.LayoutParams(Ui.dp(this, 48), Ui.dp(this, 48), Gravity.BOTTOM | Gravity.RIGHT);
        addParams.setMargins(0, 0, Ui.dp(this, 18), Ui.dp(this, 18));
        card.addView(add, addParams);
        LinearLayout.LayoutParams cardParams = Ui.matchWrap();
        cardParams.height = Ui.dp(this, 248);
        card.setLayoutParams(cardParams);
        return card;
    }

    private LinearLayout nutrientActionButton(String title, int iconRes, int fillColor, int textColor, boolean primary) {
        LinearLayout button = Ui.h(this, 0);
        button.setGravity(Gravity.CENTER);
        button.setPadding(Ui.dp(this, 18), Ui.dp(this, 17), Ui.dp(this, 18), Ui.dp(this, 17));
        button.setBackground(primary ? Ui.round(fillColor, Ui.dp(this, 12)) : Ui.stroke(fillColor, AppColors.BORDER, Ui.dp(this, 12)));
        button.setClickable(true);
        button.setFocusable(true);
        ImageView icon = symbolIcon(iconRes, textColor, Color.TRANSPARENT, 22, 2);
        button.addView(icon, Ui.fixed(this, 24, 24));
        Ui.addSpacerHorizontal(this, button, 10);
        button.addView(Ui.text(this, title, 18, textColor, android.graphics.Typeface.BOLD), Ui.wrapWrap());
        return button;
    }

    private LinearLayout nutrientSummaryView() {
        JSONArray meals = storage.getArray(storage.key("nutrient", currentUser.id, "savedMealHistoryData"));
        JSONObject latestEstimate = null;
        for (int i = meals.length() - 1; i >= 0; i--) {
            JSONObject meal = meals.optJSONObject(i);
            if (meal == null) continue;
            latestEstimate = meal.optJSONObject("estimate");
            if (latestEstimate != null) break;
        }

        LinearLayout summary = Ui.v(this, 0);
        summary.setPadding(Ui.dp(this, 2), Ui.dp(this, 4), Ui.dp(this, 2), Ui.dp(this, 2));
        String mealCount = meals.length() + " " + i18n.t("analyzed");
        String calories = latestEstimate == null ? "--" : nutrientValue(latestEstimate.optString("calories", "--"), "kcal");
        String macros = "--";
        if (latestEstimate != null) {
            String protein = nutrientValue(latestEstimate.optString("protein", "--"), "g");
            String carbs = nutrientValue(latestEstimate.optString("carbs", "--"), "g");
            String fats = nutrientValue(latestEstimate.optString("fats", latestEstimate.optString("fat", "--")), "g");
            macros = "P " + protein + " · C " + carbs + " · F " + fats;
        }
        summary.addView(nutrientSummaryRow(R.drawable.ios_icon_fork_knife, "--", mealCount), Ui.matchWrap());
        Ui.addSpacer(this, summary, 8);
        summary.addView(nutrientSummaryRow(R.drawable.ios_icon_flame, "--", calories), Ui.matchWrap());
        Ui.addSpacer(this, summary, 8);
        summary.addView(nutrientSummaryRow(R.drawable.ios_icon_chart_pie, "--", macros), Ui.matchWrap());
        return summary;
    }

    private LinearLayout nutrientSummaryRow(int iconRes, String label, String value) {
        LinearLayout row = Ui.h(this, 0);
        row.setGravity(Gravity.CENTER_VERTICAL);
        row.setPadding(Ui.dp(this, 6), Ui.dp(this, 2), Ui.dp(this, 6), Ui.dp(this, 2));
        ImageView icon = symbolIcon(iconRes, AppColors.ACCENT, Color.TRANSPARENT, 28, 1);
        row.addView(icon, Ui.fixed(this, 32, 32));
        Ui.addSpacerHorizontal(this, row, 16);
        TextView title = Ui.text(this, label, 20, AppColors.TEXT, android.graphics.Typeface.BOLD);
        row.addView(title, new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1));
        TextView val = Ui.text(this, value, 20, AppColors.MUTED, android.graphics.Typeface.NORMAL);
        val.setGravity(Gravity.RIGHT);
        row.addView(val, new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1));
        return row;
    }

    private String nutrientValue(String raw, String unit) {
        if (raw == null) return "--";
        String value = raw.trim();
        if (value.isEmpty() || value.equals("--")) return "--";
        String lower = value.toLowerCase(Locale.US);
        if (lower.contains(unit.toLowerCase(Locale.US))) return value;
        return value + " " + unit;
    }

    private View profileView() {
        LinearLayout screen = Ui.screen(this);
        LinearLayout header = Ui.v(this, 0);
        header.setGravity(Gravity.CENTER_HORIZONTAL);
        header.setPadding(0, Ui.dp(this, 10), 0, Ui.dp(this, 6));
        View avatar = profileAvatarButton();
        LinearLayout.LayoutParams avatarParams = Ui.fixed(this, 112, 112);
        avatarParams.gravity = Gravity.CENTER_HORIZONTAL;
        header.addView(avatar, avatarParams);
        Ui.addSpacer(this, header, 12);

        LinearLayout nameRow = Ui.h(this, 0);
        nameRow.setGravity(Gravity.CENTER);
        nameRow.setClickable(true);
        nameRow.setFocusable(true);
        nameRow.setOnClickListener(v -> showBasicInfoDialog());
        TextView name = Ui.text(this, currentUser.nickname, 30, AppColors.TEXT, android.graphics.Typeface.BOLD);
        nameRow.addView(name, Ui.wrapWrap());
        Ui.addSpacerHorizontal(this, nameRow, 8);
        nameRow.addView(symbolIcon(R.drawable.ios_icon_chevron_right, AppColors.MUTED, Color.TRANSPARENT, 24, 4), Ui.fixed(this, 24, 24));
        header.addView(nameRow, Ui.matchWrap());

        TextView sub = Ui.muted(this, i18n.t("Parent account for your child's care."));
        sub.setGravity(Gravity.CENTER);
        header.addView(sub, Ui.matchWrap());
        screen.addView(header, Ui.matchWrap());
        Ui.addSpacer(this, screen, 20);

        LinearLayout account = Ui.panel(this);
        account.addView(Ui.sectionTitle(this, i18n.t("Parent Account")), Ui.matchWrap());
        Ui.addSpacer(this, account, 10);
        account.addView(infoRow(i18n.t("Parent Username"), currentUser.nickname), Ui.matchWrap());
        account.addView(infoRow(i18n.t("Parent Email"), currentUser.email), Ui.matchWrap());
        account.addView(infoRow(i18n.t("Account Type"), i18n.t("Parent")), Ui.matchWrap());
        screen.addView(account, Ui.matchWrap());
        Ui.addSpacer(this, screen, 14);

        screen.addView(profileNavRow(i18n.t("Settings"), () -> showLanguageDialog()), Ui.matchWrap());
        Ui.addSpacer(this, screen, 10);

        Button logout = Ui.danger(this, i18n.t("Log Out"));
        logout.setOnClickListener(v -> logout());
        screen.addView(logout, Ui.matchWrap());
        return Ui.scroll(this, screen);
    }

    private View profileAvatarButton() {
        FrameLayout frame = new FrameLayout(this);
        String image = storage.getString(storage.key("profile", currentUser.id, "profileImageData"), "");
        if (image.isEmpty() && currentUser.profileImage != null) {
            image = currentUser.profileImage;
        }
        Bitmap bitmap = bitmapFromDataUrl(image);
        View main;
        if (bitmap != null) {
            ImageView photo = new ImageView(this);
            photo.setImageBitmap(circleBitmap(bitmap));
            photo.setScaleType(ImageView.ScaleType.CENTER_CROP);
            main = photo;
        } else {
            TextView fallback = Ui.text(this, initials(currentUser.nickname), 30, AppColors.ACCENT, android.graphics.Typeface.BOLD);
            fallback.setGravity(Gravity.CENTER);
            fallback.setBackground(Ui.round(Ui.withAlpha(AppColors.ACCENT, 24), Ui.dp(this, 54)));
            main = fallback;
        }
        FrameLayout.LayoutParams mainParams = new FrameLayout.LayoutParams(Ui.dp(this, 108), Ui.dp(this, 108), Gravity.CENTER);
        frame.addView(main, mainParams);

        ImageView camera = symbolIcon(R.drawable.ios_icon_camera_fill, AppColors.PANEL, AppColors.ACCENT, 34, 8);
        camera.setBackground(Ui.stroke(AppColors.ACCENT, AppColors.PANEL, Ui.dp(this, 17)));
        FrameLayout.LayoutParams cameraParams = new FrameLayout.LayoutParams(Ui.dp(this, 34), Ui.dp(this, 34), Gravity.BOTTOM | Gravity.RIGHT);
        cameraParams.setMargins(0, 0, Ui.dp(this, 4), Ui.dp(this, 4));
        frame.addView(camera, cameraParams);
        frame.setClickable(true);
        frame.setFocusable(true);
        frame.setOnClickListener(v -> showProfilePhotoDialog());
        return frame;
    }

    private Bitmap circleBitmap(Bitmap source) {
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

    private LinearLayout profileNavRow(String title, Runnable action) {
        LinearLayout row = Ui.h(this, 0);
        row.setGravity(Gravity.CENTER_VERTICAL);
        row.setPadding(Ui.dp(this, 18), Ui.dp(this, 16), Ui.dp(this, 14), Ui.dp(this, 16));
        row.setBackground(Ui.round(Ui.withAlpha(AppColors.ACCENT, 22), Ui.dp(this, 12)));
        row.setClickable(true);
        row.setFocusable(true);
        row.setOnClickListener(v -> {
            if (action != null) action.run();
        });
        TextView label = Ui.text(this, title, 18, AppColors.ACCENT, android.graphics.Typeface.BOLD);
        label.setGravity(Gravity.CENTER);
        row.addView(label, new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1));
        row.addView(symbolIcon(R.drawable.ios_icon_chevron_right, AppColors.ACCENT, Color.TRANSPARENT, 26, 4), Ui.fixed(this, 26, 26));
        return row;
    }

    private void showProfilePhotoDialog() {
        showChoiceSheet(i18n.t("Change child profile picture"), new String[]{i18n.t("Choose Photo"), i18n.t("Take Photo")}, (which, sheet) -> {
            sheet.dismiss();
            if (which == 0) chooseProfilePhoto();
            else takeProfilePhoto();
        });
    }

    private void showChoiceSheet(String title, String[] choices, SheetChoiceHandler handler) {
        LinearLayout content = Ui.v(this, 0);
        content.setPadding(Ui.dp(this, 12), 0, Ui.dp(this, 12), 0);
        final Dialog[] holder = new Dialog[1];
        for (int i = 0; i < choices.length; i++) {
            final int index = i;
            LinearLayout row = Ui.h(this, 0);
            row.setGravity(Gravity.CENTER_VERTICAL);
            row.setPadding(Ui.dp(this, 16), Ui.dp(this, 16), Ui.dp(this, 16), Ui.dp(this, 16));
            row.setBackground(Ui.stroke(AppColors.PANEL, AppColors.BORDER, Ui.dp(this, 16)));
            row.setClickable(true);
            row.setFocusable(true);
            TextView label = Ui.text(this, choices[i], 18, AppColors.TEXT, android.graphics.Typeface.BOLD);
            row.addView(label, new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1));
            row.addView(symbolIcon(R.drawable.ios_icon_chevron_right, AppColors.MUTED, Color.TRANSPARENT, 24, 4), Ui.fixed(this, 24, 24));
            row.setOnClickListener(v -> {
                if (handler != null) handler.onChoice(index, holder[0]);
            });
            content.addView(row, Ui.matchWrap());
            Ui.addSpacer(this, content, 10);
        }
        holder[0] = Ui.bottomSheet(this, title, content, "", null);
        holder[0].show();
    }

    private void showMessageSheet(String title, String message) {
        LinearLayout content = Ui.v(this, 0);
        content.setPadding(Ui.dp(this, 12), 0, Ui.dp(this, 12), 0);
        content.addView(Ui.muted(this, message), Ui.matchWrap());
        Ui.dialog(this, title, content, i18n.t("Done"), null);
    }

    private void chooseProfilePhoto() {
        pendingPhotoCallback = dataUrl -> {
            if (!dataUrl.isEmpty()) {
                storage.putString(storage.key("profile", currentUser.id, "profileImageData"), dataUrl);
                render();
            }
        };
        Intent intent = new Intent(Intent.ACTION_GET_CONTENT);
        intent.setType("image/*");
        startActivityForResult(Intent.createChooser(intent, i18n.t("Choose Photo")), REQUEST_GENERIC_PHOTO_LIBRARY);
    }

    private void takeProfilePhoto() {
        pendingPhotoCallback = dataUrl -> {
            if (!dataUrl.isEmpty()) {
                storage.putString(storage.key("profile", currentUser.id, "profileImageData"), dataUrl);
                render();
            }
        };
        try {
            Intent intent = new Intent(MediaStore.ACTION_IMAGE_CAPTURE);
            startActivityForResult(intent, REQUEST_GENERIC_PHOTO_CAMERA);
        } catch (Exception e) {
            pendingPhotoCallback = null;
            showMessageSheet(i18n.t("Camera is not available."), "");
        }
    }

    private LinearLayout pageHeader(String title, String subtitle) {
        return pageHeader(title, subtitle, "");
    }

    private LinearLayout pageHeader(String title, String subtitle, String iconText) {
        LinearLayout header = Ui.v(this, 0);
        if (iconText == null || iconText.isEmpty()) {
            header.addView(Ui.title(this, title), Ui.matchWrap());
        } else {
            LinearLayout row = Ui.h(this, 0);
            TextView icon = Ui.text(this, iconText, 32, AppColors.ACCENT, android.graphics.Typeface.BOLD);
            row.addView(icon, Ui.wrapWrap());
            TextView heading = Ui.title(this, title);
            LinearLayout.LayoutParams titleParams = new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1);
            titleParams.leftMargin = Ui.dp(this, 10);
            row.addView(heading, titleParams);
            header.addView(row, Ui.matchWrap());
        }
        Ui.addSpacer(this, header, 6);
        header.addView(Ui.muted(this, subtitle), Ui.matchWrap());
        return header;
    }

    private View childAvatarView(int sizeDp) {
        String image = storage.getString(storage.key("profile", currentUser.id, "profileImageData"), "");
        if (image.isEmpty() && currentUser.profileImage != null) {
            image = currentUser.profileImage;
        }
        Bitmap bitmap = bitmapFromDataUrl(image);
        if (bitmap != null) {
            ImageView view = new ImageView(this);
            view.setImageBitmap(bitmap);
            view.setScaleType(ImageView.ScaleType.CENTER_CROP);
            view.setBackground(Ui.stroke(AppColors.PANEL, AppColors.PANEL, Ui.dp(this, sizeDp / 2)));
            view.setPadding(Ui.dp(this, 2), Ui.dp(this, 2), Ui.dp(this, 2), Ui.dp(this, 2));
            view.setClickable(true);
            return view;
        }
        TextView avatar = Ui.text(this, initials(childName()), 16, AppColors.PANEL, android.graphics.Typeface.BOLD);
        avatar.setGravity(Gravity.CENTER);
        avatar.setBackground(Ui.round(AppColors.ACCENT, Ui.dp(this, sizeDp / 2)));
        avatar.setClickable(true);
        return avatar;
    }

    private LinearLayout roundHistoryButton() {
        LinearLayout row = Ui.h(this, 0);
        row.setGravity(Gravity.CENTER_VERTICAL);
        row.setClickable(true);
        row.setFocusable(true);
        ImageView icon = symbolIcon(R.drawable.ios_icon_chart_line_uptrend, AppColors.PANEL, AppColors.ACCENT, 42, 9);
        icon.setClickable(false);
        icon.setFocusable(false);
        row.addView(icon, Ui.fixed(this, 42, 42));
        Ui.addSpacerHorizontal(this, row, 8);
        row.addView(Ui.text(this, i18n.t("History"), 16, AppColors.ACCENT, android.graphics.Typeface.BOLD), Ui.wrapWrap());
        return row;
    }

    private TextView iconCircle(String text, int textColor, int fillColor, int sizeDp) {
        TextView view = Ui.text(this, text, 22, textColor, android.graphics.Typeface.BOLD);
        view.setGravity(Gravity.CENTER);
        view.setBackground(Ui.round(fillColor, Ui.dp(this, sizeDp / 2)));
        view.setClickable(true);
        view.setFocusable(true);
        return view;
    }

    private Bitmap bitmapFromDataUrl(String dataUrl) {
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

    private LinearLayout infoRow(String title, String value) {
        LinearLayout row = Ui.h(this, 0);
        row.setPadding(0, Ui.dp(this, 8), 0, Ui.dp(this, 8));
        row.addView(Ui.muted(this, title), new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1));
        TextView val = Ui.text(this, value == null ? "" : value, 14, AppColors.TEXT, android.graphics.Typeface.BOLD);
        val.setGravity(Gravity.END);
        row.addView(val, new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1));
        return row;
    }

    private void login(String username, String password) {
        clearMessage();
        if (username.trim().isEmpty() || password.isEmpty()) {
            showError(i18n.t("Please enter your parent username and password."));
            render();
            return;
        }
        isLoading = true;
        render();
        api.login(username.trim(), password, new AuthApi.Callback<CarePortalUser>() {
            @Override
            public void onSuccess(CarePortalUser value) {
                currentUser = value;
                storage.saveUser(value);
                resetLoginProtection();
                isLoading = false;
                restoreServerAppData(value);
                render();
            }

            @Override
            public void onError(String msg) {
                isLoading = false;
                if (msg.toLowerCase(Locale.US).contains("invalid") || msg.toLowerCase(Locale.US).contains("incorrect")) {
                    failedLoginAttempts++;
                    if (failedLoginAttempts >= 2) {
                        captchaRequired = true;
                        captchaCode = makeCaptchaCode();
                        captchaInput = "";
                        showError(i18n.t("Too many incorrect attempts. Please complete the verification code."));
                    } else {
                        showError(msg);
                    }
                } else {
                    showError(msg);
                }
                render();
            }
        });
    }

    private void signup(String nickname, String email, String password, String verifyPassword) {
        clearMessage();
        String cleanNickname = nickname.trim();
        String cleanEmail = email.trim().toLowerCase(Locale.US);
        if (cleanNickname.isEmpty() || cleanEmail.isEmpty() || password.isEmpty() || verifyPassword.isEmpty()) {
            showError(i18n.t("Please fill out every field."));
            render();
            return;
        }
        if (!cleanEmail.contains("@") || !cleanEmail.contains(".")) {
            showError(i18n.t("Please enter a valid email address."));
            render();
            return;
        }
        if (password.length() < 6 || !password.matches(".*\\d.*")) {
            showError(i18n.t("Password must be at least 6 characters and include one number."));
            render();
            return;
        }
        if (!password.equals(verifyPassword)) {
            showError(i18n.t("Passwords do not match."));
            render();
            return;
        }
        isLoading = true;
        render();
        api.signup(cleanNickname, cleanEmail, password, verifyPassword, new AuthApi.Callback<String>() {
            @Override
            public void onSuccess(String value) {
                isLoading = false;
                message = value;
                isError = false;
                loginNickname = cleanNickname;
                signupNickname = "";
                authScreen = "login";
                render();
            }

            @Override
            public void onError(String msg) {
                isLoading = false;
                showError(msg);
                render();
            }
        });
    }

    private void validateSavedSession() {
        if (currentUser == null) {
            return;
        }
        api.validateSavedSession(currentUser.id, new AuthApi.Callback<CarePortalUser>() {
            @Override
            public void onSuccess(CarePortalUser value) {
                currentUser = value;
                storage.saveUser(value);
                restoreServerAppData(value);
                render();
            }

            @Override
            public void onError(String msg) {
                String lower = msg.toLowerCase(Locale.US);
                if (lower.contains("blocked") || lower.contains("log in again")) {
                    logout();
                    showError(msg);
                    authScreen = "login";
                    render();
                }
            }
        });
    }

    private void restoreServerAppData(CarePortalUser user) {
        api.loadAppData(user.id, new AuthApi.Callback<JSONObject>() {
            @Override
            public void onSuccess(JSONObject value) {
                JSONObject profile = value.optJSONObject("childProfile");
                if (profile != null) {
                    putIfBlank("profile", "fullName", profile.optString("fullName"));
                    putIfBlank("profile", "birthDate", profile.optString("birthDate"));
                    putIfBlank("profile", "phone", profile.optString("supportNeeds"));
                    putIfBlank("profile", "address", profile.optString("homeSchoolNotes"));
                    putIfBlank("profile", "emergencyContact", profile.optString("emergencyContact"));
                    putIfBlank("profile", "medicalNotes", profile.optString("careNotes"));
                }
                JSONArray logs = value.optJSONArray("healthLogs");
                if (logs != null && logs.length() > 0 && storage.getArray(storage.key("health", user.id, "logData")).length() == 0) {
                    storage.putArray(storage.key("health", user.id, "logData"), logs);
                }
                JSONArray meals = value.optJSONArray("savedMeals");
                if (meals != null && meals.length() > 0 && storage.getArray(storage.key("nutrient", user.id, "savedMealHistoryData")).length() == 0) {
                    storage.putArray(storage.key("nutrient", user.id, "savedMealHistoryData"), meals);
                }
                JSONObject usage = value.optJSONObject("nutrientDailyUsage");
                if (usage != null) {
                    storage.putObject(storage.key("nutrient", user.id, "dailyUsageData"), usage);
                }
                if (value.has("nutrientDailyLimit")) {
                    storage.putInt(storage.key("nutrient", user.id, "dailyEstimateLimit"), value.optInt("nutrientDailyLimit", 3));
                }
            }

            @Override
            public void onError(String message) {
            }
        });
    }

    private void putIfBlank(String area, String key, String value) {
        String fullKey = storage.key(area, currentUser.id, key);
        if (storage.getString(fullKey, "").trim().isEmpty()) {
            storage.putString(fullKey, value);
        }
    }

    private void logout() {
        currentUser = null;
        storage.clearSavedUser();
        authScreen = "home";
        selectedTab = 0;
        loginNickname = "";
        resetLoginProtection();
        clearMessage();
        render();
    }

    private void resetLoginProtection() {
        failedLoginAttempts = 0;
        captchaRequired = false;
        captchaInput = "";
        captchaCode = makeCaptchaCode();
    }

    private void completeCaptchaChallenge() {
        if (!captchaInput.trim().equalsIgnoreCase(captchaCode)) {
            captchaInput = "";
            captchaCode = makeCaptchaCode();
            showError(i18n.t("Please enter the verification code shown."));
        } else {
            captchaRequired = false;
            failedLoginAttempts = 0;
            captchaInput = "";
            message = i18n.t("Verification complete. Please enter your password again.");
            isError = false;
        }
        render();
    }

    private void showDiagnosisCategoryDialog() {
        String key = storage.key("diagnosis", currentUser.id, "selectedOptions");
        Set<String> selected = commaSet(storage.getString(key, ""));
        boolean[] checked = new boolean[DIAGNOSIS_OPTIONS.length];
        LinearLayout content = Ui.v(this, 0);
        content.setPadding(Ui.dp(this, 12), 0, Ui.dp(this, 12), 0);
        for (int i = 0; i < DIAGNOSIS_OPTIONS.length; i++) {
            checked[i] = selected.contains(DIAGNOSIS_OPTIONS[i][0]);
            final int index = i;
            LinearLayout row = Ui.h(this, 0);
            row.setGravity(Gravity.CENTER_VERTICAL);
            row.setPadding(Ui.dp(this, 14), Ui.dp(this, 12), Ui.dp(this, 14), Ui.dp(this, 12));
            row.setBackground(Ui.stroke(checked[i] ? Ui.withAlpha(AppColors.ACCENT, 28) : AppColors.PANEL, AppColors.BORDER, Ui.dp(this, 14)));
            row.setClickable(true);
            row.setFocusable(true);
            CheckBox box = new CheckBox(this);
            box.setChecked(checked[i]);
            box.setClickable(false);
            box.setButtonTintList(android.content.res.ColorStateList.valueOf(AppColors.ACCENT));
            row.addView(box, Ui.fixed(this, 42, 42));
            String labelText = diagnosisIcon(DIAGNOSIS_OPTIONS[i][0]) + "  " + i18n.t(DIAGNOSIS_OPTIONS[i][1]);
            row.addView(Ui.text(this, labelText, 16, AppColors.TEXT, android.graphics.Typeface.BOLD), new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1));
            row.setOnClickListener(v -> {
                checked[index] = !checked[index];
                box.setChecked(checked[index]);
                row.setBackground(Ui.stroke(checked[index] ? Ui.withAlpha(AppColors.ACCENT, 28) : AppColors.PANEL, AppColors.BORDER, Ui.dp(this, 14)));
            });
            content.addView(row, Ui.matchWrap());
            Ui.addSpacer(this, content, 8);
        }
        Ui.dialogWithTopAction(this, i18n.t("Category"), content, i18n.t("Done"), () -> {
            StringBuilder builder = new StringBuilder();
            for (int i = 0; i < checked.length; i++) {
                if (checked[i]) {
                    if (builder.length() > 0) builder.append(",");
                    builder.append(DIAGNOSIS_OPTIONS[i][0]);
                }
            }
            storage.putString(key, builder.toString());
            render();
        });
    }

    private void showConditionActions(int index) {
        showChoiceSheet(i18n.t("Condition"), new String[]{i18n.t("Edit"), i18n.t("Delete")}, (which, sheet) -> {
            sheet.dismiss();
            JSONArray conditions = storage.getArray(storage.key("diagnosis", currentUser.id, "conditions"));
            JSONObject item = conditions.optJSONObject(index);
            if (which == 0 && item != null) {
                showConditionDialog(item, index);
            } else if (which == 1) {
                conditions.remove(index);
                storage.putArray(storage.key("diagnosis", currentUser.id, "conditions"), conditions);
                render();
            }
        });
    }

    private void showConditionDialog(JSONObject existing, int index) {
        LinearLayout content = Ui.v(this, 0);
        content.setPadding(Ui.dp(this, 6), 0, Ui.dp(this, 6), Ui.dp(this, 8));

        Set<String> selectedCategories = conditionCategoryIds(existing);
        EditText name = Ui.edit(this, i18n.t("Enter condition name"));
        EditText notes = Ui.multi(this, i18n.t("Add notes"));
        String[] photoData = {existing == null ? "" : existing.optString("imageData")};
        if (existing != null) {
            name.setText(existing.optString("name"));
            notes.setText(existing.optString("notes"));
        }

        Button save = Ui.primary(this, i18n.t("Save"));
        Runnable updateSave = () -> updateConditionSaveButton(save, name);
        addConditionTextWatcher(name, updateSave);
        addConditionTextWatcher(notes, updateSave);

        boolean[] categoryExpanded = {false};
        LinearLayout categoryHost = Ui.v(this, 0);
        Runnable[] refreshCategory = new Runnable[1];
        refreshCategory[0] = () -> {
            categoryHost.removeAllViews();
            categoryHost.addView(conditionCategoryDropdownCard(selectedCategories, categoryExpanded[0], () -> {
                categoryExpanded[0] = !categoryExpanded[0];
                refreshCategory[0].run();
            }, () -> {
                updateSave.run();
                refreshCategory[0].run();
            }), Ui.matchWrap());
        };
        refreshCategory[0].run();
        content.addView(categoryHost, Ui.matchWrap());
        Ui.addSpacer(this, content, 14);

        content.addView(conditionInputCard(i18n.t("Condition Name"), name), Ui.matchWrap());
        Ui.addSpacer(this, content, 14);
        content.addView(conditionInputCard(i18n.t("Notes"), notes), Ui.matchWrap());
        Ui.addSpacer(this, content, 14);
        content.addView(conditionPhotoCard(photoData, updateSave), Ui.matchWrap());

        final Dialog[] dialogRef = new Dialog[1];
        save.setOnClickListener(v -> {
            String cleanName = name.getText().toString().trim();
            if (cleanName.isEmpty()) return;
            JSONArray conditions = storage.getArray(storage.key("diagnosis", currentUser.id, "conditions"));
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
                item.put("createdAt", existing == null ? nowIso() : existing.optString("createdAt", nowIso()));
                item.put("updatedAt", nowIso());
                if (!photoData[0].isEmpty()) item.put("imageData", photoData[0]);
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
            storage.putArray(storage.key("diagnosis", currentUser.id, "conditions"), conditions);
            mergeDiagnosisSelections(selectedCategories);
            render();
            if (dialogRef[0] != null) dialogRef[0].dismiss();
        });
        LinearLayout.LayoutParams saveParams = Ui.matchWrap();
        saveParams.topMargin = Ui.dp(this, 18);
        content.addView(save, saveParams);
        updateSave.run();

        dialogRef[0] = Ui.bottomSheet(this, i18n.t(existing == null ? "New Condition" : "Edit Condition"), content, null, null);
        dialogRef[0].show();
    }

    private Set<String> conditionCategoryIds(JSONObject existing) {
        Set<String> selected = new LinkedHashSet<>();
        if (existing == null) return selected;
        JSONArray ids = existing.optJSONArray("categoryIDs");
        if (ids != null) {
            for (int i = 0; i < ids.length(); i++) {
                String id = ids.optString(i, "").trim();
                if (!id.isEmpty()) selected.add(id);
            }
        } else {
            selected.addAll(commaSet(existing.optString("categoryIDs", "")));
        }
        String single = existing.optString("categoryID", "").trim();
        if (!single.isEmpty()) selected.add(single);
        return selected;
    }

    private LinearLayout conditionFormCard() {
        LinearLayout card = Ui.v(this, 0);
        card.setPadding(Ui.dp(this, 16), Ui.dp(this, 16), Ui.dp(this, 16), Ui.dp(this, 16));
        card.setBackground(Ui.round(AppColors.PANEL, Ui.dp(this, 20)));
        return card;
    }

    private LinearLayout conditionCategoryDropdownCard(Set<String> selected, boolean expanded, Runnable onToggle, Runnable onChanged) {
        LinearLayout card = conditionFormCard();

        LinearLayout inner = Ui.h(this, 0);
        inner.setGravity(Gravity.CENTER_VERTICAL);
        inner.setPadding(Ui.dp(this, 12), Ui.dp(this, 12), Ui.dp(this, 12), Ui.dp(this, 12));
        inner.setBackground(Ui.round(conditionFieldColor(), Ui.dp(this, 14)));
        inner.setClickable(true);
        inner.setFocusable(true);

        LinearLayout textStack = Ui.v(this, 2);
        textStack.addView(Ui.text(this, i18n.t("Select category"), 14, AppColors.MUTED, android.graphics.Typeface.BOLD), Ui.matchWrap());
        TextView value = Ui.text(this, conditionCategorySummary(selected), 20, AppColors.TEXT, android.graphics.Typeface.BOLD);
        value.setSingleLine(false);
        textStack.addView(value, Ui.matchWrap());
        inner.addView(textStack, new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1));
        inner.addView(Ui.text(this, expanded ? "⌃" : "⌄", 30, AppColors.MUTED, android.graphics.Typeface.BOLD), Ui.wrapWrap());
        inner.setOnClickListener(v -> onToggle.run());
        card.addView(inner, Ui.matchWrap());

        if (expanded) {
            Ui.addSpacer(this, card, 16);
            for (String[] option : DIAGNOSIS_OPTIONS) {
                card.addView(conditionCategoryOptionRow(option, selected, onChanged), Ui.matchWrap());
                Ui.addSpacer(this, card, 8);
            }
        }
        return card;
    }

    private LinearLayout conditionCategoryOptionRow(String[] option, Set<String> selected, Runnable onChanged) {
        String id = option[0];
        boolean isSelected = selected.contains(id);
        LinearLayout row = Ui.h(this, 0);
        row.setGravity(Gravity.CENTER_VERTICAL);
        row.setPadding(Ui.dp(this, 12), Ui.dp(this, 11), Ui.dp(this, 12), Ui.dp(this, 11));
        row.setBackground(Ui.stroke(isSelected ? Ui.withAlpha(AppColors.ACCENT, 24) : AppColors.PANEL, AppColors.BORDER, Ui.dp(this, 14)));
        row.setClickable(true);
        row.setFocusable(true);

        CheckBox box = new CheckBox(this);
        box.setChecked(isSelected);
        box.setClickable(false);
        box.setButtonTintList(android.content.res.ColorStateList.valueOf(isSelected ? AppColors.ACCENT : AppColors.MUTED));
        row.addView(box, Ui.fixed(this, 38, 38));

        TextView icon = Ui.text(this, diagnosisIcon(id), 22, AppColors.TEXT, android.graphics.Typeface.NORMAL);
        icon.setGravity(Gravity.CENTER);
        row.addView(icon, Ui.fixed(this, 36, 36));

        TextView label = Ui.text(this, i18n.t(option[1]), 16, AppColors.TEXT, android.graphics.Typeface.BOLD);
        LinearLayout.LayoutParams labelParams = new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1);
        labelParams.leftMargin = Ui.dp(this, 8);
        row.addView(label, labelParams);

        row.setOnClickListener(v -> {
            if (selected.contains(id)) selected.remove(id);
            else selected.add(id);
            if (onChanged != null) onChanged.run();
        });
        return row;
    }

    private LinearLayout conditionInputCard(String title, EditText input) {
        LinearLayout card = conditionFormCard();
        card.addView(Ui.text(this, title, 19, AppColors.TEXT, android.graphics.Typeface.BOLD), Ui.matchWrap());
        Ui.addSpacer(this, card, 12);
        styleConditionInput(input);
        card.addView(input, Ui.matchWrap());
        return card;
    }

    private LinearLayout conditionPhotoCard(String[] photoData, Runnable onPhotoChanged) {
        LinearLayout card = conditionFormCard();
        card.addView(Ui.text(this, i18n.t("Photos"), 19, AppColors.TEXT, android.graphics.Typeface.BOLD), Ui.matchWrap());
        Ui.addSpacer(this, card, 12);

        TextView status = Ui.muted(this, i18n.t("Photo selected"));
        status.setVisibility(photoData[0].isEmpty() ? View.GONE : View.VISIBLE);
        card.addView(status, Ui.matchWrap());
        if (!photoData[0].isEmpty()) Ui.addSpacer(this, card, 10);

        LinearLayout row = Ui.h(this, 0);
        View camera = conditionPhotoAction(R.drawable.ios_icon_camera_fill, i18n.t("Take Photo"));
        View upload = conditionPhotoAction(R.drawable.ios_icon_photo_stack, i18n.t("Upload Photo"));
        camera.setOnClickListener(v -> {
            takeGenericPhoto(photoData, status);
            if (onPhotoChanged != null) onPhotoChanged.run();
        });
        upload.setOnClickListener(v -> {
            chooseGenericPhoto(photoData, status);
            if (onPhotoChanged != null) onPhotoChanged.run();
        });

        LinearLayout.LayoutParams left = new LinearLayout.LayoutParams(0, Ui.dp(this, 92), 1);
        left.rightMargin = Ui.dp(this, 10);
        row.addView(camera, left);
        row.addView(upload, new LinearLayout.LayoutParams(0, Ui.dp(this, 92), 1));
        card.addView(row, Ui.matchWrap());
        return card;
    }

    private View conditionPhotoAction(int iconRes, String title) {
        LinearLayout action = Ui.v(this, 7);
        action.setGravity(Gravity.CENTER);
        action.setBackground(Ui.round(Ui.withAlpha(AppColors.ACCENT, 18), Ui.dp(this, 14)));
        action.setClickable(true);
        action.setFocusable(true);
        action.addView(symbolIcon(iconRes, AppColors.ACCENT, Color.TRANSPARENT, 32, 3), Ui.fixed(this, 34, 34));
        action.addView(Ui.text(this, title, 15, AppColors.ACCENT, android.graphics.Typeface.BOLD), Ui.wrapWrap());
        return action;
    }

    private int conditionFieldColor() {
        return Color.rgb(246, 248, 246);
    }

    private void styleConditionInput(EditText input) {
        input.setTextColor(AppColors.TEXT);
        input.setHintTextColor(Ui.withAlpha(AppColors.MUTED, 135));
        input.setTextSize(18);
        boolean multiline = input.getMinLines() > 1;
        input.setPadding(Ui.dp(this, 16), multiline ? Ui.dp(this, 14) : 0, Ui.dp(this, 16), multiline ? Ui.dp(this, 14) : 0);
        input.setMinHeight(Ui.dp(this, multiline ? 150 : 62));
        input.setBackground(Ui.round(conditionFieldColor(), Ui.dp(this, 14)));
    }

    private void addConditionTextWatcher(EditText input, Runnable afterChange) {
        input.addTextChangedListener(new TextWatcher() {
            @Override
            public void beforeTextChanged(CharSequence s, int start, int count, int after) {
            }

            @Override
            public void onTextChanged(CharSequence s, int start, int before, int count) {
                if (afterChange != null) afterChange.run();
            }

            @Override
            public void afterTextChanged(Editable s) {
            }
        });
    }

    private void updateConditionSaveButton(Button save, EditText name) {
        boolean enabled = !name.getText().toString().trim().isEmpty();
        save.setEnabled(enabled);
        save.setTextColor(AppColors.PANEL);
        save.setBackground(Ui.stroke(enabled ? AppColors.ACCENT : Color.rgb(205, 211, 207), enabled ? AppColors.ACCENT : Color.rgb(205, 211, 207), Ui.dp(this, 12)));
        save.setAlpha(enabled ? 1.0f : 0.75f);
    }

    private void showConditionCategoryDialog(Set<String> selected, Runnable onChanged) {
        boolean[] checked = new boolean[DIAGNOSIS_OPTIONS.length];
        LinearLayout content = Ui.v(this, 0);
        content.setPadding(Ui.dp(this, 6), 0, Ui.dp(this, 6), 0);
        for (int i = 0; i < DIAGNOSIS_OPTIONS.length; i++) {
            checked[i] = selected.contains(DIAGNOSIS_OPTIONS[i][0]);
            final int index = i;
            LinearLayout row = Ui.h(this, 0);
            row.setGravity(Gravity.CENTER_VERTICAL);
            row.setPadding(Ui.dp(this, 14), Ui.dp(this, 12), Ui.dp(this, 14), Ui.dp(this, 12));
            row.setBackground(Ui.stroke(checked[i] ? Ui.withAlpha(AppColors.ACCENT, 28) : AppColors.PANEL, AppColors.BORDER, Ui.dp(this, 14)));
            row.setClickable(true);
            row.setFocusable(true);
            CheckBox box = new CheckBox(this);
            box.setChecked(checked[i]);
            box.setClickable(false);
            box.setButtonTintList(android.content.res.ColorStateList.valueOf(AppColors.ACCENT));
            row.addView(box, Ui.fixed(this, 42, 42));
            String labelText = diagnosisIcon(DIAGNOSIS_OPTIONS[i][0]) + "  " + i18n.t(DIAGNOSIS_OPTIONS[i][1]);
            row.addView(Ui.text(this, labelText, 16, AppColors.TEXT, android.graphics.Typeface.BOLD), new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1));
            row.setOnClickListener(v -> {
                checked[index] = !checked[index];
                box.setChecked(checked[index]);
                row.setBackground(Ui.stroke(checked[index] ? Ui.withAlpha(AppColors.ACCENT, 28) : AppColors.PANEL, AppColors.BORDER, Ui.dp(this, 14)));
            });
            content.addView(row, Ui.matchWrap());
            Ui.addSpacer(this, content, 8);
        }
        Ui.dialog(this, i18n.t("Select category"), content, i18n.t("Done"), () -> {
            selected.clear();
            for (int i = 0; i < checked.length; i++) {
                if (checked[i]) selected.add(DIAGNOSIS_OPTIONS[i][0]);
            }
            if (onChanged != null) onChanged.run();
        });
    }

    private String conditionCategorySummary(Set<String> selected) {
        List<String> labels = new ArrayList<>();
        for (String[] option : DIAGNOSIS_OPTIONS) {
            if (selected.contains(option[0])) {
                labels.add(diagnosisIcon(option[0]) + " " + i18n.t(option[1]));
            }
        }
        if (labels.isEmpty()) return i18n.t("Select category");
        StringBuilder builder = new StringBuilder();
        for (String label : labels) {
            if (builder.length() > 0) builder.append(", ");
            builder.append(label);
        }
        return builder.toString();
    }

    private void mergeDiagnosisSelections(Set<String> ids) {
        if (ids.isEmpty()) return;
        String key = storage.key("diagnosis", currentUser.id, "selectedOptions");
        Set<String> merged = new LinkedHashSet<>(commaSet(storage.getString(key, "")));
        merged.addAll(ids);
        List<String> ordered = new ArrayList<>();
        for (String[] option : DIAGNOSIS_OPTIONS) {
            if (merged.contains(option[0])) ordered.add(option[0]);
        }
        storage.putString(key, joinIds(ordered));
    }

    private void showDoctorVisitDialog() {
        LinearLayout content = Ui.v(this, 0);
        content.setPadding(Ui.dp(this, 12), 0, Ui.dp(this, 12), 0);
        EditText clinic = Ui.edit(this, "Clinic / Doctor");
        EditText date = Ui.edit(this, "Date");
        date.setText(todayKey());
        EditText notes = Ui.multi(this, "Notes");
        String[] photoData = {""};
        content.addView(Ui.fieldGroup(this, "Clinic / Doctor", clinic), Ui.matchWrap());
        Ui.addSpacer(this, content, 12);
        content.addView(Ui.fieldGroup(this, "Date", date), Ui.matchWrap());
        Ui.addSpacer(this, content, 12);
        content.addView(Ui.fieldGroup(this, "Notes", notes), Ui.matchWrap());
        Ui.addSpacer(this, content, 12);
        content.addView(photoControls("Documents / Photos", photoData), Ui.matchWrap());
        Ui.dialog(this, i18n.t("Doctor Visit"), content, i18n.t("Save"), () -> {
            JSONArray visits = storage.getArray(storage.key("diagnosis", currentUser.id, "doctorVisits"));
            JSONObject visit = new JSONObject();
            try {
                visit.put("clinic", clinic.getText().toString().trim());
                visit.put("date", date.getText().toString().trim());
                visit.put("notes", notes.getText().toString().trim());
                if (!photoData[0].isEmpty()) visit.put("imageData", photoData[0]);
            } catch (JSONException ignored) {
            }
            visits.put(visit);
            storage.putArray(storage.key("diagnosis", currentUser.id, "doctorVisits"), visits);
            render();
        });
    }

    private void showQuickLogPicker() {
        String key = storage.key("health", currentUser.id, "quickLogSelection");
        Set<String> selected = commaSet(storage.getString(key, ""));
        boolean[] checked = new boolean[QUICK_LOGS.length];
        LinearLayout content = Ui.v(this, 0);
        content.setPadding(Ui.dp(this, 12), 0, Ui.dp(this, 12), 0);
        for (int i = 0; i < QUICK_LOGS.length; i++) {
            checked[i] = selected.contains(QUICK_LOGS[i][0]);
            final int index = i;
            LinearLayout row = Ui.h(this, 0);
            row.setGravity(Gravity.CENTER_VERTICAL);
            row.setPadding(Ui.dp(this, 14), Ui.dp(this, 12), Ui.dp(this, 14), Ui.dp(this, 12));
            row.setBackground(Ui.stroke(checked[i] ? Ui.withAlpha(AppColors.ACCENT, 28) : AppColors.PANEL, AppColors.BORDER, Ui.dp(this, 14)));
            row.setClickable(true);
            row.setFocusable(true);
            ImageView icon = symbolIcon(quickLogIconRes(QUICK_LOGS[i][0]), AppColors.TEXT, Color.TRANSPARENT, 34, 4);
            row.addView(icon, Ui.fixed(this, 40, 40));
            TextView label = Ui.text(this, i18n.t(QUICK_LOGS[i][1]), 16, AppColors.TEXT, android.graphics.Typeface.BOLD);
            LinearLayout.LayoutParams labelParams = new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1);
            labelParams.leftMargin = Ui.dp(this, 10);
            row.addView(label, labelParams);
            CheckBox box = new CheckBox(this);
            box.setChecked(checked[i]);
            box.setClickable(false);
            box.setButtonTintList(android.content.res.ColorStateList.valueOf(AppColors.ACCENT));
            row.addView(box, Ui.fixed(this, 42, 42));
            row.setOnClickListener(v -> {
                checked[index] = !checked[index];
                box.setChecked(checked[index]);
                row.setBackground(Ui.stroke(checked[index] ? Ui.withAlpha(AppColors.ACCENT, 28) : AppColors.PANEL, AppColors.BORDER, Ui.dp(this, 14)));
            });
            content.addView(row, Ui.matchWrap());
            Ui.addSpacer(this, content, 8);
        }
        Ui.dialog(this, i18n.t("Choose quick-log buttons"), content, i18n.t("Save"), () -> {
            List<String> ordered = orderedQuickLogIds(storage.getString(key, ""));
            List<String> updated = new ArrayList<>();
            Set<String> added = new HashSet<>();
            for (String id : ordered) {
                int optionIndex = quickLogIndex(id);
                if (optionIndex >= 0 && checked[optionIndex]) {
                    updated.add(id);
                    added.add(id);
                }
            }
            for (int i = 0; i < checked.length; i++) {
                String id = QUICK_LOGS[i][0];
                if (checked[i] && !added.contains(id)) {
                    updated.add(id);
                }
            }
            storage.putString(key, joinIds(updated));
            render();
        });
    }

    private int quickLogIndex(String id) {
        for (int i = 0; i < QUICK_LOGS.length; i++) {
            if (QUICK_LOGS[i][0].equals(id)) return i;
        }
        return -1;
    }

    private void showHealthLogDialog(String id, String title, String type) {
        if ("sleep".equals(id)) {
            showSleepLogDialog(title);
            return;
        }
        if ("digestion".equals(id)) {
            showDigestionLogDialog(title);
            return;
        }
        if ("quickLog".equals(type)) {
            switch (id) {
                case "seizure":
                    showSeizureTimerDialog(title);
                    return;
                case "meltdown":
                    showMeltdownDialog(title);
                    return;
                case "stimming":
                    showStimmingDialog(title);
                    return;
                case "accident":
                    showAccidentDialog(title);
                    return;
                case "deescalation":
                    showDeescalationDialog(title);
                    return;
                case "allergy":
                    showAllergyDialog(title);
                    return;
                case "pain":
                    showPainDialog(title);
                    return;
                case "skin":
                    showSkinDialog(title);
                    return;
                case "discomfort":
                    showDiscomfortDialog(title);
                    return;
                case "medsFood":
                    showMedicineDialog(title);
                    return;
                case "cyclicVomiting":
                    showCyclicVomitingDialog(title);
                    return;
                default:
                    break;
            }
        }
        LinearLayout content = Ui.v(this, 0);
        content.setPadding(Ui.dp(this, 12), 0, Ui.dp(this, 12), 0);
        Calendar timestamp = Calendar.getInstance();
        content.addView(timestampCard(timestamp), Ui.matchWrap());
        Ui.addSpacer(this, content, 12);
        EditText value = Ui.edit(this, i18n.t(title));
        if ("height".equals(id) || "weight".equals(id)) {
            value.setInputType(InputType.TYPE_CLASS_NUMBER | InputType.TYPE_NUMBER_FLAG_DECIMAL);
        }
        EditText notes = Ui.multi(this, "Notes");
        content.addView(Ui.fieldGroup(this, i18n.t(title), value), Ui.matchWrap());
        Ui.addSpacer(this, content, 12);
        content.addView(Ui.fieldGroup(this, "Notes", notes), Ui.matchWrap());
        Ui.dialog(this, i18n.t(title), content, i18n.t("Save"), () -> {
            String cleanValue = value.getText().toString().trim();
            addHealthEntry(id, title, type, cleanValue.isEmpty() ? i18n.t(title) : cleanValue, notes.getText().toString().trim(), timestamp);
            render();
        });
    }

    private void showSeizureTimerDialog(String title) {
        Calendar timestamp = Calendar.getInstance();
        LinearLayout content = quickFormContent();

        int seizureRed = Color.rgb(248, 82, 82);
        LinearLayout timerCard = Ui.panel(this);
        timerCard.setPadding(Ui.dp(this, 18), Ui.dp(this, 26), Ui.dp(this, 18), Ui.dp(this, 22));
        timerCard.setBackground(Ui.stroke(AppColors.PANEL, Ui.withAlpha(AppColors.BORDER, 150), Ui.dp(this, 20)));

        TextView timerIcon = Ui.text(this, "↻", 44, seizureRed, android.graphics.Typeface.BOLD);
        timerIcon.setGravity(Gravity.CENTER);
        timerIcon.setBackground(Ui.round(Ui.withAlpha(seizureRed, 32), Ui.dp(this, 48)));
        LinearLayout.LayoutParams timerIconParams = Ui.fixed(this, 96, 96);
        timerIconParams.gravity = Gravity.CENTER_HORIZONTAL;
        timerCard.addView(timerIcon, timerIconParams);
        Ui.addSpacer(this, timerCard, 14);

        TextView timerText = Ui.text(this, "00:00", 48, AppColors.TEXT, android.graphics.Typeface.BOLD);
        timerText.setGravity(Gravity.CENTER);
        timerCard.addView(timerText, Ui.matchWrap());
        TextView timerStatus = Ui.text(this, i18n.t("Timer running"), 16, AppColors.MUTED, android.graphics.Typeface.BOLD);
        timerStatus.setGravity(Gravity.CENTER);
        timerCard.addView(timerStatus, Ui.matchWrap());
        Ui.addSpacer(this, timerCard, 18);

        LinearLayout controls = Ui.h(this, 0);
        Button pause = Ui.secondary(this, i18n.t("Pause"));
        Button stop = Ui.secondary(this, i18n.t("Stop"));
        stop.setTextColor(AppColors.PANEL);
        stop.setBackground(Ui.stroke(Color.rgb(255, 54, 64), Color.rgb(255, 54, 64), Ui.dp(this, 14)));
        Button skip = Ui.secondary(this, i18n.t("Skip"));
        LinearLayout.LayoutParams leftControlParams = new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1);
        leftControlParams.setMargins(0, 0, Ui.dp(this, 6), 0);
        LinearLayout.LayoutParams rightControlParams = new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1);
        rightControlParams.setMargins(Ui.dp(this, 6), 0, 0, 0);
        controls.addView(pause, leftControlParams);
        controls.addView(stop, rightControlParams);
        timerCard.addView(controls, Ui.matchWrap());
        Ui.addSpacer(this, timerCard, 8);
        skip.setBackground(Ui.stroke(AppColors.PANEL, Ui.withAlpha(AppColors.BORDER, 110), Ui.dp(this, 14)));
        timerCard.addView(skip, Ui.matchWrap());
        content.addView(timerCard, Ui.matchWrap());
        Ui.addSpacer(this, content, 12);

        LinearLayout details = Ui.v(this, 0);
        details.setVisibility(View.GONE);
        details.addView(timestampCard(timestamp), Ui.matchWrap());
        Ui.addSpacer(this, details, 12);

        LinearLayout durationCard = sectionCard(i18n.t("Edit Duration"));
        LinearLayout editRow = Ui.h(this, 0);
        EditText minutes = Ui.edit(this, i18n.t("Minutes"));
        minutes.setInputType(InputType.TYPE_CLASS_NUMBER);
        minutes.setText("0");
        EditText seconds = Ui.edit(this, i18n.t("Seconds"));
        seconds.setInputType(InputType.TYPE_CLASS_NUMBER);
        seconds.setText("0");
        LinearLayout.LayoutParams durationLeft = new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1);
        durationLeft.setMargins(0, 0, Ui.dp(this, 6), 0);
        LinearLayout.LayoutParams durationRight = new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1);
        durationRight.setMargins(Ui.dp(this, 6), 0, 0, 0);
        editRow.addView(Ui.fieldGroup(this, i18n.t("Minutes"), minutes), durationLeft);
        editRow.addView(Ui.fieldGroup(this, i18n.t("Seconds"), seconds), durationRight);
        durationCard.addView(editRow, Ui.matchWrap());
        details.addView(durationCard, Ui.matchWrap());
        Ui.addSpacer(this, details, 12);

        String[] seizureTypes = {
                i18n.t("Seizure Type"),
                "Tonic-clonic",
                "Absence",
                "Focal",
                "Atonic",
                "Myoclonic",
                i18n.t("Other")
        };
        Spinner typeSpinner = spinner(seizureTypes);
        details.addView(fieldCard(i18n.t("Seizure Type"), typeSpinner), Ui.matchWrap());
        Ui.addSpacer(this, details, 12);
        EditText triggers = Ui.multi(this, i18n.t("flashing lights, missed sleep, heat, illness, etc."));
        details.addView(Ui.fieldGroup(this, i18n.t("Triggers"), triggers), Ui.matchWrap());
        Ui.addSpacer(this, details, 12);
        EditText postNotes = Ui.multi(this, i18n.t("Post-event notes"));
        details.addView(Ui.fieldGroup(this, i18n.t("Post-event notes"), postNotes), Ui.matchWrap());
        content.addView(details, Ui.matchWrap());

        Handler handler = new Handler(Looper.getMainLooper());
        int[] elapsed = {0};
        boolean[] running = {true};
        Runnable[] tick = new Runnable[1];
        tick[0] = () -> {
            if (running[0]) {
                elapsed[0] += 1;
                minutes.setText(String.valueOf(elapsed[0] / 60));
                seconds.setText(String.valueOf(elapsed[0] % 60));
                timerText.setText(durationClock(elapsed[0]));
            }
            handler.postDelayed(tick[0], 1000);
        };

        Dialog dialog = showQuickLogForm(i18n.t(title), content, () -> {
            int totalSeconds = safeInt(minutes.getText().toString()) * 60 + safeInt(seconds.getText().toString());
            String type = String.valueOf(typeSpinner.getSelectedItem());
            String value = durationText(totalSeconds);
            if (!type.equals(i18n.t("Seizure Type"))) {
                value += " · " + type;
            }
            String notes = joinNotes(
                    noteLine(i18n.t("Triggers"), triggers.getText().toString()),
                    noteLine(i18n.t("Post-event notes"), postNotes.getText().toString())
            );
            addHealthEntry("seizure", title, "quickLog", value, notes, timestamp);
            render();
        });
        Runnable revealDetails = () -> {
            if (details.getVisibility() != View.VISIBLE) {
                details.setVisibility(View.VISIBLE);
            }
        };
        pause.setOnClickListener(v -> {
            revealDetails.run();
            running[0] = !running[0];
            pause.setText(i18n.t(running[0] ? "Pause" : "Resume"));
            timerStatus.setText(i18n.t(running[0] ? "Timer running" : "Timer paused"));
        });
        stop.setOnClickListener(v -> {
            revealDetails.run();
            running[0] = false;
            timerStatus.setText(i18n.t("Timer stopped"));
            pause.setText(i18n.t("Resume"));
        });
        skip.setOnClickListener(v -> {
            revealDetails.run();
            running[0] = false;
            elapsed[0] = 0;
            minutes.setText("0");
            seconds.setText("0");
            timerText.setText("00:00");
            timerStatus.setText(i18n.t("Skipped timer"));
            pause.setText(i18n.t("Resume"));
        });
        dialog.setOnDismissListener(d -> handler.removeCallbacks(tick[0]));
        handler.postDelayed(tick[0], 1000);
    }

    private void showMeltdownDialog(String title) {
        Calendar timestamp = Calendar.getInstance();
        int tint = quickLogColor("meltdown");
        LinearLayout content = quickFormContent();
        content.addView(timestampCard(timestamp), Ui.matchWrap());
        Ui.addSpacer(this, content, 12);

        int[] intensity = {3};
        TextView badge = Ui.text(this, "3/5", 16, Color.rgb(220, 145, 26), android.graphics.Typeface.BOLD);
        TextView label = Ui.text(this, i18n.t("Moderate Meltdown"), 14, Color.rgb(220, 145, 26), android.graphics.Typeface.BOLD);
        SeekBar seek = new SeekBar(this);
        seek.setMax(4);
        seek.setProgress(2);
        seek.setOnSeekBarChangeListener(new SimpleSeekListener(progress -> {
            intensity[0] = progress + 1;
            badge.setText(intensity[0] + "/5");
            label.setText(meltdownIntensityText(intensity[0]));
        }));
        tintSeekBar(seek, Color.rgb(247, 190, 54));
        LinearLayout intensityCard = sectionCard("〰 " + i18n.t("Intensity"));
        LinearLayout promptRow = Ui.h(this, 0);
        promptRow.setGravity(Gravity.CENTER_VERTICAL);
        promptRow.addView(Ui.text(this, i18n.t("How intense was it?"), 15, AppColors.MUTED, android.graphics.Typeface.BOLD), new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1));
        badge.setGravity(Gravity.CENTER);
        badge.setBackground(Ui.stroke(Ui.withAlpha(Color.rgb(247, 190, 54), 28), Color.rgb(247, 190, 54), Ui.dp(this, 18)));
        badge.setPadding(Ui.dp(this, 12), Ui.dp(this, 6), Ui.dp(this, 12), Ui.dp(this, 6));
        promptRow.addView(badge, Ui.wrapWrap());
        intensityCard.addView(promptRow, Ui.matchWrap());
        Ui.addSpacer(this, intensityCard, 12);
        intensityCard.addView(seek, Ui.matchWrap());
        Ui.addSpacer(this, intensityCard, 8);
        label.setGravity(Gravity.CENTER);
        label.setBackground(Ui.round(Ui.withAlpha(Color.rgb(247, 190, 54), 24), Ui.dp(this, 18)));
        label.setPadding(Ui.dp(this, 12), Ui.dp(this, 6), Ui.dp(this, 12), Ui.dp(this, 6));
        intensityCard.addView(label, Ui.matchWrap());
        content.addView(intensityCard, Ui.matchWrap());
        Ui.addSpacer(this, content, 12);

        Set<String> triggers = new HashSet<>();
        content.addView(chipSection(i18n.t("Triggers"), new String[]{"🔊 Loud Noise", "👥 Crowds", "🔄 Transitioning", "🍽 Hunger", "🌙 Fatigue", "❔ Unknown"}, triggers, tint), Ui.matchWrap());
        Ui.addSpacer(this, content, 12);
        String[] duration = {""};
        content.addView(singleChoiceSection(i18n.t("Duration"), new String[]{"<5 mins", "5-15 mins", "15-30 mins", "30+ mins"}, duration, tint), Ui.matchWrap());
        Ui.addSpacer(this, content, 12);
        Set<String> calming = new HashSet<>();
        content.addView(chipSection(i18n.t("Calming Tools Tried"), new String[]{"🫶 Deep Pressure", "🎧 Headphones", "💡 Dim Lights", "🛏 Weighted Blanket", "↩ Redirection"}, calming, tint), Ui.matchWrap());
        Ui.addSpacer(this, content, 12);
        EditText notes = Ui.multi(this, i18n.t("Notes"));
        content.addView(Ui.fieldGroup(this, i18n.t("Notes"), notes), Ui.matchWrap());

        showQuickLogForm(i18n.t("Log Meltdown"), content, () -> {
            String value = intensity[0] + "/5 · " + meltdownIntensityText(intensity[0]);
            if (!duration[0].isEmpty()) value += " · " + duration[0];
            String detail = joinNotes(noteLine(i18n.t("Triggers"), joinChoices(triggers)), noteLine(i18n.t("Calming Tools Tried"), joinChoices(calming)), notes.getText().toString().trim());
            addHealthEntry("meltdown", title, "quickLog", value, detail, timestamp);
            render();
        });
    }

    private void showStimmingDialog(String title) {
        Calendar timestamp = Calendar.getInstance();
        int tint = quickLogColor("stimming");
        LinearLayout content = quickFormContent();
        content.addView(timestampCard(timestamp), Ui.matchWrap());
        Ui.addSpacer(this, content, 12);
        Set<String> behaviors = new HashSet<>();
        content.addView(chipSection(i18n.t("Behavior Type"), new String[]{"👋 Hand Flapping", "🔊 Vocal Tics/Sounds", "↔ Rocking", "🚶 Pacing", "👁 Eye Blinking", "🙂 Head Shaking", "💬 Repetitive Phrases"}, behaviors, tint), Ui.matchWrap());
        Ui.addSpacer(this, content, 12);
        String[] frequency = {""};
        content.addView(singleChoiceSection(i18n.t("Frequency"), new String[]{"Low (Occasional)", "Medium (Frequent)", "High (Constant)"}, frequency, tint), Ui.matchWrap());
        Ui.addSpacer(this, content, 12);
        String[] state = {""};
        content.addView(singleChoiceSection(i18n.t("Apparent State"), new String[]{"Joyful/Regulating", "Anxious/Stressed"}, state, tint), Ui.matchWrap());
        Ui.addSpacer(this, content, 12);
        Set<String> context = new HashSet<>();
        content.addView(chipSection(i18n.t("Context / Setting"), new String[]{"🏫 School/Therapy", "📱 Screen Time", "🔄 Transitioning", "🏙 Public Place", "🏠 Relaxing at Home"}, context, tint), Ui.matchWrap());
        Ui.addSpacer(this, content, 12);
        EditText notes = Ui.multi(this, i18n.t("Notes"));
        content.addView(Ui.fieldGroup(this, i18n.t("Notes"), notes), Ui.matchWrap());
        showQuickLogForm(i18n.t(title), content, () -> {
            String value = (frequency[0].isEmpty() ? i18n.t("Stimming/Tics") : frequency[0]) + (state[0].isEmpty() ? "" : " · " + state[0]);
            String detail = joinNotes(noteLine(i18n.t("Behavior Type"), joinChoices(behaviors)), noteLine(i18n.t("Context / Setting"), joinChoices(context)), notes.getText().toString().trim());
            addHealthEntry("stimming", title, "quickLog", value, detail, timestamp);
            render();
        });
    }

    private void showAccidentDialog(String title) {
        Calendar timestamp = Calendar.getInstance();
        int tint = quickLogColor("accident");
        LinearLayout content = quickFormContent();
        content.addView(timestampCard(timestamp), Ui.matchWrap());
        Ui.addSpacer(this, content, 12);
        String[] accidentType = {""};
        content.addView(singleChoiceSection(i18n.t("Accident Type"), new String[]{"Urine", "Stool", "Both"}, accidentType, tint), Ui.matchWrap());
        Ui.addSpacer(this, content, 12);
        Set<String> context = new HashSet<>();
        content.addView(chipSection(i18n.t("Context / Setting"), new String[]{"🎯 Deep in Play", "🚌 On the Bus/Transition", "🏫 School/Therapy", "🛌 During Sleep"}, context, tint), Ui.matchWrap());
        Ui.addSpacer(this, content, 12);
        String[] signaled = {""};
        content.addView(singleChoiceSection(i18n.t("Did they signal or try to go?"), new String[]{"Yes", "No"}, signaled, tint), Ui.matchWrap());
        Ui.addSpacer(this, content, 12);
        EditText notes = Ui.multi(this, i18n.t("Notes"));
        content.addView(Ui.fieldGroup(this, i18n.t("Notes"), notes), Ui.matchWrap());
        showQuickLogForm(i18n.t(title), content, () -> {
            String value = accidentType[0].isEmpty() ? i18n.t("Accident") : accidentType[0];
            String detail = joinNotes(noteLine(i18n.t("Context / Setting"), joinChoices(context)), noteLine(i18n.t("Signaled Beforehand?"), signaled[0]), notes.getText().toString().trim());
            addHealthEntry("accident", title, "quickLog", value, detail, timestamp);
            render();
        });
    }

    private void showDeescalationDialog(String title) {
        Calendar timestamp = Calendar.getInstance();
        int tint = quickLogColor("deescalation");
        LinearLayout content = quickFormContent();
        content.addView(timestampCard(timestamp), Ui.matchWrap());
        Ui.addSpacer(this, content, 12);
        Set<String> tools = new HashSet<>();
        content.addView(chipSection(i18n.t("Tools Used"), new String[]{"🎧 Headphones", "🧱 Deep Pressure", "💡 Dimmed Lights", "🛏 Weighted Blanket", "🔄 Redirection/Distraction", "🧘 Quiet Space"}, tools, tint), Ui.matchWrap());
        Ui.addSpacer(this, content, 12);
        String[] effectiveness = {""};
        content.addView(singleChoiceSection(i18n.t("Effectiveness"), new String[]{"Not Effective", "Somewhat Effective", "Highly Effective"}, effectiveness, tint), Ui.matchWrap());
        Ui.addSpacer(this, content, 12);
        String[] baseline = {""};
        content.addView(singleChoiceSection(i18n.t("Time to Baseline"), new String[]{"<5 mins", "5-15 mins", "15-30 mins", "30+ mins"}, baseline, tint), Ui.matchWrap());
        Ui.addSpacer(this, content, 12);
        EditText notes = Ui.multi(this, i18n.t("Notes"));
        content.addView(Ui.fieldGroup(this, i18n.t("Notes"), notes), Ui.matchWrap());
        showQuickLogForm(i18n.t(title), content, () -> {
            String value = effectiveness[0].isEmpty() ? i18n.t("De-escalation") : effectiveness[0];
            if (!baseline[0].isEmpty()) value += " · " + baseline[0];
            String detail = joinNotes(noteLine(i18n.t("Tools Used"), joinChoices(tools)), notes.getText().toString().trim());
            addHealthEntry("deescalation", title, "quickLog", value, detail, timestamp);
            render();
        });
    }

    private void showAllergyDialog(String title) {
        Calendar timestamp = Calendar.getInstance();
        int tint = quickLogColor("allergy");
        LinearLayout content = quickFormContent();
        content.addView(timestampCard(timestamp), Ui.matchWrap());
        Ui.addSpacer(this, content, 12);
        String[] severity = {""};
        content.addView(singleChoiceSection(i18n.t("Severity Level"), new String[]{"Mild", "Moderate", "Severe"}, severity, tint), Ui.matchWrap());
        Ui.addSpacer(this, content, 12);
        Set<String> triggers = new HashSet<>();
        content.addView(chipSection(i18n.t("Suspected Trigger"), new String[]{"🥣 New Food", "💊 Medication", "🌿 Environmental/Outdoor", "🧼 Detergent/Soap", "🐝 Insect Bite", "❔ Unknown"}, triggers, tint), Ui.matchWrap());
        Ui.addSpacer(this, content, 12);
        Set<String> symptoms = new HashSet<>();
        content.addView(chipSection(i18n.t("Symptoms"), new String[]{"🩹 Hives/Rash", "😣 Itching", "💢 Swelling", "🤢 Vomiting", "😮‍💨 Trouble Breathing", "😢 Irritation/Crying"}, symptoms, tint), Ui.matchWrap());
        Ui.addSpacer(this, content, 12);
        EditText notes = Ui.multi(this, i18n.t("Notes"));
        content.addView(Ui.fieldGroup(this, i18n.t("Notes"), notes), Ui.matchWrap());
        showQuickLogForm(i18n.t(title), content, () -> {
            String value = severity[0].isEmpty() ? i18n.t("Allergic Reaction") : severity[0];
            if (!symptoms.isEmpty()) value += " · " + joinChoices(symptoms);
            String detail = joinNotes(noteLine(i18n.t("Suspected Trigger"), joinChoices(triggers)), notes.getText().toString().trim());
            addHealthEntry("allergy", title, "quickLog", value, detail, timestamp);
            if ("Severe".equals(severity[0]) || joinChoices(symptoms).contains("Trouble Breathing")) {
                showMessageSheet(i18n.t("Seek immediate medical attention"), i18n.t("Severe allergic symptoms can require urgent care or an EpiPen if prescribed."));
            }
            render();
        });
    }

    private void showPainDialog(String title) {
        Calendar timestamp = Calendar.getInstance();
        int tint = quickLogColor("pain");
        LinearLayout content = quickFormContent();
        content.addView(timestampCard(timestamp), Ui.matchWrap());
        Ui.addSpacer(this, content, 12);
        int[] severity = {3};
        TextView badge = Ui.text(this, "3/5", 16, AppColors.ACCENT, android.graphics.Typeface.BOLD);
        SeekBar seek = new SeekBar(this);
        seek.setMax(4);
        seek.setProgress(2);
        seek.setOnSeekBarChangeListener(new SimpleSeekListener(progress -> {
            severity[0] = progress + 1;
            badge.setText(severity[0] + "/5");
        }));
        LinearLayout severityCard = sectionCard("✚ " + i18n.t("Severity"));
        severityCard.addView(badge, Ui.wrapWrap());
        severityCard.addView(seek, Ui.matchWrap());
        content.addView(severityCard, Ui.matchWrap());
        Ui.addSpacer(this, content, 12);
        List<String> locations = new ArrayList<>();
        content.addView(painLocationMap(locations), Ui.matchWrap());
        Ui.addSpacer(this, content, 12);
        EditText indicators = Ui.multi(this, i18n.t("crying, holding head, aggression"));
        content.addView(Ui.fieldGroup(this, i18n.t("Indicators"), indicators), Ui.matchWrap());
        Ui.addSpacer(this, content, 12);
        EditText comments = Ui.multi(this, i18n.t("Short comment"));
        content.addView(Ui.fieldGroup(this, i18n.t("Short comment"), comments), Ui.matchWrap());
        showQuickLogForm(i18n.t(title), content, () -> {
            String value = severity[0] + "/5 · " + (locations.isEmpty() ? i18n.t("Pain") : joinLocationPoints(locations));
            String detail = joinNotes(noteLine(i18n.t("Indicators"), indicators.getText().toString()), comments.getText().toString().trim());
            addHealthEntry("pain", title, "quickLog", value, detail, timestamp);
            render();
        });
    }

    private LinearLayout painLocationMap(List<String> points) {
        LinearLayout card = sectionCard(i18n.t("Pain Location"));
        FrameLayout map = new FrameLayout(this);
        map.setBackground(Ui.round(AppColors.BACKGROUND, Ui.dp(this, 14)));
        ImageView image = new ImageView(this);
        image.setImageResource(R.drawable.pain_location_body);
        image.setScaleType(ImageView.ScaleType.FIT_CENTER);
        image.setAdjustViewBounds(true);
        map.addView(image, new FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, Ui.dp(this, 330), Gravity.CENTER));
        map.setOnTouchListener((view, event) -> {
            if (event.getAction() != MotionEvent.ACTION_UP) return true;
            float x = event.getX();
            float y = event.getY();
            int hitIndex = nearestPainPoint(points, x, y);
            if (hitIndex >= 0) {
                points.remove(hitIndex);
                redrawPainDots(map, points);
                return true;
            }
            if (points.size() >= 5 || !isInsidePainBodyArea(map, x, y)) return true;
            points.add(Math.round(x) + "," + Math.round(y));
            redrawPainDots(map, points);
            return true;
        });
        card.addView(map, Ui.matchWrap());
        return card;
    }

    private int nearestPainPoint(List<String> points, float x, float y) {
        for (int i = 0; i < points.size(); i++) {
            String[] parts = points.get(i).split(",");
            if (parts.length != 2) continue;
            float px = safeInt(parts[0]);
            float py = safeInt(parts[1]);
            double distance = Math.hypot(px - x, py - y);
            if (distance <= Ui.dp(this, 22)) return i;
        }
        return -1;
    }

    private boolean isInsidePainBodyArea(FrameLayout map, float x, float y) {
        int width = Math.max(1, map.getWidth());
        int height = Math.max(1, map.getHeight());
        float nx = x / width;
        float ny = y / height;
        return nx > 0.18f && nx < 0.82f && ny > 0.04f && ny < 0.96f;
    }

    private void redrawPainDots(FrameLayout map, List<String> points) {
        while (map.getChildCount() > 1) {
            map.removeViewAt(1);
        }
        for (String point : points) {
            String[] parts = point.split(",");
            if (parts.length != 2) continue;
            TextView dot = Ui.text(this, "", 1, Color.WHITE, android.graphics.Typeface.BOLD);
            dot.setBackground(Ui.round(quickLogColor("pain"), Ui.dp(this, 8)));
            FrameLayout.LayoutParams params = new FrameLayout.LayoutParams(Ui.dp(this, 16), Ui.dp(this, 16));
            params.leftMargin = safeInt(parts[0]) - Ui.dp(this, 8);
            params.topMargin = safeInt(parts[1]) - Ui.dp(this, 8);
            map.addView(dot, params);
        }
    }

    private String joinLocationPoints(List<String> points) {
        StringBuilder builder = new StringBuilder();
        for (int i = 0; i < points.size(); i++) {
            if (builder.length() > 0) builder.append(", ");
            builder.append(i18n.t("Point")).append(" ").append(i + 1);
        }
        return builder.toString();
    }

    private void showDiscomfortDialog(String title) {
        Calendar timestamp = Calendar.getInstance();
        int tint = quickLogColor("discomfort");
        LinearLayout content = quickFormContent();
        content.addView(timestampCard(timestamp), Ui.matchWrap());
        Ui.addSpacer(this, content, 12);
        int[] severity = {3};
        TextView badge = Ui.text(this, "3/5", 16, tint, android.graphics.Typeface.BOLD);
        SeekBar seek = new SeekBar(this);
        seek.setMax(4);
        seek.setProgress(2);
        seek.setOnSeekBarChangeListener(new SimpleSeekListener(progress -> {
            severity[0] = progress + 1;
            badge.setText(severity[0] + "/5");
        }));
        LinearLayout severityCard = sectionCard("🌡 " + i18n.t("Severity"));
        severityCard.addView(badge, Ui.wrapWrap());
        severityCard.addView(seek, Ui.matchWrap());
        content.addView(severityCard, Ui.matchWrap());
        Ui.addSpacer(this, content, 12);
        Set<String> signs = new HashSet<>();
        content.addView(chipSection(i18n.t("Signs"), new String[]{"😢 Crying", "🫱 Guarding body", "😠 Irritable", "😣 Restless", "🍽 Reduced appetite", "🌙 Sleepy"}, signs, tint), Ui.matchWrap());
        Ui.addSpacer(this, content, 12);
        Set<String> possibleCauses = new HashSet<>();
        content.addView(chipSection(i18n.t("Possible Cause"), new String[]{"🍽 Hunger", "🌙 Fatigue", "🚽 Constipation", "🤒 Illness", "🔥 Heat", "❔ Unknown"}, possibleCauses, tint), Ui.matchWrap());
        Ui.addSpacer(this, content, 12);
        EditText notes = Ui.multi(this, i18n.t("Notes"));
        content.addView(Ui.fieldGroup(this, i18n.t("Notes"), notes), Ui.matchWrap());
        showQuickLogForm(i18n.t(title), content, () -> {
            String value = severity[0] + "/5";
            if (!signs.isEmpty()) value += " · " + joinChoices(signs);
            String detail = joinNotes(noteLine(i18n.t("Possible Cause"), joinChoices(possibleCauses)), notes.getText().toString().trim());
            addHealthEntry("discomfort", title, "quickLog", value, detail, timestamp);
            render();
        });
    }

    private void showSkinDialog(String title) {
        Calendar timestamp = Calendar.getInstance();
        int tint = quickLogColor("skin");
        String[] photoData = {""};
        LinearLayout content = quickFormContent();
        content.addView(photoControls("Skin Photo", photoData), Ui.matchWrap());
        Ui.addSpacer(this, content, 12);
        content.addView(timestampCard(timestamp), Ui.matchWrap());
        Ui.addSpacer(this, content, 12);
        String[] severity = {""};
        content.addView(skinSeveritySection(severity), Ui.matchWrap());
        Ui.addSpacer(this, content, 12);
        Set<String> locations = new HashSet<>();
        content.addView(chipSection(i18n.t("Location"), new String[]{"Face/Neck", "Torso", "Arms", "Legs", "Full Body"}, locations, tint), Ui.matchWrap());
        Ui.addSpacer(this, content, 12);
        Set<String> triggers = new HashSet<>();
        content.addView(chipSection(i18n.t("Suspected Trigger"), new String[]{"New Food", "Medication", "Environmental/Outdoor", "Detergent/Soap", "Unknown"}, triggers, tint), Ui.matchWrap());
        Ui.addSpacer(this, content, 12);
        Set<String> symptoms = new HashSet<>();
        content.addView(chipSection(i18n.t("Symptom Tags"), new String[]{"Itching/Scratching", "Heat/Feverish skin", "Swelling", "Irritation/Crying"}, symptoms, tint), Ui.matchWrap());
        Ui.addSpacer(this, content, 12);
        EditText notes = Ui.multi(this, i18n.t("Notes"));
        content.addView(Ui.fieldGroup(this, i18n.t("Notes"), notes), Ui.matchWrap());
        showQuickLogForm(i18n.t(title), content, () -> {
            String value = severity[0].isEmpty() ? i18n.t("Skin") : severity[0];
            if (!locations.isEmpty()) value += " · " + joinChoices(locations);
            String detail = joinNotes(noteLine(i18n.t("Suspected Trigger"), joinChoices(triggers)), noteLine(i18n.t("Symptom Tags"), joinChoices(symptoms)), photoData[0].isEmpty() ? "" : i18n.t("Photo attached"), notes.getText().toString().trim());
            addHealthEntry("skin", title, "quickLog", value, detail, timestamp, photoData[0]);
            if ("Severe".equals(severity[0])) {
                showMessageSheet(i18n.t("Seek immediate medical attention"), i18n.t("Severe skin symptoms can require urgent care or an EpiPen if prescribed."));
            }
            render();
        });
    }

    private LinearLayout skinSeveritySection(String[] selected) {
        LinearLayout card = sectionCard(i18n.t("Severity Level"));
        LinearLayout rows = Ui.v(this, 0);
        String[][] options = {
                {"Mild", "Localized redness, slight itch, isolated spots", String.valueOf(Color.rgb(103, 199, 137))},
                {"Moderate", "Spreading hives, widespread rash, significant scratching", String.valueOf(Color.rgb(247, 181, 57))},
                {"Severe", "Rapidly spreading, swelling of face/lips", String.valueOf(Color.rgb(239, 58, 58))}
        };
        List<LinearLayout> rowViews = new ArrayList<>();
        for (String[] option : options) {
            LinearLayout row = Ui.h(this, 0);
            row.setGravity(Gravity.CENTER_VERTICAL);
            row.setPadding(Ui.dp(this, 14), Ui.dp(this, 12), Ui.dp(this, 14), Ui.dp(this, 12));
            row.setBackground(Ui.round(AppColors.FIELD, Ui.dp(this, 18)));

            TextView dot = Ui.text(this, "", 1, Color.WHITE, android.graphics.Typeface.BOLD);
            dot.setBackground(Ui.round(Integer.parseInt(option[2]), Ui.dp(this, 6)));
            row.addView(dot, Ui.fixed(this, 12, 12));
            Ui.addSpacerHorizontal(this, row, 12);

            LinearLayout copy = Ui.v(this, 0);
            copy.addView(Ui.text(this, i18n.t(option[0]), 17, AppColors.TEXT, android.graphics.Typeface.BOLD), Ui.matchWrap());
            copy.addView(Ui.text(this, i18n.t(option[1]), 13, AppColors.MUTED, android.graphics.Typeface.BOLD), Ui.matchWrap());
            row.addView(copy, new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1));

            TextView radio = Ui.text(this, "○", 26, AppColors.MUTED, android.graphics.Typeface.BOLD);
            radio.setGravity(Gravity.CENTER);
            row.addView(radio, Ui.fixed(this, 34, 34));

            row.setOnClickListener(v -> {
                selected[0] = option[0].equals(selected[0]) ? "" : option[0];
                for (LinearLayout rowView : rowViews) {
                    String[] meta = (String[]) rowView.getTag();
                    String value = meta[0];
                    int rowColor = Integer.parseInt(meta[1]);
                    boolean isSelected = value.equals(selected[0]);
                    rowView.setBackground(Ui.stroke(isSelected ? Ui.withAlpha(rowColor, 28) : AppColors.FIELD, isSelected ? rowColor : AppColors.FIELD, Ui.dp(this, 18)));
                    TextView mark = (TextView) rowView.getChildAt(3);
                    mark.setText(isSelected ? "●" : "○");
                    mark.setTextColor(isSelected ? rowColor : AppColors.MUTED);
                }
            });
            row.setTag(new String[]{option[0], option[2]});
            rowViews.add(row);
            rows.addView(row, Ui.matchWrap());
            Ui.addSpacer(this, rows, 10);
        }
        card.addView(rows, Ui.matchWrap());
        return card;
    }

    private void showMedicineDialog(String title) {
        Calendar timestamp = Calendar.getInstance();
        LinearLayout content = quickFormContent();
        TextView date = Ui.text(this, new SimpleDateFormat("EEEE, MMM d, yyyy", Locale.getDefault()).format(timestamp.getTime()), 16, AppColors.TEXT, android.graphics.Typeface.BOLD);
        content.addView(date, Ui.matchWrap());
        Ui.addSpacer(this, content, 12);
        Button add = Ui.secondary(this, "+ " + i18n.t("Add Medicine"));
        content.addView(add, Ui.matchWrap());
        Ui.addSpacer(this, content, 12);
        JSONArray meds = storage.getArray(storage.key("health", currentUser.id, "androidMedicines"));
        Set<String> checked = new HashSet<>();
        LinearLayout list = Ui.v(this, 0);
        if (meds.length() == 0) {
            list.addView(Ui.muted(this, i18n.t("None")), Ui.matchWrap());
        } else {
            List<JSONObject> rows = medicineDoseRows(meds);
            for (JSONObject row : rows) {
                String doseId = row.optString("id");
                CheckBox box = Ui.check(this, row.optString("time", "") + "  " + medicineDoseLabel(row));
                box.setOnCheckedChangeListener((buttonView, isChecked) -> {
                    if (isChecked) checked.add(doseId); else checked.remove(doseId);
                });
                list.addView(box, Ui.matchWrap());
                Ui.addSpacer(this, list, 8);
            }
        }
        content.addView(sectionCardWithChild(i18n.t("Today's Medicines"), list), Ui.matchWrap());
        add.setOnClickListener(v -> showAddMedicineDialog(() -> {
            showMedicineDialog(title);
        }));
        showQuickLogForm(i18n.t(title), content, () -> {
            JSONArray currentMeds = storage.getArray(storage.key("health", currentUser.id, "androidMedicines"));
            StringBuilder value = new StringBuilder();
            List<JSONObject> rows = medicineDoseRows(currentMeds);
            for (JSONObject row : rows) {
                String doseId = row.optString("id");
                if (value.length() > 0) value.append("\n");
                value.append(checked.contains(doseId) ? "Checked - " : "Not checked - ");
                value.append(row.optString("time", "")).append(" ").append(medicineDoseLabel(row));
            }
            addHealthEntry("medsFood", title, "quickLog", value.length() == 0 ? i18n.t("None") : value.toString(), "", timestamp);
            render();
        });
    }

    private void showAddMedicineDialog(Runnable afterSave) {
        LinearLayout content = quickFormContent();
        EditText name = Ui.edit(this, i18n.t("Medicine Name"));
        EditText dose = Ui.edit(this, i18n.t("Dose"));
        content.addView(Ui.fieldGroup(this, i18n.t("Medicine Name"), name), Ui.matchWrap());
        Ui.addSpacer(this, content, 12);
        content.addView(Ui.fieldGroup(this, i18n.t("Dose"), dose), Ui.matchWrap());
        Ui.addSpacer(this, content, 12);
        Spinner frequency = spinner(new String[]{
                i18n.t("Frequency"),
                i18n.t("Daily"),
                i18n.t("Every X days"),
                i18n.t("Certain days of the week")
        });
        content.addView(fieldCard(i18n.t("Frequency"), frequency), Ui.matchWrap());
        Ui.addSpacer(this, content, 12);

        EditText everyDays = Ui.edit(this, i18n.t("Every how many days?"));
        everyDays.setInputType(InputType.TYPE_CLASS_NUMBER);
        View everyDaysCard = Ui.fieldGroup(this, i18n.t("Every how many days?"), everyDays);
        everyDaysCard.setVisibility(View.GONE);
        content.addView(everyDaysCard, Ui.matchWrap());
        Ui.addSpacer(this, content, 12);

        Set<String> selectedDays = new HashSet<>();
        View daysCard = chipSection(i18n.t("Days of the week"), new String[]{"Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"}, selectedDays, AppColors.ACCENT);
        daysCard.setVisibility(View.GONE);
        content.addView(daysCard, Ui.matchWrap());
        Ui.addSpacer(this, content, 12);

        Spinner timesPerDay = spinner(new String[]{
                i18n.t("What Time?"),
                i18n.t("Once a day"),
                i18n.t("Twice a day"),
                i18n.t("Three times a day"),
                i18n.t("Multiple times a day")
        });
        content.addView(fieldCard(i18n.t("What Time?"), timesPerDay), Ui.matchWrap());
        Ui.addSpacer(this, content, 12);

        LinearLayout doseTimes = Ui.v(this, 0);
        List<Calendar> times = new ArrayList<>();
        times.add(defaultDoseTime(0));
        rebuildMedicineDoseTimes(doseTimes, times);
        content.addView(doseTimes, Ui.matchWrap());
        Ui.addSpacer(this, content, 8);
        TextView maxMessage = Ui.text(this, "", 13, AppColors.DANGER, android.graphics.Typeface.BOLD);
        maxMessage.setVisibility(View.GONE);
        Button addDose = Ui.secondary(this, "+ " + i18n.t("Dose"));
        addDose.setVisibility(View.GONE);
        content.addView(addDose, Ui.matchWrap());
        content.addView(maxMessage, Ui.matchWrap());

        frequency.setOnItemSelectedListener(new AdapterView.OnItemSelectedListener() {
            @Override
            public void onItemSelected(AdapterView<?> parent, View view, int position, long id) {
                String value = String.valueOf(frequency.getSelectedItem());
                everyDaysCard.setVisibility(value.equals(i18n.t("Every X days")) ? View.VISIBLE : View.GONE);
                daysCard.setVisibility(value.equals(i18n.t("Certain days of the week")) ? View.VISIBLE : View.GONE);
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
                if (position == 2) desired = 2;
                if (position == 3) desired = 3;
                if (position == 4) {
                    desired = Math.max(times.size(), 3);
                    multiple = true;
                }
                while (times.size() < desired) times.add(defaultDoseTime(times.size()));
                while (times.size() > desired && !multiple) times.remove(times.size() - 1);
                addDose.setVisibility(multiple ? View.VISIBLE : View.GONE);
                maxMessage.setVisibility(View.GONE);
                rebuildMedicineDoseTimes(doseTimes, times);
            }

            @Override
            public void onNothingSelected(AdapterView<?> parent) {
            }
        });

        addDose.setOnClickListener(v -> {
            if (times.size() >= 10) {
                maxMessage.setText(i18n.t("You hit the max."));
                maxMessage.setVisibility(View.VISIBLE);
                return;
            }
            times.add(defaultDoseTime(times.size()));
            maxMessage.setVisibility(View.GONE);
            rebuildMedicineDoseTimes(doseTimes, times);
        });

        showQuickLogForm(i18n.t("Add Medicine"), content, () -> {
            JSONArray meds = storage.getArray(storage.key("health", currentUser.id, "androidMedicines"));
            JSONObject med = new JSONObject();
            try {
                med.put("id", "med-" + System.currentTimeMillis());
                med.put("name", name.getText().toString().trim().isEmpty() ? i18n.t("Medicine") : name.getText().toString().trim());
                med.put("dose", dose.getText().toString().trim());
                med.put("frequency", String.valueOf(frequency.getSelectedItem()));
                med.put("everyDays", everyDays.getText().toString().trim());
                med.put("days", new JSONArray(selectedDays));
                JSONArray storedTimes = new JSONArray();
                for (Calendar calendar : times) {
                    storedTimes.put(formatDisplayTime(calendar));
                }
                med.put("times", storedTimes);
                med.put("time", storedTimes.length() > 0 ? storedTimes.optString(0) : "");
            } catch (JSONException ignored) {
            }
            meds.put(med);
            storage.putArray(storage.key("health", currentUser.id, "androidMedicines"), meds);
            if (afterSave != null) afterSave.run();
        });
    }

    private Calendar defaultDoseTime(int index) {
        Calendar calendar = Calendar.getInstance();
        calendar.set(Calendar.MINUTE, 0);
        int[] hours = {8, 12, 18};
        calendar.set(Calendar.HOUR_OF_DAY, index < hours.length ? hours[index] : Math.min(22, 8 + index * 2));
        return calendar;
    }

    private void rebuildMedicineDoseTimes(LinearLayout container, List<Calendar> times) {
        container.removeAllViews();
        for (int i = 0; i < times.size(); i++) {
            container.addView(timeOnlyRow(i18n.t("Dose") + " " + (i + 1), times.get(i)), Ui.matchWrap());
            Ui.addSpacer(this, container, 8);
        }
    }

    private List<JSONObject> medicineDoseRows(JSONArray meds) {
        List<JSONObject> rows = new ArrayList<>();
        for (int i = 0; i < meds.length(); i++) {
            JSONObject med = meds.optJSONObject(i);
            if (med == null) continue;
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
        Collections.sort(rows, (left, right) -> Integer.compare(timeSortValue(left.optString("time")), timeSortValue(right.optString("time"))));
        return rows;
    }

    private String medicineDoseLabel(JSONObject row) {
        String dose = row.optString("dose", "").trim();
        return row.optString("name", i18n.t("Medicine")) + (dose.isEmpty() ? "" : " " + dose);
    }

    private int timeSortValue(String time) {
        try {
            Date date = new SimpleDateFormat("h:mm a", Locale.getDefault()).parse(time);
            Calendar calendar = Calendar.getInstance();
            if (date != null) calendar.setTime(date);
            return calendar.get(Calendar.HOUR_OF_DAY) * 60 + calendar.get(Calendar.MINUTE);
        } catch (Exception ignored) {
            return 24 * 60;
        }
    }

    private void showCyclicVomitingDialog(String title) {
        Calendar start = Calendar.getInstance();
        Calendar end = Calendar.getInstance();
        int tint = quickLogColor("cyclicVomiting");
        LinearLayout content = quickFormContent();
        LinearLayout nav = Ui.h(this, 0);
        Button background = Ui.secondary(this, i18n.t("Background"));
        Button patterns = Ui.secondary(this, i18n.t("Vomiting Patterns"));
        nav.addView(background, new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1));
        nav.addView(patterns, new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1));
        content.addView(nav, Ui.matchWrap());
        Ui.addSpacer(this, content, 12);
        background.setOnClickListener(v -> showCyclicVomitingBackgroundDialog());
        patterns.setOnClickListener(v -> showCyclicVomitingPatternsDialog());

        LinearLayout timeCard = sectionCard("⏱ " + i18n.t("Time Tracking"));
        timeCard.addView(timeOnlyRow(i18n.t("Vomiting Start Time"), start), Ui.matchWrap());
        Ui.addSpacer(this, timeCard, 8);
        timeCard.addView(timeOnlyRow(i18n.t("Vomiting End Time"), end), Ui.matchWrap());
        Ui.addSpacer(this, timeCard, 8);
        String[] hospitalized = {""};
        timeCard.addView(singleChoiceSection(i18n.t("Hospitalized for this episode?"), new String[]{"Yes", "No"}, hospitalized, tint), Ui.matchWrap());
        content.addView(timeCard, Ui.matchWrap());
        Ui.addSpacer(this, content, 12);
        Set<String> triggers = new HashSet<>();
        content.addView(chipSection(i18n.t("Triggers before this vomiting episode"), new String[]{"Post-respiratory tract infection", "Post-improper diet", "After riding in a car or other vehicles", "Post-emotional stress/stimulation", "Menstrual period", "None of the above triggers", "Other"}, triggers, tint), Ui.matchWrap());
        Ui.addSpacer(this, content, 12);
        Set<String> before = new HashSet<>();
        content.addView(chipSection(i18n.t("Symptoms before this vomiting episode started"), new String[]{"Nausea", "Pallor", "Sweating", "Lethargy/Somnolence", "Hot flashes", "Headache", "Abdominal pain", "None of the above symptoms", "Other"}, before, tint), Ui.matchWrap());
        Ui.addSpacer(this, content, 12);
        Set<String> during = new HashSet<>();
        content.addView(chipSection(i18n.t("Symptoms during this vomiting episode"), new String[]{"Nausea", "Abdominal pain", "Diarrhea", "Anorexia", "Headache", "Photophobia", "Phonophobia", "Vertigo", "None of the above symptoms", "Other"}, during, tint), Ui.matchWrap());
        Ui.addSpacer(this, content, 12);
        Set<String> recovery = new HashSet<>();
        content.addView(chipSection(i18n.t("Symptoms after vomiting stopped"), new String[]{"Drowsiness", "Deep sleep", "Abdominal pain", "Nausea", "Headache", "Dizziness", "None of the above symptoms", "Other"}, recovery, tint), Ui.matchWrap());
        Ui.addSpacer(this, content, 12);
        EditText acts = Ui.edit(this, i18n.t("Times per Day"));
        acts.setInputType(InputType.TYPE_CLASS_NUMBER);
        content.addView(Ui.fieldGroup(this, i18n.t("Times per Day"), acts), Ui.matchWrap());
        Ui.addSpacer(this, content, 12);
        Set<String> meds = new HashSet<>();
        content.addView(chipSection(i18n.t("Current medications in use"), new String[]{"Cyproheptadine", "Amitriptyline", "Propranolol", "Aprepitant", "Sodium valproate", "Phenobarbital", "Topiramate", "Coenzyme Q10", "L-carnitine", "Omeprazole", "Other", "None"}, meds, tint), Ui.matchWrap());
        Ui.addSpacer(this, content, 12);
        EditText notes = Ui.multi(this, i18n.t("Notes"));
        content.addView(Ui.fieldGroup(this, i18n.t("Notes"), notes), Ui.matchWrap());
        showQuickLogForm(i18n.t(title), content, () -> {
            String value = i18n.t("Vomiting") + " · " + (acts.getText().toString().trim().isEmpty() ? "--" : acts.getText().toString().trim()) + " " + i18n.t("Times per Day");
            if (!hospitalized[0].isEmpty()) value += " · " + i18n.t("Hospitalized") + ": " + hospitalized[0];
            String detail = joinNotes(
                    noteLine(i18n.t("Triggers"), joinChoices(triggers)),
                    noteLine(i18n.t("Before"), joinChoices(before)),
                    noteLine(i18n.t("During"), joinChoices(during)),
                    noteLine(i18n.t("Recovery"), joinChoices(recovery)),
                    noteLine(i18n.t("Current medications in use"), joinChoices(meds)),
                    notes.getText().toString().trim()
            );
            addHealthEntry("cyclicVomiting", title, "quickLog", value, detail, start);
            render();
        });
    }

    private void showCyclicVomitingBackgroundDialog() {
        int tint = quickLogColor("cyclicVomiting");
        String key = storage.key("health", currentUser.id, "cyclicVomitingBackground");
        JSONObject existing = storage.getObject(key);
        LinearLayout content = quickFormContent();
        Set<String> family = jsonArrayToSet(existing.optJSONArray("familyHistory"));
        content.addView(chipSection(i18n.t("Family History") + " · " + i18n.t("Parents, grandparents, siblings etc with following conditions"), new String[]{"Migraine", "Abdominal migraine", "Recurrent vomiting", "Motion sickness", "Functional abdominal pain", "None"}, family, tint), Ui.matchWrap());
        Ui.addSpacer(this, content, 12);
        Set<String> surgeries = jsonArrayToSet(existing.optJSONArray("surgicalHistory"));
        content.addView(chipSection(i18n.t("Surgical History"), new String[]{"Post-tracheoesophageal fistula surgery", "Post-esophageal hiatal hernia surgery", "Post-congenital heart disease surgery", "Post-tethered cord syndrome surgery", "Post-fundoplication", "Post-Hirschsprung's disease surgery", "Other", "None"}, surgeries, tint), Ui.matchWrap());
        Ui.addSpacer(this, content, 12);
        LinearLayout onset = sectionCard(i18n.t("Onset Time of Recurrent Vomiting"));
        EditText year = Ui.edit(this, i18n.t("Year"));
        year.setInputType(InputType.TYPE_CLASS_NUMBER);
        year.setText(existing.optString("onsetYear"));
        EditText month = Ui.edit(this, i18n.t("Month"));
        month.setInputType(InputType.TYPE_CLASS_NUMBER);
        month.setText(existing.optString("onsetMonth"));
        LinearLayout onsetRow = Ui.h(this, 0);
        onsetRow.addView(year, new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1));
        onsetRow.addView(month, new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1));
        onset.addView(onsetRow, Ui.matchWrap());
        content.addView(onset, Ui.matchWrap());
        Ui.addSpacer(this, content, 12);
        Set<String> comorbidities = jsonArrayToSet(existing.optJSONArray("comorbidities"));
        content.addView(chipSection(i18n.t("Comorbidities") + " · " + i18n.t("Other co-existing conditions") + " · " + i18n.t("Multiple choice"), new String[]{"Epilepsy", "Tourette syndrome", "Coffin-Siris syndrome", "Klinefelter 综合征", "Inborn errors of metabolism", "Celiac disease", "Inflammatory bowel disease", "Other", "None of the above"}, comorbidities, tint), Ui.matchWrap());
        Ui.addSpacer(this, content, 12);
        String[] hospitalized = {existing.optString("hospitalizedAtBeijingHospital")};
        content.addView(singleChoiceSection(i18n.t("Have you ever been hospitalized at Beijing Tsinghua Changgung Hospital?"), new String[]{"Yes", "No"}, hospitalized, tint), Ui.matchWrap());
        Ui.addSpacer(this, content, 12);
        Set<String> currentMeds = jsonArrayToSet(existing.optJSONArray("currentMedications"));
        content.addView(chipSection(i18n.t("Current medications in use"), cyclicVomitingMedicineOptions(), currentMeds, tint), Ui.matchWrap());
        Ui.addSpacer(this, content, 12);
        EditText adverse = Ui.multi(this, i18n.t("Adverse drug reactions"));
        adverse.setText(existing.optString("adverseDrugReactionDetails"));
        content.addView(Ui.fieldGroup(this, i18n.t("Adverse drug reactions"), adverse), Ui.matchWrap());
        Ui.addSpacer(this, content, 12);
        Set<String> pastMeds = jsonArrayToSet(existing.optJSONArray("pastMedications"));
        content.addView(chipSection(i18n.t("Past medications used"), cyclicVomitingMedicineOptions(), pastMeds, tint), Ui.matchWrap());
        showQuickLogForm(i18n.t("Background"), content, () -> {
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
            storage.putObject(key, data);
        });
    }

    private void showCyclicVomitingPatternsDialog() {
        int tint = quickLogColor("cyclicVomiting");
        String key = storage.key("health", currentUser.id, "cyclicVomitingPatterns");
        JSONObject existing = storage.getObject(key);
        LinearLayout content = quickFormContent();
        String[] episodes = {existing.optString("episodesPastYear")};
        content.addView(singleChoiceSection(i18n.t("Number of vomiting episodes in the past year"), new String[]{"< 4 times/year", "≥ 4 times/year", "No episodes"}, episodes, tint), Ui.matchWrap());
        Ui.addSpacer(this, content, 12);
        String[] interval = {existing.optString("episodeInterval")};
        content.addView(singleChoiceSection(i18n.t("Interval between vomiting episodes"), new String[]{"> 2 months", "≤ 2 months"}, interval, tint), Ui.matchWrap());
        Ui.addSpacer(this, content, 12);
        String[] duration = {existing.optString("episodeDuration")};
        content.addView(singleChoiceSection(i18n.t("Duration of each vomiting episode"), new String[]{"≤ 2 days", "> 2 days"}, duration, tint), Ui.matchWrap());
        Ui.addSpacer(this, content, 12);
        Set<String> triggers = jsonArrayToSet(existing.optJSONArray("historicalTriggers"));
        content.addView(chipSection(i18n.t("Historical triggers before each vomiting episode"), new String[]{"Post-respiratory tract infection", "Post-improper diet", "After riding in a car or other vehicles", "Post-emotional stress/stimulation", "Menstrual period", "None of the above triggers", "Other"}, triggers, tint), Ui.matchWrap());
        Ui.addSpacer(this, content, 12);
        Set<String> prodrome = jsonArrayToSet(existing.optJSONArray("prodromalSymptoms"));
        content.addView(chipSection(i18n.t("Prodromal Symptoms"), new String[]{"Nausea", "Pallor", "Sweating", "Lethargy/Somnolence", "Hot flashes", "Headache", "Abdominal pain", "None of the above symptoms", "Other"}, prodrome, tint), Ui.matchWrap());
        Ui.addSpacer(this, content, 12);
        Set<String> during = jsonArrayToSet(existing.optJSONArray("episodeSymptoms"));
        content.addView(chipSection(i18n.t("Symptoms during each vomiting episode"), new String[]{"Nausea", "Abdominal pain", "Diarrhea", "Anorexia", "Headache", "Photophobia", "Phonophobia", "Vertigo", "None of the above symptoms", "Other"}, during, tint), Ui.matchWrap());
        Ui.addSpacer(this, content, 12);
        Set<String> post = jsonArrayToSet(existing.optJSONArray("postdromalSymptoms"));
        content.addView(chipSection(i18n.t("Postdromal Symptoms"), new String[]{"Drowsiness", "Deep sleep", "Abdominal pain", "Nausea", "Headache", "Dizziness", "None of the above symptoms", "Other"}, post, tint), Ui.matchWrap());
        Ui.addSpacer(this, content, 12);
        LinearLayout growth = sectionCard(i18n.t("Growth"));
        EditText height = Ui.edit(this, "cm");
        height.setInputType(InputType.TYPE_CLASS_NUMBER | InputType.TYPE_NUMBER_FLAG_DECIMAL);
        height.setText(existing.optString("heightCm"));
        EditText weight = Ui.edit(this, "Kg");
        weight.setInputType(InputType.TYPE_CLASS_NUMBER | InputType.TYPE_NUMBER_FLAG_DECIMAL);
        weight.setText(existing.optString("weightKg"));
        LinearLayout row = Ui.h(this, 0);
        row.addView(height, new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1));
        row.addView(weight, new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1));
        growth.addView(row, Ui.matchWrap());
        content.addView(growth, Ui.matchWrap());
        Ui.addSpacer(this, content, 12);
        String[] age = {existing.optString("qualityOfLifeAgeGroup")};
        content.addView(singleChoiceSection(i18n.t("Current Quality of Life Status"), new String[]{"13–18 years old", "8–12 years old", "5–7 years old", "2–4 years old", "1–12 months"}, age, tint), Ui.matchWrap());
        showQuickLogForm(i18n.t("Vomiting Patterns"), content, () -> {
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
            storage.putObject(key, data);
        });
    }

    private String[] cyclicVomitingMedicineOptions() {
        return new String[]{"Cyproheptadine", "Amitriptyline", "Propranolol", "Aprepitant", "Sodium valproate", "Phenobarbital", "Topiramate", "Coenzyme Q10", "L-carnitine", "Omeprazole", "Other", "None"};
    }

    private Set<String> jsonArrayToSet(JSONArray array) {
        Set<String> set = new HashSet<>();
        if (array == null) return set;
        for (int i = 0; i < array.length(); i++) {
            String value = array.optString(i);
            if (!value.isEmpty()) set.add(value);
        }
        return set;
    }

    private LinearLayout quickFormContent() {
        LinearLayout content = Ui.v(this, 0);
        content.setPadding(Ui.dp(this, 6), 0, Ui.dp(this, 6), Ui.dp(this, 8));
        return content;
    }

    private LinearLayout sectionCard(String title) {
        LinearLayout card = Ui.panel(this);
        card.setPadding(Ui.dp(this, 16), Ui.dp(this, 16), Ui.dp(this, 16), Ui.dp(this, 16));
        card.setBackground(Ui.stroke(AppColors.PANEL, Ui.withAlpha(AppColors.BORDER, 150), Ui.dp(this, 20)));
        card.addView(Ui.text(this, title, 18, AppColors.TEXT, android.graphics.Typeface.BOLD), Ui.matchWrap());
        Ui.addSpacer(this, card, 12);
        return card;
    }

    private LinearLayout sectionCardWithChild(String title, View child) {
        LinearLayout card = sectionCard(title);
        card.addView(child, Ui.matchWrap());
        return card;
    }

    private LinearLayout fieldCard(String title, View child) {
        LinearLayout card = sectionCard(title);
        card.addView(child, Ui.matchWrap());
        return card;
    }

    private Spinner spinner(String[] values) {
        Spinner spinner = new Spinner(this);
        ArrayAdapter<String> adapter = new ArrayAdapter<>(this, android.R.layout.simple_spinner_item, values);
        adapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
        spinner.setAdapter(adapter);
        spinner.setMinimumHeight(Ui.dp(this, 50));
        spinner.setBackground(Ui.stroke(AppColors.FIELD, AppColors.BORDER, Ui.dp(this, 12)));
        return spinner;
    }

    private LinearLayout chipSection(String title, String[] options, Set<String> selected) {
        return chipSection(title, options, selected, AppColors.ACCENT);
    }

    private LinearLayout chipSection(String title, String[] options, Set<String> selected, int color) {
        LinearLayout card = sectionCard(title);
        GridLayout grid = Ui.grid(this, 2);
        for (String option : options) {
            CheckBox chip = Ui.check(this, option);
            chip.setTag(option);
            prepareChoiceChip(chip);
            chip.setOnCheckedChangeListener((buttonView, isChecked) -> {
                if (isChecked) selected.add(option); else selected.remove(option);
                styleChoice(chip, isChecked, color);
            });
            styleChoice(chip, false, color);
            Ui.addGridChild(this, grid, chip, 2);
        }
        card.addView(grid, Ui.matchWrap());
        return card;
    }

    private LinearLayout singleChoiceSection(String title, String[] options, String[] selected) {
        return singleChoiceSection(title, options, selected, AppColors.ACCENT);
    }

    private LinearLayout singleChoiceSection(String title, String[] options, String[] selected, int color) {
        LinearLayout card = sectionCard(title);
        int columns = i18n.t("Frequency").equals(title) ? 1 : Math.min(3, options.length);
        GridLayout grid = Ui.grid(this, columns);
        CheckBox[] boxes = new CheckBox[options.length];
        boolean[] updating = {false};
        for (int i = 0; i < options.length; i++) {
            String option = options[i];
            CheckBox chip = Ui.check(this, option);
            chip.setTag(option);
            prepareChoiceChip(chip);
            boxes[i] = chip;
            int index = i;
            chip.setOnCheckedChangeListener((buttonView, isChecked) -> {
                if (updating[0]) return;
                updating[0] = true;
                if (isChecked) {
                    selected[0] = option;
                    for (int j = 0; j < boxes.length; j++) {
                        if (j != index) boxes[j].setChecked(false);
                        styleChoice(boxes[j], j == index, color);
                    }
                } else if (option.equals(selected[0])) {
                    selected[0] = "";
                    styleChoice(chip, false, color);
                }
                updating[0] = false;
            });
            styleChoice(chip, false, color);
            Ui.addGridChild(this, grid, chip, columns);
        }
        card.addView(grid, Ui.matchWrap());
        return card;
    }

    private void prepareChoiceChip(CheckBox chip) {
        chip.setButtonDrawable(null);
        chip.setGravity(Gravity.CENTER);
        chip.setMinHeight(Ui.dp(this, 44));
        chip.setTextSize(14);
        chip.setSingleLine(false);
        chip.setMaxLines(2);
        chip.setPadding(Ui.dp(this, 10), 0, Ui.dp(this, 10), 0);
    }

    private void styleChoice(CheckBox chip, boolean selected, int color) {
        String label = chip.getTag() instanceof String ? (String) chip.getTag() : chip.getText().toString().replace("✓ ", "");
        chip.setText(selected ? "✓ " + label : label);
        int selectedText = isLightColor(color) ? darkerChoiceColor(color) : color;
        chip.setTextColor(selected ? selectedText : AppColors.TEXT);
        chip.setTypeface(android.graphics.Typeface.DEFAULT, selected ? android.graphics.Typeface.BOLD : android.graphics.Typeface.NORMAL);
        chip.setBackground(Ui.stroke(selected ? Ui.withAlpha(color, 38) : Color.WHITE, selected ? color : Ui.withAlpha(AppColors.BORDER, 150), Ui.dp(this, 18)));
    }

    private int darkerChoiceColor(int color) {
        return Color.rgb(Math.max(0, (int) (Color.red(color) * 0.72)), Math.max(0, (int) (Color.green(color) * 0.72)), Math.max(0, (int) (Color.blue(color) * 0.72)));
    }

    private void tintSeekBar(SeekBar seekBar, int color) {
        seekBar.setProgressTintList(android.content.res.ColorStateList.valueOf(color));
        seekBar.setThumbTintList(android.content.res.ColorStateList.valueOf(Color.WHITE));
        seekBar.setProgressBackgroundTintList(android.content.res.ColorStateList.valueOf(Color.rgb(226, 226, 226)));
    }

    private boolean isLightColor(int color) {
        double luminance = 0.299 * Color.red(color) + 0.587 * Color.green(color) + 0.114 * Color.blue(color);
        return luminance > 175;
    }

    private Dialog showQuickLogForm(String title, LinearLayout content, Runnable onSave) {
        return Ui.dialog(this, title, content, i18n.t("Save Log"), onSave);
    }

    private String joinChoices(Set<String> selected) {
        if (selected == null || selected.isEmpty()) return "";
        StringBuilder builder = new StringBuilder();
        for (String value : selected) {
            if (builder.length() > 0) builder.append(", ");
            builder.append(value);
        }
        return builder.toString();
    }

    private String noteLine(String label, String value) {
        if (value == null || value.trim().isEmpty()) return "";
        return label + ": " + value.trim();
    }

    private String joinNotes(String... parts) {
        StringBuilder builder = new StringBuilder();
        for (String part : parts) {
            if (part == null || part.trim().isEmpty()) continue;
            if (builder.length() > 0) builder.append("\n");
            builder.append(part.trim());
        }
        return builder.toString();
    }

    private int safeInt(String value) {
        try {
            return Integer.parseInt(value.trim());
        } catch (Exception ignored) {
            return 0;
        }
    }

    private String durationClock(int seconds) {
        return String.format(Locale.getDefault(), "%02d:%02d", seconds / 60, seconds % 60);
    }

    private String durationText(int seconds) {
        if (seconds <= 0) return "0 min 0 sec";
        return (seconds / 60) + " min " + (seconds % 60) + " sec";
    }

    private String meltdownIntensityText(int value) {
        if (value <= 1) return i18n.t("Mild Agitation/Crying");
        if (value <= 2) return i18n.t("Mild Meltdown");
        if (value == 3) return i18n.t("Moderate Meltdown");
        if (value == 4) return i18n.t("Strong Meltdown");
        return i18n.t("Severe Meltdown/Safety Risk");
    }

    private interface ProgressCallback {
        void onProgress(int progress);
    }

    private static final class SimpleSeekListener implements SeekBar.OnSeekBarChangeListener {
        private final ProgressCallback callback;

        SimpleSeekListener(ProgressCallback callback) {
            this.callback = callback;
        }

        @Override
        public void onProgressChanged(SeekBar seekBar, int progress, boolean fromUser) {
            if (callback != null) callback.onProgress(progress);
        }

        @Override
        public void onStartTrackingTouch(SeekBar seekBar) {
        }

        @Override
        public void onStopTrackingTouch(SeekBar seekBar) {
        }
    }

    private void showDigestionLogDialog(String title) {
        int tint = snapshotColor("digestion");
        Calendar movementTime = Calendar.getInstance();
        LinearLayout content = quickFormContent();

        content.addView(movementTimeCard(movementTime), Ui.matchWrap());
        Ui.addSpacer(this, content, 12);

        int[] stoolType = {4};
        content.addView(bristolConsistencySection(stoolType, tint), Ui.matchWrap());
        Ui.addSpacer(this, content, 12);

        String[] volume = {"Medium"};
        content.addView(singleChoiceSection(i18n.t("Volume"), new String[]{"Small", "Medium", "Large"}, volume, tint), Ui.matchWrap());
        Ui.addSpacer(this, content, 12);

        String[] stoolColor = {"Brown"};
        content.addView(stoolColorSection(stoolColor, tint), Ui.matchWrap());
        Ui.addSpacer(this, content, 12);

        String[] straining = {""};
        String[] gas = {""};
        String[] undigested = {""};
        LinearLayout painCard = sectionCard(i18n.t("Pain & Strain"));
        painCard.addView(digestionYesNoRow("Straining/Discomfort during the movement?", straining, tint), Ui.matchWrap());
        Ui.addSpacer(this, painCard, 10);
        painCard.addView(digestionYesNoRow("Excessive gas or bloating noticed afterward?", gas, tint), Ui.matchWrap());
        Ui.addSpacer(this, painCard, 10);
        painCard.addView(digestionYesNoRow("Visible undigested food in the stool?", undigested, tint), Ui.matchWrap());
        content.addView(painCard, Ui.matchWrap());

        showQuickLogForm(i18n.t("Gut & Digestion"), content, () -> {
            String group = bristolGroup(stoolType[0]);
            String description = bristolDescription(stoolType[0]);
            String value = i18n.t("Type") + " " + stoolType[0] + " · " + i18n.t(group);
            String detail = joinNotes(
                    noteLine(i18n.t("Time"), formatDisplayTime(movementTime)),
                    noteLine(i18n.t("Consistency"), i18n.t("Type") + " " + stoolType[0] + " - " + i18n.t(description)),
                    noteLine(i18n.t("Volume"), i18n.t(volume[0])),
                    noteLine(i18n.t("Color"), i18n.t(stoolColor[0])),
                    noteLine(i18n.t("Straining/Discomfort"), digestionAnswer(straining[0])),
                    noteLine(i18n.t("Gas/Bloating"), digestionAnswer(gas[0])),
                    noteLine(i18n.t("Undigested Food"), digestionAnswer(undigested[0]))
            );
            addHealthEntry("digestion", title, "snapshot", value, detail, movementTime);
            render();
        });
    }

    private LinearLayout movementTimeCard(Calendar movementTime) {
        LinearLayout card = Ui.h(this, 0);
        card.setGravity(Gravity.CENTER_VERTICAL);
        card.setPadding(Ui.dp(this, 16), Ui.dp(this, 14), Ui.dp(this, 16), Ui.dp(this, 14));
        card.setBackground(Ui.stroke(AppColors.PANEL, Ui.withAlpha(AppColors.BORDER, 150), Ui.dp(this, 20)));
        TextView label = Ui.text(this, i18n.t("Movement time"), 17, AppColors.TEXT, android.graphics.Typeface.BOLD);
        label.setSingleLine(true);
        card.addView(label, new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1));
        Button time = timeButton(movementTime);
        styleTimestampButton(time);
        card.addView(time, Ui.fixed(this, 104, 42));
        return card;
    }

    private LinearLayout bristolConsistencySection(int[] selectedType, int tint) {
        LinearLayout card = sectionCard("");
        card.removeAllViews();
        LinearLayout header = Ui.h(this, 0);
        header.setGravity(Gravity.CENTER_VERTICAL);
        LinearLayout textStack = Ui.v(this, 0);
        textStack.addView(Ui.text(this, i18n.t("Consistency"), 18, AppColors.TEXT, android.graphics.Typeface.BOLD), Ui.matchWrap());
        textStack.addView(Ui.text(this, i18n.t("The Bristol Stool Chart"), 13, AppColors.MUTED, android.graphics.Typeface.BOLD), Ui.matchWrap());
        header.addView(textStack, new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1));
        Button info = Ui.secondary(this, "i");
        info.setTextSize(16);
        info.setTextColor(Color.WHITE);
        info.setMinWidth(0);
        info.setMinHeight(Ui.dp(this, 38));
        info.setBackground(Ui.round(tint, Ui.dp(this, 19)));
        info.setOnClickListener(v -> showBristolInfoSheet(tint));
        header.addView(info, Ui.fixed(this, 38, 38));
        card.addView(header, Ui.matchWrap());
        Ui.addSpacer(this, card, 14);

        HorizontalScrollView scroll = new HorizontalScrollView(this);
        scroll.setHorizontalScrollBarEnabled(false);
        LinearLayout row = Ui.h(this, 0);
        View[] tiles = new View[8];
        for (int type = 1; type <= 7; type++) {
            LinearLayout tile = stoolTypeTile(type, selectedType[0] == type, tint);
            final int finalType = type;
            tile.setOnClickListener(v -> {
                selectedType[0] = finalType;
                for (int i = 1; i <= 7; i++) {
                    styleStoolTypeTile(tiles[i], selectedType[0] == i, tint);
                }
            });
            tiles[type] = tile;
            row.addView(tile, Ui.fixed(this, 120, 132));
            Ui.addSpacerHorizontal(this, row, 10);
        }
        scroll.addView(row, Ui.wrapWrap());
        card.addView(scroll, Ui.matchWrap());
        return card;
    }

    private LinearLayout stoolTypeTile(int type, boolean selected, int tint) {
        LinearLayout tile = Ui.v(this, 0);
        tile.setGravity(Gravity.CENTER);
        tile.setPadding(Ui.dp(this, 10), Ui.dp(this, 10), Ui.dp(this, 10), Ui.dp(this, 10));
        ImageView image = new ImageView(this);
        image.setImageResource(bristolDrawable(type));
        image.setAdjustViewBounds(true);
        image.setScaleType(ImageView.ScaleType.FIT_CENTER);
        tile.addView(image, Ui.fixed(this, 92, 58));
        Ui.addSpacer(this, tile, 8);
        TextView typeLabel = Ui.text(this, i18n.t("Type") + " " + type, 13, AppColors.TEXT, android.graphics.Typeface.BOLD);
        typeLabel.setGravity(Gravity.CENTER);
        tile.addView(typeLabel, Ui.matchWrap());
        TextView group = Ui.text(this, i18n.t(bristolGroup(type)), 12, AppColors.MUTED, android.graphics.Typeface.BOLD);
        group.setGravity(Gravity.CENTER);
        group.setSingleLine(true);
        tile.addView(group, Ui.matchWrap());
        styleStoolTypeTile(tile, selected, tint);
        return tile;
    }

    private void styleStoolTypeTile(View tile, boolean selected, int tint) {
        if (tile == null) return;
        tile.setBackground(Ui.stroke(selected ? Ui.withAlpha(tint, 42) : AppColors.FIELD, selected ? tint : Color.TRANSPARENT, Ui.dp(this, 14)));
    }

    private int bristolDrawable(int type) {
        switch (type) {
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

    private String bristolGroup(int type) {
        if (type <= 2) return "Constipation";
        if (type <= 4) return "Optimal";
        return "Diarrhea/Intolerance";
    }

    private String bristolDescription(int type) {
        switch (type) {
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

    private LinearLayout stoolColorSection(String[] selected, int tint) {
        LinearLayout card = sectionCard(i18n.t("Color Check"));
        GridLayout grid = Ui.grid(this, 5);
        String[][] colors = {
                {"Brown", "#7A4021"},
                {"Green", "#478C40"},
                {"Clay/White", "#E6DBB8"},
                {"Black", "#141210"},
                {"Red", "#BA1F1C"}
        };
        View[] tiles = new View[colors.length];
        for (int i = 0; i < colors.length; i++) {
            String name = colors[i][0];
            int swatch = Color.parseColor(colors[i][1]);
            LinearLayout tile = stoolColorTile(name, swatch, name.equals(selected[0]), tint);
            final int index = i;
            tile.setOnClickListener(v -> {
                selected[0] = colors[index][0];
                for (int j = 0; j < tiles.length; j++) {
                    styleStoolColorTile(tiles[j], colors[j][0].equals(selected[0]), tint);
                }
            });
            tiles[i] = tile;
            Ui.addGridChild(this, grid, tile, 5);
        }
        card.addView(grid, Ui.matchWrap());
        return card;
    }

    private LinearLayout stoolColorTile(String name, int swatch, boolean selected, int tint) {
        LinearLayout tile = Ui.v(this, 0);
        tile.setGravity(Gravity.CENTER);
        tile.setPadding(Ui.dp(this, 6), Ui.dp(this, 8), Ui.dp(this, 6), Ui.dp(this, 8));
        TextView circle = Ui.text(this, "●", 34, swatch, android.graphics.Typeface.BOLD);
        circle.setGravity(Gravity.CENTER);
        tile.addView(circle, Ui.matchWrap());
        TextView label = Ui.text(this, i18n.t(name), 10, AppColors.TEXT, android.graphics.Typeface.BOLD);
        label.setGravity(Gravity.CENTER);
        label.setSingleLine(true);
        tile.addView(label, Ui.matchWrap());
        styleStoolColorTile(tile, selected, tint);
        return tile;
    }

    private void styleStoolColorTile(View tile, boolean selected, int tint) {
        if (tile == null) return;
        tile.setBackground(Ui.stroke(selected ? Ui.withAlpha(tint, 30) : AppColors.FIELD, selected ? tint : Color.TRANSPARENT, Ui.dp(this, 12)));
    }

    private LinearLayout digestionYesNoRow(String title, String[] selected, int tint) {
        LinearLayout row = Ui.v(this, 0);
        row.addView(Ui.text(this, i18n.t(title), 14, AppColors.TEXT, android.graphics.Typeface.BOLD), Ui.matchWrap());
        Ui.addSpacer(this, row, 8);
        LinearLayout buttons = Ui.h(this, 0);
        Button yes = Ui.secondary(this, i18n.t("Yes"));
        Button no = Ui.secondary(this, i18n.t("No"));
        Runnable update = () -> {
            styleToggleButton(yes, "Yes".equals(selected[0]), tint);
            styleToggleButton(no, "No".equals(selected[0]), tint);
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
        buttons.addView(yes, new LinearLayout.LayoutParams(0, Ui.dp(this, 44), 1));
        Ui.addSpacerHorizontal(this, buttons, 10);
        buttons.addView(no, new LinearLayout.LayoutParams(0, Ui.dp(this, 44), 1));
        row.addView(buttons, Ui.matchWrap());
        return row;
    }

    private void styleToggleButton(Button button, boolean selected, int tint) {
        button.setTextColor(selected ? Color.WHITE : AppColors.TEXT);
        button.setBackground(Ui.stroke(selected ? tint : AppColors.FIELD, selected ? tint : Color.TRANSPARENT, Ui.dp(this, 12)));
    }

    private String digestionAnswer(String value) {
        return value == null || value.isEmpty() ? "--" : i18n.t(value);
    }

    private void showBristolInfoSheet(int tint) {
        LinearLayout content = quickFormContent();
        for (int type = 1; type <= 7; type++) {
            LinearLayout row = Ui.h(this, 0);
            row.setGravity(Gravity.CENTER_VERTICAL);
            row.setPadding(Ui.dp(this, 12), Ui.dp(this, 12), Ui.dp(this, 12), Ui.dp(this, 12));
            row.setBackground(Ui.stroke(AppColors.PANEL, Ui.withAlpha(AppColors.BORDER, 130), Ui.dp(this, 14)));
            ImageView image = new ImageView(this);
            image.setImageResource(bristolDrawable(type));
            image.setScaleType(ImageView.ScaleType.FIT_CENTER);
            image.setBackground(Ui.round(Ui.withAlpha(tint, 20), Ui.dp(this, 12)));
            image.setPadding(Ui.dp(this, 8), Ui.dp(this, 8), Ui.dp(this, 8), Ui.dp(this, 8));
            row.addView(image, Ui.fixed(this, 92, 66));
            Ui.addSpacerHorizontal(this, row, 12);
            LinearLayout texts = Ui.v(this, 0);
            texts.addView(Ui.text(this, i18n.t("Type") + " " + type, 16, AppColors.TEXT, android.graphics.Typeface.BOLD), Ui.matchWrap());
            texts.addView(Ui.text(this, i18n.t(bristolGroup(type)), 12, tint, android.graphics.Typeface.BOLD), Ui.matchWrap());
            texts.addView(Ui.muted(this, i18n.t(bristolDescription(type))), Ui.matchWrap());
            row.addView(texts, new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1));
            content.addView(row, Ui.matchWrap());
            Ui.addSpacer(this, content, 10);
        }
        Ui.dialog(this, i18n.t("Bristol Stool Chart"), content, i18n.t("Done"), null);
    }

    private void showSleepLogDialog(String title) {
        LinearLayout content = Ui.v(this, 0);
        content.setPadding(Ui.dp(this, 12), 0, Ui.dp(this, 12), 0);
        Calendar date = Calendar.getInstance();
        Calendar fellAsleep = Calendar.getInstance();
        fellAsleep.add(Calendar.HOUR_OF_DAY, -9);
        Calendar wokeUp = Calendar.getInstance();
        final String[] quality = {"Normal"};
        final int[] wakeups = {0};

        content.addView(sleepTimeCard(date, fellAsleep, wokeUp), Ui.matchWrap());
        Ui.addSpacer(this, content, 12);
        content.addView(sleepQualityCard(quality), Ui.matchWrap());
        Ui.addSpacer(this, content, 12);
        content.addView(wakeCounterCard(wakeups), Ui.matchWrap());
        Ui.addSpacer(this, content, 12);
        EditText notes = Ui.multi(this, i18n.t("Nap, bedtime routine, night waking, comfort item, etc."));
        content.addView(Ui.fieldGroup(this, i18n.t("Notes"), notes), Ui.matchWrap());
        Ui.dialog(this, "🌙 " + i18n.t(title), content, i18n.t("Save"), () -> {
            int minutes = minutesBetween(fellAsleep, wokeUp);
            String value = formatSleepDuration(minutes) + " · " + i18n.t(quality[0]) + " · " + wakeups[0] + " " + i18n.t("wake-ups");
            addHealthEntry("sleep", title, "snapshot", value, notes.getText().toString().trim(), wokeUp);
            render();
        });
    }

    private LinearLayout sleepTimeCard(Calendar date, Calendar fellAsleep, Calendar wokeUp) {
        LinearLayout panel = Ui.panel(this);
        panel.setPadding(Ui.dp(this, 18), Ui.dp(this, 18), Ui.dp(this, 18), Ui.dp(this, 18));
        panel.setBackground(Ui.stroke(AppColors.PANEL, Ui.withAlpha(AppColors.BORDER, 90), Ui.dp(this, 22)));
        panel.addView(Ui.text(this, "🌙 " + i18n.t("Sleep Times"), 18, AppColors.TEXT, android.graphics.Typeface.BOLD), Ui.matchWrap());
        Ui.addSpacer(this, panel, 16);

        Button dateButton = sleepDateButton(date, fellAsleep, wokeUp);
        Button sleepButton = sleepTimeButton(fellAsleep);
        Button wakeButton = sleepTimeButton(wokeUp);
        panel.addView(sleepTimeRow(i18n.t("Date"), dateButton), Ui.matchWrap());
        Ui.addSpacer(this, panel, 12);
        panel.addView(sleepTimeRow(i18n.t("Fell asleep at"), sleepButton), Ui.matchWrap());
        Ui.addSpacer(this, panel, 12);
        panel.addView(sleepTimeRow(i18n.t("Woke up at"), wakeButton), Ui.matchWrap());
        return panel;
    }

    private LinearLayout sleepTimeRow(String label, Button button) {
        LinearLayout row = Ui.h(this, 0);
        row.setGravity(Gravity.CENTER_VERTICAL);
        row.addView(Ui.text(this, label, 15, AppColors.TEXT, android.graphics.Typeface.BOLD), new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1));
        row.addView(button, Ui.fixed(this, 132, 58));
        return row;
    }

    private Button sleepDateButton(Calendar date, Calendar... linked) {
        Button button = sleepPickerButton(formatDisplayDate(date));
        button.setOnClickListener(v -> new DatePickerDialog(this, (view, year, month, day) -> {
            date.set(Calendar.YEAR, year);
            date.set(Calendar.MONTH, month);
            date.set(Calendar.DAY_OF_MONTH, day);
            for (Calendar calendar : linked) {
                calendar.set(Calendar.YEAR, year);
                calendar.set(Calendar.MONTH, month);
                calendar.set(Calendar.DAY_OF_MONTH, day);
            }
            button.setText(formatDisplayDate(date));
        }, date.get(Calendar.YEAR), date.get(Calendar.MONTH), date.get(Calendar.DAY_OF_MONTH)).show());
        return button;
    }

    private Button sleepTimeButton(Calendar calendar) {
        Button button = sleepPickerButton(formatDisplayTime(calendar));
        button.setOnClickListener(v -> new TimePickerDialog(this, (view, hourOfDay, minute) -> {
            calendar.set(Calendar.HOUR_OF_DAY, hourOfDay);
            calendar.set(Calendar.MINUTE, minute);
            button.setText(formatDisplayTime(calendar));
        }, calendar.get(Calendar.HOUR_OF_DAY), calendar.get(Calendar.MINUTE), false).show());
        return button;
    }

    private Button sleepPickerButton(String text) {
        Button button = Ui.secondary(this, text);
        button.setTextSize(17);
        button.setTextColor(AppColors.ACCENT);
        button.setTypeface(android.graphics.Typeface.DEFAULT, android.graphics.Typeface.BOLD);
        button.setPadding(Ui.dp(this, 8), 0, Ui.dp(this, 8), 0);
        button.setMinHeight(Ui.dp(this, 58));
        button.setBackground(Ui.stroke(Color.rgb(226, 237, 233), Ui.withAlpha(AppColors.ACCENT, 70), Ui.dp(this, 16)));
        return button;
    }

    private LinearLayout sleepQualityCard(String[] selectedQuality) {
        LinearLayout panel = Ui.panel(this);
        panel.setPadding(Ui.dp(this, 18), Ui.dp(this, 18), Ui.dp(this, 18), Ui.dp(this, 18));
        panel.setBackground(Ui.stroke(AppColors.PANEL, Ui.withAlpha(AppColors.BORDER, 90), Ui.dp(this, 22)));
        panel.addView(Ui.text(this, i18n.t("Rest Quality"), 20, AppColors.TEXT, android.graphics.Typeface.BOLD), Ui.matchWrap());
        Ui.addSpacer(this, panel, 14);

        LinearLayout row = Ui.h(this, 0);
        row.setGravity(Gravity.CENTER);
        String[][] options = {
                {"😣", "Restless"},
                {"😴", "Normal"},
                {"🌙", "Deep"}
        };
        List<LinearLayout> cards = new ArrayList<>();
        for (String[] option : options) {
            LinearLayout card = sleepQualityOption(option[0], option[1], option[1].equals(selectedQuality[0]));
            cards.add(card);
            card.setOnClickListener(v -> {
                selectedQuality[0] = option[1];
                for (int index = 0; index < cards.size(); index++) {
                    styleSleepQualityOption(cards.get(index), options[index][1].equals(selectedQuality[0]));
                }
            });
            LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(0, Ui.dp(this, 92), 1);
            params.leftMargin = Ui.dp(this, 5);
            params.rightMargin = Ui.dp(this, 5);
            row.addView(card, params);
        }
        panel.addView(row, Ui.matchWrap());
        return panel;
    }

    private LinearLayout sleepQualityOption(String icon, String label, boolean selected) {
        LinearLayout card = Ui.v(this, 0);
        card.setGravity(Gravity.CENTER);
        card.setPadding(Ui.dp(this, 8), Ui.dp(this, 10), Ui.dp(this, 8), Ui.dp(this, 10));
        TextView iconView = Ui.text(this, icon, 26, AppColors.TEXT, android.graphics.Typeface.BOLD);
        iconView.setGravity(Gravity.CENTER);
        card.addView(iconView, Ui.matchWrap());
        TextView labelView = Ui.text(this, i18n.t(label), 15, AppColors.TEXT, android.graphics.Typeface.BOLD);
        labelView.setGravity(Gravity.CENTER);
        card.addView(labelView, Ui.matchWrap());
        styleSleepQualityOption(card, selected);
        return card;
    }

    private void styleSleepQualityOption(LinearLayout card, boolean selected) {
        int fill = selected ? Color.rgb(222, 240, 252) : AppColors.FIELD;
        int border = selected ? Color.rgb(82, 169, 225) : Color.TRANSPARENT;
        card.setBackground(Ui.stroke(fill, border, Ui.dp(this, 16)));
    }

    private LinearLayout wakeCounterCard(int[] wakeups) {
        LinearLayout panel = Ui.panel(this);
        panel.setPadding(Ui.dp(this, 18), Ui.dp(this, 18), Ui.dp(this, 18), Ui.dp(this, 18));
        panel.setBackground(Ui.stroke(AppColors.PANEL, Ui.withAlpha(AppColors.BORDER, 90), Ui.dp(this, 22)));
        panel.addView(Ui.text(this, i18n.t("Waking Counter"), 20, AppColors.TEXT, android.graphics.Typeface.BOLD), Ui.matchWrap());
        Ui.addSpacer(this, panel, 16);

        LinearLayout row = Ui.h(this, 0);
        row.setGravity(Gravity.CENTER_VERTICAL);
        TextView minus = sleepCounterButton("-", Color.rgb(221, 235, 247), Color.rgb(82, 169, 225));
        TextView count = Ui.text(this, String.valueOf(wakeups[0]), 28, AppColors.TEXT, android.graphics.Typeface.BOLD);
        count.setGravity(Gravity.CENTER);
        TextView plus = sleepCounterButton("+", Color.rgb(82, 169, 225), AppColors.PANEL);
        TextView suffix = Ui.text(this, i18n.t("wake-ups"), 17, AppColors.MUTED, android.graphics.Typeface.BOLD);
        suffix.setGravity(Gravity.CENTER_VERTICAL);
        minus.setOnClickListener(v -> {
            wakeups[0] = Math.max(0, wakeups[0] - 1);
            count.setText(String.valueOf(wakeups[0]));
        });
        plus.setOnClickListener(v -> {
            wakeups[0] += 1;
            count.setText(String.valueOf(wakeups[0]));
        });
        row.addView(minus, Ui.fixed(this, 72, 72));
        Ui.addSpacerHorizontal(this, row, 24);
        row.addView(count, Ui.fixed(this, 54, 72));
        Ui.addSpacerHorizontal(this, row, 24);
        row.addView(plus, Ui.fixed(this, 72, 72));
        Ui.addSpacerHorizontal(this, row, 18);
        row.addView(suffix, new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1));
        panel.addView(row, Ui.matchWrap());
        return panel;
    }

    private TextView sleepCounterButton(String text, int fill, int textColor) {
        TextView button = Ui.text(this, text, 28, textColor, android.graphics.Typeface.BOLD);
        button.setGravity(Gravity.CENTER);
        button.setBackground(Ui.round(fill, Ui.dp(this, 36)));
        return button;
    }

    private LinearLayout timestampCard(Calendar timestamp) {
        LinearLayout panel = Ui.panel(this);
        panel.setPadding(Ui.dp(this, 14), Ui.dp(this, 14), Ui.dp(this, 14), Ui.dp(this, 14));
        panel.setBackground(Ui.stroke(AppColors.PANEL, Ui.withAlpha(AppColors.BORDER, 150), Ui.dp(this, 20)));
        LinearLayout row = Ui.h(this, 0);
        row.setGravity(Gravity.CENTER_VERTICAL);
        TextView icon = Ui.text(this, "🗓", 18, AppColors.ACCENT, android.graphics.Typeface.BOLD);
        icon.setGravity(Gravity.CENTER);
        icon.setBackground(Ui.round(Ui.withAlpha(AppColors.ACCENT, 24), Ui.dp(this, 17)));
        row.addView(icon, Ui.fixed(this, 34, 34));
        Ui.addSpacerHorizontal(this, row, 8);
        TextView label = Ui.text(this, i18n.t("Timestamp"), 15, AppColors.TEXT, android.graphics.Typeface.BOLD);
        row.addView(label, new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1));
        Ui.addSpacerHorizontal(this, row, 8);
        Button date = dateButton(timestamp);
        Button time = timeButton(timestamp);
        styleTimestampButton(date);
        styleTimestampButton(time);
        row.addView(date, Ui.fixed(this, 128, 42));
        Ui.addSpacerHorizontal(this, row, 8);
        row.addView(time, Ui.fixed(this, 92, 42));
        panel.addView(row, Ui.matchWrap());
        return panel;
    }

    private void styleTimestampButton(Button button) {
        button.setTextSize(15);
        button.setTextColor(AppColors.ACCENT);
        button.setMinWidth(0);
        button.setMinHeight(Ui.dp(this, 42));
        button.setPadding(Ui.dp(this, 8), 0, Ui.dp(this, 8), 0);
        button.setBackground(Ui.round(Color.rgb(238, 239, 238), Ui.dp(this, 18)));
    }

    private LinearLayout dateOnlyRow(String label, Calendar date, Calendar... linked) {
        LinearLayout row = Ui.h(this, 0);
        row.addView(Ui.text(this, label, 14, AppColors.TEXT, android.graphics.Typeface.BOLD), new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1));
        Button button = Ui.secondary(this, formatDisplayDate(date));
        button.setOnClickListener(v -> new DatePickerDialog(this, (view, year, month, day) -> {
            date.set(Calendar.YEAR, year);
            date.set(Calendar.MONTH, month);
            date.set(Calendar.DAY_OF_MONTH, day);
            for (Calendar calendar : linked) {
                calendar.set(Calendar.YEAR, year);
                calendar.set(Calendar.MONTH, month);
                calendar.set(Calendar.DAY_OF_MONTH, day);
            }
            button.setText(formatDisplayDate(date));
        }, date.get(Calendar.YEAR), date.get(Calendar.MONTH), date.get(Calendar.DAY_OF_MONTH)).show());
        row.addView(button, Ui.wrapWrap());
        return row;
    }

    private LinearLayout timeOnlyRow(String label, Calendar calendar) {
        LinearLayout row = Ui.h(this, 0);
        row.addView(Ui.text(this, label, 14, AppColors.TEXT, android.graphics.Typeface.BOLD), new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1));
        row.addView(timeButton(calendar), Ui.wrapWrap());
        return row;
    }

    private Button dateButton(Calendar calendar) {
        Button button = Ui.secondary(this, formatDisplayDate(calendar));
        button.setOnClickListener(v -> new DatePickerDialog(this, (view, year, month, day) -> {
            calendar.set(Calendar.YEAR, year);
            calendar.set(Calendar.MONTH, month);
            calendar.set(Calendar.DAY_OF_MONTH, day);
            button.setText(formatDisplayDate(calendar));
        }, calendar.get(Calendar.YEAR), calendar.get(Calendar.MONTH), calendar.get(Calendar.DAY_OF_MONTH)).show());
        return button;
    }

    private Button timeButton(Calendar calendar) {
        Button button = Ui.secondary(this, formatDisplayTime(calendar));
        button.setOnClickListener(v -> new TimePickerDialog(this, (view, hourOfDay, minute) -> {
            calendar.set(Calendar.HOUR_OF_DAY, hourOfDay);
            calendar.set(Calendar.MINUTE, minute);
            button.setText(formatDisplayTime(calendar));
        }, calendar.get(Calendar.HOUR_OF_DAY), calendar.get(Calendar.MINUTE), false).show());
        return button;
    }

    private void addHealthEntry(String id, String title, String type, String value, String notes, Calendar timestamp) {
        addHealthEntry(id, title, type, value, notes, timestamp, "");
    }

    private void addHealthEntry(String id, String title, String type, String value, String notes, Calendar timestamp, String imageData) {
        JSONArray entries = storage.getArray(storage.key("health", currentUser.id, "logData"));
        JSONObject entry = new JSONObject();
        try {
            entry.put("id", "android-" + System.currentTimeMillis());
            entry.put("type", type);
            entry.put("categoryID", id);
            entry.put("title", title);
            entry.put("value", value);
            entry.put("notes", notes);
            entry.put("timestamp", formatIso(timestamp));
            if (imageData != null && !imageData.isEmpty()) {
                entry.put("imageData", imageData);
            }
        } catch (JSONException ignored) {
        }
        entries.put(entry);
        storage.putArray(storage.key("health", currentUser.id, "logData"), entries);
        syncHealth(entries);
    }

    private void showNotificationsToday() {
        showMessageSheet(i18n.t("Notifications Today"), i18n.t("No notifications received today."));
    }

    private boolean isHealthHistoryPage() {
        return selectedTab == 1 && !healthHistoryType.isEmpty();
    }

    private void clearHealthHistoryPage() {
        healthHistoryType = "";
        healthHistoryCategoryId = "";
        healthHistoryCategoryTitle = "";
    }

    private void showHealthHistory(String filterType) {
        healthHistoryType = "snapshot".equals(filterType) ? "snapshot" : "quickLog";
        healthHistoryCategoryId = "";
        healthHistoryCategoryTitle = "";
        render();
    }

    private View healthHistoryPage() {
        JSONArray entries = storage.getArray(storage.key("health", currentUser.id, "logData"));
        LinearLayout screen = Ui.screen(this);
        screen.setPadding(Ui.dp(this, 22), Ui.dp(this, 22), Ui.dp(this, 22), Ui.dp(this, 24));

        LinearLayout header = Ui.h(this, 0);
        header.setGravity(Gravity.CENTER_VERTICAL);
        TextView back = iconCircle("‹", AppColors.TEXT, AppColors.PANEL, 58);
        back.setTextSize(36);
        back.setOnClickListener(v -> {
            if (!healthHistoryCategoryId.isEmpty()) {
                healthHistoryCategoryId = "";
                healthHistoryCategoryTitle = "";
            } else {
                clearHealthHistoryPage();
            }
            render();
        });
        header.addView(back, Ui.fixed(this, 58, 58));
        header.addView(new View(this), new LinearLayout.LayoutParams(0, 1, 1));
        screen.addView(header, Ui.matchWrap());
        Ui.addSpacer(this, screen, 22);

        if (!healthHistoryCategoryId.isEmpty()) {
            addHealthHistoryDetailPage(screen, entries);
        } else {
            addHealthHistoryCategoryPage(screen, entries);
        }

        return Ui.scroll(this, screen);
    }

    private void addHealthHistoryCategoryPage(LinearLayout screen, JSONArray entries) {
        String title = "snapshot".equals(healthHistoryType) ? "Daily Snapshot History" : "Quick-log History";
        screen.addView(Ui.title(this, i18n.t(title)), Ui.matchWrap());
        Ui.addSpacer(this, screen, 18);
        String[][] categories = "snapshot".equals(healthHistoryType) ? SNAPSHOTS : QUICK_LOGS;
        for (String[] category : categories) {
            screen.addView(healthHistoryCategoryRow(healthHistoryType, category[0], category[1], entries), Ui.matchWrap());
            Ui.addSpacer(this, screen, 12);
        }
    }

    private void addHealthHistoryDetailPage(LinearLayout screen, JSONArray entries) {
        screen.addView(Ui.title(this, i18n.t(healthHistoryCategoryTitle)), Ui.matchWrap());
        Ui.addSpacer(this, screen, 16);
        int shown = 0;
        for (int i = entries.length() - 1; i >= 0; i--) {
            JSONObject item = entries.optJSONObject(i);
            if (item == null) continue;
            if (!healthHistoryType.equals(item.optString("type"))) continue;
            if (!healthHistoryCategoryId.equals(item.optString("categoryID"))) continue;
            View row = healthHistoryRow(item);
            row.setOnClickListener(v -> showHealthEntryDetail(item));
            screen.addView(row, Ui.matchWrap());
            Ui.addSpacer(this, screen, 8);
            shown++;
        }
        if (shown == 0) {
            LinearLayout empty = Ui.panel(this);
            empty.addView(Ui.muted(this, i18n.t("No records yet.")), Ui.matchWrap());
            screen.addView(empty, Ui.matchWrap());
        }
    }

    private void showHealthHistoryDialog(String filterType) {
        JSONArray entries = storage.getArray(storage.key("health", currentUser.id, "logData"));
        LinearLayout content = Ui.v(this, 0);
        content.setPadding(Ui.dp(this, 12), 0, Ui.dp(this, 12), 0);
        String type = "snapshot".equals(filterType) ? "snapshot" : "quickLog";
        String[][] categories = "snapshot".equals(type) ? SNAPSHOTS : QUICK_LOGS;
        for (String[] category : categories) {
            content.addView(healthHistoryCategoryRow(type, category[0], category[1], entries), Ui.matchWrap());
            Ui.addSpacer(this, content, 10);
        }
        Ui.dialog(this, i18n.t("snapshot".equals(type) ? "Daily Snapshot History" : "Quick-log History"), content, i18n.t("Done"), null);
    }

    private Button historyFilterButton(String title, boolean selected, Runnable action) {
        Button button = Ui.secondary(this, title);
        button.setTextSize(12);
        if (selected) {
            button.setTextColor(AppColors.PANEL);
            button.setBackground(Ui.stroke(AppColors.ACCENT, AppColors.ACCENT, Ui.dp(this, 12)));
        }
        button.setOnClickListener(v -> {
            if (action != null) action.run();
        });
        return button;
    }

    private View healthHistoryCategoryRow(String type, String id, String title, JSONArray entries) {
        int color = "snapshot".equals(type) ? snapshotColor(id) : quickLogColor(id);
        String displayTitle = "snapshot".equals(type) ? snapshotTitle(id, title) : title;
        LinearLayout row = Ui.h(this, 0);
        row.setGravity(Gravity.CENTER_VERTICAL);
        row.setClickable(true);
        row.setFocusable(true);
        row.setPadding(Ui.dp(this, 14), Ui.dp(this, 14), Ui.dp(this, 12), Ui.dp(this, 14));
        row.setBackground(Ui.stroke(AppColors.PANEL, Ui.withAlpha(color, 50), Ui.dp(this, 16)));

        int iconRes = "snapshot".equals(type) ? snapshotIconRes(id) : quickLogIconRes(id);
        ImageView icon = symbolIcon(iconRes, color, Ui.withAlpha(color, 28), 58, 12);
        row.addView(icon, Ui.fixed(this, 58, 58));

        LinearLayout texts = Ui.v(this, 0);
        TextView name = Ui.text(this, i18n.t(displayTitle), 19, AppColors.TEXT, android.graphics.Typeface.BOLD);
        texts.addView(name, Ui.matchWrap());
        Ui.addSpacer(this, texts, 2);
        texts.addView(Ui.muted(this, healthCategorySummary(entries, type, id)), Ui.matchWrap());
        LinearLayout.LayoutParams textParams = new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1);
        textParams.leftMargin = Ui.dp(this, 14);
        row.addView(texts, textParams);

        ImageView chevron = symbolIcon(R.drawable.ios_icon_chevron_right, AppColors.MUTED, Color.TRANSPARENT, 28, 4);
        row.addView(chevron, Ui.fixed(this, 28, 28));
        row.setOnClickListener(v -> {
            healthHistoryType = type;
            healthHistoryCategoryId = id;
            healthHistoryCategoryTitle = displayTitle;
            render();
        });
        return row;
    }

    private String healthCategorySummary(JSONArray entries, String type, String categoryId) {
        int count = 0;
        double severityTotal = 0;
        int severityCount = 0;
        JSONObject latest = null;
        for (int i = entries.length() - 1; i >= 0; i--) {
            JSONObject item = entries.optJSONObject(i);
            if (item == null) continue;
            if (!type.equals(item.optString("type"))) continue;
            if (!categoryId.equals(item.optString("categoryID"))) continue;
            count++;
            if (latest == null) latest = item;
            double score = fivePointScore(item.optString("value"));
            if (score > 0) {
                severityTotal += score;
                severityCount++;
            }
        }
        if (count == 0) return i18n.t("0 entries");
        StringBuilder summary = new StringBuilder();
        summary.append(count).append(" ").append(i18n.t(count == 1 ? "entry" : "entries"));
        if (severityCount > 0) {
            summary.append(" · ").append(i18n.t("Avg")).append(" ");
            summary.append(String.format(Locale.US, "%.1f/5", severityTotal / severityCount));
        } else if (latest != null && !latest.optString("value").isEmpty()) {
            summary.append(" · ").append(notesPreview(latest.optString("value")).replace("\n", " "));
        }
        return summary.toString();
    }

    private double fivePointScore(String value) {
        if (value == null) return 0;
        int slash = value.indexOf("/5");
        if (slash <= 0) return 0;
        int start = slash - 1;
        while (start >= 0 && (Character.isDigit(value.charAt(start)) || value.charAt(start) == '.')) {
            start--;
        }
        try {
            return Double.parseDouble(value.substring(start + 1, slash));
        } catch (NumberFormatException ignored) {
            return 0;
        }
    }

    private void showHealthCategoryDetail(String type, String categoryId, String title) {
        JSONArray entries = storage.getArray(storage.key("health", currentUser.id, "logData"));
        LinearLayout content = Ui.v(this, 0);
        content.setPadding(Ui.dp(this, 12), 0, Ui.dp(this, 12), 0);
        int shown = 0;
        for (int i = entries.length() - 1; i >= 0; i--) {
            JSONObject item = entries.optJSONObject(i);
            if (item == null) continue;
            if (!type.equals(item.optString("type"))) continue;
            if (!categoryId.equals(item.optString("categoryID"))) continue;
            View row = healthHistoryRow(item);
            row.setOnClickListener(v -> showHealthEntryDetail(item));
            content.addView(row, Ui.matchWrap());
            Ui.addSpacer(this, content, 8);
            shown++;
        }
        if (shown == 0) {
            content.addView(Ui.muted(this, i18n.t("No records yet.")), Ui.matchWrap());
        }
        Ui.dialog(this, i18n.t(title), content, i18n.t("Done"), null);
    }

    private View healthHistoryRow(JSONObject item) {
        String categoryId = item.optString("categoryID");
        String icon = "quickLog".equals(item.optString("type")) ? quickLogIcon(categoryId) : snapshotIcon(categoryId);
        String detail = displayDateTime(item.optString("timestamp")) + "\n" + item.optString("value");
        String notes = item.optString("notes");
        if (!notes.isEmpty()) detail += "\n" + notesPreview(notes);
        if (!item.optString("imageData").isEmpty()) detail += "\n" + i18n.t("Photo attached");
        return Ui.cardRow(this, i18n.t(item.optString("title")), detail, icon);
    }

    private void showHealthEntryDetail(JSONObject item) {
        LinearLayout content = Ui.v(this, 0);
        content.setPadding(Ui.dp(this, 12), 0, Ui.dp(this, 12), 0);
        content.addView(Ui.cardRow(this, i18n.t("Date"), displayDateTime(item.optString("timestamp")), "🗓"), Ui.matchWrap());
        Ui.addSpacer(this, content, 8);
        content.addView(Ui.cardRow(this, i18n.t("Log"), item.optString("value"), "✓"), Ui.matchWrap());
        if (!item.optString("notes").isEmpty()) {
            Ui.addSpacer(this, content, 8);
            content.addView(Ui.cardRow(this, i18n.t("Notes"), item.optString("notes"), "📝"), Ui.matchWrap());
        }
        if (!item.optString("imageData").isEmpty()) {
            Ui.addSpacer(this, content, 8);
            content.addView(Ui.cardRow(this, i18n.t("Photo"), i18n.t("Photo attached"), "📷"), Ui.matchWrap());
        }
        Ui.dialog(this, ("quickLog".equals(item.optString("type")) ? quickLogIcon(item.optString("categoryID")) : snapshotIcon(item.optString("categoryID"))) + " " + i18n.t(item.optString("title")), content, i18n.t("Done"), null);
    }

    private void loadHealthInsights() {
        JSONArray quick = new JSONArray();
        for (String[] option : QUICK_LOGS) quick.put(i18n.t(option[1]));
        JSONArray snaps = new JSONArray();
        for (String[] option : SNAPSHOTS) snaps.put(i18n.t(option[1]));
        JSONArray logs = storage.getArray(storage.key("health", currentUser.id, "logData"));
        api.healthInsights(childName(), quick, snaps, logs, i18n.apiLanguageName(), new AuthApi.Callback<JSONArray>() {
            @Override
            public void onSuccess(JSONArray value) {
                String insight = value.length() > 0 ? value.optJSONObject(0).optString("message") : "No insight available.";
                showMessageSheet(i18n.t("Insights & Alerts"), insight);
            }

            @Override
            public void onError(String msg) {
                showMessageSheet(i18n.t("Insights & Alerts"), msg);
            }
        });
    }

    private void showMilestoneDialog(String[] category) {
        LinearLayout content = Ui.v(this, 0);
        content.setPadding(Ui.dp(this, 12), 0, Ui.dp(this, 12), 0);
        EditText milestone = Ui.edit(this, "Example: Used two-word request");
        EditText support = Ui.edit(this, i18n.t("Support level"));
        support.setText("With some support");
        EditText notes = Ui.multi(this, "Notes");
        content.addView(Ui.fieldGroup(this, i18n.t("Milestone"), milestone), Ui.matchWrap());
        Ui.addSpacer(this, content, 12);
        content.addView(Ui.fieldGroup(this, i18n.t("Support level"), support), Ui.matchWrap());
        Ui.addSpacer(this, content, 12);
        content.addView(Ui.fieldGroup(this, "Notes", notes), Ui.matchWrap());
        Ui.dialog(this, i18n.t(category[1]), content, i18n.t("Save"), () -> {
            String clean = milestone.getText().toString().trim();
            if (clean.isEmpty()) return;
            JSONArray milestones = storage.getArray(storage.key("therapy", currentUser.id, "milestoneData"));
            JSONObject item = new JSONObject();
            try {
                item.put("id", "android-" + System.currentTimeMillis());
                item.put("categoryID", category[0]);
                item.put("categoryTitle", category[1]);
                item.put("date", nowIso());
                item.put("milestone", clean);
                item.put("supportLevel", support.getText().toString().trim());
                item.put("notes", notes.getText().toString().trim());
            } catch (JSONException ignored) {
            }
            milestones.put(item);
            storage.putArray(storage.key("therapy", currentUser.id, "milestoneData"), milestones);
            render();
        });
    }

    private void showMilestoneHistory() {
        JSONArray milestones = storage.getArray(storage.key("therapy", currentUser.id, "milestoneData"));
        LinearLayout content = Ui.v(this, 0);
        content.setPadding(Ui.dp(this, 12), 0, Ui.dp(this, 12), 0);
        if (milestones.length() == 0) {
            content.addView(Ui.muted(this, i18n.t("No milestones logged yet.")), Ui.matchWrap());
        } else {
            for (int i = milestones.length() - 1; i >= 0; i--) {
                JSONObject item = milestones.optJSONObject(i);
                if (item == null) continue;
                String detail = i18n.t(item.optString("categoryTitle")) + "\n" + displayDateTime(item.optString("date"));
                if (!item.optString("supportLevel").isEmpty()) {
                    detail += "\n" + item.optString("supportLevel");
                }
                View row = Ui.cardRow(this, item.optString("milestone"), detail, therapyIcon(item.optString("categoryID")));
                row.setOnClickListener(v -> showMilestoneDetail(item));
                content.addView(row, Ui.matchWrap());
                Ui.addSpacer(this, content, 8);
            }
        }
        Ui.dialog(this, i18n.t("History"), content, i18n.t("Done"), null);
    }

    private void showMilestoneDetail(JSONObject item) {
        LinearLayout content = Ui.v(this, 0);
        content.setPadding(Ui.dp(this, 12), 0, Ui.dp(this, 12), 0);
        content.addView(Ui.cardRow(this, i18n.t("Date"), displayDateTime(item.optString("date")), "🗓"), Ui.matchWrap());
        Ui.addSpacer(this, content, 8);
        content.addView(Ui.cardRow(this, i18n.t("Therapy"), i18n.t(item.optString("categoryTitle")), therapyIcon(item.optString("categoryID"))), Ui.matchWrap());
        if (!item.optString("supportLevel").isEmpty()) {
            Ui.addSpacer(this, content, 8);
            content.addView(Ui.cardRow(this, i18n.t("Support level"), item.optString("supportLevel"), "✓"), Ui.matchWrap());
        }
        if (!item.optString("notes").isEmpty()) {
            Ui.addSpacer(this, content, 8);
            content.addView(Ui.cardRow(this, i18n.t("Notes"), item.optString("notes"), "📝"), Ui.matchWrap());
        }
        Ui.dialog(this, therapyIcon(item.optString("categoryID")) + " " + item.optString("milestone"), content, i18n.t("Done"), null);
    }

    private void chooseMealPhoto() {
        showChoiceSheet(i18n.t("Meal Photo"), new String[]{i18n.t("Choose Photo"), i18n.t("Take Photo")}, (which, sheet) -> {
            sheet.dismiss();
            if (which == 0) {
                chooseMealPhotoFromLibrary();
            } else {
                takeMealPhoto();
            }
        });
    }

    private void chooseMealPhotoFromLibrary() {
        Intent intent = new Intent(Intent.ACTION_GET_CONTENT);
        intent.setType("image/*");
        startActivityForResult(Intent.createChooser(intent, i18n.t("Choose Photo")), REQUEST_MEAL_PHOTO);
    }

    private void takeMealPhoto() {
        try {
            Intent intent = new Intent(MediaStore.ACTION_IMAGE_CAPTURE);
            startActivityForResult(intent, REQUEST_MEAL_CAMERA);
        } catch (Exception e) {
            showError(i18n.t("Camera is not available."));
            render();
        }
    }

    private void estimateMeal() {
        int limit = storage.getInt(storage.key("nutrient", currentUser.id, "dailyEstimateLimit"), 3);
        JSONObject usage = dailyUsage();
        if (usage.optInt("estimateCount") >= limit) {
            showError(String.format(Locale.US, i18n.t("Daily nutrient estimate limit reached with limit %s."), String.valueOf(limit)));
            render();
            return;
        }
        try {
            usage.put("estimateCount", usage.optInt("estimateCount") + 1);
        } catch (JSONException ignored) {
        }
        storage.putObject(storage.key("nutrient", currentUser.id, "dailyUsageData"), usage);
        api.syncAppData(currentUser.id, null, null, null, usage);
        isLoading = true;
        clearMessage();
        render();
        api.analyzeMeal(selectedMealPhotoDataUrl, i18n.apiLanguageName(), new AuthApi.Callback<JSONObject>() {
            @Override
            public void onSuccess(JSONObject value) {
                isLoading = false;
                currentMealEstimate = value;
                hasSavedCurrentMeal = false;
                render();
            }

            @Override
            public void onError(String msg) {
                isLoading = false;
                showError(msg);
                render();
            }
        });
    }

    private LinearLayout mealEstimateView(JSONObject estimate) {
        LinearLayout panel = Ui.panel(this);
        panel.setBackground(Ui.round(AppColors.FIELD, Ui.dp(this, 12)));
        panel.addView(Ui.sectionTitle(this, estimate.optString("mealName", "Meal")), Ui.matchWrap());
        Ui.addSpacer(this, panel, 8);
        panel.addView(infoRow("Calories", estimate.optString("calories", "--")), Ui.matchWrap());
        panel.addView(infoRow("Protein", estimate.optString("protein", "--")), Ui.matchWrap());
        panel.addView(infoRow("Carbs", estimate.optString("carbs", "--")), Ui.matchWrap());
        panel.addView(infoRow("Fats", estimate.optString("fats", estimate.optString("fat", "--"))), Ui.matchWrap());
        JSONArray notes = estimate.optJSONArray("notes");
        if (notes != null) {
            for (int i = 0; i < notes.length(); i++) {
                panel.addView(Ui.muted(this, "- " + notes.optString(i)), Ui.matchWrap());
            }
        }
        return panel;
    }

    private void saveCurrentMeal() {
        if (currentMealEstimate == null) return;
        JSONArray meals = storage.getArray(storage.key("nutrient", currentUser.id, "savedMealHistoryData"));
        JSONObject meal = new JSONObject();
        try {
            meal.put("id", "android-" + System.currentTimeMillis());
            meal.put("savedAt", nowIso());
            meal.put("imageData", selectedMealPhotoDataUrl);
            meal.put("estimate", currentMealEstimate);
        } catch (JSONException ignored) {
        }
        meals.put(meal);
        storage.putArray(storage.key("nutrient", currentUser.id, "savedMealHistoryData"), meals);
        JSONArray backendMeals = new JSONArray();
        for (int i = 0; i < meals.length(); i++) {
            JSONObject copy = meals.optJSONObject(i);
            if (copy == null) continue;
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
        api.syncAppData(currentUser.id, null, null, backendMeals, null);
        selectedMealPhotoDataUrl = "";
        currentMealEstimate = null;
        hasSavedCurrentMeal = true;
        message = i18n.t("Meal saved to history.");
        isError = false;
        render();
    }

    private void showManualMealDialog() {
        LinearLayout content = Ui.v(this, 0);
        content.setPadding(Ui.dp(this, 12), 0, Ui.dp(this, 12), 0);
        String[] photoData = {""};
        EditText name = Ui.edit(this, "Meal");
        EditText calories = Ui.edit(this, "Calories");
        calories.setInputType(InputType.TYPE_CLASS_NUMBER);
        EditText protein = Ui.edit(this, "Protein");
        EditText carbs = Ui.edit(this, "Carbs");
        EditText fats = Ui.edit(this, "Fats");
        content.addView(Ui.fieldGroup(this, "Meal", name), Ui.matchWrap());
        Ui.addSpacer(this, content, 10);
        content.addView(Ui.fieldGroup(this, "Calories", calories), Ui.matchWrap());
        Ui.addSpacer(this, content, 10);
        content.addView(Ui.fieldGroup(this, "Protein", protein), Ui.matchWrap());
        Ui.addSpacer(this, content, 10);
        content.addView(Ui.fieldGroup(this, "Carbs", carbs), Ui.matchWrap());
        Ui.addSpacer(this, content, 10);
        content.addView(Ui.fieldGroup(this, "Fats", fats), Ui.matchWrap());
        Ui.addSpacer(this, content, 10);
        content.addView(photoControls("Meal Photo", photoData), Ui.matchWrap());
        Ui.dialog(this, i18n.t("Add Meal Manually"), content, i18n.t("Save"), () -> {
            JSONObject estimate = new JSONObject();
            try {
                estimate.put("mealName", name.getText().toString().trim());
                estimate.put("calories", calories.getText().toString().trim());
                estimate.put("protein", protein.getText().toString().trim());
                estimate.put("carbs", carbs.getText().toString().trim());
                estimate.put("fats", fats.getText().toString().trim());
            } catch (JSONException ignored) {
            }
            currentMealEstimate = estimate;
            selectedMealPhotoDataUrl = photoData[0];
            saveCurrentMeal();
            message = i18n.t("Manual meal saved to history.");
            isError = false;
            render();
        });
    }

    private void showMealHistory() {
        JSONArray meals = storage.getArray(storage.key("nutrient", currentUser.id, "savedMealHistoryData"));
        LinearLayout content = Ui.v(this, 0);
        content.setPadding(Ui.dp(this, 12), 0, Ui.dp(this, 12), 0);
        if (meals.length() == 0) {
            content.addView(Ui.muted(this, i18n.t("No records yet.")), Ui.matchWrap());
        } else {
            for (int i = meals.length() - 1; i >= 0; i--) {
                JSONObject meal = meals.optJSONObject(i);
                if (meal == null) continue;
                JSONObject estimate = meal.optJSONObject("estimate");
                String title = estimate == null ? i18n.t("Meal") : estimate.optString("mealName", i18n.t("Meal"));
                String detail = displayDateTime(meal.optString("savedAt"));
                if (estimate != null) {
                    detail += "\n" + i18n.t("Calories") + ": " + estimate.optString("calories", "--");
                    detail += " · " + i18n.t("Protein") + ": " + estimate.optString("protein", "--");
                }
                if (!meal.optString("imageData").isEmpty()) {
                    detail += "\n" + i18n.t("Photo attached");
                }
                View row = Ui.cardRow(this, title, detail, "🍽");
                row.setOnClickListener(v -> showMealDetail(meal));
                content.addView(row, Ui.matchWrap());
                Ui.addSpacer(this, content, 8);
            }
        }
        Ui.dialog(this, i18n.t("Meal history"), content, i18n.t("Done"), null);
    }

    private void showMealDetail(JSONObject meal) {
        JSONObject estimate = meal.optJSONObject("estimate");
        LinearLayout content = Ui.v(this, 0);
        content.setPadding(Ui.dp(this, 12), 0, Ui.dp(this, 12), 0);
        content.addView(Ui.cardRow(this, i18n.t("Date"), displayDateTime(meal.optString("savedAt")), "🗓"), Ui.matchWrap());
        Ui.addSpacer(this, content, 8);
        if (!meal.optString("imageData").isEmpty()) {
            content.addView(Ui.cardRow(this, i18n.t("Photo"), i18n.t("Photo attached"), "📷"), Ui.matchWrap());
            Ui.addSpacer(this, content, 8);
        }
        if (estimate != null) {
            content.addView(mealEstimateView(estimate), Ui.matchWrap());
        }
        String title = estimate == null ? i18n.t("Meal Details") : estimate.optString("mealName", i18n.t("Meal Details"));
        Ui.dialog(this, "🍽 " + title, content, i18n.t("Done"), null);
    }

    private void showBasicInfoDialog() {
        LinearLayout content = Ui.v(this, 0);
        content.setPadding(Ui.dp(this, 12), 0, Ui.dp(this, 12), 0);
        EditText fullName = Ui.edit(this, i18n.t("Child Name"));
        EditText birthDate = Ui.edit(this, i18n.t("Date of Birth"));
        EditText supportNeeds = Ui.multi(this, i18n.t("Support Needs"));
        EditText homeSchool = Ui.multi(this, i18n.t("Home / School Notes"));
        EditText emergency = Ui.edit(this, i18n.t("Emergency Contact"));
        EditText notes = Ui.multi(this, i18n.t("Care Notes"));
        fullName.setText(storage.getString(storage.key("profile", currentUser.id, "fullName"), ""));
        birthDate.setText(storage.getString(storage.key("profile", currentUser.id, "birthDate"), ""));
        supportNeeds.setText(storage.getString(storage.key("profile", currentUser.id, "phone"), ""));
        homeSchool.setText(storage.getString(storage.key("profile", currentUser.id, "address"), ""));
        emergency.setText(storage.getString(storage.key("profile", currentUser.id, "emergencyContact"), ""));
        notes.setText(storage.getString(storage.key("profile", currentUser.id, "medicalNotes"), ""));
        content.addView(Ui.fieldGroup(this, i18n.t("Child Name"), fullName), Ui.matchWrap());
        Ui.addSpacer(this, content, 10);
        content.addView(Ui.fieldGroup(this, i18n.t("Date of Birth"), birthDate), Ui.matchWrap());
        Ui.addSpacer(this, content, 10);
        content.addView(Ui.fieldGroup(this, i18n.t("Support Needs"), supportNeeds), Ui.matchWrap());
        Ui.addSpacer(this, content, 10);
        content.addView(Ui.fieldGroup(this, i18n.t("Home / School Notes"), homeSchool), Ui.matchWrap());
        Ui.addSpacer(this, content, 10);
        content.addView(Ui.fieldGroup(this, i18n.t("Emergency Contact"), emergency), Ui.matchWrap());
        Ui.addSpacer(this, content, 10);
        content.addView(Ui.fieldGroup(this, i18n.t("Care Notes"), notes), Ui.matchWrap());
        Ui.dialog(this, i18n.t("Child Profile"), content, i18n.t("Save"), () -> {
            storage.putString(storage.key("profile", currentUser.id, "fullName"), fullName.getText().toString().trim());
            storage.putString(storage.key("profile", currentUser.id, "birthDate"), birthDate.getText().toString().trim());
            storage.putString(storage.key("profile", currentUser.id, "phone"), supportNeeds.getText().toString().trim());
            storage.putString(storage.key("profile", currentUser.id, "address"), homeSchool.getText().toString().trim());
            storage.putString(storage.key("profile", currentUser.id, "emergencyContact"), emergency.getText().toString().trim());
            storage.putString(storage.key("profile", currentUser.id, "medicalNotes"), notes.getText().toString().trim());
            syncProfile();
            render();
        });
    }

    private void syncProfile() {
        JSONObject profile = new JSONObject();
        try {
            profile.put("fullName", storage.getString(storage.key("profile", currentUser.id, "fullName"), ""));
            profile.put("birthDate", storage.getString(storage.key("profile", currentUser.id, "birthDate"), ""));
            profile.put("supportNeeds", storage.getString(storage.key("profile", currentUser.id, "phone"), ""));
            profile.put("homeSchoolNotes", storage.getString(storage.key("profile", currentUser.id, "address"), ""));
            profile.put("emergencyContact", storage.getString(storage.key("profile", currentUser.id, "emergencyContact"), ""));
            profile.put("careNotes", storage.getString(storage.key("profile", currentUser.id, "medicalNotes"), ""));
        } catch (JSONException ignored) {
        }
        api.syncAppData(currentUser.id, profile, null, null, null);
    }

    private void syncHealth(JSONArray entries) {
        syncProfile();
        api.syncAppData(currentUser.id, childProfileJson(), entries, null, null);
    }

    private JSONObject childProfileJson() {
        JSONObject profile = new JSONObject();
        try {
            profile.put("fullName", storage.getString(storage.key("profile", currentUser.id, "fullName"), ""));
            profile.put("birthDate", storage.getString(storage.key("profile", currentUser.id, "birthDate"), ""));
            profile.put("supportNeeds", storage.getString(storage.key("profile", currentUser.id, "phone"), ""));
            profile.put("homeSchoolNotes", storage.getString(storage.key("profile", currentUser.id, "address"), ""));
            profile.put("emergencyContact", storage.getString(storage.key("profile", currentUser.id, "emergencyContact"), ""));
            profile.put("careNotes", storage.getString(storage.key("profile", currentUser.id, "medicalNotes"), ""));
        } catch (JSONException ignored) {
        }
        return profile;
    }

    private void showLanguageDialog() {
        showChoiceSheet(i18n.t("Language"), new String[]{"English", "中文"}, (which, sheet) -> {
            sheet.dismiss();
            i18n.setLanguage(which == 0 ? I18n.EN : I18n.ZH);
            render();
        });
    }

    private void showTermsDialog() {
        String text = "1. Acceptance of Terms\n\n"
                + "By using Care Portal, you agree to use this app responsibly for family care tracking.\n\n"
                + "2. Medical Disclaimer\n\n"
                + "Care Portal is not a medical provider and does not replace professional medical advice.\n\n"
                + "3. Privacy and Data\n\n"
                + "Keep your account secure and avoid entering information you do not have permission to store.";
        LinearLayout content = quickFormContent();
        TextView body = Ui.muted(this, text);
        body.setTextSize(15);
        body.setLineSpacing(Ui.dp(this, 4), 1.0f);
        content.addView(body, Ui.matchWrap());
        Ui.dialog(this, i18n.t("Terms of Use"), content, i18n.t("Done"), null);
    }

    private void addMessage(LinearLayout panel) {
        if (!message.isEmpty()) {
            panel.addView(Ui.message(this, message, isError), Ui.matchWrap());
            Ui.addSpacer(this, panel, 14);
        }
    }

    private void clearMessage() {
        message = "";
        isError = false;
    }

    private void showError(String text) {
        message = text == null ? "" : text;
        isError = true;
    }

    private String childName() {
        String name = storage.getString(storage.key("profile", currentUser.id, "fullName"), "").trim();
        return name.isEmpty() ? i18n.t("Child profile") : name;
    }

    private String latestTodaySummary(String categoryId) {
        JSONArray entries = storage.getArray(storage.key("health", currentUser.id, "logData"));
        for (int i = entries.length() - 1; i >= 0; i--) {
            JSONObject item = entries.optJSONObject(i);
            if (item != null && categoryId.equals(item.optString("categoryID")) && item.optString("timestamp").startsWith(todayKey())) {
                String value = item.optString("value");
                return value.isEmpty() ? "\nDone" : "\n" + value;
            }
        }
        return "";
    }

    private JSONObject dailyUsage() {
        String key = storage.key("nutrient", currentUser.id, "dailyUsageData");
        JSONObject usage = storage.getObject(key);
        if (!todayKey().equals(usage.optString("dateKey"))) {
            usage = new JSONObject();
            try {
                usage.put("dateKey", todayKey());
                usage.put("uploadCount", 0);
                usage.put("estimateCount", 0);
            } catch (JSONException ignored) {
            }
            storage.putObject(key, usage);
        }
        return usage;
    }

    private LinearLayout photoControls(String title, String[] photoData) {
        LinearLayout card = sectionCard("📷 " + i18n.t(title));
        TextView status = Ui.muted(this, photoData[0].isEmpty() ? i18n.t("No photo selected.") : i18n.t("Photo selected"));
        card.addView(status, Ui.matchWrap());
        Ui.addSpacer(this, card, 8);
        LinearLayout row = Ui.h(this, 0);
        Button choose = Ui.secondary(this, i18n.t("Choose Photo"));
        Button camera = Ui.secondary(this, i18n.t("Take Photo"));
        choose.setOnClickListener(v -> chooseGenericPhoto(photoData, status));
        camera.setOnClickListener(v -> takeGenericPhoto(photoData, status));
        LinearLayout.LayoutParams left = new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1);
        left.rightMargin = Ui.dp(this, 8);
        row.addView(choose, left);
        row.addView(camera, new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1));
        card.addView(row, Ui.matchWrap());
        return card;
    }

    private void chooseGenericPhoto(String[] photoData, TextView status) {
        pendingPhotoCallback = dataUrl -> {
            photoData[0] = dataUrl;
            status.setVisibility(View.VISIBLE);
            status.setText(dataUrl.isEmpty() ? i18n.t("Unable to load photo.") : i18n.t("Photo selected"));
        };
        Intent intent = new Intent(Intent.ACTION_GET_CONTENT);
        intent.setType("image/*");
        startActivityForResult(Intent.createChooser(intent, i18n.t("Choose Photo")), REQUEST_GENERIC_PHOTO_LIBRARY);
    }

    private void takeGenericPhoto(String[] photoData, TextView status) {
        pendingPhotoCallback = dataUrl -> {
            photoData[0] = dataUrl;
            status.setVisibility(View.VISIBLE);
            status.setText(dataUrl.isEmpty() ? i18n.t("Unable to load photo.") : i18n.t("Photo selected"));
        };
        try {
            Intent intent = new Intent(MediaStore.ACTION_IMAGE_CAPTURE);
            startActivityForResult(intent, REQUEST_GENERIC_PHOTO_CAMERA);
        } catch (Exception e) {
            pendingPhotoCallback = null;
            status.setVisibility(View.VISIBLE);
            status.setText(i18n.t("Camera is not available."));
        }
    }

    private void finishPendingPhoto(String dataUrl) {
        if (pendingPhotoCallback != null) {
            pendingPhotoCallback.onPhoto(dataUrl == null ? "" : dataUrl);
            pendingPhotoCallback = null;
        }
    }

    private String imageDataUrlFromCameraResult(Intent data) {
        if (data == null || data.getExtras() == null) return "";
        Object raw = data.getExtras().get("data");
        if (!(raw instanceof Bitmap)) return "";
        return bitmapToDataUrl((Bitmap) raw);
    }

    private String bitmapToDataUrl(Bitmap bitmap) {
        if (bitmap == null) return "";
        int max = 1200;
        int width = bitmap.getWidth();
        int height = bitmap.getHeight();
        if (Math.max(width, height) > max) {
            float scale = max / (float) Math.max(width, height);
            bitmap = Bitmap.createScaledBitmap(bitmap, Math.round(width * scale), Math.round(height * scale), true);
        }
        ByteArrayOutputStream output = new ByteArrayOutputStream();
        bitmap.compress(Bitmap.CompressFormat.JPEG, 74, output);
        return "data:image/jpeg;base64," + Base64.encodeToString(output.toByteArray(), Base64.NO_WRAP);
    }

    private String loadImageDataUrl(Uri uri) {
        try (InputStream input = getContentResolver().openInputStream(uri)) {
            Bitmap bitmap = BitmapFactory.decodeStream(input);
            if (bitmap == null) {
                return "";
            }
            return bitmapToDataUrl(bitmap);
        } catch (Exception e) {
            return "";
        }
    }

    private interface PhotoCallback {
        void onPhoto(String dataUrl);
    }

    private Set<String> commaSet(String raw) {
        Set<String> result = new HashSet<>();
        if (raw == null || raw.trim().isEmpty()) {
            return result;
        }
        for (String part : raw.split(",")) {
            if (!part.trim().isEmpty()) {
                result.add(part.trim());
            }
        }
        return result;
    }

    private int countBy(JSONArray array, String field, String value) {
        int count = 0;
        for (int i = 0; i < array.length(); i++) {
            JSONObject item = array.optJSONObject(i);
            if (item != null && value.equals(item.optString(field))) {
                count++;
            }
        }
        return count;
    }

    private String initials(String name) {
        String clean = name == null ? "" : name.trim();
        if (clean.isEmpty()) return "CP";
        String[] parts = clean.split("\\s+");
        StringBuilder builder = new StringBuilder();
        for (String part : parts) {
            if (!part.isEmpty() && builder.length() < 2) {
                builder.append(part.substring(0, 1).toUpperCase(Locale.US));
            }
        }
        return builder.length() == 0 ? "CP" : builder.toString();
    }

    private String nowIso() {
        return new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSSZ", Locale.US).format(new Date());
    }

    private String formatIso(Calendar calendar) {
        return new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSSZ", Locale.US).format(calendar.getTime());
    }

    private String formatDisplayDate(Calendar calendar) {
        return new SimpleDateFormat("MMM d, yyyy", Locale.US).format(calendar.getTime());
    }

    private String formatDisplayTime(Calendar calendar) {
        return new SimpleDateFormat("h:mm a", Locale.US).format(calendar.getTime());
    }

    private String displayDateTime(String iso) {
        if (iso == null || iso.trim().isEmpty()) {
            return "";
        }
        try {
            Date parsed = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSSZ", Locale.US).parse(iso);
            if (parsed != null) {
                return new SimpleDateFormat("MMM d, yyyy h:mm a", Locale.getDefault()).format(parsed);
            }
        } catch (Exception ignored) {
        }
        return iso;
    }

    private String notesPreview(String notes) {
        if (notes == null) {
            return "";
        }
        String clean = notes.replace("\n", " · ").trim();
        if (clean.length() <= 90) {
            return clean;
        }
        return clean.substring(0, 90) + "...";
    }

    private int minutesBetween(Calendar start, Calendar end) {
        long diff = end.getTimeInMillis() - start.getTimeInMillis();
        if (diff <= 0) {
            diff += 24L * 60L * 60L * 1000L;
        }
        return Math.max(0, Math.round(diff / 60000f));
    }

    private String formatSleepDuration(int minutes) {
        int hours = minutes / 60;
        int mins = minutes % 60;
        if (mins == 0) {
            return hours + "h";
        }
        return hours + "h " + mins + "m";
    }

    private String todayKey() {
        return new SimpleDateFormat("yyyy-MM-dd", Locale.US).format(new Date());
    }

    private static String makeCaptchaCode() {
        String source = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
        Random random = new Random();
        StringBuilder builder = new StringBuilder();
        for (int i = 0; i < 4; i++) {
            builder.append(source.charAt(random.nextInt(source.length())));
        }
        return builder.toString();
    }
}
