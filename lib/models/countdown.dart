import 'package:flutter/foundation.dart';

import '../core/calendar_date.dart';

/// The user's own event, such as a trip or a birthday, counted down to the
/// start of its day.
@immutable
class Countdown {
  const Countdown({required this.id, required this.title, required this.date});

  factory Countdown.fromJson(Map<String, dynamic> json) => Countdown(
    id: json['id'] as String,
    title: json['title'] as String,
    date: CalendarDate.parse(json['date'] as String),
  );

  final String id;
  final String title;
  final CalendarDate date;

  /// Midnight at the start of [date], when the countdown reaches zero.
  DateTime get target => date.startOfDay;

  Countdown copyWith({String? title, CalendarDate? date}) =>
      Countdown(id: id, title: title ?? this.title, date: date ?? this.date);

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'date': date.toIso(),
  };

  @override
  bool operator ==(Object other) =>
      other is Countdown &&
      other.id == id &&
      other.title == title &&
      other.date == date;

  @override
  int get hashCode => Object.hash(id, title, date);
}
