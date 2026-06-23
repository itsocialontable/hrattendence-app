class LoginResponse {
  final String token;
  final UserData user;

  LoginResponse({
    required this.token,
    required this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json['token'] ?? '',
      user: UserData.fromJson(json['user'] ?? {}),
    );
  }
}

class UserData {
  final String id;
  final String name;
  final String username;
  final String role;
  final String dept;
  final int salary;
  final String email;
  final String joinDate;

  UserData({
    required this.id,
    required this.name,
    required this.username,
    required this.role,
    required this.dept,
    required this.salary,
    required this.email,
    required this.joinDate,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      username: json['username'] ?? '',
      role: json['role'] ?? '',
      dept: json['dept'] ?? '',
      salary: json['salary'] ?? 0,
      email: json['email'] ?? '',
      joinDate: json['joinDate'] ?? json['join_date'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'role': role,
      'dept': dept,
      'salary': salary,
      'email': email,
      'joinDate': joinDate,
    };
  }
}

class ProfileResponse {
  final List<UserProfile> users;

  ProfileResponse({required this.users});

  factory ProfileResponse.fromJson(List<dynamic> json) {
    return ProfileResponse(
      users: json.map((user) => UserProfile.fromJson(user)).toList(),
    );
  }
}

class UserProfile {
  final String id;
  final String name;
  final String username;
  final String role;
  final String dept;
  final int salary;
  final String email;
  final String joinDate;
  final String bankAccountNo;
  final String bankName;
  final String bankBranch;
  final String bankIfsc;
  final String aadharNo;
  final String panNo;

  UserProfile({
    required this.id,
    required this.name,
    required this.username,
    required this.role,
    required this.dept,
    required this.salary,
    required this.email,
    required this.joinDate,
    required this.bankAccountNo,
    required this.bankName,
    required this.bankBranch,
    required this.bankIfsc,
    required this.aadharNo,
    required this.panNo,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      username: json['username'] ?? '',
      role: json['role'] ?? '',
      dept: json['dept'] ?? '',
      salary: json['salary'] ?? 0,
      email: json['email'] ?? '',
      joinDate: json['join_date'] ?? '',
      bankAccountNo: json['bank_ac_no'] ?? '',
      bankName: json['bank_name'] ?? '',
      bankBranch: json['bank_branch'] ?? '',
      bankIfsc: json['bank_ifsc'] ?? '',
      aadharNo: json['aadhar_no'] ?? '',
      panNo: json['pan_no'] ?? '',
    );
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException({required this.message, this.statusCode});

  @override
  String toString() => message;
}
