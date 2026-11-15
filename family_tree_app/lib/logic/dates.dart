import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';

/// Which calendar(s) to show dates in.
enum CalendarMode { gregorian, hijri, both }

class DateFormatter {
  final String locale;
  final CalendarMode mode;

  const DateFormatter({required this.locale, required this.mode});

  static const _hijriLocales = {'ar', 'en'};

  String gregorian(DateTime d) => DateFormat.yMMMd(locale).format(d);

  String hijri(DateTime d) {
    final lang = _hijriLocales.contains(locale) ? locale : 'en';
    HijriCalendar.language = lang;
    final h = HijriCalendar.fromDate(d);
    final suffix = lang == 'ar' ? ' هـ' : ' AH';
    return '${h.toFormat('dd MMMM yyyy')}$suffix';
  }

  String format(DateTime? d) {
    if (d == null) return '';
    switch (mode) {
      case CalendarMode.gregorian:
        return gregorian(d);
      case CalendarMode.hijri:
        return hijri(d);
      case CalendarMode.both:
        return '${gregorian(d)} • ${hijri(d)}';
    }
  }

  /// Year only, in the selected calendar (used on compact tree cards).
  String year(DateTime? d) {
    if (d == null) return '';
    final g = DateFormat.y(locale).format(d);
    if (mode == CalendarMode.gregorian) return g;
    final lang = _hijriLocales.contains(locale) ? locale : 'en';
    HijriCalendar.language = lang;
    final h = HijriCalendar.fromDate(d).toFormat('yyyy');
    final hs = lang == 'ar' ? '$h هـ' : '$h AH';
    return mode == CalendarMode.hijri ? hs : '$g / $hs';
  }
}
