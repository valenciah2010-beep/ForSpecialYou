package com.forspecialyou.careportal;

import java.util.HashMap;
import java.util.Locale;
import java.util.Map;

final class I18n {
    static final String EN = "en";
    static final String ZH = "zh-Hans";

    private final Storage storage;
    private final Map<String, String> zh = new HashMap<>();

    I18n(Storage storage) {
        this.storage = storage;
        seedChinese();
    }

    String language() {
        return storage.getString("app.languageCode", EN);
    }

    void setLanguage(String language) {
        storage.putString("app.languageCode", language);
    }

    String languageDisplayName() {
        return ZH.equals(language()) ? "中文" : "English";
    }

    String apiLanguageName() {
        return ZH.equals(language()) ? "Simplified Chinese" : "English";
    }

    String t(String key) {
        if (ZH.equals(language())) {
            String translated = zh.get(key);
            if (translated != null) {
                return translated;
            }
        }
        return key;
    }

    String server(String message) {
        if (message == null) {
            return "";
        }
        String trimmed = message.trim();
        String prefix = "This account is blocked until ";
        if (trimmed.startsWith(prefix) && trimmed.endsWith(".")) {
            String date = trimmed.substring(prefix.length(), trimmed.length() - 1);
            return String.format(Locale.US, t("This account is blocked until %s."), date);
        }
        return t(trimmed);
    }

