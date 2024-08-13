import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class ViewPDF extends StatelessWidget {
  final File pdf;
  const ViewPDF({super.key, required this.pdf});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox(
          height: double.infinity,
          width: double.infinity,
          child: SfPdfViewer.file(
            pdf,//'https://cdn.syncfusion.com/content/PDFViewer/flutter-succinctly.pdf',
            scrollDirection: PdfScrollDirection.vertical,
            canShowScrollStatus: true,
            enableDoubleTapZooming: true,
            enableTextSelection: true,
          )
      ),
    );
  }
}
