import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/smm_notice_model.dart';
import '../bloc/smm_notice_bloc.dart';
import '../../../../core/theme/app_theme.dart';

class SmmNoticesConfigScreen extends StatefulWidget {
  const SmmNoticesConfigScreen({super.key});

  @override
  State<SmmNoticesConfigScreen> createState() => _SmmNoticesConfigScreenState();
}

class _SmmNoticesConfigScreenState extends State<SmmNoticesConfigScreen> {
  String _selectedPlatform = 'gmail';
  final _formKey = GlobalKey<FormState>();

  final _titleCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _reviewTimeCtrl = TextEditingController();
  final _noticeCtrl = TextEditingController();
  final _todayPasswordCtrl = TextEditingController();
  bool _isActive = false;
  bool _obscurePassword = true;
  List<String> _rules = [];
  
  List<TextEditingController> _ruleControllers = [];

  @override
  void initState() {
    super.initState();
    _loadNotice();
  }

  void _loadNotice() {
    context.read<SmmNoticeBloc>().add(LoadSmmNotice(_selectedPlatform));
  }

  void _populateForm(SmmNoticeModel notice) {
    _titleCtrl.text = notice.title;
    _priceCtrl.text = notice.price;
    _reviewTimeCtrl.text = notice.reviewTime;
    _noticeCtrl.text = notice.notice;
    _todayPasswordCtrl.text = notice.todayPassword;
    _isActive = notice.isActive;
    _rules = List.from(notice.rules);
    
    // Setup rule controllers
    for (var ctrl in _ruleControllers) {
      ctrl.dispose();
    }
    _ruleControllers = _rules.map((r) => TextEditingController(text: r)).toList();
  }

  void _clearForm() {
    _titleCtrl.clear();
    _priceCtrl.clear();
    _reviewTimeCtrl.clear();
    _noticeCtrl.clear();
    _todayPasswordCtrl.clear();
    _isActive = false;
    _rules = [];
    for (var ctrl in _ruleControllers) {
      ctrl.dispose();
    }
    _ruleControllers = [];
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _priceCtrl.dispose();
    _reviewTimeCtrl.dispose();
    _noticeCtrl.dispose();
    _todayPasswordCtrl.dispose();
    for (var ctrl in _ruleControllers) {
      ctrl.dispose();
    }
    super.dispose();
  }

  void _saveConfigurations() {
    if (_formKey.currentState!.validate()) {
      // Collect rules from controllers
      final updatedRules = _ruleControllers
          .map((ctrl) => ctrl.text.trim())
          .where((text) => text.isNotEmpty)
          .toList();

      final updatedNotice = SmmNoticeModel(
        title: _titleCtrl.text.trim(),
        price: _priceCtrl.text.trim(),
        reviewTime: _reviewTimeCtrl.text.trim(),
        notice: _noticeCtrl.text.trim(),
        todayPassword: _todayPasswordCtrl.text.trim(),
        isActive: _isActive,
        rules: updatedRules,
      );

      context.read<SmmNoticeBloc>().add(UpdateSmmNotice(_selectedPlatform, updatedNotice));
    }
  }

  @override
  Widget build(BuildContext context) {
    // No Scaffold — lives inside AdminShell. All Bloc events preserved.
    return BlocConsumer<SmmNoticeBloc, SmmNoticeState>(
      listener: (context, state) {
        if (state is SmmNoticeUpdateSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: AppColors.success),
          );
        } else if (state is SmmNoticeUpdateFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
          );
        }
      },
      builder: (context, state) {
        if (state is SmmNoticeLoaded) {
          if (state.notice != null && state is! SmmNoticeUpdateLoading) {
            _populateForm(state.notice!);
          } else if (state.notice == null) {
            _clearForm();
          }
        }
        return Column(
          children: [
            _buildPlatformTabs(),
            Expanded(
              child: state is SmmNoticeLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : _buildForm(state is SmmNoticeUpdateLoading),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPlatformTabs() {
    final platforms = ['gmail', 'facebook', 'instagram'];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: platforms.map((platform) {
          final isSelected = _selectedPlatform == platform;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                if (!isSelected) {
                  setState(() => _selectedPlatform = platform);
                  _loadNotice(); // ✅ LoadSmmNotice preserved
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary.withValues(alpha: 0.15) : Colors.transparent,
                  borderRadius: AppRadius.smAll,
                  border: isSelected ? Border.all(color: AppColors.primary.withValues(alpha: 0.5)) : null,
                ),
                child: Center(
                  child: Text(
                    platform.toUpperCase(),
                    style: TextStyle(
                      color: isSelected ? AppColors.primary : AppColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildForm(bool isUpdating) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _buildTextField('Title', _titleCtrl, 'e.g. Gmail Notice'),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(child: _buildTextField('Price', _priceCtrl, 'e.g. 10.0', isNumber: true)),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: _buildTextField('Review Time', _reviewTimeCtrl, 'e.g. 24 Hours')),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _buildTextField('Welcome Notice / Alert', _noticeCtrl, 'Message to display...', minLines: 3, maxLines: 5),
          const SizedBox(height: AppSpacing.md),
          _buildPasswordField(),
          const SizedBox(height: AppSpacing.md),
          _buildActiveSwitch(),
          const SizedBox(height: AppSpacing.lg),
          Text('Service Rules & Guidelines',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.sm),
          _buildRulesEditor(),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: isUpdating ? null : _saveConfigurations, // ✅ UpdateSmmNotice preserved
              child: isUpdating
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Save & Update Configurations', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Today's Password", style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: _todayPasswordCtrl,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            hintText: 'SMM Account Password',
            prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18),
            suffixIcon: IconButton(
              icon: Icon(_obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 18),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, String hint, {bool isNumber = false, int minLines = 1, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: controller,
          keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
          minLines: minLines,
          maxLines: maxLines,
          decoration: InputDecoration(hintText: hint),
          validator: (value) {
            if (value == null || value.trim().isEmpty) return 'Required';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildActiveSwitch() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: _isActive ? AppColors.primary.withValues(alpha: 0.4) : AppColors.border),
      ),
      child: SwitchListTile(
        title: Text('Platform Active Status',
            style: TextStyle(color: _isActive ? AppColors.primary : AppColors.textPrimary, fontWeight: FontWeight.w600)),
        subtitle: Text(
          _isActive ? 'Users can submit orders' : 'Orders currently disabled',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        value: _isActive,
        onChanged: (val) => setState(() => _isActive = val),
      ),
    );
  }

  Widget _buildRulesEditor() {
    return Column(
      children: [
        for (int i = 0; i < _ruleControllers.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Text('${i + 1}',
                      style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: TextFormField(
                    controller: _ruleControllers[i],
                    decoration: const InputDecoration(hintText: 'Enter rule…'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline_rounded, color: AppColors.error, size: 20),
                  onPressed: () => setState(() {
                    _ruleControllers[i].dispose();
                    _ruleControllers.removeAt(i);
                  }),
                ),
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.sm),
        TextButton.icon(
          onPressed: () => setState(() => _ruleControllers.add(TextEditingController())),
          icon: const Icon(Icons.add_circle_rounded, color: AppColors.primary, size: 18),
          label: const Text('Add New Rule', style: TextStyle(fontWeight: FontWeight.w600)),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            backgroundColor: AppColors.primary.withValues(alpha: 0.08),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          ),
        ),
      ],
    );
  }
}
