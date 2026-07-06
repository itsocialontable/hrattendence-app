import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

// ─── Enums & Models ──────────────────────────────────────────────────────────

enum DocStatus { notUploaded, uploading, uploaded, failed, deleting }

class ServerDoc {
  final String docType;
  final String fileName;
  final String fileType;
  final String uploadedAt;
  final String viewUrl;

  ServerDoc({
    required this.docType,
    required this.fileName,
    required this.fileType,
    required this.uploadedAt,
    required this.viewUrl,
  });

  factory ServerDoc.fromJson(Map<String, dynamic> j) {
    return ServerDoc(
      docType: j['docType'] ?? j['doc_type'] ?? '',
      fileName: j['fileName'] ?? j['file_name'] ?? '',
      fileType: j['fileType'] ?? j['file_type'] ?? '',
      uploadedAt: j['uploadedAt'] ?? j['uploaded_at'] ?? '',
      viewUrl: j['viewUrl'] ?? j['view_url'] ?? '',
    );
  }
}

class DocumentItem {
  final String docType;
  final String label;
  final String description;
  final IconData icon;
  final Color color;
  final bool required;

  DocStatus status;
  String? uploadedFileName;
  String? uploadedAt;
  String? errorMsg;
  String? viewUrl;

  DocumentItem({
    required this.docType,
    required this.label,
    required this.description,
    required this.icon,
    required this.color,
    this.required = true,
    this.status = DocStatus.notUploaded,
    this.uploadedFileName,
    this.uploadedAt,
    this.errorMsg,
    this.viewUrl,
  });
}

// ─── Screen ──────────────────────────────────────────────────────────────────

class DocumentUploadScreen extends StatefulWidget {
  const DocumentUploadScreen({super.key});

