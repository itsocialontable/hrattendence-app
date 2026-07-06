// Models for the Employee Reviews & Reports endpoints:
//   GET /api/reviews/employee/:userId
//   GET /api/reviews/avg-rating/:userId
//   GET /api/reviews/attendance-rate/:userId
//   GET /api/reviews/graph/:userId
//   GET /api/reviews/monthly-summary/:userId
//
// Backend field names for these endpoints weren't fully specified, so every
// parser below is defensive: it checks several likely key spellings and
// falls back to sane defaults instead of throwing, so the UI never crashes
// on an unexpected shape — it just shows 0 / empty instead.

double _asDouble(dynamic v, [double fallback = 0]) {
  if (v == null) return fallback;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? fallback;
  return fallback;
}

int _asInt(dynamic v, [int fallback = 0]) {
  if (v == null) return fallback;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? fallback;
  return fallback;
}

String _asString(dynamic v, [String fallback = '']) {
  if (v == null) return fallback;
  return v.toString();
}

/// Unwraps common envelope shapes like {data: {...}} / {result: {...}}.
dynamic _unwrap(dynamic json) {
  if (json is Map<String, dynamic>) {
    for (final key in ['data', 'result', 'review', 'stats']) {
      if (json[key] != null) return json[key];
    }
  }
  return json;
}

/// GET /api/reviews/employee/:userId
/// A single review left for the employee (there can be several, so the API
/// call returns a List<ReviewItem>).
class ReviewItem {
  final String id;
  final String reviewerName;
  final double rating; // out of 5
  final String comment;
  final String category;
  final DateTime? date;

  ReviewItem({
    required this.id,
    required this.reviewerName,
    required this.rating,
    required this.comment,
    required this.category,
    required this.date,
  });

  factory ReviewItem.fromJson(Map<String, dynamic> json) {
    return ReviewItem(
      id: _asString(json['_id'] ?? json['id']),
      reviewerName: _asString(
        json['reviewerName'] ??
            json['reviewer'] ??
            json['reviewedBy'] ??
            json['managerName'],
        'Manager',
      ),
      rating: _asDouble(json['rating'] ?? json['score'] ?? json['stars']),
      comment: _asString(
        json['comment'] ?? json['feedback'] ?? json['remarks'] ?? json['note'],
      ),
      category: _asString(
        json['category'] ?? json['type'] ?? json['title'],
        'General',
      ),
      date: DateTime.tryParse(
        _asString(json['date'] ?? json['createdAt'] ?? json['reviewDate']),
      ),
    );
  }

