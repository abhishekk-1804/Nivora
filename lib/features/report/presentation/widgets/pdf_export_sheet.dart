import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/report_payload.dart';
import '../report_controller.dart';
import '../../../../core/providers/preferences_provider.dart';

class PdfExportConfigSheet extends ConsumerStatefulWidget {
  const PdfExportConfigSheet({super.key});

  @override
  ConsumerState<PdfExportConfigSheet> createState() => _PdfExportConfigSheetState();
}

class _PdfExportConfigSheetState extends ConsumerState<PdfExportConfigSheet> {
  bool _includeVitals = true;
  bool _includeSymptoms = true;
  bool _includeMedications = true;
  bool _includeMetabolic = true;
  bool _isGenerating = false;

  Future<void> _generate(WidgetRef ref) async {
    setState(() => _isGenerating = true);
    
    final options = PdfExportOptions(
      includeVitals: _includeVitals,
      includeSymptoms: _includeSymptoms,
      includeMedications: _includeMedications,
      includeMetabolic: _includeMetabolic,
    );

    final bytes = await ref.read(reportControllerProvider.notifier).generatePdf(options);
    
    if (mounted) {
      setState(() => _isGenerating = false);
      Navigator.of(context).pop(); // Close config sheet
      if (bytes != null) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => PdfSuccessSheet(pdfBytes: bytes),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Read preferences to conditionally show toggles
    final isRoutineGoal = ref.watch(isRoutineGoalProvider);
    final isAdvancedClinical = ref.watch(advancedClinicalTrackingProvider);

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: AppColors.warmIvory,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.lightBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'PDF Customisation',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.deepInk,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Select which insights to include in your clinical summary.',
            style: TextStyle(color: AppColors.mutedSage, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          
          _buildToggle(
            title: 'Vitals & Cycle History',
            subtitle: 'Cycle length variance, bleeding patterns, and overall statistics.',
            value: _includeVitals,
            onChanged: (val) => setState(() => _includeVitals = val),
          ),
          const Divider(color: AppColors.lightBorder),
          
          _buildToggle(
            title: 'Symptoms & Pain',
            subtitle: 'Top symptoms grouped by cycle phase and pain NRS scores.',
            value: _includeSymptoms,
            onChanged: (val) => setState(() => _includeSymptoms = val),
          ),
          
          if (isRoutineGoal) ...[
            const Divider(color: AppColors.lightBorder),
            _buildToggle(
              title: 'Medications',
              subtitle: 'Current active medications and adherence rates.',
              value: _includeMedications,
              onChanged: (val) => setState(() => _includeMedications = val),
            ),
          ],
          
          if (isAdvancedClinical) ...[
            const Divider(color: AppColors.lightBorder),
            _buildToggle(
              title: 'Metabolic Trends',
              subtitle: 'Weight, waist-to-hip ratio, and insulin resistance signs.',
              value: _includeMetabolic,
              onChanged: (val) => setState(() => _includeMetabolic = val),
            ),
          ],
          
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _isGenerating ? null : () => _generate(ref),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandAction,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: _isGenerating 
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Generate PDF', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildToggle({required String title, required String subtitle, required bool value, required ValueChanged<bool> onChanged}) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.deepInk)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.mutedSage)),
      value: value,
      onChanged: onChanged,
      activeThumbColor: AppColors.brandAction,
    );
  }
}

class PdfSuccessSheet extends StatelessWidget {
  final Uint8List pdfBytes;
  
  const PdfSuccessSheet({super.key, required this.pdfBytes});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: AppColors.warmIvory,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.lightBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Icon(Icons.check_circle_outline, color: Colors.green, size: 64),
          const SizedBox(height: 16),
          const Text(
            'PDF Generated Successfully',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.deepInk,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Your clinical summary is ready.',
            style: TextStyle(color: AppColors.mutedSage, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Printing.layoutPdf(onLayout: (format) async => pdfBytes);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.cardBg,
              foregroundColor: AppColors.deepInk,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              side: const BorderSide(color: AppColors.lightBorder),
              elevation: 0,
              alignment: Alignment.center,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.remove_red_eye_outlined),
                SizedBox(width: 8),
                Text('View PDF', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Printing.layoutPdf(onLayout: (format) async => pdfBytes, name: 'Imyra_clinical_summary.pdf');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.cardBg,
              foregroundColor: AppColors.deepInk,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              side: const BorderSide(color: AppColors.lightBorder),
              elevation: 0,
              alignment: Alignment.center,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.download_outlined),
                SizedBox(width: 8),
                Text('Save / Download', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Printing.sharePdf(bytes: pdfBytes, filename: 'Imyra_clinical_summary.pdf');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandAction,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
              alignment: Alignment.center,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.ios_share_outlined),
                SizedBox(width: 8),
                Text('Share PDF', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
