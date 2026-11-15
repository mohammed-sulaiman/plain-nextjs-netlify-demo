// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'شجرة العائلة';

  @override
  String get aboutText =>
      'ابنِ شجرة عائلتك واستكشفها وشاركها. يعمل دون اتصال، وسجّل الدخول للمزامنة بين أجهزتك.';

  @override
  String get account => 'الحساب';

  @override
  String get add => 'إضافة';

  @override
  String get addBrother => 'أخ';

  @override
  String get addSister => 'أخت';

  @override
  String get addFather => 'أب';

  @override
  String get addMother => 'أم';

  @override
  String get addSon => 'ابن';

  @override
  String get addDaughter => 'ابنة';

  @override
  String get addHusband => 'زوج';

  @override
  String get addWife => 'زوجة';

  @override
  String get addFirstPerson => 'أضف أول شخص';

  @override
  String get addPerson => 'إضافة شخص';

  @override
  String get addRelative => 'إضافة قريب';

  @override
  String get addResidence => 'إضافة مكان إقامة';

  @override
  String get editResidence => 'تعديل مكان الإقامة';

  @override
  String get ancestorGenerations => 'أجيال الأجداد';

  @override
  String get descendantGenerations => 'أجيال الأحفاد';

  @override
  String get basicInfo => 'المعلومات الأساسية';

  @override
  String get calendar => 'التقويم';

  @override
  String get calendarBoth => 'الميلادي والهجري معاً';

  @override
  String get calendarGregorian => 'الميلادي';

  @override
  String get calendarHijri => 'الهجري';

  @override
  String get cancel => 'إلغاء';

  @override
  String get cardContents => 'ما يظهر في بطاقة كل شخص';

  @override
  String get checkEmail => 'تحقق من بريدك الإلكتروني للمتابعة.';

  @override
  String get children => 'الأبناء';

  @override
  String get chooseOtherParent => 'من هو الوالد الآخر؟';

  @override
  String get choosePerson => 'اختر شخصاً';

  @override
  String get choosePhoto => 'اختيار صورة';

  @override
  String get takePhoto => 'الكاميرا';

  @override
  String get removePhoto => 'إزالة';

  @override
  String get clear => 'مسح';

  @override
  String get cloudNotConfigured => 'المزامنة السحابية غير مفعّلة';

  @override
  String get cloudNotConfiguredHint =>
      'ابنِ التطبيق مع SUPABASE_URL و SUPABASE_ANON_KEY لتفعيل تسجيل الدخول. شجرتك محفوظة على هذا الجهاز.';

  @override
  String get cloudSynced => 'محفوظة أونلاين';

  @override
  String get localOnly => 'محفوظة على هذا الجهاز';

  @override
  String get confirm => 'تأكيد';

  @override
  String get continueWithGoogle => 'المتابعة بحساب Google';

  @override
  String get copied => 'تم النسخ';

  @override
  String get createAccount => 'إنشاء حساب';

  @override
  String get deceased => 'متوفى';

  @override
  String get deletePerson => 'حذف الشخص';

  @override
  String get displayOptions => 'خيارات العرض';

  @override
  String get done => 'تم';

  @override
  String get edit => 'تعديل';

  @override
  String get editMarriage => 'تفاصيل الزواج';

  @override
  String get editPerson => 'تعديل الشخص';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get emptyTitle => 'ابدأ شجرة عائلتك';

  @override
  String get emptyBody =>
      'أضف نفسك أو أحد الأجداد، ثم أضف الوالدين والأزواج والأبناء حوله.';

  @override
  String get endDate => 'تاريخ الانتهاء';

  @override
  String get evBorn => 'الولادة';

  @override
  String get evDied => 'الوفاة';

  @override
  String get exportGedcom => 'تصدير GEDCOM';

  @override
  String get importGedcom => 'استيراد GEDCOM';

  @override
  String get exportImage => 'تصدير الشجرة كصورة';

  @override
  String get exportPdf => 'تصدير أو طباعة PDF';

  @override
  String get faceConsent => 'السماح بمقارنة ملامح الوجه';

  @override
  String get faceConsentHint =>
      'مطلوب قبل مقارنة هذه الصورة. احصل على موافقة الشخص أو وليّه.';

  @override
  String get faceFailed => 'فشلت المقارنة';

  @override
  String get faceNoConsent =>
      'لا توجد صورة لهذا الشخص أو لم يوافق على مقارنة الوجه. عدّل بيانات الشخص لتفعيلها.';

  @override
  String get faceNoFace => 'تعذّر اكتشاف وجه في الصورة.';

  @override
  String get faceNotConfigured =>
      'تحتاج مقارنة الوجوه إلى الخدمة السحابية. فعّل Supabase أولاً.';

  @override
  String get faceNotSignedIn => 'سجّل الدخول لاستخدام مقارنة الوجوه.';

  @override
  String get facePrivacy =>
      'تُرسل الصور بشكل آمن إلى خدمة المقارنة فقط عند الضغط على الزر، ولا تحتفظ بها الخدمة، ولا يُقارن إلا من وافق على ذلك.';

  @override
  String get faceSimilarity => 'تشابه الملامح';

  @override
  String get findLookalikes => 'من الأكثر شبهاً؟';

  @override
  String get familyMap => 'خريطة العائلة';

  @override
  String get familyName => 'اسم العائلة';

  @override
  String get givenName => 'الاسم';

  @override
  String get female => 'أنثى';

  @override
  String get male => 'ذكر';

  @override
  String get unknownGender => 'غير محدد';

  @override
  String get gender => 'الجنس';

  @override
  String get fieldAge => 'العمر';

  @override
  String get fieldBirthDate => 'تاريخ الميلاد';

  @override
  String get fieldBirthPlace => 'مكان الميلاد';

  @override
  String get fieldDeathDate => 'تاريخ الوفاة';

  @override
  String get fieldKunya => 'الكنية';

  @override
  String get fieldLineage => 'النسب';

  @override
  String get fieldPhoto => 'الصورة';

  @override
  String get fieldResidence => 'مكان الإقامة';

  @override
  String get fieldTribe => 'القبيلة / العشيرة';

  @override
  String get kunyaHint => 'مثل: أبو محمد';

  @override
  String get nickname => 'اللقب';

  @override
  String get firstPerson => 'الشخص الأول';

  @override
  String get secondPerson => 'الشخص الثاني';

  @override
  String get focusLabel => 'المحور';

  @override
  String get forgotPassword => 'نسيت كلمة المرور؟';

  @override
  String get fromDate => 'من';

  @override
  String get toDate => 'إلى';

  @override
  String get geneticRelatedness => 'نسبة القرابة الجينية (من الشجرة)';

  @override
  String get geneticRelatednessHint =>
      'النسبة المتوقعة من الحمض النووي الموروث من الأجداد المشتركين، محسوبة من روابط النسب فقط. الإخوة ≈ 50%، أبناء العم ≈ 12.5%.';

  @override
  String get haveAccount => 'لدي حساب بالفعل';

  @override
  String get noAccount => 'إنشاء حساب جديد';

  @override
  String get importEmpty => 'لم يُعثر على أشخاص في الملف.';

  @override
  String get importMerge => 'دمج';

  @override
  String get importReplace => 'استبدال';

  @override
  String get importTitle => 'استيراد GEDCOM';

  @override
  String get invalidEmail => 'أدخل بريداً إلكترونياً صحيحاً';

  @override
  String get kindAdoptive => 'بالكفالة / التبني';

  @override
  String get kindBiological => 'نسب';

  @override
  String get kindMilk => 'من الرضاعة';

  @override
  String get language => 'اللغة';

  @override
  String get lifeEvents => 'أحداث الحياة';

  @override
  String get lineageSon => 'بن';

  @override
  String get lineageDaughter => 'بنت';

  @override
  String get linkExistingChild => 'ربط ابن موجود';

  @override
  String get linkExistingParent => 'ربط والد موجود';

  @override
  String get linkExistingSpouse => 'ربط زوج موجود';

  @override
  String get linkType => 'نوع الصلة';

  @override
  String get loadSample => 'تحميل عائلة تجريبية';

  @override
  String get mahramStatus => 'حكم المحرمية';

  @override
  String get mahramBlood => 'محرم بالنسب';

  @override
  String get mahramMilk => 'محرم بالرضاعة';

  @override
  String get mahramMarriage => 'محرم بالمصاهرة';

  @override
  String get mahramConsummation => 'يثبت ذلك فقط إن تم الدخول بالزوجة/الأم.';

  @override
  String get mahramDisclaimer =>
      'محسوب فقط من الصلات المسجلة في الشجرة. للاسترشاد فقط، ويُرجع إلى أهل العلم في الأحكام.';

  @override
  String get mahramFormerSpouse => 'زوج سابق: ليس محرماً';

  @override
  String get mahramSameGender => 'من نفس الجنس: لا ينطبق';

  @override
  String get mahramSpouse => 'زوجان';

  @override
  String get mahramUnknownGender => 'حدّد جنس الشخصين للحساب';

  @override
  String get notMahram => 'ليس محرماً';

  @override
  String get marriageDate => 'تاريخ الزواج';

  @override
  String get needParentsForSibling =>
      'أضف أحد الوالدين أولاً، ثم أضف الإخوة كأبناء له.';

  @override
  String get noEvents => 'لا توجد أحداث مؤرخة بعد.';

  @override
  String get noMapData =>
      'لا توجد أماكن إقامة محددة على الخريطة بعد. عدّل شخصاً وأضف مكان إقامة وحدّده على الخريطة.';

  @override
  String get noResidences => 'لا توجد أماكن إقامة مسجلة.';

  @override
  String get noResults => 'لا توجد نتائج';

  @override
  String get none => 'لا يوجد';

  @override
  String get notFound => 'الشخص غير موجود';

  @override
  String get notNow => 'ليس الآن';

  @override
  String get notSet => 'غير محدد';

  @override
  String get notes => 'ملاحظات';

  @override
  String get openSettings => 'فتح الإعدادات';

  @override
  String get parents => 'الوالدان';

  @override
  String get password => 'كلمة المرور';

  @override
  String get passwordTooShort => '8 أحرف على الأقل';

  @override
  String get pickOnMap => 'تحديد على الخريطة';

  @override
  String get pickTwoPeople => 'اختر شخصين لمعرفة صلة القرابة بينهما.';

  @override
  String get placeName => 'المكان';

  @override
  String get present => 'الآن';

  @override
  String get recenter => 'العودة إلى المحور';

  @override
  String get zoomIn => 'تكبير';

  @override
  String get zoomOut => 'تصغير';

  @override
  String get relationship => 'صلة القرابة';

  @override
  String get relationshipCalculator => 'حاسبة القرابة';

  @override
  String get required => 'مطلوب';

  @override
  String get residences => 'أماكن الإقامة';

  @override
  String get save => 'حفظ';

  @override
  String get saveFailed => 'تعذّر الحفظ';

  @override
  String get search => 'البحث عن شخص';

  @override
  String get searchFailed => 'فشل البحث. تحقق من الاتصال.';

  @override
  String get searchHint => 'الاسم أو النسب أو الكنية أو القبيلة';

  @override
  String get searchPlace => 'ابحث عن مدينة أو مكان';

  @override
  String get setAsFocus => 'جعله محور الشجرة';

  @override
  String get settings => 'الإعدادات';

  @override
  String get showOnMap => 'الخريطة';

  @override
  String get showSiblings => 'إظهار الإخوة';

  @override
  String get showSpouses => 'إظهار الأزواج';

  @override
  String get showUnclesAunts => 'إظهار الأعمام والأخوال';

  @override
  String get siblings => 'الإخوة';

  @override
  String get signIn => 'تسجيل الدخول';

  @override
  String get signInHint =>
      'سجّل الدخول لحفظ شجرتك أونلاين وفتحها على جميع أجهزتك.';

  @override
  String get signOut => 'تسجيل الخروج';

  @override
  String get spouses => 'الأزواج';

  @override
  String get statusDivorced => 'مطلّق';

  @override
  String get statusMarried => 'متزوج';

  @override
  String get statusWidowed => 'أرمل';

  @override
  String get swap => 'تبديل';

  @override
  String get systemDefault => 'حسب الجهاز';

  @override
  String get theme => 'المظهر';

  @override
  String get themeDark => 'داكن';

  @override
  String get themeLight => 'فاتح';

  @override
  String get timeline => 'الخط الزمني';

  @override
  String get treeHint =>
      'تلميح: اضغط على شخص لعرض الخيارات، واضغط مرتين لجعله المحور، واستخدم القرص أو العجلة للتكبير.';

  @override
  String get treeScope => 'من يظهر في الشجرة';

  @override
  String get unlink => 'إزالة الربط';

  @override
  String get unlinkConfirm => 'إزالة هذه الصلة؟ سيبقى الأشخاص في الشجرة.';

  @override
  String get unnamed => '(بدون اسم)';

  @override
  String get upload => 'رفع';

  @override
  String get uploadTitle => 'رفع شجرتك؟';

  @override
  String get viewDetails => 'عرض التفاصيل';

  @override
  String get actionFailed => 'حدث خطأ';

  @override
  String get anyoneWithCode => 'أي شخص لديه الرمز';

  @override
  String get changeRole => 'تغيير الصلاحية';

  @override
  String get checkInvite => 'تحقق من الرمز';

  @override
  String get copyCode => 'نسخ الرمز';

  @override
  String get copyInviteMessage => 'نسخ رسالة الدعوة';

  @override
  String get createInvite => 'إنشاء الدعوة';

  @override
  String get deleteTree => 'حذف الشجرة';

  @override
  String get emptyViewOnly =>
      'هذه الشجرة المشتركة فارغة، ولديك صلاحية العرض فقط.';

  @override
  String get inviteCode => 'رمز الدعوة';

  @override
  String get inviteEmailHint =>
      'إن حددته، فلن يستخدم الدعوة إلا من يسجل الدخول بهذا البريد.';

  @override
  String get inviteEmailOptional => 'البريد الإلكتروني (اختياري)';

  @override
  String get inviteExpired => 'انتهت صلاحية هذه الدعوة. اطلب دعوة جديدة.';

  @override
  String get inviteNotFound => 'رمز الدعوة غير موجود. تحقق منه وحاول مرة أخرى.';

  @override
  String get inviteReady => 'الدعوة جاهزة';

  @override
  String get inviteReadyHint =>
      'أرسل هذا الرمز لقريبك. يسجّل الدخول في التطبيق ويدخله من «الانضمام برمز». يُستخدم مرة واحدة وينتهي بعد 7 أيام.';

  @override
  String get inviteRelative => 'دعوة قريب';

  @override
  String get inviteRoleQuestion => 'ما الذي يمكنه فعله؟';

  @override
  String get inviteUsed => 'تم استخدام هذه الدعوة من قبل.';

  @override
  String get inviteWrongEmail => 'هذه الدعوة مخصصة لبريد إلكتروني آخر.';

  @override
  String get joinHint => 'أدخل رمز الدعوة الذي أرسله لك قريبك.';

  @override
  String get joinTree => 'الانضمام للشجرة';

  @override
  String get joinWithCode => 'الانضمام برمز';

  @override
  String get leaveTree => 'مغادرة الشجرة';

  @override
  String get liveEditingNote =>
      'تظهر تعديلات أي محرر للجميع خلال ثوانٍ. إذا عدّل شخصان نفس الفرد في الوقت نفسه، يُعتمد آخر حفظ.';

  @override
  String get myTrees => 'أشجار عائلتي';

  @override
  String get newTree => 'شجرة جديدة';

  @override
  String get noPendingInvites => 'لا توجد دعوات معلّقة.';

  @override
  String get pendingInvites => 'دعوات معلّقة';

  @override
  String get removeMember => 'إزالة من الشجرة';

  @override
  String get renameTree => 'إعادة التسمية';

  @override
  String get revokeConfirm => 'إلغاء هذه الدعوة؟ سيتوقف الرمز عن العمل.';

  @override
  String get revokeInvite => 'إلغاء الدعوة';

  @override
  String get roleEditor => 'محرر';

  @override
  String get roleEditorHint => 'يمكنه إضافة الأشخاص وتعديلهم';

  @override
  String get roleOwner => 'المالك';

  @override
  String get roleOwnerHint => 'يدير المشاركة والشجرة';

  @override
  String get roleViewer => 'مشاهد';

  @override
  String get roleViewerHint => 'يمكنه العرض فقط';

  @override
  String get shareIntro => 'ادعُ أقاربك لعرض هذه الشجرة أو بنائها معك.';

  @override
  String get shareTree => 'مشاركة الشجرة';

  @override
  String get shareTreeHint => 'الأعضاء والدعوات';

  @override
  String get signInToJoin =>
      'سجّل الدخول أو أنشئ حساباً للانضمام إلى شجرة مشتركة.';

  @override
  String get treeName => 'اسم الشجرة';

  @override
  String get viewOnly => 'عرض فقط';

  @override
  String get you => 'أنت';

  @override
  String ageYears(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n سنة',
      few: '$n سنوات',
      two: 'سنتان',
      one: 'سنة واحدة',
      zero: 'أقل من سنة',
    );
    return '$_temp0';
  }

  @override
  String diedAged(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'توفي بعمر $n سنة',
      few: 'توفي بعمر $n سنوات',
      two: 'توفي بعمر سنتين',
      one: 'توفي بعمر سنة',
      zero: 'توفي رضيعاً',
    );
    return '$_temp0';
  }

  @override
  String bornShort(String date) {
    return 'و. $date';
  }

  @override
  String diedShort(String date) {
    return 'ت. $date';
  }

  @override
  String commonAncestor(String name) {
    return 'الجد المشترك: $name';
  }

  @override
  String deleteConfirm(String name) {
    return 'حذف $name وجميع صلاته؟';
  }

  @override
  String evBornIn(String place) {
    return 'وُلد في $place';
  }

  @override
  String evChildBorn(String name) {
    return 'ولادة $name';
  }

  @override
  String evDivorced(String name) {
    return 'الطلاق من $name';
  }

  @override
  String evMarried(String name) {
    return 'الزواج من $name';
  }

  @override
  String evMoved(String place) {
    return 'الانتقال إلى $place';
  }

  @override
  String evParentDied(String name) {
    return 'وفاة $name';
  }

  @override
  String evWidowed(String name) {
    return 'الترمّل: $name';
  }

  @override
  String faceEligible(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'يمكن المقارنة مع $count فرداً.',
      few: 'يمكن المقارنة مع $count أفراد.',
      two: 'يمكن المقارنة مع فردين.',
      one: 'يمكن المقارنة مع فرد واحد.',
      zero: 'لم يوافق أي فرد آخر على المقارنة بعد.',
    );
    return '$_temp0';
  }

  @override
  String focusSet(String name) {
    return 'أصبح $name محور الشجرة';
  }

  @override
  String importDone(int count) {
    return 'تم استيراد $count شخص';
  }

  @override
  String importQuestion(int count) {
    return 'يحتوي الملف على $count شخص. هل تريد دمجهم مع الشجرة الحالية أم استبدالها؟';
  }

  @override
  String isRelationOf(String b, String relation, String a) {
    return 'صلة $b بـ$a: $relation';
  }

  @override
  String peopleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count شخصاً في الشجرة',
      few: '$count أشخاص في الشجرة',
      two: 'شخصان في الشجرة',
      one: 'شخص واحد في الشجرة',
      zero: 'لا يوجد أشخاص في الشجرة',
    );
    return '$_temp0';
  }

  @override
  String relationTo(String relation, String name) {
    return '$relation لـ$name';
  }

  @override
  String uploadQuestion(int count) {
    return 'شجرتك السحابية فارغة. هل تريد رفع $count شخص محفوظين على هذا الجهاز؟';
  }

  @override
  String deleteTreeConfirm(String name) {
    return 'حذف «$name» وكل محتواها لجميع الأعضاء؟ لا يمكن التراجع عن ذلك.';
  }

  @override
  String expiresOn(String date) {
    return 'تنتهي في $date';
  }

  @override
  String inviteMessage(String tree, String code, String link) {
    return 'أنت مدعو إلى شجرة العائلة «$tree». افتح تطبيق شجرة العائلة، وسجّل الدخول، واختر «الانضمام برمز» وأدخل: $code $link';
  }

  @override
  String invitedAs(String role) {
    return 'أنت مدعو بصلاحية: $role';
  }

  @override
  String invitedBy(String email) {
    return 'الدعوة من $email';
  }

  @override
  String joined(String name) {
    return 'انضممت إلى «$name»';
  }

  @override
  String leaveConfirm(String name) {
    return 'مغادرة «$name»؟ ستحتاج دعوة جديدة للعودة.';
  }

  @override
  String membersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count عضواً',
      few: '$count أعضاء',
      two: 'عضوان',
      one: 'عضو واحد',
    );
    return '$_temp0';
  }

  @override
  String removeMemberConfirm(String email) {
    return 'إزالة $email من هذه الشجرة؟';
  }
}
