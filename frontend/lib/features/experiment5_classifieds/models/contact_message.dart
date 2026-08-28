class ContactMessage {
  final String id;
  final String listingId;
  final String listingTitle;
  final String name;
  final String message;
  final String senderId;
  final String recipientId;
  final String? createdAt;

  const ContactMessage({
    required this.id,
    required this.listingId,
    required this.listingTitle,
    required this.name,
    required this.message,
    required this.senderId,
    required this.recipientId,
    this.createdAt,
  });

  bool isIncoming(String currentUserId) => senderId != currentUserId;

  factory ContactMessage.fromJson(Map<String, dynamic> json) => ContactMessage(
        id: (json['id'] ?? '').toString(),
        listingId: (json['listing_id'] ?? '').toString(),
        listingTitle: (json['listing_title'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
        message: (json['message'] ?? '').toString(),
        senderId: (json['sender_id'] ?? '').toString(),
        recipientId: (json['recipient_id'] ?? '').toString(),
        createdAt: json['created_at']?.toString(),
      );
}