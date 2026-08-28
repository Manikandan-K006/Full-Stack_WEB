import '../../../core/network/api_client.dart';
import '../models/contact_message.dart';
import '../models/favorite.dart';
import '../models/listing.dart';

class ClassifiedService {
  static Future<List<Listing>> listListings({
    String? search,
    String? category,
    String? condition,
    double? minPrice,
    double? maxPrice,
    String? location,
    String sort = 'created_at',
    String direction = 'desc',
  }) async {
    final data = await ApiClient.instance.get(
      '/api/listings',
      query: {
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (category != null && category != 'ALL') 'category': category,
        if (condition != null && condition != 'ALL') 'condition': condition,
        if (minPrice != null && minPrice >= 0) 'min_price': minPrice,
        if (maxPrice != null && maxPrice >= 0) 'max_price': maxPrice,
        if (location != null && location.trim().isNotEmpty) 'location': location.trim(),
        'sort': sort,
        'direction': direction,
      },
    );
    return (data as List)
        .map((e) => Listing.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<Listing> getListing(String id) async =>
      Listing.fromJson(await ApiClient.instance.get('/api/listings/$id') as Map<String, dynamic>);

  static Future<List<Listing>> myListings() async {
    final data = await ApiClient.instance.get('/api/listings/mine');
    return (data as List)
        .map((e) => Listing.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<Listing> createListing({
    required String title,
    required String description,
    required num price,
    required String category,
    required String condition,
    required String location,
    required List<String> images,
  }) async {
    final data = await ApiClient.instance.post('/api/listings', body: {
      'title': title,
      'description': description,
      'price': price,
      'category': category,
      'condition': condition,
      'location': location,
      'images': images,
    });
    return Listing.fromJson(data as Map<String, dynamic>);
  }

  static Future<Listing> updateListing(String id, Map<String, dynamic> updates) async {
    final data = await ApiClient.instance.put('/api/listings/$id', body: updates);
    return Listing.fromJson(data as Map<String, dynamic>);
  }

  static Future<void> deleteListing(String id) async {
    await ApiClient.instance.delete('/api/listings/$id');
  }

  static Future<Listing> markSold(String id) async {
    final data = await ApiClient.instance.put('/api/listings/$id/sold');
    return Listing.fromJson(data as Map<String, dynamic>);
  }

  static Future<void> contactSeller(
    String listingId, {
    required String name,
    required String message,
  }) async {
    await ApiClient.instance.post('/api/listings/$listingId/contact', body: {
      'name': name,
      'message': message,
    });
  }

  static Future<List<Favorite>> myFavorites() async {
    final data = await ApiClient.instance.get('/api/favorites');
    return (data as List)
        .map((e) => Favorite.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<bool> toggleFavorite(String listingId) async {
    final data =
        await ApiClient.instance.post('/api/favorites/$listingId') as Map<String, dynamic>;
    return data['favorited'] == true;
  }

  static Future<List<ContactMessage>> myMessages() async {
    final data = await ApiClient.instance.get('/api/messages');
    return (data as List)
        .map((e) => ContactMessage.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}