import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_theme.dart';

class HomeBannerScreen extends StatefulWidget {
  const HomeBannerScreen({super.key});

  @override
  State<HomeBannerScreen> createState() => _HomeBannerScreenState();
}

class _HomeBannerScreenState extends State<HomeBannerScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  bool _isUploading = false;
  String _uploadStatusText = '';
  double _uploadProgress = 0.0;

  // ── Fetch Cloudinary Credentials ───────────────────────────────────────────
  Future<Map<String, String>?> _getCloudinaryCredentials() async {
    try {
      final doc = await _firestore.collection('app_config').doc('cloudinary').get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final cloudName = (data['cloudName'] ?? data['cloud_name'] ?? '').toString().trim();
        final uploadPreset =
            (data['uploadPreset'] ?? data['upload_preset'] ?? '').toString().trim();

        if (cloudName.isNotEmpty && uploadPreset.isNotEmpty) {
          return {'cloudName': cloudName, 'uploadPreset': uploadPreset};
        }
      }
    } catch (e) {
      debugPrint('Error fetching Cloudinary credentials: $e');
    }
    return null;
  }

  // ── Pick and Upload Banners to Cloudinary ───────────────────────────────────
  Future<void> _pickAndUploadBanners() async {
    // 1. Fetch Cloudinary config first
    final credentials = await _getCloudinaryCredentials();
    if (!mounted) return;

    if (credentials == null) {
      _showCloudinaryConfigMissingDialog();
      return;
    }

    final cloudName = credentials['cloudName']!;
    final uploadPreset = credentials['uploadPreset']!;

    try {
      // 2. Pick images (multiple selection)
      final List<XFile> pickedFiles = await _picker.pickMultiImage(
        imageQuality: 85,
      );

      if (pickedFiles.isEmpty) return;

      setState(() {
        _isUploading = true;
        _uploadProgress = 0.0;
        _uploadStatusText = 'Preparing ${pickedFiles.length} image(s)...';
      });

      final List<String> uploadedUrls = [];

      for (int i = 0; i < pickedFiles.length; i++) {
        final file = pickedFiles[i];
        final bytes = await file.readAsBytes();
        final filename = file.name.isNotEmpty ? file.name : 'banner_$i.jpg';

        setState(() {
          _uploadProgress = (i) / pickedFiles.length;
          _uploadStatusText = 'Uploading image ${i + 1} of ${pickedFiles.length}...';
        });

        final secureUrl = await _uploadSingleImageToCloudinary(
          bytes: bytes,
          filename: filename,
          cloudName: cloudName,
          uploadPreset: uploadPreset,
        );

        if (secureUrl != null && secureUrl.isNotEmpty) {
          uploadedUrls.add(secureUrl);
        }
      }

      if (uploadedUrls.isEmpty) {
        if (mounted) {
          _showSnackBar('No images were uploaded successfully.', isError: true);
        }
        return;
      }

      // 3. Update Firestore array using arrayUnion
      setState(() {
        _uploadStatusText = 'Saving to database...';
        _uploadProgress = 1.0;
      });

      await _firestore.collection('app_config').doc('home_banner').set({
        'images': FieldValue.arrayUnion(uploadedUrls),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        _showSnackBar(
          'Successfully uploaded ${uploadedUrls.length} banner(s)!',
          isError: false,
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Upload failed: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadStatusText = '';
          _uploadProgress = 0.0;
        });
      }
    }
  }

  // ── Cloudinary REST API Upload Helper ──────────────────────────────────────
  Future<String?> _uploadSingleImageToCloudinary({
    required Uint8List bytes,
    required String filename,
    required String cloudName,
    required String uploadPreset,
  }) async {
    final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

    final request = http.MultipartRequest('POST', uri);
    request.fields['upload_preset'] = uploadPreset;

    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: filename,
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      return data['secure_url']?.toString() ?? data['url']?.toString();
    } else {
      debugPrint('Cloudinary Error: ${response.statusCode} - ${response.body}');
      throw Exception('Cloudinary upload error (${response.statusCode}): ${response.body}');
    }
  }

  // ── Delete Banner ──────────────────────────────────────────────────────────
  Future<void> _deleteBanner(String imageUrl) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
        title: Row(
          children: [
            const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 24),
            const SizedBox(width: 8),
            Text(
              'Delete Banner',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete this banner?',
          style: TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _firestore.collection('app_config').doc('home_banner').update({
        'images': FieldValue.arrayRemove([imageUrl]),
      });

      if (mounted) {
        _showSnackBar('Banner deleted successfully.');
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to delete banner: $e', isError: true);
      }
    }
  }

  // ── Helper Snackbar ────────────────────────────────────────────────────────
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
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      ),
    );
  }

  // ── Missing Cloudinary Config Dialog ───────────────────────────────────────
  void _showCloudinaryConfigMissingDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
        title: Row(
          children: [
            const Icon(Icons.cloud_off_rounded, color: AppColors.warning, size: 24),
            const SizedBox(width: 8),
            Text('Cloudinary Not Configured', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16)),
          ],
        ),
        content: const Text(
          'Please configure your Cloud Name and Upload Preset in the Cloudinary Config settings screen before uploading banners.',
          style: TextStyle(fontSize: 13),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Home Banner Management'),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isUploading ? null : _pickAndUploadBanners,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_photo_alternate_rounded, color: Colors.white),
        label: Text(
          'Add Banner',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          // ── Uploading Status Progress Bar ──────────────────────────────────
          if (_isUploading) _buildUploadProgressBanner(),

          // ── Real-Time Banner Stream ────────────────────────────────────────
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: _firestore.collection('app_config').doc('home_banner').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'Failed to load home banners',
                            style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            snapshot.error.toString(),
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
                final rawImages = data['images'] as List<dynamic>? ?? [];
                final List<String> imageUrls =
                    rawImages.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();

                if (imageUrls.isEmpty) {
                  return _buildEmptyState();
                }

                return Column(
                  children: [
                    // Summary ribbon
                    _buildHeaderRibbon(imageUrls.length),

                    // Grid View
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          // Responsive column count
                          int crossAxisCount = 1;
                          if (constraints.maxWidth > 1200) {
                            crossAxisCount = 3;
                          } else if (constraints.maxWidth > 650) {
                            crossAxisCount = 2;
                          }

                          return GridView.builder(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              crossAxisSpacing: AppSpacing.md,
                              mainAxisSpacing: AppSpacing.md,
                              childAspectRatio: 16 / 9,
                            ),
                            itemCount: imageUrls.length,
                            itemBuilder: (context, index) {
                              final url = imageUrls[index];
                              return _BannerCard(
                                imageUrl: url,
                                index: index + 1,
                                onDelete: () => _deleteBanner(url),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Upload Progress Bar Widget ─────────────────────────────────────────────
  Widget _buildUploadProgressBanner() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        border: const Border(bottom: BorderSide(color: AppColors.primary, width: 1.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _uploadStatusText,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
              Text(
                '${(_uploadProgress * 100).toInt()}%',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: _uploadProgress > 0 ? _uploadProgress : null,
            backgroundColor: AppColors.border,
            color: AppColors.primary,
            minHeight: 4,
            borderRadius: BorderRadius.circular(2),
          ),
        ],
      ),
    );
  }

  // ── Header Ribbon ──────────────────────────────────────────────────────────
  Widget _buildHeaderRibbon(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm + 2),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.photo_library_outlined, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Active Banners ($count)',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.successBg,
                  borderRadius: AppRadius.smAll,
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.cloud_done_rounded, size: 12, color: AppColors.success),
                    const SizedBox(width: 4),
                    Text(
                      'Cloudinary Active',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Empty State ────────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add_photo_alternate_outlined, size: 56, color: AppColors.textHint),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'No Home Banners Yet',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'Upload banner images to display in the main carousel slider on the mobile user home screen.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton.icon(
              onPressed: _pickAndUploadBanners,
              icon: const Icon(Icons.upload_file_rounded),
              label: const Text('Add First Banner'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Banner Card Component
// ─────────────────────────────────────────────────────────────────────────────
class _BannerCard extends StatelessWidget {
  const _BannerCard({
    required this.imageUrl,
    required this.index,
    required this.onDelete,
  });

  final String imageUrl;
  final int index;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.sm,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── 1. Image Display ───────────────────────────────────────────────
          Image.network(
            imageUrl,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                color: AppColors.surfaceVariant,
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: AppColors.surfaceVariant,
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image_rounded, size: 36, color: AppColors.textHint),
                      SizedBox(height: 6),
                      Text('Image failed to load', style: TextStyle(fontSize: 11, color: AppColors.textHint)),
                    ],
                  ),
                ),
              );
            },
          ),

          // ── 2. Tap to View Fullscreen (Background ink) ─────────────────────
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _openFullScreenPreview(context, imageUrl),
              ),
            ),
          ),

          // ── 3. Gradient Overlay on Top & Bottom (Ignore Pointer) ───────────
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.55),
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.6),
                    ],
                    stops: const [0.0, 0.3, 0.7, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // ── 4. Index Badge (Top Left) ──────────────────────────────────────
          Positioned(
            top: 10,
            left: 10,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: AppRadius.smAll,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                ),
                child: Text(
                  'Slide #$index',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ),

          // ── 5. Action Buttons (Top Right: Copy & Prominent Delete) ──────────
          Positioned(
            top: 8,
            right: 8,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Copy URL button
                Material(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: imageUrl));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Banner URL copied to clipboard'),
                          duration: Duration(seconds: 1),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(Icons.copy_rounded, color: Colors.white, size: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Prominent Delete button (Red circular background)
                Material(
                  color: AppColors.error,
                  elevation: 2,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onDelete,
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(
                        Icons.delete_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openFullScreenPreview(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: AppRadius.lgAll,
              child: InteractiveViewer(
                child: Image.network(url, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                style: IconButton.styleFrom(backgroundColor: Colors.black54),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