  @override
  State<DocumentUploadScreen> createState() => _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends State<DocumentUploadScreen>
    with TickerProviderStateMixin {
  //
  // static const String _baseUrl =
  //     'https://whacking-dispute-agility.ngrok-free.dev';

  bool _initialLoading = true;
  String? _loadError;
  late AnimationController _headerAnim;

  final List<DocumentItem> _docs = [
    DocumentItem(
      docType: 'aadhar',
      label: 'Aadhar Card',
      description: 'Front & back side, clear scan/photo',
      icon: Icons.fingerprint_rounded,
      color: AppColors.primary,
      required: true,
    ),
    DocumentItem(
      docType: 'pan',
      label: 'PAN Card',
      description: 'Clear photo of PAN card',
      icon: Icons.credit_card_rounded,
      color: AppColors.secondary,
      required: true,
    ),
    DocumentItem(
      docType: 'passbook',
      label: 'Bank Account Proof',
      description: 'Passbook front page or cancelled cheque',
      icon: Icons.account_balance_rounded,
      color: AppColors.success,
      required: true,
    ),
    DocumentItem(
      docType: 'marksheet',
      label: 'Graduation Marksheet',
      description: 'Final year or consolidated marksheet',
      icon: Icons.school_rounded,
      color: AppColors.warning,
      required: true,
    ),
    DocumentItem(
      docType: 'resume',
      label: 'Resume / CV',
      description: 'Latest updated resume (PDF preferred)',
      icon: Icons.description_rounded,
      color: AppColors.accent,
      required: false,
    ),
    DocumentItem(
      docType: 'experience',
      label: 'Experience Letter',
      description: 'From previous employer (if applicable)',
      icon: Icons.work_history_rounded,
      color: AppColors.primaryLight,
      required: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _headerAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchDocs());
  }

  @override
  void dispose() {
    _headerAnim.dispose();
    super.dispose();
  }

  String get _userId => context.read<AuthProvider>().user?.id ?? '';
  String? get _token => context.read<AuthProvider>().token;

  // ─── GET all docs ──────────────────────────────────────────────────────────

  Future<void> _fetchDocs() async {
    setState(() { _initialLoading = true; _loadError = null; });
    try {
      final token = _token;
      debugPrint('📂 [DocumentUpload] GET /api/documents/$_userId');
      debugPrint('📂 [DocumentUpload] Token: $token');

      final res = await http.get(
        Uri.parse('${ApiService.baseUrl}/api/documents/$_userId'),
        headers: {
          'Authorization': 'Bearer $token',
          // 'ngrok-skip-browser-warning': 'true',
        },
      ).timeout(const Duration(seconds: 30));

      log('📥 GET docs ${res.statusCode}: ${res.body}');
      debugPrint('📂 [DocumentUpload] FETCH STATUS: ${res.statusCode}');
      debugPrint('📂 [DocumentUpload] FETCH BODY: ${res.body}');

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        // Support both list and {documents:[...]} format
        final List<dynamic> list = data is List
            ? data
            : (data['documents'] ?? data['data'] ?? []);

        final serverDocs = list.map((e) => ServerDoc.fromJson(e)).toList();

        setState(() {
          for (final sd in serverDocs) {
            final doc = _docs.firstWhere(
                  (d) => d.docType == sd.docType,
              orElse: () => DocumentItem(
                docType: sd.docType, label: sd.docType,
                description: '', icon: Icons.insert_drive_file_rounded,
                color: AppColors.textMid,
              ),
            );
            doc.status = DocStatus.uploaded;
            doc.uploadedFileName = sd.fileName;
            doc.uploadedAt = sd.uploadedAt;
            doc.viewUrl = sd.viewUrl.isNotEmpty
                ? sd.viewUrl
                : '${ApiService.baseUrl}/api/documents/$_userId/${sd.docType}/view';
          }
        });
        debugPrint('📂 [DocumentUpload] ✅ Loaded ${serverDocs.length} document(s) successfully');
      } else {
        _loadError = 'Failed to fetch documents';
        debugPrint('📂 [DocumentUpload] ❌ Fetch failed — status: ${res.statusCode}, body: ${res.body}');
      }
    } catch (e) {
      log('❌ Fetch error: $e');
      debugPrint('📂 [DocumentUpload] ❌ Fetch EXCEPTION: $e');
      _loadError = 'Could not load documents. Pull to refresh.';
    } finally {
      setState(() => _initialLoading = false);
    }
  }

  // ─── GET single doc view ───────────────────────────────────────────────────

