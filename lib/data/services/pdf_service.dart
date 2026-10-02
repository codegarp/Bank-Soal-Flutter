import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/app_settings_model.dart';
import '../models/question_package_model.dart';
import '../models/question_model.dart';

enum PdfExportType {
  studentOnly, // Lembar Soal Siswa
  teacherOnly, // Kunci Jawaban & Pembahasan Guru
  complete, // Soal + Kunci Jawaban
}

class PdfService {
  Future<Uint8List> generateExamPdf({
    required QuestionPackageModel package,
    required AppSettingsModel settings,
    required PdfExportType exportType,
  }) async {
    final pdf = pw.Document();

    final fontRegular = await PdfGoogleFonts.poppinsRegular();
    final fontBold = await PdfGoogleFonts.poppinsBold();
    final fontItalic = await PdfGoogleFonts.poppinsItalic();

    final theme = pw.ThemeData.withFont(
      base: fontRegular,
      bold: fontBold,
      italic: fontItalic,
    );

    // 1. Generate Student Exam Paper (if studentOnly or complete)
    if (exportType == PdfExportType.studentOnly || exportType == PdfExportType.complete) {
      pdf.addPage(
        pw.MultiPage(
          pageTheme: pw.PageTheme(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 32),
            theme: theme,
          ),
          header: (context) => _buildHeader(settings, package, isAnswerKey: false),
          footer: (context) => _buildFooter(context, isAnswerKey: false),
          build: (context) => [
            _buildStudentIdentityBox(package),
            pw.SizedBox(height: 12),
            _buildInstructions(),
            pw.SizedBox(height: 14),
            _buildQuestionsSection(package.questions, fontBold: fontBold, isAnswerKey: false),
          ],
        ),
      );
    }

