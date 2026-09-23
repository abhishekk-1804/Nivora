import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/providers/database_provider.dart';
import '../domain/report_payload.dart';
import '../service/doctor_pdf_generator.dart';
import 'package:intl/intl.dart';

part 'report_controller.g.dart';

class ReportState {
  final bool isGenerating;
  final DoctorReportData? previewData;

  ReportState({this.isGenerating = false, this.previewData});
}

@riverpod
class ReportController extends _$ReportController {
  @override
  ReportState build() {
    return ReportState();
  }

  Future<void> generatePreview(int months) async {
    final endDate = DateTime.now();
    final startDate = DateTime(endDate.year, endDate.month - months, endDate.day);
    await generatePreviewForRange(startDate, endDate, isCustom: false);
  }

  Future<void> generatePreviewForRange(DateTime startDate, DateTime endDate, {bool isCustom = true}) async {
    state = ReportState(isGenerating: true, previewData: state.previewData);
    
    final dao = ref.read(reportDaoProvider);
    String rangeLabel;
    
    if (isCustom) {
      rangeLabel = '${DateFormat('MMM d, yyyy').format(startDate)} – ${DateFormat('MMM d, yyyy').format(endDate)}';
    } else {
      final months = (endDate.difference(startDate).inDays / 30).round();
      rangeLabel = 'Last $months Months (${DateFormat('MMM yyyy').format(startDate)} - ${DateFormat('MMM yyyy').format(endDate)})';
    }
    
    try {
      final data = await dao.generateReport(
        startDate: startDate,
        endDate: endDate,
        rangeLabel: rangeLabel,
      );
      state = ReportState(isGenerating: false, previewData: data);
    } catch (e) {
      // In case of an unexpected DB query or isolate crash, recover safely
      // and clear the loader instead of leaving the UI hanging.
      state = ReportState(isGenerating: false, previewData: null);
    }
  }

  Future<Uint8List?> generatePdf(PdfExportOptions options) async {
    final data = state.previewData;
    if (data == null) return null;

    state = ReportState(isGenerating: true, previewData: data);
    
    try {
      Uint8List? regularFontBytes;
      Uint8List? boldFontBytes;
      try {
        final regByteData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
        regularFontBytes = regByteData.buffer.asUint8List(regByteData.offsetInBytes, regByteData.lengthInBytes);
        final boldByteData = await rootBundle.load('assets/fonts/Roboto-Bold.ttf');
        boldFontBytes = boldByteData.buffer.asUint8List(boldByteData.offsetInBytes, boldByteData.lengthInBytes);
      } catch (_) {
        // Fallback gracefully if bundle load is unavailable (e.g. in certain test environments)
      }

      // Offload PDF generation to a background isolate to prevent UI freezing
      final args = PdfExportArgs(
        data,
        options,
        regularFontBytes: regularFontBytes,
        boldFontBytes: boldFontBytes,
      );
      return await compute(DoctorPdfGenerator.generatePdfBytes, args);
    } finally {
      state = ReportState(isGenerating: false, previewData: data);
    }
  }
}
