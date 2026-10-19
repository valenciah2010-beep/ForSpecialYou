package com.forspecialyou.careportal;

import android.text.InputType;
import android.view.Gravity;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.CheckBox;
import android.widget.EditText;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;
import java.util.Set;

final class AuthScreens {

    private final MainActivity host;

    AuthScreens(MainActivity host) {
        this.host = host;
    }

    void renderAuth() {
        LinearLayout screen = Ui.screen(host);
        LinearLayout panel = Ui.panel(host);
        screen.addView(panel, Ui.matchWrap());
        if ("login".equals(host.authScreen)) {
            host.renderLogin(panel);
        } else if ("signup".equals(host.authScreen)) {
            host.renderSignup(panel);
        } else {
            host.renderHome(panel);
        }
        host.setContentView(Ui.scroll(host, screen));
    }

    void renderHome(LinearLayout panel) {
        LinearLayout top = Ui.h(host, 0);
        TextView spacer = new TextView(host);
        top.addView(spacer, new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1));
        Button language = Ui.secondary(host, host.i18n.languageDisplayName());
        language.setOnClickListener(v -> host.showLanguageDialog());
        top.addView(language, Ui.wrapWrap());
        panel.addView(top, Ui.matchWrap());
        Ui.addSpacer(host, panel, 18);
        ImageView logo = new ImageView(host);
        logo.setImageResource(R.drawable.care_portal_logo);
        logo.setAdjustViewBounds(true);
        logo.setScaleType(ImageView.ScaleType.FIT_CENTER);
        LinearLayout.LayoutParams logoParams = Ui.fixed(host, 120, 120);
        logoParams.gravity = Gravity.CENTER_HORIZONTAL;
        panel.addView(logo, logoParams);
        Ui.addSpacer(host, panel, 16);
        TextView brand = Ui.title(host, host.i18n.t("Care Portal"));
        brand.setGravity(Gravity.CENTER);
        panel.addView(brand, Ui.matchWrap());
        Ui.addSpacer(host, panel, 20);
        TextView offer = Ui.text(host, host.i18n.t("For Special You"), 24, AppColors.TEXT, android.graphics.Typeface.BOLD);
        offer.setGravity(Gravity.CENTER);
        panel.addView(offer, Ui.matchWrap());
        Ui.addSpacer(host, panel, 8);
        TextView intro = Ui.muted(host, host.i18n.t("A parent-run care space for tracking your child's health, routines, and support needs."));
        intro.setGravity(Gravity.CENTER);
        panel.addView(intro, Ui.matchWrap());
        Ui.addSpacer(host, panel, 22);
        Button login = Ui.primary(host, host.i18n.t("Log In"));
        login.setOnClickListener(v -> {
            host.authScreen = "login";
            host.clearMessage();
            host.render();
        });
        panel.addView(login, Ui.matchWrap());
        Ui.addSpacer(host, panel, 12);
        Button signup = Ui.secondary(host, host.i18n.t("Create Parent Account"));
        signup.setOnClickListener(v -> {
            host.authScreen = "signup";
            host.clearMessage();
            host.render();
        });
        panel.addView(signup, Ui.matchWrap());
    }

    void renderLogin(LinearLayout panel) {
        Button home = Ui.secondary(host, "< " + host.i18n.t("Home"));
        home.setOnClickListener(v -> {
            host.authScreen = "home";
            host.clearMessage();
            host.render();
        });
        panel.addView(home, Ui.wrapWrap());
        Ui.addSpacer(host, panel, 16);
        panel.addView(Ui.sectionTitle(host, host.i18n.t("Welcome Back")), Ui.matchWrap());
        Ui.addSpacer(host, panel, 16);
        EditText username = Ui.edit(host, host.i18n.t("Parent Username"));
        username.setText(host.loginNickname);
        panel.addView(Ui.fieldGroup(host, host.i18n.t("Parent Username"), username), Ui.matchWrap());
        Ui.addSpacer(host, panel, 14);
        EditText password = Ui.password(host, host.i18n.t("Password"));
        password.setEnabled(!host.captchaRequired);
        panel.addView(Ui.fieldGroup(host, host.i18n.t("Password"), password), Ui.matchWrap());
        Ui.addSpacer(host, panel, 14);
        EditText captcha = null;
        if (host.captchaRequired) {
            LinearLayout challenge = Ui.panel(host);
            challenge.setBackground(Ui.round(Ui.withAlpha(AppColors.ACCENT, 20), Ui.dp(host, 12)));
            LinearLayout row = Ui.h(host, 0);
            TextView code = Ui.text(host, host.captchaCode, 18, AppColors.TEXT, android.graphics.Typeface.BOLD);
            code.setGravity(Gravity.CENTER);
            code.setLetterSpacing(0.12f);
            code.setBackground(Ui.stroke(AppColors.FIELD, Ui.withAlpha(AppColors.ACCENT, 60), Ui.dp(host, 9)));
            row.addView(code, Ui.fixed(host, 98, 40));
            EditText captchaEdit = Ui.edit(host, "Code");
            captchaEdit.setInputType(InputType.TYPE_CLASS_TEXT | InputType.TYPE_TEXT_FLAG_CAP_CHARACTERS);
            LinearLayout.LayoutParams capParams = new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1);
            capParams.leftMargin = Ui.dp(host, 10);
            row.addView(captchaEdit, capParams);
            Button refresh = Ui.secondary(host, "Refresh");
            refresh.setOnClickListener(v -> {
                host.captchaCode = host.makeCaptchaCode();
                host.captchaInput = "";
                host.render();
            });
            LinearLayout.LayoutParams refreshParams = Ui.wrapWrap();
            refreshParams.leftMargin = Ui.dp(host, 8);
            row.addView(refresh, refreshParams);
            challenge.addView(row, Ui.matchWrap());
            panel.addView(challenge, Ui.matchWrap());
            Ui.addSpacer(host, panel, 14);
            captcha = captchaEdit;
        }
        host.addMessage(panel);
        CheckBox terms = Ui.check(host, host.i18n.t("I agree to the Terms and Conditions before using this app."));
        terms.setOnLongClickListener(v -> {
            host.showTermsDialog();
            return true;
        });
        terms.setOnClickListener(v -> {
            if (!terms.isChecked()) {
                return;
            }
        });
        terms.setOnCheckedChangeListener((buttonView, isChecked) -> {
            if (isChecked) {
                host.showTermsDialog();
            }
        });
        panel.addView(terms, Ui.matchWrap());
        Ui.addSpacer(host, panel, 14);
        Button submit = Ui.primary(host, host.isLoading ? host.i18n.t("Logging In...") : (host.captchaRequired ? host.i18n.t("Verify Code") : host.i18n.t("Log In")));
        EditText finalCaptcha = captcha;
        submit.setOnClickListener(v -> {
            if (!terms.isChecked()) {
                host.showError(host.i18n.t("I agree to the Terms and Conditions before using this app."));
                host.render();
                return;
            }
            host.loginNickname = username.getText().toString();
            if (host.captchaRequired) {
                host.captchaInput = finalCaptcha == null ? "" : finalCaptcha.getText().toString();
                host.completeCaptchaChallenge();
            } else {
                host.login(host.loginNickname, password.getText().toString());
            }
        });
        panel.addView(submit, Ui.matchWrap());
        Ui.addSpacer(host, panel, 10);
        Button signup = Ui.secondary(host, host.i18n.t("Need an account? Sign up"));
        signup.setOnClickListener(v -> {
            host.authScreen = "signup";
            host.clearMessage();
            host.render();
        });
        panel.addView(signup, Ui.matchWrap());
    }

    void renderSignup(LinearLayout panel) {
        Button home = Ui.secondary(host, "< " + host.i18n.t("Home"));
        home.setOnClickListener(v -> {
            host.authScreen = "home";
            host.clearMessage();
            host.render();
        });
        panel.addView(home, Ui.wrapWrap());
        Ui.addSpacer(host, panel, 16);
        panel.addView(Ui.sectionTitle(host, host.i18n.t("Create Parent Account")), Ui.matchWrap());
        Ui.addSpacer(host, panel, 4);
        panel.addView(Ui.muted(host, host.i18n.t("Set up a parent login to track your child's care.")), Ui.matchWrap());
        Ui.addSpacer(host, panel, 16);
        EditText nickname = Ui.edit(host, host.i18n.t("Parent Username"));
        nickname.setText(host.signupNickname);
        EditText email = Ui.edit(host, host.i18n.t("Email"));
        email.setInputType(InputType.TYPE_CLASS_TEXT | InputType.TYPE_TEXT_VARIATION_EMAIL_ADDRESS);
        EditText password = Ui.password(host, host.i18n.t("Password"));
        EditText verify = Ui.password(host, host.i18n.t("Verify Password"));
        panel.addView(Ui.fieldGroup(host, host.i18n.t("Parent Username"), nickname), Ui.matchWrap());
        Ui.addSpacer(host, panel, 14);
        panel.addView(Ui.fieldGroup(host, host.i18n.t("Email"), email), Ui.matchWrap());
        Ui.addSpacer(host, panel, 14);
        panel.addView(Ui.fieldGroup(host, host.i18n.t("Password"), password), Ui.matchWrap());
        Ui.addSpacer(host, panel, 14);
        panel.addView(Ui.fieldGroup(host, host.i18n.t("Verify Password"), verify), Ui.matchWrap());
        Ui.addSpacer(host, panel, 14);
        host.addMessage(panel);
        CheckBox terms = Ui.check(host, host.i18n.t("I agree to the Terms and Conditions before using this app."));
        terms.setOnCheckedChangeListener((buttonView, isChecked) -> {
            if (isChecked) {
                host.showTermsDialog();
            }
        });
        panel.addView(terms, Ui.matchWrap());
        Ui.addSpacer(host, panel, 14);
        Button submit = Ui.primary(host, host.isLoading ? host.i18n.t("Creating Account...") : host.i18n.t("Create Parent Account"));
        submit.setOnClickListener(v -> {
            if (!terms.isChecked()) {
                host.showError(host.i18n.t("I agree to the Terms and Conditions before using this app."));
                host.render();
                return;
            }
            host.signupNickname = nickname.getText().toString();
            host.signup(host.signupNickname, email.getText().toString(), password.getText().toString(), verify.getText().toString());
        });
        panel.addView(submit, Ui.matchWrap());
        Ui.addSpacer(host, panel, 10);
        Button login = Ui.secondary(host, host.i18n.t("Already have an account? Log in"));
        login.setOnClickListener(v -> {
            host.authScreen = "login";
            host.clearMessage();
            host.render();
        });
        panel.addView(login, Ui.matchWrap());
    }
}
