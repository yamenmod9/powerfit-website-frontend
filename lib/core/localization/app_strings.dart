/// Centralized bilingual (Arabic/English) strings for the entire app.
/// All UI strings are organized by feature area. Dynamic values (names,
/// IDs, numbers) stay as parameters.
///
/// Every entry is a runtime getter (not `const`) so it can react to the
/// active language via [S.setArabic]/[S.isArabic] — the tradeoff is that
/// callers can no longer wrap these in a `const` widget (e.g.
/// `const Text(S.login)` must become `Text(S.login)`).
class S {
  S._();

  static bool _ar = true;

  /// True if Arabic is active (the default). Set via [setArabic].
  static bool get isArabic => _ar;

  /// Switch the active language for every S.xxx getter. Call this whenever
  /// the app's locale changes (see LocaleProvider) — no rebuild is implied
  /// here; the caller is responsible for triggering one (LocaleProvider
  /// does this via notifyListeners()).
  static void setArabic(bool value) => _ar = value;

  static String _t(String ar, String en) => _ar ? ar : en;

  // ─── COMMON / SHARED ────────────────────────────────────────
  static String get login => _t('تسجيل الدخول', 'Log in');
  static String get logout => _t('تسجيل الخروج', 'Log out');
  static String get cancel => _t('إلغاء', 'Cancel');
  static String get close => _t('إغلاق', 'Close');
  static String get confirm => _t('تأكيد', 'Confirm');
  static String get retry => _t('إعادة المحاولة', 'Retry');
  static String get save => _t('حفظ', 'Save');
  static String get apply => _t('تطبيق', 'Apply');
  static String get clear => _t('مسح', 'Clear');
  static String get submit => _t('إرسال', 'Submit');
  static String get ok => _t('حسناً', 'OK');
  static String get yes => _t('نعم', 'Yes');
  static String get no => _t('لا', 'No');
  static String get back => _t('رجوع', 'Back');
  static String get continueText => _t('متابعة', 'Continue');
  static String get refresh => _t('تحديث', 'Refresh');
  static String get loading => _t('جاري التحميل...', 'Loading...');
  static String get error => _t('خطأ', 'Error');
  static String get required => _t('مطلوب', 'Required');
  static String get settings => _t('الإعدادات', 'Settings');
  static String get active => _t('نشط', 'Active');
  static String get inactive => _t('غير نشط', 'Inactive');
  static String get unknown => _t('غير معروف', 'Unknown');
  static String get na => _t('غير متوفر', 'N/A');
  static String get viewAll => _t('عرض الكل', 'View all');
  static String get viewDetails => _t('عرض التفاصيل', 'View details');
  static String get or => _t('أو', 'or');
  static String get register => _t('تسجيل', 'Register');
  static String get delete => _t('حذف', 'Delete');
  static String get edit => _t('تعديل', 'Edit');
  static String get activate => _t('تفعيل', 'Activate');
  static String get deactivate => _t('إلغاء التفعيل', 'Deactivate');
  static String get pending => _t('معلق', 'Pending');
  static String get approved => _t('موافق عليه', 'Approved');
  static String get change => _t('تغيير', 'Change');

  // ─── LOGIN SCREEN ───────────────────────────────────────────
  static String get managementSystem => _t('نظام الإدارة', 'Management System');
  static String get loginFailed => _t('فشل تسجيل الدخول', 'Login failed');
  static String get username => _t('اسم المستخدم', 'Username');
  static String get enterUsername => _t('أدخل اسم المستخدم', 'Enter your username');
  static String get usernameRequired => _t('اسم المستخدم مطلوب', 'Username is required');
  static String get password => _t('كلمة المرور', 'Password');
  static String get enterPassword => _t('أدخل كلمة المرور', 'Enter your password');
  static String get passwordRequired => _t('كلمة المرور مطلوبة', 'Password is required');
  static String get loginWithBiometrics => _t('تسجيل الدخول بالبصمة', 'Log in with biometrics');
  static String get biometricLoginFailed => _t('فشل تسجيل الدخول بالبصمة', 'Biometric login failed');
  static String get staffConsoleSubtitle => _t('ادخل إلى كونسول الموظفين', 'Enter the staff console');
  static String get memberEntry => _t('دخول الأعضاء', 'Member entry');
  static String get roleAutoResolved => _t('يحدّد النظام دورك تلقائياً بعد تسجيل الدخول.', 'Your role is resolved automatically after login.');
  static String get backToHome => _t('الرئيسية', 'Home');

  // ─── UNIFIED LOGIN SCREEN (web) ──────────────────────────────
  static String get unifiedLoginSubtitle => _t('سجّل الدخول للمتابعة — للموظفين والإداريين والأعضاء', 'Sign in to continue — for staff, admins, and members');
  static String get loginIdentifier => _t('اسم المستخدم أو الهاتف أو البريد الإلكتروني', 'Username, phone, or email');
  static String get enterLoginIdentifier => _t('أدخل اسم المستخدم أو رقم الهاتف أو البريد الإلكتروني', 'Enter your username, phone, or email');
  static String get loginIdentifierRequired => _t('هذا الحقل مطلوب', 'This field is required');

  // ─── GYM SETUP WIZARD ──────────────────────────────────────
  static String get setupYourGym => _t('إعداد النادي الرياضي', 'Set up your gym');
  static String stepOf(int step) => _t(
        'الخطوة $step من ${_stepLabelsAr.length} — ${_stepLabelsAr[step - 1]}',
        'Step $step of ${_stepLabelsEn.length} — ${_stepLabelsEn[step - 1]}',
      );
  static const List<String> _stepLabelsAr = ['اسم النادي', 'الشعار', 'ألوان العلامة التجارية', 'اللغة المفضلة'];
  static const List<String> _stepLabelsEn = ['Gym name', 'Logo', 'Brand colors', 'Preferred language'];
  static String get gymName => _t('اسم النادي', 'Gym name');
  static String get logo => _t('الشعار', 'Logo');
  static String get brandColors => _t('ألوان العلامة التجارية', 'Brand colors');
  static String get finishSetup => _t('إنهاء الإعداد', 'Finish setup');
  static String get whatsYourGymCalled => _t('ما اسم ناديك الرياضي؟', 'What\'s your gym called?');
  static String get gymNameHint => _t('مثال: بودي آرت فيتنس', 'e.g. Body Art Fitness');
  static String get gymNameAppears => _t('سيظهر هذا الاسم في التطبيق لجميع الموظفين والعملاء.', 'This name will appear in the app for all staff and members.');
  static String get pleaseEnterGymName => _t('يرجى إدخال اسم النادي', 'Please enter your gym name');
  static String get nameTooShort => _t('يجب أن يكون الاسم حرفين على الأقل', 'The name must be at least 2 characters');
  static String get fileNotFound => _t('الملف المحدد غير موجود', 'The selected file was not found');
  static String get chooseFromGallery => _t('اختيار من المعرض', 'Choose from gallery');
  static String get takePhoto => _t('التقاط صورة', 'Take a photo');
  static String get removeLogo => _t('إزالة الشعار', 'Remove logo');
  static String get uploadGymLogo => _t('ارفع شعار النادي', 'Upload your gym logo');
  static String get logoShownOn => _t('سيظهر في شاشة تسجيل الدخول ورأس التطبيق.', 'It will appear on the login screen and in the app header.');
  static String get cannotDisplayImage => _t('لا يمكن عرض الصورة', 'The image can\'t be displayed');
  static String get changeLogo => _t('تغيير الشعار', 'Change logo');
  static String get chooseLogo => _t('اختيار شعار', 'Choose a logo');
  static String get skipLogoHint => _t('يمكنك تخطي هذا الآن وإضافة شعار لاحقاً من الإعدادات.', 'You can skip this for now and add a logo later from Settings.');
  static String get tapToUpload => _t('اضغط للرفع', 'Tap to upload');
  static String get chooseYourBrandColors => _t('اختر ألوان العلامة التجارية', 'Choose your brand colors');
  static String get colorsUsedThroughout => _t('ستُستخدم هذه الألوان في جميع أنحاء التطبيق لناديك.', 'These colors will be used throughout the app for your gym.');
  static String get primaryColor => _t('اللون الأساسي', 'Primary color');
  static String get usedForButtons => _t('يُستخدم للأزرار والعناصر المميزة', 'Used for buttons and highlighted elements');
  static String get secondaryColor => _t('اللون الثانوي', 'Secondary color');
  static String get usedForSecondary => _t('يُستخدم للعناصر الثانوية', 'Used for secondary elements');
  static String get preview => _t('معاينة', 'Preview');
  static String get yourGym => _t('ناديك', 'Your gym');
  static String get primary => _t('أساسي', 'Primary');
  static String get secondary => _t('ثانوي', 'Secondary');

  // ─── LANGUAGE SETUP STEP (shared: wizard, client, staff onboarding) ──
  static String get preferredLanguage => _t('اللغة المفضلة', 'Preferred language');
  static String get chooseYourLanguage => _t('اختر لغتك المفضلة', 'Choose your preferred language');
  static String get languageUsedThroughout => _t('ستُستخدم هذه اللغة في جميع أنحاء التطبيق. يمكنك تغييرها لاحقاً من الإعدادات.', 'This language will be used throughout the app. You can change it later from Settings.');
  static String get arabicLanguageName => _t('العربية', 'العربية');
  static String get englishLanguageName => _t('English', 'English');
  static String get languageSaveFailed => _t('تعذّر حفظ اللغة المفضلة. حاول مرة أخرى.', 'Couldn\'t save your language preference. Please try again.');

