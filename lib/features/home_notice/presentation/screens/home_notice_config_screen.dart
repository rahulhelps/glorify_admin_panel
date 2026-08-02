import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';

class HomeNoticeConfigScreen extends StatefulWidget {
  const HomeNoticeConfigScreen({super.key});

  @override
  State<HomeNoticeConfigScreen> createState() => _HomeNoticeConfigScreenState();
}

class _HomeNoticeConfigScreenState extends State<HomeNoticeConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  // Controllers for text fields
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _noticeTextController = TextEditingController();

  // State variables for document fields
  bool _isActive = false;
  String? _currentImageUrl;
  File? _selectedImage;

  // Loading & Progress States
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  DateTime? _lastUpdatedAt;

  @override
  void initState() {
    super.initState();
    _fetchNoticeConfig();
  }

  @override
  void dispose() {
    _textController.dispose();
    _noticeTextController.dispose();
    super.dispose();
  }

  // ── Fetch Initial Data from Firestore (app_config/home_notice) ─────────────
  Future<void> _fetchNoticeConfig() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final doc = await _firestore.collection('app_config').doc('home_notice').get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        setState(() {
          _isActive = data['isActive'] ?? false;
          _textController.text = (data['text'] ?? '').toString();
          _noticeTextController.text = (data['noticeText'] ?? '').toString();
          _currentImageUrl = data['imageUrl'] as String?;
          _selectedImage = null;

          if (data['updatedAt'] is Timestamp) {
            _lastUpdatedAt = (data['updatedAt'] as Timestamp).toDate();
          }
        });
      } else {
        setState(() {
          _isActive = false;
          _textController.text = '';
          _noticeTextController.text = '';
          _currentImageUrl = null;
          _selectedImage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load notice configuration: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ── Image Picker from Gallery ──────────────────────────────────────────────
  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to pick image: $e', isError: true);
      }
    }
  }

  // ── Dynamic Cloudinary Upload Logic ────────────────────────────────────────
  Future<String?> _uploadImageToCloudinary(File imageFile) async {
    // 1. Fetch Cloudinary credentials dynamically from Firestore
    final credDoc = await _firestore.collection('app_config').doc('cloudinary').get();
    if (!credDoc.exists || credDoc.data() == null) {
      throw Exception('Cloudinary configuration not found in app_config/cloudinary');
    }

    final credData = credDoc.data()!;
    final cloudName = (credData['cloudName'] ?? credData['cloud_name'] ?? '').toString().trim();
    final uploadPreset = (credData['uploadPreset'] ?? credData['upload_preset'] ?? '').toString().trim();

    if (cloudName.isEmpty || uploadPreset.isEmpty) {
      throw Exception('Cloud Name or Upload Preset is missing in Cloudinary settings.');
    }

    // 2. Build multipart POST request
    final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
    final request = http.MultipartRequest('POST', uri);
    request.fields['upload_preset'] = uploadPreset;
    request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    // 3. Send request and parse response
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final jsonResponse = json.decode(response.body) as Map<String, dynamic>;
      final secureUrl = jsonResponse['secure_url']?.toString() ?? jsonResponse['url']?.toString();
      if (secureUrl != null && secureUrl.isNotEmpty) {
        return secureUrl;
      } else {
        throw Exception('Cloudinary did not return a valid image URL');
      }
    } else {
      throw Exception('Cloudinary upload failed (${response.statusCode}): ${response.body}');
    }
  }

  // ── Save/Update All 4 Fields in Firestore ───────────────────────────────────
  Future<void> _updateNotice() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isSaving = true;
    });

    try {
      String? finalImageUrl = _currentImageUrl;

      // 1. Upload new image if selected
      if (_selectedImage != null) {
        final uploadedUrl = await _uploadImageToCloudinary(_selectedImage!);
        if (uploadedUrl != null && uploadedUrl.isNotEmpty) {
          finalImageUrl = uploadedUrl;
        }
      }

      // 2. Save all 4 fields to Firestore: app_config/home_notice
      await _firestore.collection('app_config').doc('home_notice').set({
        'text': _textController.text.trim(),
        'noticeText': _noticeTextController.text.trim(),
        'isActive': _isActive,
        'imageUrl': finalImageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      setState(() {
        _currentImageUrl = finalImageUrl;
        _selectedImage = null;
        _lastUpdatedAt = DateTime.now();
      });

      if (mounted) {
        _showSnackBar('Home Notice updated successfully!');
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to update notice: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // ── Helper SnackBar ────────────────────────────────────────────────────────
  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline_rounded : Icons.check_circle_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Home Notice Configuration',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Reload Settings',
            onPressed: _isLoading || _isSaving ? null : _fetchNoticeConfig,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _errorMessage != null
              ? _buildErrorView()
              : _buildContent(),
    );
  }

  // ── Error View ─────────────────────────────────────────────────────────────
  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 56, color: AppColors.error),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Failed to Load Notice',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _errorMessage ?? 'An unexpected error occurred.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: _fetchNoticeConfig,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Main Content View ──────────────────────────────────────────────────────
  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Guide / Info Card
            _buildGuideCard(),
            const SizedBox(height: AppSpacing.lg),

            // 2. Live Preview Card
            _buildLivePreviewCard(),
            const SizedBox(height: AppSpacing.lg),

            // 3. Active Status Switch Card
            _buildStatusSwitchCard(),
            const SizedBox(height: AppSpacing.lg),

            // 4. Banner Image Section Card
            _buildImageUploadCard(),
            const SizedBox(height: AppSpacing.lg),

            // 5. Global Earn Notice Text (noticeText) Card
            _buildNoticeTextCard(),
            const SizedBox(height: AppSpacing.lg),

            // 6. Home Scrolling Notice Text (text) Card
            _buildScrollingNoticeCard(),
            const SizedBox(height: AppSpacing.xl),

            // 7. Update Notice Action Button
            _buildSaveButton(),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  // ── 1. Guide & Info Card ───────────────────────────────────────────────────
  Widget _buildGuideCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md + 2),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF), // Soft Blue
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFBFDBFE)),
        boxShadow: AppShadows.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.campaign_rounded, color: Color(0xFF2563EB), size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dynamic Home Notice Controls',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: const Color(0xFF1E40AF),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Manage all 4 notice fields (Status, Image, Global Notice, and Scrolling Text) directly in Firestore (app_config/home_notice). Uploaded images are securely stored in Cloudinary.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF1E3A8A),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 2. Live Preview Card ───────────────────────────────────────────────────
  Widget _buildLivePreviewCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _isActive ? AppColors.success : AppColors.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Live App Preview',
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _isActive
                            ? AppColors.success.withValues(alpha: 0.12)
                            : AppColors.error.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _isActive ? 'ACTIVE' : 'INACTIVE',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: _isActive ? AppColors.success : AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_lastUpdatedAt != null)
                Text(
                  'Updated: ${DateFormat('dd MMM, hh:mm a').format(_lastUpdatedAt!)}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textHint,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Scrolling Marquee Preview
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                const Icon(Icons.volume_up_rounded, color: AppColors.primaryDark, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _textController.text.trim().isNotEmpty
                        ? _textController.text.trim()
                        : 'No scrolling notice set (Field: text)',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _textController.text.trim().isNotEmpty
                          ? AppColors.textPrimary
                          : AppColors.textHint,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 3. Notice Active Status Switch Card (isActive) ─────────────────────────
  Widget _buildStatusSwitchCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.sm,
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
        title: Text(
          'Notice Active Status',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          'Toggle whether the notice banner and popup are displayed on the user app.',
          style: GoogleFonts.inter(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
        activeThumbColor: AppColors.primary,
        activeTrackColor: AppColors.primary.withValues(alpha: 0.4),
        value: _isActive,
        onChanged: (val) {
          setState(() {
            _isActive = val;
          });
        },
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }

  // ── 4. Notice Banner Image Card (imageUrl) ─────────────────────────────────
  Widget _buildImageUploadCard() {
    final bool hasLocalImage = _selectedImage != null;
    final bool hasNetworkImage = _currentImageUrl != null && _currentImageUrl!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.image_rounded, color: AppColors.primaryDark, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Notice Banner Image',
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (hasLocalImage || hasNetworkImage)
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                  tooltip: 'Remove Image',
                  onPressed: () {
                    setState(() {
                      _selectedImage = null;
                      _currentImageUrl = null;
                    });
                  },
                ),
            ],
          ),
          const Divider(height: 24, color: AppColors.divider),

          // Image Preview / Upload Box
          Container(
            width: double.infinity,
            height: 180,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (hasLocalImage)
                  Image.file(
                    _selectedImage!,
                    fit: BoxFit.cover,
                  )
                else if (hasNetworkImage)
                  Image.network(
                    _currentImageUrl!,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(color: AppColors.primary),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(Icons.broken_image_rounded, size: 40, color: AppColors.textHint),
                      );
                    },
                  )
                else
                  InkWell(
                    onTap: _pickImage,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 48,
                          color: AppColors.primary.withValues(alpha: 0.7),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Tap to select banner image from gallery',
                          style: GoogleFonts.inter(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Badge when new local image selected
                if (hasLocalImage)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'New Image Selected (Pending Save)',
                        style: GoogleFonts.inter(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Upload Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isSaving ? null : _pickImage,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.photo_library_rounded, size: 18),
              label: Text(
                hasLocalImage || hasNetworkImage ? 'Change Image' : 'Select Image from Gallery',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 5. Global Earn Notice Text Card (noticeText) ───────────────────────────
  Widget _buildNoticeTextCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.article_rounded, color: AppColors.primaryDark, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Global Notice Text',
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildFieldHelpers(_noticeTextController),
            ],
          ),
          const Divider(height: 24, color: AppColors.divider),
          TextFormField(
            controller: _noticeTextController,
            minLines: 3,
            maxLines: 5,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Enter comprehensive notice text or announcement details...',
              prefixIcon: const Padding(
                padding: EdgeInsets.only(bottom: 48),
                child: Icon(Icons.description_outlined, size: 20, color: AppColors.primary),
              ),
              suffixIcon: _noticeTextController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.cancel_rounded, size: 18, color: AppColors.textHint),
                      tooltip: 'Clear Text',
                      onPressed: () => setState(() => _noticeTextController.clear()),
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  // ── 6. Home Scrolling Notice Text Card (text) ──────────────────────────────
  Widget _buildScrollingNoticeCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.view_headline_rounded, color: AppColors.primaryDark, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Scrolling Notice Text',
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildFieldHelpers(_textController),
            ],
          ),
          const Divider(height: 24, color: AppColors.divider),
          TextFormField(
            controller: _textController,
            minLines: 2,
            maxLines: 3,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Enter short scrolling marquee notice for top home banner...',
              prefixIcon: const Padding(
                padding: EdgeInsets.only(bottom: 24),
                child: Icon(Icons.campaign_outlined, size: 20, color: AppColors.primary),
              ),
              suffixIcon: _textController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.cancel_rounded, size: 18, color: AppColors.textHint),
                      tooltip: 'Clear Text',
                      onPressed: () => setState(() => _textController.clear()),
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  // ── Helper Paste & Clear Row ───────────────────────────────────────────────
  Widget _buildFieldHelpers(TextEditingController controller) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () async {
            final data = await Clipboard.getData('text/plain');
            if (data?.text != null && data!.text!.isNotEmpty) {
              setState(() {
                controller.text = data.text!;
              });
            }
          },
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.paste_rounded, size: 14, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(
                  'Paste',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (controller.text.isNotEmpty) ...[
          const SizedBox(width: 6),
          InkWell(
            onTap: () => setState(() => controller.clear()),
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.clear_all_rounded, size: 14, color: AppColors.textHint),
                  const SizedBox(width: 4),
                  Text(
                    'Clear',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textHint,
                      fontWeight: FontWeight.w500,
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

  // ── 7. Save / Update Notice Button ─────────────────────────────────────────
  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: _isSaving ? null : _updateNotice,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.cloud_upload_rounded, color: Colors.white, size: 20),
        label: Text(
          _isSaving ? 'Uploading & Updating Notice...' : 'Update Notice',
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
