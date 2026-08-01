import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/drive_offer.dart';
import '../bloc/drive_offer_bloc.dart';
import '../bloc/drive_offer_event.dart';
import '../bloc/drive_offer_state.dart';

class DriveOffersScreen extends StatefulWidget {
  const DriveOffersScreen({super.key});

  @override
  State<DriveOffersScreen> createState() => _DriveOffersScreenState();
}

class _DriveOffersScreenState extends State<DriveOffersScreen> {
  final Set<String> _deletingOfferIds = <String>{};
  List<DriveOffer>? _cachedOffers;

  @override
  void initState() {
    super.initState();
    context.read<DriveOfferBloc>().add(LoadOffers());
  }

  void _showOfferForm([DriveOffer? offer]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (context) => _DriveOfferForm(offer: offer),
    );
  }

  void _deleteOffer(String offerId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Offer?'),
        content: const Text('Are you sure you want to delete this offer?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _deletingOfferIds.add(offerId);
              });
              context.read<DriveOfferBloc>().add(DeleteOffer(offerId));
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DriveOfferBloc, DriveOfferState>(
      listener: (context, state) {
        if (state is DriveOfferActionSuccess) {
          setState(() {
            _deletingOfferIds.clear();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.success,
            ),
          );
        } else if (state is DriveOfferActionError) {
          setState(() {
            _deletingOfferIds.clear();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        } else if (state is DriveOffersError) {
          setState(() {
            _deletingOfferIds.clear();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        } else if (state is DriveOffersLoaded) {
          setState(() {
            _cachedOffers = state.offers;
            _deletingOfferIds.removeWhere((id) => !state.offers.any((o) => o.id == id));
          });
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Drive Offers'),
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: AppColors.primary,
            onPressed: () => _showOfferForm(),
            child: const Icon(Icons.add, color: Colors.white),
          ),
          body: _buildBody(state),
        );
      },
    );
  }

  Widget _buildBody(DriveOfferState state) {
    final offers = (state is DriveOffersLoaded) ? state.offers : _cachedOffers;

    if (offers == null) {
      if (state is DriveOffersError) {
        return Center(
          child: Text(
            state.message,
            style: GoogleFonts.inter(color: AppColors.error),
          ),
        );
      }
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (offers.isEmpty) {
      return Center(
        child: Text(
          'No drive offers found.',
          style: GoogleFonts.inter(color: AppColors.textSecondary),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: offers.length,
      itemBuilder: (context, index) {
        final offer = offers[index];
        final isDeleting = _deletingOfferIds.contains(offer.id);

        return Card(
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          color: AppColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            side: const BorderSide(color: AppColors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        offer.title,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: AppColors.primary, size: 20),
                          onPressed: isDeleting ? null : () => _showOfferForm(offer),
                          tooltip: 'Edit',
                        ),
                        if (isDeleting)
                          const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.error),
                            ),
                          )
                        else
                          IconButton(
                            icon: const Icon(Icons.delete, color: AppColors.error, size: 20),
                            onPressed: () => _deleteOffer(offer.id),
                            tooltip: 'Delete',
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getOperatorColor(offer.operator).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(color: _getOperatorColor(offer.operator).withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    offer.operator,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _getOperatorColor(offer.operator),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildPriceColumn('Regular Price', offer.regularPrice, isStrikethrough: true),
                    _buildPriceColumn('Offer Price', offer.offerPrice, color: AppColors.success),
                    _buildPriceColumn('Savings', offer.savings, color: AppColors.primary),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPriceColumn(String label, double amount, {Color? color, bool isStrikethrough = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '৳${amount.toStringAsFixed(0)}',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color ?? AppColors.textPrimary,
            decoration: isStrikethrough ? TextDecoration.lineThrough : null,
          ),
        ),
      ],
    );
  }

  Color _getOperatorColor(String operator) {
    switch (operator.toLowerCase()) {
      case 'grameenphone':
        return Colors.blue;
      case 'robi':
        return Colors.red;
      case 'airtel':
        return Colors.deepOrange;
      case 'banglalink':
        return Colors.orange;
      case 'teletalk':
        return Colors.green;
      default:
        return AppColors.primary;
    }
  }
}

class _DriveOfferForm extends StatefulWidget {
  final DriveOffer? offer;

  const _DriveOfferForm({this.offer});

  @override
  State<_DriveOfferForm> createState() => _DriveOfferFormState();
}

class _DriveOfferFormState extends State<_DriveOfferForm> {
  final _formKey = GlobalKey<FormState>();
  late String _selectedOperator;
  late TextEditingController _titleController;
  late TextEditingController _offerPriceController;
  late TextEditingController _regularPriceController;
  late TextEditingController _savingsController;
  bool _isSubmitting = false;

  final List<String> _operators = ['Grameenphone', 'Robi', 'Airtel', 'Banglalink', 'Teletalk'];

  @override
  void initState() {
    super.initState();
    _selectedOperator = widget.offer?.operator ?? _operators.first;
    _titleController = TextEditingController(text: widget.offer?.title ?? '');
    _offerPriceController = TextEditingController(
      text: widget.offer != null ? widget.offer!.offerPrice.toStringAsFixed(0) : '',
    );
    _regularPriceController = TextEditingController(
      text: widget.offer != null ? widget.offer!.regularPrice.toStringAsFixed(0) : '',
    );
    _savingsController = TextEditingController(
      text: widget.offer != null ? widget.offer!.savings.toStringAsFixed(0) : '',
    );

    _offerPriceController.addListener(_calculateSavings);
    _regularPriceController.addListener(_calculateSavings);
  }

  void _calculateSavings() {
    final regular = double.tryParse(_regularPriceController.text.trim()) ?? 0.0;
    final offer = double.tryParse(_offerPriceController.text.trim()) ?? 0.0;
    if (regular > 0 && offer > 0 && regular >= offer) {
      _savingsController.text = (regular - offer).toStringAsFixed(0);
    } else {
      _savingsController.text = '0';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _offerPriceController.dispose();
    _regularPriceController.dispose();
    _savingsController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_isSubmitting) return;

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      final title = _titleController.text.trim();
      final offerPrice = double.tryParse(_offerPriceController.text.trim()) ?? 0.0;
      final regularPrice = double.tryParse(_regularPriceController.text.trim()) ?? 0.0;
      final savings = double.tryParse(_savingsController.text.trim()) ?? 0.0;

      final offer = DriveOffer(
        id: widget.offer?.id ?? '',
        title: title,
        operator: _selectedOperator,
        offerPrice: offerPrice,
        regularPrice: regularPrice,
        savings: savings,
        createdAt: widget.offer?.createdAt ?? DateTime.now(),
      );

      if (widget.offer == null) {
        context.read<DriveOfferBloc>().add(CreateOffer(offer));
      } else {
        context.read<DriveOfferBloc>().add(UpdateOffer(offer));
      }

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    
    return Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.lg, AppSpacing.md, bottomPadding + AppSpacing.md),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.offer == null ? 'Add Drive Offer' : 'Edit Drive Offer',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            
            // Operator Dropdown
            DropdownButtonFormField<String>(
              initialValue: _selectedOperator,
              decoration: const InputDecoration(
                labelText: 'Operator',
                border: OutlineInputBorder(),
              ),
              items: _operators.map((op) {
                return DropdownMenuItem(
                  value: op,
                  child: Text(op),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedOperator = val);
              },
            ),
            const SizedBox(height: AppSpacing.md),
            
            // Title
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Offer Title (e.g. 50GB + 1000 Min)',
                border: OutlineInputBorder(),
              ),
              validator: (val) => (val == null || val.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _regularPriceController,
                    decoration: const InputDecoration(
                      labelText: 'Regular Price',
                      border: OutlineInputBorder(),
                      prefixText: '৳ ',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (val) => (val == null || val.isEmpty) ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: TextFormField(
                    controller: _offerPriceController,
                    decoration: const InputDecoration(
                      labelText: 'Offer Price',
                      border: OutlineInputBorder(),
                      prefixText: '৳ ',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (val) => (val == null || val.isEmpty) ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            
            TextFormField(
              controller: _savingsController,
              decoration: const InputDecoration(
                labelText: 'Savings (Auto-calculated)',
                border: OutlineInputBorder(),
                prefixText: '৳ ',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (val) => (val == null || val.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: AppSpacing.xl),
            
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      widget.offer == null ? 'CREATE OFFER' : 'UPDATE OFFER',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
