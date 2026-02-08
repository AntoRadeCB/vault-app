import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// The type of a Vault profile — one per card game.
enum ProfileType { riftbound, pokemon, mtg, yugioh, onepiece, other }

/// Represents a user profile (e.g. "Pokémon TCG", "Magic: The Gathering").
/// Each profile controls which tabs are visible (feature gating) and
/// optionally has a monthly budget.
class UserProfile {
  final String id;
  final String name;
  final ProfileType type;
  final List<String> enabledTabs;
  final List<String> trackedGames; // TCG ids the user wants to see
  final double? budgetMonthly;
  final double? budgetSpent;
  final int collectionTarget;
  final bool autoInventory;
  final DateTime createdAt;

  const UserProfile({
    required this.id,
    required this.name,
    required this.type,
    required this.enabledTabs,
    this.trackedGames = const [],
    this.budgetMonthly,
    this.budgetSpent,
    this.collectionTarget = 1,
    this.autoInventory = false,
    required this.createdAt,
  });

  // ─── Icon derived from type ─────────────────────
  IconData get icon {
    switch (type) {
      case ProfileType.riftbound:
        return Icons.auto_awesome;
      case ProfileType.pokemon:
        return Icons.catching_pokemon;
      case ProfileType.mtg:
        return Icons.auto_fix_high;
      case ProfileType.yugioh:
        return Icons.style;
      case ProfileType.onepiece:
        return Icons.sailing;
      case ProfileType.other:
        return Icons.collections_bookmark;
    }
  }

  // ─── Color derived from type ────────────────────
  Color get color {
    switch (type) {
      case ProfileType.riftbound:
        return const Color(0xFF667eea); // accentBlue
      case ProfileType.pokemon:
        return const Color(0xFFFFCB05); // Pokémon yellow
      case ProfileType.mtg:
        return const Color(0xFF764ba2); // accentPurple
      case ProfileType.yugioh:
        return const Color(0xFFE53935); // red
      case ProfileType.onepiece:
        return const Color(0xFFFF7043); // deep orange
      case ProfileType.other:
        return const Color(0xFF26C6DA); // teal
    }
  }

  // ─── Budget helpers ─────────────────────────────
  bool get hasBudget => budgetMonthly != null && budgetMonthly! > 0;

  double get budgetProgress {
    if (!hasBudget) return 0;
    return ((budgetSpent ?? 0) / budgetMonthly!).clamp(0.0, 1.5);
  }

