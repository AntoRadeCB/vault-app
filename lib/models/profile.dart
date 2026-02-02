import 'package:cloud_firestore/cloud_firestore.dart';

class Profile {
  final String? id;
  final String name;
  final List<String> features;
  final List<String> platforms;
  final String category;
  final String experienceLevel;
  final double budget;
  final DateTime? createdAt;

  const Profile({
    this.id,
    required this.name,
    required this.features,
    this.platforms = const [],
    required this.category,
    required this.experienceLevel,
    this.budget = 0.0,
    this.createdAt,
  });

  factory Profile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Profile(
      id: doc.id,
      name: data['name'] ?? '',
      features: List<String>.from(data['features'] ?? []),
      platforms: List<String>.from(data['platforms'] ?? []),
      category: data['category'] ?? 'generic',
      experienceLevel: data['experienceLevel'] ?? 'beginner',
      budget: (data['budget'] ?? 0).toDouble(),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'features': features,
      'platforms': platforms,
      'category': category,
      'experienceLevel': experienceLevel,
      'budget': budget,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  Profile copyWith({
    String? id,
    String? name,
    List<String>? features,
    List<String>? platforms,
    String? category,
    String? experienceLevel,
    double? budget,
    DateTime? createdAt,
  }) {
    return Profile(
      id: id ?? this.id,
      name: name ?? this.name,
      features: features ?? this.features,
      platforms: platforms ?? this.platforms,
      category: category ?? this.category,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      budget: budget ?? this.budget,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool hasFeature(String feature) => features.contains(feature);

  /// Determine category from a set of selected categories/platforms
  static String determineCategory(Set<String> platforms) {
    if (platforms.isEmpty) return 'generic';

    final cardPlatforms = {'cardmarket'};
    final sneakerPlatforms = {'stockx', 'goat'};
    final luxuryPlatforms = {'vestiaire', 'grailed'};
    final techPlatforms = {'tech'};

    final isCards = platforms.every((p) => cardPlatforms.contains(p));
    final isSneakers = platforms.every((p) => sneakerPlatforms.contains(p));
    final isLuxury = platforms.every((p) => luxuryPlatforms.contains(p));
    final isTech = platforms.every((p) => techPlatforms.contains(p));

    if (isCards && platforms.intersection(cardPlatforms).isNotEmpty) return 'cards';
    if (isSneakers && platforms.intersection(sneakerPlatforms).isNotEmpty) return 'sneakers';
    if (isLuxury && platforms.intersection(luxuryPlatforms).isNotEmpty) return 'luxury';
    if (isTech && platforms.intersection(techPlatforms).isNotEmpty) return 'tech';

    return 'generic';
  }

  /// Category display label
  static String categoryLabel(String category) {
    switch (category) {
      case 'cards':
        return '🃏 Carte Collezionabili';
      case 'sneakers':
        return '👟 Sneakers & Streetwear';
      case 'luxury':
        return '💎 Luxury & Designer';
      case 'vintage':
        return '👗 Moda & Vintage';
      case 'tech':
        return '🎮 Tech & Elettronica';
      case 'generic':
      default:
        return '🛒 Marketplace Generico';
    }
  }

  /// Short category label (no emoji)
  static String categoryShortLabel(String category) {
    switch (category) {
      case 'cards':
        return 'Carte';
      case 'sneakers':
        return 'Sneakers';
      case 'luxury':
        return 'Luxury';
      case 'vintage':
        return 'Vintage';
      case 'tech':
        return 'Tech';
      case 'generic':
      default:
        return 'Generico';
    }
  }
}