  static List<ReviewItem> listFromJson(dynamic body) {
    final unwrapped = _unwrap(body);
    final list = unwrapped is List
        ? unwrapped
        : (unwrapped is Map<String, dynamic>
            ? (unwrapped['reviews'] ?? unwrapped['items'] ?? [])
            : []);
    return (list as List)
        .whereType<Map>()
        .map((e) => ReviewItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}

/// GET /api/reviews/avg-rating/:userId
class AvgRatingData {
  final double avgRating; // out of 5
  final int totalReviews;
  final double changePercent; // e.g. +4.2 vs previous period, may be 0

  AvgRatingData({
    required this.avgRating,
    required this.totalReviews,
    required this.changePercent,
  });

  factory AvgRatingData.fromJson(dynamic body) {
    final json = _unwrap(body);
    if (json is! Map<String, dynamic>) {
      return AvgRatingData(avgRating: 0, totalReviews: 0, changePercent: 0);
    }
    return AvgRatingData(
      avgRating: _asDouble(
        json['avgRating'] ?? json['averageRating'] ?? json['rating'] ?? json['average'],
      ),
      totalReviews: _asInt(
        json['totalReviews'] ?? json['reviewCount'] ?? json['count'],
      ),
      changePercent: _asDouble(
        json['changePercent'] ?? json['change'] ?? json['trend'],
      ),
    );
  }
}

/// GET /api/reviews/attendance-rate/:userId
class AttendanceRateData {
  final double attendanceRate; // 0-100
  final int presentDays;
  final int totalDays;
  final int lateDays;
  final int absentDays;

  AttendanceRateData({
    required this.attendanceRate,
    required this.presentDays,
    required this.totalDays,
    required this.lateDays,
    required this.absentDays,
  });

  factory AttendanceRateData.fromJson(dynamic body) {
    final json = _unwrap(body);
    if (json is! Map<String, dynamic>) {
      return AttendanceRateData(
        attendanceRate: 0,
        presentDays: 0,
        totalDays: 0,
        lateDays: 0,
        absentDays: 0,
      );
    }
    // Some backends send 0-1 fractions instead of 0-100 percentages.
    double rate = _asDouble(
      json['attendanceRate'] ?? json['rate'] ?? json['percentage'] ?? json['percent'],
    );
    if (rate <= 1.0) rate *= 100;
    return AttendanceRateData(
      attendanceRate: rate,
      presentDays: _asInt(json['presentDays'] ?? json['present']),
      totalDays: _asInt(json['totalDays'] ?? json['total']),
      lateDays: _asInt(json['lateDays'] ?? json['late']),
      absentDays: _asInt(json['absentDays'] ?? json['absent']),
    );
  }
}

/// A single point on the performance/attendance trend graph.
class GraphPoint {
  final String label;
  final double value;

  GraphPoint({required this.label, required this.value});

  factory GraphPoint.fromJson(Map<String, dynamic> json) {
    return GraphPoint(
      label: _asString(
        json['label'] ?? json['month'] ?? json['week'] ?? json['day'] ?? json['date'],
      ),
      value: _asDouble(json['value'] ?? json['rating'] ?? json['score'] ?? json['attendanceRate']),
    );
  }
}

/// GET /api/reviews/graph/:userId
class GraphData {
  final List<GraphPoint> points;

  GraphData({required this.points});

  factory GraphData.fromJson(dynamic body) {
    final unwrapped = _unwrap(body);
    List list;
    if (unwrapped is List) {
      list = unwrapped;
    } else if (unwrapped is Map<String, dynamic>) {
      list = (unwrapped['points'] ?? unwrapped['graph'] ?? unwrapped['series'] ?? []) as List;
    } else {
      list = [];
    }
    return GraphData(
      points: list
          .whereType<Map>()
          .map((e) => GraphPoint.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

/// A single month's rolled-up performance summary.
class MonthlySummaryItem {
  final String month;
  final double avgRating;
  final double attendanceRate;
  final int totalReviews;

  MonthlySummaryItem({
    required this.month,
    required this.avgRating,
    required this.attendanceRate,
    required this.totalReviews,
  });

  factory MonthlySummaryItem.fromJson(Map<String, dynamic> json) {
    double rate = _asDouble(json['attendanceRate'] ?? json['attendance']);
    if (rate <= 1.0 && rate > 0) rate *= 100;
    return MonthlySummaryItem(
      month: _asString(json['month'] ?? json['label'] ?? json['period'], '-'),
      avgRating: _asDouble(json['avgRating'] ?? json['rating'] ?? json['score']),
      attendanceRate: rate,
      totalReviews: _asInt(json['totalReviews'] ?? json['reviewCount'] ?? json['count']),
    );
  }
}

/// GET /api/reviews/monthly-summary/:userId
class MonthlySummaryData {
  final List<MonthlySummaryItem> months;

  MonthlySummaryData({required this.months});

  factory MonthlySummaryData.fromJson(dynamic body) {
    final unwrapped = _unwrap(body);
    List list;
    if (unwrapped is List) {
      list = unwrapped;
    } else if (unwrapped is Map<String, dynamic>) {
      list = (unwrapped['months'] ?? unwrapped['summary'] ?? unwrapped['items'] ?? []) as List;
    } else {
      list = [];
    }
    return MonthlySummaryData(
      months: list
          .whereType<Map>()
          .map((e) => MonthlySummaryItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

/// Bundle of everything the Reports screen needs, fetched together.
class EmployeeReportsBundle {
  final List<ReviewItem> reviews;
  final AvgRatingData avgRating;
  final AttendanceRateData attendanceRate;
  final GraphData graph;
  final MonthlySummaryData monthlySummary;

  EmployeeReportsBundle({
    required this.reviews,
    required this.avgRating,
    required this.attendanceRate,
    required this.graph,
    required this.monthlySummary,
  });
}
