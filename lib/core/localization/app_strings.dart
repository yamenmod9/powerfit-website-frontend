/// Centralized Arabic translations for the entire app.
/// All UI strings are organized by feature area.
/// Dynamic values (names, IDs, numbers) stay as parameters.
class S {
  S._();

  // ─── COMMON / SHARED ────────────────────────────────────────
  static const String login = 'تسجيل الدخول';
  static const String logout = 'تسجيل الخروج';
  static const String cancel = 'إلغاء';
  static const String close = 'إغلاق';
  static const String confirm = 'تأكيد';
  static const String retry = 'إعادة المحاولة';
  static const String save = 'حفظ';
  static const String apply = 'تطبيق';
  static const String clear = 'مسح';
  static const String submit = 'إرسال';
  static const String ok = 'حسناً';
  static const String yes = 'نعم';
  static const String no = 'لا';
  static const String back = 'رجوع';
  static const String continueText = 'متابعة';
  static const String refresh = 'تحديث';
  static const String loading = 'جاري التحميل...';
  static const String error = 'خطأ';
  static const String required = 'مطلوب';
  static const String settings = 'الإعدادات';
  static const String active = 'نشط';
  static const String inactive = 'غير نشط';
  static const String unknown = 'غير معروف';
  static const String na = 'غير متوفر';
  static const String viewAll = 'عرض الكل';
  static const String viewDetails = 'عرض التفاصيل';
  static const String or = 'أو';
  static const String register = 'تسجيل';
  static const String delete = 'حذف';
  static const String edit = 'تعديل';
  static const String activate = 'تفعيل';
  static const String deactivate = 'إلغاء التفعيل';
  static const String pending = 'معلق';
  static const String approved = 'موافق عليه';
  static const String change = 'تغيير';

  // ─── LOGIN SCREEN ───────────────────────────────────────────
  static const String managementSystem = 'نظام الإدارة';
  static const String loginFailed = 'فشل تسجيل الدخول';
  static const String username = 'اسم المستخدم';
  static const String enterUsername = 'أدخل اسم المستخدم';
  static const String usernameRequired = 'اسم المستخدم مطلوب';
  static const String password = 'كلمة المرور';
  static const String enterPassword = 'أدخل كلمة المرور';
  static const String passwordRequired = 'كلمة المرور مطلوبة';
  static const String loginWithBiometrics = 'تسجيل الدخول بالبصمة';
  static const String biometricLoginFailed = 'فشل تسجيل الدخول بالبصمة';
  static const String staffConsoleSubtitle = 'ادخل إلى كونسول الموظفين';
  static const String memberEntry = 'دخول الأعضاء';
  static const String roleAutoResolved = 'يحدّد النظام دورك تلقائياً بعد تسجيل الدخول.';
  static const String backToHome = 'الرئيسية';

  // ─── GYM SETUP WIZARD ──────────────────────────────────────
  static const String setupYourGym = 'إعداد النادي الرياضي';
  static String stepOf(int step) => 'الخطوة $step من 3 — ${_stepLabels[step - 1]}';
  static const List<String> _stepLabels = ['اسم النادي', 'الشعار', 'ألوان العلامة التجارية'];
  static const String gymName = 'اسم النادي';
  static const String logo = 'الشعار';
  static const String brandColors = 'ألوان العلامة التجارية';
  static const String finishSetup = 'إنهاء الإعداد';
  static const String whatsYourGymCalled = 'ما اسم ناديك الرياضي؟';
  static const String gymNameHint = 'مثال: بودي آرت فيتنس';
  static const String gymNameAppears = 'سيظهر هذا الاسم في التطبيق لجميع الموظفين والعملاء.';
  static const String pleaseEnterGymName = 'يرجى إدخال اسم النادي';
  static const String nameTooShort = 'يجب أن يكون الاسم حرفين على الأقل';
  static const String fileNotFound = 'الملف المحدد غير موجود';
  static const String chooseFromGallery = 'اختيار من المعرض';
  static const String takePhoto = 'التقاط صورة';
  static const String removeLogo = 'إزالة الشعار';
  static const String uploadGymLogo = 'ارفع شعار النادي';
  static const String logoShownOn = 'سيظهر في شاشة تسجيل الدخول ورأس التطبيق.';
  static const String cannotDisplayImage = 'لا يمكن عرض الصورة';
  static const String changeLogo = 'تغيير الشعار';
  static const String chooseLogo = 'اختيار شعار';
  static const String skipLogoHint = 'يمكنك تخطي هذا الآن وإضافة شعار لاحقاً من الإعدادات.';
  static const String tapToUpload = 'اضغط للرفع';
  static const String chooseYourBrandColors = 'اختر ألوان العلامة التجارية';
  static const String colorsUsedThroughout = 'ستُستخدم هذه الألوان في جميع أنحاء التطبيق لناديك.';
  static const String primaryColor = 'اللون الأساسي';
  static const String usedForButtons = 'يُستخدم للأزرار والعناصر المميزة';
  static const String secondaryColor = 'اللون الثانوي';
  static const String usedForSecondary = 'يُستخدم للعناصر الثانوية';
  static const String preview = 'معاينة';
  static const String yourGym = 'ناديك';
  static const String primary = 'أساسي';
  static const String secondary = 'ثانوي';

  // ─── OWNER DASHBOARD ───────────────────────────────────────
  static const String ownerDashboard = 'لوحة تحكم المالك';
  static const String loadingDashboard = 'جاري تحميل لوحة التحكم...';
  static const String overview = 'نظرة عامة';
  static const String branches = 'الفروع';
  static const String staff = 'الموظفون';
  static const String finance = 'المالية';
  static const String issues = 'المشكلات';
  static const String keyMetrics = 'المؤشرات الرئيسية';
  static const String recentAlerts = 'التنبيهات الأخيرة';
  static const String welcomeBack = 'أهلاً بعودتك،';
  static const String totalRevenue = 'إجمالي الإيرادات';
  static const String activeSubs = 'الاشتراكات النشطة';
  static const String totalCustomers = 'إجمالي العملاء';
  static const String noBranchesFound = 'لا توجد فروع';
  static const String noBranchesYet = 'لا توجد فروع بعد';
  static const String createFirstBranchDesc = 'أنشئ أول فرع لبدء إدارة الجيم';
  static const String createBranch = 'إنشاء فرع';
  static const String branchNameLabel = 'اسم الفرع';
  static const String branchNameHint = 'مثال: نادي التنين';
  static const String branchCodeLabel = 'رمز الفرع';
  static const String branchCodeHint = 'مثال: DRG001';
  static const String branchAddressLabel = 'العنوان';
  static const String branchAddressHint = 'مثال: ١٢٣ شارع النيل';
  static const String branchPhoneLabel = 'هاتف الفرع';
  static const String branchPhoneHint = 'مثال: 0201234567';
  static const String branchCityLabel = 'المدينة';
  static const String branchCityHint = 'مثال: القاهرة';
  static const String branchCreated = 'تم إنشاء الفرع بنجاح';
  static const String failedToCreateBranch = 'فشل إنشاء الفرع';
  static const String noStaffYet = 'لا يوجد موظفون بعد';
  static const String addStaffDesc = 'أضف موظفين لفروعك لبدء العمل';
  static const String createBranchFirst = 'أنشئ فرعاً أولاً قبل إضافة الموظفين';
  static const String customers = 'العملاء';
  static const String revenue = 'الإيرادات';
  static const String leaderboard = 'لوحة المتصدرين';
  static const String addStaff = 'إضافة موظف';
  static String transactionsCount(int count) => '$count عملية';
  static const String totalExpenses = 'إجمالي المصروفات';
  static const String netProfit = 'صافي الربح';
  static const String activeSubscriptions = 'الاشتراكات النشطة';
  static const String noComplaints = 'لا توجد شكاوى';
  static const String allClear = 'كل شيء على ما يرام!';
  static const String complaint = 'شكوى';
  static const String unknownBranch = 'فرع غير معروف';

