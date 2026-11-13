import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart' as pfd;
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart' as xl;
import '../../data/models/admin_user_item.dart';

/// Helper utility for generating and exporting native PDF and Excel files
/// for the Admin User Management module.
class AdminExportHelper {
  /// Generates native Microsoft Excel (.xlsx) bytes from a list of user items.
  static Uint8List generateExcelBytes(List<AdminUserItem> users) {
    final excel = xl.Excel.createExcel();
    const sheetName = 'Users';
    final sheet = excel[sheetName];
    excel.setDefaultSheet(sheetName);
    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    // Header Row
    sheet.appendRow([
      xl.TextCellValue('User ID'),
      xl.TextCellValue('Full Name'),
      xl.TextCellValue('Email'),
      xl.TextCellValue('Phone Number'),
      xl.TextCellValue('Reputation'),
      xl.TextCellValue('Status'),
      xl.TextCellValue('Role'),
    ]);

    // Data Rows
    for (final user in users) {
      sheet.appendRow([
        xl.TextCellValue(user.id),
        xl.TextCellValue(user.name),
        xl.TextCellValue(user.fullEmail.isNotEmpty ? user.fullEmail : user.emailMasked),
        xl.TextCellValue(user.phoneNumber),
        xl.IntCellValue(user.reputation),
        xl.TextCellValue(user.status),
        xl.TextCellValue(user.role),
      ]);
    }

    final bytes = excel.encode();
    return Uint8List.fromList(bytes ?? []);
  }

  /// Generates native PDF document bytes with branded headers and formatted table.
  static Future<Uint8List> generatePdfBytes(List<AdminUserItem> users) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: pfd.PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        header: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(bottom: 12.0),
            padding: const pw.EdgeInsets.only(bottom: 8.0),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: pfd.PdfColors.grey400, width: 0.5),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'PAWS & FOUND',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: pfd.PdfColors.teal800,
                  ),
                ),
                pw.Text(
                  'Admin User Directory Export',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: pfd.PdfColors.grey700,
                  ),
                ),
              ],
            ),
          );
        },
        footer: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 12.0),
            child: pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 9, color: pfd.PdfColors.grey600),
            ),
          );
        },
        build: (pw.Context context) => [
          pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'User Directory Report',
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: pfd.PdfColors.teal900,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Official administrator summary export',
                      style: const pw.TextStyle(fontSize: 10, color: pfd.PdfColors.grey600),
                    ),
                  ],
                ),
                pw.Text(
                  'Total: ${users.length} Users',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: pfd.PdfColors.teal800,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 14),
          pw.TableHelper.fromTextArray(
            headers: ['Name', 'Email', 'Phone', 'Role', 'Status', 'Rep.'],
            data: users.map((u) => [
              u.name,
              u.fullEmail.isNotEmpty ? u.fullEmail : u.emailMasked,
              u.phoneNumber.isNotEmpty ? u.phoneNumber : '--',
              u.role,
              u.status,
              u.reputation.toString(),
            ]).toList(),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: pfd.PdfColors.white,
              fontSize: 9.5,
            ),
            headerDecoration: const pw.BoxDecoration(color: pfd.PdfColors.teal800),
            rowDecoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: pfd.PdfColors.grey200, width: 0.5),
              ),
            ),
            cellAlignment: pw.Alignment.centerLeft,
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            cellStyle: const pw.TextStyle(fontSize: 9),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  /// Generates a human-readable metadata & preview summary for the UI modal.
  static String generatePreviewSummary({
    required String format,
    required List<AdminUserItem> users,
  }) {
    final buffer = StringBuffer();
    if (format == 'PDF') {
      buffer.writeln('=== PDF DOCUMENT PREVIEW ===');
      buffer.writeln('Format: Portable Document Format (.pdf)');
      buffer.writeln('Title: Paws & Found User Directory Report');
      buffer.writeln('Records: ${users.length} user(s) included');
      buffer.writeln('Columns: Name, Email, Phone, Role, Status, Reputation');
      buffer.writeln('Layout: Branded Header, Multi-Page Table, Footer');
      buffer.writeln('');
      buffer.writeln('Sample Records:');
      for (int i = 0; i < users.length && i < 5; i++) {
        final u = users[i];
        final email = u.fullEmail.isNotEmpty ? u.fullEmail : u.emailMasked;
        buffer.writeln('${i + 1}. ${u.name} <$email> - ${u.status} (${u.role})');
      }
      if (users.length > 5) {
        buffer.writeln('... and ${users.length - 5} more record(s)');
      }
    } else {
      buffer.writeln('=== EXCEL SPREADSHEET PREVIEW ===');
      buffer.writeln('Format: Microsoft Excel OpenXML (.xlsx)');
      buffer.writeln('Worksheet Name: Users');
      buffer.writeln('Total Rows: ${users.length + 1} (1 Header + ${users.length} Data)');
      buffer.writeln('Columns: User ID, Full Name, Email, Phone, Reputation, Status, Role');
      buffer.writeln('');
      buffer.writeln('Sample Rows:');
      for (int i = 0; i < users.length && i < 5; i++) {
        final u = users[i];
        final email = u.fullEmail.isNotEmpty ? u.fullEmail : u.emailMasked;
        buffer.writeln('${i + 1}. ${u.id} | ${u.name} | $email | ${u.status} | ${u.role}');
      }
      if (users.length > 5) {
        buffer.writeln('... and ${users.length - 5} more row(s)');
      }
    }
    return buffer.toString();
  }

  /// Exports bytes, persists to a temporary file, and opens the system share dialog.
  static Future<String?> exportAndShare({
    required String format,
    required List<AdminUserItem> users,
  }) async {
    try {
      Uint8List bytes;
      String fileName;
      String mimeType;

      if (format == 'PDF') {
        bytes = await generatePdfBytes(users);
        fileName = 'paws_users_${DateTime.now().millisecondsSinceEpoch}.pdf';
        mimeType = 'application/pdf';
      } else {
        bytes = generateExcelBytes(users);
        fileName = 'paws_users_${DateTime.now().millisecondsSinceEpoch}.xlsx';
        mimeType = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      }

      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(bytes, flush: true);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(filePath, mimeType: mimeType, name: fileName)],
          text: 'Paws & Found Users Export ($format)',
          subject: 'Paws & Found Users Export',
        ),
      );

      return filePath;
    } catch (e) {
      debugPrint('Export/Share execution note: $e');
      return null;
    }
  }
}
