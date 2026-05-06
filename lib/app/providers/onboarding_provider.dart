import 'package:flutter/material.dart';
import '../services/onboarding_service.dart';

class OnboardingProvider with ChangeNotifier {
  bool _isFirstTime = true;
  OnboardingStep _currentStep = OnboardingStep.profile;
  bool _isOnboardingActive = false;

  bool get isFirstTime => _isFirstTime;
  OnboardingStep get currentStep => _currentStep;
  bool get isOnboardingActive => _isOnboardingActive;

  // Initialize onboarding status
  Future<void> initializeOnboarding() async {
    _isFirstTime = await OnboardingService.isFirstTimeUser();
    _currentStep = await OnboardingService.getNextStep();
    _isOnboardingActive = _isFirstTime && _currentStep != OnboardingStep.completed;
    notifyListeners();
  }

  // Start onboarding flow
  Future<void> startOnboarding() async {
    _isOnboardingActive = true;
    _currentStep = await OnboardingService.getNextStep();
    notifyListeners();
  }

  // Complete profile step
  Future<void> completeProfileStep() async {
    await OnboardingService.markProfileCompleted();
    await _moveToNextStep();
  }

  // Complete passcode step
  Future<void> completePasscodeStep() async {
    await OnboardingService.markPasscodeSet();
    await _moveToNextStep();
  }

  // Complete app lock step
  Future<void> completeAppLockStep() async {
    await OnboardingService.markAppLockEnabled();
    await _moveToNextStep();
  }

  // Complete wallet intro step
  Future<void> completeWalletIntroStep() async {
    await OnboardingService.markWalletIntroShown();
    await _moveToNextStep();
  }

  // Move to next step
  Future<void> _moveToNextStep() async {
    _currentStep = await OnboardingService.getNextStep();
    
    if (_currentStep == OnboardingStep.completed) {
      await OnboardingService.markNotFirstTime();
      await OnboardingService.markOnboardingCompleted();
      _isFirstTime = false;
      _isOnboardingActive = false;
    }
    
    notifyListeners();
  }

  // Skip onboarding (emergency)
  Future<void> skipOnboarding() async {
    await OnboardingService.markNotFirstTime();
    await OnboardingService.markOnboardingCompleted();
    _isFirstTime = false;
    _isOnboardingActive = false;
    notifyListeners();
  }

  // Reset onboarding (for testing)
  Future<void> resetOnboarding() async {
    await OnboardingService.resetOnboarding();
    _isFirstTime = true;
    _currentStep = OnboardingStep.profile;
    _isOnboardingActive = true;
    notifyListeners();
  }

  // Force start onboarding (for testing)
  Future<void> forceStartOnboarding() async {
    await OnboardingService.resetOnboarding();
    await initializeOnboarding();
    _isOnboardingActive = true;
    notifyListeners();
  }

  // Check if specific step is completed
  Future<bool> isStepCompleted(OnboardingStep step) async {
    switch (step) {
      case OnboardingStep.profile:
        return await OnboardingService.isProfileCompleted();
      case OnboardingStep.passcode:
        return await OnboardingService.isPasscodeSet();
      case OnboardingStep.appLock:
        return await OnboardingService.isAppLockEnabled();
      case OnboardingStep.walletIntro:
        return await OnboardingService.isWalletIntroShown();
      case OnboardingStep.completed:
        return await OnboardingService.isOnboardingCompleted();
    }
  }
}