  // ─── OWNER SETTINGS ────────────────────────────────────────
  static const String owner = 'المالك';
  static const String ownerRole = 'مالك';
  static const String appearance = 'المظهر';
  static const String theme = 'السمة';
  static const String darkModeDefault = 'الوضع الداكن (افتراضي)';
  static const String appUsesDarkTheme = 'التطبيق يستخدم السمة الداكنة افتراضياً';
  static const String language = 'اللغة';
  static const String arabicDefault = 'العربية (افتراضي)';
  static const String languageComingSoon = 'اختيار اللغة قريباً';
  static const String account = 'الحساب';
  static const String changePassword = 'تغيير كلمة المرور';
  static const String aboutApp = 'حول التطبيق';
  static const String helpSupport = 'المساعدة والدعم';
  static const String helpSupportComingSoon = 'المساعدة والدعم قريباً';
  static const String currentPassword = 'كلمة المرور الحالية';
  static const String newPassword = 'كلمة المرور الجديدة';
  static const String confirmNewPassword = 'تأكيد كلمة المرور الجديدة';
  static const String passwordChangeComingSoon = 'تغيير كلمة المرور قريباً';
  static const String aboutGymManagement = 'حول تطبيق إدارة النادي';
  static const String version100 = 'الإصدار: 1.0.0';
  static const String buildDate = 'البناء: فبراير 2026';
  static const String aboutDescription = 'نظام شامل لإدارة الأندية الرياضية للمالكين والمديرين والمحاسبين والموظفين.';
  static const String confirmLogout = 'هل أنت متأكد من تسجيل الخروج؟';

  // ─── SMART ALERTS ──────────────────────────────────────────
  static const String smartAlerts = 'التنبيهات الذكية';
  static const String loadingAlerts = 'جاري تحميل التنبيهات...';
  static const String noAlerts = 'لا توجد تنبيهات';
  static const String allSystemsNormal = 'جميع الأنظمة تعمل بشكل طبيعي';
  static const String critical = 'حرج';
  static const String warning = 'تحذير';
  static const String info = 'معلومات';
  static const String criticalAlerts = 'تنبيهات حرجة';
  static const String warnings = 'تحذيرات';
  static const String information = 'معلومات';
  static const String alert = 'تنبيه';
  static const String noDescription = 'لا يوجد وصف';
  static const String allBranches = 'جميع الفروع';
  static const String dismiss = 'تجاهل';
  static const String alertDetails = 'تفاصيل التنبيه';
  static String alertType(String type) => 'النوع: $type';
  static String alertMessage(String msg) => 'الرسالة: $msg';
  static String alertBranch(String branch) => 'الفرع: $branch';
  static String alertTime(String time) => 'الوقت: $time';
  static String alertDetailsFull(String details) => 'التفاصيل: $details';
  static const String alertDismissed = 'تم تجاهل التنبيه';

  // ─── STAFF LEADERBOARD ─────────────────────────────────────
  static const String staffLeaderboard = 'لوحة متصدري الموظفين';
  static const String loadingStaffPerformance = 'جاري تحميل أداء الموظفين...';
  static const String noPerformanceData = 'لا توجد بيانات أداء للموظفين';
  static const String topPerformers = 'الأفضل أداءً';
  static const String allStaffMembers = 'جميع الموظفين';
  static const String transactions = 'العمليات';
  static const String retention = 'الاحتفاظ';
  static const String filterOptions = 'خيارات التصفية';
  static const String sortByRevenue = 'ترتيب حسب الإيرادات';
  static const String sortByCustomers = 'ترتيب حسب العملاء';
  static const String sortByRetention = 'ترتيب حسب معدل الاحتفاظ';

  // ─── BRANCH DETAIL ─────────────────────────────────────────
  static const String operations = 'العمليات';
  static const String loadingBranchDetails = 'جاري تحميل تفاصيل الفرع...';
  static const String failedToLoadBranch = 'فشل تحميل بيانات الفرع';
  static const String capacity = 'السعة';
  static const String branchInformation = 'معلومات الفرع';
  static const String branchId = 'رقم الفرع';
  static const String branchName = 'اسم الفرع';
  static const String status = 'الحالة';
  static const String address = 'العنوان';
  static const String revenueByService = 'الإيرادات حسب الخدمة';
  static const String noRevenueData = 'لا توجد بيانات إيرادات';
  static String customersCount(int count) => '$count عميل';
  static const String branchStaff = 'موظفو الفرع';
  static const String noStaffData = 'لا توجد بيانات موظفين';
  static String txCount(int count) => '$count عملية';
  static const String dailyOperations = 'العمليات اليومية';
  static const String checkInsThisMonth = 'تسجيلات الدخول هذا الشهر';
  static const String openComplaints = 'الشكاوى المفتوحة';
  static const String expiredThisMonth = 'المنتهية هذا الشهر';
  static const String frozenSubscriptions = 'الاشتراكات المجمدة';
  static const String newCustomers = 'عملاء جدد';

  // ─── OPERATIONAL MONITOR ───────────────────────────────────
  static const String operationalMonitor = 'مراقبة العمليات';
  static const String loadingOperationalData = 'جاري تحميل بيانات العمليات...';
  static const String failedToLoadOperational = 'فشل تحميل بيانات العمليات';
  static const String liveMonitoring = 'مراقبة مباشرة';
  static const String gymFloor = 'صالة التمارين';
  static const String swimmingPool = 'حوض السباحة';
  static const String karateArea = 'منطقة الكاراتيه';
  static String spotsLeft(int count) => '$count مكان متاح';
  static const String todaysClasses = 'حصص اليوم';
  static const String staffAttendance = 'حضور الموظفين';
  static const String yogaClass = 'حصة يوغا';
  static const String karateBasics = 'أساسيات الكاراتيه';
  static const String swimmingLessons = 'دروس السباحة';
  static const String advancedKarate = 'كاراتيه متقدم';
  static const String live = 'مباشر';
  static const String present = 'حاضر';
  static const String absent = 'غائب';

