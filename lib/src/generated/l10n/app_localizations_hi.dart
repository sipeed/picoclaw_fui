// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'PicoClaw UI';

  @override
  String get run => 'चलाएं';

  @override
  String get stop => 'रोकें';

  @override
  String get config => 'कॉन्फ़िग';

  @override
  String get webAdmin => 'वेब एडमिन';

  @override
  String get logs => 'लॉग';

  @override
  String get viewLogs => 'लॉग देखें';

  @override
  String get statusRunning => 'चल रहा है';

  @override
  String get statusStopped => 'रुका हुआ';

  @override
  String get settings => 'सेटिंग्स';

  @override
  String get address => 'पता';

  @override
  String get port => 'पोर्ट';

  @override
  String get save => 'सहेजें';

  @override
  String get showWindow => 'विंडो दिखाएं';

  @override
  String get exit => 'बाहर निकलें';

  @override
  String get binaryPath => 'बाइनरी पथ';

  @override
  String get browse => 'ब्राउज़ करें';

  @override
  String get pathError => 'अमान्य पथ';

  @override
  String get arguments => 'तर्क';

  @override
  String get argumentsHint => 'उदा. config.json';

  @override
  String get notStarted => 'सेवा शुरू नहीं हुई';

  @override
  String get startHint => 'कृपया पहले डैशबोर्ड से सेवा शुरू करें।';

  @override
  String get goToDashboard => 'डैशबोर्ड पर जाएं';

  @override
  String get back => 'वापस';

  @override
  String get forward => 'आगे';

  @override
  String get refresh => 'रीफ्रेश';

  @override
  String get coreBinaryMissing =>
      'कोर बाइनरी नहीं मिली। प्लेटफ़ॉर्म बाइनरी को app/bin/ में रखें या सेटिंग्स में पथ सेट करें।';

  @override
  String get coreStartFailed => 'कोर सेवा शुरू करने में विफल।';

  @override
  String get coreStopFailed => 'कोर सेवा रोकने में विफल।';

  @override
  String get coreInvalidBinary => 'अमान्य कोर बाइनरी फ़ाइल।';

  @override
  String coreUnknownError(Object code) {
    return 'अज्ञात कोर त्रुटि: $code';
  }

  @override
  String get coreValid => 'कोर बाइनरी वैध है।';

  @override
  String get publicMode => 'पब्लिक मोड';

  @override
  String get publicModeHintDesc =>
      'सक्षम होने पर, सेवा बाहरी एक्सेस की अनुमति देती है और पता फ़ील्ड अक्षम हो जाएगी';

  @override
  String get themeSelection => 'थीम';

  @override
  String get check => 'जांचें';

  @override
  String get launchService => 'सेवा शुरू करें';

  @override
  String get stopService => 'सेवा रोकें';

  @override
  String get endpoint => 'एंडपॉइंट';

  @override
  String get statusActive => 'सक्रिय';

  @override
  String get statusSyncing => 'सिंक हो रहा है';

  @override
  String get statusIdle => 'निष्क्रिय';

  @override
  String get publicModeEnabled => 'पब्लिक मोड सक्षम';

  @override
  String get localMode => 'लोकल मोड';

  @override
  String get unableToGetDeviceIp => 'डिवाइस IP प्राप्त करने में असमर्थ';

  @override
  String get deviceReportingTitle => 'डिवाइस संगतता प्रतिक्रिया';

  @override
  String get deviceReportingSubtitle =>
      'केवल OS संस्करण और ऐप संस्करण संगतता की जांच के लिए उपयोग किया जाता है। चैट संदेशों, खाता विवरण या व्यक्तिगत सामग्री का कोई संबंध नहीं है';

  @override
  String get deviceReportingConsentTitle =>
      'डिवाइस संगतता में सुधार करने में मदद करें';

  @override
  String get deviceReportingConsentDescription =>
      'सक्षम होने पर, केवल संगतता को समझने के लिए एक अनाम इंस्टॉलेशन ID, OS संस्करण और ऐप संस्करण भेजे जाते हैं। भाषा और क्षेत्र Firebase Analytics द्वारा अलग से एकत्र किए जा सकते हैं। कोई चैट संदेश, टाइप की गई सामग्री, खाता विवरण, फ़ाइलें या कस्टम सेटिंग्स अपलोड नहीं की जाती हैं';

  @override
  String get deviceReportingBannerDescription =>
      'संगतता में सुधार के लिए केवल एक अनाम इंस्टॉलेशन ID, OS संस्करण और ऐप संस्करण सिंक किए जाते हैं। भाषा और क्षेत्र Firebase Analytics द्वारा अलग से एकत्र किए जा सकते हैं। कोई चैट संदेश, खाता विवरण, फ़ाइलें या व्यक्तिगत सामग्री नहीं भेजी जाती';

  @override
  String get deviceReportingWhatWillBeSent => 'केवल ये डिवाइस विवरण शामिल हैं';

  @override
  String get deviceReportingDeviceLabel => 'डिवाइस मॉडल';

  @override
  String get deviceReportingPlatformLabel => 'डिवाइस श्रेणी';

  @override
  String get deviceReportingSystemLabel => 'OS संस्करण';

  @override
  String get deviceReportingTimingNote =>
      'सक्षम होने पर एक बार सिंक चलता है, और फिर केवल तब जब सिस्टम अपडेट का पता चलता है';

  @override
  String get deviceReportingDeny => 'अभी नहीं';

  @override
  String get deviceReportingAllow => 'सक्षम करें';

  @override
  String get deviceReportingUploadSucceeded =>
      'डिवाइस संगतता प्रतिक्रिया सक्षम है';

  @override
  String get deviceReportingUploadFailed =>
      'डिवाइस संगतता प्रतिक्रिया सक्षम है, लेकिन वर्तमान डिवाइस जानकारी सिंक पूरा नहीं हुआ';

  @override
  String get deviceReportingDisabled => 'डिवाइस संगतता प्रतिक्रिया अक्षम है';

  @override
  String get localModeHint =>
      '1. सेवा कॉन्फ़िगरेशन पर जाएं\n2. पब्लिक मोड चालू करें\n3. सेवा पुनः आरंभ करें\n4. PicoClaw तक पहुंचने के लिए QR कोड स्कैन करें';

  @override
  String get publicModeHint =>
      '1. सेवा शुरू करें\n2. PicoClaw तक पहुंचने के लिए QR कोड स्कैन करें';

  @override
  String get noLogsToExport => 'निर्यात करने के लिए कोई लॉग नहीं';

  @override
  String get logsSavedToMediaLibrary =>
      'लॉग डाउनलोड (Android मीडिया लाइब्रेरी) में सहेजे गए';

  @override
  String logsSavedToDownloads(Object path) {
    return 'लॉग डाउनलोड में सहेजे गए: $path';
  }

  @override
  String get shareLogsText => 'Picoclaw लॉग';

  @override
  String get workspaceDirectory => 'कार्यस्थान';

  @override
  String logsSavedToMediaLibraryWithName(Object name) {
    return 'लॉग डाउनलोड (Android मीडिया लाइब्रेरी) में सहेजे गए: $name';
  }

  @override
  String shareFailed(Object error) {
    return 'शेयर डायलॉग खोलने में विफल: $error';
  }

  @override
  String get exportLogs => 'लॉग निर्यात करें';

  @override
  String logEventsCount(int count) {
    return '$count इवेंट्स';
  }

  @override
  String get unsavedChanges => 'असहेजे गए परिवर्तन';

  @override
  String get unsavedChangesHint =>
      'आपके पास असहेजे गए परिवर्तन हैं। क्या आप उन्हें छोड़ना चाहते हैं?';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get discard => 'छोड़ें';

  @override
  String get saved => 'सहेजे गए';

  @override
  String get language => 'भाषा';

  @override
  String get selectLanguage => 'भाषा चुनें';

  @override
  String get about => 'परिचय';

  @override
  String get aboutDescription =>
      'PicoClaw, PicoClaw सेवा को प्रबंधित करने के लिए एक क्रॉस-प्लेटफ़ॉर्म Flutter ऐप है।';

  @override
  String get aboutAppVersionLabel => 'PicoClaw संस्करण';

  @override
  String get aboutCoreVersionLabel => 'PicoClaw Core संस्करण';

  @override
  String get aboutVersionUnavailable => 'उपलब्ध नहीं';

  @override
  String get picoclawOfficial => 'PicoClaw आधिकारिक साइट';

  @override
  String get sipeedOfficial => 'Sipeed आधिकारिक साइट';

  @override
  String get openLinkFailed => 'आधिकारिक लिंक नहीं खुल सका।';

  @override
  String get close => 'बंद करें';
}