  // ─── OWNER DASHBOARD ───────────────────────────────────────
  static String get ownerDashboard => _t('لوحة تحكم المالك', 'Owner Dashboard');
  static String get loadingDashboard => _t('جاري تحميل لوحة التحكم...', 'Loading dashboard...');
  static String get overview => _t('نظرة عامة', 'Overview');
  static String get branches => _t('الفروع', 'Branches');
  static String get staff => _t('الموظفون', 'Staff');
  static String get finance => _t('المالية', 'Finance');
  static String get issues => _t('المشكلات', 'Issues');
  static String get keyMetrics => _t('المؤشرات الرئيسية', 'Key metrics');
  static String get recentAlerts => _t('التنبيهات الأخيرة', 'Recent alerts');
  static String get welcomeBack => _t('أهلاً بعودتك،', 'Welcome back,');
  static String get totalRevenue => _t('إجمالي الإيرادات', 'Total revenue');
  static String get activeSubs => _t('الاشتراكات النشطة', 'Active subscriptions');
  static String get totalCustomers => _t('إجمالي العملاء', 'Total members');
  static String get noBranchesFound => _t('لا توجد فروع', 'No branches found');
  static String get noBranchesYet => _t('لا توجد فروع بعد', 'No branches yet');
  static String get createFirstBranchDesc => _t('أنشئ أول فرع لبدء إدارة الجيم', 'Create your first branch to start managing your gym');
  static String get createBranch => _t('إنشاء فرع', 'Create branch');
  static String get branchNameLabel => _t('اسم الفرع', 'Branch name');
  static String get branchNameHint => _t('مثال: نادي التنين', 'e.g. Dragon Gym');
  static String get branchCodeLabel => _t('رمز الفرع', 'Branch code');
  static String get branchCodeHint => _t('مثال: DRG001', 'e.g. DRG001');
  static String get branchAddressLabel => _t('العنوان', 'Address');
  static String get branchAddressHint => _t('مثال: ١٢٣ شارع النيل', 'e.g. 123 Nile St.');
  static String get branchPhoneLabel => _t('هاتف الفرع', 'Branch phone');
  static String get branchPhoneHint => _t('مثال: 0201234567', 'e.g. 0201234567');
  static String get branchCityLabel => _t('المدينة', 'City');
  static String get branchCityHint => _t('مثال: القاهرة', 'e.g. Cairo');
  static String get branchCreated => _t('تم إنشاء الفرع بنجاح', 'Branch created successfully');
  static String get failedToCreateBranch => _t('فشل إنشاء الفرع', 'Failed to create branch');
  static String get noStaffYet => _t('لا يوجد موظفون بعد', 'No staff yet');
  static String get addStaffDesc => _t('أضف موظفين لفروعك لبدء العمل', 'Add staff to your branches to get started');
  static String get createBranchFirst => _t('أنشئ فرعاً أولاً قبل إضافة الموظفين', 'Create a branch first before adding staff');
  static String get customers => _t('العملاء', 'Members');
  static String get revenue => _t('الإيرادات', 'Revenue');
  static String get leaderboard => _t('لوحة المتصدرين', 'Leaderboard');
  static String get addStaff => _t('إضافة موظف', 'Add staff');
  static String transactionsCount(int count) => _t('$count عملية', '$count transactions');
  static String get totalExpenses => _t('إجمالي المصروفات', 'Total expenses');
  static String get netProfit => _t('صافي الربح', 'Net profit');
  static String get activeSubscriptions => _t('الاشتراكات النشطة', 'Active subscriptions');
  static String get noComplaints => _t('لا توجد شكاوى', 'No complaints');
  static String get allClear => _t('كل شيء على ما يرام!', 'Everything looks good!');
  static String get complaint => _t('شكوى', 'Complaint');
  static String get unknownBranch => _t('فرع غير معروف', 'Unknown branch');

  // ─── OWNER SETTINGS ────────────────────────────────────────
  static String get owner => _t('المالك', 'Owner');
  static String get ownerRole => _t('مالك', 'Owner');
  static String get appearance => _t('المظهر', 'Appearance');
  static String get theme => _t('السمة', 'Theme');
  static String get darkModeDefault => _t('الوضع الداكن (افتراضي)', 'Dark mode (default)');
  static String get appUsesDarkTheme => _t('التطبيق يستخدم السمة الداكنة افتراضياً', 'The app uses the dark theme by default');
  static String get language => _t('اللغة', 'Language');
  static String get arabicDefault => _t('العربية (افتراضي)', 'Arabic (default)');
  static String get languageComingSoon => _t('اختيار اللغة قريباً', 'Language selection coming soon');
  static String get account => _t('الحساب', 'Account');
  static String get changePassword => _t('تغيير كلمة المرور', 'Change password');
  static String get aboutApp => _t('حول التطبيق', 'About the app');
  static String get helpSupport => _t('المساعدة والدعم', 'Help & support');
  static String get helpSupportComingSoon => _t('المساعدة والدعم قريباً', 'Help & support coming soon');
  static String get currentPassword => _t('كلمة المرور الحالية', 'Current password');
  static String get newPassword => _t('كلمة المرور الجديدة', 'New password');
  static String get confirmNewPassword => _t('تأكيد كلمة المرور الجديدة', 'Confirm new password');
  static String get passwordChangeComingSoon => _t('تغيير كلمة المرور قريباً', 'Password change coming soon');
  static String get aboutGymManagement => _t('حول تطبيق إدارة النادي', 'About the gym management app');
  static String get version100 => _t('الإصدار: 1.0.0', 'Version: 1.0.0');
  static String get buildDate => _t('البناء: فبراير 2026', 'Build: February 2026');
  static String get aboutDescription => _t('نظام شامل لإدارة الأندية الرياضية للمالكين والمديرين والمحاسبين والموظفين.', 'A comprehensive gym management system for owners, managers, accountants, and staff.');
  static String get confirmLogout => _t('هل أنت متأكد من تسجيل الخروج؟', 'Are you sure you want to log out?');

  // ─── SMART ALERTS ──────────────────────────────────────────
  static String get smartAlerts => _t('التنبيهات الذكية', 'Smart alerts');
  static String get loadingAlerts => _t('جاري تحميل التنبيهات...', 'Loading alerts...');
  static String get noAlerts => _t('لا توجد تنبيهات', 'No alerts');
  static String get allSystemsNormal => _t('جميع الأنظمة تعمل بشكل طبيعي', 'All systems are running normally');
  static String get critical => _t('حرج', 'Critical');
  static String get warning => _t('تحذير', 'Warning');
  static String get info => _t('معلومات', 'Info');
  static String get criticalAlerts => _t('تنبيهات حرجة', 'Critical alerts');
  static String get warnings => _t('تحذيرات', 'Warnings');
  static String get information => _t('معلومات', 'Information');
  static String get alert => _t('تنبيه', 'Alert');
  static String get noDescription => _t('لا يوجد وصف', 'No description');
  static String get allBranches => _t('جميع الفروع', 'All branches');
  static String get dismiss => _t('تجاهل', 'Dismiss');
  static String get alertDetails => _t('تفاصيل التنبيه', 'Alert details');
  static String alertType(String type) => _t('النوع: $type', 'Type: $type');
  static String alertMessage(String msg) => _t('الرسالة: $msg', 'Message: $msg');
  static String alertBranch(String branch) => _t('الفرع: $branch', 'Branch: $branch');
  static String alertTime(String time) => _t('الوقت: $time', 'Time: $time');
  static String alertDetailsFull(String details) => _t('التفاصيل: $details', 'Details: $details');
  static String get alertDismissed => _t('تم تجاهل التنبيه', 'Alert dismissed');

  // ─── STAFF LEADERBOARD ─────────────────────────────────────
  static String get staffLeaderboard => _t('لوحة متصدري الموظفين', 'Staff leaderboard');
  static String get loadingStaffPerformance => _t('جاري تحميل أداء الموظفين...', 'Loading staff performance...');
  static String get noPerformanceData => _t('لا توجد بيانات أداء للموظفين', 'No staff performance data');
  static String get topPerformers => _t('الأفضل أداءً', 'Top performers');
  static String get allStaffMembers => _t('جميع الموظفين', 'All staff');
  static String get transactions => _t('العمليات', 'Transactions');
  static String get retention => _t('الاحتفاظ', 'Retention');
  static String get filterOptions => _t('خيارات التصفية', 'Filter options');
  static String get sortByRevenue => _t('ترتيب حسب الإيرادات', 'Sort by revenue');
  static String get sortByCustomers => _t('ترتيب حسب العملاء', 'Sort by members');
  static String get sortByRetention => _t('ترتيب حسب معدل الاحتفاظ', 'Sort by retention rate');

  // ─── BRANCH DETAIL ─────────────────────────────────────────
  static String get operations => _t('العمليات', 'Operations');
  static String get loadingBranchDetails => _t('جاري تحميل تفاصيل الفرع...', 'Loading branch details...');
  static String get failedToLoadBranch => _t('فشل تحميل بيانات الفرع', 'Failed to load branch data');
  static String get capacity => _t('السعة', 'Capacity');
  static String get branchInformation => _t('معلومات الفرع', 'Branch information');
  static String get branchId => _t('رقم الفرع', 'Branch ID');
  static String get branchName => _t('اسم الفرع', 'Branch name');
  static String get status => _t('الحالة', 'Status');
  static String get address => _t('العنوان', 'Address');
  static String get revenueByService => _t('الإيرادات حسب الخدمة', 'Revenue by service');
  static String get noRevenueData => _t('لا توجد بيانات إيرادات', 'No revenue data');
  static String customersCount(int count) => _t('$count عميل', '$count members');
  static String get branchStaff => _t('موظفو الفرع', 'Branch staff');
  static String get noStaffData => _t('لا توجد بيانات موظفين', 'No staff data');
  static String txCount(int count) => _t('$count عملية', '$count transactions');
  static String get dailyOperations => _t('العمليات اليومية', 'Daily operations');
  static String get checkInsThisMonth => _t('تسجيلات الدخول هذا الشهر', 'Check-ins this month');
  static String get openComplaints => _t('الشكاوى المفتوحة', 'Open complaints');
  static String get expiredThisMonth => _t('المنتهية هذا الشهر', 'Expired this month');
  static String get frozenSubscriptions => _t('الاشتراكات المجمدة', 'Frozen subscriptions');
  static String get newCustomers => _t('عملاء جدد', 'New members');

