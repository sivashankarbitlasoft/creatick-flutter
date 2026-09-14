import 'dart:convert';
import 'package:http/http.dart' as http;

import 'constants.dart';
import 'api_exception.dart';
import '../models/user_model.dart';
import '../models/ticket_model.dart';

class ApiService {
  static final Uri _base = Uri.parse(ApiConstants.baseUrl);

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
      };

  /// Reads either a JSON list or a JSON object from the response body,
  /// or throws an ApiException with the backend's error detail on failure.
  static dynamic _decodeOrThrow(http.Response response) {
    final decoded = response.body.isNotEmpty ? jsonDecode(response.body) : null;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }
    final detail = (decoded is Map && decoded['detail'] != null)
        ? decoded['detail'].toString()
        : 'Something went wrong (${response.statusCode})';
    throw ApiException(detail);
  }

  // ---------- AUTH ----------

  static Future<AppUser> login(String email, String password) async {
    final response = await http.post(
      _base.replace(path: '/auth/login'),
      headers: _headers,
      body: jsonEncode({'email': email, 'password': password}),
    );
    final data = _decodeOrThrow(response);
    return AppUser.fromJson(data as Map<String, dynamic>);
  }

  static Future<AppUser> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final response = await http.post(
      _base.replace(path: '/auth/register'),
      headers: _headers,
      body: jsonEncode({
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
      }),
    );
    final data = _decodeOrThrow(response);
    return AppUser.fromJson(data as Map<String, dynamic>);
  }

  // ---------- USER PROFILE ----------

  static Future<AppUser> updateProfile({
    required int userId,
    String? name,
    String? phone,
    String? password,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (phone != null) body['phone'] = phone;
    if (password != null && password.isNotEmpty) body['password'] = password;

    final response = await http.put(
      _base.replace(path: '/users/$userId'),
      headers: _headers,
      body: jsonEncode(body),
    );
    final data = _decodeOrThrow(response);
    return AppUser.fromJson(data as Map<String, dynamic>);
  }

  // ---------- TICKETS ----------

  /// Creates ticket(s). If appType == 'both', the backend returns 2 tickets.
  static Future<List<Ticket>> createTicket({
    required String operatorName,
    required String subDomain,
    String? website,
    String? description,
    List<String?> imageUrls = const [null, null, null, null, null, null],
    required String appType, // 'android' | 'ios' | 'both'
    required int createdBy,
  }) async {
    final body = {
      'operator_name': operatorName,
      'sub_domain': subDomain,
      'website': website,
      'description': description,
      'image_url_1': imageUrls.isNotEmpty ? imageUrls[0] : null,
      'image_url_2': imageUrls.length > 1 ? imageUrls[1] : null,
      'image_url_3': imageUrls.length > 2 ? imageUrls[2] : null,
      'image_url_4': imageUrls.length > 3 ? imageUrls[3] : null,
      'image_url_5': imageUrls.length > 4 ? imageUrls[4] : null,
      'image_url_6': imageUrls.length > 5 ? imageUrls[5] : null,
      'app_type': appType,
      'created_by': createdBy,
    };
    final response = await http.post(
      _base.replace(path: '/tickets'),
      headers: _headers,
      body: jsonEncode(body),
    );
    final data = _decodeOrThrow(response) as List;
    return data.map((t) => Ticket.fromJson(t as Map<String, dynamic>)).toList();
  }

  /// Tickets created by one user (for the Dashboard tab).
  static Future<List<Ticket>> getMyTickets(int userId) async {
    final response = await http.get(
      _base.replace(path: '/tickets', queryParameters: {'user_id': '$userId'}),
      headers: _headers,
    );
    final data = _decodeOrThrow(response) as List;
    return data.map((t) => Ticket.fromJson(t as Map<String, dynamic>)).toList();
  }

  static Future<Ticket> getTicket(String ticketNumber) async {
    final response = await http.get(
      _base.replace(path: '/tickets/$ticketNumber'),
      headers: _headers,
    );
    final data = _decodeOrThrow(response);
    return Ticket.fromJson(data as Map<String, dynamic>);
  }

  /// Full ticket edit (used by the update page).
  static Future<Ticket> updateTicket({
    required String ticketNumber,
    String? operatorName,
    String? website,
    String? description,
    List<String?>? imageUrls,
    String? status,
  }) async {
    final body = <String, dynamic>{};
    if (operatorName != null) body['operator_name'] = operatorName;
    if (website != null) body['website'] = website;
    if (description != null) body['description'] = description;
    if (imageUrls != null) {
      for (var i = 0; i < imageUrls.length && i < 6; i++) {
        body['image_url_${i + 1}'] = imageUrls[i];
      }
    }
    if (status != null) body['status'] = status;

    final response = await http.put(
      _base.replace(path: '/tickets/$ticketNumber'),
      headers: _headers,
      body: jsonEncode(body),
    );
    final data = _decodeOrThrow(response);
    return Ticket.fromJson(data as Map<String, dynamic>);
  }
}