    private void seedChinese() {
        zh.put("For Special You", "For Special You");
        zh.put("A parent-run care space for tracking your child's health, routines, and support needs.", "由家长使用的照护空间，用来记录孩子的健康、日常和支持需求。");
        zh.put("Log In", "登录");
        zh.put("Create Parent Account", "创建家长账号");
        zh.put("Welcome Back", "欢迎回来");
        zh.put("Parent Username", "家长用户名");
        zh.put("Password", "密码");
        zh.put("Verify Password", "确认密码");
        zh.put("Email", "邮箱");
        zh.put("Need an account? Sign up", "还没有账号？注册");
        zh.put("Already have an account? Log in", "已有账号？登录");
        zh.put("Set up a parent login to track your child's care.", "创建家长登录，用来跟踪孩子的照护记录。");
        zh.put("I agree to the Terms and Conditions before using this app.", "使用本应用前，我同意条款与条件。");
        zh.put("Terms and Conditions", "条款与条件");
        zh.put("Terms of Use", "使用条款");
        zh.put("Done", "完成");
        zh.put("Home", "首页");
        zh.put("Language", "语言");
        zh.put("Please enter your parent username and password.", "请输入家长用户名和密码。");
        zh.put("Please enter your nickname and password.", "请输入昵称和密码。");
        zh.put("Please fill out every field.", "请填写所有字段。");
        zh.put("Please enter a valid email address.", "请输入有效邮箱地址。");
        zh.put("Password must be at least 6 characters and include one number.", "密码至少 6 位，并包含一个数字。");
        zh.put("Passwords do not match.", "两次输入的密码不一致。");
        zh.put("Too many incorrect attempts. Please complete the verification code.", "错误次数过多，请完成验证码。");
        zh.put("Please enter the verification code shown.", "请输入图中显示的验证码。");
        zh.put("Verification complete. Please enter your password again.", "验证完成，请重新输入密码。");
        zh.put("Logging In...", "正在登录...");
        zh.put("Creating Account...", "正在创建账号...");
        zh.put("Verify Code", "验证");
        zh.put("Diagnosis", "诊断");
        zh.put("Category", "分类");
        zh.put("Health", "健康");
        zh.put("Therapy", "康复");
        zh.put("Nutrient", "营养");
        zh.put("Profile", "我的");
        zh.put("%s's Day", "%s的一天");
        zh.put("Monitored by %s", "由 %s 记录");
        zh.put("Edit", "编辑");
        zh.put("Save", "保存");
        zh.put("Delete", "删除");
        zh.put("Cancel", "取消");
        zh.put("Conditions", "诊断情况");
        zh.put("No conditions added yet.", "还没有添加诊断情况。");
        zh.put("Add condition", "添加诊断情况");
        zh.put("New Condition", "新诊断情况");
        zh.put("Edit Condition", "编辑诊断情况");
        zh.put("Select category", "选择分类");
        zh.put("Condition Name", "诊断名称");
        zh.put("Enter condition name", "输入诊断名称");
        zh.put("Add notes", "添加备注");
        zh.put("Photos", "照片");
        zh.put("Upload Photo", "上传照片");
        zh.put("Doctor Visit", "就诊记录");
        zh.put("No records yet.", "暂无记录。");
        zh.put("Quick-log buttons", "快速记录");
        zh.put("Daily Snapshot", "每日快照");
        zh.put("All", "全部");
        zh.put("Insights & Alerts", "洞察与提醒");
        zh.put("Choose quick-log buttons", "选择快速记录按钮");
        zh.put("History", "历史");
        zh.put("Refresh insights", "刷新洞察");
        zh.put("Timestamp", "时间");
        zh.put("Date", "日期");
        zh.put("Sleep Times", "睡眠时间");
        zh.put("Fell asleep at", "入睡时间");
        zh.put("Woke up at", "醒来时间");
        zh.put("Sleep quality", "睡眠质量");
        zh.put("Rest Quality", "休息质量");
        zh.put("Restless", "睡不安稳");
        zh.put("Normal", "正常");
        zh.put("Deep", "深睡/安稳");
        zh.put("Waking Counter", "夜醒计数");
        zh.put("Wake-ups", "夜醒次数");
        zh.put("wake-ups", "次醒来");
        zh.put("Nap, bedtime routine, night waking, comfort item, etc.", "午睡、睡前流程、夜醒、安抚物品等");
        zh.put("Notes", "备注");
        zh.put("Save Log", "保存记录");
        zh.put("Pause", "暂停");
        zh.put("Resume", "继续");
        zh.put("Stop", "停止");
        zh.put("Skip", "跳过");
        zh.put("Minutes", "分钟");
        zh.put("Seconds", "秒");
        zh.put("Seizure Timer", "癫痫计时器");
        zh.put("Seizure Type", "癫痫类型");
        zh.put("Triggers", "诱因");
        zh.put("flashing lights, missed sleep, heat, illness, etc.", "闪光、睡眠不足、炎热、疾病等");
        zh.put("Post-event notes", "发作后备注");
        zh.put("Intensity", "强度");
        zh.put("Mild Agitation/Crying", "轻度烦躁/哭闹");
        zh.put("Mild Meltdown", "轻度情绪崩溃");
        zh.put("Moderate Meltdown", "中度情绪崩溃");
        zh.put("Strong Meltdown", "较强情绪崩溃");
        zh.put("Severe Meltdown/Safety Risk", "严重情绪崩溃/安全风险");
        zh.put("Duration", "持续时间");
        zh.put("Calming Tools Tried", "尝试过的安抚工具");
        zh.put("Behavior Type", "行为类型");
        zh.put("Frequency", "频率");
        zh.put("Apparent State", "看起来的状态");
        zh.put("Context / Setting", "情境/场景");
        zh.put("Accident Type", "意外类型");
        zh.put("Did they signal or try to go?", "是否有示意或尝试去厕所？");
        zh.put("Signaled Beforehand?", "是否提前示意？");
        zh.put("Tools Used", "使用的工具");
        zh.put("Effectiveness", "效果");
        zh.put("Time to Baseline", "恢复平静用时");
        zh.put("Severity", "严重程度");
        zh.put("Pain Location", "疼痛位置");
        zh.put("Indicators", "表现");
        zh.put("crying, holding head, aggression", "哭闹、抱头、攻击行为等");
        zh.put("Short comment", "简短备注");
        zh.put("Severity Level", "严重程度");
        zh.put("Location", "位置");
        zh.put("Suspected Trigger", "疑似诱因");
        zh.put("Symptom Tags", "症状标签");
        zh.put("Seek immediate medical attention", "请立即寻求医疗帮助");
        zh.put("Severe skin symptoms can require urgent care or an EpiPen if prescribed.", "严重皮肤症状可能需要紧急就医；如医生开具过 EpiPen，请按医嘱使用。");
        zh.put("OK", "好的");
        zh.put("Medicine", "药物");
        zh.put("Today's Medicines", "今日药物");
        zh.put("Add Medicine", "添加药物");
        zh.put("Medicine Name", "药物名称");
        zh.put("Dose", "剂量");
        zh.put("What Time?", "服药时间");
        zh.put("None", "无");
        zh.put("Time Tracking", "时间追踪");
        zh.put("Vomiting Start Time", "呕吐开始时间");
        zh.put("Vomiting End Time", "呕吐结束时间");
        zh.put("Hospitalized for this episode?", "本次是否住院？");
        zh.put("Triggers before this vomiting episode", "本次呕吐前诱因");
        zh.put("Symptoms before this vomiting episode started", "呕吐开始前症状");
        zh.put("Symptoms during this vomiting episode", "呕吐期间症状");
        zh.put("Symptoms after vomiting stopped", "呕吐停止后至恢复前症状");
        zh.put("Times per Day", "每天次数");
        zh.put("Current medications in use", "目前使用药物");
        zh.put("Vomiting", "呕吐");
        zh.put("Hospitalized", "住院");
        zh.put("Before", "发作前");
        zh.put("During", "发作中");
        zh.put("Recovery", "恢复期");
        zh.put("Allergic Reaction", "过敏反应");
        zh.put("Discomfort", "不适");
        zh.put("Symptoms", "症状");
        zh.put("Signs", "表现");
        zh.put("Possible Cause", "可能原因");
        zh.put("Severe allergic symptoms can require urgent care or an EpiPen if prescribed.", "严重过敏症状可能需要紧急就医；如医生开具过 EpiPen，请按医嘱使用。");
        zh.put("Seizure Track", "癫痫记录");
        zh.put("Seizure", "癫痫");
        zh.put("Meltdown", "情绪崩溃");
        zh.put("Stimming/Tics", "刻板行为/抽动");
        zh.put("Accident", "如厕意外");
        zh.put("De-escalation", "安抚降级");
        zh.put("Pain", "疼痛");
        zh.put("Skin", "皮肤");
        zh.put("Meds/Food", "药物");
        zh.put("Cyclic Vomiting", "周期性呕吐");
        zh.put("Sleep / Rest", "睡眠与休息");
        zh.put("Sleep", "睡眠");
        zh.put("Digestion", "肠胃与消化");
        zh.put("Bowel Movement", "排便");
        zh.put("Gut & Digestion", "肠胃与消化");
        zh.put("Movement time", "排便时间");
        zh.put("Time", "时间");
        zh.put("Consistency", "性状");
        zh.put("The Bristol Stool Chart", "布里斯托大便分类表");
        zh.put("Bristol Stool Chart", "布里斯托大便分类表");
        zh.put("Type", "类型");
        zh.put("Constipation", "便秘");
        zh.put("Optimal", "理想");
        zh.put("Diarrhea/Intolerance", "腹泻/不耐受");
        zh.put("Separate hard lumps, like little pebbles.", "分离的硬块，像小石子。");
        zh.put("Hard and lumpy, starting to resemble a sausage.", "硬且结块，开始像香肠。");
        zh.put("Sausage-shaped with cracks on the surface.", "香肠状，表面有裂纹。");
        zh.put("Smooth and soft, snake-like.", "光滑柔软，蛇状。");
        zh.put("Soft blobs with clear-cut edges.", "柔软小块，边缘清楚。");
        zh.put("Fluffy, mushy pieces with ragged edges.", "蓬松糊状，边缘不规则。");
        zh.put("Watery with no solid pieces.", "水样，无固体块。");
        zh.put("Volume", "量");
        zh.put("Small", "少量");
        zh.put("Medium", "中等");
        zh.put("Large", "大量");
        zh.put("Color Check", "颜色检查");
        zh.put("Brown", "棕色");
        zh.put("Green", "绿色");
        zh.put("Clay/White", "陶土色/白色");
        zh.put("Black", "黑色");
        zh.put("Red", "红色");
        zh.put("Color", "颜色");
        zh.put("Pain & Strain", "疼痛与用力");
        zh.put("Straining/Discomfort during the movement?", "排便时是否用力或不适？");
        zh.put("Excessive gas or bloating noticed afterward?", "之后是否有明显胀气或腹胀？");
        zh.put("Visible undigested food in the stool?", "粪便中是否有可见未消化食物？");
        zh.put("Straining/Discomfort", "用力/不适");
        zh.put("Gas/Bloating", "胀气/腹胀");
        zh.put("Undigested Food", "未消化食物");
        zh.put("Yes", "是");
        zh.put("No", "否");
        zh.put("Nutrition", "营养");
        zh.put("Mood", "心情");
        zh.put("Height", "身高");
        zh.put("Weight", "体重");
        zh.put("Log", "记录");
        zh.put("Dashboard", "仪表盘");
        zh.put("Child profile", "孩子档案");
        zh.put("Therapy Tracking", "康复追踪");
        zh.put("Log milestones and therapy wins to see your child's progress over time.", "记录里程碑和治疗进步，查看孩子的长期改善。");
        zh.put("Therapy Session", "治疗课程");
        zh.put("Physical", "物理治疗");
        zh.put("Occupational", "作业治疗");
        zh.put("Speech", "语言治疗");
        zh.put("Behavioral/RDI", "行为/RDI");
        zh.put("Social", "社交");
        zh.put("Feeding", "进食训练");
        zh.put("Appointments, exercises, notes", "预约、练习、备注");
        zh.put("Balance, strength, stairs, movement", "平衡、力量、楼梯、运动");
        zh.put("Fine motor, sensory, dressing, daily skills", "精细动作、感统、穿衣和日常技能");
        zh.put("Words, AAC, requests, social communication", "词语、AAC、表达需求、社交沟通");
        zh.put("Transitions, regulation, coping, routines", "转换、情绪调节、应对和日常流程");
        zh.put("Play, turn-taking, peer interaction", "游戏、轮流和同伴互动");
        zh.put("Textures, chewing, new foods, hydration", "食物质地、咀嚼、新食物、饮水");
        zh.put("Recent Milestones", "最近里程碑");
        zh.put("No milestones logged yet.", "还没有记录里程碑。");
        zh.put("Milestone", "里程碑");
        zh.put("Support level", "支持程度");
        zh.put("Add Meal Manually", "手动添加餐食");
        zh.put("Meal", "餐食");
        zh.put("Meal Details", "餐食详情");
        zh.put("Calories", "热量");
        zh.put("Protein", "蛋白质");
        zh.put("Carbs", "碳水");
        zh.put("Fats", "脂肪");
        zh.put("Meals", "餐食");
        zh.put("Macros", "宏量营养");
        zh.put("analyzed", "已分析");
        zh.put("Choose Photo", "选择照片");
        zh.put("Take Photo", "拍照");
        zh.put("Meal Photo", "餐食照片");
        zh.put("Skin Photo", "皮肤照片");
        zh.put("Photo", "照片");
        zh.put("Documents / Photos", "文件 / 照片");
        zh.put("No photo selected.", "还没有选择照片。");
        zh.put("Unable to load photo.", "无法载入照片。");
        zh.put("Camera is not available.", "无法使用相机。");
        zh.put("Photo attached", "已附加照片");
        zh.put("Photo selected", "已选择照片");
        zh.put("Estimates Left Today", "今日剩余估算");
        zh.put("Estimate Nutrients", "估算营养");
        zh.put("Estimating...", "正在估算...");
        zh.put("Save Meal", "保存餐食");
        zh.put("Saved", "已保存");
        zh.put("Meal history", "餐食历史");
        zh.put("Daily nutrient estimate limit reached with limit %s.", "今日营养估算次数已达上限：%s。");
        zh.put("Meal saved to history.", "餐食已保存到历史。");
        zh.put("Manual meal saved to history.", "手动餐食已保存到历史。");
        zh.put("Parent Account", "家长账号");
        zh.put("Parent Email", "家长邮箱");
        zh.put("Account Type", "账号类型");
        zh.put("Parent", "家长");
        zh.put("Settings", "设置");
        zh.put("Log Out", "退出登录");
        zh.put("Parent account for your child's care.", "用于孩子照护的家长账号。");
        zh.put("Child Profile", "孩子档案");
        zh.put("Child Name", "孩子姓名");
        zh.put("Date of Birth", "出生日期");
        zh.put("Support Needs", "支持需求");
        zh.put("Home / School Notes", "家庭 / 学校备注");
        zh.put("Emergency Contact", "紧急联系人");
        zh.put("Care Notes", "照护备注");
        zh.put("This account is blocked until %s.", "该账号被封禁至 %s。");
        zh.put("Unable to reach the server.", "无法连接服务器。");
        zh.put("The server sent an unexpected response.", "服务器返回了异常响应。");
        zh.put("The server address is not valid.", "服务器地址无效。");
        zh.put("Invalid nickname or password.", "昵称或密码无效。");
        zh.put("Account created successfully.", "账号创建成功。");
        zh.put("This email has already been used.", "该邮箱已被使用。");
        zh.put("This nickname is already in use.", "该昵称已被使用。");
        zh.put("Nickname or email is already in use.", "昵称或邮箱已被使用。");
        zh.put("Could not create account right now.", "当前无法创建账号。");
        zh.put("Please log in again.", "请重新登录。");
    }
}