  // ─── OPERATIONAL MONITOR ───────────────────────────────────
  static String get operationalMonitor => _t('مراقبة العمليات', 'Operational monitor');
  static String get loadingOperationalData => _t('جاري تحميل بيانات العمليات...', 'Loading operational data...');
  static String get failedToLoadOperational => _t('فشل تحميل بيانات العمليات', 'Failed to load operational data');
  static String get liveMonitoring => _t('مراقبة مباشرة', 'Live monitoring');
  static String get gymFloor => _t('صالة التمارين', 'Gym floor');
  static String get swimmingPool => _t('حوض السباحة', 'Swimming pool');
  static String get karateArea => _t('منطقة الكاراتيه', 'Karate area');
  static String spotsLeft(int count) => _t('$count مكان متاح', '$count spots left');
  static String get todaysClasses => _t('حصص اليوم', 'Today\'s classes');
  static String get staffAttendance => _t('حضور الموظفين', 'Staff attendance');
  static String get yogaClass => _t('حصة يوغا', 'Yoga class');
  static String get karateBasics => _t('أساسيات الكاراتيه', 'Karate basics');
  static String get swimmingLessons => _t('دروس السباحة', 'Swimming lessons');
  static String get advancedKarate => _t('كاراتيه متقدم', 'Advanced karate');
  static String get live => _t('مباشر', 'Live');
  static String get present => _t('حاضر', 'Present');
  static String get absent => _t('غائب', 'Absent');

  // ─── ADD STAFF DIALOG ──────────────────────────────────────
  static String get addNewStaff => _t('إضافة موظف جديد', 'Add new staff member');
  static String get fullName => _t('الاسم الكامل', 'Full name');
  static String get fullNameRequired => _t('الاسم الكامل *', 'Full name *');
  static String get fullNameHint => _t('مثال: أحمد حسن', 'e.g. Ahmed Hassan');
  static String get usernameRequired2 => _t('اسم المستخدم *', 'Username *');
  static String get usernameHint => _t('مثال: ahmed_front', 'e.g. ahmed_front');
  static String get atLeast3Chars => _t('3 أحرف على الأقل', 'At least 3 characters');
  static String get emailRequired => _t('البريد الإلكتروني *', 'Email *');
  static String get email => _t('البريد الإلكتروني', 'Email');
  static String get autoGeneratedFromUsername => _t('يُولّد تلقائياً من اسم المستخدم', 'Auto-generated from the username');
  static String get resetToAutoGenerated => _t('إعادة التعيين للتوليد التلقائي', 'Reset to auto-generated');
  static String get invalidEmail => _t('بريد إلكتروني غير صالح', 'Invalid email address');
  static String get passwordRequired2 => _t('كلمة المرور *', 'Password *');
  static String get min6Chars => _t('6 أحرف على الأقل', 'At least 6 characters');
  static String get atLeast6Chars => _t('6 أحرف على الأقل', 'At least 6 characters');
  static String get phoneOptional => _t('الهاتف (اختياري)', 'Phone (optional)');
  static String get roleRequired => _t('الدور *', 'Role *');
  static String get branchManager => _t('مدير فرع', 'Branch manager');
  static String get frontDesk => _t('الاستقبال', 'Front desk');
  static String get branchAccountant => _t('محاسب فرع', 'Branch accountant');
  static String get centralAccountant => _t('محاسب مركزي', 'Central accountant');
  static String get branchRequired => _t('الفرع *', 'Branch *');
  static String get noBranchesCreateFirst => _t('لا توجد فروع. أنشئ فرعاً أولاً.', 'No branches. Create one first.');
  static String get selectBranch => _t('اختر فرعاً', 'Select a branch');
  static String get creating => _t('جاري الإنشاء...', 'Creating...');
  static String get createStaffMember => _t('إنشاء موظف', 'Create staff member');
  static String staffAddedSuccess(String name) => _t('تمت إضافة $name بنجاح!', '$name was added successfully!');

  // ─── RECEPTION NAVIGATION ──────────────────────────────────
  static String get home => _t('الرئيسية', 'Home');
  static String get subs => _t('الاشتراكات', 'Subscriptions');
  static String get ops => _t('العمليات', 'Operations');
  static String get clients => _t('العملاء', 'Members');
  static String get profile => _t('الملف الشخصي', 'Profile');

  // ─── RECEPTION HOME ────────────────────────────────────────
  static String get dashboard => _t('لوحة التحكم', 'Dashboard');
  static String get dashboardStats => _t('إحصائيات لوحة التحكم', 'Dashboard stats');
  static String get newToday => _t('جديد اليوم', 'New today');
  static String get complaints => _t('الشكاوى', 'Complaints');
  static String get quickActions => _t('إجراءات سريعة', 'Quick actions');
  static String get registerCustomer => _t('تسجيل عميل', 'Register member');
  static String get activateSub => _t('تفعيل اشتراك', 'Activate subscription');
  static String get scanCustomerQR => _t('مسح رمز QR للعميل', 'Scan member\'s QR code');
  static String get recentCustomers => _t('العملاء الأخيرون', 'Recent members');
  static String get noRecentCustomers => _t('لا يوجد عملاء حديثون', 'No recent members');

  // ─── CUSTOMERS LIST ────────────────────────────────────────
  static String get allCustomers => _t('جميع العملاء', 'All members');
  static String get searchCustomers => _t('البحث عن عملاء', 'Search members');
  static String get namePhoneEmail => _t('الاسم أو الهاتف أو البريد', 'Name, phone, or email');
  static String customersCountLabel(int count) => _t('$count عميل', '$count members');
  static String get noCustomersFound => _t('لا يوجد عملاء', 'No members found');
  static String get noCustomersMatch => _t('لا يوجد عملاء مطابقون للبحث', 'No members match your search');
  static String copiedToClipboard(String label) => _t('تم نسخ $label إلى الحافظة', '$label copied to clipboard');
  static String get noSubscription => _t('لا يوجد اشتراك', 'No subscription');
  static String get phone => _t('الهاتف', 'Phone');
  static String get qrCode => _t('رمز QR', 'QR code');
  static String get clientAppCredentials => _t('بيانات تطبيق العميل', 'Member app credentials');
  static String get notAvailable => _t('غير متوفر', 'Not available');
  static String get passwordNotReturned => _t('⚠️ كلمة المرور غير متاحة من الخادم — تحتاج إصلاح', '⚠️ Password not returned by the server — needs a fix');
  static String get permanentLoginPassword => _t('هذه كلمة المرور الدائمة للعميل', 'This is the member\'s permanent password');
  static String copyLabel(String label) => _t('نسخ $label', 'Copy $label');

  // ─── CUSTOMER DETAIL ───────────────────────────────────────
  static String get customerProfile => _t('ملف العميل', 'Member profile');
  static String customerId(int id) => _t('المعرف: $id', 'ID: $id');
  static String get scanQRToCheckIn => _t('امسح رمز QR هذا لتسجيل الدخول', 'Scan this QR code to check in');
  static String get viewFullQR => _t('عرض رمز QR الكامل', 'View full QR code');
  static String get regenerating => _t('جاري إعادة التوليد...', 'Regenerating...');
  static String get regenerate => _t('إعادة توليد', 'Regenerate');
  static String get qrRegenerated => _t('تم إعادة توليد رمز QR بنجاح', 'QR code regenerated successfully');
  static String get failedToRegenerateQR => _t('فشل في إعادة توليد رمز QR', 'Failed to regenerate QR code');
  static String get temporaryPassword => _t('كلمة المرور المؤقتة', 'Temporary password');
  static String get passwordChanged => _t('تم تغيير كلمة المرور', 'Password changed');
  static String get firstTimeLoginPassword => _t('كلمة مرور تسجيل الدخول الأول', 'First-login password');
  static String get sharePasswordWithCustomer => _t('شارك هذه كلمة المرور مع العميل لتسجيل دخوله الأول', 'Share this password with the member for their first login');
  static String get contactInformation => _t('معلومات الاتصال', 'Contact information');
  static String get gender => _t('الجنس', 'Gender');
  static String get age => _t('العمر', 'Age');
  static String ageYears(String a) => _t('$a سنة', '$a years');
  static String get healthMetrics => _t('المؤشرات الصحية', 'Health metrics');
  static String get weight => _t('الوزن', 'Weight');
  static String weightKg(String w) => _t('$w كجم', '$w kg');
  static String get height => _t('الطول', 'Height');
  static String heightCm(String h) => _t('$h سم', '$h cm');
  static String get bmi => _t('مؤشر كتلة الجسم', 'BMI');
  static String get bmr => _t('معدل الأيض الأساسي', 'BMR');
  static String calValue(String c) => _t('$c سعرة', '$c cal');
  static String get dailyCalories => _t('السعرات اليومية', 'Daily calories');
  static String get recommendedIntake => _t('الكمية الموصى بها', 'Recommended intake');

  // ─── OPERATIONS SCREEN ─────────────────────────────────────
  static String get dailyClosing => _t('الإغلاق اليومي', 'Daily closing');
  static String get finalizeTodayTransactions => _t('إنهاء عمليات اليوم', 'Finalize today\'s transactions');
  static String get recordPayment => _t('تسجيل دفعة', 'Record payment');
  static String get submitComplaint => _t('تقديم شكوى', 'Submit complaint');
  static String get dailyClosingConfirm => _t('هل أنت متأكد من إجراء الإغلاق اليومي؟ سيتم إنهاء جميع عمليات اليوم.', 'Are you sure you want to run the daily closing? This will finalize all of today\'s transactions.');
  static String get dailyClosingCompleted => _t('تم الإغلاق اليومي بنجاح', 'Daily closing completed successfully');
  static String get dailyClosingFailed => _t('فشل الإغلاق اليومي', 'Daily closing failed');

