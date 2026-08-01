import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../../../../core/theme/app_theme.dart';

class HomeNoticeConfigScreen extends StatefulWidget {
  const HomeNoticeConfigScreen({super.key});

  @override
  State<HomeNoticeConfigScreen> createState() => _HomeNoticeConfigScreenState();
}

class _HomeNoticeConfigScreenState extends State<HomeNoticeConfigScreen> {
  // A placeholder string variable String imgBbApiKey = "YOUR_API_KEY_HERE";
  final String imgBbApiKey = "190bfc59ac32310fd883fb71a805a9d5";

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _noticeController = TextEditingController();

  bool _isActive = false;
  String? _imageUrl;
  File? _selectedLocalImage;
  
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    _fetchCurrentNotice();
  }

  @override
  void dispose() {
    _noticeController.dispose();
    super.dispose();
  }

  Future<void> _fetchCurrentNotice() async {
    try {
      final doc = await _firestore.collection('app_config').doc('home_notice').get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          setState(() {
            _isActive = data['isActive'] ?? false;
            _noticeController.text = data['noticeText'] ?? '';
            _imageUrl = data['imageUrl'];
          });
        }
      }
    } catch (e) {
      _showSnackBar('Failed to load notice configuration: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickAndUploadImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        print("Image successfully picked: ${pickedFile.path}");
        setState(() {
          _selectedLocalImage = File(pickedFile.path);
          _isUploadingImage = true;
        });

        await uploadToImgBB(_selectedLocalImage!);
      } else {
        print("User cancelled image picking operation.");
      }
    } catch (e) {
      print("CRITICAL ERROR DURING IMAGE PICKING: $e");
      _showSnackBar('Error picking image: $e', isError: true);
    }
  }

  Future<void> uploadToImgBB(File imageFile) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.imgbb.com/1/upload?key=$imgBbApiKey'),
      );
      request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonResponse = json.decode(responseData);

      if (response.statusCode == 200 && jsonResponse['success'] == true) {
        setState(() {
          _imageUrl = jsonResponse['data']['url'];
        });
        _showSnackBar('Image uploaded successfully!');
      } else {
        _showSnackBar('Failed to upload image to ImgBB.', isError: true);
        setState(() {
          _selectedLocalImage = null; // Revert
        });
      }
    } catch (e) {
      _showSnackBar('Network error during image upload: $e', isError: true);
      setState(() {
        _selectedLocalImage = null; // Revert
      });
    } finally {
      setState(() {
        _isUploadingImage = false;
      });
    }
  }

  Future<void> _saveConfiguration() async {
    setState(() {
      _isSaving = true;
    });

    try {
      await _firestore.collection('app_config').doc('home_notice').set({
        'isActive': _isActive,
        'noticeText': _noticeController.text.trim(),
        'imageUrl': _imageUrl,
      }, SetOptions(merge: true));

      _showSnackBar('কনফিগারেশন আপডেট করা হয়েছে!');
    } catch (e) {
      _showSnackBar('Failed to save configuration: $e', isError: true);
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.grey[800] : const Color(0xFF00CED1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Home Notice')),
        body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Home Notice')),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              // Active Toggle
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.lgAll,
                  border: Border.all(color: AppColors.border),
                  boxShadow: AppShadows.sm,
                ),
                child: SwitchListTile(
                  title: const Text('Notice Active Status',
                      style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  subtitle: const Text('Toggle to show or hide the notice banner in the app.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  activeColor: AppColors.primary,
                  value: _isActive,
                  onChanged: (val) => setState(() => _isActive = val),
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Notice Text Field
              const Text('Notice Text',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: AppSpacing.sm),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.lgAll,
                  border: Border.all(color: AppColors.border),
                  boxShadow: AppShadows.sm,
                ),
                child: TextFormField(
                  controller: _noticeController,
                  maxLines: null,
                  minLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Enter free text, emojis, or external links here...',
                    border: OutlineInputBorder(
                      borderRadius: AppRadius.lgAll,
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(AppSpacing.md),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Image Upload Canvas
              const Text('Notice Banner Image',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: AppSpacing.sm),
              _buildImageCanvas(),

              const SizedBox(height: AppSpacing.xxl),

              // Global Save Button
              ElevatedButton(
                onPressed: _isUploadingImage ? null : _saveConfiguration,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('কনফিগারেশন আপডেট করুন',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
        if (_isSaving)
          Container(
            color: Colors.black.withValues(alpha: 0.3),
            child: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          ),
      ],
      ),
    );
  }

  Widget _buildImageCanvas() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: AppRadius.lgAll,
        boxShadow: AppShadows.sm,
      ),
      child: Material(
        color: AppColors.surface,
        borderRadius: AppRadius.lgAll,
        child: InkWell(
          onTap: _isUploadingImage ? null : _pickAndUploadImage,
          borderRadius: AppRadius.lgAll,
          child: CustomPaint(
            painter: _DashedBorderPainter(color: AppColors.primary),
            child: SizedBox(
              height: 200,
              width: double.infinity,
              child: ClipRRect(
                borderRadius: AppRadius.lgAll,
                child: _buildImageCanvasContent(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageCanvasContent() {
    if (_isUploadingImage) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_selectedLocalImage != null)
            Expanded(
              child: Opacity(
                opacity: 0.5,
                child: Image.file(_selectedLocalImage!, fit: BoxFit.cover, width: double.infinity),
              ),
            ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.0),
            child: LinearProgressIndicator(color: Color(0xFF00CED1)),
          ),
          const SizedBox(height: 8),
          const Text('Uploading to ImgBB...', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
        ],
      );
    }

    if (_imageUrl != null && _imageUrl!.isNotEmpty) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            _imageUrl!,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const Center(child: CircularProgressIndicator(color: AppColors.primary));
            },
            errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 50, color: AppColors.textHint),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () => setState(() {
                _imageUrl = null;
                _selectedLocalImage = null;
              }),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_photo_alternate_outlined, size: 48, color: AppColors.primary.withValues(alpha: 0.7)),
        const SizedBox(height: AppSpacing.md),
        const Text('গ্যালারি থেকে ব্যানার ছবি আপলোড করুন',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth = 2.0;
  final double gap = 5.0;
  final double radius = 16.0;

  _DashedBorderPainter({
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final RRect rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    );

    Path path = Path()..addRRect(rrect);
    PathMetrics pathMetrics = path.computeMetrics();

    for (PathMetric pathMetric in pathMetrics) {
      double distance = 0.0;
      while (distance < pathMetric.length) {
        Path extractPath = pathMetric.extractPath(distance, distance + gap);
        canvas.drawPath(extractPath, paint);
        distance += gap * 2;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
