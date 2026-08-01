import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/app_limits.dart';
import '../bloc/app_limits_bloc.dart';
import '../bloc/app_limits_event.dart';
import '../bloc/app_limits_state.dart';

class AppLimitsScreen extends StatefulWidget {
  const AppLimitsScreen({super.key});

  @override
  State<AppLimitsScreen> createState() => _AppLimitsScreenState();
}

class _AppLimitsScreenState extends State<AppLimitsScreen> {
  final _formKey = GlobalKey<FormState>();

  final _minDepositCtrl = TextEditingController();
  final _maxDepositCtrl = TextEditingController();
  final _minWithdrawalCtrl = TextEditingController();
  final _maxWithdrawalCtrl = TextEditingController();
  final _firstTimeWithdrawalCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<AppLimitsBloc>().add(LoadAppLimits());
  }

  void _populateForm(AppLimits limits) {
    _minDepositCtrl.text = limits.minDeposit.toString();
    _maxDepositCtrl.text = limits.maxDeposit.toString();
    _minWithdrawalCtrl.text = limits.minWithdrawal.toString();
    _maxWithdrawalCtrl.text = limits.maxWithdrawal.toString();
    _firstTimeWithdrawalCtrl.text = limits.firstTimeWithdrawal.toString();
  }

  @override
  void dispose() {
    _minDepositCtrl.dispose();
    _maxDepositCtrl.dispose();
    _minWithdrawalCtrl.dispose();
    _maxWithdrawalCtrl.dispose();
    _firstTimeWithdrawalCtrl.dispose();
    super.dispose();
  }

  void _saveConfigurations() {
    if (_formKey.currentState!.validate()) {
      final updatedLimits = AppLimits(
        minDeposit: int.tryParse(_minDepositCtrl.text.trim()) ?? 10,
        maxDeposit: int.tryParse(_maxDepositCtrl.text.trim()) ?? 25000,
        minWithdrawal: int.tryParse(_minWithdrawalCtrl.text.trim()) ?? 100,
        maxWithdrawal: int.tryParse(_maxWithdrawalCtrl.text.trim()) ?? 10000,
        firstTimeWithdrawal: int.tryParse(_firstTimeWithdrawalCtrl.text.trim()) ?? 20,
      );

      context.read<AppLimitsBloc>().add(UpdateAppLimits(updatedLimits));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('App Limits'),
      ),
      body: BlocConsumer<AppLimitsBloc, AppLimitsState>(
        listener: (context, state) {
          if (state is AppLimitsUpdateSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('App Limits successfully updated!'), backgroundColor: AppColors.success),
            );
          } else if (state is AppLimitsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
            );
          }
        },
        builder: (context, state) {
          if (state is AppLimitsLoaded) {
            _populateForm(state.limits);
          } else if (state is AppLimitsUpdateSuccess) {
            _populateForm(state.limits);
          }

          return Column(
            children: [
              Expanded(
                child: state is AppLimitsLoading && state is! AppLimitsUpdateSuccess
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                    : _buildForm(state is AppLimitsLoading),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildForm(bool isUpdating) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.lgAll,
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Deposit Limits',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(child: _buildTextField('Minimum Deposit', _minDepositCtrl, 'e.g. 10')),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: _buildTextField('Maximum Deposit', _maxDepositCtrl, 'e.g. 25000')),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.lgAll,
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Withdrawal Limits',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(child: _buildTextField('Minimum Withdrawal', _minWithdrawalCtrl, 'e.g. 100')),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: _buildTextField('Maximum Withdrawal', _maxWithdrawalCtrl, 'e.g. 10000')),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                _buildTextField('First-Time Withdrawal Limit', _firstTimeWithdrawalCtrl, 'e.g. 20'),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: isUpdating ? null : _saveConfigurations,
              child: isUpdating
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Save & Update Limits', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(hintText: hint),
          validator: (value) {
            if (value == null || value.trim().isEmpty) return 'Required';
            if (int.tryParse(value.trim()) == null) return 'Must be a valid integer';
            if (int.parse(value.trim()) < 0) return 'Must be a positive number';
            return null;
          },
        ),
      ],
    );
  }
}