  // ─── SUBSCRIPTION OPS ──────────────────────────────────────
  static String get subscriptionOperations => _t('عمليات الاشتراك', 'Subscription operations');
  static String get activateSubscription => _t('تفعيل اشتراك', 'Activate subscription');
  static String get renewSubscription => _t('تجديد اشتراك', 'Renew subscription');
  static String get freezeSubscription => _t('تجميد اشتراك', 'Freeze subscription');
  static String get stopSubscription => _t('إيقاف اشتراك', 'Stop subscription');

  // ─── QR SCANNER ────────────────────────────────────────────
  static String get scanQRCode => _t('مسح رمز QR', 'Scan QR code');
  static String get loadingCustomer => _t('جاري تحميل بيانات العميل...', 'Loading member data...');
  static String get invalidQRFormat => _t('تنسيق رمز QR غير صالح', 'Invalid QR code format');
  static String get customerDataMissingId => _t('بيانات العميل تفتقد المعرف', 'Member data is missing an ID');
  static String get invalidResponseFormat => _t('تنسيق الاستجابة غير صالح', 'Invalid response format');
  static String customerNotFound(int id) => _t('العميل غير موجود (المعرف: $id)', 'Member not found (ID: $id)');
  static String checkInTitle(String name) => _t('تسجيل دخول: $name', 'Check-in: $name');
  static String customerIdLabel(int id) => _t('معرف العميل: $id', 'Member ID: $id');
  static String get activeSubscription => _t('اشتراك نشط', 'Active subscription');
  static String subscriptionType(String type) => _t('النوع: $type', 'Type: $type');
  static String remaining(dynamic count) => _t('المتبقي: $count', 'Remaining: $count');
  static String expires(String date) => _t('ينتهي: $date', 'Expires: $date');
  static String get selectAction => _t('اختر الإجراء:', 'Select an action:');
  static String get noActiveSubFound => _t('لم يتم العثور على اشتراك نشط.', 'No active subscription found.');
  static String get deduct1Session => _t('خصم جلسة واحدة', 'Deduct 1 session');
  static String get checkInOnly => _t('تسجيل دخول فقط', 'Check-in only');
  static String customerScanned(String name, int id) => _t('العميل: $name (المعرف: $id)', 'Member: $name (ID: $id)');
  static String sessionDeducted(dynamic remaining) => _t('تم خصم الجلسة بنجاح!\nالمتبقي: $remaining', 'Session deducted successfully!\nRemaining: $remaining');
  static String get failedToDeductSession => _t('فشل خصم الجلسة', 'Failed to deduct session');
  static String checkedInSuccess(String name) => _t('تم تسجيل دخول $name بنجاح!', '$name checked in successfully!');
  static String get failedToCheckIn => _t('فشل تسجيل الدخول', 'Check-in failed');
  static String get positionQRInFrame => _t('ضع رمز QR داخل الإطار', 'Position the QR code inside the frame');
  static String get codeScannedAutomatically => _t('سيتم مسح الرمز تلقائياً', 'The code will scan automatically');

  // ─── PROFILE SETTINGS ──────────────────────────────────────
  static String get profileSettings => _t('الملف الشخصي والإعدادات', 'Profile & settings');
  static String get user => _t('المستخدم', 'User');
  static String get reception => _t('الاستقبال', 'Front desk');
  static String branchIdLabel(String id) => _t('رقم الفرع: $id', 'Branch ID: $id');

  // ─── HEALTH REPORT ─────────────────────────────────────────
  static String get healthReport => _t('التقرير الصحي', 'Health report');
  static String yearsOld(String age) => _t('$age سنة', '$age years old');
  static String get customerQRCode => _t('رمز QR العميل', 'Member QR code');
  static String get qrCopied => _t('تم نسخ رمز QR إلى الحافظة', 'QR code copied to clipboard');
  static String get copyQRCode => _t('نسخ رمز QR', 'Copy QR code');
  static String get scanQRForIdentification => _t('امسح رمز QR هذا لتعريف العميل والوصول السريع', 'Scan this QR code to identify the member for quick access');
  static String get physicalMeasurements => _t('القياسات الجسدية', 'Physical measurements');
  static String get bodyMassIndex => _t('مؤشر كتلة الجسم (BMI)', 'Body Mass Index (BMI)');
  static String get bmiScore => _t('نتيجة BMI', 'BMI score');
  static String get metabolicInfo => _t('معلومات الأيض', 'Metabolic info');
  static String get basalMetabolicRate => _t('معدل الأيض الأساسي (BMR)', 'Basal Metabolic Rate (BMR)');
  static String get caloriesBurnedAtRest => _t('السعرات المحروقة في الراحة', 'Calories burned at rest');
  static String get dailyCalorieNeeds => _t('احتياجات السعرات اليومية', 'Daily calorie needs');
  static String get forModerateActivity => _t('للنشاط المعتدل', 'For moderate activity');
  static String get recommendations => _t('التوصيات', 'Recommendations');
  static String get healthTips => _t('نصائح صحية', 'Health tips');
  static String generatedOn(String date) => _t('تم التوليد في $date', 'Generated on $date');
  static String get underweight => _t('نقص الوزن', 'Underweight');
  static String get normal => _t('طبيعي', 'Normal');
  static String get overweight => _t('زيادة الوزن', 'Overweight');
  static String get obese => _t('سمنة', 'Obese');
  // Health tips
  static String get tipIncreaseCaloric => _t('زيادة السعرات الحرارية بأطعمة غنية بالعناصر الغذائية', 'Increase caloric intake with nutrient-rich foods');
  static String get tipStrengthTraining => _t('التركيز على تمارين القوة', 'Focus on strength training');
  static String get tipConsultNutritionist => _t('استشارة أخصائي تغذية لخطة وجبات', 'Consult a nutritionist for a meal plan');
  static String get tipMaintainHealthy => _t('الحفاظ على العادات الصحية الحالية', 'Maintain your current healthy habits');
  static String get tipContinueExercise => _t('الاستمرار في برنامج التمارين المنتظم', 'Continue your regular exercise routine');
  static String get tipBalancedDiet => _t('تناول نظام غذائي متوازن ومتنوع', 'Eat a balanced, varied diet');
  static String get tipCalorieDeficit => _t('إنشاء عجز معتدل في السعرات الحرارية', 'Create a moderate calorie deficit');
  static String get tipIncreaseCardio => _t('زيادة تمارين القلب والأوعية الدموية', 'Increase cardiovascular exercise');
  static String get tipPortionControl => _t('التركيز على التحكم في الحصص', 'Focus on portion control');
  static String get tipConsultHealthcare => _t('استشارة مقدم الرعاية الصحية', 'Consult a healthcare provider');
  static String get tipLowImpact => _t('البدء بتمارين منخفضة التأثير', 'Start with low-impact exercises');
  static String get tipWorkWithDietitian => _t('العمل مع أخصائي تغذية', 'Work with a dietitian');
  static String get tipMaintainBalanced => _t('الحفاظ على نظام غذائي متوازن', 'Maintain a balanced diet');
  static String get tipExerciseRegularly => _t('ممارسة الرياضة بانتظام', 'Exercise regularly');
  static String get tipStayHydrated => _t('شرب كمية كافية من الماء', 'Stay well hydrated');
  static String get shareWhatsAppSoon => _t('مشاركة عبر واتساب قريباً...', 'Share via WhatsApp coming soon...');
  static String get printSoon => _t('الطباعة قريباً...', 'Printing coming soon...');

  // ─── ACTIVATE SUBSCRIPTION DIALOG ──────────────────────────
  static String get coinsPackage => _t('باقة العملات', 'Coins package');
  static String get oneYearValidity => _t('صلاحية سنة واحدة', 'Valid for one year');
  static String get timeBasedPackage => _t('باقة زمنية', 'Time-based package');
  static String get monthOptions => _t('1، 3، 6، 9، أو 12 شهر', '1, 3, 6, 9, or 12 months');
  static String get personalTraining => _t('تدريب شخصي', 'Personal training');
  static String get sessionsWithTrainer => _t('جلسات مع المدرب', 'Sessions with a trainer');
  static String get month1 => _t('شهر واحد', '1 month');
  static String get months3 => _t('3 أشهر', '3 months');
  static String get months6 => _t('6 أشهر', '6 months');
  static String get months9 => _t('9 أشهر', '9 months');
  static String get months12 => _t('12 شهر', '12 months');
  static String coins(int n) => _t('$n عملة', '$n coins');
  static String sessions(int n) => _t('$n جلسة', '$n sessions');
  static String get pleaseSelectSubType => _t('يرجى اختيار نوع الاشتراك', 'Please select a subscription type');
  static String get pleaseSelectCoins => _t('يرجى اختيار عدد العملات', 'Please select the number of coins');
  static String get pleaseSelectDuration => _t('يرجى اختيار المدة', 'Please select a duration');
  static String get pleaseSelectSessions => _t('يرجى اختيار عدد الجلسات', 'Please select the number of sessions');
  static String get subscriptionActivated => _t('تم تفعيل الاشتراك', 'Subscription activated');
  static String get customerIdRequired => _t('معرف العميل *', 'Member ID *');
  static String get subscriptionTypeRequired => _t('نوع الاشتراك *', 'Subscription type *');
  static String get chooseSubType => _t('اختر نوع الاشتراك', 'Choose a subscription type');
  static String get coinsAmountRequired => _t('عدد العملات *', 'Number of coins *');
  static String get validFor1Year => _t('صالح لمدة سنة واحدة', 'Valid for one year');
  static String get durationRequired => _t('المدة *', 'Duration *');
  static String get selectSubDuration => _t('اختر مدة الاشتراك', 'Select subscription duration');
  static String get sessionsRequired => _t('عدد الجلسات *', 'Number of sessions *');
  static String get sessionsWithPersonalTrainer => _t('جلسات مع مدرب شخصي', 'Sessions with a personal trainer');
  static String get amountRequired => _t('المبلغ *', 'Amount *');
  static String get paymentMethodRequired => _t('طريقة الدفع *', 'Payment method *');
  static String get cash => _t('نقداً', 'Cash');
  static String get card => _t('بطاقة', 'Card');
  static String get transfer => _t('تحويل', 'Transfer');
  // CORS error (keep English technical terms)
  static String get corsErrorDetected => _t('خطأ CORS', 'CORS error');
  static String get corsDescription => _t('أنت تستخدم متصفح الويب الذي يحظر الطلبات عبر المصادر (CORS).', 'Your web browser is blocking cross-origin requests (CORS).');
  static String get immediateSolution => _t('✅ الحل الفوري:', '✅ Immediate solution:');
  static String get closeThisApp => _t('1. أغلق هذا التطبيق', '1. Close this app');
  static String get runDebugBat => _t('2. انقر مرتين على: DEBUG_SUBSCRIPTION_ACTIVATION.bat', '2. Double-click: DEBUG_SUBSCRIPTION_ACTIVATION.bat');
  static String get selectOption1 => _t('3. اختر الخيار 1 (جهاز أندرويد)', '3. Choose option 1 (Android device)');
  static String get orOption2 => _t('   أو الخيار 2 (محاكي أندرويد)', '   or option 2 (Android emulator)');
  static String get whyAndroid => _t('📱 لماذا أندرويد؟', '📱 Why Android?');
  static String get noCorsRestrictions => _t('• لا قيود CORS', '• No CORS restrictions');
  static String get directBackendConnection => _t('• اتصال مباشر بالخادم', '• Direct connection to the server');
  static String get allFeaturesWork => _t('• جميع الميزات تعمل فوراً', '• All features work right away');
  static String get technicalDetails => _t('💡 التفاصيل التقنية:', '💡 Technical details:');
  static String get corsExplanation => _t('المتصفحات تحظر الطلبات من localhost إلى pythonanywhere.com لأسباب أمنية. تطبيقات أندرويد الأصلية ليس لديها هذا القيد.', 'Browsers block requests from localhost to pythonanywhere.com for security reasons. Native Android apps don\'t have this restriction.');
  static String get runOnAndroid => _t('تشغيل على أندرويد', 'Run on Android');
  static String get activationFailed => _t('فشل التفعيل', 'Activation failed');
  static String get details => _t('التفاصيل:', 'Details:');
  static String get loginAgain => _t('تسجيل الدخول مرة أخرى', 'Log in again');

