import 'dart:typed_data';
import 'dart:convert';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:http/http.dart' as http;
import '../models/thermal_receipt.dart';

class ReceiptFormatter {
  static final _currency = NumberFormat.currency(symbol: '₦');

  /// Build ESC/POS bytes using the esc_pos_utils Generator
  static Future<List<int>> buildEscPosBytes(
    ThermalReceipt receipt,
    PaperSize paperSize,
  ) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(paperSize, profile);
    List<int> bytes = [];

    // Header
    bytes += generator.text(
      receipt.organization.name,
      styles: const PosStyles(align: PosAlign.center, height: PosTextSize.size2, width: PosTextSize.size2, bold: true),
    );

    if ((receipt.organization.address).isNotEmpty) {
      bytes += generator.text(receipt.organization.address, styles: const PosStyles(align: PosAlign.center));
    }
    if ((receipt.organization.phone).isNotEmpty) {
      bytes += generator.text('Tel: ${receipt.organization.phone}', styles: const PosStyles(align: PosAlign.center));
    }
    bytes += generator.feed(1);
    bytes += generator.text('RECEIPT', styles: const PosStyles(align: PosAlign.center, bold: true));
    bytes += generator.hr();

    // Receipt meta
    bytes += generator.row([
      PosColumn(text: 'No:', width: 4),
      PosColumn(text: receipt.receiptNumber, width: 8),
    ]);
    bytes += generator.row([
      PosColumn(text: 'Date:', width: 4),
      PosColumn(text: DateFormat('dd/MM/yyyy HH:mm').format(receipt.receiptDate), width: 8),
    ]);
    bytes += generator.hr();

    // Student
    bytes += generator.text('STUDENT', styles: const PosStyles(bold: true));
    bytes += generator.row([
      PosColumn(text: 'Name:', width: 4),
      PosColumn(text: receipt.student.studentName, width: 8),
    ]);
    bytes += generator.row([
      PosColumn(text: 'Adm No:', width: 4),
      PosColumn(text: receipt.student.admissionNumber, width: 8),
    ]);
    bytes += generator.hr();

    // Items
    final descWidth = paperSize == PaperSize.mm80 ? 6 : 5;
    final qtyWidth = paperSize == PaperSize.mm80 ? 2 : 2;
    final amtWidth = paperSize == PaperSize.mm80 ? 4 : 5;

    bytes += generator.row([
      PosColumn(text: 'Description', width: descWidth, styles: const PosStyles(bold: true)),
      PosColumn(text: 'Qty', width: qtyWidth, styles: const PosStyles(bold: true)),
      PosColumn(text: 'Amount', width: amtWidth, styles: const PosStyles(bold: true, align: PosAlign.right)),
    ]);
    bytes += generator.hr();

    for (final it in receipt.items) {
      final desc = it.description;
      final qty = it.quantity.toString();
      final amt = _currency.format(it.totalAmount);
      bytes += generator.row([
        PosColumn(text: _shorten(desc, paperSize == PaperSize.mm80 ? 24 : 16), width: descWidth),
        PosColumn(text: qty, width: qtyWidth),
        PosColumn(text: amt, width: amtWidth, styles: const PosStyles(align: PosAlign.right)),
      ]);
    }
    bytes += generator.hr();

    // Totals
    bytes += generator.row([
      PosColumn(text: 'Subtotal', width: 8),
      PosColumn(text: _currency.format(receipt.totals.subtotal), width: 4, styles: const PosStyles(align: PosAlign.right)),
    ]);
    if (receipt.totals.discountAmount > 0) {
      bytes += generator.row([
        PosColumn(text: 'Discount', width: 8),
        PosColumn(text: '-${_currency.format(receipt.totals.discountAmount)}', width: 4, styles: const PosStyles(align: PosAlign.right)),
      ]);
    }
    if (receipt.totals.taxAmount > 0) {
      bytes += generator.row([
        PosColumn(text: 'Tax', width: 8),
        PosColumn(text: _currency.format(receipt.totals.taxAmount), width: 4, styles: const PosStyles(align: PosAlign.right)),
      ]);
    }
    bytes += generator.hr();
    bytes += generator.row([
      PosColumn(text: 'TOTAL', width: 8, styles: const PosStyles(bold: true)),
      PosColumn(text: _currency.format(receipt.totals.grandTotal), width: 4, styles: const PosStyles(bold: true, align: PosAlign.right)),
    ]);
    bytes += generator.hr();

