// Models for the Admin Review endpoints:
//   POST   /api/reviews                   — submit / upsert review
//   PUT    /api/reviews/:id               — update review
//   DELETE /api/reviews/:id               — delete review
//   GET    /api/reviews/admin/all         — get all reviews by this admin

double _d(dynamic v, [double f = 0]) {
  if (v == null) return f;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? f;
  return f;
}

int _i(dynamic v, [int f = 0]) {
  if (v == null) return f;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? f;
  return f;
}

String _s(dynamic v, [String f = '']) => v == null ? f : v.toString();

/// A single review record as returned by GET /api/reviews/admin/all
class AdminReview {
  final String id;
  final String userId;
  final String employeeName;
  final String month;       // "YYYY-MM"
  final double rating;      // 1–5
  final String title;
  final String comment;
  final String category;    // default "overall"
  final bool isVisible;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AdminReview({
    required this.id,
    required this.userId,
    required this.employeeName,
    required this.month,
    required this.rating,
    required this.title,
    required this.comment,
    required this.category,
    required this.isVisible,
    this.createdAt,
    this.updatedAt,
  });

  factory AdminReview.fromJson(Map<String, dynamic> j) {
    // Unwrap common envelopes
    final data = (j['data'] ?? j['review'] ?? j) as Map<String, dynamic>;

    final userMap = data['user'] ?? data['employee'];
    String empName = '';
    if (userMap is Map) {
      empName = _s(userMap['name'] ?? userMap['fullName']);
    }
    if (empName.isEmpty) {
      empName = _s(data['employeeName'] ?? data['userName'] ?? data['name']??data['employee_name']);
    }

    return AdminReview(
      id: _s(data['_id'] ?? data['id']),
      userId: _s(data['user_id'] ?? data['userId'] ??
          (userMap is Map ? (userMap['_id'] ?? userMap['id']) : null)),
      employeeName: empName.isEmpty ? 'Employee' : empName,
      month: _s(data['month']),
      rating: _d(data['rating'] ?? data['score']),
      title: _s(data['title']),
      comment: _s(data['comment'] ?? data['feedback'] ?? data['remarks']),
      category: _s(data['category'], 'overall'),
      isVisible: (data['is_visible'] ?? data['isVisible'] ?? true) == true,
      createdAt: DateTime.tryParse(_s(data['createdAt'] ?? data['created_at'])),
      updatedAt: DateTime.tryParse(_s(data['updatedAt'] ?? data['updated_at'])),
    );
  }

  static List<AdminReview> listFromJson(dynamic body) {
    List raw = [];
    if (body is List) {
      raw = body;
    } else if (body is Map<String, dynamic>) {
      for (final k in ['data', 'reviews', 'items', 'result']) {
        if (body[k] is List) { raw = body[k]; break; }
      }
      if (raw.isEmpty && body.containsKey('_id')) raw = [body];
    }
    return raw
        .whereType<Map>()
        .map((e) => AdminReview.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  AdminReview copyWith({
    String? title,
    String? comment,
    String? category,
    double? rating,
    bool? isVisible,
  }) =>
      AdminReview(
        id: id,
        userId: userId,
        employeeName: employeeName,
        month: month,
        rating: rating ?? this.rating,
        title: title ?? this.title,
        comment: comment ?? this.comment,
        category: category ?? this.category,
        isVisible: isVisible ?? this.isVisible,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}

/// Input payload for POST /api/reviews
class AdminReviewInput {
  final String userId;
  final String month;       // "YYYY-MM"
  final double rating;
  final String? title;
  final String? comment;
  final String? category;

  const AdminReviewInput({
    required this.userId,
    required this.month,
    required this.rating,
    this.title,
    this.comment,
    this.category,
  });

  Map<String, dynamic> toJson() => {
    // NOTE: employee_id, employeeId, employee, user_id, and userId have all
    // been tried here — the backend returned the exact same
    // "dup key: { employee_id: null }" error for every variant. That rules
    // out a client-side field-naming issue: the backend isn't reading
    // employee_id from this request body at all (or a stale null-keyed
    // document already occupies the unique index for this month). This
    // needs to be fixed server-side — see the conversation for details.
    'employeeId': userId,
    'employee_id': userId,
    'user_id': userId,
    'month': month,
    'rating': rating,
    if (title != null && title!.isNotEmpty) 'title': title,
    if (comment != null && comment!.isNotEmpty) 'comment': comment,
    if (category != null && category!.isNotEmpty) 'category': category,
  };
}

/// Input payload for PUT /api/reviews/:id
class AdminReviewUpdateInput {
  final double rating;
  final String? title;
  final String? comment;
  final String? category;
  final bool? isVisible;

  const AdminReviewUpdateInput({
    required this.rating,
    this.title,
    this.comment,
    this.category,
    this.isVisible,
  });

  Map<String, dynamic> toJson() => {
    'rating': rating,
    if (title != null) 'title': title,
    if (comment != null) 'comment': comment,
    if (category != null) 'category': category,
    if (isVisible != null) 'is_visible': isVisible,
  };
}