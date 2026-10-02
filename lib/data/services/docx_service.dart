import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/app_settings_model.dart';
import '../models/question_package_model.dart';

class DocxService {
  /// Generate .docx file bytes
  Uint8List generateDocxBytes({
    required QuestionPackageModel package,
    required AppSettingsModel settings,
  }) {
    final archive = Archive();

    // 1. [Content_Types].xml
    const contentTypesXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
  <Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>
</Types>''';
    archive.addFile(ArchiveFile('[Content_Types].xml', contentTypesXml.length, utf8.encode(contentTypesXml)));

    // 2. _rels/.rels
    const relsXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>''';
    archive.addFile(ArchiveFile('_rels/.rels', relsXml.length, utf8.encode(relsXml)));

    // 3. word/_rels/document.xml.rels
    const docRelsXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
</Relationships>''';
    archive.addFile(ArchiveFile('word/_rels/document.xml.rels', docRelsXml.length, utf8.encode(docRelsXml)));

    // 4. word/styles.xml
    const stylesXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:docDefaults>
    <w:rPrDefault>
      <w:rPr>
        <w:rFonts w:ascii="Calibri" w:hAnsi="Calibri" w:cs="Calibri"/>
        <w:sz w:val="22"/>
      </w:rPr>
    </w:rPrDefault>
  </w:docDefaults>
</w:styles>''';
    archive.addFile(ArchiveFile('word/styles.xml', stylesXml.length, utf8.encode(stylesXml)));

    // 5. word/document.xml
    final documentXml = _buildDocumentXml(package, settings);
    final docBytes = utf8.encode(documentXml);
    archive.addFile(ArchiveFile('word/document.xml', docBytes.length, docBytes));

    final encoder = ZipEncoder();
    final zipData = encoder.encode(archive);
    return Uint8List.fromList(zipData);
  }

