import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// The type of a Vault profile, determines icon, color, and default tabs.
enum ProfileType { generic, cards, sneakers }

/// Represents a user profile (e.g. "Generico", "Carte Pokémon", "Sneakers").
/// Each profile controls which tabs are visible (feature gating) and
/// optionally has a monthly budget.
class UserProfile {
  final String id;
  final String name;
  final ProfileType type;
  final List<String> enabledTabs;
  final double? budgetMonthly;
  final double? budgetSpent;
  final DateTime createdAt;

  const UserProfile({
    required this.id,
    required this.name,
    required this.type,
    required this.enabledTabs,
    this.budgetMonthly,
    this.budgetSpent,
    required this.createdAt,
  });

  // ─── Icon derived from type ─────────────────────
  IconData get icon {
    switch (type) {
      case ProfileType.generic:
        return Icons.inventory_2;
      case ProfileType.cards:
        return Icons.style;
      case ProfileType.sneakers:
        return Icons.directions_run;
    }
  }

  // ─── Color derived from type ────────────────────
  Color get color {
    switch (type) {
      case ProfileType.generic:
        return const Color(0xFF667eea); // accentBlue
      case ProfileType.cards:
        return const Color(0xFF764ba2); // accentPurple
      case ProfileType.sneakers:
        return const Color(0xFF26C6DA); // accentTeal
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
      'budgetMonthly': budgetMonthly,
      'budgetSpent': budgetSpent,
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
        orElse: () => ProfileType.generic,
      ),
      enabledTabs: List<String>.from(data['enabledTabs'] ?? _allTabs),
      budgetMonthly: (data['budgetMonthly'] as num?)?.toDouble(),
      budgetSpent: (data['budgetSpent'] as num?)?.toDouble(),
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
    double? budgetMonthly,
    double? budgetSpent,
    DateTime? createdAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      enabledTabs: enabledTabs ?? this.enabledTabs,
      budgetMonthly: budgetMonthly ?? this.budgetMonthly,
      budgetSpent: budgetSpent ?? this.budgetSpent,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // ─── Tab identifiers used throughout the app ────
  static const List<String> _allTabs = [
    'dashboard',
    'inventory',
    'shipments',
    'reports',
    'settings',
  ];

  // ═══════════════════════════════════════════════════
  //  3 STATIC PRESET PROFILES
  // ═══════════════════════════════════════════════════

  /// Generico — all tabs, blue, inventory icon
  static UserProfile get presetGenerico => UserProfile(
        id: '',
        name: 'Generico',
        type: ProfileType.generic,
        enabledTabs: const [
          'dashboard',
          'inventory',
          'shipments',
          'reports',
          'settings',
        ],
        createdAt: DateTime.now(),
      );

  /// Carte Pokémon — no shipments tab, purple, style icon
  static UserProfile get presetCards => UserProfile(
        id: '',
        name: 'Carte Pokémon',
        type: ProfileType.cards,
        enabledTabs: const [
          'dashboard',
          'inventory',
          'reports',
          'settings',
        ],
        createdAt: DateTime.now(),
      );

  /// Sneakers — all tabs, teal, running icon
  static UserProfile get presetSneakers => UserProfile(
        id: '',
        name: 'Sneakers',
        type: ProfileType.sneakers,
        enabledTabs: const [
          'dashboard',
          'inventory',
          'shipments',
          'reports',
          'settings',
        ],
        createdAt: DateTime.now(),
      );

  static List<UserProfile> get presets => [
        presetGenerico,
        presetCards,
        presetSneakers,
      ];
}
