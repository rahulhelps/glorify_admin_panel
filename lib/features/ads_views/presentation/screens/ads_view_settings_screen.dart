import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/settings/ads_view_settings_bloc.dart';
import '../bloc/settings/ads_view_settings_event.dart';
import '../bloc/settings/ads_view_settings_state.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdsViewSettingsScreen extends StatelessWidget {
  const AdsViewSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AdsViewSettingsBloc(db: FirebaseFirestore.instance)..add(FetchBotUrlEvent()),
      child: const AdsViewSettingsView(),
    );
  }
}

class AdsViewSettingsView extends StatefulWidget {
  const AdsViewSettingsView({super.key});

  @override
  State<AdsViewSettingsView> createState() => _AdsViewSettingsViewState();
}

class _AdsViewSettingsViewState extends State<AdsViewSettingsView> {
  final TextEditingController _urlCtrl = TextEditingController();

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Ads View Settings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF00CED1),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: BlocConsumer<AdsViewSettingsBloc, AdsViewSettingsState>(
        listener: (context, state) {
          if (state is AdsViewSettingsLoaded) {
            _urlCtrl.text = state.currentUrl;
          } else if (state is AdsViewSettingsSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('টেলিগ্রাম বোট লিংক সফলভাবে আপডেট করা হয়েছে!'), backgroundColor: Colors.green),
            );
            context.read<AdsViewSettingsBloc>().add(FetchBotUrlEvent());
          } else if (state is AdsViewSettingsFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: ${state.errorMessage}'), backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          if (state is AdsViewSettingsInitial || state is AdsViewSettingsLoading) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF00CED1)));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Card(
              color: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00CED1).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.smart_toy, color: Color(0xFF00CED1), size: 28),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Text(
                            'টেলিগ্রাম বোট লিংক পরিবর্তন করুন',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _urlCtrl,
                      decoration: InputDecoration(
                        labelText: 'Telegram Bot URL',
                        hintText: 'https://t.me/your_bot',
                        prefixIcon: const Icon(Icons.link, color: Colors.grey),
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF00CED1)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () {
                        context.read<AdsViewSettingsBloc>().add(UpdateBotUrlEvent(_urlCtrl.text));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00CED1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                      ),
                      child: const Text(
                        'সংরক্ষণ করুন',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
