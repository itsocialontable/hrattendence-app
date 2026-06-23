import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class HRPolicyScreen extends StatelessWidget {
  const HRPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(20),
          ),
          child: SfPdfViewer.asset(
            'assets/pdf/hr_policy.pdf',
            canShowScrollHead: true,
            canShowScrollStatus: true,
            pageLayoutMode: PdfPageLayoutMode.continuous,

            onDocumentLoadFailed: (details) {
              debugPrint(
                'PDF Error: ${details.error} - ${details.description}',
              );
            },
          ),
        ),
      ),
    );
  }
}