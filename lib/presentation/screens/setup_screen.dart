import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/settings_provider.dart';
import '../widgets/custom_button.dart';

class SetupScreen extends StatefulWidget {
  final bool isInitialSetup;
  const SetupScreen({super.key, this.isInitialSetup = false});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final TextEditingController _apiKeyController = TextEditingController();
  bool _isGuideExpanded = true;
  bool _obscureKey = true;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>().settings;
    _apiKeyController.text = settings.apiKey;
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _openUrl(String urlString) async {
    final uri = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuka browser: $e')),
        );
      }
    }
  }

  Future<void> _handleTestConnection() async {
    final key = _apiKeyController.text.trim();
    if (key.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan masukkan atau tempel API Key terlebih dahulu.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final settingsProvider = context.read<SettingsProvider>();
    await settingsProvider.testAndSaveApiKey(key);
  }

  void _handleContinue() {
    if (widget.isInitialSetup) {
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final isSuccess = settingsProvider.testConnectionSuccess == true;
    final isTesting = settingsProvider.isTestingConnection;
    final resultMsg = settingsProvider.testConnectionResult;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isInitialSetup ? 'Setup AI Agent' : 'Pengaturan API Key'),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            children: [
              const SizedBox(height: 10),

              // Simple Heading
              const Text(
                'Masukkan Key API AI',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              const Text(
                'Mendukung Groq (Llama 3.3 Free & Open Source) dan Google Gemini.',
                style: TextStyle(
                  fontSize: 13.5,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Expandable Guide Card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    InkWell(
                      onTap: () {
                        setState(() {
                          _isGuideExpanded = !_isGuideExpanded;
                        });
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            const Icon(Icons.link, size: 20, color: AppColors.primary),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                'Referensi & Link Ambil API Key Gratis',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                            ),
                            Icon(
                              _isGuideExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                              color: AppColors.textMuted,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_isGuideExpanded) ...[
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            // Button 1: Groq (Open Source & 100% Free)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF97316),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.bolt, color: Colors.white, size: 20),
                              ),
                              title: const Row(
                                children: [
                                  Text(
                                    'Groq (Llama 3.3)',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    '100% GRATIS & KILAT',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFC2410C),
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: const Text(
                                'console.groq.com/keys (Kunci awalan gsk_...)',
                                style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                              ),
                              trailing: ElevatedButton(
                                onPressed: () => _openUrl('https://console.groq.com/keys'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFF97316),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  visualDensity: VisualDensity.compact,
                                ),
                                child: const Text('Buka Groq', style: TextStyle(fontSize: 12, color: Colors.white)),
                              ),
                            ),
                            const Divider(height: 16),

                            // Button 2: Gemini
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0D9488),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                              ),
                              title: const Text(
                                'Google Gemini API Key (Gratis)',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                              ),
                              subtitle: const Text(
                                'aistudio.google.com/app/apikey (Kunci awalan AIza...)',
                                style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                              ),
                              trailing: ElevatedButton(
                                onPressed: () => _openUrl('https://aistudio.google.com/app/apikey'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0D9488),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  visualDensity: VisualDensity.compact,
                                ),
                                child: const Text('Buka Gemini', style: TextStyle(fontSize: 12, color: Colors.white)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Single Form Input for API Key
              const Text(
                'Form Input API Key',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _apiKeyController,
                obscureText: _obscureKey,
                onChanged: (_) {
                  if (settingsProvider.testConnectionSuccess != null) {
                    settingsProvider.clearTestResult();
                  }
                },
                decoration: InputDecoration(
                  hintText: 'Tempel / Paste API Key di sini (gsk_... atau AIza...)',
                  prefixIcon: const Icon(Icons.key, color: AppColors.textMuted, size: 20),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          _obscureKey ? Icons.visibility_off : Icons.visibility,
                          color: AppColors.textMuted,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscureKey = !_obscureKey),
                      ),
                      if (_apiKeyController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear, color: AppColors.textMuted, size: 18),
                          onPressed: () {
                            _apiKeyController.clear();
                            settingsProvider.clearTestResult();
                          },
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Button: Uji Koneksi API
              CustomButton(
                text: isTesting ? 'Sedang Menguji Koneksi...' : 'Uji Koneksi API',
                icon: Icons.network_check,
                variant: ButtonVariant.outline,
                isLoading: isTesting,
                onPressed: isTesting ? null : _handleTestConnection,
              ),

              // Result Status Box
              if (resultMsg != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isSuccess ? AppColors.successLight : AppColors.errorLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSuccess ? AppColors.success : AppColors.error,
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        isSuccess ? Icons.check_circle : Icons.error,
                        color: isSuccess ? AppColors.success : AppColors.error,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          resultMsg,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSuccess ? FontWeight.w600 : FontWeight.normal,
                            color: isSuccess ? const Color(0xFF065F46) : const Color(0xFF991B1B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),

              // Button: Lanjutkan Buat Soal (Active ONLY when connection test is successful)
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: isSuccess ? _handleContinue : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSuccess ? AppColors.primary : const Color(0xFFE2E8F0),
                    foregroundColor: isSuccess ? Colors.white : const Color(0xFF94A3B8),
                    disabledBackgroundColor: const Color(0xFFE2E8F0),
                    disabledForegroundColor: const Color(0xFF94A3B8),
                    elevation: isSuccess ? 1 : 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isSuccess ? 'Lanjutkan Buat Soal' : 'Uji Koneksi Dahulu untuk Melanjutkan',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isSuccess ? Colors.white : const Color(0xFF94A3B8),
                        ),
                      ),
                      if (isSuccess) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward, size: 20, color: Colors.white),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
