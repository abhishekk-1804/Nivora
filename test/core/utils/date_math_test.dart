import 'package:flutter_test/flutter_test.dart';
import 'package:imyra_app/core/utils/date_utils.dart';

void main() {
  group('Date Math Loophole Tests', () {
    test('DST Spring Forward does not break calendar day calculation', () {
      // In 2023, US Daylight Saving Time started on March 12, jumping from 2:00 AM to 3:00 AM.
      // A local DateTime difference across this boundary is only 23 hours instead of 24.
      
      final preDst = DateTime(2023, 3, 11);
      final postDst = DateTime(2023, 3, 13);

      // Using raw difference in days on LOCAL time objects might yield 1 instead of 2 
      // if the timezone is affected. However, AppDateUtils.daysBetween converts to UTC
      // at midnight, guaranteeing exactly 24 * X hours difference.
      
      final safeDiff = AppDateUtils.daysBetween(preDst, postDst);
      
      expect(safeDiff, 2);
    });

    test('DST Fall Back does not break calendar day calculation', () {
      // In 2023, US DST ended on Nov 5. (25 hour day)
      final preDst = DateTime(2023, 11, 4);
      final postDst = DateTime(2023, 11, 6);

      final safeDiff = AppDateUtils.daysBetween(preDst, postDst);
      
      expect(safeDiff, 2);
    });
  });
}
