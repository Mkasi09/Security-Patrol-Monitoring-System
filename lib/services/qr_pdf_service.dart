import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/location.dart';

class QRPdfService {
  static Future<void> generateAndDownloadQRPdf(Location location) async {
    try {
      // Create PDF document
      final pdf = pw.Document();
      
      // Generate QR code image data
      final qrValidationResult = QrValidator.validate(
        data: location.qrCode,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.L,
      );
      
      if (qrValidationResult.status != QrValidationStatus.valid) {
        throw Exception('Invalid QR code data');
      }
      
      final qrCode = qrValidationResult.qrCode!;
      final painter = QrPainter.withQr(
        qr: qrCode,
        color: Colors.black,
        gapless: true,
        embeddedImageStyle: null,
        embeddedImage: null,
      );
      
      final qrImageData = await painter.toImageData(300);
      final qrImageBytes = qrImageData!.buffer.asUint8List();
      
      // Add PDF page
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                // Title
                pw.Text(
                  'Location QR Code',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 20),
                
                // Location Information Card
                pw.Container(
                  padding: const pw.EdgeInsets.all(20),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Location Details',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 10),
                      _buildInfoRow('Name:', location.name),
                      pw.SizedBox(height: 5),
                      _buildInfoRow('Address:', location.address),
                      pw.SizedBox(height: 5),
                      _buildInfoRow('QR Code:', location.qrCode),
                      pw.SizedBox(height: 5),
                      _buildInfoRow('Location ID:', location.id),
                    ],
                  ),
                ),
                pw.SizedBox(height: 30),
                
                // QR Code
                pw.Container(
                  padding: const pw.EdgeInsets.all(20),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'Scan this QR Code',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 15),
                      pw.Image(
                        pw.MemoryImage(qrImageBytes),
                        width: 200,
                        height: 200,
                      ),
                      pw.SizedBox(height: 10),
                      pw.Text(
                        location.qrCode,
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontStyle: pw.FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),
                
                // Instructions
                pw.Container(
                  padding: const pw.EdgeInsets.all(15),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Instructions:',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Bullet(
                        text: 'Print this QR code and place it at the location',
                      ),
                      pw.Bullet(
                        text: 'Ensure the QR code is clearly visible and accessible',
                      ),
                      pw.Bullet(
                        text: 'Guards can scan this code to submit patrol reports',
                      ),
                    ],
                  ),
                ),
                
                pw.Spacer(),
                
                // Footer
                pw.Text(
                  'Generated on ${DateTime.now().toString().split('.')[0]}',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            );
          },
        ),
      );
      
      // Save PDF to temporary directory
      final directory = await getTemporaryDirectory();
      final fileName = 'QR_Code_${location.name.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${directory.path}/$fileName');
      
      await file.writeAsBytes(await pdf.save());
      
      // Share the PDF file
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'QR Code for ${location.name}',
        text: 'QR code for location: ${location.name}',
      );
      
    } catch (e) {
      throw Exception('Failed to generate PDF: $e');
    }
  }
  
  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 80,
          child: pw.Text(
            label,
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            value,
            style: const pw.TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }
}
