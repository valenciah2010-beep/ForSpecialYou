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
import android.provider.OpenableColumns;
import android.media.MediaMetadataRetriever;
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

    interface SheetChoiceHandler {

        void onChoice(int index, Dialog sheet);
    }

    static final int REQUEST_MEAL_PHOTO = 101;

    static final int REQUEST_MEAL_CAMERA = 102;

    static final int REQUEST_GENERIC_PHOTO_LIBRARY = 103;

    static final int REQUEST_GENERIC_PHOTO_CAMERA = 104;

    static final int REQUEST_MILESTONE_MEDIA = 105;

    static final String[][] DIAGNOSIS_OPTIONS = { { "genetics", "Genetics" }, { "pediatricHealthClinic", "Pediatric Health Clinic (Early Screening)" }, { "developmentalBehavioral", "Developmental-Behavioral Pediatrics" }, { "childPsychiatryPsychology", "Child Psychiatry/Psychology" }, { "neurology", "Neurology" }, { "rehabilitationInterventions", "Rehabilitation / Interventions" }, { "gastroenterology", "Gastroenterology" }, { "oralRelated", "Oral Related (Stomatology)" }, { "dermatology", "Dermatology" }, { "orthopedics", "Orthopedics" }, { "stomatology", "Otolaryngology (ENT)" }, { "neurosurgery", "Neurosurgery" }, { "ophthalmology", "Ophthalmology" }, { "traditionalChineseMedicine", "Traditional Chinese Medicine" }, { "nutrition", "Nutrition" }, { "autismSpecialist", "Autism Specialist" }, { "other", "Other" } };

    static final String[][] QUICK_LOGS = { { "seizure", "Seizure Track" }, { "meltdown", "Meltdown" }, { "stimming", "Stimming/Tics" }, { "accident", "Accident" }, { "deescalation", "De-escalation" }, { "allergy", "Allergic Reaction" }, { "pain", "Pain" }, { "skin", "Skin" }, { "cyclicVomiting", "Cyclic Vomiting" }, { "discomfort", "Discomfort" }, { "medsFood", "Medicine" } };

    static final String[][] SNAPSHOTS = { { "sleep", "Sleep / Rest" }, { "digestion", "Digestion" }, { "nutrition", "Nutrition" }, { "mood", "Mood" }, { "height", "Height" }, { "weight", "Weight" } };

    static final String[][] THERAPY_CATEGORIES = { { "physical", "Physical", "Balance, strength, stairs, movement" }, { "occupational", "Occupational", "Fine motor, sensory, dressing, daily skills" }, { "speech", "Speech", "Words, AAC, requests, social communication" }, { "behavioral", "Behavioral/RDI", "Transitions, regulation, coping, routines" }, { "social", "Social", "Play, turn-taking, peer interaction" }, { "other", "Others", "Additional therapy goals and supports" } };

    Storage storage;

    I18n i18n;

    AuthApi api;

    CarePortalUser currentUser;

    String authScreen = "home";

    String message = "";

    boolean isError = false;

    boolean isLoading = false;

    int selectedTab = 0;

    int failedLoginAttempts = 0;

    boolean captchaRequired = false;

    String captchaCode = makeCaptchaCode();

    String captchaInput = "";

    String loginNickname = "";

    String signupNickname = "";

    String selectedMealPhotoDataUrl = "";

    PhotoCallback pendingPhotoCallback;

    MilestoneMediaCallback pendingMilestoneMediaCallback;

    JSONObject currentMealEstimate;

    boolean hasSavedCurrentMeal = false;

    String healthHistoryType = "";

    String healthHistoryCategoryId = "";

    String healthHistoryCategoryTitle = "";

    boolean isNutritionPage = false;

    boolean isFirstLoginOnboarding = false;
    int onboardingSlide = 0;
    String onboardingChildName = "";
    String onboardingChildAge = "";
    String onboardingGender = "Prefer not to say";
    String onboardingDiagnoses = "";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        storage = new Storage(this);
        i18n = new I18n(storage);
        api = new AuthApi(this, i18n);
        api.onSessionExpired(() -> {
            if (currentUser == null || isFinishing() || isDestroyed()) return;
            logout();
            authScreen = "login";
            showError(i18n.server("Please log in again."));
            render();
        });
        currentUser = api.hasSession() ? storage.getSavedUser() : null;
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
        } else if (requestCode == REQUEST_MILESTONE_MEDIA && resultCode == RESULT_OK && data != null && data.getData() != null) {
            finishPendingMilestoneMedia(data.getData(), data.getFlags());
        }
    }

    void render() {
        if (currentUser == null) {
            renderAuth();
        } else if (isFirstLoginOnboarding) {
            renderFirstLoginOnboarding();
        } else {
            renderApp();
        }
    }

    void renderAuth() {
        authScreens.renderAuth();
    }

    void renderHome(LinearLayout panel) {
        authScreens.renderHome(panel);
    }

    void renderLogin(LinearLayout panel) {
        authScreens.renderLogin(panel);
    }

    void renderSignup(LinearLayout panel) {
        authScreens.renderSignup(panel);
    }

    void renderApp() {
        LinearLayout shell = new LinearLayout(this);
        shell.setOrientation(LinearLayout.VERTICAL);
        shell.setBackgroundColor(AppColors.BACKGROUND);
        FrameLayout content = new FrameLayout(this);
        shell.addView(content, new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, 0, 1));
        content.addView(tabContent(), Ui.frameMatch());
        if (!isHealthHistoryPage() && !isNutritionPage) {
            shell.addView(bottomNav(), new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, Ui.dp(this, 108)));
        }
        setContentView(shell);
    }

    void renderFirstLoginOnboarding() {
        LinearLayout screen = Ui.screen(this);
        screen.setPadding(Ui.dp(this, 24), Ui.dp(this, 42), Ui.dp(this, 24), Ui.dp(this, 22));
        LinearLayout progress = Ui.h(this, 0);
        for (int i = 0; i < 3; i++) {
            View bar = new View(this);
            bar.setBackground(Ui.round(i <= onboardingSlide ? AppColors.ACCENT : Ui.withAlpha(AppColors.ACCENT, 38), Ui.dp(this, 4)));
            LinearLayout.LayoutParams barParams = new LinearLayout.LayoutParams(0, Ui.dp(this, 5), 1);
            if (i < 2) barParams.rightMargin = Ui.dp(this, 8);
            progress.addView(bar, barParams);
        }
        screen.addView(progress, Ui.matchWrap());
        Ui.addSpacer(this, screen, 28);

        if (onboardingSlide == 0) {
            screen.addView(symbolIcon(R.drawable.ios_tab_profile, AppColors.ACCENT, Color.TRANSPARENT, 116, 8), Ui.fixed(this, 116, 116));
            Ui.addSpacer(this, screen, 18);
            TextView title = Ui.title(this, "For Special You");
            title.setGravity(Gravity.CENTER);
            screen.addView(title, Ui.matchWrap());
            Ui.addSpacer(this, screen, 16);
            TextView introduction = Ui.muted(this, "For Special You is created for parents or caretakers of special needs children with developmental delays to easily track their symptoms, daily life, milestones, therapy, and more. We aim to empower our children through navigable systems that log and support their unique needs.");
            introduction.setTextSize(16);
            introduction.setGravity(Gravity.CENTER);
            screen.addView(introduction, Ui.matchWrap());
        } else if (onboardingSlide == 1) {
            TextView icon = Ui.text(this, "●", 52, AppColors.ACCENT, android.graphics.Typeface.BOLD);
            icon.setGravity(Gravity.CENTER);
            screen.addView(icon, Ui.matchWrap());
            TextView title = Ui.sectionTitle(this, "Let's get to know your child");
            title.setGravity(Gravity.CENTER);
            screen.addView(title, Ui.matchWrap());
            TextView subtitle = Ui.muted(this, "Tell us a little about them");
            subtitle.setGravity(Gravity.CENTER);
            screen.addView(subtitle, Ui.matchWrap());
            Ui.addSpacer(this, screen, 24);
            EditText name = Ui.edit(this, "Enter your child's name");
            name.setText(onboardingChildName);
            screen.addView(Ui.fieldGroup(this, "What is your child's name?", name), Ui.matchWrap());
            Ui.addSpacer(this, screen, 16);
            EditText age = Ui.edit(this, "Enter age");
            age.setInputType(InputType.TYPE_CLASS_NUMBER);
            age.setText(onboardingChildAge);
            screen.addView(Ui.fieldGroup(this, "How old is your child?", age), Ui.matchWrap());
            Ui.addSpacer(this, screen, 16);
            Spinner gender = new Spinner(this);
            String[] genders = { "Prefer not to say", "Female", "Male", "Nonbinary", "Self-describe" };
            gender.setAdapter(new ArrayAdapter<>(this, android.R.layout.simple_spinner_dropdown_item, genders));
            for (int i = 0; i < genders.length; i++) if (genders[i].equals(onboardingGender)) gender.setSelection(i);
            screen.addView(Ui.text(this, "Gender", 14, AppColors.TEXT, android.graphics.Typeface.BOLD), Ui.matchWrap());
            screen.addView(gender, Ui.matchWrap());
            Ui.addSpacer(this, screen, 16);
            EditText diagnoses = Ui.edit(this, "Add diagnoses or conditions (optional)");
            diagnoses.setText(onboardingDiagnoses);
            screen.addView(Ui.fieldGroup(this, "Diagnosis or Conditions", diagnoses), Ui.matchWrap());
            name.setTag(age);
            age.setTag(gender);
            gender.setTag(diagnoses);
            screen.setTag(name);
        } else {
            TextView title = Ui.title(this, i18n.t("Terms and Conditions"));
            title.setGravity(Gravity.CENTER);
            screen.addView(title, Ui.matchWrap());
            Ui.addSpacer(this, screen, 18);
            TextView terms = Ui.muted(this, "For Special You helps caregivers organize information. It does not provide medical advice, diagnosis, or treatment. AI-generated information may be incomplete or inaccurate and should not be used for important health decisions without a qualified professional.");
            terms.setTextSize(16);
            terms.setPadding(Ui.dp(this, 16), Ui.dp(this, 16), Ui.dp(this, 16), Ui.dp(this, 16));
            terms.setBackground(Ui.round(AppColors.PANEL, Ui.dp(this, 14)));
            screen.addView(terms, Ui.matchWrap());
            Button readTerms = Ui.secondary(this, "Read the full Terms and Conditions");
            readTerms.setOnClickListener(v -> showTermsDialog());
            screen.addView(readTerms, Ui.matchWrap());
            CheckBox agreement = Ui.check(this, i18n.t("I agree to the Terms and Conditions before using this app."));
            agreement.setChecked(storage.getInt(storage.key("profile", currentUser.id, "onboardingTermsAccepted"), 0) == 1);
            screen.addView(agreement, Ui.matchWrap());
            screen.setTag(agreement);
        }
        View spacer = new View(this);
        screen.addView(spacer, new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, 0, 1));
        Button next = Ui.primary(this, onboardingSlide == 2 ? "Start Using For Special You" : "Next");
        next.setOnClickListener(v -> advanceFirstLoginOnboarding(screen));
        screen.addView(next, Ui.matchWrap());
        setContentView(screen);
    }

    void advanceFirstLoginOnboarding(LinearLayout screen) {
        if (onboardingSlide == 1) {
            EditText name = (EditText) screen.getTag();
            EditText age = (EditText) name.getTag();
            Spinner gender = (Spinner) age.getTag();
            EditText diagnoses = (EditText) gender.getTag();
            onboardingChildName = name.getText().toString().trim();
            onboardingChildAge = age.getText().toString().trim();
            onboardingGender = String.valueOf(gender.getSelectedItem());
            onboardingDiagnoses = diagnoses.getText().toString().trim();
            if (onboardingChildName.isEmpty() || onboardingChildAge.isEmpty()) {
                showError("Please enter your child's name and age.");
                renderFirstLoginOnboarding();
                return;
            }
        }
        if (onboardingSlide < 2) {
            onboardingSlide++;
            renderFirstLoginOnboarding();
            return;
        }
        CheckBox agreement = (CheckBox) screen.getTag();
        if (!agreement.isChecked()) return;
        storage.putString(storage.key("profile", currentUser.id, "fullName"), onboardingChildName);
        storage.putString(storage.key("profile", currentUser.id, "phone"), onboardingDiagnoses);
        storage.putString(storage.key("profile", currentUser.id, "childAge"), onboardingChildAge);
        storage.putString(storage.key("profile", currentUser.id, "gender"), onboardingGender);
        storage.putInt(storage.key("profile", currentUser.id, "onboardingTermsAccepted"), 1);
        storage.putInt("auth.completedFirstLoginOnboarding." + currentUser.id, 1);
        storage.putInt("auth.pendingFirstLoginOnboarding." + currentUser.nickname.trim().toLowerCase(Locale.US), 0);
        api.syncAppData(currentUser.id, childProfileJson(), null, null, null);
        isFirstLoginOnboarding = false;
        selectedTab = 1;
        render();
    }

    View tabContent() {
        if (selectedTab == 0) {
            return diagnosisView();
        } else if (selectedTab == 1) {
            if (isNutritionPage) {
                return nutrientView();
            }
            if (isHealthHistoryPage()) {
                return healthHistoryPage();
            }
            return healthView();
        } else if (selectedTab == 2) {
            return therapyView();
        } else if (selectedTab == 3) {
            return milestonesView();
        }
        return profileView();
    }

    View bottomNav() {
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
        String[] labels = { i18n.t("Diagnosis"), i18n.t("Health"), i18n.t("Therapy"), i18n.t("Milestones"), i18n.t("Profile") };
        int[] icons = { R.drawable.ios_tab_diagnosis, R.drawable.ios_tab_health, R.drawable.ios_therapy_session, R.drawable.ios_therapy_social, R.drawable.ios_tab_profile };
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
                isNutritionPage = false;
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

    View diagnosisView() {
        return diagnosisScreens.diagnosisView();
    }

    FrameLayout diagnosisConditionSwipeRow(JSONObject item, int index) {
        return diagnosisScreens.diagnosisConditionSwipeRow(item, index);
    }

    LinearLayout conditionSwipeAction(String title, int iconRes, int color, Runnable action) {
        return diagnosisScreens.conditionSwipeAction(title, iconRes, color, action);
    }

    void enableSwipeReveal(View card, int actionWidth) {
        diagnosisScreens.enableSwipeReveal(card, actionWidth);
    }

    void deleteCondition(int index) {
        diagnosisScreens.deleteCondition(index);
    }

    void addSelectedDiagnosis(LinearLayout screen) {
        diagnosisScreens.addSelectedDiagnosis(screen);
    }

    LinearLayout diagnosisConditionCard(JSONObject item) {
        return diagnosisScreens.diagnosisConditionCard(item);
    }

    String conditionCategoryNames(JSONObject item) {
        return diagnosisScreens.conditionCategoryNames(item);
    }

    LinearLayout diagnosisDoctorVisitButton() {
        return diagnosisScreens.diagnosisDoctorVisitButton();
    }

    LinearLayout diagnosisCategoryCard(String[] option) {
        return diagnosisScreens.diagnosisCategoryCard(option);
    }

    String diagnosisIcon(String id) {
        return diagnosisScreens.diagnosisIcon(id);
    }

    int diagnosisColor(String id) {
        return diagnosisScreens.diagnosisColor(id);
    }

    void addDoctorVisits(LinearLayout screen) {
        diagnosisScreens.addDoctorVisits(screen);
    }

    View healthView() {
        return healthDashboard.healthView();
    }

    View quickLogCard(String id, String title) {
        return healthDashboard.quickLogCard(id, title);
    }

    void enableQuickLogDrag(View card, String id) {
        healthDashboard.enableQuickLogDrag(card, id);
    }

    void disallowParentIntercept(View view, boolean disallow) {
        healthDashboard.disallowParentIntercept(view, disallow);
    }

    String quickLogTargetAt(View view, float rawX, float rawY, String draggedId) {
        return healthDashboard.quickLogTargetAt(view, rawX, rawY, draggedId);
    }

    void moveQuickLogButton(String draggedId, String targetId) {
        healthDashboard.moveQuickLogButton(draggedId, targetId);
    }

    List<String[]> orderedQuickLogs(String raw) {
        return healthDashboard.orderedQuickLogs(raw);
    }

    List<String> orderedQuickLogIds(String raw) {
        return healthDashboard.orderedQuickLogIds(raw);
    }

    String[] quickLogOption(String id) {
        return healthDashboard.quickLogOption(id);
    }

    String joinIds(List<String> ids) {
        return healthDashboard.joinIds(ids);
    }

    ImageView quickLogIconView(String id) {
        return healthDashboard.quickLogIconView(id);
    }

    ImageView symbolIcon(int resId, int tintColor, int backgroundColor, int sizeDp, int paddingDp) {
        return healthDashboard.symbolIcon(resId, tintColor, backgroundColor, sizeDp, paddingDp);
    }

    void setButtonSymbol(Button button, int resId, int tintColor, int sizeDp) {
        healthDashboard.setButtonSymbol(button, resId, tintColor, sizeDp);
    }

    void setTextSymbol(TextView view, int resId, int tintColor, int sizeDp) {
        healthDashboard.setTextSymbol(view, resId, tintColor, sizeDp);
    }

    int quickLogIconRes(String id) {
        return healthDashboard.quickLogIconRes(id);
    }

    View snapshotCard(String id, String title, boolean compact) {
        return healthDashboard.snapshotCard(id, title, compact);
    }

    ImageView snapshotIconView(String id, int color, boolean compact) {
        return healthDashboard.snapshotIconView(id, color, compact);
    }

    int snapshotIconRes(String id) {
        return healthDashboard.snapshotIconRes(id);
    }

    String quickLogIcon(String id) {
        return healthDashboard.quickLogIcon(id);
    }

    int quickLogColor(String id) {
        return healthDashboard.quickLogColor(id);
    }

    String snapshotIcon(String id) {
        return healthDashboard.snapshotIcon(id);
    }

    int snapshotColor(String id) {
        return healthDashboard.snapshotColor(id);
    }

    String snapshotTitle(String id, String fallback) {
        return healthDashboard.snapshotTitle(id, fallback);
    }

    View therapyView() {
        return therapyScreens.therapyView();
    }

    View milestonesView() {
        return therapyScreens.milestonesView();
    }

    View therapySessionButton(String[] category) {
        return therapyScreens.therapySessionButton(category);
    }

    LinearLayout therapyCard(String[] category, int count) {
        return therapyScreens.therapyCard(category, count);
    }

    LinearLayout therapyHeader() {
        return therapyScreens.therapyHeader();
    }

    ImageView therapyIconView(String id, int tintColor, int backgroundColor, int sizeDp, int paddingDp) {
        return therapyScreens.therapyIconView(id, tintColor, backgroundColor, sizeDp, paddingDp);
    }

    int therapyIconRes(String id) {
        return therapyScreens.therapyIconRes(id);
    }

    String therapyIcon(String id) {
        return therapyScreens.therapyIcon(id);
    }

    int therapyColor(String id) {
        return therapyScreens.therapyColor(id);
    }

    View nutrientView() {
        return nutritionScreens.nutrientView();
    }

    void showNutritionFromHealth() {
        selectedTab = 1;
        clearHealthHistoryPage();
        isNutritionPage = true;
        clearMessage();
        render();
    }

    void closeNutritionPage() {
        isNutritionPage = false;
        render();
    }

    @Override
    public void onBackPressed() {
        if (isNutritionPage) {
            closeNutritionPage();
            return;
        }
        if (isHealthHistoryPage()) {
            clearHealthHistoryPage();
            render();
            return;
        }
        super.onBackPressed();
    }

    LinearLayout nutrientQuotaPill(int left, int limit) {
        return nutritionScreens.nutrientQuotaPill(left, limit);
    }

    LinearLayout nutrientGoalsRow() {
        return nutritionScreens.nutrientGoalsRow();
    }

    View mealPhotoUploadCard() {
        return nutritionScreens.mealPhotoUploadCard();
    }

    LinearLayout nutrientActionButton(String title, int iconRes, int fillColor, int textColor, boolean primary) {
        return nutritionScreens.nutrientActionButton(title, iconRes, fillColor, textColor, primary);
    }

    LinearLayout nutrientSummaryView() {
        return nutritionScreens.nutrientSummaryView();
    }

    LinearLayout nutrientSummaryRow(int iconRes, String label, String value) {
        return nutritionScreens.nutrientSummaryRow(iconRes, label, value);
    }

    String nutrientValue(String raw, String unit) {
        return nutritionScreens.nutrientValue(raw, unit);
    }

    View profileView() {
        return profileScreens.profileView();
    }

    View profileAvatarButton() {
        return profileScreens.profileAvatarButton();
    }

    Bitmap circleBitmap(Bitmap source) {
        return profileScreens.circleBitmap(source);
    }

    LinearLayout profileNavRow(String title, Runnable action) {
        return profileScreens.profileNavRow(title, action);
    }

    void showProfilePhotoDialog() {
        profileScreens.showProfilePhotoDialog();
    }

    void showChoiceSheet(String title, String[] choices, SheetChoiceHandler handler) {
        profileScreens.showChoiceSheet(title, choices, handler);
    }

    void showMessageSheet(String title, String message) {
        profileScreens.showMessageSheet(title, message);
    }

    void chooseProfilePhoto() {
        profileScreens.chooseProfilePhoto();
    }

    void takeProfilePhoto() {
        profileScreens.takeProfilePhoto();
    }

    LinearLayout pageHeader(String title, String subtitle) {
        return profileScreens.pageHeader(title, subtitle);
    }

    LinearLayout pageHeader(String title, String subtitle, String iconText) {
        return profileScreens.pageHeader(title, subtitle, iconText);
    }

    View childAvatarView(int sizeDp) {
        return profileScreens.childAvatarView(sizeDp);
    }

    LinearLayout roundHistoryButton() {
        return profileScreens.roundHistoryButton();
    }

    TextView iconCircle(String text, int textColor, int fillColor, int sizeDp) {
        return profileScreens.iconCircle(text, textColor, fillColor, sizeDp);
    }

    Bitmap bitmapFromDataUrl(String dataUrl) {
        return profileScreens.bitmapFromDataUrl(dataUrl);
    }

    LinearLayout infoRow(String title, String value) {
        return profileScreens.infoRow(title, value);
    }

    void login(String username, String password) {
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
                String pendingKey = "auth.pendingFirstLoginOnboarding." + username.trim().toLowerCase(Locale.US);
                isFirstLoginOnboarding = storage.getInt(pendingKey, 0) == 1
                    && storage.getInt("auth.completedFirstLoginOnboarding." + value.id, 0) == 0;
                onboardingSlide = 0;
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

    void signup(String nickname, String email, String password, String verifyPassword) {
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
                storage.putInt("auth.pendingFirstLoginOnboarding." + cleanNickname.toLowerCase(Locale.US), 1);
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

    void validateSavedSession() {
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

    void restoreServerAppData(CarePortalUser user) {
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

    void putIfBlank(String area, String key, String value) {
        String fullKey = storage.key(area, currentUser.id, key);
        if (storage.getString(fullKey, "").trim().isEmpty()) {
            storage.putString(fullKey, value);
        }
    }

    void logout() {
        api.logout();
        currentUser = null;
        storage.clearSavedUser();
        authScreen = "home";
        selectedTab = 0;
        loginNickname = "";
        resetLoginProtection();
        clearMessage();
        render();
    }

    void resetLoginProtection() {
        failedLoginAttempts = 0;
        captchaRequired = false;
        captchaInput = "";
        captchaCode = makeCaptchaCode();
    }

    void completeCaptchaChallenge() {
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

    void showDiagnosisCategoryDialog() {
        diagnosisScreens.showDiagnosisCategoryDialog();
    }

    void showConditionActions(int index) {
        diagnosisScreens.showConditionActions(index);
    }

    void showConditionDialog(JSONObject existing, int index) {
        diagnosisScreens.showConditionDialog(existing, index);
    }

    Set<String> conditionCategoryIds(JSONObject existing) {
        return diagnosisScreens.conditionCategoryIds(existing);
    }

    LinearLayout conditionFormCard() {
        return diagnosisScreens.conditionFormCard();
    }

    LinearLayout conditionCategoryDropdownCard(Set<String> selected, boolean expanded, Runnable onToggle, Runnable onChanged) {
        return diagnosisScreens.conditionCategoryDropdownCard(selected, expanded, onToggle, onChanged);
    }

    LinearLayout conditionCategoryOptionRow(String[] option, Set<String> selected, Runnable onChanged) {
        return diagnosisScreens.conditionCategoryOptionRow(option, selected, onChanged);
    }

    LinearLayout conditionInputCard(String title, EditText input) {
        return diagnosisScreens.conditionInputCard(title, input);
    }

    LinearLayout conditionPhotoCard(String[] photoData, Runnable onPhotoChanged) {
        return diagnosisScreens.conditionPhotoCard(photoData, onPhotoChanged);
    }

    View conditionPhotoAction(int iconRes, String title) {
        return diagnosisScreens.conditionPhotoAction(iconRes, title);
    }

    int conditionFieldColor() {
        return diagnosisScreens.conditionFieldColor();
    }

    void styleConditionInput(EditText input) {
        diagnosisScreens.styleConditionInput(input);
    }

    void addConditionTextWatcher(EditText input, Runnable afterChange) {
        diagnosisScreens.addConditionTextWatcher(input, afterChange);
    }

    void updateConditionSaveButton(Button save, EditText name) {
        diagnosisScreens.updateConditionSaveButton(save, name);
    }

    void showConditionCategoryDialog(Set<String> selected, Runnable onChanged) {
        diagnosisScreens.showConditionCategoryDialog(selected, onChanged);
    }

    String conditionCategorySummary(Set<String> selected) {
        return diagnosisScreens.conditionCategorySummary(selected);
    }

    void mergeDiagnosisSelections(Set<String> ids) {
        diagnosisScreens.mergeDiagnosisSelections(ids);
    }

    void showDoctorVisitDialog() {
        diagnosisScreens.showDoctorVisitDialog();
    }

    void showQuickLogPicker() {
        quickLogForms.showQuickLogPicker();
    }

    int quickLogIndex(String id) {
        return quickLogForms.quickLogIndex(id);
    }

    void showHealthLogDialog(String id, String title, String type) {
        quickLogForms.showHealthLogDialog(id, title, type);
    }

    void showSeizureTimerDialog(String title) {
        quickLogForms.showSeizureTimerDialog(title);
    }

    void showMeltdownDialog(String title) {
        quickLogForms.showMeltdownDialog(title);
    }

    void showStimmingDialog(String title) {
        quickLogForms.showStimmingDialog(title);
    }

    void showAccidentDialog(String title) {
        quickLogForms.showAccidentDialog(title);
    }

    void showDeescalationDialog(String title) {
        quickLogForms.showDeescalationDialog(title);
    }

    void showAllergyDialog(String title) {
        quickLogForms.showAllergyDialog(title);
    }

    void showPainDialog(String title) {
        quickLogForms.showPainDialog(title);
    }

    LinearLayout painLocationMap(List<String> points) {
        return quickLogForms.painLocationMap(points);
    }

    int nearestPainPoint(List<String> points, float x, float y) {
        return quickLogForms.nearestPainPoint(points, x, y);
    }

    boolean isInsidePainBodyArea(FrameLayout map, float x, float y) {
        return quickLogForms.isInsidePainBodyArea(map, x, y);
    }

    void redrawPainDots(FrameLayout map, List<String> points) {
        quickLogForms.redrawPainDots(map, points);
    }

    String joinLocationPoints(List<String> points) {
        return quickLogForms.joinLocationPoints(points);
    }

    void showDiscomfortDialog(String title) {
        quickLogForms.showDiscomfortDialog(title);
    }

    void showSkinDialog(String title) {
        quickLogForms.showSkinDialog(title);
    }

    LinearLayout skinSeveritySection(String[] selected) {
        return quickLogForms.skinSeveritySection(selected);
    }

    void showMedicineDialog(String title) {
        quickLogForms.showMedicineDialog(title);
    }

    void showAddMedicineDialog(Runnable afterSave) {
        quickLogForms.showAddMedicineDialog(afterSave);
    }

    Calendar defaultDoseTime(int index) {
        return medicationForms.defaultDoseTime(index);
    }

    void rebuildMedicineDoseTimes(LinearLayout container, List<Calendar> times) {
        medicationForms.rebuildMedicineDoseTimes(container, times);
    }

    List<JSONObject> medicineDoseRows(JSONArray meds) {
        return medicationForms.medicineDoseRows(meds);
    }

    String medicineDoseLabel(JSONObject row) {
        return medicationForms.medicineDoseLabel(row);
    }

    int timeSortValue(String time) {
        return medicationForms.timeSortValue(time);
    }

    void showCyclicVomitingDialog(String title) {
        medicationForms.showCyclicVomitingDialog(title);
    }

    void showCyclicVomitingBackgroundDialog() {
        medicationForms.showCyclicVomitingBackgroundDialog();
    }

    void showCyclicVomitingPatternsDialog() {
        medicationForms.showCyclicVomitingPatternsDialog();
    }

    String[] cyclicVomitingMedicineOptions() {
        return medicationForms.cyclicVomitingMedicineOptions();
    }

    Set<String> jsonArrayToSet(JSONArray array) {
        return medicationForms.jsonArrayToSet(array);
    }

    LinearLayout quickFormContent() {
        return medicationForms.quickFormContent();
    }

    LinearLayout sectionCard(String title) {
        return medicationForms.sectionCard(title);
    }

    LinearLayout sectionCardWithChild(String title, View child) {
        return medicationForms.sectionCardWithChild(title, child);
    }

    LinearLayout fieldCard(String title, View child) {
        return medicationForms.fieldCard(title, child);
    }

    Spinner spinner(String[] values) {
        return medicationForms.spinner(values);
    }

    LinearLayout chipSection(String title, String[] options, Set<String> selected) {
        return medicationForms.chipSection(title, options, selected);
    }

    LinearLayout chipSection(String title, String[] options, Set<String> selected, int color) {
        return medicationForms.chipSection(title, options, selected, color);
    }

    LinearLayout singleChoiceSection(String title, String[] options, String[] selected) {
        return medicationForms.singleChoiceSection(title, options, selected);
    }

    LinearLayout singleChoiceSection(String title, String[] options, String[] selected, int color) {
        return medicationForms.singleChoiceSection(title, options, selected, color);
    }

    void prepareChoiceChip(CheckBox chip) {
        medicationForms.prepareChoiceChip(chip);
    }

    void styleChoice(CheckBox chip, boolean selected, int color) {
        medicationForms.styleChoice(chip, selected, color);
    }

    int darkerChoiceColor(int color) {
        return medicationForms.darkerChoiceColor(color);
    }

    void tintSeekBar(SeekBar seekBar, int color) {
        medicationForms.tintSeekBar(seekBar, color);
    }

    boolean isLightColor(int color) {
        return medicationForms.isLightColor(color);
    }

    Dialog showQuickLogForm(String title, LinearLayout content, Runnable onSave) {
        return medicationForms.showQuickLogForm(title, content, onSave);
    }

    String joinChoices(Set<String> selected) {
        return medicationForms.joinChoices(selected);
    }

    String noteLine(String label, String value) {
        return medicationForms.noteLine(label, value);
    }

    String joinNotes(String... parts) {
        return medicationForms.joinNotes(parts);
    }

    int safeInt(String value) {
        return medicationForms.safeInt(value);
    }

    String durationClock(int seconds) {
        return medicationForms.durationClock(seconds);
    }

    String durationText(int seconds) {
        return medicationForms.durationText(seconds);
    }

    String meltdownIntensityText(int value) {
        return medicationForms.meltdownIntensityText(value);
    }

    interface ProgressCallback {

        void onProgress(int progress);
    }

    static final class SimpleSeekListener implements SeekBar.OnSeekBarChangeListener {

        private final ProgressCallback callback;

        SimpleSeekListener(ProgressCallback callback) {
            this.callback = callback;
        }

        @Override
        public void onProgressChanged(SeekBar seekBar, int progress, boolean fromUser) {
            if (callback != null)
                callback.onProgress(progress);
        }

        @Override
        public void onStartTrackingTouch(SeekBar seekBar) {
        }

        @Override
        public void onStopTrackingTouch(SeekBar seekBar) {
        }
    }

    void showDigestionLogDialog(String title) {
        digestionForms.showDigestionLogDialog(title);
    }

    LinearLayout movementTimeCard(Calendar movementTime) {
        return digestionForms.movementTimeCard(movementTime);
    }

    LinearLayout bristolConsistencySection(int[] selectedType, int tint) {
        return digestionForms.bristolConsistencySection(selectedType, tint);
    }

    LinearLayout stoolTypeTile(int type, boolean selected, int tint) {
        return digestionForms.stoolTypeTile(type, selected, tint);
    }

    void styleStoolTypeTile(View tile, boolean selected, int tint) {
        digestionForms.styleStoolTypeTile(tile, selected, tint);
    }

    int bristolDrawable(int type) {
        return digestionForms.bristolDrawable(type);
    }

    String bristolGroup(int type) {
        return digestionForms.bristolGroup(type);
    }

    String bristolDescription(int type) {
        return digestionForms.bristolDescription(type);
    }

    LinearLayout stoolColorSection(String[] selected, int tint) {
        return digestionForms.stoolColorSection(selected, tint);
    }

    LinearLayout stoolColorTile(String name, int swatch, boolean selected, int tint) {
        return digestionForms.stoolColorTile(name, swatch, selected, tint);
    }

    void styleStoolColorTile(View tile, boolean selected, int tint) {
        digestionForms.styleStoolColorTile(tile, selected, tint);
    }

    LinearLayout digestionYesNoRow(String title, String[] selected, int tint) {
        return digestionForms.digestionYesNoRow(title, selected, tint);
    }

    void styleToggleButton(Button button, boolean selected, int tint) {
        digestionForms.styleToggleButton(button, selected, tint);
    }

    String digestionAnswer(String value) {
        return digestionForms.digestionAnswer(value);
    }

    void showBristolInfoSheet(int tint) {
        digestionForms.showBristolInfoSheet(tint);
    }

    void showSleepLogDialog(String title) {
        sleepForms.showSleepLogDialog(title);
    }

    LinearLayout sleepTimeCard(Calendar date, Calendar fellAsleep, Calendar wokeUp) {
        return sleepForms.sleepTimeCard(date, fellAsleep, wokeUp);
    }

    LinearLayout sleepTimeRow(String label, Button button) {
        return sleepForms.sleepTimeRow(label, button);
    }

    Button sleepDateButton(Calendar date, Calendar... linked) {
        return sleepForms.sleepDateButton(date, linked);
    }

    Button sleepTimeButton(Calendar calendar) {
        return sleepForms.sleepTimeButton(calendar);
    }

    Button sleepPickerButton(String text) {
        return sleepForms.sleepPickerButton(text);
    }

    LinearLayout sleepQualityCard(String[] selectedQuality) {
        return sleepForms.sleepQualityCard(selectedQuality);
    }

    LinearLayout sleepQualityOption(String icon, String label, boolean selected) {
        return sleepForms.sleepQualityOption(icon, label, selected);
    }

    void styleSleepQualityOption(LinearLayout card, boolean selected) {
        sleepForms.styleSleepQualityOption(card, selected);
    }

    LinearLayout wakeCounterCard(int[] wakeups) {
        return sleepForms.wakeCounterCard(wakeups);
    }

    TextView sleepCounterButton(String text, int fill, int textColor) {
        return sleepForms.sleepCounterButton(text, fill, textColor);
    }

    LinearLayout timestampCard(Calendar timestamp) {
        return sleepForms.timestampCard(timestamp);
    }

    void styleTimestampButton(Button button) {
        sleepForms.styleTimestampButton(button);
    }

    LinearLayout dateOnlyRow(String label, Calendar date, Calendar... linked) {
        return sleepForms.dateOnlyRow(label, date, linked);
    }

    LinearLayout timeOnlyRow(String label, Calendar calendar) {
        return sleepForms.timeOnlyRow(label, calendar);
    }

    Button dateButton(Calendar calendar) {
        return sleepForms.dateButton(calendar);
    }

    Button timeButton(Calendar calendar) {
        return sleepForms.timeButton(calendar);
    }

    void addHealthEntry(String id, String title, String type, String value, String notes, Calendar timestamp) {
        healthHistoryScreens.addHealthEntry(id, title, type, value, notes, timestamp);
    }

    void addHealthEntry(String id, String title, String type, String value, String notes, Calendar timestamp, String imageData) {
        healthHistoryScreens.addHealthEntry(id, title, type, value, notes, timestamp, imageData);
    }

    void showNotificationsToday() {
        healthHistoryScreens.showNotificationsToday();
    }

    boolean isHealthHistoryPage() {
        return healthHistoryScreens.isHealthHistoryPage();
    }

    void clearHealthHistoryPage() {
        healthHistoryScreens.clearHealthHistoryPage();
    }

    void showHealthHistory(String filterType) {
        healthHistoryScreens.showHealthHistory(filterType);
    }

    View healthHistoryPage() {
        return healthHistoryScreens.healthHistoryPage();
    }

    void addHealthHistoryCategoryPage(LinearLayout screen, JSONArray entries) {
        healthHistoryScreens.addHealthHistoryCategoryPage(screen, entries);
    }

    void addHealthHistoryDetailPage(LinearLayout screen, JSONArray entries) {
        healthHistoryScreens.addHealthHistoryDetailPage(screen, entries);
    }

    void showHealthHistoryDialog(String filterType) {
        healthHistoryScreens.showHealthHistoryDialog(filterType);
    }

    Button historyFilterButton(String title, boolean selected, Runnable action) {
        return healthHistoryScreens.historyFilterButton(title, selected, action);
    }

    View healthHistoryCategoryRow(String type, String id, String title, JSONArray entries) {
        return healthHistoryScreens.healthHistoryCategoryRow(type, id, title, entries);
    }

    String healthCategorySummary(JSONArray entries, String type, String categoryId) {
        return healthHistoryScreens.healthCategorySummary(entries, type, categoryId);
    }

    double fivePointScore(String value) {
        return healthHistoryScreens.fivePointScore(value);
    }

    void showHealthCategoryDetail(String type, String categoryId, String title) {
        healthHistoryScreens.showHealthCategoryDetail(type, categoryId, title);
    }

    View healthHistoryRow(JSONObject item) {
        return healthHistoryScreens.healthHistoryRow(item);
    }

    void showHealthEntryDetail(JSONObject item) {
        healthHistoryScreens.showHealthEntryDetail(item);
    }

    void loadHealthInsights() {
        healthHistoryScreens.loadHealthInsights();
    }

    void showMilestoneDialog(String[] category) {
        therapyScreens.showMilestoneDialog(category);
    }

    void showMilestoneHistory() {
        therapyScreens.showMilestoneHistory();
    }

    void showMilestoneDetail(JSONObject item) {
        therapyScreens.showMilestoneDetail(item);
    }

    void chooseMealPhoto() {
        nutritionScreens.chooseMealPhoto();
    }

    void chooseMealPhotoFromLibrary() {
        nutritionScreens.chooseMealPhotoFromLibrary();
    }

    void takeMealPhoto() {
        nutritionScreens.takeMealPhoto();
    }

    void refreshNutrientQuota() {
        nutritionScreens.refreshNutrientQuota();
    }

    void estimateMeal() {
        nutritionScreens.estimateMeal();
    }

    LinearLayout mealEstimateView(JSONObject estimate) {
        return nutritionScreens.mealEstimateView(estimate);
    }

    void saveCurrentMeal() {
        nutritionScreens.saveCurrentMeal();
    }

    void showManualMealDialog() {
        nutritionScreens.showManualMealDialog();
    }

    void showMealHistory() {
        nutritionScreens.showMealHistory();
    }

    void showMealDetail(JSONObject meal) {
        nutritionScreens.showMealDetail(meal);
    }

    void showBasicInfoDialog() {
        profileScreens.showBasicInfoDialog();
    }

    void syncProfile() {
        profileScreens.syncProfile();
    }

    void syncHealth(JSONArray entries) {
        profileScreens.syncHealth(entries);
    }

    JSONObject childProfileJson() {
        return profileScreens.childProfileJson();
    }

    void showLanguageDialog() {
        profileScreens.showLanguageDialog();
    }

    void showTermsDialog() {
        profileScreens.showTermsDialog();
    }

    void addMessage(LinearLayout panel) {
        if (!message.isEmpty()) {
            panel.addView(Ui.message(this, message, isError), Ui.matchWrap());
            Ui.addSpacer(this, panel, 14);
        }
    }

    void clearMessage() {
        message = "";
        isError = false;
    }

    void showError(String text) {
        message = text == null ? "" : text;
        isError = true;
    }

    String childName() {
        String name = storage.getString(storage.key("profile", currentUser.id, "fullName"), "").trim();
        return name.isEmpty() ? i18n.t("Child profile") : name;
    }

    String latestTodaySummary(String categoryId) {
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

    JSONObject dailyUsage() {
        String key = storage.key("nutrient", currentUser.id, "dailyUsageData");
        JSONObject usage = storage.getObject(key);
        java.text.SimpleDateFormat quotaDate = new java.text.SimpleDateFormat("yyyy-MM-dd", java.util.Locale.ROOT);
        quotaDate.setTimeZone(java.util.TimeZone.getTimeZone("UTC"));
        String quotaDay = quotaDate.format(new java.util.Date());
        if (!quotaDay.equals(usage.optString("dateKey"))) {
            usage = new JSONObject();
            try {
                usage.put("dateKey", quotaDay);
                usage.put("uploadCount", 0);
                usage.put("estimateCount", 0);
            } catch (JSONException ignored) {
            }
            storage.putObject(key, usage);
        }
        return usage;
    }

    LinearLayout photoControls(String title, String[] photoData) {
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

    void chooseGenericPhoto(String[] photoData, TextView status) {
        pendingPhotoCallback = dataUrl -> {
            photoData[0] = dataUrl;
            status.setVisibility(View.VISIBLE);
            status.setText(dataUrl.isEmpty() ? i18n.t("Unable to load photo.") : i18n.t("Photo selected"));
        };
        Intent intent = new Intent(Intent.ACTION_GET_CONTENT);
        intent.setType("image/*");
        startActivityForResult(Intent.createChooser(intent, i18n.t("Choose Photo")), REQUEST_GENERIC_PHOTO_LIBRARY);
    }

    void takeGenericPhoto(String[] photoData, TextView status) {
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

    void finishPendingPhoto(String dataUrl) {
        if (pendingPhotoCallback != null) {
            pendingPhotoCallback.onPhoto(dataUrl == null ? "" : dataUrl);
            pendingPhotoCallback = null;
        }
    }

    void chooseMilestoneMedia(MilestoneMediaCallback callback) {
        pendingMilestoneMediaCallback = callback;
        Intent intent = new Intent(Intent.ACTION_OPEN_DOCUMENT);
        intent.addCategory(Intent.CATEGORY_OPENABLE);
        intent.setType("*/*");
        intent.putExtra(Intent.EXTRA_MIME_TYPES, new String[] { "image/*", "video/*" });
        startActivityForResult(Intent.createChooser(intent, i18n.t("Add Photo or Video")), REQUEST_MILESTONE_MEDIA);
    }

    void finishPendingMilestoneMedia(Uri uri, int flags) {
        if (pendingMilestoneMediaCallback == null) return;
        String type = getContentResolver().getType(uri);
        if (type != null && type.startsWith("video/")) {
            long size = mediaSize(uri);
            long durationMs = videoDuration(uri);
            if (size > 100L * 1024L * 1024L) {
                pendingMilestoneMediaCallback.onError(i18n.t("Videos must be smaller than 100 MB."));
            } else if (durationMs > 30_000L) {
                pendingMilestoneMediaCallback.onError(i18n.t("Videos can be no longer than 30 seconds."));
            } else {
                try {
                    getContentResolver().takePersistableUriPermission(uri, flags & (Intent.FLAG_GRANT_READ_URI_PERMISSION | Intent.FLAG_GRANT_WRITE_URI_PERMISSION));
                } catch (Exception ignored) {
                }
                pendingMilestoneMediaCallback.onVideo(uri.toString());
            }
        } else {
            String photoData = loadImageDataUrl(uri);
            if (photoData.isEmpty()) pendingMilestoneMediaCallback.onError(i18n.t("Unable to load photo."));
            else pendingMilestoneMediaCallback.onPhoto(photoData);
        }
        pendingMilestoneMediaCallback = null;
    }

    long mediaSize(Uri uri) {
        try (android.database.Cursor cursor = getContentResolver().query(uri, new String[] { OpenableColumns.SIZE }, null, null, null)) {
            if (cursor != null && cursor.moveToFirst()) return cursor.getLong(0);
        } catch (Exception ignored) {
        }
        return 0;
    }

    long videoDuration(Uri uri) {
        MediaMetadataRetriever retriever = new MediaMetadataRetriever();
        try {
            retriever.setDataSource(this, uri);
            String raw = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION);
            return raw == null ? 0 : Long.parseLong(raw);
        } catch (Exception ignored) {
            return 0;
        } finally {
            try { retriever.release(); } catch (Exception ignored) { }
        }
    }

    interface MilestoneMediaCallback {
        void onPhoto(String dataUrl);
        void onVideo(String uri);
        void onError(String message);
    }

    String imageDataUrlFromCameraResult(Intent data) {
        if (data == null || data.getExtras() == null)
            return "";
        Object raw = data.getExtras().get("data");
        if (!(raw instanceof Bitmap))
            return "";
        return bitmapToDataUrl((Bitmap) raw);
    }

    String bitmapToDataUrl(Bitmap bitmap) {
        if (bitmap == null)
            return "";
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

    String loadImageDataUrl(Uri uri) {
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

    interface PhotoCallback {

        void onPhoto(String dataUrl);
    }

    Set<String> commaSet(String raw) {
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

    int countBy(JSONArray array, String field, String value) {
        int count = 0;
        for (int i = 0; i < array.length(); i++) {
            JSONObject item = array.optJSONObject(i);
            if (item != null && value.equals(item.optString(field))) {
                count++;
            }
        }
        return count;
    }

    String initials(String name) {
        String clean = name == null ? "" : name.trim();
        if (clean.isEmpty())
            return "CP";
        String[] parts = clean.split("\\s+");
        StringBuilder builder = new StringBuilder();
        for (String part : parts) {
            if (!part.isEmpty() && builder.length() < 2) {
                builder.append(part.substring(0, 1).toUpperCase(Locale.US));
            }
        }
        return builder.length() == 0 ? "CP" : builder.toString();
    }

    String nowIso() {
        return new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSSZ", Locale.US).format(new Date());
    }

    String formatIso(Calendar calendar) {
        return new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSSZ", Locale.US).format(calendar.getTime());
    }

    String formatDisplayDate(Calendar calendar) {
        return new SimpleDateFormat("MMM d, yyyy", Locale.US).format(calendar.getTime());
    }

    String formatDisplayTime(Calendar calendar) {
        return new SimpleDateFormat("h:mm a", Locale.US).format(calendar.getTime());
    }

    String displayDateTime(String iso) {
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

    String notesPreview(String notes) {
        if (notes == null) {
            return "";
        }
        String clean = notes.replace("\n", " · ").trim();
        if (clean.length() <= 90) {
            return clean;
        }
        return clean.substring(0, 90) + "...";
    }

    int minutesBetween(Calendar start, Calendar end) {
        long diff = end.getTimeInMillis() - start.getTimeInMillis();
        if (diff <= 0) {
            diff += 24L * 60L * 60L * 1000L;
        }
        return Math.max(0, Math.round(diff / 60000f));
    }

    String formatSleepDuration(int minutes) {
        int hours = minutes / 60;
        int mins = minutes % 60;
        if (mins == 0) {
            return hours + "h";
        }
        return hours + "h " + mins + "m";
    }

    String todayKey() {
        return new SimpleDateFormat("yyyy-MM-dd", Locale.US).format(new Date());
    }

    static String makeCaptchaCode() {
        String source = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
        Random random = new Random();
        StringBuilder builder = new StringBuilder();
        for (int i = 0; i < 4; i++) {
            builder.append(source.charAt(random.nextInt(source.length())));
        }
        return builder.toString();
    }

    private final AuthScreens authScreens = new AuthScreens(this);

    private final DiagnosisScreens diagnosisScreens = new DiagnosisScreens(this);

    private final HealthDashboard healthDashboard = new HealthDashboard(this);

    private final TherapyScreens therapyScreens = new TherapyScreens(this);

    private final NutritionScreens nutritionScreens = new NutritionScreens(this);

    private final ProfileScreens profileScreens = new ProfileScreens(this);

    private final QuickLogForms quickLogForms = new QuickLogForms(this);

    private final MedicationForms medicationForms = new MedicationForms(this);

    private final DigestionForms digestionForms = new DigestionForms(this);

    private final SleepForms sleepForms = new SleepForms(this);

    private final HealthHistoryScreens healthHistoryScreens = new HealthHistoryScreens(this);
}
