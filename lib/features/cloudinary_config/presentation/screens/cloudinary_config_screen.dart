import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';

class CloudinaryConfigScreen extends StatefulWidget {
  const CloudinaryConfigScreen({super.key});

  @override
  State<CloudinaryConfigScreen> createState() => _CloudinaryConfigScreenState();
}

class _CloudinaryConfigScreenState extends State<CloudinaryConfigScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _cloudNameController = TextEditingController();
  final TextEditingController _uploadPresetController = TextEditingController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchCloudinaryConfig();
  }

  @override
  void dispose() {
    _cloudNameController.dispose();
    _uploadPresetController.dispose();
    super.dispose();
  }

  // ── Fetch existing Cloudinary credentials from Firestore ───────────────────
  Future<void> _fetchCloudinaryConfig() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final doc = await _firestore.collection('app_config').doc('cloudinary').get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        _cloudNameController.text = (data['cloudName'] ?? data['cloud_name'] ?? '').toString();
        _uploadPresetController.text =
            (data['uploadPreset'] ?? data['upload_preset'] ?? '').toString();
      } else {
        _cloudNameController.text = '';
        _uploadPresetController.text = '';
      }
    } catch (e) {
      _errorMessage = 'Failed to load Cloudinary settings: $e';
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ── Save or update Cloudinary credentials in Firestore ────────────────────
  Future<void> _saveCloudinaryConfig() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Hide keyboard
    FocusScope.of(context).unfocus();

    setState(() {
      _isSaving = true;
    });

    final cloudName = _cloudNameController.text.trim();
    final uploadPreset = _uploadPresetController.text.trim();

    try {
      await _firestore.collection('app_config').doc('cloudinary').set({
        'cloudName': cloudName,
        'uploadPreset': uploadPreset,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Cloudinary configuration saved successfully!',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text('Failed to save configuration: $e')),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Cloudinary Configuration'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Reload Settings',
            onPressed: _isLoading || _isSaving ? null : _fetchCloudinaryConfig,
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
              'Failed to Load Settings',
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
              onPressed: _fetchCloudinaryConfig,
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
            // ── Information & Guide Card ─────────────────────────────────────
            _buildGuideCard(),
            const SizedBox(height: AppSpacing.lg),

            // ── Configuration Form Card ──────────────────────────────────────
            _buildFormCard(),
            const SizedBox(height: AppSpacing.xl),

            // ── Save / Update Action Button ──────────────────────────────────
            _buildSaveButton(),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  // ── Information & Guide Card ───────────────────────────────────────────────
  Widget _buildGuideCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md + 4),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF), // Light Blue
        borderRadius: AppRadius.lgAll,
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
              borderRadius: AppRadius.mdAll,
            ),
            child: const Icon(Icons.cloud_queue_rounded, color: Color(0xFF2563EB), size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cloudinary Storage Integration',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: const Color(0xFF1E40AF),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'These credentials allow your mobile apps and admin panel to upload images (profile pictures, payment slips, offer banners, task proofs) directly to Cloudinary using unsigned upload presets.',
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

  // ── Configuration Form Card ────────────────────────────────────────────────
  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: AppRadius.mdAll,
                ),
                child: const Icon(Icons.tune_rounded, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cloudinary Credentials',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  // const Text(
                  //   'Stored in Firestore: collection "app_config" → document "cloudinary"',
                  //   style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  // ),
                ],
              ),
            ],
          ),
          const Divider(height: 28, color: AppColors.divider),

          // ── Cloud Name Field ───────────────────────────────────────────────
          Text(
            'Cloud Name',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _cloudNameController,
            decoration: InputDecoration(
              hintText: 'e.g. dxxyz1234',
              prefixIcon: const Icon(Icons.cloud_outlined, size: 20, color: AppColors.primary),
              suffixIcon: _cloudNameController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 16, color: AppColors.textHint),
                      tooltip: 'Copy Cloud Name',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _cloudNameController.text.trim()));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Cloud Name copied')),
                        );
                      },
                    )
                  : null,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter the Cloud Name';
              }
              return null;
            },
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Upload Preset Field ────────────────────────────────────────────
          Text(
            'Upload Preset',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _uploadPresetController,
            decoration: InputDecoration(
              hintText: 'e.g. glorify_unsigned_preset',
              prefixIcon: const Icon(Icons.vpn_key_outlined, size: 20, color: AppColors.primary),
              suffixIcon: _uploadPresetController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 16, color: AppColors.textHint),
                      tooltip: 'Copy Upload Preset',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _uploadPresetController.text.trim()));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Upload Preset copied')),
                        );
                      },
                    )
                  : null,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter the Upload Preset';
              }
              return null;
            },
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }

  // ── Save Button Widget ─────────────────────────────────────────────────────
  Widget _buildSaveButton() {
    return SizedBox(
      height: 50,
      child: ElevatedButton.icon(
        onPressed: _isSaving ? null : _saveCloudinaryConfig,
        icon: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.save_rounded, color: Colors.white),
        label: Text(
          _isSaving ? 'Saving Configuration...' : 'Save Cloudinary Settings',
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
        ),
      ),
    );
  }
}