  Future<void> _viewDoc(DocumentItem doc) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(doc.color),
            ),
            const SizedBox(height: 16),
            Text('Loading ${doc.label}...',
                style: GoogleFonts.poppins(
                    fontSize: 13, color: AppColors.textMid)),
          ]),
        ),
      ),
    );

    try {
      final url = doc.viewUrl ??
          '${ApiService.baseUrl}/api/documents/$_userId/${doc.docType}/view';

      log('👁 Fetching view: $url');
      debugPrint('📂 [DocumentUpload] VIEW GET: $url');
      debugPrint('📂 [DocumentUpload] Token: $_token');

      final res = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $_token',
          // 'ngrok-skip-browser-warning': 'true',
        },
      ).timeout(const Duration(seconds: 30));

      if (mounted) Navigator.pop(context); // close loader

      log('📥 View ${res.statusCode}, type: ${res.headers['content-type']}');
      debugPrint('📂 [DocumentUpload] VIEW STATUS: ${res.statusCode}');
      debugPrint('📂 [DocumentUpload] VIEW content-type: ${res.headers['content-type']}');

      if (res.statusCode == 200) {
        final contentType = res.headers['content-type'] ?? '';
        debugPrint('📂 [DocumentUpload] ✅ VIEW success — ${res.bodyBytes.length} bytes');

        if (contentType.contains('json')) {
          // Server wrapped the file inside a JSON object (e.g. base64 fileData)
          debugPrint('📂 [DocumentUpload] VIEW raw JSON body: ${res.body}');
          try {
            final json = jsonDecode(res.body) as Map<String, dynamic>;
            final base64Str = json['fileData'] ?? json['file_data'] ??
                json['data'] ?? json['base64'] ?? json['content'];
            final realType = json['fileType'] ?? json['file_type'] ??
                json['mimeType'] ?? json['contentType'] ?? '';

            if (base64Str == null) {
              debugPrint('📂 [DocumentUpload] ❌ No file data field found in JSON keys: ${json.keys}');
              _showSnack('Server did not return file data', AppColors.error);
              return;
            }

            // Strip data: URL prefix if present, e.g. "data:image/png;base64,...."
            final cleanBase64 = (base64Str as String).contains(',')
                ? base64Str.split(',').last
                : base64Str;
            final decodedBytes = base64Decode(cleanBase64);
            debugPrint('📂 [DocumentUpload] ✅ Decoded base64 → ${decodedBytes.length} bytes, type: $realType');
            _showDocViewer(doc, decodedBytes, realType as String);
          } catch (e) {
            debugPrint('📂 [DocumentUpload] ❌ JSON file parse error: $e');
            _showSnack('Could not parse document data', AppColors.error);
          }
        } else {
          final bytes = res.bodyBytes;
          _showDocViewer(doc, bytes, contentType);
        }
      } else {
        debugPrint('📂 [DocumentUpload] ❌ VIEW failed — status: ${res.statusCode}, body: ${res.body}');
        _showSnack('Could not load document preview', AppColors.error);
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      log('❌ View error: $e');
      debugPrint('📂 [DocumentUpload] ❌ VIEW EXCEPTION: $e');
      _showSnack('Failed to load document', AppColors.error);
    }
  }

  void _showDocViewer(DocumentItem doc, List<int> bytes, String contentType) {
    final isImage = contentType.contains('image');
    final isPdf = contentType.contains('pdf');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.92,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, ctrl) => Container(
          decoration: const BoxDecoration(
            color: AppColors.textDark,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(children: [
            // Handle & Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Column(children: [
                Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 14),
                Row(children: [
                  Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      color: doc.color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(doc.icon, color: doc.color, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(doc.label,
                        style: GoogleFonts.poppins(
                            fontSize: 15, fontWeight: FontWeight.w700,
                            color: Colors.white)),
                    if (doc.uploadedFileName != null)
                      Text(doc.uploadedFileName!,
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                              fontSize: 11, color: Colors.white54)),
                  ])),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 34, height: 34,
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.close_rounded,
                          color: Colors.white, size: 18),
                    ),
                  ),
                ]),
              ]),
            ),
            Container(height: 1, color: Colors.white10),

            // Content
            Expanded(
              child: isImage
                  ? InteractiveViewer(
                child: Center(
                  child: Image.memory(
                    Uint8List.fromList(bytes),
                    fit: BoxFit.contain,
                  ),
                ),
              )
                  : isPdf
                  ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.picture_as_pdf_rounded,
                    color: AppColors.error, size: 56),
                const SizedBox(height: 12),
                Text('PDF Preview',
                    style: GoogleFonts.poppins(
                        fontSize: 16, fontWeight: FontWeight.w600,
                        color: Colors.white)),
                const SizedBox(height: 6),
                Text(doc.uploadedFileName ?? '',
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: Colors.white54)),
                const SizedBox(height: 16),
                Text('Add syncfusion_flutter_pdfviewer\nfor in-app PDF viewing',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: Colors.white38)),
              ]))
                  : Center(child: Text('Cannot preview this file type',
                  style: GoogleFonts.poppins(color: Colors.white54))),
            ),
          ]),
        ),
      ),
    );
  }

  // ─── DELETE doc ────────────────────────────────────────────────────────────

  Future<void> _deleteDoc(DocumentItem doc) async {
    // Confirm dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 60, height: 60,
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.error, size: 28),
            ),
            const SizedBox(height: 16),
            Text('Delete Document?',
                style: GoogleFonts.poppins(
                    fontSize: 17, fontWeight: FontWeight.w700,
                    color: AppColors.textDark)),
            const SizedBox(height: 8),
            Text(
              'Are you sure you want to delete "${doc.label}"? This action cannot be undone.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 13, color: AppColors.textMid, height: 1.5),
            ),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(child: GestureDetector(
                onTap: () => Navigator.pop(context, false),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(child: Text('Cancel',
                      style: GoogleFonts.poppins(
                          fontSize: 14, fontWeight: FontWeight.w600,
                          color: AppColors.textMid))),
                ),
              )),
              const SizedBox(width: 12),
              Expanded(child: GestureDetector(
                onTap: () => Navigator.pop(context, true),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(
                      color: AppColors.error.withOpacity(0.3),
                      blurRadius: 8, offset: const Offset(0, 3),
                    )],
                  ),
                  child: Center(child: Text('Delete',
                      style: GoogleFonts.poppins(
                          fontSize: 14, fontWeight: FontWeight.w700,
                          color: Colors.white))),
                ),
              )),
            ]),
          ]),
        ),
      ),
    );

    if (confirm != true) return;

    setState(() => doc.status = DocStatus.deleting);

    try {
      final url = '${ApiService.baseUrl}/api/documents/$_userId/${doc.docType}';
      log('🗑 DELETE: $url');
      debugPrint('📂 [DocumentUpload] DELETE: $url');
      debugPrint('📂 [DocumentUpload] Token: $_token');

      final res = await http.delete(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $_token',
          // 'ngrok-skip-browser-warning': 'true',
        },
      ).timeout(const Duration(seconds: 30));

      log('📥 DELETE ${res.statusCode}: ${res.body}');
      debugPrint('📂 [DocumentUpload] DELETE STATUS: ${res.statusCode}');
      debugPrint('📂 [DocumentUpload] DELETE BODY: ${res.body}');

      if (res.statusCode == 200 || res.statusCode == 204) {
        setState(() {
          doc.status = DocStatus.notUploaded;
          doc.uploadedFileName = null;
          doc.uploadedAt = null;
          doc.viewUrl = null;
          doc.errorMsg = null;
        });
        debugPrint('📂 [DocumentUpload] ✅ DELETE success — ${doc.docType}');
        if (mounted) {
          _showSnack('${doc.label} deleted successfully', AppColors.success);
        }
      } else {
        final body = jsonDecode(res.body);
        debugPrint('📂 [DocumentUpload] ❌ DELETE failed — status: ${res.statusCode}, body: ${res.body}');
        throw Exception(body['message'] ?? 'Delete failed');
      }
    } catch (e) {
      log('❌ Delete error: $e');
      debugPrint('📂 [DocumentUpload] ❌ DELETE EXCEPTION: $e');
      setState(() {
        doc.status = DocStatus.uploaded; // revert
        doc.errorMsg = null;
      });
      if (mounted) {
        _showSnack('Delete failed: ${e.toString().replaceAll('Exception: ', '')}',
            AppColors.error);
      }
    }
  }

  // ─── Upload ────────────────────────────────────────────────────────────────

  Future<void> _pickAndUpload(DocumentItem doc) async {
    final source = await _showPickerSheet(doc);
    if (source == null) return;

    File? file;
    String? fileName;
    String? fileType;

    if (source == 'camera') {
      final picked = await ImagePicker().pickImage(
          source: ImageSource.camera, imageQuality: 85);
      if (picked == null) return;
      file = File(picked.path);
      fileName = picked.name;
      fileType = 'image/jpeg';
    } else if (source == 'gallery') {
      final picked = await ImagePicker().pickImage(
          source: ImageSource.gallery, imageQuality: 85);
      if (picked == null) return;
      file = File(picked.path);
      fileName = picked.name;
      fileType = 'image/${picked.path.split('.').last.toLowerCase()}';
    } else {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );
      if (result == null || result.files.isEmpty) return;
      final pf = result.files.first;
      if (pf.path == null) return;
      file = File(pf.path!);
      fileName = pf.name;
      final ext = pf.extension?.toLowerCase() ?? 'pdf';
      fileType = ext == 'pdf' ? 'application/pdf' : 'image/$ext';
    }

    await _upload(doc, file, fileName!, fileType!);
  }

  Future<String?> _showPickerSheet(DocumentItem doc) async {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4,
              decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          Row(children: [
            Container(width: 44, height: 44,
                decoration: BoxDecoration(
                    color: doc.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14)),
                child: Icon(doc.icon, color: doc.color, size: 22)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Upload ${doc.label}',
                  style: GoogleFonts.poppins(
                      fontSize: 16, fontWeight: FontWeight.w700,
                      color: AppColors.textDark)),
              Text('Choose upload method',
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: AppColors.textLight)),
            ])),
          ]),
          const SizedBox(height: 24),
          _pickerTile(Icons.camera_alt_rounded, 'Take a Photo',
              'Capture document with camera', AppColors.primary,
                  () => Navigator.pop(context, 'camera')),
          const SizedBox(height: 10),
          _pickerTile(Icons.photo_library_rounded, 'Choose from Gallery',
              'Select image from photos', AppColors.secondary,
                  () => Navigator.pop(context, 'gallery')),
          const SizedBox(height: 10),
          _pickerTile(Icons.folder_open_rounded, 'Browse Files',
              'Upload PDF or image file', AppColors.success,
                  () => Navigator.pop(context, 'file')),
        ]),
      ),
    );
  }

  Widget _pickerTile(IconData icon, String label, String sub, Color color,
      VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(children: [
          Container(width: 40, height: 40,
              decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 20)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: GoogleFonts.poppins(
                fontSize: 14, fontWeight: FontWeight.w600,
                color: AppColors.textDark)),
            Text(sub, style: GoogleFonts.poppins(
                fontSize: 11, color: AppColors.textLight)),
          ])),
          Icon(Icons.chevron_right_rounded, color: color, size: 20),
        ]),
      ),
    );
  }

  Future<void> _upload(
      DocumentItem doc, File file, String fileName, String fileType) async {
    setState(() { doc.status = DocStatus.uploading; doc.errorMsg = null; });
    try {
      final bytes = await file.readAsBytes();
      final payload = {
        'userId': _userId,
        'docType': doc.docType,
        'fileData': base64Encode(bytes),
        'fileName': fileName,
        'fileType': fileType,
      };

      log('📤 Uploading ${doc.docType}');
      debugPrint('📂 [DocumentUpload] POST /api/documents — docType: ${doc.docType}, fileName: $fileName');
      debugPrint('📂 [DocumentUpload] Token: $_token');

      final res = await http.post(
        Uri.parse('${ApiService.baseUrl}/api/documents'),
        headers: {
           'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
          // 'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 60));

      log('📥 Upload ${res.statusCode}: ${res.body}');
      debugPrint('📂 [DocumentUpload] UPLOAD STATUS: ${res.statusCode}');
      debugPrint('📂 [DocumentUpload] UPLOAD BODY: ${res.body}');

      if (res.statusCode == 200 || res.statusCode == 201) {
        final body = jsonDecode(res.body);
        setState(() {
          doc.status = DocStatus.uploaded;
          doc.uploadedFileName = fileName;
          doc.uploadedAt = DateTime.now().toIso8601String();
          doc.viewUrl = body['viewUrl'] ?? body['view_url'] ??
              '${ApiService.baseUrl}/api/documents/$_userId/${doc.docType}/view';
        });
        debugPrint('📂 [DocumentUpload] ✅ UPLOAD success — ${doc.docType}');
        if (mounted) _showSnack('${doc.label} uploaded!', AppColors.success);
      } else {
        final body = jsonDecode(res.body);
        debugPrint('📂 [DocumentUpload] ❌ UPLOAD failed — status: ${res.statusCode}, body: ${res.body}');
        throw Exception(body['message'] ?? 'Upload failed');
      }
    } catch (e) {
      log('❌ Upload error: $e');
      debugPrint('📂 [DocumentUpload] ❌ UPLOAD EXCEPTION: $e');
      setState(() {
        doc.status = DocStatus.failed;
        doc.errorMsg = e.toString().replaceAll('Exception: ', '');
      });
      if (mounted) _showSnack('Upload failed: ${doc.errorMsg}', AppColors.error);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600, color: Colors.white)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.all(16),
    ));
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_initialLoading) return _buildShimmer();

    final uploaded = _docs.where((d) => d.status == DocStatus.uploaded).length;
    final reqTotal = _docs.where((d) => d.required).length;
    final reqDone = _docs.where((d) => d.required && d.status == DocStatus.uploaded).length;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _fetchDocs,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 16),

          // Error banner
          if (_loadError != null) ...[
            _buildErrorBanner(),
            const SizedBox(height: 16),
          ],

          // Status Banner
          FadeTransition(
            opacity: _headerAnim,
            child: _buildStatusBanner(uploaded, reqTotal, reqDone),
          ),
          const SizedBox(height: 24),

          // Required
          _sectionLabel('Required Documents', Icons.verified_rounded, AppColors.error),
          const SizedBox(height: 12),
          ..._docs.where((d) => d.required).map(_buildDocCard),
          const SizedBox(height: 24),

          // Optional
          _sectionLabel('Optional Documents', Icons.add_circle_outline_rounded,
              AppColors.textMid),
          const SizedBox(height: 12),
          ..._docs.where((d) => !d.required).map(_buildDocCard),
          const SizedBox(height: 24),

          _buildInfoNote(),
        ]),
      ),
    );
  }

  // ─── Shimmer ───────────────────────────────────────────────────────────────

  Widget _buildShimmer() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      child: Column(children: [
        _ShimmerBox(height: 140, radius: 20),
        const SizedBox(height: 24),
        ...[1, 2, 3, 4].map((_) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _ShimmerBox(height: 84, radius: 16),
        )),
      ]),
    );
  }

  // ─── Error Banner ──────────────────────────────────────────────────────────

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Row(children: [
        const Icon(Icons.wifi_off_rounded, color: AppColors.error, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(_loadError!,
            style: GoogleFonts.poppins(fontSize: 12, color: AppColors.error))),
        GestureDetector(
          onTap: _fetchDocs,
          child: Text('Retry',
              style: GoogleFonts.poppins(
                  fontSize: 12, fontWeight: FontWeight.w700,
                  color: AppColors.error)),
        ),
      ]),
    );
  }

  // ─── Status Banner ─────────────────────────────────────────────────────────

  Widget _buildStatusBanner(int uploaded, int reqTotal, int reqDone) {
    final allDone = reqDone == reqTotal;
    final progress = _docs.isEmpty ? 0.0 : uploaded / _docs.length;

    return PremiumCard(
      gradient: allDone ? AppColors.successGradient : AppColors.primaryGradient,
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 44, height: 44,
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14)),
              child: Icon(
                  allDone ? Icons.task_alt_rounded : Icons.folder_open_rounded,
                  color: Colors.white, size: 22)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(allDone ? 'All required docs uploaded!' : 'Document Verification',
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w700,
                    color: Colors.white)),
            Text('$uploaded / ${_docs.length} documents uploaded',
                style: GoogleFonts.poppins(
                    fontSize: 12, color: Colors.white.withOpacity(0.8))),
          ])),
          GestureDetector(
            onTap: _fetchDocs,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.refresh_rounded,
                  color: Colors.white, size: 16),
            ),
          ),
        ]),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white.withOpacity(0.25),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 12),
        Row(children: [
          _pill('$reqDone/$reqTotal', 'Required'),
          const SizedBox(width: 10),
          _pill('${(progress * 100).toInt()}%', 'Complete'),
          const Spacer(),
          if (!allDone)
            Text('${reqTotal - reqDone} pending',
                style: GoogleFonts.poppins(
                    fontSize: 11, color: Colors.white.withOpacity(0.8))),
        ]),
      ]),
    );
  }

  Widget _pill(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(value, style: GoogleFonts.poppins(
            fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.poppins(
            fontSize: 10, color: Colors.white.withOpacity(0.8))),
      ]),
    );
  }

  // ─── Section label ─────────────────────────────────────────────────────────

  Widget _sectionLabel(String title, IconData icon, Color color) {
    return Row(children: [
      Icon(icon, size: 16, color: color),
      const SizedBox(width: 8),
      Text(title, style: GoogleFonts.poppins(
          fontSize: 14, fontWeight: FontWeight.w700,
          color: AppColors.textDark)),
    ]);
  }

  // ─── Document Card ─────────────────────────────────────────────────────────

  Widget _buildDocCard(DocumentItem doc) {
    final isUploaded = doc.status == DocStatus.uploaded;
    final isDeleting = doc.status == DocStatus.deleting;
    final isUploading = doc.status == DocStatus.uploading;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PremiumCard(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            // Icon
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: _statusBg(doc),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(children: [
                Center(child: isDeleting
                    ? SizedBox(width: 22, height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(AppColors.error)))
                    : Icon(isUploaded ? Icons.check_circle_rounded : doc.icon,
                    color: _iconColor(doc), size: 24)),
                if (isUploading)
                  Positioned.fill(child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(doc.color),
                  )),
              ]),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(doc.label,
                    style: GoogleFonts.poppins(
                        fontSize: 14, fontWeight: FontWeight.w700,
                        color: AppColors.textDark))),
                if (doc.required && !isUploaded)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('Required',
                        style: GoogleFonts.poppins(
                            fontSize: 9, fontWeight: FontWeight.w700,
                            color: AppColors.error)),
                  ),
                if (isUploaded)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('Uploaded',
                        style: GoogleFonts.poppins(
                            fontSize: 9, fontWeight: FontWeight.w700,
                            color: AppColors.success)),
                  ),
              ]),
              const SizedBox(height: 3),

              if (isUploaded && doc.uploadedFileName != null)
                Text(doc.uploadedFileName!,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: AppColors.success,
                        fontWeight: FontWeight.w500))
              else if (doc.status == DocStatus.failed)
                Text(doc.errorMsg ?? 'Upload failed. Tap to retry.',
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: AppColors.error))
              else if (isUploading)
                  Text('Uploading...',
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: doc.color,
                          fontWeight: FontWeight.w500))
                else if (isDeleting)
                    Text('Deleting...',
                        style: GoogleFonts.poppins(
                            fontSize: 11, color: AppColors.error,
                            fontWeight: FontWeight.w500))
                  else
                    Text(doc.description,
                        style: GoogleFonts.poppins(
                            fontSize: 11, color: AppColors.textLight)),

              // Upload date
              if (isUploaded && doc.uploadedAt != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(_fmtDate(doc.uploadedAt!),
                      style: GoogleFonts.poppins(
                          fontSize: 10, color: AppColors.textLight)),
                ),
            ])),
          ]),

          // Action buttons row (only when uploaded or not uploaded)
          if (!isUploading && !isDeleting) ...[
            const SizedBox(height: 12),
            if (isUploaded)
              Row(children: [
                // View
                Expanded(child: _actionBtn(
                  label: 'View',
                  icon: Icons.visibility_rounded,
                  color: doc.color,
                  onTap: () => _viewDoc(doc),
                )),
                const SizedBox(width: 8),
                // Re-upload
                Expanded(child: _actionBtn(
                  label: 'Re-upload',
                  icon: Icons.upload_rounded,
                  color: AppColors.primary,
                  onTap: () => _pickAndUpload(doc),
                )),
                const SizedBox(width: 8),
                // Delete
                _iconActionBtn(
                  icon: Icons.delete_outline_rounded,
                  color: AppColors.error,
                  onTap: () => _deleteDoc(doc),
                ),
              ])
            else
              SizedBox(
                width: double.infinity,
                child: _uploadBtn(doc),
              ),
          ],
        ]),
      ),
    );
  }

  Widget _actionBtn({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(label, style: GoogleFonts.poppins(
              fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ]),
      ),
    );
  }

  Widget _iconActionBtn({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }

  Widget _uploadBtn(DocumentItem doc) {
    final isFailed = doc.status == DocStatus.failed;
    return GestureDetector(
      onTap: () => _pickAndUpload(doc),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          gradient: isFailed
              ? const LinearGradient(
              colors: [AppColors.error, AppColors.errorLight],
              begin: Alignment.topLeft, end: Alignment.bottomRight)
              : AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [BoxShadow(
            color: (isFailed ? AppColors.error : AppColors.primary)
                .withOpacity(0.3),
            blurRadius: 8, offset: const Offset(0, 3),
          )],
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(isFailed ? Icons.refresh_rounded : Icons.upload_rounded,
              size: 15, color: Colors.white),
          const SizedBox(width: 6),
          Text(isFailed ? 'Retry Upload' : 'Upload Document',
              style: GoogleFonts.poppins(
                  fontSize: 13, fontWeight: FontWeight.w700,
                  color: Colors.white)),
        ]),
      ),
    );
  }

  // ─── Info Note ─────────────────────────────────────────────────────────────

  Widget _buildInfoNote() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.info_outline_rounded, color: AppColors.warning, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Document Guidelines',
              style: GoogleFonts.poppins(
                  fontSize: 13, fontWeight: FontWeight.w700,
                  color: AppColors.textDark)),
          const SizedBox(height: 6),
          ...['Accepted formats: JPG, PNG, PDF',
            'Max file size: 5 MB per document',
            'Documents must be clear and readable',
            'All required docs needed for verification',
          ].map((t) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(margin: const EdgeInsets.only(top: 6),
                  width: 4, height: 4,
                  decoration: BoxDecoration(
                      color: AppColors.warning, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Expanded(child: Text(t, style: GoogleFonts.poppins(
                  fontSize: 11, color: AppColors.textMid, height: 1.5))),
            ]),
          )),
        ])),
      ]),
    );
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  String _fmtDate(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      const m = ['Jan','Feb','Mar','Apr','May','Jun',
        'Jul','Aug','Sep','Oct','Nov','Dec'];
      return 'Uploaded ${dt.day} ${m[dt.month - 1]} ${dt.year}';
    } catch (_) { return ''; }
  }

  Color _statusBg(DocumentItem doc) {
    switch (doc.status) {
      case DocStatus.uploaded: return AppColors.success.withOpacity(0.1);
      case DocStatus.failed: return AppColors.error.withOpacity(0.1);
      case DocStatus.deleting: return AppColors.error.withOpacity(0.06);
      default: return doc.color.withOpacity(0.1);
    }
  }

  Color _iconColor(DocumentItem doc) {
    switch (doc.status) {
      case DocStatus.uploaded: return AppColors.success;
      case DocStatus.failed: return AppColors.error;
      case DocStatus.deleting: return AppColors.error;
      default: return doc.color;
    }
  }
}

// ─── Shimmer ─────────────────────────────────────────────────────────────────

class _ShimmerBox extends StatefulWidget {
  final double height;
  final double radius;
  const _ShimmerBox({required this.height, required this.radius});
  @override State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  @override void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400))..repeat();
    _anim = Tween<double>(begin: -1.5, end: 2.5)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.radius),
          gradient: LinearGradient(
            begin: Alignment(_anim.value - 1, 0),
            end: Alignment(_anim.value, 0),
            colors: const [AppColors.neutralGreyLight, AppColors.background, AppColors.neutralGreyLight],
          ),
        ),
      ),
    );
  }
}