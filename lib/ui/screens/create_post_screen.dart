import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/ad_service.dart';
import '../../data/models/article_model.dart';
import '../../data/models/category_model.dart';
import '../../data/repositories/news_repository.dart';
import '../../providers/auth_provider.dart';
import '../../providers/home_provider.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _mediaUrlController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  final NewsRepository _newsRepository = NewsRepository();

  List<CategoryModel> _categories = [];
  CategoryModel? _selectedCategory;
  bool _isLoadingCategories = true;

  XFile? _featuredImage;
  final List<XFile> _galleryMedia = [];

  bool _isSubmitting = false;
  String? _submittingStatus; // 'draft' or 'published'

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _contentController.dispose();
    _mediaUrlController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    // First try HomeProvider if already fetched
    final homeProvider = Provider.of<HomeProvider>(context, listen: false);
    if (homeProvider.categories.isNotEmpty) {
      setState(() {
        _categories = homeProvider.categories;
        _isLoadingCategories = false;
        if (_categories.isNotEmpty) {
          _selectedCategory = _categories.first;
        }
      });
      return;
    }

    try {
      final fetched = await _newsRepository.getCategories();
      if (!mounted) return;
      setState(() {
        _categories = fetched;
        _isLoadingCategories = false;
        if (_categories.isNotEmpty) {
          _selectedCategory = _categories.first;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingCategories = false;
      });
    }
  }

  Future<void> _pickFeaturedImage(ImageSource source) async {
    try {
      AdService().pauseAppOpenAds();
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() {
          _featuredImage = picked;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to select featured image: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      Future.delayed(const Duration(seconds: 2), () {
        AdService().resumeAppOpenAds();
      });
    }
  }

  void _showFeaturedImagePickerModal(bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.cardDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
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
                'Featured Image',
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
                onTap: () {
                  Navigator.pop(ctx);
                  _pickFeaturedImage(ImageSource.gallery);
                },
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
                onTap: () {
                  Navigator.pop(ctx);
                  _pickFeaturedImage(ImageSource.camera);
                },
              ),
              if (_featuredImage != null)
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 22),
                  ),
                  title: const Text('Remove Image', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _featuredImage = null);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickGalleryImages() async {
    try {
      AdService().pauseAppOpenAds();
      final images = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (images.isNotEmpty) {
        setState(() {
          _galleryMedia.addAll(images);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick gallery images: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      Future.delayed(const Duration(seconds: 2), () {
        AdService().resumeAppOpenAds();
      });
    }
  }

  Future<void> _pickGalleryVideo() async {
    try {
      AdService().pauseAppOpenAds();
      final video = await _picker.pickVideo(source: ImageSource.gallery);
      if (video != null) {
        setState(() {
          _galleryMedia.add(video);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick video: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      Future.delayed(const Duration(seconds: 2), () {
        AdService().resumeAppOpenAds();
      });
    }
  }

  void _showAddMediaOptions(bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.cardDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
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
                'Add Media to Gallery',
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
                  child: const Icon(Icons.collections_rounded, color: AppColors.primary, size: 22),
                ),
                title: const Text('Add Multiple Images', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Select photos from gallery', style: TextStyle(fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickGalleryImages();
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.video_collection_rounded, color: Colors.deepPurple, size: 22),
                ),
                title: const Text('Add Video File', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Select a video from gallery', style: TextStyle(fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickGalleryVideo();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitPost({required String status}) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final token = auth.token;
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to submit a post.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _submittingStatus = status;
    });

    try {
      final galleryPaths = _galleryMedia.map((f) => f.path).toList();

      final ArticleModel createdArticle = await _newsRepository.createAuthorPost(
        token: token,
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        categoryId: _selectedCategory?.id,
        status: status,
        featuredImagePath: _featuredImage?.path,
        galleryPaths: galleryPaths.isEmpty ? null : galleryPaths,
        mediaUrl: _mediaUrlController.text.trim().isEmpty ? null : _mediaUrlController.text.trim(),
        tags: _tagsController.text.trim().isEmpty ? null : _tagsController.text.trim(),
      );

      // Refresh author dashboard metrics
      await auth.loadDashboard(refresh: true, silent: true);

      if (!mounted) return;

      final isPublished = status == 'published';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isPublished ? Icons.check_circle_rounded : Icons.save_rounded,
                color: Colors.white,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isPublished
                      ? 'Post published successfully!'
                      : 'Post draft saved successfully!',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: isPublished ? Colors.green.shade700 : Colors.blueGrey.shade800,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

      Navigator.pop(context, createdArticle);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save post: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _submittingStatus = null;
        });
      }
    }
  }

  Widget _buildSectionHeader(String title, IconData icon, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
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
            fillColor: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.03),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? Colors.white12 : Colors.black12,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? Colors.white12 : Colors.black12,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CATEGORY',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
            color: isDark ? Colors.white70 : AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.white12 : Colors.black12,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: _isLoadingCategories
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text('Loading live categories...', style: TextStyle(fontSize: 13)),
                      ),
                    ],
                  ),
                )
              : DropdownButtonHideUnderline(
                  child: DropdownButton<CategoryModel>(
                    isExpanded: true,
                    value: _selectedCategory,
                    hint: const Text('Select a Category'),
                    dropdownColor: isDark ? AppColors.cardDark : Colors.white,
                    icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
                    items: _categories.map((cat) {
                      return DropdownMenuItem<CategoryModel>(
                        value: cat,
                        child: Row(
                          children: [
                            const Icon(Icons.folder_outlined, size: 16, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                cat.name,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : AppColors.textPrimaryLight,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedCategory = val);
                      }
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildFeaturedImageSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'FEATURED IMAGE',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
                color: isDark ? Colors.white70 : AppColors.textSecondaryLight,
              ),
            ),
            if (_featuredImage != null)
              GestureDetector(
                onTap: () => _showFeaturedImagePickerModal(isDark),
                child: const Text(
                  'Change',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        if (_featuredImage != null) ...[
          Container(
            height: 190,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(
                    File(_featuredImage!.path),
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => setState(() => _featuredImage = null),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 14),
                          SizedBox(width: 4),
                          Text('Featured Image Attached', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ] else ...[
          InkWell(
            onTap: () => _showFeaturedImagePickerModal(isDark),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.black.withValues(alpha: 0.02),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? Colors.white24 : Colors.black12,
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add_photo_alternate_rounded, color: AppColors.primary, size: 26),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Upload Featured Image',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Supports JPG, PNG, WEBP (tap to browse)',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white54 : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMediaGallerySection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'MEDIA GALLERY (${_galleryMedia.length})',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
                color: isDark ? Colors.white70 : AppColors.textSecondaryLight,
              ),
            ),
            GestureDetector(
              onTap: () => _showAddMediaOptions(isDark),
              child: const Row(
                children: [
                  Icon(Icons.add, size: 14, color: AppColors.primary),
                  SizedBox(width: 2),
                  Text(
                    'Add Media',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_galleryMedia.isEmpty)
          InkWell(
            onTap: () => _showAddMediaOptions(isDark),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              height: 90,
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.03)
                    : Colors.black.withValues(alpha: 0.02),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? Colors.white12 : Colors.black12,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.perm_media_outlined, color: isDark ? Colors.white38 : Colors.black38, size: 24),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        'Add gallery images or video clips',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white54 : AppColors.textSecondaryLight,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _galleryMedia.length + 1,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                if (index == _galleryMedia.length) {
                  return InkWell(
                    onTap: () => _showAddMediaOptions(isDark),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 90,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.black.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_circle_outline, color: AppColors.primary, size: 24),
                          SizedBox(height: 4),
                          Text('Add More', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary)),
                        ],
                      ),
                    ),
                  );
                }

                final file = _galleryMedia[index];
                final isVideo = file.path.toLowerCase().endsWith('.mp4') ||
                    file.path.toLowerCase().endsWith('.mov') ||
                    file.path.toLowerCase().endsWith('.m4v');

                return Container(
                  width: 110,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? Colors.white24 : Colors.black12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (isVideo)
                          Container(
                            color: Colors.black87,
                            child: const Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 32),
                                  SizedBox(height: 4),
                                  Text('VIDEO', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w800)),
                                ],
                              ),
                            ),
                          )
                        else
                          Image.file(
                            File(file.path),
                            fit: BoxFit.cover,
                          ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _galleryMedia.removeAt(index);
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.75),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, color: Colors.white, size: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Create New Post'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  children: [
                    _buildSectionHeader('BASIC INFORMATION', Icons.article_rounded, isDark),
                    const SizedBox(height: 4),

                    // 1. Title
                    _buildTextField(
                      controller: _titleController,
                      label: 'POST TITLE *',
                      hint: 'Enter a catchy, informative headline',
                      icon: Icons.title_rounded,
                      isDark: isDark,
                      maxLines: 2,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Please enter a post title';
                        }
                        if (val.trim().length < 5) {
                          return 'Title should be at least 5 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // 2. Category Dropdown
                    _buildCategoryDropdown(isDark),
                    const SizedBox(height: 14),

                    // 3. Short Description / Excerpt
                    _buildTextField(
                      controller: _descriptionController,
                      label: 'SHORT DESCRIPTION / EXCERPT',
                      hint: 'Brief summary of the article (appears in feeds and cards)',
                      icon: Icons.short_text_rounded,
                      isDark: isDark,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 14),

                    // 4. Full Content
                    _buildTextField(
                      controller: _contentController,
                      label: 'FULL ARTICLE CONTENT *',
                      hint: 'Write or paste the full body text here...',
                      icon: Icons.notes_rounded,
                      isDark: isDark,
                      maxLines: 8,
                      keyboardType: TextInputType.multiline,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Please enter the full article content';
                        }
                        if (val.trim().length < 20) {
                          return 'Content should be at least 20 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    _buildSectionHeader('MEDIA & ATTACHMENTS', Icons.perm_media_rounded, isDark),
                    const SizedBox(height: 4),

                    // 5. Featured Image
                    _buildFeaturedImageSection(isDark),
                    const SizedBox(height: 16),

                    // 6. Media Gallery
                    _buildMediaGallerySection(isDark),
                    const SizedBox(height: 16),

                    // 7. Media URL Field
                    _buildTextField(
                      controller: _mediaUrlController,
                      label: 'MEDIA URL (YOUTUBE / VIDEO / PODCAST)',
                      hint: 'https://youtube.com/watch?v=... or direct MP4/stream URL',
                      icon: Icons.link_rounded,
                      isDark: isDark,
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: 16),

                    _buildSectionHeader('TAGS & KEYWORDS', Icons.label_outline_rounded, isDark),
                    const SizedBox(height: 4),

                    // 8. Tags
                    _buildTextField(
                      controller: _tagsController,
                      label: 'TAGS / KEYWORDS',
                      hint: 'Bollywood, Exclusive, Movies, OTT (comma-separated)',
                      icon: Icons.tag_rounded,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),

              // Bottom Action Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : Colors.white,
                  border: Border(
                    top: BorderSide(
                      color: isDark ? Colors.white12 : Colors.black12,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Save Draft Button
                    Expanded(
                      flex: 4,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(
                            color: isDark ? Colors.white24 : Colors.black26,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _isSubmitting ? null : () => _submitPost(status: 'draft'),
                        icon: _isSubmitting && _submittingStatus == 'draft'
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey),
                              )
                            : const Icon(Icons.drafts_outlined, size: 18),
                        label: Text(
                          _isSubmitting && _submittingStatus == 'draft' ? 'Saving...' : 'Save Draft',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Publish Button
                    Expanded(
                      flex: 5,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        onPressed: _isSubmitting ? null : () => _submitPost(status: 'published'),
                        icon: _isSubmitting && _submittingStatus == 'published'
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.publish_rounded, size: 18),
                        label: Text(
                          _isSubmitting && _submittingStatus == 'published' ? 'Publishing...' : 'Publish',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
