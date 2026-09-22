import 'package:flutter_test/flutter_test.dart';
import 'package:nivora_app/features/report/service/doctor_pdf_generator.dart';
import 'package:nivora_app/features/report/domain/report_payload.dart';

void main() {
  group('DoctorPdfGenerator Tests', () {
    test('PDF Generator executes without errors with fully populated phenotype data', () async {
      final payload = DoctorReportData(
        dateRange: 'Jan 2026 - Jun 2026',
        totalCycles: 5,
        cycleLengthsForChart: [28, 45, 38, 30, 40],
        cycleRangeMin: 28,
        cycleRangeMax: 45,
        medianCycleLength: 38,
        adherencePercentage: 95,
        totalHeavyWithClotsDays: 2,
        floodingEventsCount: 0,
        spottingColorProfile: 'N/A',
        cycleRows: [
          ['1', 'Jan 1, 2026', 'Jan 30, 2026', '30 days', 'Medium', 'None']
        ],
        symptomPhaseClusters: [
          ['Anxiety', '4', 'Luteal Alignment (PMDD Pattern)']
        ],
        treatmentBenchmark: null,
        rotterdamOvulatoryDysfunction: true,
        rotterdamHyperandrogenism: true,
        rotterdamPCOM: true,
      );
      final args = PdfExportArgs(payload, const PdfExportOptions());
      final pdfBytes = await DoctorPdfGenerator.generatePdfBytes(args);
      
      expect(pdfBytes, isNotNull);
      expect(pdfBytes.isNotEmpty, isTrue);
    });
  });
}
