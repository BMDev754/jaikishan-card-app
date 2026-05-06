import 'package:shared_preferences/shared_preferences.dart';

class OnboardingService {
  static const String _isFirstTimeKey = 'is_first_time_user';
  static const String _profileCompletedKey = 'profile_completed';
  static const String _passcodeSetKey = 'passcode_set';
  static const String _appLockEnabledKey = 'app_lock_enabled';
  static const String _walletIntroShownKey = 'wallet_intro_shown';
  static const String _onboardingCompletedKey = 'onboarding_completed';

  // Check if user is first time user
  static Future<bool> isFirstTimeUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isFirstTimeKey) ?? true;
  }

  // Mark user as not first time
  static Future<void> markNotFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isFirstTimeKey, false);
  }

  // Check if profile is completed
  static Future<bool> isProfileCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_profileCompletedKey) ?? false;
  }

  // Mark profile as completed
  static Future<void> markProfileCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_profileCompletedKey, true);
  }

  // Check if passcode is set
  static Future<bool> isPasscodeSet() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_passcodeSetKey) ?? false;
  }

  // Mark passcode as set
  static Future<void> markPasscodeSet() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_passcodeSetKey, true);
  }

  // Check if app lock is enabled
  static Future<bool> isAppLockEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_appLockEnabledKey) ?? false;
  }

  // Mark app lock as enabled
  static Future<void> markAppLockEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_appLockEnabledKey, true);
  }

  // Check if wallet intro is shown
  static Future<bool> isWalletIntroShown() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_walletIntroShownKey) ?? false;
  }

  // Mark wallet intro as shown
  static Future<void> markWalletIntroShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_walletIntroShownKey, true);
  }

  // Check if onboarding is completed
  static Future<bool> isOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingCompletedKey) ?? false;
  }

  // Mark onboarding as completed
  static Future<void> markOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingCompletedKey, true);
  }

  // Get next onboarding step
  static Future<OnboardingStep> getNextStep() async {
    if (await isOnboardingCompleted()) {
      return OnboardingStep.completed;
    }

    if (!await isProfileCompleted()) {
      return OnboardingStep.profile;
    }

    if (!await isPasscodeSet()) {
      return OnboardingStep.passcode;
    }

    if (!await isAppLockEnabled()) {
      return OnboardingStep.appLock;
    }

    if (!await isWalletIntroShown()) {
      return OnboardingStep.walletIntro;
    }

    // Mark as completed if all steps are done
    await markOnboardingCompleted();
    return OnboardingStep.completed;
  }

  // Reset onboarding (for testing purposes)
  static Future<void> resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isFirstTimeKey, true);
    await prefs.setBool(_profileCompletedKey, false);
    await prefs.setBool(_passcodeSetKey, false);
    await prefs.setBool(_appLockEnabledKey, false);
    await prefs.setBool(_walletIntroShownKey, false);
    await prefs.setBool(_onboardingCompletedKey, false);
  }
}

enum OnboardingStep {
  profile,
  passcode,
  appLock,
  walletIntro,
  completed,
}
