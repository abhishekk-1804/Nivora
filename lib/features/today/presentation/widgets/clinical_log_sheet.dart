import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/database_provider.dart';
import '../../../../core/database/app_database.dart';
import 'package:drift/drift.dart' as drift;

class ClinicalLogSheet extends ConsumerStatefulWidget {
  const ClinicalLogSheet({super.key});

  @override
  ConsumerState<ClinicalLogSheet> createState() => _ClinicalLogSheetState();
}

class _ClinicalLogSheetState extends ConsumerState<ClinicalLogSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Lab Results Form State
  DateTime _labDate = DateTime.now();
  String _selectedTest = 'Fasting Insulin';
  final TextEditingController _labValueCtrl = TextEditingController();
  final TextEditingController _labNotesCtrl = TextEditingController();

  final List<String> _commonTests = [
    'Fasting Insulin',
    'Total Testosterone',
    'Free Androgen Index',
    'TSH (Thyroid)',
    'HbA1c',
    'LH / FSH Ratio',
    'Fasting Glucose',
    'DHEA-S',
  ];

  // Interventions Form State
  DateTime _interventionDate = DateTime.now();
  final TextEditingController _interventionTitleCtrl = TextEditingController();
  final TextEditingController _interventionNotesCtrl = TextEditingController();

  // Clinical Profile / Rotterdam State
  bool _hasPCOM = false;
  String? _selectedPhenotype;

  final List<Map<String, String>> _phenotypes = [
    {
      'code': 'A',
      'title': 'Phenotype A (Classic)',
      'desc': 'Irregular Cycles + High Androgens + Polycystic Ovaries'
    },
    {
      'code': 'B',
      'title': 'Phenotype B (Classic)',
      'desc': 'Irregular Cycles + High Androgens (No PCOM ultrasound sign)'
    },
    {
      'code': 'C',
      'title': 'Phenotype C (Ovulatory)',
      'desc': 'Regular Cycles + High Androgens + Polycystic Ovaries'
    },
    {
      'code': 'D',
      'title': 'Phenotype D (Non-Androgenic)',
      'desc': 'Irregular Cycles + Polycystic Ovaries (Normal Androgens)'
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadExistingProfile();
  }

  Future<void> _loadExistingProfile() async {
    final profile = await ref.read(clinicalProfileDaoProvider).getProfile();
    if (profile != null) {
      setState(() {
        _hasPCOM = profile.hasPCOM;
        _selectedPhenotype = profile.phenotype;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _labValueCtrl.dispose();
    _labNotesCtrl.dispose();
    _interventionTitleCtrl.dispose();
    _interventionNotesCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectLabDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _labDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _labDate = picked);
    }
  }

  Future<void> _selectInterventionDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _interventionDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _interventionDate = picked);
    }
  }

  Future<void> _saveLabResult() async {
    final value = _labValueCtrl.text.trim();
    if (value.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a test value (e.g. 14.2 uIU/mL)'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    await ref.read(labResultDaoProvider).insertLabResult(
      date: _labDate,
      testName: _selectedTest,
      value: value,
      notes: _labNotesCtrl.text.trim().isEmpty ? null : _labNotesCtrl.text.trim(),
    );

    HapticFeedback.mediumImpact();
    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lab result saved successfully!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _saveIntervention() async {
    final title = _interventionTitleCtrl.text.trim();
    if (title.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a treatment title (e.g. Started Metformin)'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    final db = ref.read(appDatabaseProvider);
    // Direct Drift table insert using the companion
    await db.into(db.treatmentInterventions).insert(
          TreatmentInterventionsCompanion.insert(
            title: title,
            startDate: _interventionDate,
            notes: drift.Value(_interventionNotesCtrl.text.trim().isEmpty
                ? null
                : _interventionNotesCtrl.text.trim()),
          ),
        );

    HapticFeedback.mediumImpact();
    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Treatment intervention recorded!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _saveClinicalProfile() async {
    await ref.read(clinicalProfileDaoProvider).saveProfile(
      _selectedPhenotype,
      _hasPCOM,
    );

    HapticFeedback.mediumImpact();
    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Clinical Profile updated!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.warmIvory,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: Container(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: MediaQuery.of(context).padding.top + 20,
          bottom: MediaQuery.of(context).viewInsets.bottom +
              MediaQuery.of(context).padding.bottom +
              24,
        ),
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
        
            const Text(
              'Clinical & Medical Logs',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.deepInk,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
        
            // Custom styled TabBar (Notion/Cal.com style)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.cardBorder.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                labelColor: AppColors.deepInk,
                unselectedLabelColor: AppColors.mutedSage,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                tabs: const [
                  Tab(text: 'Lab Results'),
                  Tab(text: 'Treatments'),
                  Tab(text: 'Profile / PCOM'),
                ],
              ),
            ),
            const SizedBox(height: 24),
        
            // Tab content
            Flexible(
              child: SingleChildScrollView(
                child: SizedBox(
                  height: 380,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildLabTab(),
                      _buildInterventionTab(),
                      _buildProfileTab(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Date of Test',
              style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.deepInk)),
          subtitle: Text(DateFormat('MMMM d, yyyy').format(_labDate)),
          trailing: const Icon(Icons.calendar_today, color: AppColors.mutedSage, size: 20),
          onTap: _selectLabDate,
        ),
        const Divider(color: AppColors.lightBorder),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _selectedTest,
          decoration: InputDecoration(
            labelText: 'Biomarker / Test Name',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          items: _commonTests
              .map((test) => DropdownMenuItem(value: test, child: Text(test)))
              .toList(),
          onChanged: (val) {
            if (val != null) setState(() => _selectedTest = val);
          },
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _labValueCtrl,
          decoration: InputDecoration(
            labelText: 'Value (e.g. 12.4 uIU/mL, 85 ng/dL)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _labNotesCtrl,
          decoration: InputDecoration(
            labelText: 'Notes (optional)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const Spacer(),
        ElevatedButton(
          onPressed: _saveLabResult,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.brandAction,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: const Text('Save Lab Result',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildInterventionTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Start Date',
              style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.deepInk)),
          subtitle: Text(DateFormat('MMMM d, yyyy').format(_interventionDate)),
          trailing: const Icon(Icons.calendar_today, color: AppColors.mutedSage, size: 20),
          onTap: _selectInterventionDate,
        ),
        const Divider(color: AppColors.lightBorder),
        const SizedBox(height: 8),
        TextField(
          controller: _interventionTitleCtrl,
          decoration: InputDecoration(
            labelText: 'Treatment/Intervention Title (e.g. Started Metformin 500mg)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _interventionNotesCtrl,
          decoration: InputDecoration(
            labelText: 'Notes/Dose details (optional)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          maxLines: 3,
        ),
        const Spacer(),
        ElevatedButton(
          onPressed: _saveIntervention,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.brandAction,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: const Text('Record Intervention',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildProfileTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Ultrasound confirmed polycystic ovaries (PCOM) Switch
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text('Ultrasound Confirmed PCOM',
              style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.deepInk)),
          subtitle: const Text('Ultrasound scans confirm polycystic ovarian morphology'),
          value: _hasPCOM,
          activeTrackColor: AppColors.brandAction.withValues(alpha: 0.5),
          activeThumbColor: AppColors.brandAction,
          onChanged: (val) => setState(() => _hasPCOM = val),
        ),
        const Divider(color: AppColors.lightBorder),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _selectedPhenotype,
          decoration: InputDecoration(
            labelText: 'Rotterdam Phenotype',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Text('Not Diagnosed / Unknown'),
            ),
            ..._phenotypes.map((p) => DropdownMenuItem<String>(
                  value: p['code'],
                  child: Text(p['title']!),
                )),
          ],
          onChanged: (val) {
            setState(() => _selectedPhenotype = val);
          },
        ),
        if (_selectedPhenotype != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.brandAction.withValues(alpha: 0.05),
              border: Border.all(color: AppColors.brandAction.withValues(alpha: 0.12)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _phenotypes.firstWhere((p) => p['code'] == _selectedPhenotype)['desc']!,
              style: const TextStyle(fontSize: 12, color: AppColors.brandAction, height: 1.4),
            ),
          ),
        ],
        const Spacer(),
        ElevatedButton(
          onPressed: _saveClinicalProfile,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.brandAction,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: const Text('Update Clinical Profile',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
