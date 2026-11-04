import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/ad_service.dart';
import '../../providers/auth_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _displayNameController;
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _dobController;
  late TextEditingController _genderController;
  late TextEditingController _educationController;
  late TextEditingController _designationController;
  late TextEditingController _experienceController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _addressController;
  late TextEditingController _descriptionController;

  // Social Links
  late TextEditingController _facebookController;
  late TextEditingController _instagramController;
  late TextEditingController _xTwitterController;
  late TextEditingController _youtubeController;
  late TextEditingController _linkedinController;

  bool _isSaving = false;
  bool _isUploadingAvatar = false;
  bool _hasProfileChanges = false;
  File? _localImageFile;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final author = auth.author;

    // Prefill with real backend profile data
    String firstName = author?.firstName ?? '';
    String lastName = author?.lastName ?? '';

    if (firstName.isEmpty && lastName.isEmpty && author?.name != null && author!.name.isNotEmpty) {
      final parts = author.name.trim().split(' ');
      firstName = parts.first;
      if (parts.length > 1) {
        lastName = parts.sublist(1).join(' ');
      }
    }

    _displayNameController = TextEditingController(
      text: author?.displayName?.isNotEmpty == true ? author!.displayName! : (author?.name ?? ''),
    );
    _firstNameController = TextEditingController(text: firstName);
    _lastNameController = TextEditingController(text: lastName);
    _phoneController = TextEditingController(text: author?.phone ?? '');
    _emailController = TextEditingController(text: author?.email ?? '');
    _dobController = TextEditingController(text: author?.dob ?? '');
    _genderController = TextEditingController(text: author?.gender ?? '');
    _educationController = TextEditingController(text: author?.education ?? '');
    _designationController = TextEditingController(text: author?.designation ?? '');
    _experienceController = TextEditingController(text: author?.experience ?? '');
    _cityController = TextEditingController(text: author?.city ?? '');
    _stateController = TextEditingController(text: author?.state ?? '');
    _addressController = TextEditingController(text: author?.address ?? '');
    _descriptionController = TextEditingController(text: author?.description ?? '');

    _facebookController = TextEditingController(text: author?.facebook ?? '');
    _instagramController = TextEditingController(text: author?.instagram ?? '');
    _xTwitterController = TextEditingController(text: author?.xTwitter ?? '');
    _youtubeController = TextEditingController(text: author?.youtube ?? '');
    _linkedinController = TextEditingController(text: author?.linkedin ?? '');
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _dobController.dispose();
    _genderController.dispose();
    _educationController.dispose();
    _designationController.dispose();
    _experienceController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    _facebookController.dispose();
    _instagramController.dispose();
    _xTwitterController.dispose();
    _youtubeController.dispose();
    _linkedinController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadAvatar(ImageSource source) async {
    Navigator.of(context).pop();
    AdService().pauseAppOpenAds();

    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile == null) return;
      if (!mounted) return;

      final file = File(pickedFile.path);
      setState(() {
        _localImageFile = file;
        _isUploadingAvatar = true;
      });

      final messenger = ScaffoldMessenger.of(context);
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final success = await auth.updateAvatar(file.path);

      if (!mounted) return;
      setState(() => _isUploadingAvatar = false);

      if (success) {
        _hasProfileChanges = true;
        messenger.showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Text('Profile photo updated successfully!'),
              ],
            ),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      } else {
        final error = auth.errorMessage ?? 'Failed to update profile photo.';
        messenger.showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploadingAvatar = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting image: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } finally {
      Future.delayed(const Duration(seconds: 2), () {
        AdService().resumeAppOpenAds();
      });
    }
  }

  void _showPhotoPickerOptions(BuildContext context, bool isDark) {
    if (_isUploadingAvatar) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.cardDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Change Profile Photo',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.photo_library_rounded, color: AppColors.primary, size: 22),
                  ),
                  title: const Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () => _pickAndUploadAvatar(ImageSource.gallery),
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt_rounded, color: AppColors.primary, size: 22),
                  ),
                  title: const Text('Take a Photo', style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () => _pickAndUploadAvatar(ImageSource.camera),
                ),
                ListTile(
                  leading: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(Icons.close_rounded, color: Colors.grey, size: 22),
                  ),
                  title: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
                  onTap: () => Navigator.pop(sheetContext),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _selectDob(BuildContext context) async {
    DateTime initialDate = DateTime(1995, 1, 1);
    if (_dobController.text.trim().isNotEmpty) {
      final parsed = DateTime.tryParse(_dobController.text.trim());
      if (parsed != null) initialDate = parsed;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primary,
              brightness: Theme.of(context).brightness,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formatted = '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      setState(() {
        _dobController.text = formatted;
      });
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    final success = await auth.updateProfile(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      displayName: _displayNameController.text.trim().isEmpty ? null : _displayNameController.text.trim(),
      phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      dob: _dobController.text.trim().isEmpty ? null : _dobController.text.trim(),
      gender: _genderController.text.trim().isEmpty ? null : _genderController.text.trim(),
      education: _educationController.text.trim().isEmpty ? null : _educationController.text.trim(),
      designation: _designationController.text.trim().isEmpty ? null : _designationController.text.trim(),
      experience: _experienceController.text.trim().isEmpty ? null : _experienceController.text.trim(),
      city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
      state: _stateController.text.trim().isEmpty ? null : _stateController.text.trim(),
      address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
      description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      facebook: _facebookController.text.trim().isEmpty ? null : _facebookController.text.trim(),
      instagram: _instagramController.text.trim().isEmpty ? null : _instagramController.text.trim(),
      xTwitter: _xTwitterController.text.trim().isEmpty ? null : _xTwitterController.text.trim(),
      youtube: _youtubeController.text.trim().isEmpty ? null : _youtubeController.text.trim(),
      linkedin: _linkedinController.text.trim().isEmpty ? null : _linkedinController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      _hasProfileChanges = true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Text('Profile updated successfully!'),
            ],
          ),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      Navigator.pop(context, true);
    } else {
      final error = auth.errorMessage ?? 'Failed to update profile. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Widget _buildAvatarHeader(AuthProvider auth, bool isDark) {
    final author = auth.author;
    final name = author?.effectiveDisplayName ?? author?.name ?? 'Author';
    final email = author?.email ?? '';
    final avatarUrl = author?.avatar;

    return Center(
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              GestureDetector(
                onTap: () => _showPhotoPickerOptions(context, isDark),
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary, width: 2.8),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 18,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (_localImageFile != null)
                          Image.file(
                            _localImageFile!,
                            fit: BoxFit.cover,
                          )
                        else if (avatarUrl != null && avatarUrl.isNotEmpty)
                          Image.network(
                            avatarUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => _buildAvatarFallback(name),
                          )
                        else
                          _buildAvatarFallback(name),

                        if (_isUploadingAvatar)
                          Container(
                            color: Colors.black54,
                            child: const Center(
                              child: SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              // Camera overlay badge
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () => _showPhotoPickerOptions(context, isDark),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? AppColors.backgroundDark : Colors.white,
                        width: 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            name,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppColors.textPrimaryLight,
            ),
          ),
          if (email.isNotEmpty) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.email_outlined,
                    size: 13,
                    color: isDark ? Colors.white60 : AppColors.textSecondaryLight,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    email,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white70 : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatarFallback(String name) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'A';
    return Container(
      color: AppColors.primary.withValues(alpha: 0.2),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w900,
          fontSize: 34,
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: isDark ? Colors.white : AppColors.textPrimaryLight,
            ),
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
    bool isDark = true,
    int maxLines = 1,
    bool readOnly = false,
    VoidCallback? onTap,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
            color: isDark ? Colors.white70 : AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          readOnly: readOnly,
          onTap: onTap,
          keyboardType: keyboardType,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : AppColors.textPrimaryLight,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white30 : Colors.black26,
            ),
            prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
            filled: true,
            fillColor: isDark ? AppColors.cardDark : AppColors.cardLight,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.08),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildFixedOrganizationField(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ORGANIZATION',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
            color: isDark ? Colors.white70 : AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.primary.withValues(alpha: 0.08)
                : AppColors.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.3),
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.business_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'CineFlix Media',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Fixed',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGenderSelector(bool isDark) {
    final options = ['male', 'female', 'other'];
    final current = _genderController.text.trim().toLowerCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'GENDER',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
            color: isDark ? Colors.white70 : AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          children: options.map((opt) {
            final isSelected = current == opt;
            final label = opt[0].toUpperCase() + opt.substring(1);
            return ChoiceChip(
              label: Text(label),
              selected: isSelected,
              selectedColor: AppColors.primary,
              backgroundColor: isDark ? AppColors.cardDark : AppColors.cardLight,
              labelStyle: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : (isDark ? Colors.white70 : AppColors.textPrimaryLight),
              ),
              onSelected: (val) {
                setState(() {
                  _genderController.text = val ? opt : '';
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context, _hasProfileChanges),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildAvatarHeader(auth, isDark),
              const SizedBox(height: 24),

              // 1. Basic & Professional Info Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : AppColors.cardLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.06),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('Basic & Identity', Icons.person_rounded, isDark),
                    _buildTextField(
                      controller: _displayNameController,
                      label: 'DISPLAY NAME',
                      hint: 'e.g. CineFlix Editorial',
                      icon: Icons.badge_outlined,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _firstNameController,
                            label: 'FIRST NAME',
                            hint: 'First name',
                            icon: Icons.person_outline_rounded,
                            isDark: isDark,
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Required';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            controller: _lastNameController,
                            label: 'LAST NAME',
                            hint: 'Last name',
                            icon: Icons.person_outline_rounded,
                            isDark: isDark,
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Required';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildFixedOrganizationField(isDark),
                    const SizedBox(height: 14),
                    _buildTextField(
                      controller: _designationController,
                      label: 'DESIGNATION',
                      hint: 'e.g. Senior Film Journalist',
                      icon: Icons.work_outline_rounded,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 14),
                    _buildTextField(
                      controller: _experienceController,
                      label: 'EXPERIENCE',
                      hint: 'e.g. 5+ Years in Entertainment News',
                      icon: Icons.timeline_rounded,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 14),
                    _buildTextField(
                      controller: _educationController,
                      label: 'EDUCATION',
                      hint: 'e.g. MA in Journalism & Mass Comm',
                      icon: Icons.school_outlined,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 2. Personal & Contact Info Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : AppColors.cardLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.06),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('Personal & Contact', Icons.contact_mail_rounded, isDark),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _dobController,
                            label: 'DATE OF BIRTH (DOB)',
                            hint: 'YYYY-MM-DD',
                            icon: Icons.cake_outlined,
                            readOnly: true,
                            onTap: () => _selectDob(context),
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(top: 22),
                          child: IconButton(
                            tooltip: 'Select Date',
                            icon: const Icon(Icons.calendar_month_rounded, color: AppColors.primary),
                            onPressed: () => _selectDob(context),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildGenderSelector(isDark),
                    const SizedBox(height: 14),
                    _buildTextField(
                      controller: _phoneController,
                      label: 'PHONE NUMBER',
                      hint: 'e.g. +91 9876543210',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 14),
                    _buildTextField(
                      controller: _emailController,
                      label: 'EMAIL ADDRESS',
                      hint: 'Author Email',
                      icon: Icons.email_outlined,
                      readOnly: true,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _cityController,
                            label: 'CITY',
                            hint: 'e.g. Mumbai',
                            icon: Icons.location_city_rounded,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            controller: _stateController,
                            label: 'STATE',
                            hint: 'e.g. Maharashtra',
                            icon: Icons.map_outlined,
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildTextField(
                      controller: _addressController,
                      label: 'ADDRESS',
                      hint: 'Full street address, area or landmark',
                      icon: Icons.place_outlined,
                      maxLines: 2,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 3. Bio / About Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : AppColors.cardLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.06),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('Author Bio', Icons.description_rounded, isDark),
                    _buildTextField(
                      controller: _descriptionController,
                      label: 'BIO / ABOUT',
                      hint: 'Brief description about you as an author/contributor',
                      icon: Icons.notes_rounded,
                      maxLines: 4,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 4. Social Profile Links Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : AppColors.cardLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.06),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('Social Profiles', Icons.share_rounded, isDark),
                    _buildTextField(
                      controller: _facebookController,
                      label: 'FACEBOOK',
                      hint: 'https://facebook.com/username or username',
                      icon: Icons.facebook_rounded,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 14),
                    _buildTextField(
                      controller: _instagramController,
                      label: 'INSTAGRAM',
                      hint: 'https://instagram.com/username or @username',
                      icon: Icons.camera_alt_outlined,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 14),
                    _buildTextField(
                      controller: _xTwitterController,
                      label: 'X (TWITTER)',
                      hint: 'https://x.com/username or @handle',
                      icon: Icons.alternate_email_rounded,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 14),
                    _buildTextField(
                      controller: _youtubeController,
                      label: 'YOUTUBE',
                      hint: 'https://youtube.com/@channel or channel link',
                      icon: Icons.smart_display_rounded,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 14),
                    _buildTextField(
                      controller: _linkedinController,
                      label: 'LINKEDIN',
                      hint: 'https://linkedin.com/in/username or profile URL',
                      icon: Icons.link_rounded,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Save button
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 3,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.save_rounded, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Save Changes',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 14),

              // Cancel button
              TextButton(
                onPressed: _isSaving ? null : () => Navigator.pop(context, _hasProfileChanges),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white60 : AppColors.textSecondaryLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