  // ─── ADD STAFF DIALOG ──────────────────────────────────────
  static const String addNewStaff = 'إضافة موظف جديد';
  static const String fullName = 'الاسم الكامل';
  static const String fullNameRequired = 'الاسم الكامل *';
  static const String fullNameHint = 'مثال: أحمد حسن';
  static const String usernameRequired2 = 'اسم المستخدم *';
  static const String usernameHint = 'مثال: ahmed_front';
  static const String atLeast3Chars = '3 أحرف على الأقل';
  static const String emailRequired = 'البريد الإلكتروني *';
  static const String email = 'البريد الإلكتروني';
  static const String autoGeneratedFromUsername = 'يُولّد تلقائياً من اسم المستخدم';
  static const String resetToAutoGenerated = 'إعادة التعيين للتوليد التلقائي';
  static const String invalidEmail = 'بريد إلكتروني غير صالح';
  static const String passwordRequired2 = 'كلمة المرور *';
  static const String min6Chars = '6 أحرف على الأقل';
  static const String atLeast6Chars = '6 أحرف على الأقل';
  static const String phoneOptional = 'الهاتف (اختياري)';
  static const String roleRequired = 'الدور *';
  static const String branchManager = 'مدير فرع';
  static const String frontDesk = 'الاستقبال';
  static const String branchAccountant = 'محاسب فرع';
  static const String centralAccountant = 'محاسب مركزي';
  static const String branchRequired = 'الفرع *';
  static const String noBranchesCreateFirst = 'لا توجد فروع. أنشئ فرعاً أولاً.';
  static const String selectBranch = 'اختر فرعاً';
  static const String creating = 'جاري الإنشاء...';
  static const String createStaffMember = 'إنشاء موظف';
  static String staffAddedSuccess(String name) => 'تمت إضافة $name بنجاح!';

  // ─── RECEPTION NAVIGATION ──────────────────────────────────
  static const String home = 'الرئيسية';
  static const String subs = 'الاشتراكات';
  static const String ops = 'العمليات';
  static const String clients = 'العملاء';
  static const String profile = 'الملف الشخصي';

  // ─── RECEPTION HOME ────────────────────────────────────────
  static const String dashboard = 'لوحة التحكم';
  static const String dashboardStats = 'إحصائيات لوحة التحكم';
  static const String newToday = 'جديد اليوم';
  static const String complaints = 'الشكاوى';
  static const String quickActions = 'إجراءات سريعة';
  static const String registerCustomer = 'تسجيل عميل';
  static const String activateSub = 'تفعيل اشتراك';
  static const String scanCustomerQR = 'مسح رمز QR للعميل';
  static const String recentCustomers = 'العملاء الأخيرون';
  static const String noRecentCustomers = 'لا يوجد عملاء حديثون';

  // ─── CUSTOMERS LIST ────────────────────────────────────────
  static const String allCustomers = 'جميع العملاء';
  static const String searchCustomers = 'البحث عن عملاء';
  static const String namePhoneEmail = 'الاسم أو الهاتف أو البريد';
  static String customersCountLabel(int count) => '$count عميل';
  static const String noCustomersFound = 'لا يوجد عملاء';
  static const String noCustomersMatch = 'لا يوجد عملاء مطابقون للبحث';
  static String copiedToClipboard(String label) => 'تم نسخ $label إلى الحافظة';
  static const String noSubscription = 'لا يوجد اشتراك';
  static const String phone = 'الهاتف';
  static const String qrCode = 'رمز QR';
  static const String clientAppCredentials = 'بيانات تطبيق العميل';
  static const String notAvailable = 'غير متوفر';
  static const String passwordNotReturned = '⚠️ كلمة المرور غير متاحة من الخادم — تحتاج إصلاح';
  static const String permanentLoginPassword = 'هذه كلمة المرور الدائمة للعميل';
  static String copyLabel(String label) => 'نسخ $label';

  // ─── CUSTOMER DETAIL ───────────────────────────────────────
  static const String customerProfile = 'ملف العميل';
  static String customerId(int id) => 'المعرف: $id';
  static const String scanQRToCheckIn = 'امسح رمز QR هذا لتسجيل الدخول';
  static const String viewFullQR = 'عرض رمز QR الكامل';
  static const String regenerating = 'جاري إعادة التوليد...';
  static const String regenerate = 'إعادة توليد';
  static const String qrRegenerated = 'تم إعادة توليد رمز QR بنجاح';
  static const String failedToRegenerateQR = 'فشل في إعادة توليد رمز QR';
  static const String temporaryPassword = 'كلمة المرور المؤقتة';
  static const String passwordChanged = 'تم تغيير كلمة المرور';
  static const String firstTimeLoginPassword = 'كلمة مرور تسجيل الدخول الأول';
  static const String sharePasswordWithCustomer = 'شارك هذه كلمة المرور مع العميل لتسجيل دخوله الأول';
  static const String contactInformation = 'معلومات الاتصال';
  static const String gender = 'الجنس';
  static const String age = 'العمر';
  static String ageYears(String a) => '$a سنة';
  static const String healthMetrics = 'المؤشرات الصحية';
  static const String weight = 'الوزن';
  static String weightKg(String w) => '$w كجم';
  static const String height = 'الطول';
  static String heightCm(String h) => '$h سم';
  static const String bmi = 'مؤشر كتلة الجسم';
  static const String bmr = 'معدل الأيض الأساسي';
  static String calValue(String c) => '$c سعرة';
  static const String dailyCalories = 'السعرات اليومية';
  static const String recommendedIntake = 'الكمية الموصى بها';

  // ─── OPERATIONS SCREEN ─────────────────────────────────────
  static const String dailyClosing = 'الإغلاق اليومي';
  static const String finalizeTodayTransactions = 'إنهاء عمليات اليوم';
  static const String recordPayment = 'تسجيل دفعة';
  static const String submitComplaint = 'تقديم شكوى';
  static const String dailyClosingConfirm = 'هل أنت متأكد من إجراء الإغلاق اليومي؟ سيتم إنهاء جميع عمليات اليوم.';
  static const String dailyClosingCompleted = 'تم الإغلاق اليومي بنجاح';
  static const String dailyClosingFailed = 'فشل الإغلاق اليومي';

  // ─── SUBSCRIPTION OPS ──────────────────────────────────────
  static const String subscriptionOperations = 'عمليات الاشتراك';
  static const String activateSubscription = 'تفعيل اشتراك';
  static const String renewSubscription = 'تجديد اشتراك';
  static const String freezeSubscription = 'تجميد اشتراك';
  static const String stopSubscription = 'إيقاف اشتراك';

