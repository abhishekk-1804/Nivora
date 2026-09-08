import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/database/app_database.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/notifications/notification_service.dart';

class RoutineSetupSheet extends ConsumerStatefulWidget {
  /// Pass an existing [routine] to open in edit mode; null = add new medicine.
  final Routine? routine;
  const RoutineSetupSheet({super.key, this.routine});

  @override
  ConsumerState<RoutineSetupSheet> createState() => _RoutineSetupSheetState();
}

class _RoutineSetupSheetState extends ConsumerState<RoutineSetupSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _doseController;
  late final TextEditingController _notesController;
  late String _selectedRegimen;
  late TimeOfDay _reminderTime;
  late DateTime _startDate;
  late String _selectedDuration;
  DateTime? _customEndDate;
  bool _isSaving = false;

  bool get _isEditing => widget.routine != null;

  @override
  void initState() {
    super.initState();
    final r = widget.routine;
    _nameController = TextEditingController(text: r?.name ?? '');
    _doseController = TextEditingController(text: r?.dose ?? '');
    _notesController = TextEditingController(text: r?.notes ?? '');
    _selectedRegimen = r?.regimenType ?? 'Daily';
    _startDate = r?.startDate ?? DateTime.now();

    // Parse reminder time from stored "HH:mm" string
    if (r != null) {
      final parts = r.reminderTime.split(':');
      _reminderTime = TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 20,
        minute: int.tryParse(parts.elementAtOrNull(1) ?? '0') ?? 0,
      );
    } else {
      _reminderTime = const TimeOfDay(hour: 20, minute: 0);
    }

    // Duration
    _selectedDuration = 'Indefinite';
    if (r?.endDate != null) {
      _customEndDate = r!.endDate;
      _selectedDuration = 'Custom';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _doseController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // ── Pickers ────────────────────────────────────────────────────────────────

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.deepInk,
            onPrimary: AppColors.warmIvory,
            surface: AppColors.warmIvory,
            onSurface: AppColors.deepInk,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _reminderTime = picked);
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.deepInk,
            onPrimary: AppColors.warmIvory,
            surface: AppColors.warmIvory,
            onSurface: AppColors.deepInk,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _selectCustomEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _customEndDate ?? _startDate.add(const Duration(days: 30)),
      firstDate: _startDate,
      lastDate: DateTime(2101),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.deepInk,
            onPrimary: AppColors.warmIvory,
            surface: AppColors.warmIvory,
            onSurface: AppColors.deepInk,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _customEndDate = picked;
        _selectedDuration = 'Custom';
      });
    } else if (_selectedDuration == 'Custom' && _customEndDate == null) {
      setState(() => _selectedDuration = 'Indefinite');
    }
  }

  // ── Save ───────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    final name = _nameController.text.trim().isEmpty ? 'My Routine' : _nameController.text.trim();
    final timeStr =
        '${_reminderTime.hour.toString().padLeft(2, '0')}:${_reminderTime.minute.toString().padLeft(2, '0')}';

    DateTime? calculatedEndDate;
    if (_selectedDuration == '1 Month') {
      calculatedEndDate = _startDate.add(const Duration(days: 30));
    } else if (_selectedDuration == '3 Months') {
      calculatedEndDate = _startDate.add(const Duration(days: 90));
    } else if (_selectedDuration == '6 Months') {
      calculatedEndDate = _startDate.add(const Duration(days: 180));
    } else if (_selectedDuration == 'Custom') {
      calculatedEndDate = _customEndDate;
    }

    // Guard: end date must be after start date
    if (calculatedEndDate != null && !calculatedEndDate.isAfter(_startDate)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('End date must be after the start date.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    final dao = ref.read(routineDaoProvider);

    setState(() => _isSaving = true);
    
    try {
      if (_isEditing) {
        await dao.updateRoutine(
          id: widget.routine!.id,
          name: name,
          regimenType: _selectedRegimen,
          startDate: _startDate,
          reminderTime: timeStr,
          dose: _doseController.text.trim().isEmpty ? null : _doseController.text.trim(),
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          endDate: calculatedEndDate,
        );
        await NotificationService.scheduleRoutineReminder(
          routineId: widget.routine!.id,
          routineName: name,
          hour: _reminderTime.hour,
          minute: _reminderTime.minute,
          regimenType: _selectedRegimen,
          startDate: _startDate,
        );
      } else {
        final routineId = await dao.insertRoutine(
          name: name,
          regimenType: _selectedRegimen,
          startDate: _startDate,
          reminderTime: timeStr,
          dose: _doseController.text.trim().isEmpty ? null : _doseController.text.trim(),
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          endDate: calculatedEndDate,
        );
        await NotificationService.scheduleRoutineReminder(
          routineId: routineId,
          routineName: name,
          hour: _reminderTime.hour,
          minute: _reminderTime.minute,
          regimenType: _selectedRegimen,
          startDate: _startDate,
        );
      }
      // B-03 fix: only dismiss the sheet on success.
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      // Show error instead of silently closing the sheet.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not save medication: ${e.toString()}'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isToday = DateUtils.isSameDay(_startDate, DateTime.now());
    final isFuture = _startDate.isAfter(DateTime.now());

    return Material(
      color: AppColors.warmIvory,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: Padding(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 48,
          left: 24,
          right: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom + 24,
        ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isEditing ? 'Edit Medication' : 'Add Medication',
              style: const TextStyle(
                color: AppColors.deepInk,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            // Name
            TextField(
              controller: _nameController,
              maxLength: 50,
              decoration: InputDecoration(
                labelText: 'Name (e.g. Metformin, Inositol)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 16),

            // Dose
            TextField(
              controller: _doseController,
              decoration: InputDecoration(
                labelText: 'Dose (e.g. 500mg, 1 capsule)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 16),

            // Notes
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            // Regimen Type
            const Text(
              'Schedule',
              style: TextStyle(color: AppColors.deepInk, fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Column(
              children: [
                _buildRadioTile(
                  title: 'Standard 21/7 Regimen',
                  subtitle: '21 active days followed by 7 break days',
                  value: 'Cyclic_21_7',
                ),
                _buildRadioTile(
                  title: 'Continuous Daily',
                  subtitle: 'Daily medication without breaks',
                  value: 'Daily',
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Start Date
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Start Date',
                  style: TextStyle(color: AppColors.deepInk, fontWeight: FontWeight.w600)),
              subtitle: Text(DateFormat('MMM d, yyyy').format(_startDate)),
              trailing: const Icon(Icons.calendar_today, color: AppColors.mutedSage),
              onTap: _selectDate,
            ),

            // Fresh user contextual hint
            if (isToday || isFuture)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.brandAction.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.brandAction.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline, size: 16, color: AppColors.brandAction),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isToday
                              ? 'Starting today — Day 1 will be logged from today onwards. You can backdate if your doctor prescribed earlier.'
                              : 'Future start date set — tracking will begin when that day arrives.',
                          style: const TextStyle(
                            color: AppColors.brandAction,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const Divider(color: AppColors.lightBorder),

            // Duration
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Duration',
                  style: TextStyle(color: AppColors.deepInk, fontWeight: FontWeight.w600)),
              subtitle: Text(
                _selectedDuration == 'Custom' && _customEndDate != null
                    ? 'Until ${DateFormat('MMM d, yyyy').format(_customEndDate!)}'
                    : _selectedDuration,
              ),
              trailing: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.mutedSage),
                  value: _selectedDuration,
                  items: ['Indefinite', '1 Month', '3 Months', '6 Months', 'Custom']
                      .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                      .toList(),
                  onChanged: (newValue) {
                    if (newValue == 'Custom') {
                      _selectCustomEndDate();
                    } else if (newValue != null) {
                      setState(() => _selectedDuration = newValue);
                    }
                  },
                ),
              ),
            ),
            const Divider(color: AppColors.lightBorder),

            // Reminder Time
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Daily Reminder',
                  style: TextStyle(color: AppColors.deepInk, fontWeight: FontWeight.w600)),
              subtitle: Text(_reminderTime.format(context)),
              trailing: const Icon(Icons.access_time, color: AppColors.mutedSage),
              onTap: _selectTime,
            ),
            const SizedBox(height: 32),

            // Save Button
            ElevatedButton(
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandAction,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.lightBorder.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.brandAction),
                    )
                  : Text(
                      _isEditing ? 'Update Medication' : 'Save Medication',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildRadioTile({
    required String title,
    required String subtitle,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: _selectedRegimen == value ? AppColors.brandAction : AppColors.lightBorder,
            width: _selectedRegimen == value ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            setState(() => _selectedRegimen = value);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Icon(
                  _selectedRegimen == value
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: _selectedRegimen == value ? AppColors.brandAction : AppColors.mutedSage,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.deepInk),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(color: AppColors.mutedSage, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