  // ─── REGISTER CUSTOMER DIALOG ──────────────────────────────
  static String get customerRegistered => _t('تم تسجيل العميل بنجاح', 'Member registered successfully');
  static String customerIdCreated(int id) => _t('معرف العميل: $id', 'Member ID: $id');
  static String get registrationFailed => _t('فشل التسجيل', 'Registration failed');
  static String get failedToRegister => _t('فشل تسجيل العميل', 'Failed to register member');
  static String get unexpectedError => _t('حدث خطأ غير متوقع', 'An unexpected error occurred');
  static String get registerNewCustomer => _t('تسجيل عميل جديد', 'Register new member');
  static String get male => _t('ذكر', 'Male');
  static String get female => _t('أنثى', 'Female');
  static String get genderRequired => _t('الجنس *', 'Gender *');
  static String get ageRequired => _t('العمر *', 'Age *');
  static String get weightRequired => _t('الوزن (كجم) *', 'Weight (kg) *');
  static String get heightRequired => _t('الطول (سم) *', 'Height (cm) *');
  static String get qrAndHealthAutoGenerated => _t('سيتم توليد رمز QR والمؤشرات الصحية تلقائياً', 'The QR code and health metrics will be generated automatically');

  // ─── RECORD PAYMENT DIALOG ─────────────────────────────────
  static String get paymentRecorded => _t('تم تسجيل الدفعة', 'Payment recorded');
  static String get failedToRecordPayment => _t('فشل تسجيل الدفعة', 'Failed to record payment');
  static String get notes => _t('ملاحظات', 'Notes');
  static String get record => _t('تسجيل', 'Record');

  // ─── RENEW SUBSCRIPTION DIALOG ─────────────────────────────
  static String get subscriptionRenewed => _t('تم تجديد الاشتراك بنجاح', 'Subscription renewed successfully');
  static String get failedToRenew => _t('فشل تجديد الاشتراك', 'Failed to renew subscription');
  static String get subscriptionIdRequired => _t('رقم الاشتراك *', 'Subscription ID *');
  static String get invalidAmount => _t('مبلغ غير صالح', 'Invalid amount');
  static String get renew => _t('تجديد', 'Renew');

  // ─── FREEZE SUBSCRIPTION DIALOG ────────────────────────────
  static String get subscriptionFrozen => _t('تم تجميد الاشتراك بنجاح', 'Subscription frozen successfully');
  static String get failedToFreeze => _t('فشل تجميد الاشتراك', 'Failed to freeze subscription');
  static String get freezeDescription => _t('إيقاف الاشتراك مؤقتاً بدون خسارة الأيام المتبقية', 'Temporarily pause the subscription without losing remaining days');
  static String get freezeDaysRequired => _t('أيام التجميد *', 'Freeze days *');
  static String get numberOfDaysToFreeze => _t('عدد أيام التجميد', 'Number of days to freeze');
  static String get atLeast1Day => _t('يجب أن يكون يوم واحد على الأقل', 'Must be at least 1 day');
  static String get freeze => _t('تجميد', 'Freeze');

  // ─── STOP SUBSCRIPTION DIALOG ──────────────────────────────
  static String get confirmStop => _t('تأكيد الإيقاف', 'Confirm stop');
  static String get stopConfirmMessage => _t('هل أنت متأكد من إيقاف هذا الاشتراك؟ لا يمكن التراجع عن هذا الإجراء وسيتم إلغاء الوصول فوراً.', 'Are you sure you want to stop this subscription? This action can\'t be undone and access will be revoked immediately.');
  static String get stop => _t('إيقاف', 'Stop');
  static String get subscriptionStopped => _t('تم إيقاف الاشتراك بنجاح', 'Subscription stopped successfully');
  static String get failedToStop => _t('فشل إيقاف الاشتراك', 'Failed to stop subscription');
  static String get willDeactivateAccess => _t('سيتم إلغاء وصول العميل فوراً', 'The member\'s access will be revoked immediately');

  // ─── SUBMIT COMPLAINT DIALOG ───────────────────────────────
  static String get complaintSubmitted => _t('تم تقديم الشكوى', 'Complaint submitted');
  static String get failedToSubmitComplaint => _t('فشل تقديم الشكوى', 'Failed to submit complaint');
  static String get customerIdOptional => _t('معرف العميل (اختياري)', 'Member ID (optional)');
  static String get titleRequired => _t('العنوان *', 'Title *');
  static String get descriptionRequired => _t('الوصف *', 'Description *');

  // ─── CUSTOMER QR CODE WIDGET ───────────────────────────────
  static String get customerQRCodeTitle => _t('رمز QR العميل', 'Member QR code');
  static String customerIdBadge(int id) => _t('معرف العميل: $id', 'Member ID: $id');
  static String get scanQRAtEntrance => _t('امسح رمز QR هذا عند المدخل لتسجيل الدخول', 'Scan this QR code at the entrance to check in');

  // ─── BRANCH MANAGER DASHBOARD ──────────────────────────────
  static String get branchManagerTitle => _t('مدير الفرع', 'Branch Manager');
  static String get performanceOverview => _t('نظرة عامة على الأداء', 'Performance overview');
  static String get todaysRevenue => _t('إيرادات اليوم', 'Today\'s revenue');
  static String get activeMembers => _t('الأعضاء النشطون', 'Active members');
  static String expiringSoon(int count) => _t('ينتهي قريباً ($count)', 'Expiring soon ($count)');
  static String get pendingIssues => _t('مشكلات معلقة', 'Pending issues');
  static String get noStaffFound => _t('لا يوجد موظفون', 'No staff found');

  // ─── BRANCH MANAGER SETTINGS ───────────────────────────────
  static String get manager => _t('المدير', 'Manager');
  static String get branchManagerRole => _t('مدير فرع', 'Branch manager');

  // ─── ACCOUNTANT DASHBOARD ──────────────────────────────────
  static String get accountantDashboard => _t('لوحة تحكم المحاسب', 'Accountant Dashboard');
  static String get loadingFinancialData => _t('جاري تحميل البيانات المالية...', 'Loading financial data...');
  static String get sales => _t('المبيعات', 'Sales');
  static String get expenses => _t('المصروفات', 'Expenses');
  static String get reports => _t('التقارير', 'Reports');
  static String get todaysSummary => _t('ملخص اليوم', 'Today\'s summary');
  static String get todaysSales => _t('مبيعات اليوم', 'Today\'s sales');
  static String get paymentBreakdown => _t('تفاصيل المدفوعات', 'Payment breakdown');
  static String get networkCard => _t('بطاقة/شبكة', 'Card/network');
  static String get thisMonth => _t('هذا الشهر', 'This month');
  static String itemsCount(int n) => _t('$n عنصر', '$n items');
  static String get alerts => _t('التنبيهات', 'Alerts');
  static String get monthOverMonth => _t('مقارنة شهرية', 'Month over month');
  static String get salesAndTransactions => _t('المبيعات والعمليات', 'Sales & transactions');
  static String transactionsToday(int n) => _t('$n عملية اليوم', '$n transactions today');
  static String get fullLedger => _t('السجل الكامل', 'Full ledger');
  static String get total => _t('الإجمالي', 'Total');
  static String get noTransactionsToday => _t('لا توجد عمليات اليوم', 'No transactions today');
  static String get viewTransactionHistory => _t('عرض سجل العمليات', 'View transaction history');
  static String get noExpensesFound => _t('لا توجد مصروفات', 'No expenses found');
  static String get noBranchData => _t('لا توجد بيانات فروع', 'No branch data');
  static String get subscriptions => _t('الاشتراكات', 'Subscriptions');
  static String get financialReports => _t('التقارير المالية', 'Financial reports');
  static String get revenueBreakdown => _t('تفاصيل الإيرادات', 'Revenue breakdown');
  static String get weeklyReport => _t('التقرير الأسبوعي', 'Weekly report');
  static String get monthlyReport => _t('التقرير الشهري', 'Monthly report');
  static String get cashDifferences => _t('فروقات النقد', 'Cash differences');
  static String get noReportData => _t('لا توجد بيانات تقارير', 'No report data');
  static String get tryAdjustingDateRange => _t('حاول تعديل نطاق التاريخ', 'Try adjusting the date range');
  static String get byBranch => _t('حسب الفرع', 'By branch');
  static String get byService => _t('حسب الخدمة', 'By service');
  static String get byPaymentMethod => _t('حسب طريقة الدفع', 'By payment method');
  static String get weeklyRevenue => _t('الإيرادات الأسبوعية', 'Weekly revenue');
  static String get weeklyExpenses => _t('المصروفات الأسبوعية', 'Weekly expenses');
  static String get dailyBreakdown => _t('التفاصيل اليومية', 'Daily breakdown');
  static String get monthlyRevenue => _t('الإيرادات الشهرية', 'Monthly revenue');
  static String get monthlyExpenses => _t('المصروفات الشهرية', 'Monthly expenses');
  static String get dailyAverageRevenue => _t('متوسط الإيرادات اليومية', 'Average daily revenue');
  static String get totalCashDifference => _t('إجمالي فروقات النقد', 'Total cash difference');

