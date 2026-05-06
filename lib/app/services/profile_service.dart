import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ProfileService {
  static const String _profileDataKey = 'user_profile_data';
  static const String _profileImageKey = 'user_profile_image';
  
  static ProfileService? _instance;
  static ProfileService get instance => _instance ??= ProfileService._();
  ProfileService._();

  // Profile data model
  Map<String, dynamic> _defaultProfile = {
    'name': '',
    'email': '',
    'phone': '',
    'address': '',
    'dateOfBirth': '',
    'gender': '',
    'occupation': '',
    'emergencyContact': '',
    'profileImagePath': '',
  };

  // Get profile data
  Future<Map<String, dynamic>> get profileData async {
    final prefs = await SharedPreferences.getInstance();
    final profileJson = prefs.getString(_profileDataKey);
    
    if (profileJson != null) {
      return Map<String, dynamic>.from(json.decode(profileJson));
    }
    
    // Return default profile if no data exists
    return Map<String, dynamic>.from(_defaultProfile);
  }

  // Save profile data
  Future<void> saveProfileData(Map<String, dynamic> profileData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileDataKey, json.encode(profileData));
  }

  // Get specific profile field
  Future<String> getProfileField(String field) async {
    final profile = await profileData;
    return profile[field]?.toString() ?? '';
  }

  // Update specific profile field
  Future<void> updateProfileField(String field, String value) async {
    final profile = await profileData;
    profile[field] = value;
    await saveProfileData(profile);
  }

  // Get profile image path
  Future<String?> get profileImagePath async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_profileImageKey);
  }

  // Save profile image path
  Future<void> saveProfileImagePath(String imagePath) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileImageKey, imagePath);
    
    // Also update in profile data
    await updateProfileField('profileImagePath', imagePath);
  }

  // Clear profile data (for logout)
  Future<void> clearProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_profileDataKey);
    await prefs.remove(_profileImageKey);
  }

  // Get user's name
  Future<String> get userName async {
    return await getProfileField('name');
  }

  // Get user's email
  Future<String> get userEmail async {
    return await getProfileField('email');
  }

  // Get user's phone
  Future<String> get userPhone async {
    return await getProfileField('phone');
  }

  // Initialize with default data if needed
  Future<void> initializeDefaultProfile() async {
    final profile = await profileData;
    if (profile.isEmpty || profile['name'].isEmpty) {
      await saveProfileData(_defaultProfile);
    }
  }
}
