import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/preference_keys.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden');
});

class IsPcosGoalNotifier extends Notifier<bool> {
  @override
  bool build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getBool(PreferenceKeys.isPcosGoal) ?? false;
  }
  
  @override
  set state(bool value) => super.state = value;
}

final isPcosGoalProvider = NotifierProvider<IsPcosGoalNotifier, bool>(() => IsPcosGoalNotifier());

class IsRoutineGoalNotifier extends Notifier<bool> {
  @override
  bool build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getBool(PreferenceKeys.isRoutineGoal) ?? false;
  }
  @override
  set state(bool value) => super.state = value;
}

final isRoutineGoalProvider = NotifierProvider<IsRoutineGoalNotifier, bool>(() => IsRoutineGoalNotifier());

class AdvancedClinicalTrackingNotifier extends Notifier<bool> {
  @override
  bool build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final isAdvanced = prefs.getBool(PreferenceKeys.advancedClinicalTracking);
    if (isAdvanced != null) return isAdvanced;
    
    return prefs.getBool(PreferenceKeys.isPcosGoal) ?? false;
  }
  @override
  set state(bool value) => super.state = value;
}

final advancedClinicalTrackingProvider = NotifierProvider<AdvancedClinicalTrackingNotifier, bool>(() => AdvancedClinicalTrackingNotifier());
