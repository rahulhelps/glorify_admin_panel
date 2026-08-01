import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _priceController = TextEditingController();
  final List<TextEditingController> _genControllers = List.generate(
    10,
    (_) => TextEditingController(),
  );

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchSubscriptionConfig();
  }

  @override
  void dispose() {
    _priceController.dispose();
    for (final controller in _genControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _fetchSubscriptionConfig() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final doc = await FirebaseFirestore.instance
          .collection('app_config')
          .doc('subscription')
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final plan320 = data['plan320'] as Map<String, dynamic>? ?? {};

        _priceController.text = plan320['price']?.toString() ?? '320';

        final referral = plan320['referral'] as Map<String, dynamic>? ?? {};
        final defaultGens = ['100', '45', '20', '10', '5', '4', '3', '2', '2', '2'];

        for (int i = 0; i < 10; i++) {
          final genKey = 'gen${i + 1}';
          _genControllers[i].text = referral[genKey]?.toString() ?? defaultGens[i];
        }
      } else {
        // Fallback default values
        _priceController.text = '320';
        final defaultGens = ['100', '45', '20', '10', '5', '4', '3', '2', '2', '2'];
        for (int i = 0; i < 10; i++) {
          _genControllers[i].text = defaultGens[i];
        }
      }
    } catch (e) {
      _errorMessage = 'Failed to load subscription settings: $e';
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveSubscriptionConfig() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final Map<String, String> referralMap = {};
    for (int i = 0; i < 10; i++) {
      referralMap['gen${i + 1}'] = _genControllers[i].text.trim();
    }

    final payload = {
      'plan320': {
        'price': _priceController.text.trim(),
        'referral': referralMap,
      },
    };

    try {
      await FirebaseFirestore.instance
          .collection('app_config')
          .doc('subscription')
          .set(payload, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 10),
                Expanded(
                  child: Text('Subscription plan configuration updated successfully!'),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(child: Text('Failed to update configuration: $e')),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
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

  double _calculateTotalReferralBonus() {
    double total = 0.0;
    for (final controller in _genControllers) {
      total += double.tryParse(controller.text.trim()) ?? 0.0;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Subscription Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Reload',
            onPressed: _isLoading ? null : _fetchSubscriptionConfig,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _errorMessage != null
              ? _buildErrorView()
              : _buildContent(),
    );
  }

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
              'Failed to Load Configuration',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _errorMessage ?? 'Unknown error occurred.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: _fetchSubscriptionConfig,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Overview & Plan Info Card ──────────────────────────────────────
            _buildPlanPriceCard(),
            const SizedBox(height: AppSpacing.lg),

            // ── 10 Generation Setup Card ─────────────────────────────────────
            _buildGenerationsCard(),
            const SizedBox(height: AppSpacing.lg),

            // ── Distribution Summary Card ────────────────────────────────────
            _buildSummaryCard(),
            const SizedBox(height: AppSpacing.xl),

            // ── Save Button ──────────────────────────────────────────────────
            _buildSaveButton(),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanPriceCard() {
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: AppRadius.mdAll,
                ),
                child: const Icon(Icons.workspace_premium_rounded, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Plan Price Setup (Plan 320)',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Set the standard subscription amount in Taka required for user verification.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 28, color: AppColors.divider),
          Text(
            'Subscription Fee (৳)',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _priceController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              hintText: 'e.g. 320',
              prefixIcon: const Icon(Icons.payments_outlined, color: AppColors.primary),
              suffixText: 'BDT',
              suffixStyle: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary),
              filled: true,
              fillColor: AppColors.surfaceVariant.withValues(alpha: 0.5),
              border: OutlineInputBorder(
                borderRadius: AppRadius.mdAll,
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppRadius.mdAll,
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppRadius.mdAll,
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Please enter the plan price';
              }
              if (int.tryParse(val.trim()) == null) {
                return 'Enter a valid number';
              }
              return null;
            },
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }

  Widget _buildGenerationsCard() {
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.12),
                  borderRadius: AppRadius.mdAll,
                ),
                child: const Icon(Icons.account_tree_rounded, color: Colors.purple, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '10 Generation Referral Bonus Setup',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Configure the distributed commission amount for each referrer tier upon activation.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 28, color: AppColors.divider),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 600;
              final crossAxisCount = isWide ? 2 : 1;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 12,
                  mainAxisExtent: 80,
                ),
                itemCount: 10,
                itemBuilder: (context, index) {
                  final genNum = index + 1;
                  return _buildGenInputField(genNum, _genControllers[index]);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGenInputField(int genNum, TextEditingController controller) {
    Color badgeColor;
    if (genNum == 1) {
      badgeColor = Colors.teal;
    } else if (genNum == 2) {
      badgeColor = Colors.blue;
    } else if (genNum <= 5) {
      badgeColor = Colors.indigo;
    } else {
      badgeColor = Colors.blueGrey;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'GEN $genNum',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: badgeColor,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'Generation $genNum Commission',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            prefixIcon: const Padding(
              padding: EdgeInsets.only(left: 10, right: 6),
              child: Text('৳', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
            hintText: '0',
            filled: true,
            fillColor: AppColors.surfaceVariant.withValues(alpha: 0.4),
            border: OutlineInputBorder(
              borderRadius: AppRadius.smAll,
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadius.smAll,
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppRadius.smAll,
              borderSide: BorderSide(color: badgeColor, width: 1.5),
            ),
          ),
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return 'Required';
            }
            if (int.tryParse(val.trim()) == null) {
              return 'Invalid';
            }
            return null;
          },
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  Widget _buildSummaryCard() {
    final double planPrice = double.tryParse(_priceController.text.trim()) ?? 0.0;
    final double totalReferral = _calculateTotalReferralBonus();
    final double remainingCompanyShare = planPrice - totalReferral;
    final bool isDeficit = remainingCompanyShare < 0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDeficit ? AppColors.errorBg : const Color(0xFFF0FDF4),
        borderRadius: AppRadius.lgAll,
        border: Border.all(
          color: isDeficit ? AppColors.error.withValues(alpha: 0.4) : AppColors.success.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isDeficit ? Icons.warning_amber_rounded : Icons.pie_chart_outline_rounded,
            color: isDeficit ? AppColors.error : AppColors.success,
            size: 28,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Commission Distribution Summary',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: isDeficit ? AppColors.error : const Color(0xFF166534),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Plan Price: ৳${planPrice.toStringAsFixed(0)}  •  Total Distributed: ৳${totalReferral.toStringAsFixed(0)}  •  Net Margin: ৳${remainingCompanyShare.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDeficit ? AppColors.error : const Color(0xFF15803D),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      height: 50,
      child: ElevatedButton.icon(
        onPressed: _isSaving ? null : _saveSubscriptionConfig,
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
          _isSaving ? 'Saving Changes...' : 'Save Plan Changes',
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.mdAll,
          ),
        ),
      ),
    );
  }
}
