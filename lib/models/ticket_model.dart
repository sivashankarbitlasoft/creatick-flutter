class Ticket {
  final int id;
  final String? ticketNumber;
  final String operatorName;
  final String subDomain;
  final String? website;
  final String? description;
  final String? imageUrl1;
  final String? imageUrl2;
  final String? imageUrl3;
  final String? imageUrl4;
  final String? imageUrl5;
  final String? imageUrl6;
  final String appType; // "android" or "ios"
  final String status; // "to-do" | "in-progress" | "dev-done" | "closed"
  final int? createdBy;
  final String createdAt;
  final String updatedAt;

  Ticket({
    required this.id,
    required this.ticketNumber,
    required this.operatorName,
    required this.subDomain,
    this.website,
    this.description,
    this.imageUrl1,
    this.imageUrl2,
    this.imageUrl3,
    this.imageUrl4,
    this.imageUrl5,
    this.imageUrl6,
    required this.appType,
    required this.status,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['id'] as int,
      ticketNumber: json['ticket_number'] as String?,
      operatorName: json['operator_name'] as String,
      subDomain: json['sub_domain'] as String,
      website: json['website'] as String?,
      description: json['description'] as String?,
      imageUrl1: json['image_url_1'] as String?,
      imageUrl2: json['image_url_2'] as String?,
      imageUrl3: json['image_url_3'] as String?,
      imageUrl4: json['image_url_4'] as String?,
      imageUrl5: json['image_url_5'] as String?,
      imageUrl6: json['image_url_6'] as String?,
      appType: json['app_type'] as String,
      status: json['status'] as String,
      createdBy: json['created_by'] as int?,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );
  }

  /// All non-empty image URLs, in order - handy for a gallery view.
  List<String> get imageUrls {
    return [imageUrl1, imageUrl2, imageUrl3, imageUrl4, imageUrl5, imageUrl6]
        .whereType<String>()
        .where((url) => url.trim().isNotEmpty)
        .toList();
  }
}

/// Allowed ticket statuses, in the order they appear in a dropdown.
const List<String> kTicketStatuses = [
  'to-do',
  'in-progress',
  'dev-done',
  'closed',
];
