import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' as drift;
import 'package:imyra_app/core/database/app_database.dart';
import 'package:imyra_app/core/diagnostics/error_logger.dart';

void main() {
  test('5-Year Payload Stress Test generates report efficiently', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        return '.';
      },
    );
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final now = DateTime.now();
    final startDate = now.subtract(const Duration(days: 1800)); // ~5 years
    
    // Inject 1,800 days of data
    List<CycleEventsCompanion> cycleEvents = [];
    
    for (int i = 0; i < 1800; i++) {
      final date = startDate.add(Duration(days: i));
      
      // Every 28 days is a cycle start
      if (i % 28 == 0) {
        cycleEvents.add(CycleEventsCompanion.insert(
          date: date,
          flowType: 'Medium',
          isTrueCycleStart: const drift.Value(true),
        ));
      } else if (i % 28 >= 20) {
        // Luteal phase symptoms
        cycleEvents.add(CycleEventsCompanion.insert(
          date: date,
          flowType: 'Spotting',
          symptoms: const drift.Value('Anxiety, Bloating'),
          isTrueCycleStart: const drift.Value(false),
        ));
      }
    }

    // Batch insert for performance
    await db.batch((batch) {
      batch.insertAll(db.cycleEvents, cycleEvents);
    });

    final stopwatch = Stopwatch()..start();
    
    final report = await db.reportDao.generateReport(
      startDate: startDate,
      endDate: now,
      rangeLabel: '5 Year Test',
    );
    
    stopwatch.stop();

    // The generation logic should handle 5 years of dense data efficiently
    expect(report.totalCycles, greaterThan(60));
    expect(report.symptomPhaseClusters.isNotEmpty, true);
    
    // Log execution time. In a native memory DB this should be < 1 second.
    // If it's slow, we know the clustering algorithm is scaling poorly O(N^2).
    ErrorLogger.info('5-Year Report Generation took: ${stopwatch.elapsedMilliseconds}ms');
    expect(stopwatch.elapsedMilliseconds, lessThan(2000), reason: 'Report generation is too slow for 5 years of data');
  });
}