  String _xmlEscape(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  String _buildDocumentXml(QuestionPackageModel package, AppSettingsModel settings) {
    final sb = StringBuffer();
    sb.writeln('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
    sb.writeln('<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">');
    sb.writeln('<w:body>');

    // Kop Surat Sekolah
    sb.writeln(_buildParagraph(
      settings.schoolName.toUpperCase(),
      isBold: true,
      fontSize: 28,
      align: 'center',
    ));

    if (settings.schoolAddress.isNotEmpty) {
      sb.writeln(_buildParagraph(
        settings.schoolAddress,
        fontSize: 19,
        align: 'center',
      ));
    }

    if (settings.schoolPhone.isNotEmpty) {
      sb.writeln(_buildParagraph(
        'Telp/Kontak: ${settings.schoolPhone}',
        fontSize: 18,
        align: 'center',
      ));
    }

    // Border line bawah kop
    sb.writeln('''<w:p>
      <w:pPr>
        <w:pBdr>
          <w:bottom w:val="double" w:sz="12" w:space="4" w:color="000000"/>
        </w:pBdr>
      </w:pPr>
    </w:p>''');

    sb.writeln(_buildParagraph(
      'LEMBAR SOAL PENILAIAN SISWA',
      isBold: true,
      fontSize: 24,
      align: 'center',
      isUnderline: true,
    ));

    sb.writeln(_buildParagraph('', fontSize: 12));

    // Tabel Identitas Siswa
    sb.writeln(_buildIdentityTableXml(package, settings));

    sb.writeln(_buildParagraph('', fontSize: 12));

    // Petunjuk Pengerjaan
    sb.writeln(_buildParagraph('PETUNJUK UMUM:', isBold: true, fontSize: 19));
    sb.writeln(_buildParagraph('1. Tuliskan nama dan identitas Anda pada kolom yang telah disediakan.', fontSize: 19));
    sb.writeln(_buildParagraph('2. Periksa dan bacalah setiap butir soal dengan teliti sebelum menjawab.', fontSize: 19));
    sb.writeln(_buildParagraph('3. Dahulukan menjawab soal-soal yang Anda anggap mudah.', fontSize: 19));

    sb.writeln(_buildParagraph('', fontSize: 16));

    // Daftar Soal Siswa
    for (final q in package.questions) {
      sb.writeln(_buildParagraph(
        '${q.number}. ${_xmlEscape(q.questionText)}',
        isBold: true,
        fontSize: 21,
      ));

      if (q.options.isNotEmpty) {
        for (final opt in q.options) {
          sb.writeln(_buildParagraph(
            '     ${opt.key}. ${_xmlEscape(opt.text)}',
            fontSize: 20,
          ));
        }
      } else {
        // Essay blank lines
        sb.writeln(_buildParagraph('     Jawab: .................................................................................................................................................', fontSize: 18));
        sb.writeln(_buildParagraph('     ..............................................................................................................................................................', fontSize: 18));
      }
      sb.writeln(_buildParagraph('', fontSize: 10));
    }

    // PAGE BREAK FOR TEACHER ANSWER KEY
    sb.writeln('''<w:p>
      <w:r>
        <w:br w:type="page"/>
      </w:r>
    </w:p>''');

    // Section 2: Kunci Jawaban & Pembahasan
    sb.writeln(_buildParagraph(
      'KUNCI JAWABAN & PEMBAHASAN LENGKAP',
      isBold: true,
      fontSize: 26,
      align: 'center',
      isUnderline: true,
    ));
    sb.writeln(_buildParagraph(
      'Mata Pelajaran: ${package.subject} | Kelas: ${package.grade}',
      fontSize: 20,
      align: 'center',
    ));
    sb.writeln(_buildParagraph('', fontSize: 14));

    // Ringkasan Kunci PG
    final pgQuestions = package.questions.where((q) => q.isMultipleChoice).toList();
    if (pgQuestions.isNotEmpty) {
      sb.writeln(_buildParagraph('RINGKASAN KUNCI JAWABAN PILIHAN GANDA:', isBold: true, fontSize: 20));
      final keysString = pgQuestions.map((q) => '${q.number}.${q.correctAnswer}').join('   |   ');
      sb.writeln(_buildParagraph(keysString, isBold: true, fontSize: 19));
      sb.writeln(_buildParagraph('', fontSize: 14));
    }

    // Pembahasan Rinci Per Butir Soal
    sb.writeln(_buildParagraph('PEMBAHASAN DAN PEDOMAN PENSKORAN:', isBold: true, fontSize: 20));
    for (final q in package.questions) {
      sb.writeln(_buildParagraph(
        'Nomor ${q.number} (Kunci: ${_xmlEscape(q.correctAnswer)})',
        isBold: true,
        fontSize: 20,
      ));
      sb.writeln(_buildParagraph(
        'Pembahasan: ${_xmlEscape(q.explanation)}',
        fontSize: 19,
      ));
      sb.writeln(_buildParagraph('', fontSize: 10));
    }

    // Tanda Tangan Guru
    sb.writeln(_buildParagraph('', fontSize: 20));
    final dateStr = DateFormat('dd MMMM yyyy', 'id_ID').format(DateTime.now());
    sb.writeln(_buildParagraph(dateStr, align: 'right', fontSize: 19));
    sb.writeln(_buildParagraph('Guru Pengampu Mata Pelajaran,', align: 'right', fontSize: 19));
    sb.writeln(_buildParagraph('', fontSize: 36));
    sb.writeln(_buildParagraph(settings.teacherName, isBold: true, isUnderline: true, align: 'right', fontSize: 20));
    if (settings.teacherNip.isNotEmpty) {
      sb.writeln(_buildParagraph('NIP. ${settings.teacherNip}', align: 'right', fontSize: 18));
    }

    sb.writeln('</w:body>');
    sb.writeln('</w:document>');
    return sb.toString();
  }

  String _buildParagraph(
    String text, {
    bool isBold = false,
    bool isUnderline = false,
    int fontSize = 22,
    String align = 'left',
  }) {
    final alignTag = align != 'left' ? '<w:jc w:val="$align"/>' : '';
    final boldTag = isBold ? '<w:b/>' : '';
    final underlineTag = isUnderline ? '<w:u w:val="single"/>' : '';

    return '''<w:p>
      <w:pPr>$alignTag</w:pPr>
      <w:r>
        <w:rPr>
          $boldTag
          $underlineTag
          <w:sz w:val="$fontSize"/>
        </w:rPr>
        <w:t xml:space="preserve">${_xmlEscape(text)}</w:t>
      </w:r>
    </w:p>''';
  }

  String _buildIdentityTableXml(QuestionPackageModel package, AppSettingsModel settings) {
    return '''<w:tbl>
      <w:tblPr>
        <w:tblW w:w="5000" w:type="pct"/>
        <w:tblBorders>
          <w:top w:val="single" w:sz="4" w:space="0" w:color="CCCCCC"/>
          <w:left w:val="single" w:sz="4" w:space="0" w:color="CCCCCC"/>
          <w:bottom w:val="single" w:sz="4" w:space="0" w:color="CCCCCC"/>
          <w:right w:val="single" w:sz="4" w:space="0" w:color="CCCCCC"/>
          <w:insideH w:val="single" w:sz="4" w:space="0" w:color="E5E5E5"/>
          <w:insideV w:val="single" w:sz="4" w:space="0" w:color="E5E5E5"/>
        </w:tblBorders>
      </w:tblPr>
      <w:tr>
        <w:tc>
          <w:p><w:r><w:rPr><w:b/><w:sz w:val="18"/></w:rPr><w:t>Mata Pelajaran</w:t></w:r></w:p>
        </w:tc>
        <w:tc>
          <w:p><w:r><w:rPr><w:sz w:val="18"/></w:rPr><w:t>: ${_xmlEscape(package.subject)}</w:t></w:r></w:p>
        </w:tc>
        <w:tc>
          <w:p><w:r><w:rPr><w:b/><w:sz w:val="18"/></w:rPr><w:t>Nama Siswa</w:t></w:r></w:p>
        </w:tc>
        <w:tc>
          <w:p><w:r><w:rPr><w:sz w:val="18"/></w:rPr><w:t>: ............................................</w:t></w:r></w:p>
        </w:tc>
      </w:tr>
      <w:tr>
        <w:tc>
          <w:p><w:r><w:rPr><w:b/><w:sz w:val="18"/></w:rPr><w:t>Kelas / Jenjang</w:t></w:r></w:p>
        </w:tc>
        <w:tc>
          <w:p><w:r><w:rPr><w:sz w:val="18"/></w:rPr><w:t>: ${_xmlEscape(package.grade)}</w:t></w:r></w:p>
        </w:tc>
        <w:tc>
          <w:p><w:r><w:rPr><w:b/><w:sz w:val="18"/></w:rPr><w:t>No. Absen / Peserta</w:t></w:r></w:p>
        </w:tc>
        <w:tc>
          <w:p><w:r><w:rPr><w:sz w:val="18"/></w:rPr><w:t>: ............................................</w:t></w:r></w:p>
        </w:tc>
      </w:tr>
      <w:tr>
        <w:tc>
          <w:p><w:r><w:rPr><w:b/><w:sz w:val="18"/></w:rPr><w:t>Kurikulum</w:t></w:r></w:p>
        </w:tc>
        <w:tc>
          <w:p><w:r><w:rPr><w:sz w:val="18"/></w:rPr><w:t>: ${_xmlEscape(package.curriculum)}</w:t></w:r></w:p>
        </w:tc>
        <w:tc>
          <w:p><w:r><w:rPr><w:b/><w:sz w:val="18"/></w:rPr><w:t>Hari / Tanggal</w:t></w:r></w:p>
        </w:tc>
        <w:tc>
          <w:p><w:r><w:rPr><w:sz w:val="18"/></w:rPr><w:t>: ............................................</w:t></w:r></w:p>
        </w:tc>
      </w:tr>
      <w:tr>
        <w:tc>
          <w:p><w:r><w:rPr><w:b/><w:sz w:val="18"/></w:rPr><w:t>Alokasi Waktu</w:t></w:r></w:p>
        </w:tc>
        <w:tc>
          <w:p><w:r><w:rPr><w:sz w:val="18"/></w:rPr><w:t>: ${package.durationMinutes} Menit</w:t></w:r></w:p>
        </w:tc>
        <w:tc>
          <w:p><w:r><w:rPr><w:b/><w:sz w:val="18"/></w:rPr><w:t>Materi</w:t></w:r></w:p>
        </w:tc>
        <w:tc>
          <w:p><w:r><w:rPr><w:sz w:val="18"/></w:rPr><w:t>: ${_xmlEscape(package.topics.join(", "))}</w:t></w:r></w:p>
        </w:tc>
      </w:tr>
    </w:tbl>''';
  }

  /// Export & Share DOCX file via WhatsApp / Drive / Email
  Future<void> exportAndShareDocx({
    required QuestionPackageModel package,
    required AppSettingsModel settings,
  }) async {
    final bytes = generateDocxBytes(package: package, settings: settings);
    final filename = 'Soal_${package.subject}_${package.grade}.docx';

    if (kIsWeb) {
      // In web, trigger share / download
      final xFile = XFile.fromData(
        bytes,
        name: filename,
        mimeType: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      );
      await Share.shareXFiles([xFile], text: 'Dokumen Soal Word: ${package.title}');
    } else {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$filename');
      await file.writeAsBytes(bytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Dokumen Soal Word: ${package.title}',
      );
    }
  }

  /// Save DOCX file directly to device storage
  Future<String> saveDocxLocally({
    required QuestionPackageModel package,
    required AppSettingsModel settings,
  }) async {
    final bytes = generateDocxBytes(package: package, settings: settings);
    final filename = 'Soal_${package.subject}_${package.grade}_${DateTime.now().millisecondsSinceEpoch}.docx';

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes);
    return file.path;
  }
}
