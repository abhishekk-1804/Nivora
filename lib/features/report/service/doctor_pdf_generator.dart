import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../domain/report_payload.dart';

class PdfExportArgs {
  final DoctorReportData data;
  final PdfExportOptions options;
  const PdfExportArgs(this.data, this.options);
}

class DoctorPdfGenerator {
  /// Generates the PDF bytes. Safe to run in an Isolate via compute().
  static Future<Uint8List> generatePdfBytes(PdfExportArgs args) async {
    final data = args.data;
    final options = args.options;
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('NIVORA CLINICAL REPORT', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.deepPurple900)),
                  pw.Text('Patient ID: ____________________', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                ]
              ),
              pw.SizedBox(height: 4),
              pw.Text('Observation Window: ${data.dateRange}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
              pw.Divider(thickness: 2, color: PdfColors.deepPurple900),
              pw.SizedBox(height: 12),
            ],
          );
        },
        footer: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Divider(thickness: 0.5, color: PdfColors.grey400),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Self-reported patient record. Zero Cloud Storage.', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                  pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                ],
              ),
            ]
          );
        },
        build: (pw.Context context) {
          return [
            // Vitals Summary Grid
            if (options.includeVitals) ...[
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey50,
                  border: pw.Border.all(color: PdfColors.grey400),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                child: pw.Column(
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatBlock('Total Cycles', '${data.totalCycles} Recorded'),
                        _buildStatBlock('Median Length', data.medianCycleLength > 0 ? '${data.medianCycleLength} Days' : 'N/A'),
                        _buildStatBlock('Length Variance', data.cycleRangeMin > 0 ? '${data.cycleRangeMin}-${data.cycleRangeMax} Days' : 'N/A'),
                        _buildStatBlock('Avg Pain', '${data.averagePainScore.toStringAsFixed(1)}/10'),
                        _buildStatBlock('Peak Pain', '${data.peakPainScore}/10'),
                      ],
                    ),
                    pw.SizedBox(height: 12),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatBlock('Luteal Pain', '${data.lutealAveragePainScore.toStringAsFixed(1)}/10'),
                        _buildStatBlock('Med Adherence', '${data.adherencePercentage}%'),
                        _buildStatBlock('Flooding/Clots', '${data.totalHeavyWithClotsDays + data.floodingEventsCount} Days'),
                        _buildStatBlock('Anovulatory', '${data.anovulatoryMonthsLogged} Months'),
                        _buildStatBlock('Spotting Color', data.spottingColorProfile),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),
            ],

            if (options.includeVitals && data.cycleLengthsForChart.isNotEmpty && data.cycleLengthsForChart.length >= 2) ...[
              pw.Text('Cycle Length Variation Chart', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.deepPurple900)),
              pw.SizedBox(height: 6),
              pw.Container(
                height: 150,
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Chart(
                  grid: pw.CartesianGrid(
                    xAxis: pw.FixedAxis.fromStrings(
                      List.generate(data.cycleLengthsForChart.length, (i) => 'C${i + 1}'),
                      marginStart: 10,
                      marginEnd: 10,
                      ticks: true,
                    ),
                    yAxis: pw.FixedAxis(
                      [0, 15, 30, 45, 60, 75, 90],
                      format: (v) => v.toInt().toString(),
                      ticks: true,
                    ),
                  ),
                  datasets: [
                    pw.LineDataSet(
                      data: List.generate(
                        data.cycleLengthsForChart.length,
                        (i) => pw.PointChartValue(i.toDouble(), data.cycleLengthsForChart[i].toDouble()),
                      ),
                      legend: 'Cycle Length (Days)',
                      color: PdfColors.deepPurple,
                      pointColor: PdfColors.deepPurple800,
                      pointSize: 4,
                      lineWidth: 2,
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),
            ],

            if (options.includeMedications && data.activeMedications.isNotEmpty) ...[
              pw.Text('Active Medications / Supplements', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.Text(
                data.activeMedications.join(', '),
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.black),
              ),
              pw.SizedBox(height: 16),
            ],

            // Tier 4: Rotterdam Phenotype Screening
            pw.Text('Rotterdam Diagnostic Indicators (PCOS/PMOS)', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.deepPurple900)),
            pw.SizedBox(height: 4),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.purple50,
                border: pw.Border.all(color: PdfColors.purple200),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _buildRotterdamFlag('1. Ovulatory Dysfunction', data.rotterdamOvulatoryDysfunction),
                  _buildRotterdamFlag('2. Hyperandrogenism (Clinical)', data.rotterdamHyperandrogenism),
                  _buildRotterdamFlag('3. Polycystic Ovaries (PCOM)', data.rotterdamPCOM),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            if (options.includeVitals) ...[
              pw.Text('Recorded Menstrual Cycles (Recent)', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.TableHelper.fromTextArray(
                headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.deepPurple900),
                cellStyle: const pw.TextStyle(fontSize: 8.5),
                headers: ['Cycle', 'Start Date', 'End Date', 'Length', 'Flow', 'Symptoms'],
                data: data.cycleRows,
              ),
            ],
            
            if (options.includeSymptoms && data.symptomPhaseClusters.isNotEmpty) ...[
              pw.SizedBox(height: 16),
              pw.Text('Symptom Phase Clustering (PMDD/Dysmenorrhea Screen)', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.TableHelper.fromTextArray(
                headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.deepPurple900),
                cellStyle: const pw.TextStyle(fontSize: 8.5),
                headers: ['Symptom', 'Frequency', 'Clinical Pattern'],
                data: data.symptomPhaseClusters,
              ),
            ],

            if (data.labResultsRows.isNotEmpty) ...[
              pw.SizedBox(height: 16),
              pw.Text('Laboratory Results', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.TableHelper.fromTextArray(
                headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.deepPurple900),
                cellStyle: const pw.TextStyle(fontSize: 8.5),
                headers: ['Date', 'Test Name', 'Value', 'Notes'],
                data: data.labResultsRows,
              ),
            ],

            if (options.includeMetabolic && data.metabolicRows.isNotEmpty) ...[
              pw.SizedBox(height: 16),
              pw.Text('Metabolic & Anthropometric Trends', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.TableHelper.fromTextArray(
                headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.deepPurple900),
                cellStyle: const pw.TextStyle(fontSize: 8.5),
                headers: ['Date', 'Weight', 'W/H Ratio', 'Clinical Signs (Insulin Resistance)'],
                data: data.metabolicRows,
              ),
            ],

            if (data.treatmentBenchmark != null) ...[
              pw.SizedBox(height: 16),
              pw.Text('Treatment Benchmark: ${data.treatmentBenchmark!['title']}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  border: pw.Border.all(color: PdfColors.grey400),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(data.treatmentBenchmark!['pre']!, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.red900)),
                    pw.Text(data.treatmentBenchmark!['post']!, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.green900)),
                  ],
                ),
              ),
            ],
          ];
        },
      ),
    );

    return doc.save();
  }

  static Future<void> sharePdf(Uint8List bytes) async {
    await Printing.sharePdf(bytes: bytes, filename: 'nivora_clinical_summary.pdf');
  }

  static pw.Widget _buildStatBlock(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey600)),
        pw.SizedBox(height: 2),
        pw.Text(value, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }

  static pw.Widget _buildRotterdamFlag(String label, bool isPresent) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey800)),
        pw.SizedBox(height: 2),
        pw.Text(
          isPresent ? 'Observed Pattern' : 'Standard Baseline',
          style: pw.TextStyle(
            fontSize: 9, 
            fontWeight: pw.FontWeight.bold, 
            color: isPresent ? PdfColors.deepPurple700 : PdfColors.grey600,
          ),
        ),
      ],
    );
  }
}