  // ─── QR SCANNER ────────────────────────────────────────────
  static const String scanQRCode = 'مسح رمز QR';
  static const String loadingCustomer = 'جاري تحميل بيانات العميل...';
  static const String invalidQRFormat = 'تنسيق رمز QR غير صالح';
  static const String customerDataMissingId = 'بيانات العميل تفتقد المعرف';
  static const String invalidResponseFormat = 'تنسيق الاستجابة غير صالح';
  static String customerNotFound(int id) => 'العميل غير موجود (المعرف: $id)';
  static String checkInTitle(String name) => 'تسجيل دخول: $name';
  static String customerIdLabel(int id) => 'معرف العميل: $id';
  static const String activeSubscription = 'اشتراك نشط';
  static String subscriptionType(String type) => 'النوع: $type';
  static String remaining(dynamic count) => 'المتبقي: $count';
  static String expires(String date) => 'ينتهي: $date';
  static const String selectAction = 'اختر الإجراء:';
  static const String noActiveSubFound = 'لم يتم العثور على اشتراك نشط.';
  static const String deduct1Session = 'خصم جلسة واحدة';
  static const String checkInOnly = 'تسجيل دخول فقط';
  static String customerScanned(String name, int id) => 'العميل: $name (المعرف: $id)';
  static String sessionDeducted(dynamic remaining) => 'تم خصم الجلسة بنجاح!\nالمتبقي: $remaining';
  static const String failedToDeductSession = 'فشل خصم الجلسة';
  static String checkedInSuccess(String name) => 'تم تسجيل دخول $name بنجاح!';
  static const String failedToCheckIn = 'فشل تسجيل الدخول';
  static const String positionQRInFrame = 'ضع رمز QR داخل الإطار';
  static const String codeScannedAutomatically = 'سيتم مسح الرمز تلقائياً';

  // ─── PROFILE SETTINGS ──────────────────────────────────────
  static const String profileSettings = 'الملف الشخصي والإعدادات';
  static const String user = 'المستخدم';
  static const String reception = 'الاستقبال';
  static String branchIdLabel(String id) => 'رقم الفرع: $id';

  // ─── HEALTH REPORT ─────────────────────────────────────────
  static const String healthReport = 'التقرير الصحي';
  static String yearsOld(String age) => '$age سنة';
  static const String customerQRCode = 'رمز QR العميل';
  static const String qrCopied = 'تم نسخ رمز QR إلى الحافظة';
  static const String copyQRCode = 'نسخ رمز QR';
  static const String scanQRForIdentification = 'امسح رمز QR هذا لتعريف العميل والوصول السريع';
  static const String physicalMeasurements = 'القياسات الجسدية';
  static const String bodyMassIndex = 'مؤشر كتلة الجسم (BMI)';
  static const String bmiScore = 'نتيجة BMI';
  static const String metabolicInfo = 'معلومات الأيض';
  static const String basalMetabolicRate = 'معدل الأيض الأساسي (BMR)';
  static const String caloriesBurnedAtRest = 'السعرات المحروقة في الراحة';
  static const String dailyCalorieNeeds = 'احتياجات السعرات اليومية';
  static const String forModerateActivity = 'للنشاط المعتدل';
  static const String recommendations = 'التوصيات';
  static const String healthTips = 'نصائح صحية';
  static String generatedOn(String date) => 'تم التوليد في $date';
  static const String underweight = 'نقص الوزن';
  static const String normal = 'طبيعي';
  static const String overweight = 'زيادة الوزن';
  static const String obese = 'سمنة';
  // Health tips
  static const String tipIncreaseCaloric = 'زيادة السعرات الحرارية بأطعمة غنية بالعناصر الغذائية';
  static const String tipStrengthTraining = 'التركيز على تمارين القوة';
  static const String tipConsultNutritionist = 'استشارة أخصائي تغذية لخطة وجبات';
  static const String tipMaintainHealthy = 'الحفاظ على العادات الصحية الحالية';
  static const String tipContinueExercise = 'الاستمرار في برنامج التمارين المنتظم';
  static const String tipBalancedDiet = 'تناول نظام غذائي متوازن ومتنوع';
  static const String tipCalorieDeficit = 'إنشاء عجز معتدل في السعرات الحرارية';
  static const String tipIncreaseCardio = 'زيادة تمارين القلب والأوعية الدموية';
  static const String tipPortionControl = 'التركيز على التحكم في الحصص';
  static const String tipConsultHealthcare = 'استشارة مقدم الرعاية الصحية';
  static const String tipLowImpact = 'البدء بتمارين منخفضة التأثير';
  static const String tipWorkWithDietitian = 'العمل مع أخصائي تغذية';
  static const String tipMaintainBalanced = 'الحفاظ على نظام غذائي متوازن';
  static const String tipExerciseRegularly = 'ممارسة الرياضة بانتظام';
  static const String tipStayHydrated = 'شرب كمية كافية من الماء';
  static const String shareWhatsAppSoon = 'مشاركة عبر واتساب قريباً...';
  static const String printSoon = 'الطباعة قريباً...';

  // ─── ACTIVATE SUBSCRIPTION DIALOG ──────────────────────────
  static const String coinsPackage = 'باقة العملات';
  static const String oneYearValidity = 'صلاحية سنة واحدة';
  static const String timeBasedPackage = 'باقة زمنية';
  static const String monthOptions = '1، 3، 6، 9، أو 12 شهر';
  static const String personalTraining = 'تدريب شخصي';
  static const String sessionsWithTrainer = 'جلسات مع المدرب';
  static const String month1 = 'شهر واحد';
  static const String months3 = '3 أشهر';
  static const String months6 = '6 أشهر';
  static const String months9 = '9 أشهر';
  static const String months12 = '12 شهر';
  static String coins(int n) => '$n عملة';
  static String sessions(int n) => '$n جلسة';
  static const String pleaseSelectSubType = 'يرجى اختيار نوع الاشتراك';
  static const String pleaseSelectCoins = 'يرجى اختيار عدد العملات';
  static const String pleaseSelectDuration = 'يرجى اختيار المدة';
  static const String pleaseSelectSessions = 'يرجى اختيار عدد الجلسات';
  static const String subscriptionActivated = 'تم تفعيل الاشتراك';
  static const String customerIdRequired = 'معرف العميل *';
  static const String subscriptionTypeRequired = 'نوع الاشتراك *';
  static const String chooseSubType = 'اختر نوع الاشتراك';
  static const String coinsAmountRequired = 'عدد العملات *';
  static const String validFor1Year = 'صالح لمدة سنة واحدة';
  static const String durationRequired = 'المدة *';
  static const String selectSubDuration = 'اختر مدة الاشتراك';
  static const String sessionsRequired = 'عدد الجلسات *';
  static const String sessionsWithPersonalTrainer = 'جلسات مع مدرب شخصي';
  static const String amountRequired = 'المبلغ *';
  static const String paymentMethodRequired = 'طريقة الدفع *';
  static const String cash = 'نقداً';
  static const String card = 'بطاقة';
  static const String transfer = 'تحويل';
  // CORS error (keep English technical terms)
  static const String corsErrorDetected = 'خطأ CORS';
  static const String corsDescription = 'أنت تستخدم متصفح الويب الذي يحظر الطلبات عبر المصادر (CORS).';
  static const String immediateSolution = '✅ الحل الفوري:';
  static const String closeThisApp = '1. أغلق هذا التطبيق';
  static const String runDebugBat = '2. انقر مرتين على: DEBUG_SUBSCRIPTION_ACTIVATION.bat';
  static const String selectOption1 = '3. اختر الخيار 1 (جهاز أندرويد)';
  static const String orOption2 = '   أو الخيار 2 (محاكي أندرويد)';
  static const String whyAndroid = '📱 لماذا أندرويد؟';
  static const String noCorsRestrictions = '• لا قيود CORS';
  static const String directBackendConnection = '• اتصال مباشر بالخادم';
  static const String allFeaturesWork = '• جميع الميزات تعمل فوراً';
  static const String technicalDetails = '💡 التفاصيل التقنية:';
  static const String corsExplanation = 'المتصفحات تحظر الطلبات من localhost إلى pythonanywhere.com لأسباب أمنية. تطبيقات أندرويد الأصلية ليس لديها هذا القيد.';
  static const String runOnAndroid = 'تشغيل على أندرويد';
  static const String activationFailed = 'فشل التفعيل';
  static const String details = 'التفاصيل:';
  static const String loginAgain = 'تسجيل الدخول مرة أخرى';

