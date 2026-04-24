import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      
      // Load logo image
      final logoData = await rootBundle.load('assets/loggo.png');
      final logoBytes = logoData.buffer.asUint8List();
      
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
      
      final qrImageData = await painter.toImageData(400); // Larger QR code for better scanning
      final qrImageBytes = qrImageData!.buffer.asUint8List();
      
      // Add PDF page
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (pw.Context context) {
            return pw.Container(
              width: double.infinity,
              height: double.infinity,
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.black, width: 2),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
              ),
              child: pw.Padding(
                padding: const pw.EdgeInsets.all(20),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    // Header with Logo
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        pw.Container(
                          width: 80,
                          height: 80,
                          child: pw.Image(
                            pw.MemoryImage(logoBytes),
                            fit: pw.BoxFit.contain,
                          ),
                        ),
                        pw.SizedBox(width: 20),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'Security Patrol',
                              style: pw.TextStyle(
                                fontSize: 28,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.blue800,
                              ),
                            ),
                            pw.Text(
                              'Check-in Point',
                              style: pw.TextStyle(
                                fontSize: 16,
                                color: PdfColors.grey600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 30),
                    
                    // Location Information
                    pw.Container(
                      width: double.infinity,
                      padding: const pw.EdgeInsets.all(20),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.blue50,
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                        border: pw.Border.all(color: PdfColors.blue200),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          pw.Text(
                            location.name,
                            style: pw.TextStyle(
                              fontSize: 24,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.blue800,
                            ),
                            textAlign: pw.TextAlign.center,
                          ),
                          pw.SizedBox(height: 8),
                          pw.Text(
                            location.address,
                            style: pw.TextStyle(
                              fontSize: 16,
                              color: PdfColors.grey700,
                            ),
                            textAlign: pw.TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 40),
                    
                    // QR Code - Large and prominent
                    pw.Container(
                      padding: const pw.EdgeInsets.all(30),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.white,
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
                        border: pw.Border.all(color: PdfColors.grey400, width: 2),
                      ),
                      child: pw.Column(
                        children: [
                          pw.Text(
                            'SCAN TO CHECK IN',
                            style: pw.TextStyle(
                              fontSize: 18,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.blue800,
                            ),
                          ),
                          pw.SizedBox(height: 20),
                          pw.Image(
                            pw.MemoryImage(qrImageBytes),
                            width: 250,
                            height: 250,
                          ),
                          pw.SizedBox(height: 20),
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            decoration: pw.BoxDecoration(
                              color: PdfColors.blue100,
                              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(20)),
                            ),
                            child: pw.Text(
                              'Location ID: ${location.id}',
                              style: pw.TextStyle(
                                fontSize: 12,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.blue800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    pw.Spacer(),
                    
                    // Footer
                    pw.Container(
                      width: double.infinity,
                      padding: const pw.EdgeInsets.all(15),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey100,
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                      ),
                      child: pw.Column(
                        children: [
                          pw.Text(
                            'Security Patrol Monitoring System',
                            style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.grey600,
                            ),
                          ),
                          pw.SizedBox(height: 5),
                          pw.Text(
                            'Place this QR code at the designated checkpoint',
                            style: pw.TextStyle(
                              fontSize: 10,
                              color: PdfColors.grey500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
      
      // Save PDF to temporary directory
      final directory = await getTemporaryDirectory();
      final fileName = 'Checkpoint_${location.name.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${directory.path}/$fileName');
      
      await file.writeAsBytes(await pdf.save());
      
      // Share the PDF file
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Security Checkpoint - ${location.name}',
        text: 'Security patrol checkpoint QR code for: ${location.name}',
      );
      
    } catch (e) {
      throw Exception('Failed to generate PDF: $e');
    }
  }
  
}
