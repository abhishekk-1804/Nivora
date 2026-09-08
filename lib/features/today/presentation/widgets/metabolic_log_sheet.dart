import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/database_provider.dart';

class MetabolicLogSheet extends ConsumerStatefulWidget {
  const MetabolicLogSheet({super.key});

  @override
  ConsumerState<MetabolicLogSheet> createState() => _MetabolicLogSheetState();
}

class _MetabolicLogSheetState extends ConsumerState<MetabolicLogSheet> {
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _waistController = TextEditingController();
  final TextEditingController _hipController = TextEditingController();

  /// T2-4: false = metric (kg, cm), true = imperial (lb, in).
  /// Cleared on toggle to avoid silent unit conversion errors.
  bool _useImperial = false;

  final List<String> _selectedSigns = [];
  final List<String> _commonSigns = [
    'Dark skin patches (neck/armpits)',
    'Severe Sugar Cravings',
    'Extreme Fatigue',
    'Skin Tags',
  ];

  @override
  void dispose() {
    _weightController.dispose();
    _waistController.dispose();
    _hipController.dispose();
    super.dispose();
  }

  // ── Unit conversion helpers ───────────────────────────────────────────────

  /// Parse weight field and convert to kg (always stored in kg internally).
  double? _parseWeight() {
    final v = double.tryParse(_weightController.text.trim());
    if (v == null) return null;
    return _useImperial ? v * 0.453592 : v;
  }

  /// Parse a measurement field and convert to cm (always stored in cm).
  double? _parseCm(TextEditingController ctrl) {
    final v = double.tryParse(ctrl.text.trim());
    if (v == null) return null;
    return _useImperial ? v * 2.54 : v;
  }

  bool get _hasAnyInput =>
      _weightController.text.trim().isNotEmpty ||
      _waistController.text.trim().isNotEmpty ||
      _hipController.text.trim().isNotEmpty ||
      _selectedSigns.isNotEmpty;

  // ── Range validation ──────────────────────────────────────────────────────

  String? _validateInputs() {
    final weightText = _weightController.text.trim();
    if (weightText.isNotEmpty) {
      final parsed = double.tryParse(weightText);
      if (parsed == null) {
        return 'Please enter a valid number for Weight.';
      }
      final wKg = _useImperial ? parsed * 0.453592 : parsed;
      if (wKg < 10 || wKg > 500) {
        return _useImperial
            ? 'Weight must be between 22 lb and 1,100 lb.'
            : 'Weight must be between 10 kg and 500 kg.';
      }
    }

    final waistText = _waistController.text.trim();
    if (waistText.isNotEmpty) {
      final parsed = double.tryParse(waistText);
      if (parsed == null) {
        return 'Please enter a valid number for Waist.';
      }
      final waistCm = _useImperial ? parsed * 2.54 : parsed;
      if (waistCm < 30 || waistCm > 300) {
        return _useImperial
            ? 'Waist must be between 12 in and 118 in.'
            : 'Waist must be between 30 cm and 300 cm.';
      }
    }

    final hipText = _hipController.text.trim();
    if (hipText.isNotEmpty) {
      final parsed = double.tryParse(hipText);
      if (parsed == null) {
        return 'Please enter a valid number for Hip.';
      }
      final hipCm = _useImperial ? parsed * 2.54 : parsed;
      if (hipCm < 30 || hipCm > 300) {
        return _useImperial
            ? 'Hip must be between 12 in and 118 in.'
            : 'Hip must be between 30 cm and 300 cm.';
      }
    }
    return null;
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!_hasAnyInput) {
      if (mounted) Navigator.pop(context);
      return;
    }

    final error = _validateInputs();
    if (error != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
      return;
    }

    final signs = _selectedSigns.isNotEmpty ? _selectedSigns.join(', ') : null;
    final db = ref.read(appDatabaseProvider);
    await db.metabolicLogDao.addLog(
      weight: _parseWeight(),
      waistCircumference: _parseCm(_waistController),
      hipCircumference: _parseCm(_hipController),
      signs: signs,
    );

    if (mounted) Navigator.pop(context);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final weightLabel = _useImperial ? 'Weight (lb)' : 'Weight (kg)';
    final waistLabel  = _useImperial ? 'Waist (in)'  : 'Waist (cm)';
    final hipLabel    = _useImperial ? 'Hip (in)'    : 'Hip (cm)';

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: MediaQuery.of(context).padding.top + 24,
        bottom: MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom +
            24,
      ),
      decoration: const BoxDecoration(
        color: AppColors.warmIvory,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
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
            const SizedBox(height: 20),

            // Title + unit toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Metabolic Metrics',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.deepInk,
                  ),
                ),
                // Metric ↔ Imperial animated pill toggle
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _useImperial = !_useImperial;
                      // Clear fields on switch to prevent silent conversion errors.
                      _weightController.clear();
                      _waistController.clear();
                      _hipController.clear();
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: _useImperial
                          ? AppColors.brandAction.withValues(alpha: 0.1)
                          : AppColors.cardBorder.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _useImperial
                            ? AppColors.brandAction
                            : AppColors.lightBorder,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _useImperial ? 'lb / in' : 'kg / cm',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _useImperial
                                ? AppColors.brandAction
                                : AppColors.mutedSage,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.swap_horiz,
                          size: 14,
                          color: _useImperial
                              ? AppColors.brandAction
                              : AppColors.mutedSage,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Body Composition
            const Text(
              'Body Composition',
              style: TextStyle(
                  fontWeight: FontWeight.w600, color: AppColors.deepInk),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _weightController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: weightLabel,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                suffixText: _useImperial ? 'lb' : 'kg',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _waistController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: waistLabel,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      suffixText: _useImperial ? 'in' : 'cm',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _hipController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: hipLabel,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      suffixText: _useImperial ? 'in' : 'cm',
                    ),
                  ),
                ),
              ],
            ),
            // Imperial hint
            if (_useImperial) ...[
              const SizedBox(height: 8),
              Row(
                children: const [
                  Icon(Icons.info_outline, size: 13, color: AppColors.mutedSage),
                  SizedBox(width: 6),
                  Text(
                    'Values are stored in metric (kg / cm) internally.',
                    style: TextStyle(fontSize: 11, color: AppColors.mutedSage),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),

            // Clinical Signs
            const Text(
              'Clinical Signs (Insulin Resistance)',
              style: TextStyle(
                  fontWeight: FontWeight.w600, color: AppColors.deepInk),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _commonSigns.map((sign) {
                final isSelected = _selectedSigns.contains(sign);
                return FilterChip(
                  label: Text(sign),
                  selected: isSelected,
                  onSelected: (val) {
                    HapticFeedback.lightImpact();
                    setState(() {
                      if (val) {
                        _selectedSigns.add(sign);
                      } else {
                        _selectedSigns.remove(sign);
                      }
                    });
                  },
                  selectedColor: AppColors.brandAction.withValues(alpha: 0.1),
                  checkmarkColor: AppColors.brandAction,
                  labelStyle: TextStyle(
                    color:
                        isSelected ? AppColors.brandAction : AppColors.deepInk,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandAction,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text(
                'Save Log',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