  // ─── Firestore serialisation ────────────────────
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'type': type.name,
      'enabledTabs': enabledTabs,
      'trackedGames': trackedGames,
      'budgetMonthly': budgetMonthly,
      'budgetSpent': budgetSpent,
      'collectionTarget': collectionTarget,
      'autoInventory': autoInventory,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      id: doc.id,
      name: data['name'] ?? 'Profilo',
      type: ProfileType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => ProfileType.other,
      ),
      enabledTabs: _mergeNewTabs(List<String>.from(data['enabledTabs'] ?? _allTabs)),
      trackedGames: List<String>.from(data['trackedGames'] ?? []),
      budgetMonthly: (data['budgetMonthly'] as num?)?.toDouble(),
      budgetSpent: (data['budgetSpent'] as num?)?.toDouble(),
      collectionTarget: (data['collectionTarget'] as num?)?.toInt() ?? 1,
      autoInventory: data['autoInventory'] ?? false,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  UserProfile copyWith({
    String? id,
    String? name,
    ProfileType? type,
    List<String>? enabledTabs,
    List<String>? trackedGames,
    double? budgetMonthly,
    double? budgetSpent,
    int? collectionTarget,
    bool? autoInventory,
    DateTime? createdAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      enabledTabs: enabledTabs ?? this.enabledTabs,
      trackedGames: trackedGames ?? this.trackedGames,
      budgetMonthly: budgetMonthly ?? this.budgetMonthly,
      budgetSpent: budgetSpent ?? this.budgetSpent,
      collectionTarget: collectionTarget ?? this.collectionTarget,
      autoInventory: autoInventory ?? this.autoInventory,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Merge any new tabs from [_allTabs] into a saved list, preserving order.
  static List<String> _mergeNewTabs(List<String> saved) {
    final result = List<String>.from(saved);
    // Migration: remove legacy tabs
    result.remove('reports');
    result.remove('inventory');
    result.remove('ebay');
    result.remove('settings');
    for (var i = 0; i < _allTabs.length; i++) {
      if (!result.contains(_allTabs[i])) {
        // Insert at the canonical position (or end if beyond length)
        final pos = i.clamp(0, result.length);
        result.insert(pos, _allTabs[i]);
      }
    }
    return result;
  }

  // ─── Tab identifiers used throughout the app ────
  static const List<String> _allTabs = [
    'dashboard',
    'collection',
    'marketplace',
    'shipments',
  ];

  // ═══════════════════════════════════════════════════
  //  6 STATIC PRESET PROFILES (one per card game)
  // ═══════════════════════════════════════════════════

  static UserProfile get presetRiftbound => UserProfile(
        id: '',
        name: 'Riftbound',
        type: ProfileType.riftbound,
        trackedGames: const ['riftbound'],
        enabledTabs: _allTabs,
        createdAt: DateTime.now(),
      );

  static UserProfile get presetPokemon => UserProfile(
        id: '',
        name: 'Pokémon TCG',
        type: ProfileType.pokemon,
        trackedGames: const ['pokemon'],
        enabledTabs: _allTabs,
        createdAt: DateTime.now(),
      );

  static UserProfile get presetMtg => UserProfile(
        id: '',
        name: 'Magic: The Gathering',
        type: ProfileType.mtg,
        trackedGames: const ['mtg'],
        enabledTabs: _allTabs,
        createdAt: DateTime.now(),
      );

  static UserProfile get presetYugioh => UserProfile(
        id: '',
        name: 'Yu-Gi-Oh!',
        type: ProfileType.yugioh,
        trackedGames: const ['yugioh'],
        enabledTabs: _allTabs,
        createdAt: DateTime.now(),
      );

  static UserProfile get presetOnePiece => UserProfile(
        id: '',
        name: 'One Piece TCG',
        type: ProfileType.onepiece,
        trackedGames: const ['onepiece'],
        enabledTabs: _allTabs,
        createdAt: DateTime.now(),
      );

  static UserProfile get presetOther => UserProfile(
        id: '',
        name: 'Altro',
        type: ProfileType.other,
        trackedGames: const ['riftbound', 'pokemon', 'mtg', 'yugioh', 'onepiece'],
        enabledTabs: _allTabs,
        createdAt: DateTime.now(),
      );

  static List<UserProfile> get presets => [
        presetRiftbound,
        presetPokemon,
        presetMtg,
        presetYugioh,
        presetOnePiece,
        presetOther,
      ];

  /// All supported TCG game ids
  static const List<String> allSupportedGames = [
    'riftbound', 'pokemon', 'mtg', 'yugioh', 'onepiece',
  ];

  /// Game display info
  static String gameLabel(String gameId) {
    switch (gameId) {
      case 'riftbound': return 'Riftbound';
      case 'pokemon': return 'Pokémon TCG';
      case 'mtg': return 'Magic: The Gathering';
      case 'yugioh': return 'Yu-Gi-Oh!';
      case 'onepiece': return 'One Piece TCG';
      default: return gameId;
    }
  }

  static IconData gameIcon(String gameId) {
    switch (gameId) {
      case 'riftbound': return Icons.auto_awesome;
      case 'pokemon': return Icons.catching_pokemon;
      case 'mtg': return Icons.auto_fix_high;
      case 'yugioh': return Icons.style;
      case 'onepiece': return Icons.sailing;
      default: return Icons.collections_bookmark;
    }
  }

  static Color gameColor(String gameId) {
    switch (gameId) {
      case 'riftbound': return const Color(0xFF667eea);
      case 'pokemon': return const Color(0xFFFFCB05);
      case 'mtg': return const Color(0xFF764ba2);
      case 'yugioh': return const Color(0xFFE53935);
      case 'onepiece': return const Color(0xFFFF7043);
      default: return const Color(0xFF26C6DA);
    }
  }

  /// Category display label (used in onboarding picker)
  static String categoryLabel(ProfileType type) {
    switch (type) {
      case ProfileType.riftbound:
        return 'Riftbound';
      case ProfileType.pokemon:
        return 'Pokémon TCG';
      case ProfileType.mtg:
        return 'Magic: The Gathering';
      case ProfileType.yugioh:
        return 'Yu-Gi-Oh!';
      case ProfileType.onepiece:
        return 'One Piece TCG';
      case ProfileType.other:
        return 'Altro';
    }
  }

  /// Category hint examples (shown below category in onboarding)
  static String categoryHint(ProfileType type) {
    switch (type) {
      case ProfileType.riftbound:
        return 'Il nuovo gioco di carte collezionabili. Starter box, buste e carte singole.';
      case ProfileType.pokemon:
        return 'Carte singole, booster pack, ETB, display box e prodotti speciali Pokémon.';
      case ProfileType.mtg:
        return 'Draft booster, collector booster, carte singole, mazzi Commander e altro.';
      case ProfileType.yugioh:
        return 'Buste, tin, carte singole, structure deck e prodotti Yu-Gi-Oh!';
      case ProfileType.onepiece:
        return 'Booster pack, starter deck, carte singole del gioco One Piece Card Game.';
      case ProfileType.other:
        return 'Qualsiasi altro gioco di carte collezionabili: Digimon, Dragon Ball, Lorcana...';
    }
  }
}
