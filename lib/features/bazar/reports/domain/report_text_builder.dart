import 'package:family_hub/core/utils/bangla_numerals.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/money.dart';

enum ReportTextPeriod { daily, weekly, monthly }

final class ReportTextCategory {
  const ReportTextCategory({required this.name, required this.total});

  final String name;
  final Money total;
}

final class ReportTextData {
  ReportTextData({
    required this.period,
    required this.range,
    required this.bazarTotal,
    required List<ReportTextCategory> categories,
    required this.choresCompleted,
    required this.choresRemaining,
    required this.choresAwaitingVerification,
    required this.budget,
    required this.spent,
    required this.fundBalance,
  }) : categories = List<ReportTextCategory>.unmodifiable(categories);

  final ReportTextPeriod period;
  final DateKeyRange range;
  final Money bazarTotal;
  final List<ReportTextCategory> categories;
  final int choresCompleted;
  final int choresRemaining;
  final int choresAwaitingVerification;
  final Money? budget;
  final Money spent;
  final Money fundBalance;
}

abstract final class ReportTextBuilder {
  static String build(ReportTextData data, {required String languageCode}) {
    final isBangla = languageCode == 'bn';
    final money = MoneyFormatter(locale: languageCode).format;
    final title = switch ((data.period, isBangla)) {
      (ReportTextPeriod.daily, true) => 'দৈনিক পরিবারের প্রতিবেদন',
      (ReportTextPeriod.weekly, true) => 'সাপ্তাহিক পরিবারের প্রতিবেদন',
      (ReportTextPeriod.monthly, true) => 'মাসিক পরিবারের প্রতিবেদন',
      (ReportTextPeriod.daily, false) => 'Daily family report',
      (ReportTextPeriod.weekly, false) => 'Weekly family report',
      (ReportTextPeriod.monthly, false) => 'Monthly family report',
    };
    final labels = isBangla
        ? (
            range: 'সময়কাল',
            bazar: 'বাজারের মোট',
            chores: 'ঘরের কাজ',
            completed: 'সম্পন্ন',
            remaining: 'বাকি',
            awaiting: 'যাচাইয়ের অপেক্ষায়',
            budget: 'মাসিক বাজেট',
            spent: 'খরচ',
            fund: 'তহবিলের স্থিতি',
          )
        : (
            range: 'Period',
            bazar: 'Bazar total',
            chores: 'Household chores',
            completed: 'Completed',
            remaining: 'Remaining',
            awaiting: 'Awaiting verification',
            budget: 'Monthly budget',
            spent: 'Spent',
            fund: 'Fund balance',
          );
    final lines = <String>[
      title,
      '${labels.range}: ${data.range.start} – ${data.range.end}',
      '',
      '${labels.bazar}: ${money(data.bazarTotal)}',
      for (final category in data.categories)
        '  ${category.name}: ${money(category.total)}',
      '',
      labels.chores,
      '${labels.completed}: ${data.choresCompleted}',
      '${labels.remaining}: ${data.choresRemaining}',
      '${labels.awaiting}: ${data.choresAwaitingVerification}',
      '',
      if (data.budget != null) '${labels.budget}: ${money(data.budget!)}',
      '${labels.spent}: ${money(data.spent)}',
      '${labels.fund}: ${money(data.fundBalance)}',
    ];
    final text = lines.join('\n');
    return isBangla ? toBanglaDigits(text) : text;
  }
}
