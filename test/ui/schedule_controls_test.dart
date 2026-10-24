import 'package:flutter_test/flutter_test.dart';
import 'package:week_counter/ui/widgets/schedule_controls.dart';

void main() {
  const mondayFirst = [1, 2, 3, 4, 5, 6, 7];
  const sundayFirst = [7, 1, 2, 3, 4, 5, 6];

  test('a work week starts where its run of workdays starts', () {
    // Sunday to Thursday, in a week that starts on Monday.
    expect(workWeek({7, 1, 2, 3, 4}, mondayFirst), [7, 1, 2, 3, 4]);
    // Friday to Monday shifts.
    expect(workWeek({5, 6, 7, 1}, mondayFirst), [5, 6, 7, 1]);
  });

  test('a week that fits the calendar week keeps its order', () {
    expect(workWeek({1, 2, 3, 4, 5}, mondayFirst), [1, 2, 3, 4, 5]);
    expect(workWeek({1, 2, 3, 4, 5}, sundayFirst), [1, 2, 3, 4, 5]);
    expect(workWeek({1, 3, 5}, mondayFirst), [1, 3, 5]);
    expect(workWeek({1, 2, 3, 4, 5, 6, 7}, sundayFirst), sundayFirst);
    expect(workWeek({}, mondayFirst), isEmpty);
  });
}
