import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

// ─── Model ───────────────────────────────────────────────────────────────────

class UploadedDoc {
  final String docType;
  final String fileName;
  final String fileType;
  final String uploadedAt;

  UploadedDoc({
    required this.docType,
    required this.fileName,
    required this.fileType,
    required this.uploadedAt,
  });

  factory UploadedDoc.fromJson(Map<String, dynamic> j) {
    return UploadedDoc(
      docType: j['docType'] ?? j['doc_type'] ?? j['type'] ?? '',
      fileName: j['fileName'] ?? j['file_name'] ?? j['name'] ?? '',
      fileType: j['fileType'] ?? j['file_type'] ?? j['mimeType'] ?? '',
      uploadedAt: j['uploadedAt'] ?? j['uploaded_at'] ?? j['createdAt'] ?? j['created_at'] ?? '',
    );
  }
}

// ─── Screen ──────────────────────────────────────────────────────────────────

class MyDocumentsScreen extends StatefulWidget {
  const MyDocumentsScreen({super.key});

  @override
  State<MyDocumentsScreen> createState() => _MyDocumentsScreenState();
}

class _MyDocumentsScreenState extends State<MyDocumentsScreen>
    with SingleTickerProviderStateMixin {

  // static const String _baseUrl =
  //     'https://whacking-dispute-agility.ngrok-free.dev';

  bool _loading = true;
  String? _error;
  List<UploadedDoc> _docs = [];
  late AnimationController _animCtrl;

  // Friendly labels & icons per docType
  static const Map<String, Map<String, dynamic>> _meta = {
    'aadhar':         {'label': 'Aadhar Card',          'icon': Icons.fingerprint_rounded,       'color': AppColors.primary},
    'pan':            {'label': 'PAN Card',              'icon': Icons.credit_card_rounded,       'color': AppColors.secondary},
    'passbook':       {'label': 'Bank Account Proof',   'icon': Icons.account_balance_rounded,   'color': AppColors.success},
    'marksheet':{'label': 'Graduation Marksheet', 'icon': Icons.school_rounded,            'color': AppColors.warning},
    'resume':              {'label': 'Resume / CV',           'icon': Icons.description_rounded,       'color': AppColors.accent},
    'experience':   {'label': 'Experience Letter',    'icon': Icons.work_history_rounded,      'color': AppColors.primaryLight},
  };

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500))
      ..forward();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchDocs());
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  String get _userId => context.read<AuthProvider>().user?.id ?? '';
  String? get _token => context.read<AuthProvider>().token;

  // ─── GET ─────────────────────────────────────────────────────────────────

  Future<void> _fetchDocs() async {
    setState(() { _loading = true; _error = null; });
    try {
      debugPrint('📁 [MyDocuments] GET /api/documents/$_userId');
      debugPrint('📁 [MyDocuments] Token: $_token');

      final res = await http.get(
        Uri.parse('${ApiService.baseUrl}/api/documents/$_userId'),
        headers: {
          'Authorization': 'Bearer $_token',
          // 'ngrok-skip-browser-warning': 'true',
        },
      ).timeout(const Duration(seconds: 30));

      log('📥 GET docs ${res.statusCode}: ${res.body}');
      debugPrint('📁 [MyDocuments] FETCH STATUS: ${res.statusCode}');
      debugPrint('📁 [MyDocuments] FETCH BODY: ${res.body}');

      if (res.statusCode == 200) {
        final raw = jsonDecode(res.body);
        List<dynamic> list;
        if (raw is List) {
          list = raw;
        } else if (raw is Map) {
          list = raw['documents'] ?? raw['data'] ?? raw['docs'] ?? [];
        } else {
          list = [];
        }
        setState(() => _docs = list.map((e) => UploadedDoc.fromJson(e)).toList());
        debugPrint('📁 [MyDocuments] ✅ Loaded ${_docs.length} document(s) successfully');
      } else {
        setState(() => _error = 'Server error (${res.statusCode})');
        debugPrint('📁 [MyDocuments] ❌ Fetch failed — status: ${res.statusCode}, body: ${res.body}');
      }
    } catch (e) {
      log('❌ Fetch error: $e');
      debugPrint('📁 [MyDocuments] ❌ Fetch EXCEPTION: $e');
      setState(() => _error = 'Could not load documents. Pull to refresh.');
    } finally {
      setState(() => _loading = false);
    }
  }

  // ─── VIEW ─────────────────────────────────────────────────────────────────

  Future<void> _viewDoc(UploadedDoc doc) async {
    _showLoadingDialog(doc);
    try {
      final url = '${ApiService.baseUrl}/api/documents/$_userId/${doc.docType}/view';
      log('👁 View: $url');
      debugPrint('📁 [MyDocuments] VIEW GET: $url');
      debugPrint('📁 [MyDocuments] Token: $_token');

      final res = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $_token',
          // 'ngrok-skip-browser-warning': 'true',
        },
      ).timeout(const Duration(seconds: 30));

      if (mounted) Navigator.pop(context);

      debugPrint('📁 [MyDocuments] VIEW STATUS: ${res.statusCode}');

      if (res.statusCode == 200) {
        final ct = res.headers['content-type'] ?? '';
        debugPrint('📁 [MyDocuments] ✅ VIEW success — ${res.bodyBytes.length} bytes, type: $ct');

        if (ct.contains('json')) {
          // Server wrapped the file inside a JSON object (e.g. base64 fileData)
          debugPrint('📁 [MyDocuments] VIEW raw JSON body: ${res.body}');
          try {
            final json = jsonDecode(res.body) as Map<String, dynamic>;
            final base64Str = json['fileData'] ?? json['file_data'] ??
                json['data'] ?? json['base64'] ?? json['content'];
            final realType = (json['fileType'] ?? json['file_type'] ??
                json['mimeType'] ?? json['contentType'] ?? '') as String;

            if (base64Str == null) {
              debugPrint('📁 [MyDocuments] ❌ No file data field found in JSON keys: ${json.keys}');
              _snack('Server did not return file data', AppColors.error);
              return;
            }

            final cleanBase64 = (base64Str as String).contains(',')
                ? base64Str.split(',').last
                : base64Str;
            final decodedBytes = base64Decode(cleanBase64);
            debugPrint('📁 [MyDocuments] ✅ Decoded base64 → ${decodedBytes.length} bytes, type: $realType');
            _openViewer(doc, decodedBytes, realType);
          } catch (e) {
            debugPrint('📁 [MyDocuments] ❌ JSON file parse error: $e');
            _snack('Could not parse document data', AppColors.error);
          }
        } else {
          _openViewer(doc, res.bodyBytes, ct);
        }
      } else {
        debugPrint('📁 [MyDocuments] ❌ VIEW failed — status: ${res.statusCode}, body: ${res.body}');
        _snack('Could not load preview', AppColors.error);
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      debugPrint('📁 [MyDocuments] ❌ VIEW EXCEPTION: $e');
      _snack('Failed to load document', AppColors.error);
    }
  }

  void _showLoadingDialog(UploadedDoc doc) {
    final m = _meta[doc.docType];
    final color = (m?['color'] as Color?) ?? AppColors.primary;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(20)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(color)),
            const SizedBox(height: 16),
            Text('Loading preview...',
                style: GoogleFonts.poppins(
                    fontSize: 13, color: AppColors.textMid)),
          ]),
        ),
      ),
    );
  }

  void _openViewer(UploadedDoc doc, Uint8List bytes, String ct) {
    final m = _meta[doc.docType];
    final color = (m?['color'] as Color?) ?? AppColors.primary;
    final icon = (m?['icon'] as IconData?) ?? Icons.insert_drive_file_rounded;
    final label = (m?['label'] as String?) ?? doc.docType;
    final isImage = ct.contains('image');

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
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
              child: Column(children: [
                Container(width: 40, height: 4,
                    decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 14),
                Row(children: [
                  Container(width: 40, height: 40,
                      decoration: BoxDecoration(
                          color: color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12)),
                      child: Icon(icon, color: color, size: 20)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(label, style: GoogleFonts.poppins(
                        fontSize: 15, fontWeight: FontWeight.w700,
                        color: Colors.white)),
                    Text(doc.fileName, maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                            fontSize: 11, color: Colors.white54)),
                  ])),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(width: 34, height: 34,
                        decoration: BoxDecoration(
                            color: Colors.white12,
                            borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.close_rounded,
                            color: Colors.white, size: 18)),
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
                    child: Image.memory(bytes, fit: BoxFit.contain),
                  ))
                  : Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.picture_as_pdf_rounded,
                    color: AppColors.error, size: 64),
                const SizedBox(height: 14),
                Text('PDF Document', style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w600,
                    color: Colors.white)),
                const SizedBox(height: 6),
                Text(doc.fileName, style: GoogleFonts.poppins(
                    fontSize: 12, color: Colors.white54)),
              ])),
            ),
          ]),
        ),
      ),
    );
  }

  // ─── DELETE ───────────────────────────────────────────────────────────────

  Future<void> _deleteDoc(UploadedDoc doc) async {
    final m = _meta[doc.docType];
    final label = (m?['label'] as String?) ?? doc.docType;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 64, height: 64,
                decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    shape: BoxShape.circle),
                child: const Icon(Icons.delete_outline_rounded,
                    color: AppColors.error, size: 30)),
            const SizedBox(height: 16),
            Text('Delete Document?', style: GoogleFonts.poppins(
                fontSize: 17, fontWeight: FontWeight.w700,
                color: AppColors.textDark)),
            const SizedBox(height: 8),
            Text('Are you sure you want to delete "$label"?\nThis cannot be undone.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 13, color: AppColors.textMid, height: 1.5)),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(child: GestureDetector(
                onTap: () => Navigator.pop(context, false),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(12)),
                  child: Center(child: Text('Cancel', style: GoogleFonts.poppins(
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
                          blurRadius: 8, offset: const Offset(0, 3))]),
                  child: Center(child: Text('Delete', style: GoogleFonts.poppins(
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

    // Optimistic remove
    setState(() => _docs.removeWhere((d) => d.docType == doc.docType));

    try {
      final url = '${ApiService.baseUrl}/api/documents/$_userId/${doc.docType}';
      log('🗑 DELETE: $url');
      debugPrint('📁 [MyDocuments] DELETE: $url');
      debugPrint('📁 [MyDocuments] Token: $_token');

      final res = await http.delete(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $_token',
          // 'ngrok-skip-browser-warning': 'true',
        },
      ).timeout(const Duration(seconds: 30));

      log('📥 DELETE ${res.statusCode}');
      debugPrint('📁 [MyDocuments] DELETE STATUS: ${res.statusCode}');
      debugPrint('📁 [MyDocuments] DELETE BODY: ${res.body}');

      if (res.statusCode == 200 || res.statusCode == 204) {
        debugPrint('📁 [MyDocuments] ✅ DELETE success — ${doc.docType}');
        _snack('$label deleted', AppColors.success);
      } else {
        // Revert
        setState(() => _docs.add(doc));
        debugPrint('📁 [MyDocuments] ❌ DELETE failed — status: ${res.statusCode}, body: ${res.body}');
        _snack('Delete failed', AppColors.error);
      }
    } catch (e) {
      setState(() => _docs.add(doc));
      debugPrint('📁 [MyDocuments] ❌ DELETE EXCEPTION: $e');
      _snack('Delete failed: network error', AppColors.error);
    }
  }

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600, color: Colors.white)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.all(16),
    ));
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('My Documents', style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700, color: AppColors.textDark)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.refresh_rounded,
                  color: AppColors.primary, size: 18),
            ),
            onPressed: _fetchDocs,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? _buildShimmer()
            : RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _fetchDocs,
          child: _error != null
              ? _buildError()
              : _docs.isEmpty
              ? _buildEmpty()
              : _buildList(),
        ),
      ),
    );
  }

  // ─── List ─────────────────────────────────────────────────────────────────

  Widget _buildList() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── Summary banner ──
        _buildSummaryBanner(),
        const SizedBox(height: 24),

        // ── Doc count label ──
        Row(children: [
          const Icon(Icons.folder_open_rounded,
              size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Text('${_docs.length} Document${_docs.length == 1 ? '' : 's'} Uploaded',
              style: GoogleFonts.poppins(
                  fontSize: 14, fontWeight: FontWeight.w700,
                  color: AppColors.textDark)),
        ]),
        const SizedBox(height: 12),

        // ── Cards ──
        ..._docs.asMap().entries.map((e) {
          final delay = e.key * 80;
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: 400 + delay),
            curve: Curves.easeOut,
            builder: (_, v, child) => Opacity(
              opacity: v,
              child: Transform.translate(
                  offset: Offset(0, 20 * (1 - v)), child: child),
            ),
            child: _buildDocCard(e.value),
          );
        }),
      ]),
    );
  }

  // ─── Summary Banner ───────────────────────────────────────────────────────

  Widget _buildSummaryBanner() {
    final requiredTypes = {'aadhar_card', 'pan_card', 'bank_passbook',
      'graduation_marksheet'};
    final uploadedTypes = _docs.map((d) => d.docType).toSet();
    final doneReq = uploadedTypes.intersection(requiredTypes).length;
    final totalReq = requiredTypes.length;
    final allDone = doneReq == totalReq;
    final progress = _docs.length / 6.0;

    return PremiumCard(
      gradient: allDone ? AppColors.successGradient : AppColors.primaryGradient,
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 46, height: 46,
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14)),
              child: Icon(
                  allDone ? Icons.task_alt_rounded : Icons.folder_special_rounded,
                  color: Colors.white, size: 22)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(allDone ? 'All required docs uploaded!' : 'Document Status',
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w700,
                    color: Colors.white)),
            Text('$doneReq / $totalReq required docs uploaded',
                style: GoogleFonts.poppins(
                    fontSize: 12, color: Colors.white.withOpacity(0.8))),
          ])),
        ]),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: Colors.white.withOpacity(0.25),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 12),
        Row(children: [
          _pill('${_docs.length}', 'Uploaded'),
          const SizedBox(width: 10),
          _pill('$doneReq/$totalReq', 'Required'),
          const Spacer(),
          if (!allDone)
            Text('${totalReq - doneReq} required pending',
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
          borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(value, style: GoogleFonts.poppins(
            fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.poppins(
            fontSize: 10, color: Colors.white.withOpacity(0.8))),
      ]),
    );
  }

  // ─── Doc Card ─────────────────────────────────────────────────────────────

  Widget _buildDocCard(UploadedDoc doc) {
    final m = _meta[doc.docType];
    final color = (m?['color'] as Color?) ?? AppColors.primary;
    final icon = (m?['icon'] as IconData?) ?? Icons.insert_drive_file_rounded;
    final label = (m?['label'] as String?) ?? doc.docType;
    final isPdf = doc.fileType.contains('pdf') ||
        doc.fileName.toLowerCase().endsWith('.pdf');

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PremiumCard(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Top row
          Row(children: [
            // Icon
            Container(width: 54, height: 54,
                decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16)),
                child: Icon(icon, color: color, size: 26)),
            const SizedBox(width: 14),

            // Info
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: GoogleFonts.poppins(
                  fontSize: 15, fontWeight: FontWeight.w700,
                  color: AppColors.textDark)),
              const SizedBox(height: 3),
              Row(children: [
                Icon(isPdf ? Icons.picture_as_pdf_rounded
                    : Icons.image_rounded,
                    size: 12, color: AppColors.textLight),
                const SizedBox(width: 4),
                Expanded(child: Text(doc.fileName,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: AppColors.textLight))),
              ]),
              if (doc.uploadedAt.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(_fmtDate(doc.uploadedAt),
                    style: GoogleFonts.poppins(
                        fontSize: 10, color: AppColors.textLight)),
              ],
            ])),

            // Uploaded badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.check_circle_rounded,
                    size: 11, color: AppColors.success),
                const SizedBox(width: 4),
                Text('Uploaded', style: GoogleFonts.poppins(
                    fontSize: 10, fontWeight: FontWeight.w700,
                    color: AppColors.success)),
              ]),
            ),
          ]),

          const SizedBox(height: 14),
          Container(height: 1, color: AppColors.border),
          const SizedBox(height: 14),

          // Action buttons
          Row(children: [
            // View
            Expanded(child: GestureDetector(
              onTap: () => _viewDoc(doc),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withOpacity(0.7)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 8, offset: const Offset(0, 3))]),
                child: Row(mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.visibility_rounded,
                          size: 15, color: Colors.white),
                      const SizedBox(width: 6),
                      Text('View', style: GoogleFonts.poppins(
                          fontSize: 13, fontWeight: FontWeight.w700,
                          color: Colors.white)),
                    ]),
              ),
            )),
            const SizedBox(width: 10),

            // Delete
            GestureDetector(
              onTap: () => _deleteDoc(doc),
              child: Container(
                width: 46, height: 46,
                decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.error.withOpacity(0.25))),
                child: const Icon(Icons.delete_outline_rounded,
                    color: AppColors.error, size: 20),
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  // ─── Empty State ──────────────────────────────────────────────────────────

  Widget _buildEmpty() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 90, height: 90,
                decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    shape: BoxShape.circle),
                child: const Icon(Icons.folder_open_rounded,
                    color: AppColors.primary, size: 40)),
            const SizedBox(height: 20),
            Text('No Documents Yet', style: GoogleFonts.poppins(
                fontSize: 18, fontWeight: FontWeight.w700,
                color: AppColors.textDark)),
            const SizedBox(height: 8),
            Text('You haven\'t uploaded any documents.\nGo to profile to upload.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 13, color: AppColors.textLight, height: 1.5)),
            const SizedBox(height: 28),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 14),
                decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: AppShadow.strong),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.upload_file_rounded,
                      color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text('Upload Documents', style: GoogleFonts.poppins(
                      fontSize: 14, fontWeight: FontWeight.w700,
                      color: Colors.white)),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // ─── Error State ──────────────────────────────────────────────────────────

  Widget _buildError() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 80, height: 80,
                decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    shape: BoxShape.circle),
                child: const Icon(Icons.wifi_off_rounded,
                    color: AppColors.error, size: 36)),
            const SizedBox(height: 16),
            Text('Something went wrong', style: GoogleFonts.poppins(
                fontSize: 16, fontWeight: FontWeight.w700,
                color: AppColors.textDark)),
            const SizedBox(height: 8),
            Text(_error ?? '', textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 13, color: AppColors.textLight)),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _fetchDocs,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: AppShadow.strong),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.refresh_rounded,
                      color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Text('Retry', style: GoogleFonts.poppins(
                      fontSize: 14, fontWeight: FontWeight.w600,
                      color: Colors.white)),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // ─── Shimmer ──────────────────────────────────────────────────────────────

  Widget _buildShimmer() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      child: Column(children: [
        _Shimmer(height: 130, radius: 20),
        const SizedBox(height: 24),
        ...[1, 2, 3].map((_) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _Shimmer(height: 140, radius: 20),
        )),
      ]),
    );
  }

  String _fmtDate(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      const m = ['Jan','Feb','Mar','Apr','May','Jun',
        'Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${dt.day} ${m[dt.month - 1]} ${dt.year}';
    } catch (_) { return raw; }
  }
}

// ─── Shimmer widget ───────────────────────────────────────────────────────────

class _Shimmer extends StatefulWidget {
  final double height;
  final double radius;
  const _Shimmer({required this.height, required this.radius});
  @override State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _a;
  @override void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400))..repeat();
    _a = Tween<double>(begin: -1.5, end: 2.5)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => AnimatedBuilder(
    animation: _a,
    builder: (_, __) => Container(
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.radius),
        gradient: LinearGradient(
          begin: Alignment(_a.value - 1, 0),
          end: Alignment(_a.value, 0),
          colors: const [AppColors.neutralGreyLight, AppColors.background, AppColors.neutralGreyLight],
        ),
      ),
    ),
  );
}