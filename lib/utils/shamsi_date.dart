/// Solar Hijri (Jalali) date conversion and display helpers.
///
/// The Afghan and Iranian calendars share the same day numbering and differ
/// only in month names (Hamal↔Farvardin, Sunbula↔Shahrivar, ...), so both
/// names are shown side by side: «۲۸ سنبله / شهریور ۱۴۰۵».
library;

class ShamsiDate {
  ShamsiDate._();

  static const List<String> afghanMonths = <String>[
    'حمل', 'ثور', 'جوزا', 'سرطان', 'اسد', 'سنبله',
    'میزان', 'عقرب', 'قوس', 'جدی', 'دلو', 'حوت',
  ];

  static const List<String> iranianMonths = <String>[
    'فروردین', 'اردیبهشت', 'خرداد', 'تیر', 'مرداد', 'شهریور',
    'مهر', 'آبان', 'آذر', 'دی', 'بهمن', 'اسفند',
  ];

  static const String _digits = '۰۱۲۳۴۵۶۷۸۹';

  static String _fa(int n) {
    final String s = n.toString();
    final StringBuffer b = StringBuffer();
    for (final String ch in s.split('')) {
      final int i = int.parse(ch);
      b.write(_digits[i]);
    }
    return b.toString();
  }

  /// Classic jalaali conversion (jdf.scr.ir algorithm).
  static List<int> gregorianToJalali(int gy, int gm, int gd) {
    const List<int> gDaysInMonth = <int>[
      0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334,
    ];
    int jy = (gy <= 1600) ? 0 : 979;
    gy -= (gy <= 1600) ? 621 : 1600;
    final int gy2 = (gm > 2) ? (gy + 1) : gy;
    int days = (365 * gy) +
        ((gy2 + 3) ~/ 4) -
        ((gy2 + 99) ~/ 100) +
        ((gy2 + 399) ~/ 400) -
        80 +
        gd +
        gDaysInMonth[gm - 1];
    jy += 33 * (days ~/ 12053);
    days %= 12053;
    jy += 4 * (days ~/ 1461);
    days %= 1461;
    if (days > 365) {
      jy += (days - 1) ~/ 365;
      days = (days - 1) % 365;
    }
    final int jm = (days < 186) ? 1 + (days ~/ 31) : 7 + ((days - 186) ~/ 30);
    final int jd = 1 + ((days < 186) ? (days % 31) : ((days - 186) % 30));
    return <int>[jy, jm, jd];
  }

  /// «۲۸ سنبله / شهریور ۱۴۰۵» — Afghan and Iranian month names together.
  static String format(DateTime date) {
    final List<int> j = gregorianToJalali(date.year, date.month, date.day);
    final int jy = j[0], jm = j[1], jd = j[2];
    return '${_fa(jd)} ${afghanMonths[jm - 1]} / ${iranianMonths[jm - 1]} ${_fa(jy)}';
  }
}