  // ─── REGISTER CUSTOMER DIALOG ──────────────────────────────
  static const String customerRegistered = 'تم تسجيل العميل بنجاح';
  static String customerIdCreated(int id) => 'معرف العميل: $id';
  static const String registrationFailed = 'فشل التسجيل';
  static const String failedToRegister = 'فشل تسجيل العميل';
  static const String unexpectedError = 'حدث خطأ غير متوقع';
  static const String registerNewCustomer = 'تسجيل عميل جديد';
  static const String male = 'ذكر';
  static const String female = 'أنثى';
  static const String genderRequired = 'الجنس *';
  static const String ageRequired = 'العمر *';
  static const String weightRequired = 'الوزن (كجم) *';
  static const String heightRequired = 'الطول (سم) *';
  static const String qrAndHealthAutoGenerated = 'سيتم توليد رمز QR والمؤشرات الصحية تلقائياً';

  // ─── RECORD PAYMENT DIALOG ─────────────────────────────────
  static const String paymentRecorded = 'تم تسجيل الدفعة';
  static const String failedToRecordPayment = 'فشل تسجيل الدفعة';
  static const String notes = 'ملاحظات';
  static const String record = 'تسجيل';

  // ─── RENEW SUBSCRIPTION DIALOG ─────────────────────────────
  static const String subscriptionRenewed = 'تم تجديد الاشتراك بنجاح';
  static const String failedToRenew = 'فشل تجديد الاشتراك';
  static const String subscriptionIdRequired = 'رقم الاشتراك *';
  static const String invalidAmount = 'مبلغ غير صالح';
  static const String renew = 'تجديد';

  // ─── FREEZE SUBSCRIPTION DIALOG ────────────────────────────
  static const String subscriptionFrozen = 'تم تجميد الاشتراك بنجاح';
  static const String failedToFreeze = 'فشل تجميد الاشتراك';
  static const String freezeDescription = 'إيقاف الاشتراك مؤقتاً بدون خسارة الأيام المتبقية';
  static const String freezeDaysRequired = 'أيام التجميد *';
  static const String numberOfDaysToFreeze = 'عدد أيام التجميد';
  static const String atLeast1Day = 'يجب أن يكون يوم واحد على الأقل';
  static const String freeze = 'تجميد';

  // ─── STOP SUBSCRIPTION DIALOG ──────────────────────────────
  static const String confirmStop = 'تأكيد الإيقاف';
  static const String stopConfirmMessage = 'هل أنت متأكد من إيقاف هذا الاشتراك؟ لا يمكن التراجع عن هذا الإجراء وسيتم إلغاء الوصول فوراً.';
  static const String stop = 'إيقاف';
  static const String subscriptionStopped = 'تم إيقاف الاشتراك بنجاح';
  static const String failedToStop = 'فشل إيقاف الاشتراك';
  static const String willDeactivateAccess = 'سيتم إلغاء وصول العميل فوراً';

  // ─── SUBMIT COMPLAINT DIALOG ───────────────────────────────
  static const String complaintSubmitted = 'تم تقديم الشكوى';
  static const String failedToSubmitComplaint = 'فشل تقديم الشكوى';
  static const String customerIdOptional = 'معرف العميل (اختياري)';
  static const String titleRequired = 'العنوان *';
  static const String descriptionRequired = 'الوصف *';

  // ─── CUSTOMER QR CODE WIDGET ───────────────────────────────
  static const String customerQRCodeTitle = 'رمز QR العميل';
  static String customerIdBadge(int id) => 'معرف العميل: $id';
  static const String scanQRAtEntrance = 'امسح رمز QR هذا عند المدخل لتسجيل الدخول';

  // ─── BRANCH MANAGER DASHBOARD ──────────────────────────────
  static const String branchManagerTitle = 'مدير الفرع';
  static const String performanceOverview = 'نظرة عامة على الأداء';
  static const String todaysRevenue = 'إيرادات اليوم';
  static const String activeMembers = 'الأعضاء النشطون';
  static String expiringSoon(int count) => 'ينتهي قريباً ($count)';
  static const String pendingIssues = 'مشكلات معلقة';
  static const String noStaffFound = 'لا يوجد موظفون';

  // ─── BRANCH MANAGER SETTINGS ───────────────────────────────
  static const String manager = 'المدير';
  static const String branchManagerRole = 'مدير فرع';

  // ─── ACCOUNTANT DASHBOARD ──────────────────────────────────
  static const String accountantDashboard = 'لوحة تحكم المحاسب';
  static const String loadingFinancialData = 'جاري تحميل البيانات المالية...';
  static const String sales = 'المبيعات';
  static const String expenses = 'المصروفات';
  static const String reports = 'التقارير';
  static const String todaysSummary = 'ملخص اليوم';
  static const String todaysSales = 'مبيعات اليوم';
  static const String paymentBreakdown = 'تفاصيل المدفوعات';
  static const String networkCard = 'بطاقة/شبكة';
  static const String thisMonth = 'هذا الشهر';
  static String itemsCount(int n) => '$n عنصر';
  static const String alerts = 'التنبيهات';
  static const String monthOverMonth = 'مقارنة شهرية';
  static const String salesAndTransactions = 'المبيعات والعمليات';
  static String transactionsToday(int n) => '$n عملية اليوم';
  static const String fullLedger = 'السجل الكامل';
  static const String total = 'الإجمالي';
  static const String noTransactionsToday = 'لا توجد عمليات اليوم';
  static const String viewTransactionHistory = 'عرض سجل العمليات';
  static const String noExpensesFound = 'لا توجد مصروفات';
  static const String noBranchData = 'لا توجد بيانات فروع';
  static const String subscriptions = 'الاشتراكات';
  static const String financialReports = 'التقارير المالية';
  static const String revenueBreakdown = 'تفاصيل الإيرادات';
  static const String weeklyReport = 'التقرير الأسبوعي';
  static const String monthlyReport = 'التقرير الشهري';
  static const String cashDifferences = 'فروقات النقد';
  static const String noReportData = 'لا توجد بيانات تقارير';
  static const String tryAdjustingDateRange = 'حاول تعديل نطاق التاريخ';
  static const String byBranch = 'حسب الفرع';
  static const String byService = 'حسب الخدمة';
  static const String byPaymentMethod = 'حسب طريقة الدفع';
  static const String weeklyRevenue = 'الإيرادات الأسبوعية';
  static const String weeklyExpenses = 'المصروفات الأسبوعية';
  static const String dailyBreakdown = 'التفاصيل اليومية';
  static const String monthlyRevenue = 'الإيرادات الشهرية';
  static const String monthlyExpenses = 'المصروفات الشهرية';
  static const String dailyAverageRevenue = 'متوسط الإيرادات اليومية';
  static const String totalCashDifference = 'إجمالي فروقات النقد';