    // Payment
    bytes += generator.text('PAYMENT', styles: const PosStyles(bold: true));
    bytes += generator.row([
      PosColumn(text: 'Method:', width: 4),
      PosColumn(text: receipt.payment.paymentMethod, width: 8),
    ]);
    if (receipt.payment.transactionReference != null) {
      bytes += generator.row([
        PosColumn(text: 'Ref:', width: 4),
        PosColumn(text: receipt.payment.transactionReference!, width: 8),
      ]);
    }
    bytes += generator.feed(1);

    // Footer
    if (receipt.footerMessage != null && receipt.footerMessage!.isNotEmpty) {
      bytes += generator.text(receipt.footerMessage!, styles: const PosStyles(align: PosAlign.center));
      bytes += generator.feed(1);
    }
    bytes += generator.text('Thank you!', styles: const PosStyles(align: PosAlign.center, bold: true));
    bytes += generator.feed(2);
    bytes += generator.cut();

    return bytes;
  }

  /// Fallback: generate a PDF bytes buffer for reprint or saving
  static Future<Uint8List> buildPdf(Uint8List? logoBytes, ThermalReceipt receipt) async {
    final pdf = pw.Document();
    final font = pw.Font.helvetica();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80, // approximate thermal width
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              if (logoBytes != null)
                pw.Center(child: pw.Image(pw.MemoryImage(logoBytes), width: 80, height: 80)),
              pw.SizedBox(height: 8),
              pw.Text(receipt.organization.name, style: pw.TextStyle(font: font, fontSize: 14, fontWeight: pw.FontWeight.bold)),
              if ((receipt.organization.address).isNotEmpty) pw.Text(receipt.organization.address, style: pw.TextStyle(font: font, fontSize: 9)),
              pw.SizedBox(height: 6),
              pw.Text('RECEIPT', style: pw.TextStyle(font: font, fontSize: 12, fontWeight: pw.FontWeight.bold)),
              pw.Divider(),
              pw.Text('Receipt No: ${receipt.receiptNumber}', style: pw.TextStyle(font: font, fontSize: 9)),
              pw.Text('Date: ${DateFormat('dd/MM/yyyy HH:mm').format(receipt.receiptDate)}', style: pw.TextStyle(font: font, fontSize: 9)),
              pw.SizedBox(height: 6),
              pw.Text('STUDENT', style: pw.TextStyle(font: font, fontSize: 10, fontWeight: pw.FontWeight.bold)),
              pw.Text('${receipt.student.studentName} • ${receipt.student.admissionNumber}', style: pw.TextStyle(font: font, fontSize: 9)),
              pw.Divider(),
              pw.Table.fromTextArray(
                headers: ['Description', 'Qty', 'Amount'],
                data: receipt.items.map((it) => [it.description, it.quantity.toString(), _currency.format(it.totalAmount)]).toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
                cellStyle: pw.TextStyle(fontSize: 9),
              ),
              pw.Divider(),
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                pw.Text('TOTAL', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                pw.Text(_currency.format(receipt.totals.grandTotal), style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
              ]),
              pw.SizedBox(height: 12),
              if (receipt.footerMessage != null) pw.Text(receipt.footerMessage!, textAlign: pw.TextAlign.center),
              pw.SizedBox(height: 12),
              pw.Text('Thank you!', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Attempt to fetch logo bytes (network or base64)
  static Future<Uint8List?> fetchLogoBytes(String? logo) async {
    if (logo == null || logo.isEmpty) return null;
    try {
      // If looks like base64
      if (logo.startsWith('data:image')) {
        final base64Str = logo.split(',').last;
        return base64Decode(base64Str);
      }
      // Otherwise try HTTP fetch
      final res = await http.get(Uri.parse(logo)).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) return res.bodyBytes;
    } catch (_) {}
    return null;
  }

  static String _shorten(String s, int len) {
    if (s.length <= len) return s;
    return '${s.substring(0, len - 3)}...';
  }
}