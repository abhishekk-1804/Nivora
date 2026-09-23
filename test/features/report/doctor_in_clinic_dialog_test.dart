import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nivora_app/features/report/domain/report_payload.dart';
import 'package:nivora_app/features/report/presentation/widgets/doctor_in_clinic_dialog.dart';

void main() {
  DoctorReportData createTestData({
    bool rotterdamOD = false,
    bool rotterdamHA = false,
    bool rotterdamPCOM = false,
    int heavyDays = 0,
    int floodingEvents = 0,
    int medianLength = 28,
    int totalCycles = 4,
    int adherence = 85,
  }) {
    return DoctorReportData(
      dateRange: 'Jan 1, 2026 – Mar 31, 2026',
      totalCycles: totalCycles,
      cycleRangeMin: 26,
      cycleRangeMax: 32,
      medianCycleLength: medianLength,
      adherencePercentage: adherence,
      totalHeavyWithClotsDays: heavyDays,
      floodingEventsCount: floodingEvents,
      spottingColorProfile: 'None',
      cycleRows: [],
      symptomPhaseClusters: [],
      cycleLengthsForChart: [28, 29, 27, 30],
      rotterdamOvulatoryDysfunction: rotterdamOD,
      rotterdamHyperandrogenism: rotterdamHA,
      rotterdamPCOM: rotterdamPCOM,
    );
  }

  Widget createWidget(DoctorReportData data, {VoidCallback? onExportPdf}) {
    return MaterialApp(
      home: Scaffold(
        body: DoctorInClinicDialog(
          data: data,
          onExportPdf: onExportPdf,
        ),
      ),
    );
  }

  group('DoctorInClinicDialog - Clinical Verification', () {
    testWidgets('renders clinical parameters and metrics accurately', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final data = createTestData(
        medianLength: 30,
        totalCycles: 5,
        adherence: 92,
        heavyDays: 3,
        floodingEvents: 1,
      );

      await tester.pumpWidget(createWidget(data));
      await tester.pumpAndSettle();

      expect(find.text('In-Clinic Quick Glance'), findsOneWidget);
      expect(find.text('30d'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('92%'), findsOneWidget);
      expect(find.text('3 days'), findsOneWidget);
      expect(find.text('1 events'), findsOneWidget);
    });

    testWidgets('accurately maps Rotterdam phenotypes A, B, C, D and subclinical states', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // 1. Phenotype A (Full: OD + HA + PCOM)
      await tester.pumpWidget(createWidget(createTestData(rotterdamOD: true, rotterdamHA: true, rotterdamPCOM: true)));
      await tester.pumpAndSettle();
      expect(find.text('Phenotype A (Full Criteria)'), findsOneWidget);

      // 2. Phenotype B (Classic: OD + HA, no PCOM)
      await tester.pumpWidget(createWidget(createTestData(rotterdamOD: true, rotterdamHA: true, rotterdamPCOM: false)));
      await tester.pumpAndSettle();
      expect(find.text('Phenotype B (Classic)'), findsOneWidget);

      // 3. Phenotype C (Ovulatory: HA + PCOM, no OD)
      await tester.pumpWidget(createWidget(createTestData(rotterdamOD: false, rotterdamHA: true, rotterdamPCOM: true)));
      await tester.pumpAndSettle();
      expect(find.text('Phenotype C (Ovulatory)'), findsOneWidget);

      // 4. Phenotype D (Non-Hyperandrogenic: OD + PCOM, no HA)
      await tester.pumpWidget(createWidget(createTestData(rotterdamOD: true, rotterdamHA: false, rotterdamPCOM: true)));
      await tester.pumpAndSettle();
      expect(find.text('Phenotype D (Non-Hyperandrogenic)'), findsOneWidget);

      // 5. Unconfirmed OD only
      await tester.pumpWidget(createWidget(createTestData(rotterdamOD: true, rotterdamHA: false, rotterdamPCOM: false)));
      await tester.pumpAndSettle();
      expect(find.text('Ovulatory Dysfunction (Unconfirmed PCOM)'), findsOneWidget);

      // 6. Subclinical / Normal
      await tester.pumpWidget(createWidget(createTestData(rotterdamOD: false, rotterdamHA: false, rotterdamPCOM: false)));
      await tester.pumpAndSettle();
      expect(find.text('Subclinical / Normal'), findsOneWidget);
    });

    testWidgets('triggers export PDF callback when action button tapped', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      bool exportTriggered = false;
      final data = createTestData();

      await tester.pumpWidget(
        createWidget(
          data,
          onExportPdf: () {
            exportTriggered = true;
          },
        ),
      );
      await tester.pumpAndSettle();

      final exportButton = find.text('Export Full PDF');
      expect(exportButton, findsOneWidget);

      await tester.tap(exportButton);
      await tester.pumpAndSettle();

      expect(exportTriggered, isTrue);
    });
  });
}
