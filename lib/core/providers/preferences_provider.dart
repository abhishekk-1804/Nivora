import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden');
});

class IsPcosGoalNotifier extends Notifier<bool> {
  @override
  bool build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getBool('is_pcos_goal') ?? false;
  }
  
  @override
  set state(bool value) => super.state = value;
}

final isPcosGoalProvider = NotifierProvider<IsPcosGoalNotifier, bool>(() => IsPcosGoalNotifier());

class IsRoutineGoalNotifier extends Notifier<bool> {
  @override
  bool build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getBool('is_routine_goal') ?? false;
  }
  @override
  set state(bool value) => super.state = value;
}

final isRoutineGoalProvider = NotifierProvider<IsRoutineGoalNotifier, bool>(() => IsRoutineGoalNotifier());

class AdvancedClinicalTrackingNotifier extends Notifier<bool> {
  @override
  bool build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final isAdvanced = prefs.getBool('advanced_clinical_tracking');
    if (isAdvanced != null) return isAdvanced;
    
    return prefs.getBool('is_pcos_goal') ?? false;
  }
  @override
  set state(bool value) => super.state = value;
}

final advancedClinicalTrackingProvider = NotifierProvider<AdvancedClinicalTrackingNotifier, bool>(() => AdvancedClinicalTrackingNotifier());
