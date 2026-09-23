import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:nivora_app/features/report/service/doctor_pdf_generator.dart';
import 'package:nivora_app/features/report/domain/report_payload.dart';

class OfflineHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    throw Exception('NETWORK CALL ATTEMPTED! The app must remain 100% offline.');
  }
}

void main() {
  group('Offline Resilience Tests', () {
    setUpAll(() {
      // Force all network calls to throw exceptions
      HttpOverrides.global = OfflineHttpOverrides();
    });

    test('PDF Generator must execute completely offline without any network dependencies', () async {
      // Create a dummy payload
      final payload = DoctorReportData(
        dateRange: 'Jan 2026 - Jun 2026',
        totalCycles: 5,
        cycleLengthsForChart: [28, 32, 30, 29, 31],
        cycleRangeMin: 28,
        cycleRangeMax: 32,
        medianCycleLength: 30,
        adherencePercentage: 95,
        totalHeavyWithClotsDays: 2,
        floodingEventsCount: 0,
        spottingColorProfile: 'N/A',
        cycleRows: [
          ['1', 'Jan 1, 2026', 'Jan 30, 2026', '30 days', 'Medium', 'None']
        ],
        symptomPhaseClusters: [],
        treatmentBenchmark: null,
      );
      try {
        final regularFontBytes = File('assets/fonts/Roboto-Regular.ttf').readAsBytesSync();
        final boldFontBytes = File('assets/fonts/Roboto-Bold.ttf').readAsBytesSync();

        final args = PdfExportArgs(
          payload,
          const PdfExportOptions(),
          regularFontBytes: regularFontBytes,
          boldFontBytes: boldFontBytes,
        );
        final pdfBytes = await DoctorPdfGenerator.generatePdfBytes(args);
        
        expect(pdfBytes, isNotNull);
        expect(pdfBytes.isNotEmpty, isTrue);
      } catch (e) {
        if (e.toString().contains('NETWORK CALL ATTEMPTED')) {
          fail('Offline Resilience Failed: A package attempted to make a network call during PDF generation.');
        } else {
          rethrow;
        }
      }
    });
  });
}
