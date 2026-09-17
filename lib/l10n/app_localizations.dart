import 'package:flutter/material.dart';

/// Hand-written localization delegate; only Dari/Persian and English are
/// supported. Content data uses the same two language codes.
class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations)!;

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = <Locale>[
    Locale('fa'),
    Locale('en'),
  ];

  String get languageCode => locale.languageCode;
  bool get isRtl => languageCode == 'fa';
  TextDirection get textDirection =>
      isRtl ? TextDirection.rtl : TextDirection.ltr;

  String t(String key) =>
      (_values[languageCode] ?? _values['fa']!)[key] ??
      _values['fa']![key] ??
      key;

  String get appName => t('appName');
  String get appTagline => t('appTagline');
  String get navHome => t('navHome');
  String get navCases => t('navCases');
  String get casesAfghan => t('casesAfghan');
  String get casesIranian => t('casesIranian');
  String get navDocuments => t('navDocuments');
  String get navProfile => t('navProfile');
  String get navSettings => t('navSettings');
  String get search => t('search');
  String get searchNewsHint => t('searchNewsHint');
  String get searchCityHint => t('searchCityHint');
  String get latestNews => t('latestNews');
  String get featured => t('featured');
  String get readMore => t('readMore');
  String get publishedBy => t('publishedBy');
  String get noResults => t('noResults');
  String get loading => t('loading');
  String get retry => t('retry');
  String get errorGeneric => t('errorGeneric');
  String get errorNetwork => t('errorNetwork');
  String get casesTitle => t('casesTitle');
  String get casesSubtitle => t('casesSubtitle');
  String get stepsLabel => t('stepsLabel');
  String get stepsCount => t('stepsCount');
  String get caseGuide => t('caseGuide');
  String get caseNotes => t('caseNotes');
  String get caseNews => t('caseNews');
  String get faq => t('faq');
  String get followOn => t('followOn');
  String get followOff => t('followOff');
  String get followHint => t('followHint');
  String get documentsTitle => t('documentsTitle');
  String get download => t('download');
  String get downloadsCount => t('downloadsCount');
  String get downloading => t('downloading');
  String get downloadDone => t('downloadDone');
  String get downloadFailed => t('downloadFailed');
  String get downloadNotAvailable => t('downloadNotAvailable');
  String get downloadConditions => t('downloadConditions');
  String get signIn => t('signIn');
  String get signInGoogle => t('signInGoogle');
  String get signInTitle => t('signInTitle');
  String get signInBody => t('signInBody');
  String get signInFailed => t('signInFailed');
  String get signOut => t('signOut');
  String get cancel => t('cancel');
  String get close => t('close');
  String get save => t('save');
  String get saved => t('saved');
  String get notifications => t('notifications');
  String get noNotifications => t('noNotifications');
  String get markAllRead => t('markAllRead');
  String get profileTitle => t('profileTitle');
  String get guest => t('guest');
  String get chooseAvatar => t('chooseAvatar');
  String get avatarSaved => t('avatarSaved');
  String get firstName => t('firstName');
  String get lastName => t('lastName');
  String get phone => t('phone');
  String get email => t('email');
  String get myCases => t('myCases');
  String get noFollowedCases => t('noFollowedCases');
  String get latestEvent => t('latestEvent');
  String get settingsTitle => t('settingsTitle');
  String get darkMode => t('darkMode');
  String get lightMode => t('lightMode');
  String get themeSystem => t('themeSystem');
  String get language => t('language');
  String get languageDari => t('languageDari');
  String get languageEnglish => t('languageEnglish');
  String get weather => t('weather');
  String get humidity => t('humidity');
  String get wind => t('wind');
  String get forecast => t('forecast');
  String get calculator => t('calculator');
  String get shareApp => t('shareApp');
  String get appVersion => t('appVersion');
  String get developer => t('developer');
  String get socialLinks => t('socialLinks');
  String get about => t('about');
  String get aboutBody => t('aboutBody');
  String get disclaimer => t('disclaimer');
  String get welcomeBack => t('welcomeBack');
  String get viewAll => t('viewAll');
  String get open => t('open');
  String get categoryAll => t('categoryAll');
  String get linkFailed => t('linkFailed');
  String get shareSubject => t('shareSubject');

  static const Map<String, Map<String, String>> _values =
      <String, Map<String, String>>{
    'fa': <String, String>{
      "appName": "Afghan in USA",
      "appTagline": "راهنمای مهاجرت افغان‌ها در آمریکا",
      "navHome": "خانه",
      "navCases": "پرونده",
      "casesAfghan": "پرونده‌های افغان‌ها",
      "casesIranian": "پرونده‌های ایرانیان",
      "navDocuments": "مستندات",
      "navProfile": "پروفایل",
      "navSettings": "تنظیمات",
      "search": "جستجو",
      "searchNewsHint": "جستجوی خبر یا پرونده...",
      "searchCityHint": "نام شهر را وارد کنید",
      "latestNews": "آخرین رویدادها",
      "featured": "ویژه",
      "readMore": "ادامه مطلب",
      "publishedBy": "منتشر شده توسط",
      "noResults": "نتیجه‌ای یافت نشد",
      "loading": "در حال بارگذاری...",
      "retry": "تلاش دوباره",
      "errorGeneric": "مشکلی پیش آمد",
      "errorNetwork": "اتصال اینترنت را بررسی کنید",
      "casesTitle": "دسته‌های پرونده",
      "casesSubtitle": "مراحل ثبت نام و طی مراحل اداری",
      "stepsLabel": "مرحله",
      "stepsCount": "مرحله",
      "caseGuide": "راهنمای گام‌به‌گام",
      "caseNotes": "نکات مهم",
      "caseNews": "خبرهای مرتبط",
      "faq": "پرسش‌های متداول",
      "followOn": "زنگوله فعال شد؛ خبرهای این پرونده را دریافت می‌کنید",
      "followOff": "زنگوله خاموش شد",
      "followHint": "برای دریافت خبرهای این پرونده زنگوله را سبز کنید",
      "documentsTitle": "اسناد و فرم‌ها",
      "download": "دانلود",
      "downloadsCount": "دانلود",
      "downloading": "در حال دانلود...",
      "downloadDone": "دانلود کامل شد",
      "downloadFailed": "دانلود ناموفق بود",
      "downloadNotAvailable": "فایل این سند فعلاً در دسترس نیست",
      "downloadConditions":
          "شرط دانلود: برای دانلود این سند باید عضو شوید یا با ایمیل خود وارد شوید",
      "signIn": "ورود",
      "signInGoogle": "ورود با حساب گوگل",
      "signInTitle": "ورود به حساب",
      "signInBody":
          "برای دانلود اسناد و دریافت اطلاع‌رسانی، با حساب گوگل خود وارد شوید",
      "signInFailed": "ورود انجام نشد",
      "signOut": "خروج از حساب",
      "cancel": "لغو",
      "close": "بستن",
      "save": "ذخیره",
      "saved": "ذخیره شد",
      "notifications": "اطلاع‌رسانی‌ها",
      "noNotifications": "فعلاً اطلاع‌رسانی جدیدی ندارید",
      "markAllRead": "همه خوانده شد",
      "profileTitle": "پروفایل",
      "guest": "کاربر مهمان",
      "chooseAvatar": "انتخاب آواتار",
      "avatarSaved": "آواتار انتخاب شد",
      "firstName": "نام",
      "lastName": "تخلص",
      "phone": "شماره تماس (اختیاری)",
      "email": "ایمیل",
      "myCases": "پرونده‌های من",
      "noFollowedCases": "هیچ پرونده‌ای را دنبال نمی‌کنید",
      "latestEvent": "آخرین رویداد پرونده شما",
      "settingsTitle": "تنظیمات",
      "darkMode": "حالت شب",
      "lightMode": "حالت روز",
      "themeSystem": "مطابق سیستم",
      "language": "زبان",
      "languageDari": "پارسی",
      "languageEnglish": "انگلیسی",
      "weather": "آب و هوا",
      "humidity": "رطوبت",
      "wind": "باد",
      "forecast": "پیش‌بینی ۵ روزه",
      "calculator": "ماشین حساب",
      "shareApp": "شریک نمودن اپ با دوستان",
      "appVersion": "آخرین نسخه",
      "developer": "سازنده برنامه",
      "socialLinks": "شبکه‌های اجتماعی",
      "about": "درباره برنامه",
      "aboutBody":
          "این برنامه اطلاعات عمومی درباره مسیرهای مهاجرت افغان‌ها به آمریکا را ارائه می‌کند و مشاوره حقوقی نیست.",
      "disclaimer": "این محتوا مشاوره حقوقی نیست",
      "welcomeBack": "خوش آمدید",
      "viewAll": "مشاهده همه",
      "open": "باز کردن",
      "categoryAll": "همه",
      "linkFailed": "باز کردن لینک ناموفق بود",
      "shareSubject": "معرفی اپلیکیشن",
    },
    'en': <String, String>{
      "appName": "Afghan in USA",
      "appTagline": "Immigration guide for Afghans in the USA",
      "navHome": "Home",
      "navCases": "Cases",
      "casesAfghan": "Afghan Cases",
      "casesIranian": "Iranian Cases",
      "navDocuments": "Documents",
      "navProfile": "Profile",
      "navSettings": "Settings",
      "search": "Search",
      "searchNewsHint": "Search news or cases...",
      "searchCityHint": "Enter a city name",
      "latestNews": "Latest updates",
      "featured": "Featured",
      "readMore": "Read more",
      "publishedBy": "Published by",
      "noResults": "No results found",
      "loading": "Loading...",
      "retry": "Retry",
      "errorGeneric": "Something went wrong",
      "errorNetwork": "Check your internet connection",
      "casesTitle": "Case categories",
      "casesSubtitle": "Registration & administrative steps",
      "stepsLabel": "Step",
      "stepsCount": "steps",
      "caseGuide": "Step-by-step guide",
      "caseNotes": "Important notes",
      "caseNews": "Related news",
      "faq": "FAQ",
      "followOn": "Alerts on: you will get updates for this case",
      "followOff": "Alerts off",
      "followHint": "Turn the bell green to get updates for this case",
      "documentsTitle": "Documents & forms",
      "download": "Download",
      "downloadsCount": "downloads",
      "downloading": "Downloading...",
      "downloadDone": "Download complete",
      "downloadFailed": "Download failed",
      "downloadNotAvailable": "This file is not available yet",
      "downloadConditions": "To download, please sign in with your email",
      "signIn": "Sign in",
      "signInGoogle": "Sign in with Google",
      "signInTitle": "Sign in",
      "signInBody": "Sign in with Google to download documents and get alerts",
      "signInFailed": "Sign-in failed",
      "signOut": "Sign out",
      "cancel": "Cancel",
      "close": "Close",
      "save": "Save",
      "saved": "Saved",
      "notifications": "Notifications",
      "noNotifications": "No notifications yet",
      "markAllRead": "Mark all as read",
      "profileTitle": "Profile",
      "guest": "Guest user",
      "chooseAvatar": "Choose avatar",
      "avatarSaved": "Avatar selected",
      "firstName": "First name",
      "lastName": "Last name",
      "phone": "Phone (optional)",
      "email": "Email",
      "myCases": "My cases",
      "noFollowedCases": "You are not following any case",
      "latestEvent": "Latest event for your case",
      "settingsTitle": "Settings",
      "darkMode": "Dark mode",
      "lightMode": "Light mode",
      "themeSystem": "System default",
      "language": "Language",
      "languageDari": "Persian",
      "languageEnglish": "English",
      "weather": "Weather",
      "humidity": "Humidity",
      "wind": "Wind",
      "forecast": "5-day forecast",
      "calculator": "Calculator",
      "shareApp": "Share app with friends",
      "appVersion": "App version",
      "developer": "Developer",
      "socialLinks": "Social media",
      "about": "About",
      "aboutBody":
          "This app provides general information about Afghan immigration pathways to the USA and is not legal advice.",
      "disclaimer": "This content is not legal advice",
      "welcomeBack": "Welcome back",
      "viewAll": "View all",
      "open": "Open",
      "categoryAll": "All",
      "linkFailed": "Could not open the link",
      "shareSubject": "App introduction",
    },
  };
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      <String>['fa', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
