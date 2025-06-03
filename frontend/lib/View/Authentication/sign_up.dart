// ignore_for_file: deprecated_member_use, use_build_context_synchronously, unused_local_variable

import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:frontend/controllers/input_controllers.dart';
import 'package:frontend/services/api_service.dart';
import 'package:image_picker/image_picker.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with TickerProviderStateMixin {
  // Form keys for each tab
  final _profileFormKey = GlobalKey<FormState>();
  final _accountFormKey = GlobalKey<FormState>();

  // Using InputControllers from the backend logic
  final InputControllers _inputControllers = InputControllers();

  // State variables
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;
  bool _privacyPolicyRead = false;
  int _currentStep = 0;
  late TabController _tabController;

  // Backend integration variables
  Uint8List? _profileImage;
  bool _isLoading = false;

  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Username validation state
  bool _isCheckingUsername = false;
  bool _isUsernameAvailable = true;
  String? _usernameError;
  Timer? _usernameDebounce;

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
    _usernameDebounce?.cancel();
    super.dispose();
  }

  // Image picker functionality from backend
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

  void _nextTab() {
    if (_currentStep == 0) {
      if (_profileFormKey.currentState!.validate()) {
        _tabController.animateTo(_currentStep + 1);
      }
    } else if (_currentStep == 1) {
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

  // Backend registration logic
  Future<void> _handleSignUp() async {
    if (!_agreeToTerms || !_privacyPolicyRead) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please read and accept the privacy policy and terms'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => WillPopScope(
          onWillPop: () async => false,
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
            ),
          ),
        ),
      );

      final response = await ApiService.register(
        name: _inputControllers.nameController.text.trim(),
        email: _inputControllers.emailController.text.trim(),
        password: _inputControllers.passwordController.text,
        userName: _inputControllers.usernameController.text.trim(),
        age: int.parse(_inputControllers.ageController.text.trim()),
        phone: _inputControllers.phoneController.text.trim(),
        profileImage: _profileImage,
      );

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
          (route) => false,
        );
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Validators
  String? _requiredFieldValidator(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your $fieldName';
    }
    return null;
  }

  // Real-time username validation
  Future<void> _checkUsernameAvailability(String username) async {
    if (username.length < 3) {
      setState(() {
        _isUsernameAvailable = true;
        _usernameError = null;
      });
      return;
    }

    if (!RegExp(r'^[a-zA-Z0-9._]+$').hasMatch(username)) {
      setState(() {
        _isUsernameAvailable = false;
        _usernameError =
            'Username can only contain letters, numbers, dots, and underscores';
      });
      return;
    }

    setState(() {
      _isCheckingUsername = true;
      _usernameError = null;
    });

    try {
      final response = await ApiService.checkUsernameAvailability(username);
      if (mounted) {
        setState(() {
          _isCheckingUsername = false;
          _isUsernameAvailable = response['available'] as bool;
          _usernameError = response['message'] as String;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCheckingUsername = false;
          _isUsernameAvailable = false;
          _usernameError = 'Error checking username availability';
        });
      }
    }
  }

  // Update username validator
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
    if (!_isUsernameAvailable) {
      return 'Username is already taken';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _inputControllers.passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

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
            Container(
              padding: const EdgeInsets.only(top: 60),
              child: Column(
                children: [
                  // Header
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        Text(
                          'Create Account',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                            letterSpacing: 0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Progress indicator
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30.0),
                    child: Row(
                      children: [
                        _buildStepIndicator(0, "Profile"),
                        _buildStepConnector(),
                        _buildStepIndicator(1, "Account"),
                        _buildStepConnector(),
                        _buildStepIndicator(2, "Privacy"),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Tabbed content
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildProfileTab(colorScheme),
                        _buildAccountTab(colorScheme),
                        _buildPrivacyPolicyTab(colorScheme),
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

  Widget _buildStepIndicator(int step, String label) {
    final colorScheme = Theme.of(context).colorScheme;
    final isActive = step == _currentStep;
    final isCompleted = step < _currentStep;

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isActive || isCompleted
                  ? colorScheme.secondary
                  : colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: colorScheme.secondary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: isCompleted
                  ? const Icon(Icons.check, color: Colors.white, size: 20)
                  : Text(
                      '${step + 1}',
                      style: TextStyle(
                        color: isActive ? Colors.white : colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: isActive
                  ? colorScheme.secondary
                  : colorScheme.primary.withOpacity(0.7),
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepConnector() {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 40,
      height: 3,
      color: colorScheme.primary.withOpacity(0.1),
    );
  }

  Widget _buildProfileTab(ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _profileFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            Text(
              'Tell us about yourself',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Profile photo with image picker integration
            Center(
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: () => _pickImage(ImageSource.gallery),
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colorScheme.secondary.withOpacity(0.5),
                          width: 2,
                        ),
                      ),
                      child: _profileImage != null
                          ? ClipOval(
                              child: Image.memory(
                                _profileImage!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : const Icon(
                              Icons.person,
                              size: 60,
                              color: Colors.white,
                            ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () => _pickImage(ImageSource.gallery),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: colorScheme.secondary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Optional text
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Optional: You can add a photo now or later',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.primary.withOpacity(0.6),
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 24),

            // Form fields
            _buildTextField(
              controller: _inputControllers.nameController,
              label: 'Full Name',
              hint: 'Enter your full name',
              icon: Icons.person_outline,
              validator: (value) => _requiredFieldValidator(value, 'full name'),
            ),
            const SizedBox(height: 16),

            _buildUsernameField(),
            const SizedBox(height: 16),

            _buildTextField(
              controller: _inputControllers.ageController,
              label: 'Age',
              hint: 'Enter your age',
              icon: Icons.cake_outlined,
              keyboardType: TextInputType.number,
              validator: _validateAge,
            ),
            const SizedBox(height: 40),

            _buildActionButton(
              label: 'NEXT',
              onPressed: _nextTab,
              icon: Icons.arrow_forward,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsernameField() {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
          controller: _inputControllers.usernameController,
          label: 'Username',
          hint: 'Choose a unique username',
          icon: Icons.alternate_email,
          validator: _validateUsername,
          onChanged: (value) {
            _usernameDebounce?.cancel();
            _usernameDebounce = Timer(const Duration(milliseconds: 500), () {
              _checkUsernameAvailability(value);
            });
          },
        ),
        if (_isCheckingUsername)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 16),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(colorScheme.primary),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Checking availability...',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.primary.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          )
        else if (_usernameError != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 16),
            child: Row(
              children: [
                Icon(
                  _isUsernameAvailable ? Icons.check_circle : Icons.error,
                  size: 16,
                  color: _isUsernameAvailable ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  _usernameError!,
                  style: TextStyle(
                    fontSize: 12,
                    color: _isUsernameAvailable ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildAccountTab(ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _accountFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            Text(
              'Set up your account',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            _buildTextField(
              controller: _inputControllers.emailController,
              label: 'Email Address',
              hint: 'Enter your email',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: _validateEmail,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _inputControllers.phoneController,
              label: 'Phone Number',
              hint: 'Enter your phone number',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: _validatePhone,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _inputControllers.passwordController,
              label: 'Password',
              hint: 'Create a strong password',
              icon: Icons.lock_outline,
              isPassword: true,
              obscureText: _obscurePassword,
              validator: _validatePassword,
              onTogglePassword: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _inputControllers.confirmPasswordController,
              label: 'Confirm Password',
              hint: 'Confirm your password',
              icon: Icons.lock_outline,
              isPassword: true,
              obscureText: _obscureConfirmPassword,
              validator: _validateConfirmPassword,
              onTogglePassword: () {
                setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                });
              },
            ),
            const SizedBox(height: 40),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    label: 'BACK',
                    onPressed: _previousTab,
                    icon: Icons.arrow_back,
                    isOutlined: true,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildActionButton(
                    label: 'NEXT',
                    onPressed: _nextTab,
                    icon: Icons.arrow_forward,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyPolicyTab(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Privacy Policy & Terms',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colorScheme.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Text(
                      'Privacy Policy',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _privacyPolicyText,
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.primary.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Terms of Service',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _termsOfServiceText,
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.primary.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Checkbox(
                value: _privacyPolicyRead,
                activeColor: colorScheme.secondary,
                onChanged: (value) {
                  setState(() {
                    _privacyPolicyRead = value ?? false;
                  });
                },
              ),
              Expanded(
                child: Text(
                  'I have read the Privacy Policy',
                  style: TextStyle(fontSize: 14, color: colorScheme.primary),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Checkbox(
                value: _agreeToTerms,
                activeColor: colorScheme.secondary,
                onChanged: (value) {
                  setState(() {
                    _agreeToTerms = value ?? false;
                  });
                },
              ),
              Expanded(
                child: Text(
                  'I agree to the Terms of Service and Privacy Policy',
                  style: TextStyle(fontSize: 14, color: colorScheme.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  label: 'BACK',
                  onPressed: _previousTab,
                  icon: Icons.arrow_back,
                  isOutlined: true,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActionButton(
                  label: _isLoading ? 'CREATING...' : 'REGISTER',
                  onPressed: _agreeToTerms && _privacyPolicyRead && !_isLoading
                      ? _handleSignUp
                      : null,
                  icon: _isLoading ? null : Icons.check_circle_outline,
                  isLoading: _isLoading,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Already have an account?',
                style: TextStyle(color: colorScheme.primary.withOpacity(0.7)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Sign In',
                  style: TextStyle(
                    color: colorScheme.secondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool isPassword = false,
    bool obscureText = false,
    String? Function(String?)? validator,
    VoidCallback? onTogglePassword,
    void Function(String)? onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword ? obscureText : false,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          floatingLabelBehavior: FloatingLabelBehavior.never,
          filled: true,
          fillColor: colorScheme.surface,
          errorMaxLines: 2,
          prefixIcon: Icon(icon, color: colorScheme.secondary),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    obscureText ? Icons.visibility_off : Icons.visibility,
                    color: colorScheme.primary.withOpacity(0.7),
                  ),
                  onPressed: onTogglePassword,
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: colorScheme.secondary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required VoidCallback? onPressed,
    IconData? icon,
    bool isOutlined = false,
    bool isLoading = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 50,
      decoration: isOutlined
          ? null
          : BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.secondary.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isOutlined ? Colors.transparent : colorScheme.secondary,
          foregroundColor: isOutlined ? colorScheme.secondary : Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: isOutlined
                ? BorderSide(color: colorScheme.secondary, width: 1.5)
                : BorderSide.none,
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isOutlined && icon == Icons.arrow_back)
                    Icon(icon, size: 18),
                  if (isOutlined && icon == Icons.arrow_back)
                    const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  if ((!isOutlined || icon != Icons.arrow_back) && icon != null)
                    const SizedBox(width: 8),
                  if ((!isOutlined || icon != Icons.arrow_back) && icon != null)
                    Icon(icon, size: 18),
                ],
              ),
      ),
    );
  }

  final String _privacyPolicyText = '''
Our app is committed to protecting your privacy. We collect personal information such as your name, email address, and demographic information to provide you with a personalized experience.

We use this information to:
• Create and manage your account
• Provide you with personalized content and recommendations
• Improve our services and develop new features
• Communicate with you about updates and new features
''';

  final String _termsOfServiceText = '''
By accessing or using our app, you agree to be bound by these Terms of Service. If you disagree with any part of the terms, you may not access the app.

CONTENT AND CONDUCT
• You are responsible for all content you post and activity that occurs under your account
• You must not post content that is illegal, offensive, threatening, defamatory, or infringing on intellectual property rights
• You must not use the app to engage in any illegal activities or to harass, bully, or harm others
''';
}
