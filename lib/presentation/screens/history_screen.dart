import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../data/services/docx_service.dart';
import '../../providers/settings_provider.dart';
import '../../providers/history_provider.dart';
import '../../providers/generator_provider.dart';
import 'preview_editor_screen.dart';
import 'pdf_viewer_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showDeleteDialog(BuildContext context, String id, String title) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Paket Soal?'),
        content: Text('Apakah Anda yakin ingin menghapus "$title"? Data yang dihapus tidak dapat dikembalikan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<HistoryProvider>().deletePackage(id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Paket soal berhasil dihapus')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final historyProvider = context.watch<HistoryProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bank Soal & Riwayat'),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => historyProvider.setSearchQuery(val),
              decoration: InputDecoration(
                hintText: 'Cari mapel, judul, atau materi...',
                prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          historyProvider.setSearchQuery('');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
          ),

          // Packages List
          Expanded(
            child: historyProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : historyProvider.packages.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: () => historyProvider.loadPackages(),
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: historyProvider.packages.length,
                          itemBuilder: (context, index) {
                            final package = historyProvider.packages[index];
                            final dateStr = DateFormat('dd MMMM yyyy, HH:mm', 'id_ID').format(package.createdAt);

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: InkWell(
                                onTap: () {
                                  context.read<GeneratorProvider>().setCurrentPackage(package);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const PreviewEditorScreen(),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Top info row
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: AppColors.primaryContainer,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              package.subject,
                                              style: const TextStyle(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.primaryDark,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            dateStr,
                                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),

                                      // Title
                                      Text(
                                        package.title,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),

                                      // Grade & Stats
                                      Text(
                                        '${package.grade} • ${package.curriculum} • ${package.totalQuestions} Soal (${package.questionType})',
                                        style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                                      ),
                                      const SizedBox(height: 6),

                                      // Topics preview
                                      if (package.topics.isNotEmpty)
                                        Text(
                                          'Materi: ${package.topics.join(", ")}',
                                          style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),

                                      const SizedBox(height: 12),
                                      const Divider(height: 1),
                                      const SizedBox(height: 8),

                                      // Actions
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          TextButton.icon(
                                            icon: const Icon(Icons.description_outlined, size: 16, color: Color(0xFF2563EB)),
                                            label: const Text('MS Word (.docx)', style: TextStyle(fontSize: 12, color: Color(0xFF2563EB))),
                                            onPressed: () async {
                                              final settings = context.read<SettingsProvider>().settings;
                                              final docxService = DocxService();
                                              await docxService.exportAndShareDocx(package: package, settings: settings);
                                            },
                                          ),
                                          const SizedBox(width: 4),
                                          TextButton.icon(
                                            icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                                            label: const Text('Cetak / PDF', style: TextStyle(fontSize: 12)),
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => PdfViewerScreen(package: package),
                                                ),
                                              );
                                            },
                                          ),
                                          const SizedBox(width: 4),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                                            onPressed: () => _showDeleteDialog(context, package.id, package.title),
                                            tooltip: 'Hapus',
                                            visualDensity: VisualDensity.compact,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 56, color: AppColors.textMuted.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            const Text(
              'Tidak ada riwayat soal',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            const Text(
              'Soal yang pernah Anda buat akan tersimpan otomatis di sini secara permanen di memori HP Anda.',
              style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