  // ─── ACCOUNTANT SETTINGS ───────────────────────────────────
  static String get accountant => _t('المحاسب', 'Accountant');
  static String get accountantRole => _t('محاسب', 'Accountant');
  static String get aboutDescriptionReception => _t('نظام شامل لإدارة الأندية الرياضية لموظفي الاستقبال ومديري الفروع والمالكين.', 'A comprehensive gym management system for front desk staff, branch managers, and owners.');

  // ─── TRANSACTION LEDGER ────────────────────────────────────
  static String get transactionLedger => _t('سجل العمليات', 'Transaction ledger');
  static String get changeDate => _t('تغيير التاريخ', 'Change date');
  static String transactionsCountLabel(int n) => _t('$n عملية', '$n transactions');
  static String get searchByCustomer => _t('البحث بالاسم أو المعرف...', 'Search by name or ID...');
  static String paymentFilter(String method) => _t('الدفع: $method', 'Payment: $method');
  static String get loadingTransactions => _t('جاري تحميل العمليات...', 'Loading transactions...');
  static String get noTransactionsForDate => _t('لا توجد عمليات لهذا التاريخ', 'No transactions for this date');
  static String get pickAnotherDate => _t('اختر تاريخاً آخر', 'Pick another date');
  static String get walkIn => _t('زائر', 'Walk-in');
  static String transactionNumber(int id) => _t('عملية #$id', 'Transaction #$id');
  static String get grossAmount => _t('المبلغ الإجمالي', 'Gross amount');
  static String get discount => _t('الخصم', 'Discount');
  static String get netAmount => _t('المبلغ الصافي', 'Net amount');
  static String get payment => _t('الدفع', 'Payment');
  static String get time => _t('الوقت', 'Time');
  static String get filterTransactions => _t('تصفية العمليات', 'Filter transactions');
  static String get paymentMethod => _t('طريقة الدفع', 'Payment method');
  static String get allMethods => _t('جميع الطرق', 'All methods');

  // ─── MANAGER SETTINGS ──────────────────────────────────────
  static String get managerRole => _t('مدير', 'Manager');

  // ─── CLIENT/WELCOME SCREEN ─────────────────────────────────
  static String get pleaseEnterCredentials => _t('يرجى إدخال الهاتف/البريد وكلمة المرور', 'Please enter your phone/email and password');
  static String get loginSuccessful => _t('تم تسجيل الدخول بنجاح!', 'Logged in successfully!');
  static String get gymMemberPortal => _t('بوابة أعضاء النادي', 'Gym Member Portal');
  static String get loginToAccess => _t('سجل الدخول للوصول إلى عضويتك', 'Log in to access your membership');
  static String get phoneOrEmail => _t('رقم الهاتف أو البريد الإلكتروني', 'Phone number or email');
  static String get enterPhoneOrEmail => _t('أدخل هاتفك أو بريدك', 'Enter your phone or email');
  static String get credentialsFromReception => _t('استخدم البيانات المقدمة من الاستقبال', 'Use the credentials provided by the front desk');
  static String get firstTimeHint => _t('المستخدمون الجدد: استخدم كلمة المرور المؤقتة من الاستقبال', 'New users: use the temporary password from the front desk');
  static String get firstTime => _t('أول مرة؟', 'First time?');
  static String get newMember => _t('عضو جديد؟', 'New member?');
  static String get visitReception => _t('يرجى زيارة استقبال النادي للحصول على بيانات الدخول', 'Please visit the gym\'s front desk to get your login credentials');

  // ─── CLIENT HOME ───────────────────────────────────────────
  static String get guest => _t('ضيف', 'Guest');
  static String get subExpiringSoon => _t('الاشتراك ينتهي قريباً', 'Subscription expiring soon');
  static String subExpiresInDays(int days) => _t('ينتهي اشتراكك خلال $days يوم', 'Your subscription expires in $days days');
  static String get subExpired => _t('انتهى الاشتراك', 'Subscription expired');
  static String get pleaseRenew => _t('يرجى تجديد اشتراكك', 'Please renew your subscription');
  static String get subFrozen => _t('الاشتراك مجمد', 'Subscription frozen');
  static String get subCurrentlyFrozen => _t('اشتراكك مجمد حالياً', 'Your subscription is currently frozen');
  static String get lowCoinBalance => _t('رصيد عملات منخفض', 'Low coin balance');
  static String get fewSessionsLeft => _t('جلسات قليلة متبقية', 'Few sessions left');
  static String onlyCoinsRemaining(dynamic n) => _t('$n عملة متبقية فقط', 'Only $n coins remaining');
  static String onlySessionsRemaining(dynamic n) => _t('$n جلسة متبقية فقط', 'Only $n sessions remaining');
  static String get subscription => _t('الاشتراك', 'Subscription');
  static String get type => _t('النوع', 'Type');
  static String get expiresLabel => _t('ينتهي', 'Expires');
  static String get myQRCode => _t('رمز QR الخاص بي', 'My QR code');
  static String get entryHistory => _t('سجل الدخول', 'Entry history');
  static String get coinBased => _t('عملات', 'Coins');
  static String get timeBased => _t('زمني', 'Time-based');
  static String get sessionBased => _t('جلسات', 'Sessions');
  static String get personalTrainingType => _t('تدريب شخصي', 'Personal training');
  static String get remainingLabel => _t('المتبقي', 'Remaining');
  static String get timeLeft => _t('الوقت المتبقي', 'Time left');
  static String get sessionsLabel => _t('الجلسات', 'Sessions');
  static String get training => _t('التدريب', 'Training');

  // ─── CLIENT MAIN SCREEN ────────────────────────────────────
  static String get qr => _t('QR', 'QR');
  static String get plan => _t('الخطة', 'Plan');
  static String get history => _t('السجل', 'History');

  // ─── CLIENT MEMBER-APP REDESIGN ────────────────────────────
  static String get checkInNav => _t('الدخول', 'Check-in');
  static String get quickCheckIn => _t('دخول سريع', 'Quick check-in');
  static String get showQrAtDoor => _t('اعرض رمز QR عند الباب', 'Show your QR code at the door');
  static String get untilRenewal => _t('متبقٍ حتى التجديد', 'left until renewal');
  static String get manageSubscription => _t('إدارة الاشتراك', 'Manage subscription');
  static String get dayUnit => _t('يوم', 'day');
  static String get coinUnit => _t('عملة', 'coin');
  static String get sessionUnit => _t('جلسة', 'session');
  static String get entryCode => _t('رمز الدخول', 'Entry code');
  static String get pointCodeAtScanner => _t('وجّه الرمز نحو الماسح الضوئي عند مدخل النادي.', 'Point the code at the scanner at the gym entrance.');
  static String get signUp => _t('إنشاء حساب', 'Create account');
  static String get yourGymInPocket => _t('ناديك في جيبك — اشترك، ادخل، وتابع تقدمك.', 'Your gym in your pocket — subscribe, check in, and track your progress.');
  static String get recentVisits => _t('آخر زياراتك للنادي', 'Your recent gym visits');

  // ─── CLIENT OVERVIEW TAB ───────────────────────────────────
  static String get subEndpointNotAvailable => _t('نقطة نهاية الاشتراك غير متاحة.', 'The subscription endpoint isn\'t available.');
  static String expiresInDays(int days) => _t('ينتهي خلال $days يوم', 'Expires in $days days');
  static String get expired => _t('منتهي', 'Expired');
  static String get remainingCoins => _t('العملات المتبقية', 'Remaining coins');
  static String get timeRemaining => _t('الوقت المتبقي', 'Time remaining');
  static String get trainingSessions => _t('جلسات التدريب', 'Training sessions');
  static String get sessionsLeft => _t('الجلسات المتبقية', 'Sessions left');
  static String get daysLeft => _t('الأيام المتبقية', 'Days left');
  static String get membership => _t('العضوية', 'Membership');
  static String coinsBalance(dynamic n) => _t('رصيد العملات: $n', 'Coin balance: $n');
  static String sessionRemaining(dynamic n) => _t('$n جلسة متبقية', '$n sessions remaining');