    // 2. Generate Teacher Answer Key & Explanation (if teacherOnly or complete)
    if (exportType == PdfExportType.teacherOnly || exportType == PdfExportType.complete) {
      pdf.addPage(
        pw.MultiPage(
          pageTheme: pw.PageTheme(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 32),
            theme: theme,
          ),
          header: (context) => _buildHeader(settings, package, isAnswerKey: true),
          footer: (context) => _buildFooter(context, isAnswerKey: true),
          build: (context) => [
            _buildAnswerKeySummaryTable(package.questions, fontBold: fontBold),
            pw.SizedBox(height: 16),
            pw.Text(
              'PEMBAHASAN LENGKAP & PEDOMAN PENSKORAN',
              style: pw.TextStyle(font: fontBold, fontSize: 12, color: PdfColors.indigo900),
            ),
            pw.Divider(thickness: 1, color: PdfColors.indigo300),
            pw.SizedBox(height: 8),
            _buildQuestionsSection(package.questions, fontBold: fontBold, isAnswerKey: true),
            pw.SizedBox(height: 24),
            _buildTeacherSignature(settings),
          ],
        ),
      );
    }

    return await pdf.save();
  }

  // --- Kop Surat / Header ---
  pw.Widget _buildHeader(AppSettingsModel settings, QuestionPackageModel package, {required bool isAnswerKey}) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Expanded(
              child: pw.Column(
                children: [
                  pw.Text(
                    settings.schoolName.toUpperCase(),
                    style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    settings.schoolAddress,
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                    textAlign: pw.TextAlign.center,
                  ),
                  if (settings.schoolPhone.isNotEmpty)
                    pw.Text(
                      'Telp: ${settings.schoolPhone}',
                      style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                      textAlign: pw.TextAlign.center,
                    ),
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 6),
        pw.Container(
          height: 2,
          color: PdfColors.black,
        ),
        pw.SizedBox(height: 1),
        pw.Container(
          height: 0.5,
          color: PdfColors.black,
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          isAnswerKey ? 'KUNCI JAWABAN & PEMBAHASAN' : 'LEMBAR SOAL PENILAIAN',
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: isAnswerKey ? PdfColors.indigo800 : PdfColors.black,
            decoration: pw.TextDecoration.underline,
          ),
        ),
        pw.SizedBox(height: 8),
      ],
    );
  }

  // --- Kotak Identitas Siswa ---
  pw.Widget _buildStudentIdentityBox(QuestionPackageModel package) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey600, width: 0.8),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            flex: 3,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Mata Pelajaran', ': ${package.subject}'),
                _buildInfoRow('Kelas / Jenjang', ': ${package.grade} (${package.educationLevel})'),
                _buildInfoRow('Kurikulum', ': ${package.curriculum}'),
                _buildInfoRow('Materi / Topik', ': ${package.topics.join(", ")}'),
              ],
            ),
          ),
          pw.SizedBox(width: 12),
          pw.Expanded(
            flex: 2,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Nama Siswa', ': .....................................'),
                _buildInfoRow('No. Peserta / Absen', ': .....................................'),
                _buildInfoRow('Hari / Tanggal', ': .....................................'),
                _buildInfoRow('Waktu', ': ${package.durationMinutes} Menit'),
              ],
            ),
          ),
          pw.Container(
            width: 60,
            height: 50,
            margin: const pw.EdgeInsets.only(left: 8),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey600, width: 0.8),
            ),
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text('Nilai', style: const pw.TextStyle(fontSize: 8)),
                pw.SizedBox(height: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 90,
            child: pw.Text(label, style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey800)),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold),
              maxLines: 2,
              overflow: pw.TextOverflow.clip,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildInstructions() {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: const pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(2)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'PETUNJUK UMUM:',
            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            '1. Tuliskan identitas Anda pada kolom yang telah disediakan.\n2. Periksa dan bacalah setiap butir soal dengan teliti sebelum menjawab.\n3. Dahulukan menjawab soal-soal yang Anda anggap mudah.',
            style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey800),
          ),
        ],
      ),
    );
  }

  // --- Daftar Butir Soal ---
  pw.Widget _buildQuestionsSection(List<QuestionModel> questions, {required pw.Font fontBold, required bool isAnswerKey}) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: questions.map((q) {
        return pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 12),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.SizedBox(
                width: 22,
                child: pw.Text(
                  '${q.number}.',
                  style: pw.TextStyle(font: fontBold, fontSize: 9.5),
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      q.questionText,
                      style: const pw.TextStyle(fontSize: 9.5, lineSpacing: 1.3),
                    ),
                    if (q.options.isNotEmpty) ...[
                      pw.SizedBox(height: 4),
                      ...q.options.map((opt) {
                        final isCorrect = isAnswerKey && opt.key.toUpperCase() == q.correctAnswer.toUpperCase();
                        return pw.Padding(
                          padding: const pw.EdgeInsets.only(left: 4, bottom: 2),
                          child: pw.Row(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.SizedBox(
                                width: 18,
                                child: pw.Text(
                                  '${opt.key}.',
                                  style: pw.TextStyle(
                                    fontSize: 9,
                                    font: isCorrect ? fontBold : null,
                                    color: isCorrect ? PdfColors.green800 : PdfColors.black,
                                  ),
                                ),
                              ),
                              pw.Expanded(
                                child: pw.Text(
                                  opt.text,
                                  style: pw.TextStyle(
                                    fontSize: 9,
                                    font: isCorrect ? fontBold : null,
                                    color: isCorrect ? PdfColors.green800 : PdfColors.black,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                    if (isAnswerKey) ...[
                      pw.SizedBox(height: 6),
                      pw.Container(
                        padding: const pw.EdgeInsets.all(6),
                        decoration: const pw.BoxDecoration(
                          color: PdfColors.indigo50,
                          borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'Kunci Jawaban: ${q.correctAnswer}',
                              style: pw.TextStyle(font: fontBold, fontSize: 8.5, color: PdfColors.indigo900),
                            ),
                            pw.SizedBox(height: 2),
                            pw.Text(
                              'Pembahasan: ${q.explanation}',
                              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey900),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // --- Tabel Ringkasan Kunci Jawaban ---
  pw.Widget _buildAnswerKeySummaryTable(List<QuestionModel> questions, {required pw.Font fontBold}) {
    final multipleChoiceQuestions = questions.where((q) => q.isMultipleChoice).toList();
    if (multipleChoiceQuestions.isEmpty) return pw.SizedBox();

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.indigo400, width: 0.8),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'TABEL RINGKASAN KUNCI JAWABAN PILIHAN GANDA',
            style: pw.TextStyle(font: fontBold, fontSize: 9, color: PdfColors.indigo900),
          ),
          pw.SizedBox(height: 6),
          pw.Wrap(
            spacing: 8,
            runSpacing: 4,
            children: multipleChoiceQuestions.map((q) {
              return pw.Container(
                width: 48,
                padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                decoration: const pw.BoxDecoration(
                  color: PdfColors.indigo50,
                  borderRadius: pw.BorderRadius.all(pw.Radius.circular(2)),
                ),
                child: pw.Text(
                  '${q.number}. ${q.correctAnswer}',
                  style: pw.TextStyle(fontSize: 8.5, font: fontBold, color: PdfColors.indigo900),
                  textAlign: pw.TextAlign.center,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // --- Tanda Tangan Guru ---
  pw.Widget _buildTeacherSignature(AppSettingsModel settings) {
    final dateStr = DateFormat('dd MMMM yyyy', 'id_ID').format(DateTime.now());
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(dateStr, style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700)),
            pw.SizedBox(height: 2),
            pw.Text('Mengetahui / Guru Pengampu,', style: const pw.TextStyle(fontSize: 9)),
            pw.SizedBox(height: 44),
            pw.Text(
              settings.teacherName,
              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, decoration: pw.TextDecoration.underline),
            ),
            if (settings.teacherNip.isNotEmpty)
              pw.Text('NIP. ${settings.teacherNip}', style: const pw.TextStyle(fontSize: 8)),
          ],
        ),
      ],
    );
  }

  // --- Footer Nomor Halaman ---
  pw.Widget _buildFooter(pw.Context context, {required bool isAnswerKey}) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 8),
      padding: const pw.EdgeInsets.only(top: 4),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey400, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'GuruSoal AI • ${isAnswerKey ? "Pegangan Guru" : "Dokumen Ujian"}',
            style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600),
          ),
          pw.Text(
            'Halaman ${context.pageNumber} dari ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  /// Print or preview PDF directly
  Future<void> printExamPdf({
    required QuestionPackageModel package,
    required AppSettingsModel settings,
    required PdfExportType exportType,
  }) async {
    final pdfBytes = await generateExamPdf(
      package: package,
      settings: settings,
      exportType: exportType,
    );

    final title = '${package.subject}_${package.grade}_${exportType.name}';
    await Printing.layoutPdf(
      onLayout: (format) async => pdfBytes,
      name: '$title.pdf',
    );
  }

  /// Share PDF via WhatsApp / Drive / Email
  Future<void> shareExamPdf({
    required QuestionPackageModel package,
    required AppSettingsModel settings,
    required PdfExportType exportType,
  }) async {
    final pdfBytes = await generateExamPdf(
      package: package,
      settings: settings,
      exportType: exportType,
    );

    final filename = 'Soal_${package.subject}_${package.grade}.pdf';
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: filename,
    );
  }
}
