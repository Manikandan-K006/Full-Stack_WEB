import 'listing.dart';

class Favorite {
  final Listing listing;
  final String? favoritedAt;

  const Favorite({required this.listing, this.favoritedAt});

  factory Favorite.fromJson(Map<String, dynamic> json) => Favorite(
        listing: Listing.fromJson(json),
        favoritedAt: json['favorited_at']?.toString(),
      );
}