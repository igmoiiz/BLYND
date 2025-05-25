// ignore_for_file: deprecated_member_use, use_build_context_synchronously, unused_local_variable

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:frontend/Controller/input_controllers.dart';
import 'package:frontend/services/api_service.dart';
import 'package:image_picker/image_picker.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> with TickerProviderStateMixin {
  // Form keys for each tab
  final _profileFormKey = GlobalKey<FormState>();
  final _accountFormKey = GlobalKey<FormState>();

  // Controllers Instance
  final InputControllers _inputControllers = InputControllers();

  // State variables
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;
  bool _privacyPolicyRead = false;
  int _currentStep = 0;
  late TabController _tabController;
  Uint8List? _profileImage;
  bool _isLoading = false;

  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();

    _tabController.addListener(() {
      setState(() {
        _currentStep = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _tabController.dispose();
    _inputControllers.nameController.dispose();
    _inputControllers.usernameController.dispose();
    _inputControllers.emailController.dispose();
    _inputControllers.passwordController.dispose();
    _inputControllers.confirmPasswordController.dispose();
    _inputControllers.ageController.dispose();
    _inputControllers.phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final imageBytes = await pickedFile.readAsBytes();
        setState(() {
          _profileImage = imageBytes;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Choose Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a picture'),
              onTap: () {
                Navigator.of(ctx).pop();
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.of(ctx).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSignUp() async {
    if (!_profileFormKey.currentState!.validate() ||
        !_accountFormKey.currentState!.validate()) {
      return;
    }

    if (!_agreeToTerms || !_privacyPolicyRead) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to the Terms and Privacy Policy'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await ApiService.register(
        name: _inputControllers.nameController.text.trim(),
        email: _inputControllers.emailController.text.trim(),
        password: _inputControllers.passwordController.text,
        userName: _inputControllers.usernameController.text.trim(),
        age: int.parse(_inputControllers.ageController.text.trim()),
        phone: _inputControllers.phoneController.text.trim(),
        profileImage: _profileImage,
      );

      if (mounted) {
        // Registration successful, navigate to login
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _nextTab() {
    if (_currentStep == 0) {
      // Validate profile information
      if (_profileFormKey.currentState!.validate()) {
        _tabController.animateTo(_currentStep + 1);
      }
    } else if (_currentStep == 1) {
      // Validate account information
      if (_accountFormKey.currentState!.validate()) {
        _tabController.animateTo(_currentStep + 1);
      }
    }
  }

  void _previousTab() {
    if (_currentStep > 0) {
      _tabController.animateTo(_currentStep - 1);
    }
  }

  // Common validator
  String? _requiredFieldValidator(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your $fieldName';
    }
    return null;
  }

  // Username validator
  String? _validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a username';
    }
    if (value.length < 3) {
      return 'Username must be at least 3 characters';
    }
    if (!RegExp(r'^[a-zA-Z0-9._]+$').hasMatch(value)) {
      return 'Username can only contain letters, numbers, dots, and underscores';
    }
    return null;
  }

  // Email validator
  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  // Password validator
  String? _validatePassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  // Confirm password validator
  String? _validateConfirmPassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _inputControllers.passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  // Age validator
  String? _validateAge(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your age';
    }
    final age = int.tryParse(value);
    if (age == null) {
      return 'Please enter a valid number';
    }
    if (age < 13) {
      return 'You must be at least 13 years old';
    }
    if (age > 120) {
      return 'Please enter a valid age';
    }
    return null;
  }

  // Phone number validator
  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your phone number';
    }
    if (!RegExp(r'^\+?[0-9]{10,15}$').hasMatch(value)) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Stack(
          children: [
            // Background decoration
            Positioned(
              top: -50,
              right: -50,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.secondary.withOpacity(0.1),
                ),
              ),
            ),
            Positioned(
              bottom: -80,
              left: -80,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.secondary.withOpacity(0.1),
                ),
              ),
            ),

            // Back button
            Positioned(
              top: 16,
              left: 16,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: IconButton(
                  icon: Icon(Icons.arrow_back_ios, color: colorScheme.primary),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),

            // Main content
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Progress indicator
                  LinearProgressIndicator(
                    value: (_currentStep + 1) / 3,
                    backgroundColor: colorScheme.primary.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Tab bar
                  TabBar(
                    controller: _tabController,
                    indicatorColor: colorScheme.secondary,
                    labelColor: colorScheme.secondary,
                    unselectedLabelColor: colorScheme.primary.withOpacity(0.5),
                    tabs: const [
                      Tab(text: 'Profile'),
                      Tab(text: 'Account'),
                      Tab(text: 'Review'),
                    ],
                  ),

                  // Tab views
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        // Profile information form
                        SingleChildScrollView(
                          child: Form(
                            key: _profileFormKey,
                            child: Column(
                              children: [
                                const SizedBox(height: 24),
                                // Profile image picker
                                GestureDetector(
                                  onTap: _showImageSourceDialog,
                                  child: CircleAvatar(
                                    radius: 50,
                                    backgroundColor:
                                        colorScheme.primary.withOpacity(0.1),
                                    backgroundImage: _profileImage != null
                                        ? MemoryImage(_profileImage!)
                                        : null,
                                    child: _profileImage == null
                                        ? Icon(
                                            Icons.add_a_photo,
                                            color: colorScheme.primary,
                                            size: 32,
                                          )
                                        : null,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                // Name field
                                TextFormField(
                                  controller: _inputControllers.nameController,
                                  decoration: InputDecoration(
                                    labelText: 'Full Name',
                                    prefixIcon: Icon(
                                      Icons.person_outline,
                                      color: colorScheme.secondary,
                                    ),
                                  ),
                                  validator: (value) =>
                                      _requiredFieldValidator(value, 'name'),
                                ),
                                const SizedBox(height: 16),
                                // Username field
                                TextFormField(
                                  controller:
                                      _inputControllers.usernameController,
                                  decoration: InputDecoration(
                                    labelText: 'Username',
                                    prefixIcon: Icon(
                                      Icons.alternate_email,
                                      color: colorScheme.secondary,
                                    ),
                                  ),
                                  validator: _validateUsername,
                                ),
                                const SizedBox(height: 16),
                                // Age field
                                TextFormField(
                                  controller: _inputControllers.ageController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: 'Age',
                                    prefixIcon: Icon(
                                      Icons.cake_outlined,
                                      color: colorScheme.secondary,
                                    ),
                                  ),
                                  validator: _validateAge,
                                ),
                                const SizedBox(height: 16),
                                // Phone field
                                TextFormField(
                                  controller: _inputControllers.phoneController,
                                  keyboardType: TextInputType.phone,
                                  decoration: InputDecoration(
                                    labelText: 'Phone Number',
                                    prefixIcon: Icon(
                                      Icons.phone_outlined,
                                      color: colorScheme.secondary,
                                    ),
                                  ),
                                  validator: _validatePhone,
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Account information form
                        SingleChildScrollView(
                          child: Form(
                            key: _accountFormKey,
                            child: Column(
                              children: [
                                const SizedBox(height: 24),
                                // Email field
                                TextFormField(
                                  controller: _inputControllers.emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: InputDecoration(
                                    labelText: 'Email',
                                    prefixIcon: Icon(
                                      Icons.email_outlined,
                                      color: colorScheme.secondary,
                                    ),
                                  ),
                                  validator: _validateEmail,
                                ),
                                const SizedBox(height: 16),
                                // Password field
                                TextFormField(
                                  controller:
                                      _inputControllers.passwordController,
                                  obscureText: _obscurePassword,
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    prefixIcon: Icon(
                                      Icons.lock_outline,
                                      color: colorScheme.secondary,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                    ),
                                  ),
                                  validator: _validatePassword,
                                ),
                                const SizedBox(height: 16),
                                // Confirm password field
                                TextFormField(
                                  controller: _inputControllers
                                      .confirmPasswordController,
                                  obscureText: _obscureConfirmPassword,
                                  decoration: InputDecoration(
                                    labelText: 'Confirm Password',
                                    prefixIcon: Icon(
                                      Icons.lock_outline,
                                      color: colorScheme.secondary,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureConfirmPassword
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscureConfirmPassword =
                                              !_obscureConfirmPassword;
                                        });
                                      },
                                    ),
                                  ),
                                  validator: _validateConfirmPassword,
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Review and submit
                        SingleChildScrollView(
                          child: Column(
                            children: [
                              const SizedBox(height: 24),
                              // Terms and conditions
                              CheckboxListTile(
                                value: _agreeToTerms,
                                onChanged: (value) {
                                  setState(() {
                                    _agreeToTerms = value ?? false;
                                  });
                                },
                                title: const Text(
                                  'I agree to the Terms of Service',
                                ),
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                              ),
                              // Privacy policy
                              CheckboxListTile(
                                value: _privacyPolicyRead,
                                onChanged: (value) {
                                  setState(() {
                                    _privacyPolicyRead = value ?? false;
                                  });
                                },
                                title: const Text(
                                  'I have read the Privacy Policy',
                                ),
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                              ),
                              const SizedBox(height: 32),
                              // Submit button
                              ElevatedButton(
                                onPressed: _isLoading ? null : _handleSignUp,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colorScheme.secondary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 48,
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child: _isLoading
                                    ? const CircularProgressIndicator()
                                    : const Text(
                                        'Create Account',
                                        style: TextStyle(fontSize: 16),
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Navigation buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (_currentStep > 0)
                          TextButton(
                            onPressed: _previousTab,
                            child: const Text('Previous'),
                          )
                        else
                          const SizedBox.shrink(),
                        if (_currentStep < 2)
                          ElevatedButton(
                            onPressed: _nextTab,
                            child: const Text('Next'),
                          )
                        else
                          const SizedBox.shrink(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
