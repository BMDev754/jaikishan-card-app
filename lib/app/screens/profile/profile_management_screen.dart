import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../../providers/auth_provider.dart';
import '../../providers/onboarding_provider.dart';
import '../../services/api/api_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ProfileManagementScreen extends StatefulWidget {
  final bool isOnboarding;
  
  const ProfileManagementScreen({
    super.key,
    this.isOnboarding = false,
  });

  @override
  State<ProfileManagementScreen> createState() => _ProfileManagementScreenState();
}

class _ProfileManagementScreenState extends State<ProfileManagementScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  // Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _occupationController = TextEditingController();
  final _emergencyContactController = TextEditingController();
  
  // Image handling (keeping for future use, but not storing locally)
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();
  
  // Form data
  String _selectedGender = '';
  DateTime? _selectedDateOfBirth;
  bool _isLoading = false;
  bool _hasChanges = false;
  
  // Login method tracking
  bool _isEmailLogin = false;
  bool _isPhoneLogin = false;
  String _loginEmail = '';
  String _loginPhone = '';

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    // Wait for AuthProvider to be initialized before loading data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _waitForAuthProviderAndLoadData();
    });
    _fadeController.forward();
  }

  Future<void> _waitForAuthProviderAndLoadData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Wait for AuthProvider to be initialized
    while (!authProvider.isInitialized) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    
    print('=== Profile Management - AuthProvider Initialized ===');
    print('Login status: ${authProvider.isLoggedIn}');
    print('Has API data: ${await authProvider.hasApiProfileData()}');
    print('======================================================');
    
    // Now load profile data
    await _loadProfileData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _occupationController.dispose();
    _emergencyContactController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get login data from AuthProvider to determine login method
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // First try to get data from ProcessValidateEmailOTPLoginForMember API
      final apiProfileData = await authProvider.getApiProfileData();
      
      if (apiProfileData != null) {
        print('=== Loading API Profile Data in Profile Management ===');
        print('API Data: $apiProfileData');
        print('=====================================================');
        
        // Use API data for all profile fields
        String apiName = apiProfileData['Name'] ?? '';
        String apiEmail = apiProfileData['Email'] ?? apiProfileData['email'] ?? ''; // Check both capital and lowercase
        String apiMobile = apiProfileData['Mobile'] ?? '';
        String apiAddress = apiProfileData['Address'] ?? '';
        String apiGender = apiProfileData['Gender'] ?? '';
        String apiDateOfBirth = apiProfileData['DateofBirth'] ?? '';
        
        // Clean mobile number - remove +91 prefix if present
        String cleanMobile = apiMobile;
        if (cleanMobile.startsWith('+91')) {
          cleanMobile = cleanMobile.substring(3).trim();
        }
        
        // Determine login method from AuthProvider
        String loginPhoneNumber = authProvider.phoneNumber ?? '';
        String loginEmail = authProvider.email ?? '';
        _isEmailLogin = loginEmail.isNotEmpty;
        _isPhoneLogin = loginPhoneNumber.isNotEmpty;
        _loginEmail = loginEmail;
        _loginPhone = loginPhoneNumber;
        
        setState(() {
          // Fill all fields with API data
          _nameController.text = apiName;
          _emailController.text = apiEmail.isNotEmpty ? apiEmail : loginEmail;
          _phoneController.text = cleanMobile.isNotEmpty ? cleanMobile : loginPhoneNumber.replaceAll('+91', '').trim();
          _addressController.text = apiAddress;
          _occupationController.text = 'Farmer'; // Default occupation for agricultural app
          _emergencyContactController.text = ''; // API doesn't provide emergency contact
          _selectedGender = apiGender;
          
          // Parse date of birth if available
          print('API Date of Birth raw: "$apiDateOfBirth"');
          if (apiDateOfBirth.isNotEmpty) {
            try {
              _selectedDateOfBirth = _parseDateOfBirth(apiDateOfBirth);
              print('Parsed Date of Birth: $_selectedDateOfBirth');
            } catch (e) {
              print('Error parsing date of birth: $e');
              _selectedDateOfBirth = null;
            }
          } else {
            print('API Date of Birth is empty');
            _selectedDateOfBirth = null;
          }
          
          _profileImage = null; // API doesn't provide profile image
          _isLoading = false;
          _hasChanges = false; // Reset changes flag after loading API data
        });
        
        print('=== Profile Management Data Set ===');
        print('Name: ${_nameController.text}');
        print('Email: ${_emailController.text}');
        print('Phone: ${_phoneController.text}');
        print('Address: ${_addressController.text}');
        print('Gender: $_selectedGender');
        print('DOB: $_selectedDateOfBirth');
        print('==================================');
        
        return;
      }
      
      // Fallback if API data is not available
      String loginPhoneNumber = authProvider.phoneNumber ?? '';
      String loginEmail = authProvider.email ?? '';
      
      // Determine login method based on AuthProvider data
      _isEmailLogin = loginEmail.isNotEmpty && loginPhoneNumber.isEmpty;
      _isPhoneLogin = loginPhoneNumber.isNotEmpty && loginEmail.isEmpty;
      _loginEmail = loginEmail;
      _loginPhone = loginPhoneNumber;
      
      // Clean phone number - remove +91 prefix if present for display
      String cleanLoginPhone = loginPhoneNumber;
      if (cleanLoginPhone.startsWith('+91')) {
        cleanLoginPhone = cleanLoginPhone.substring(3).trim();
      }
      
      setState(() {
        // Initialize with basic login data only
        _nameController.text = '';
        _addressController.text = '';
        _occupationController.text = 'Farmer'; // Default occupation
        _emergencyContactController.text = '';
        _selectedGender = '';
        _selectedDateOfBirth = null;
        
        // Set email field based on login method
        if (_isEmailLogin) {
          _emailController.text = _loginEmail;
        } else {
          _emailController.text = '';
        }
        
        // Set phone field based on login method  
        if (_isPhoneLogin) {
          _phoneController.text = cleanLoginPhone;
        } else {
          _phoneController.text = '';
        }
        
        _profileImage = null;
        _isLoading = false;
        _hasChanges = false; // Reset changes flag after loading data
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error loading profile data: $e');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload profile data when dependencies change (e.g., AuthProvider updates)
    _loadProfileData();
  }

  // Add method to refresh profile data manually
  Future<void> refreshProfileData() async {
    await _loadProfileData();
  }

  DateTime? _parseDateOfBirth(String dateString) {
    try {
      // Clean the input string
      dateString = dateString.trim();
      print('Parsing date string: "$dateString"');
      
      // First, try to parse ISO 8601 format (e.g., "2001-10-17T00:00:00")
      if (dateString.contains('T') || dateString.contains('-') && dateString.length >= 8) {
        try {
          // Handle ISO 8601 format
          DateTime parsedDate = DateTime.parse(dateString);
          print('Parsed ISO date: ${parsedDate.year}-${parsedDate.month}-${parsedDate.day}');
          return DateTime(parsedDate.year, parsedDate.month, parsedDate.day);
        } catch (e) {
          print('Failed to parse as ISO date: $e');
        }
      }
      
      // Try different separators for other formats
      List<String> separators = ['/', '-', '.'];
      
      for (String separator in separators) {
        if (dateString.contains(separator)) {
          List<String> dateParts = dateString.split(separator);
          if (dateParts.length == 3) {
            try {
              // First priority: yyyy/MM/dd format (our preferred format)
              if (dateParts[0].length == 4 && dateParts[1].length <= 2 && dateParts[2].length <= 2) {
                int year = int.parse(dateParts[0]);
                int month = int.parse(dateParts[1]);
                int day = int.parse(dateParts[2]);
                if (day <= 31 && month <= 12 && year > 1900 && year < 2100) {
                  print('Parsed date (yyyy/MM/dd): $year-$month-$day');
                  return DateTime(year, month, day);
                }
              }
              
              // Second priority: dd/MM/yyyy format
              if (dateParts[0].length <= 2 && dateParts[1].length <= 2 && dateParts[2].length == 4) {
                int day = int.parse(dateParts[0]);
                int month = int.parse(dateParts[1]);
                int year = int.parse(dateParts[2]);
                if (day <= 31 && month <= 12 && year > 1900 && year < 2100) {
                  print('Parsed date (dd/MM/yyyy): $year-$month-$day');
                  return DateTime(year, month, day);
                }
              }
              
              // Third priority: MM/dd/yyyy format
              if (dateParts[0].length <= 2 && dateParts[1].length <= 2 && dateParts[2].length == 4) {
                int month = int.parse(dateParts[0]);
                int day = int.parse(dateParts[1]);
                int year = int.parse(dateParts[2]);
                if (day <= 31 && month <= 12 && year > 1900 && year < 2100) {
                  print('Parsed date (MM/dd/yyyy): $year-$month-$day');
                  return DateTime(year, month, day);
                }
              }
            } catch (e) {
              print('Error parsing with separator $separator: $e');
              continue; // Try next format
            }
          }
        }
      }
      
      // If all parsing attempts fail
      print('Could not parse date: $dateString');
      return null;
    } catch (e) {
      print('Error parsing date of birth: $e');
      return null;
    }
  }

  void _onFieldChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  Future<void> _saveProfileData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Get required data from AuthProvider
      final email = authProvider.email ?? '';
      final tokenCode = await authProvider.getTokenCode();
      final contactID = await authProvider.getContactID();
      final phoneNumber = authProvider.phoneNumber ?? '';
      
      // Validate required fields - either email or phone number must be present
      if ((email.isEmpty && phoneNumber.isEmpty) || tokenCode.isEmpty || contactID.isEmpty) {
        print('=== Authentication Validation Failed ===');
        print('Email: $email');
        print('Phone: $phoneNumber');
        print('TokenCode: $tokenCode');
        print('ContactID: $contactID');
        print('======================================');
        throw Exception('Missing authentication data. Please login again.');
      }
      
      // Use email if available, otherwise use phone number for identification
      final userIdentifier = email.isNotEmpty ? email : phoneNumber;
      
      // Format date of birth for API (yyyy-MM-dd format)
      String formattedDateOfBirth = '';
      if (_selectedDateOfBirth != null) {
        formattedDateOfBirth = '${_selectedDateOfBirth!.year.toString()}-${_selectedDateOfBirth!.month.toString().padLeft(2, '0')}-${_selectedDateOfBirth!.day.toString().padLeft(2, '0')}';
      }
      
      print('=== Saving Profile Data ===');
      print('Email: $email');
      print('TokenCode: $tokenCode');
      print('ContactID: $contactID');
      print('Name: ${_nameController.text}');
      print('Phone: ${_phoneController.text}');
      print('Email to save: ${_emailController.text}');
      print('Gender: $_selectedGender');
      print('DOB: $formattedDateOfBirth');
      print('Address: ${_addressController.text}');
      print('Occupation: ${_occupationController.text}');
      
      // Call the API
      final result = await ApiService.updateMemberProfile(
        email: userIdentifier, // Use email if available, otherwise phone number
        tokenCode: tokenCode,
        contactID: contactID,
        contactName: _nameController.text.trim(),
        contEmail: _emailController.text.trim(),
        phoneTelNo: _phoneController.text.trim(),
        gender: _selectedGender,
        dateOfBirth: formattedDateOfBirth,
        contAddDetails: _addressController.text.trim(),
        occupation: _occupationController.text.trim(),
      );
      
      print('=== API Response ===');
      print('Result: $result');
      print('====================');
      
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        if (result['success'] == true) {
          // Update the AuthProvider's email field directly if email was changed
          final newEmail = _emailController.text.trim();
          if (newEmail.isNotEmpty && newEmail != authProvider.email) {
            // Update the AuthProvider's stored email
            await authProvider.updateUserEmail(newEmail);
          }
          
          // Update the stored API profile data with the new values
          await authProvider.updateApiProfileData({
            'Name': _nameController.text.trim(),
            'Email': _emailController.text.trim(), // Store with capital E for consistency
            'Mobile': _phoneController.text.trim(),
            'Gender': _selectedGender,
            'DateofBirth': formattedDateOfBirth,
            'Address': _addressController.text.trim(),
            'Occupation': _occupationController.text.trim(),
          });
          
          print('=== Profile Data Updated Locally ===');
          print('Email stored: ${_emailController.text.trim()}');
          print('====================================');
          
          // Success
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Profile updated successfully!'),
              backgroundColor: const Color(0xFF4CAF50),
              duration: const Duration(seconds: 3),
            ),
          );
          
          setState(() {
            _hasChanges = false;
          });
          
          // Force refresh the AuthProvider's cached API data to get updated profile
          await authProvider.refreshApiDataForAllScreens();
          
          // Reload profile data to show updated information
          await _loadProfileData();
          
          // Handle onboarding flow
          if (widget.isOnboarding) {
            final onboardingProvider = Provider.of<OnboardingProvider>(context, listen: false);
            await onboardingProvider.completeProfileStep();
            Navigator.pop(context, true);
          } else {
            Navigator.pop(context, true);
          }
        } else {
          // Error
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to update profile'),
              backgroundColor: const Color(0xFFE57373),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      print('Error saving profile: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: const Color(0xFFE57373),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Select Profile Picture',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildImageOption(
                        icon: Icons.camera_alt,
                        label: 'Camera',
                        onTap: () => _getImage(ImageSource.camera),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildImageOption(
                        icon: Icons.photo_library,
                        label: 'Gallery',
                        onTap: () => _getImage(ImageSource.gallery),
                      ),
                    ),
                  ],
                ),
                if (_profileImage != null) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: _buildImageOption(
                      icon: Icons.delete,
                      label: 'Remove Picture',
                      onTap: _removeImage,
                      color: const Color(0xFFE57373),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      print('Error showing image picker: $e');
    }
  }

  Widget _buildImageOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: (color ?? const Color(0xFF6A11CB)).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: (color ?? const Color(0xFF6A11CB)).withOpacity(0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: color ?? const Color(0xFF6A11CB),
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color ?? const Color(0xFF6A11CB),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _getImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        // Save image to app directory
        final Directory appDir = await getApplicationDocumentsDirectory();
        final String fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final String savedPath = path.join(appDir.path, 'profile_images', fileName);
        
        // Create directory if it doesn't exist
        final Directory profileImagesDir = Directory(path.dirname(savedPath));
        if (!await profileImagesDir.exists()) {
          await profileImagesDir.create(recursive: true);
        }

        // Copy file to app directory
        final File imageFile = File(pickedFile.path);
        final File savedFile = await imageFile.copy(savedPath);

        setState(() {
          _profileImage = savedFile;
          _onFieldChanged();
        });

        HapticFeedback.lightImpact();
      }
    } catch (e) {
      print('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error selecting image. Please try again.'),
            backgroundColor: Color(0xFFE57373),
          ),
        );
      }
    }
  }

  void _removeImage() {
    setState(() {
      _profileImage = null;
      _onFieldChanged();
    });
    HapticFeedback.lightImpact();
  }

  Future<void> _selectDateOfBirth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateOfBirth ?? DateTime(1990),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF6A11CB),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDateOfBirth) {
      setState(() {
        _selectedDateOfBirth = picked;
        _onFieldChanged();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              onPressed: () {
                if (_hasChanges) {
                  _showUnsavedChangesDialog();
                } else {
                  Navigator.pop(context);
                }
              },
              icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
            ),
            title: const Text(
              'Manage Profile',
              style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: _isLoading ? null : _saveProfileData,
              child: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6A11CB)),
                      ),
                    )
                  : const Text(
                      'Save',
                      style: TextStyle(
                        color: Color(0xFF6A11CB),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
        ],
      ),
      body: _isLoading && _nameController.text.isEmpty
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6A11CB)),
              ),
            )
          : FadeTransition(
              opacity: _fadeAnimation,
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Profile Image Section
                      _buildProfileImageSection(),
                      
                      const SizedBox(height: 20),
                      
                      // Login Method Indicator
                      _buildLoginMethodIndicator(),
                      
                      const SizedBox(height: 30),
                      
                      // Personal Information Section
                      _buildSectionHeader('Personal Information'),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _nameController,
                        label: 'Full Name',
                        icon: Icons.person,
                        validator: null, // Optional field
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _emailController,
                        label: 'Email Address',
                        icon: Icons.email,
                        keyboardType: TextInputType.emailAddress,
                        readOnly: _isEmailLogin, // Not editable if user logged in with email
                        suffixIcon: _isEmailLogin ? Icon(Icons.lock, color: Colors.grey[400], size: 16) : null,
                        helperText: _isEmailLogin ? 'Email from login (cannot be changed)' : null,
                        validator: (value) {
                          // Optional field for phone login, but validate format if provided
                          if (!_isEmailLogin && value != null && value.trim().isNotEmpty && !value.contains('@')) {
                            return 'Enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _phoneController,
                        label: 'Phone Number',
                        icon: Icons.phone,
                        keyboardType: TextInputType.phone,
                        readOnly: _isPhoneLogin, // Not editable if user logged in with phone
                        suffixIcon: _isPhoneLogin ? Icon(Icons.lock, color: Colors.grey[400], size: 16) : null,
                        helperText: _isPhoneLogin ? 'Phone from login (cannot be changed)' : null,
                        validator: (value) {
                          // Optional field for email login, but validate if provided
                          if (!_isPhoneLogin && value != null && value.trim().isNotEmpty) {
                            if (value.length < 10) {
                              return 'Enter a valid phone number';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildGenderDropdown(),
                      const SizedBox(height: 16),
                      _buildDateOfBirthField(),
                      
                      const SizedBox(height: 30),
                      
                      // Additional Information Section
                      _buildSectionHeader('Additional Information'),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _addressController,
                        label: 'Address',
                        icon: Icons.location_on,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _occupationController,
                        label: 'Occupation',
                        icon: Icons.work,
                      ),
                      const SizedBox(height: 16),
                      // Emergency Contact field hidden as requested
                      // _buildTextField(
                      //   controller: _emergencyContactController,
                      //   label: 'Emergency Contact',
                      //   icon: Icons.emergency,
                      //   keyboardType: TextInputType.phone,
                      // ),
                      
                      const SizedBox(height: 40),
                      
                      // Save Button
                      _buildSaveButton(),
                      
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
        );
      },
    );
  }

  // Helper method to generate avatar widget
  Widget _buildAvatarWidget({required double size, double? fontSize}) {
    if (_profileImage != null) {
      return Image.file(
        _profileImage!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildInitialsAvatar(size: size, fontSize: fontSize);
        },
      );
    } else {
      return _buildInitialsAvatar(size: size, fontSize: fontSize);
    }
  }

  // Helper method to build initials avatar
  Widget _buildInitialsAvatar({required double size, double? fontSize}) {
    String initials = _getInitials(_nameController.text);
    Color avatarColor = _getAvatarColor(_nameController.text);
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: avatarColor,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: fontSize ?? (size * 0.4),
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // Helper method to get initials from name
  String _getInitials(String name) {
    if (name.isEmpty || name == 'Guest User' || name == 'User') {
      return 'U';
    }
    
    List<String> nameParts = name.trim().split(' ').where((part) => part.isNotEmpty).toList();
    
    if (nameParts.length >= 2) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    } else if (nameParts.length == 1 && nameParts[0].isNotEmpty) {
      return nameParts[0][0].toUpperCase();
    }
    return 'U';
  }

  // Helper method to get avatar color based on name
  Color _getAvatarColor(String name) {
    if (name.isEmpty || name == 'Guest User' || name == 'User') {
      return Colors.grey[600]!;
    }
    
    // Generate color based on name hash
    int hash = name.hashCode;
    List<Color> colors = [
      const Color(0xFF2196F3), // Blue
      const Color(0xFF4CAF50), // Green
      const Color(0xFFFF9800), // Orange
      const Color(0xFF9C27B0), // Purple
      const Color(0xFFF44336), // Red
      const Color(0xFF607D8B), // Blue Grey
      const Color(0xFF795548), // Brown
      const Color(0xFF3F51B5), // Indigo
      const Color(0xFFE91E63), // Pink
      const Color(0xFF009688), // Teal
    ];
    
    return colors[hash.abs() % colors.length];
  }

  Widget _buildProfileImageSection() {
    return Center(
      child: Stack(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[300],
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipOval(
              child: _buildAvatarWidget(size: 120, fontSize: 48),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF6A11CB),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1A1A1A),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
    bool readOnly = false,
    Widget? suffixIcon,
    String? helperText,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines,
      readOnly: readOnly,
      onChanged: (_) => _onFieldChanged(),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF6A11CB)),
        suffixIcon: suffixIcon,
        helperText: helperText,
        helperStyle: TextStyle(
          color: Colors.grey[600],
          fontSize: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF6A11CB), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE57373), width: 2),
        ),
        filled: true,
        fillColor: readOnly ? Colors.grey[100] : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedGender.isEmpty ? null : _selectedGender,
      decoration: InputDecoration(
        labelText: 'Gender',
        prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF6A11CB)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF6A11CB), width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      items: ['Male', 'Female', 'Other'].map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _selectedGender = newValue ?? '';
          _onFieldChanged();
        });
      },
    );
  }

  Widget _buildDateOfBirthField() {
    print('Building date of birth field. Selected date: $_selectedDateOfBirth');
    
    return GestureDetector(
      onTap: _selectDateOfBirth,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE0E0E0)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: Color(0xFF6A11CB)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _selectedDateOfBirth != null
                    ? '${_selectedDateOfBirth!.year}/${_selectedDateOfBirth!.month.toString().padLeft(2, '0')}/${_selectedDateOfBirth!.day.toString().padLeft(2, '0')}'
                    : 'Select Date of Birth',
                style: TextStyle(
                  fontSize: 16,
                  color: _selectedDateOfBirth != null
                      ? Colors.black87
                      : Colors.grey[600],
                ),
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _hasChanges && !_isLoading ? _saveProfileData : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6A11CB),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Save Changes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  void _showUnsavedChangesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text(
          'You have unsaved changes. Do you want to save them before leaving?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Discard'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _saveProfileData();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginMethodIndicator() {
    if (!_isEmailLogin && !_isPhoneLogin) {
      return const SizedBox.shrink(); // Hide if login method is unclear
    }

    return FutureBuilder<Map<String, dynamic>?>(
      future: Provider.of<AuthProvider>(context, listen: false).getApiProfileData(),
      builder: (context, snapshot) {
        final hasApiData = snapshot.data != null;
        
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: (hasApiData ? Colors.green : Colors.blue).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: (hasApiData ? Colors.green : Colors.blue).withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(
                _isEmailLogin ? Icons.email : Icons.phone,
                color: hasApiData ? Colors.green[700] : Colors.blue[700],
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _isEmailLogin 
                      ? 'You logged in with email: ${_loginEmail}\n${hasApiData ? "Profile." : "Email cannot be changed, but you can add a phone number."}'
                      : 'You logged in with phone: ${_loginPhone}\nPhone cannot be changed, but you can add an email address.',
                  style: TextStyle(
                    color: hasApiData ? Colors.green[700] : Colors.blue[700],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
