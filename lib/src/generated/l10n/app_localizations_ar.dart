// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'PicoClaw UI';

  @override
  String get run => 'تشغيل';

  @override
  String get stop => 'إيقاف';

  @override
  String get config => 'إعداد';

  @override
  String get webAdmin => 'إدارة الويب';

  @override
  String get logs => 'السجلات';

  @override
  String get viewLogs => 'عرض السجلات';

  @override
  String get statusRunning => 'قيد التشغيل';

  @override
  String get statusStopped => 'متوقف';

  @override
  String get settings => 'الإعدادات';

  @override
  String get address => 'العنوان';

  @override
  String get port => 'المنفذ';

  @override
  String get save => 'حفظ';

  @override
  String get showWindow => 'إظهار النافذة';

  @override
  String get exit => 'خروج';

  @override
  String get binaryPath => 'مسار الثنائي';

  @override
  String get browse => 'تصفح';

  @override
  String get pathError => 'مسار غير صالح';

  @override
  String get arguments => 'المعاملات';

  @override
  String get argumentsHint => 'مثلاً: config.json';

  @override
  String get notStarted => 'الخدمة لم تبدأ بعد';

  @override
  String get startHint => 'يرجى بدء الخدمة من لوحة التحكم أولاً.';

  @override
  String get goToDashboard => 'الذهاب إلى لوحة التحكم';

  @override
  String get back => 'رجوع';

  @override
  String get forward => 'تقديم';

  @override
  String get refresh => 'تحديث';

  @override
  String get coreBinaryMissing =>
      'لم يتم العثور على الملف الثنائي الأساسي. ضع الثنائي للنظام الأساسي في app/bin/ أو حدد المسار في الإعدادات.';

  @override
  String get coreStartFailed => 'فشل في بدء خدمة النواة.';

  @override
  String get coreStopFailed => 'فشل في إيقاف خدمة النواة.';

  @override
  String get coreInvalidBinary => 'ملف ثنائي أساسي غير صالح.';

  @override
  String coreUnknownError(Object code) {
    return 'خطأ أساسي غير معروف: $code';
  }

  @override
  String get coreValid => 'الملف الثنائي الأساسي صالح.';

  @override
  String get publicMode => 'الوضع العام';

  @override
  String get publicModeHintDesc =>
      'عند التمكين، تسمح الخدمة بالوصول الخارجي وسيتم تعطيل حقل العنوان';

  @override
  String get themeSelection => 'السمة';

  @override
  String get check => 'فحص';

  @override
  String get launchService => 'تشغيل الخدمة';

  @override
  String get stopService => 'إيقاف الخدمة';

  @override
  String get endpoint => 'نقطة الوصول';

  @override
  String get statusActive => 'نشط';

  @override
  String get statusSyncing => 'جارٍ المزامنة';

  @override
  String get statusIdle => 'خامل';

  @override
  String get publicModeEnabled => 'الوضع العام مفعل';

  @override
  String get localMode => 'الوضع المحلي';

  @override
  String get unableToGetDeviceIp => 'تعذر الحصول على عنوان IP للجهاز';

  @override
  String get deviceReportingTitle => 'تعليقات توافق الجهاز';

  @override
  String get deviceReportingSubtitle =>
      'تُستخدم فقط للتحقق من توافق إصدار نظام التشغيل وإصدار التطبيق. لا تتضمن رسائل الدردشة أو تفاصيل الحساب أو المحتوى الشخصي';

  @override
  String get deviceReportingConsentTitle => 'ساعد في تحسين توافق الجهاز';

  @override
  String get deviceReportingConsentDescription =>
      'عند التمكين، يتم إرسال معرف تثبيت مجهول فقط وإصدار نظام التشغيل وإصدار التطبيق لفهم التوافق. قد يتم جمع اللغة والمنطقة بشكل منفصل بواسطة Firebase Analytics. لا يتم تحميل رسائل الدردشة أو المحتوى المكتوب أو تفاصيل الحساب أو الملفات أو الإعدادات المخصصة';

  @override
  String get deviceReportingBannerDescription =>
      'يتم مزامنة معرف التثبيت المجهول وإصدار نظام التشغيل وإصدار التطبيق فقط لتحسين التوافق. قد يتم جمع اللغة والمنطقة بشكل منفصل بواسطة Firebase Analytics. لا يتم إرسال رسائل الدردشة أو تفاصيل الحساب أو الملفات أو المحتوى الشخصي';

  @override
  String get deviceReportingWhatWillBeSent => 'تتضمن فقط تفاصيل الجهاز هذه';

  @override
  String get deviceReportingDeviceLabel => 'طراز الجهاز';

  @override
  String get deviceReportingPlatformLabel => 'فئة الجهاز';

  @override
  String get deviceReportingSystemLabel => 'إصدار نظام التشغيل';

  @override
  String get deviceReportingTimingNote =>
      'يتم تشغيل المزامنة مرة واحدة عند التمكين، ومرة أخرى فقط بعد اكتشاف تحديث للنظام';

  @override
  String get deviceReportingDeny => 'ليس الآن';

  @override
  String get deviceReportingAllow => 'تشغيل';

  @override
  String get deviceReportingUploadSucceeded => 'تعليقات توافق الجهاز مفعلة';

  @override
  String get deviceReportingUploadFailed =>
      'تعليقات توافق الجهاز مفعلة، لكن مزامنة معلومات الجهاز الحالية لم تكتمل';

  @override
  String get deviceReportingDisabled => 'تعليقات توافق الجهاز معطلة';

  @override
  String get localModeHint =>
      '1. انتقل إلى تكوين الخدمة\n2. شغّل الوضع العام\n3. أعد تشغيل الخدمة\n4. امسح رمز QR للوصول إلى PicoClaw';

  @override
  String get publicModeHint =>
      '1. ابدأ الخدمة\n2. امسح رمز QR للوصول إلى PicoClaw';

  @override
  String get noLogsToExport => 'لا توجد سجلات للتصدير';

  @override
  String get logsSavedToMediaLibrary =>
      'تم حفظ السجلات في التنزيلات (مكتبة وسائط Android)';

  @override
  String logsSavedToDownloads(Object path) {
    return 'تم حفظ السجلات في التنزيلات: $path';
  }

  @override
  String get shareLogsText => 'سجلات Picoclaw';

  @override
  String get workspaceDirectory => 'مساحة العمل';

  @override
  String logsSavedToMediaLibraryWithName(Object name) {
    return 'تم حفظ السجلات في التنزيلات (مكتبة وسائط Android): $name';
  }

  @override
  String shareFailed(Object error) {
    return 'فشل في فتح حوار المشاركة: $error';
  }

  @override
  String get exportLogs => 'تصدير السجلات';

  @override
  String logEventsCount(int count) {
    return '$count أحداث';
  }

  @override
  String get unsavedChanges => 'تغييرات غير محفوظة';

  @override
  String get unsavedChangesHint =>
      'لديك تغييرات غير محفوظة. هل تريد التخلص منها؟';

  @override
  String get cancel => 'إلغاء';

  @override
  String get discard => 'تجاهل';

  @override
  String get saved => 'تم الحفظ';

  @override
  String get language => 'اللغة';

  @override
  String get selectLanguage => 'اختر اللغة';

  @override
  String get about => 'حول';

  @override
  String get aboutDescription =>
      'PicoClaw هو تطبيق Flutter متعدد المنصات لإدارة خدمة PicoClaw.';

  @override
  String get aboutAppVersionLabel => 'إصدار PicoClaw';

  @override
  String get aboutCoreVersionLabel => 'إصدار PicoClaw Core';

  @override
  String get aboutVersionUnavailable => 'غير متوفر';

  @override
  String get picoclawOfficial => 'موقع PicoClaw الرسمي';

  @override
  String get sipeedOfficial => 'موقع Sipeed الرسمي';

  @override
  String get openLinkFailed => 'تعذر فتح الرابط الرسمي.';

  @override
  String get close => 'إغلاق';
}