  // ─── ACCOUNTANT SETTINGS ───────────────────────────────────
  static const String accountant = 'المحاسب';
  static const String accountantRole = 'محاسب';
  static const String aboutDescriptionReception = 'نظام شامل لإدارة الأندية الرياضية لموظفي الاستقبال ومديري الفروع والمالكين.';

  // ─── TRANSACTION LEDGER ────────────────────────────────────
  static const String transactionLedger = 'سجل العمليات';
  static const String changeDate = 'تغيير التاريخ';
  static String transactionsCountLabel(int n) => '$n عملية';
  static const String searchByCustomer = 'البحث بالاسم أو المعرف...';
  static String paymentFilter(String method) => 'الدفع: $method';
  static const String loadingTransactions = 'جاري تحميل العمليات...';
  static const String noTransactionsForDate = 'لا توجد عمليات لهذا التاريخ';
  static const String pickAnotherDate = 'اختر تاريخاً آخر';
  static const String walkIn = 'زائر';
  static String transactionNumber(int id) => 'عملية #$id';
  static const String grossAmount = 'المبلغ الإجمالي';
  static const String discount = 'الخصم';
  static const String netAmount = 'المبلغ الصافي';
  static const String payment = 'الدفع';
  static const String time = 'الوقت';
  static const String filterTransactions = 'تصفية العمليات';
  static const String paymentMethod = 'طريقة الدفع';
  static const String allMethods = 'جميع الطرق';

  // ─── MANAGER SETTINGS ──────────────────────────────────────
  static const String managerRole = 'مدير';

  // ─── CLIENT/WELCOME SCREEN ─────────────────────────────────
  static const String pleaseEnterCredentials = 'يرجى إدخال الهاتف/البريد وكلمة المرور';
  static const String loginSuccessful = 'تم تسجيل الدخول بنجاح!';
  static const String gymMemberPortal = 'بوابة أعضاء النادي';
  static const String loginToAccess = 'سجل الدخول للوصول إلى عضويتك';
  static const String phoneOrEmail = 'رقم الهاتف أو البريد الإلكتروني';
  static const String enterPhoneOrEmail = 'أدخل هاتفك أو بريدك';
  static const String credentialsFromReception = 'استخدم البيانات المقدمة من الاستقبال';
  static const String firstTimeHint = 'المستخدمون الجدد: استخدم كلمة المرور المؤقتة من الاستقبال';
  static const String firstTime = 'أول مرة؟';
  static const String newMember = 'عضو جديد؟';
  static const String visitReception = 'يرجى زيارة استقبال النادي للحصول على بيانات الدخول';

  // ─── CLIENT HOME ───────────────────────────────────────────
  static const String guest = 'ضيف';
  static const String subExpiringSoon = 'الاشتراك ينتهي قريباً';
  static String subExpiresInDays(int days) => 'ينتهي اشتراكك خلال $days يوم';
  static const String subExpired = 'انتهى الاشتراك';
  static const String pleaseRenew = 'يرجى تجديد اشتراكك';
  static const String subFrozen = 'الاشتراك مجمد';
  static const String subCurrentlyFrozen = 'اشتراكك مجمد حالياً';
  static const String lowCoinBalance = 'رصيد عملات منخفض';
  static const String fewSessionsLeft = 'جلسات قليلة متبقية';
  static String onlyCoinsRemaining(dynamic n) => '$n عملة متبقية فقط';
  static String onlySessionsRemaining(dynamic n) => '$n جلسة متبقية فقط';
  static const String subscription = 'الاشتراك';
  static const String type = 'النوع';
  static const String expiresLabel = 'ينتهي';
  static const String myQRCode = 'رمز QR الخاص بي';
  static const String entryHistory = 'سجل الدخول';
  static const String coinBased = 'عملات';
  static const String timeBased = 'زمني';
  static const String sessionBased = 'جلسات';
  static const String personalTrainingType = 'تدريب شخصي';
  static const String remainingLabel = 'المتبقي';
  static const String timeLeft = 'الوقت المتبقي';
  static const String sessionsLabel = 'الجلسات';
  static const String training = 'التدريب';

  // ─── CLIENT MAIN SCREEN ────────────────────────────────────
  static const String qr = 'QR';
  static const String plan = 'الخطة';
  static const String history = 'السجل';

  // ─── CLIENT MEMBER-APP REDESIGN ────────────────────────────
  static const String checkInNav = 'الدخول';
  static const String quickCheckIn = 'دخول سريع';
  static const String showQrAtDoor = 'اعرض رمز QR عند الباب';
  static const String untilRenewal = 'متبقٍ حتى التجديد';
  static const String manageSubscription = 'إدارة الاشتراك';
  static const String dayUnit = 'يوم';
  static const String coinUnit = 'عملة';
  static const String sessionUnit = 'جلسة';
  static const String entryCode = 'رمز الدخول';
  static const String pointCodeAtScanner = 'وجّه الرمز نحو الماسح الضوئي عند مدخل النادي.';
  static const String signUp = 'إنشاء حساب';
  static const String yourGymInPocket = 'ناديك في جيبك — اشترك، ادخل، وتابع تقدمك.';
  static const String recentVisits = 'آخر زياراتك للنادي';

  // ─── CLIENT OVERVIEW TAB ───────────────────────────────────
  static const String subEndpointNotAvailable = 'نقطة نهاية الاشتراك غير متاحة.';
  static String expiresInDays(int days) => 'ينتهي خلال $days يوم';
  static const String expired = 'منتهي';
  static const String remainingCoins = 'العملات المتبقية';
  static const String timeRemaining = 'الوقت المتبقي';
  static const String trainingSessions = 'جلسات التدريب';
  static const String sessionsLeft = 'الجلسات المتبقية';
  static const String daysLeft = 'الأيام المتبقية';
  static const String membership = 'العضوية';
  static String coinsBalance(dynamic n) => 'رصيد العملات: $n';
  static String sessionRemaining(dynamic n) => '$n جلسة متبقية';

  // ─── SUBSCRIPTION SCREEN ───────────────────────────────────
  static const String subscriptionDetails = 'تفاصيل الاشتراك';
  static const String subscriptionInformation = 'معلومات الاشتراك';
  static const String planLabel = 'الخطة';
  static const String startDate = 'تاريخ البدء';
  static const String expiryDate = 'تاريخ الانتهاء';
  static const String allowedServices = 'الخدمات المسموحة';
  static const String freezeHistory = 'سجل التجميد';
  static String frozenDate(String date) => 'مجمد: $date';
  static String unfrozenDate(String date) => 'إلغاء التجميد: $date';
  static String reason(String r) => 'السبب: $r';
  static const String noSubscriptionData = 'لا توجد بيانات اشتراك';
  static String progressLabel(dynamic current, dynamic total) => '$current / $total متبقي';
  static const String remainingCoinsLabel = 'العملات المتبقية';
  static const String timeRemainingLabel = 'الوقت المتبقي';
  static const String sessionsRemainingLabel = 'الجلسات المتبقية';
  static const String trainingSessionsLabel = 'جلسات التدريب';