  // ─── SUBSCRIPTION SCREEN ───────────────────────────────────
  static String get subscriptionDetails => _t('تفاصيل الاشتراك', 'Subscription details');
  static String get subscriptionInformation => _t('معلومات الاشتراك', 'Subscription information');
  static String get planLabel => _t('الخطة', 'Plan');
  static String get startDate => _t('تاريخ البدء', 'Start date');
  static String get expiryDate => _t('تاريخ الانتهاء', 'Expiry date');
  static String get allowedServices => _t('الخدمات المسموحة', 'Allowed services');
  static String get freezeHistory => _t('سجل التجميد', 'Freeze history');
  static String frozenDate(String date) => _t('مجمد: $date', 'Frozen: $date');
  static String unfrozenDate(String date) => _t('إلغاء التجميد: $date', 'Unfrozen: $date');
  static String reason(String r) => _t('السبب: $r', 'Reason: $r');
  static String get noSubscriptionData => _t('لا توجد بيانات اشتراك', 'No subscription data');
  static String progressLabel(dynamic current, dynamic total) => _t('$current / $total متبقي', '$current / $total remaining');
  static String get remainingCoinsLabel => _t('العملات المتبقية', 'Remaining coins');
  static String get timeRemainingLabel => _t('الوقت المتبقي', 'Time remaining');
  static String get sessionsRemainingLabel => _t('الجلسات المتبقية', 'Sessions remaining');
  static String get trainingSessionsLabel => _t('جلسات التدريب', 'Training sessions');

  // ─── QR SCREEN ─────────────────────────────────────────────
  static String get qrRefreshed => _t('تم تحديث رمز QR بنجاح', 'QR code refreshed successfully');
  static String failedToRefresh(String e) => _t('فشل التحديث: $e', 'Refresh failed: $e');
  static String get myQRCodeTitle => _t('رمز QR الخاص بي', 'My QR code');
  static String get qrNoActiveSub => _t('رمز QR صالح، لكن ليس لديك اشتراك نشط. يرجى تفعيل اشتراك لاستخدام خدمات النادي.', 'Your QR code is valid, but you don\'t have an active subscription. Please activate a subscription to use the gym\'s services.');
  static String get scannableYes => _t('قابل للمسح: نعم', 'Scannable: Yes');
  static String get scannableExpired => _t('قابل للمسح: منتهي', 'Scannable: Expired');
  static String get qrCodeExpired => _t('رمز QR منتهي الصلاحية', 'QR code expired');
  static String expiresIn(String time) => _t('ينتهي خلال: $time', 'Expires in: $time');
  static String get refreshQRCode => _t('تحديث رمز QR', 'Refresh QR code');
  static String get howToUse => _t('كيفية الاستخدام', 'How to use');
  static String get qrInstructions => _t('• أظهر رمز QR هذا عند مدخل النادي\n• رمز QR صالح لمدة ساعة واحدة\n• حدّث إذا انتهت صلاحيته\n• أبقِ شاشة الهاتف مضيئة للمسح', '• Show this QR code at the gym entrance\n• The QR code is valid for one hour\n• Refresh it if it expires\n• Keep your phone screen bright for scanning');
  static String get activeSubscriptionStatus => _t('اشتراك نشط', 'Active subscription');
  static String get subscriptionFrozenStatus => _t('اشتراك مجمد', 'Frozen subscription');
  static String get subscriptionStoppedStatus => _t('اشتراك متوقف', 'Stopped subscription');
  static String get inactiveStatus => _t('غير نشط', 'Inactive');

  // ─── ENTRY HISTORY SCREEN ──────────────────────────────────
  static String get entryHistoryNotAvailable => _t('ميزة سجل الدخول غير متاحة حالياً.\n\nيرجى المحاولة لاحقاً أو التواصل مع الدعم.', 'The entry history feature isn\'t available right now.\n\nPlease try again later or contact support.');
  static String get entryHistoryTitle => _t('سجل الدخول', 'Entry history');
  static String get noEntryHistory => _t('لا يوجد سجل دخول بعد', 'No entry history yet');
  static String get visitsAppearHere => _t('ستظهر زياراتك للنادي هنا', 'Your gym visits will appear here');
  static String get approvedEntry => _t('مقبول', 'Approved');
  static String get deniedEntry => _t('مرفوض', 'Denied');

  // ─── CLIENT SETTINGS ───────────────────────────────────────
  static String get profileInformation => _t('معلومات الملف الشخصي', 'Profile information');
  static String get viewEditProfile => _t('عرض وتعديل ملفك الشخصي', 'View and edit your profile');
  static String get profileEditingSoon => _t('تعديل الملف الشخصي قريباً', 'Profile editing coming soon');
  static String get contactInformationSetting => _t('معلومات الاتصال', 'Contact information');
  static String get manageContactDetails => _t('إدارة تفاصيل الاتصال', 'Manage your contact details');
  static String get contactEditingSoon => _t('تعديل الاتصال قريباً', 'Contact editing coming soon');
  static String get preferences => _t('التفضيلات', 'Preferences');
  static String get notifications => _t('الإشعارات', 'Notifications');
  static String get manageNotifications => _t('إدارة إعدادات الإشعارات', 'Manage notification settings');
  static String get notificationsSoon => _t('إعدادات الإشعارات قريباً', 'Notification settings coming soon');
  static String get notificationsEnabled => _t('الإشعارات مفعّلة', 'Notifications enabled');
  static String get notificationsDisabled => _t('الإشعارات معطّلة', 'Notifications disabled');
  static String get enableNotifications => _t('تفعيل الإشعارات', 'Enable notifications');
  static String get receiveNotificationsDesc => _t('استقبال إشعارات الاشتراكات والدخول والتنبيهات', 'Receive notifications for subscriptions, entries, and alerts');
  static String get notificationsActivated => _t('تم تفعيل الإشعارات', 'Notifications activated');
  static String get notificationsDeactivated => _t('تم تعطيل الإشعارات', 'Notifications deactivated');
  static String get darkMode => _t('الوضع الداكن', 'Dark mode');
  static String get themeSelectionSoon => _t('اختيار السمة قريباً', 'Theme selection coming soon');
  static String get support => _t('الدعم', 'Support');
  static String get getHelpSupport => _t('الحصول على المساعدة والدعم', 'Get help and support');
  static String get about => _t('حول', 'About');
  static String get appVersionInfo => _t('إصدار التطبيق والمعلومات', 'App version and information');
  static String get gymClient => _t('عميل النادي', 'Gym Client');
  static String get modernGymApp => _t('تطبيق حديث لإدارة عضوية النادي الرياضي.', 'A modern app for managing your gym membership.');
  static String get privacyPolicy => _t('سياسة الخصوصية', 'Privacy policy');
  static String get readPrivacyPolicy => _t('قراءة سياسة الخصوصية', 'Read the privacy policy');
  static String get privacyPolicySoon => _t('سياسة الخصوصية قريباً', 'Privacy policy coming soon');
  static String get deleteAccount => _t('حذف الحساب', 'Delete account');
  static String get deleteAccountAfter90Days => _t('سيتم حذف الحساب بعد 90 يوماً', 'The account will be deleted after 90 days');
  static String get deleteAccountWarning => _t('يمكنك طلب حذف حسابك الآن، وسيتم حذفه نهائياً بعد 90 يوماً.', 'You can request account deletion now — it will be permanently deleted after 90 days.');
  static String get deleteAccountConfirmQuestion => _t('هل تريد إرسال طلب حذف الحساب؟', 'Do you want to submit an account deletion request?');
  static String get deleteAccountRequested => _t('تم إرسال طلب حذف الحساب. سيتم حذف حسابك خلال 90 يوماً.', 'Account deletion request submitted. Your account will be deleted within 90 days.');
  static String get deleteAccountRequestFailed => _t('فشل إرسال طلب حذف الحساب.', 'Failed to submit the account deletion request.');
  static String get requestDeletion => _t('طلب الحذف', 'Request deletion');
  static String get signOutTestingOnly => _t('تسجيل الخروج (للاختبار فقط)', 'Log out (testing only)');
  static String get signOutQuestion => _t('تسجيل الخروج من حسابك؟', 'Log out of your account?');

  // ─── CHANGE PASSWORD SCREEN ────────────────────────────────
  static String get fillAllFields => _t('يرجى ملء جميع الحقول', 'Please fill in all fields');
  static String get newPasswordMin6 => _t('كلمة المرور الجديدة يجب أن تكون 6 أحرف على الأقل', 'The new password must be at least 6 characters');
  static String get passwordsDoNotMatch => _t('كلمات المرور الجديدة غير متطابقة', 'The new passwords don\'t match');
  static String get newPasswordMustDiffer => _t('كلمة المرور الجديدة يجب أن تختلف عن الحالية', 'The new password must be different from the current one');
  static String get passwordChangedSuccess => _t('تم تغيير كلمة المرور بنجاح!', 'Password changed successfully!');
  static String get setNewPassword => _t('تعيين كلمة مرور جديدة', 'Set a new password');
  static String get changeTempPassword => _t('يرجى تغيير كلمة المرور المؤقتة قبل المتابعة', 'Please change your temporary password before continuing');
  static String get temporaryPasswordLabel => _t('كلمة المرور المؤقتة', 'Temporary password');
  static String get min6Characters => _t('6 أحرف كحد أدنى', 'Minimum 6 characters');

  // ─── ACTIVATION SCREEN ─────────────────────────────────────
  static String get pleaseEnterAllDigits => _t('يرجى إدخال جميع الأرقام الـ 6', 'Please enter all 6 digits');
  static String get activationCodeResent => _t('تم إعادة إرسال رمز التفعيل!', 'Activation code resent!');
  static String get activateAccount => _t('تفعيل الحساب', 'Activate account');
  static String get enterActivationCode => _t('أدخل رمز التفعيل', 'Enter activation code');
  static String codeSentTo(String id) => _t('أرسلنا رمزاً مكوناً من 6 أرقام إلى\n$id', 'We sent a 6-digit code to\n$id');
  static String get verify => _t('تحقق', 'Verify');
  static String get didntReceiveCode => _t('لم تستلم الرمز؟ إعادة إرسال', 'Didn\'t receive the code? Resend');
  static String get codeExpires10Min => _t('ينتهي الرمز خلال 10 دقائق', 'The code expires in 10 minutes');

