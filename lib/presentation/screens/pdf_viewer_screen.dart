import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/question_package_model.dart';
import '../../data/services/pdf_service.dart';
import '../../providers/settings_provider.dart';

class PdfViewerScreen extends StatefulWidget {
  final QuestionPackageModel package;
  const PdfViewerScreen({super.key, required this.package});

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  final PdfService _pdfService = PdfService();
  PdfExportType _selectedExportType = PdfExportType.studentOnly;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>().settings;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pratinjau Dokumen PDF'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () async {
              await _pdfService.shareExamPdf(
                package: widget.package,
                settings: settings,
                exportType: _selectedExportType,
              );
            },
            tooltip: 'Bagikan PDF (WhatsApp / Drive)',
          ),
          IconButton(
            icon: const Icon(Icons.print_outlined),
            onPressed: () async {
              await _pdfService.printExamPdf(
                package: widget.package,
                settings: settings,
                exportType: _selectedExportType,
              );
            },
            tooltip: 'Cetak Dokumen',
          ),
        ],
      ),
      body: Column(
        children: [
          // Segmented Button for PDF Type Selection
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.white,
            child: SegmentedButton<PdfExportType>(
              segments: const [
                ButtonSegment(
                  value: PdfExportType.studentOnly,
                  label: Text('Lembar Soal', style: TextStyle(fontSize: 12)),
                  icon: Icon(Icons.person_outline, size: 16),
                ),
                ButtonSegment(
                  value: PdfExportType.teacherOnly,
                  label: Text('Kunci & Bahas', style: TextStyle(fontSize: 12)),
                  icon: Icon(Icons.vpn_key_outlined, size: 16),
                ),
                ButtonSegment(
                  value: PdfExportType.complete,
                  label: Text('Lengkap', style: TextStyle(fontSize: 12)),
                  icon: Icon(Icons.auto_stories_outlined, size: 16),
                ),
              ],
              selected: {_selectedExportType},
              onSelectionChanged: (Set<PdfExportType> newSelection) {
                setState(() {
                  _selectedExportType = newSelection.first;
                });
              },
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: AppColors.primaryContainer,
                selectedForegroundColor: AppColors.primaryDark,
              ),
            ),
          ),
          const Divider(height: 1),

          // Interactive PDF Viewer
          Expanded(
            child: PdfPreview(
              build: (format) => _pdfService.generateExamPdf(
                package: widget.package,
                settings: settings,
                exportType: _selectedExportType,
              ),
              canChangeOrientation: false,
              canChangePageFormat: false,
              canDebug: false,
              dynamicLayout: false,
              pdfFileName: 'Soal_${widget.package.subject}_${widget.package.grade}.pdf',
              loadingWidget: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