  // ─── QR SCREEN ─────────────────────────────────────────────
  static const String qrRefreshed = 'تم تحديث رمز QR بنجاح';
  static String failedToRefresh(String e) => 'فشل التحديث: $e';
  static const String myQRCodeTitle = 'رمز QR الخاص بي';
  static const String qrNoActiveSub = 'رمز QR صالح، لكن ليس لديك اشتراك نشط. يرجى تفعيل اشتراك لاستخدام خدمات النادي.';
  static const String scannableYes = 'قابل للمسح: نعم';
  static const String scannableExpired = 'قابل للمسح: منتهي';
  static const String qrCodeExpired = 'رمز QR منتهي الصلاحية';
  static String expiresIn(String time) => 'ينتهي خلال: $time';
  static const String refreshQRCode = 'تحديث رمز QR';
  static const String howToUse = 'كيفية الاستخدام';
  static const String qrInstructions = '• أظهر رمز QR هذا عند مدخل النادي\n• رمز QR صالح لمدة ساعة واحدة\n• حدّث إذا انتهت صلاحيته\n• أبقِ شاشة الهاتف مضيئة للمسح';
  static const String activeSubscriptionStatus = 'اشتراك نشط';
  static const String subscriptionFrozenStatus = 'اشتراك مجمد';
  static const String subscriptionStoppedStatus = 'اشتراك متوقف';
  static const String inactiveStatus = 'غير نشط';

  // ─── ENTRY HISTORY SCREEN ──────────────────────────────────
  static const String entryHistoryNotAvailable = 'ميزة سجل الدخول غير متاحة حالياً.\n\nيرجى المحاولة لاحقاً أو التواصل مع الدعم.';
  static const String entryHistoryTitle = 'سجل الدخول';
  static const String noEntryHistory = 'لا يوجد سجل دخول بعد';
  static const String visitsAppearHere = 'ستظهر زياراتك للنادي هنا';
  static const String approvedEntry = 'مقبول';
  static const String deniedEntry = 'مرفوض';

  // ─── CLIENT SETTINGS ───────────────────────────────────────
  static const String profileInformation = 'معلومات الملف الشخصي';
  static const String viewEditProfile = 'عرض وتعديل ملفك الشخصي';
  static const String profileEditingSoon = 'تعديل الملف الشخصي قريباً';
  static const String contactInformationSetting = 'معلومات الاتصال';
  static const String manageContactDetails = 'إدارة تفاصيل الاتصال';
  static const String contactEditingSoon = 'تعديل الاتصال قريباً';
  static const String preferences = 'التفضيلات';
  static const String notifications = 'الإشعارات';
  static const String manageNotifications = 'إدارة إعدادات الإشعارات';
  static const String notificationsSoon = 'إعدادات الإشعارات قريباً';
  static const String notificationsEnabled = 'الإشعارات مفعّلة';
  static const String notificationsDisabled = 'الإشعارات معطّلة';
  static const String enableNotifications = 'تفعيل الإشعارات';
  static const String receiveNotificationsDesc = 'استقبال إشعارات الاشتراكات والدخول والتنبيهات';
  static const String notificationsActivated = 'تم تفعيل الإشعارات';
  static const String notificationsDeactivated = 'تم تعطيل الإشعارات';
  static const String darkMode = 'الوضع الداكن';
  static const String themeSelectionSoon = 'اختيار السمة قريباً';
  static const String support = 'الدعم';
  static const String getHelpSupport = 'الحصول على المساعدة والدعم';
  static const String about = 'حول';
  static const String appVersionInfo = 'إصدار التطبيق والمعلومات';
  static const String gymClient = 'عميل النادي';
  static const String modernGymApp = 'تطبيق حديث لإدارة عضوية النادي الرياضي.';
  static const String privacyPolicy = 'سياسة الخصوصية';
  static const String readPrivacyPolicy = 'قراءة سياسة الخصوصية';
  static const String privacyPolicySoon = 'سياسة الخصوصية قريباً';
  static const String deleteAccount = 'حذف الحساب';
  static const String deleteAccountAfter90Days = 'سيتم حذف الحساب بعد 90 يوماً';
  static const String deleteAccountWarning = 'يمكنك طلب حذف حسابك الآن، وسيتم حذفه نهائياً بعد 90 يوماً.';
  static const String deleteAccountConfirmQuestion = 'هل تريد إرسال طلب حذف الحساب؟';
  static const String deleteAccountRequested = 'تم إرسال طلب حذف الحساب. سيتم حذف حسابك خلال 90 يوماً.';
  static const String deleteAccountRequestFailed = 'فشل إرسال طلب حذف الحساب.';
  static const String requestDeletion = 'طلب الحذف';
  static const String signOutTestingOnly = 'تسجيل الخروج (للاختبار فقط)';
  static const String signOutQuestion = 'تسجيل الخروج من حسابك؟';

  // ─── CHANGE PASSWORD SCREEN ────────────────────────────────
  static const String fillAllFields = 'يرجى ملء جميع الحقول';
  static const String newPasswordMin6 = 'كلمة المرور الجديدة يجب أن تكون 6 أحرف على الأقل';
  static const String passwordsDoNotMatch = 'كلمات المرور الجديدة غير متطابقة';
  static const String newPasswordMustDiffer = 'كلمة المرور الجديدة يجب أن تختلف عن الحالية';
  static const String passwordChangedSuccess = 'تم تغيير كلمة المرور بنجاح!';
  static const String setNewPassword = 'تعيين كلمة مرور جديدة';
  static const String changeTempPassword = 'يرجى تغيير كلمة المرور المؤقتة قبل المتابعة';
  static const String temporaryPasswordLabel = 'كلمة المرور المؤقتة';
  static const String min6Characters = '6 أحرف كحد أدنى';

  // ─── ACTIVATION SCREEN ─────────────────────────────────────
  static const String pleaseEnterAllDigits = 'يرجى إدخال جميع الأرقام الـ 6';
  static const String activationCodeResent = 'تم إعادة إرسال رمز التفعيل!';
  static const String activateAccount = 'تفعيل الحساب';
  static const String enterActivationCode = 'أدخل رمز التفعيل';
  static String codeSentTo(String id) => 'أرسلنا رمزاً مكوناً من 6 أرقام إلى\n$id';
  static const String verify = 'تحقق';
  static const String didntReceiveCode = 'لم تستلم الرمز؟ إعادة إرسال';
  static const String codeExpires10Min = 'ينتهي الرمز خلال 10 دقائق';