  // ─── BIOMETRIC SETTINGS ────────────────────────────────────
  static String get security => _t('الأمان', 'Security');
  static String get biometricLogin => _t('تسجيل الدخول بالبصمة', 'Biometric login');
  static String get useBiometricToLogin => _t('استخدم البصمة أو الوجه لتسجيل الدخول', 'Use your fingerprint or face to log in');
  static String get quicklyLoginWithBiometric => _t('تسجيل دخول سريع بالبصمة أو الوجه', 'Quick login with fingerprint or face');
  static String get setupBiometricLogin => _t('إعداد تسجيل الدخول بالبصمة', 'Set up biometric login');
  static String get fingerprint => _t('بصمة الإصبع', 'Fingerprint');
  static String get faceId => _t('بصمة الوجه', 'Face ID');
  static String get biometric => _t('البصمة', 'Biometric');
  static String get deviceSupportsBoth => _t('جهازك يدعم بصمة الإصبع وبصمة الوجه. اضغط متابعة للتحقق.', 'Your device supports both fingerprint and face recognition. Tap continue to verify.');
  static String get deviceSupportsFingerprint => _t('جهازك يدعم بصمة الإصبع. اضغط متابعة للتحقق.', 'Your device supports fingerprint recognition. Tap continue to verify.');
  static String get deviceSupportsFaceId => _t('جهازك يدعم بصمة الوجه. اضغط متابعة للتحقق.', 'Your device supports face recognition. Tap continue to verify.');
  static String get deviceSupportsBiometric => _t('جهازك يدعم المصادقة البيومترية. اضغط متابعة للتحقق.', 'Your device supports biometric authentication. Tap continue to verify.');
  static String get verifyBiometricToEnable => _t('تحقق من بصمتك لتفعيل تسجيل الدخول السريع', 'Verify your biometrics to enable quick login');
  static String get biometricVerificationFailed => _t('فشل التحقق من البصمة. يرجى المحاولة مرة أخرى.', 'Biometric verification failed. Please try again.');
  static String get biometricVerified => _t('تم التحقق من البصمة!', 'Biometrics verified!');
  static String get enterPasswordToComplete => _t('أدخل كلمة المرور لإكمال الإعداد. سيتم تخزين بياناتك بشكل آمن على هذا الجهاز.', 'Enter your password to complete setup. Your data will be stored securely on this device.');
  static String get enable => _t('تفعيل', 'Enable');
  static String get biometricEnabled => _t('تم تفعيل تسجيل الدخول بالبصمة بنجاح!', 'Biometric login enabled successfully!');
  static String get disableBiometricLogin => _t('تعطيل تسجيل الدخول بالبصمة', 'Disable biometric login');
  static String get disableBiometricConfirm => _t('هل أنت متأكد من تعطيل تسجيل الدخول بالبصمة؟ ستحتاج إلى إدخال كلمة المرور لتسجيل الدخول.', 'Are you sure you want to disable biometric login? You\'ll need to enter your password to log in.');
  static String get disable => _t('تعطيل', 'Disable');
  static String get biometricDisabled => _t('تم تعطيل تسجيل الدخول بالبصمة', 'Biometric login disabled');

  // ─── ERROR DISPLAY ─────────────────────────────────────────
  static String get errorTitle => _t('خطأ', 'Error');

  // ─── DATE RANGE PICKER ─────────────────────────────────────
  static String get selectDateRange => _t('اختيار نطاق التاريخ', 'Select date range');
  static String get startDateLabel => _t('تاريخ البدء', 'Start date');
  static String get endDateLabel => _t('تاريخ الانتهاء', 'End date');

  // ─── SUPER ADMIN DASHBOARD ─────────────────────────────────
  static String get platformAdmin => _t('مدير المنصة', 'Platform Admin');
  static String get loadingPlatformData => _t('جاري تحميل بيانات المنصة...', 'Loading platform data...');
  static String get owners => _t('المالكون', 'Owners');
  static String get newOwner => _t('مالك جديد', 'New owner');
  static String get platformAdministration => _t('إدارة المنصة', 'Platform administration');
  static String get createManageOwners => _t('إنشاء وإدارة حسابات مالكي الأندية', 'Create and manage gym owner accounts');
  static String get platformOverview => _t('نظرة عامة على المنصة', 'Platform overview');
  static String get totalOwners => _t('إجمالي المالكين', 'Total owners');
  static String get activeOwners => _t('المالكون النشطون', 'Active owners');
  static String get recentOwners => _t('المالكون الأخيرون', 'Recent owners');
  static String get noOwnersYet => _t('لا يوجد مالكون بعد', 'No owners yet');
  static String get createFirstOwner => _t('أنشئ أول حساب مالك نادي للبدء', 'Create your first gym owner account to get started');
  static String get noOwnersYetTab => _t('لا يوجد مالكون بعد', 'No owners yet');
  static String get tapPlusToCreate => _t('اضغط + لإنشاء أول مالك نادي', 'Tap + to create your first gym owner');
  static String lastLogin(String time) => _t('آخر دخول: $time', 'Last login: $time');
  static String minutesAgo(int n) => _t('منذ $n دقيقة', '$n minutes ago');
  static String hoursAgo(int n) => _t('منذ $n ساعة', '$n hours ago');
  static String daysAgo(int n) => _t('منذ $n يوم', '$n days ago');

  // ─── SUPER ADMIN SETTINGS ──────────────────────────────────
  static String get superAdmin => _t('المدير العام', 'Super Admin');
  static String get platformAdministrator => _t('مدير المنصة', 'Platform administrator');
  static String get appVersion => _t('إصدار التطبيق', 'App version');
  static String get platform => _t('المنصة', 'Platform');
  static String get multiGymSaas => _t('نظام إدارة الأندية المتعددة', 'Multi-gym management system');

  // ─── CREATE GYM SCREEN ─────────────────────────────────────
  static String get createGymOwner => _t('إنشاء مالك نادي', 'Create gym owner');
  static String get ownerAccount => _t('حساب المالك', 'Owner account');
  static String get ownerAccountDescription => _t('أنشئ حساب دخول لمالك النادي. سيقوم بتسجيل الدخول وإعداد اسم النادي والشعار والعلامة التجارية والفروع والموظفين بنفسه.', 'Create a login account for the gym owner. They\'ll log in and set up the gym name, logo, branding, branches, and staff themselves.');
  static String get ownerDetails => _t('تفاصيل المالك', 'Owner details');
  static String get fullNameLabel => _t('الاسم الكامل', 'Full name');
  static String get fullNameHintOwner => _t('مثال: أحمد حسن', 'e.g. Ahmed Hassan');
  static String get fullNameIsRequired => _t('الاسم الكامل مطلوب', 'Full name is required');
  static String get usernameLabel => _t('اسم المستخدم', 'Username');
  static String get usernameHintOwner => _t('مثال: ahmed_gym', 'e.g. ahmed_gym');
  static String get usernameIsRequired => _t('اسم المستخدم مطلوب', 'Username is required');
  static String get usernameTooShort => _t('اسم المستخدم يجب أن يكون 3 أحرف على الأقل', 'Username must be at least 3 characters');
  static String get usernameNoSpaces => _t('اسم المستخدم لا يمكن أن يحتوي على مسافات', 'Username can\'t contain spaces');
  static String get passwordLabel => _t('كلمة المرور', 'Password');
  static String get createPasswordHint => _t('أنشئ كلمة مرور للمالك', 'Create a password for the owner');
  static String get passwordIsRequired => _t('كلمة المرور مطلوبة', 'Password is required');
  static String get passwordTooShort => _t('كلمة المرور يجب أن تكون 6 أحرف على الأقل', 'Password must be at least 6 characters');
  static String get emailOptional => _t('البريد الإلكتروني (اختياري)', 'Email (optional)');
  static String get emailHint => _t('مثال: owner@email.com', 'e.g. owner@email.com');
  static String get phoneOptionalLabel => _t('الهاتف (اختياري)', 'Phone (optional)');
  static String get phoneHint => _t('مثال: 01012345678', 'e.g. 01012345678');
  static String get ownerCreated => _t('تم إنشاء المالك بنجاح', 'Owner created successfully');
  static String get failedToCreateOwner => _t('فشل إنشاء المالك', 'Failed to create owner');
  static String get createOwnerAccount => _t('إنشاء حساب المالك', 'Create owner account');

  // ─── GYM DETAIL SCREEN ─────────────────────────────────────
  static String get statistics => _t('الإحصائيات', 'Statistics');
  static String get ownerInformation => _t('معلومات المالك', 'Owner information');
  static String get name => _t('الاسم', 'Name');
  static String get notAssigned => _t('غير معيّن', 'Not assigned');
  static String get branding => _t('العلامة التجارية', 'Branding');
  static String get emailDomain => _t('نطاق البريد', 'Email domain');
  static String get setupComplete => _t('اكتمل الإعداد', 'Setup complete');
  static String get setupPending => _t('قيد الإعداد', 'Setup pending');
  static String get created => _t('تاريخ الإنشاء', 'Created');

  // ─── HELPERS (getRelativeTime, validators, BMI) ────────────
  static String yearsAgo(int n) => _t('منذ $n سنة', '$n years ago');
  static String monthsAgo(int n) => _t('منذ $n شهر', '$n months ago');
  static String get justNow => _t('الآن', 'Just now');
  static String fieldRequired(String name) => _t('$name مطلوب', '$name is required');
  static String get emailIsRequired => _t('البريد الإلكتروني مطلوب', 'Email is required');
  static String get invalidEmailFormat => _t('تنسيق البريد الإلكتروني غير صالح', 'Invalid email format');
  static String get phoneIsRequired => _t('رقم الهاتف مطلوب', 'Phone number is required');
  static String get invalidPhoneFormat => _t('تنسيق رقم الهاتف غير صالح', 'Invalid phone format');
}