  // ─── BIOMETRIC SETTINGS ────────────────────────────────────
  static const String security = 'الأمان';
  static const String biometricLogin = 'تسجيل الدخول بالبصمة';
  static const String useBiometricToLogin = 'استخدم البصمة أو الوجه لتسجيل الدخول';
  static const String quicklyLoginWithBiometric = 'تسجيل دخول سريع بالبصمة أو الوجه';
  static const String setupBiometricLogin = 'إعداد تسجيل الدخول بالبصمة';
  static const String fingerprint = 'بصمة الإصبع';
  static const String faceId = 'بصمة الوجه';
  static const String biometric = 'البصمة';
  static const String deviceSupportsBoth = 'جهازك يدعم بصمة الإصبع وبصمة الوجه. اضغط متابعة للتحقق.';
  static const String deviceSupportsFingerprint = 'جهازك يدعم بصمة الإصبع. اضغط متابعة للتحقق.';
  static const String deviceSupportsFaceId = 'جهازك يدعم بصمة الوجه. اضغط متابعة للتحقق.';
  static const String deviceSupportsBiometric = 'جهازك يدعم المصادقة البيومترية. اضغط متابعة للتحقق.';
  static const String verifyBiometricToEnable = 'تحقق من بصمتك لتفعيل تسجيل الدخول السريع';
  static const String biometricVerificationFailed = 'فشل التحقق من البصمة. يرجى المحاولة مرة أخرى.';
  static const String biometricVerified = 'تم التحقق من البصمة!';
  static const String enterPasswordToComplete = 'أدخل كلمة المرور لإكمال الإعداد. سيتم تخزين بياناتك بشكل آمن على هذا الجهاز.';
  static const String enable = 'تفعيل';
  static const String biometricEnabled = 'تم تفعيل تسجيل الدخول بالبصمة بنجاح!';
  static const String disableBiometricLogin = 'تعطيل تسجيل الدخول بالبصمة';
  static const String disableBiometricConfirm = 'هل أنت متأكد من تعطيل تسجيل الدخول بالبصمة؟ ستحتاج إلى إدخال كلمة المرور لتسجيل الدخول.';
  static const String disable = 'تعطيل';
  static const String biometricDisabled = 'تم تعطيل تسجيل الدخول بالبصمة';

  // ─── ERROR DISPLAY ─────────────────────────────────────────
  static const String errorTitle = 'خطأ';

  // ─── DATE RANGE PICKER ─────────────────────────────────────
  static const String selectDateRange = 'اختيار نطاق التاريخ';
  static const String startDateLabel = 'تاريخ البدء';
  static const String endDateLabel = 'تاريخ الانتهاء';

  // ─── SUPER ADMIN DASHBOARD ─────────────────────────────────
  static const String platformAdmin = 'مدير المنصة';
  static const String loadingPlatformData = 'جاري تحميل بيانات المنصة...';
  static const String owners = 'المالكون';
  static const String newOwner = 'مالك جديد';
  static const String platformAdministration = 'إدارة المنصة';
  static const String createManageOwners = 'إنشاء وإدارة حسابات مالكي الأندية';
  static const String platformOverview = 'نظرة عامة على المنصة';
  static const String totalOwners = 'إجمالي المالكين';
  static const String activeOwners = 'المالكون النشطون';
  static const String recentOwners = 'المالكون الأخيرون';
  static const String noOwnersYet = 'لا يوجد مالكون بعد';
  static const String createFirstOwner = 'أنشئ أول حساب مالك نادي للبدء';
  static const String noOwnersYetTab = 'لا يوجد مالكون بعد';
  static const String tapPlusToCreate = 'اضغط + لإنشاء أول مالك نادي';
  static String lastLogin(String time) => 'آخر دخول: $time';
  static String minutesAgo(int n) => 'منذ $n دقيقة';
  static String hoursAgo(int n) => 'منذ $n ساعة';
  static String daysAgo(int n) => 'منذ $n يوم';

  // ─── SUPER ADMIN SETTINGS ──────────────────────────────────
  static const String superAdmin = 'المدير العام';
  static const String platformAdministrator = 'مدير المنصة';
  static const String appVersion = 'إصدار التطبيق';
  static const String platform = 'المنصة';
  static const String multiGymSaas = 'نظام إدارة الأندية المتعددة';

  // ─── CREATE GYM SCREEN ─────────────────────────────────────
  static const String createGymOwner = 'إنشاء مالك نادي';
  static const String ownerAccount = 'حساب المالك';
  static const String ownerAccountDescription = 'أنشئ حساب دخول لمالك النادي. سيقوم بتسجيل الدخول وإعداد اسم النادي والشعار والعلامة التجارية والفروع والموظفين بنفسه.';
  static const String ownerDetails = 'تفاصيل المالك';
  static const String fullNameLabel = 'الاسم الكامل';
  static const String fullNameHintOwner = 'مثال: أحمد حسن';
  static const String fullNameIsRequired = 'الاسم الكامل مطلوب';
  static const String usernameLabel = 'اسم المستخدم';
  static const String usernameHintOwner = 'مثال: ahmed_gym';
  static const String usernameIsRequired = 'اسم المستخدم مطلوب';
  static const String usernameTooShort = 'اسم المستخدم يجب أن يكون 3 أحرف على الأقل';
  static const String usernameNoSpaces = 'اسم المستخدم لا يمكن أن يحتوي على مسافات';
  static const String passwordLabel = 'كلمة المرور';
  static const String createPasswordHint = 'أنشئ كلمة مرور للمالك';
  static const String passwordIsRequired = 'كلمة المرور مطلوبة';
  static const String passwordTooShort = 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
  static const String emailOptional = 'البريد الإلكتروني (اختياري)';
  static const String emailHint = 'مثال: owner@email.com';
  static const String phoneOptionalLabel = 'الهاتف (اختياري)';
  static const String phoneHint = 'مثال: 01012345678';
  static const String ownerCreated = 'تم إنشاء المالك بنجاح';
  static const String failedToCreateOwner = 'فشل إنشاء المالك';
  static const String createOwnerAccount = 'إنشاء حساب المالك';

  // ─── GYM DETAIL SCREEN ─────────────────────────────────────
  static const String statistics = 'الإحصائيات';
  static const String ownerInformation = 'معلومات المالك';
  static const String name = 'الاسم';
  static const String notAssigned = 'غير معيّن';
  static const String branding = 'العلامة التجارية';
  static const String emailDomain = 'نطاق البريد';
  static const String setupComplete = 'اكتمل الإعداد';
  static const String setupPending = 'قيد الإعداد';
  static const String created = 'تاريخ الإنشاء';

  // ─── HELPERS (getRelativeTime, validators, BMI) ────────────
  static String yearsAgo(int n) => 'منذ $n سنة';
  static String monthsAgo(int n) => 'منذ $n شهر';
  static const String justNow = 'الآن';
  static String fieldRequired(String name) => '$name مطلوب';
  static const String emailIsRequired = 'البريد الإلكتروني مطلوب';
  static const String invalidEmailFormat = 'تنسيق البريد الإلكتروني غير صالح';
  static const String phoneIsRequired = 'رقم الهاتف مطلوب';
  static const String invalidPhoneFormat = 'تنسيق رقم الهاتف غير صالح';
}
