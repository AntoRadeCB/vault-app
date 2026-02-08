import 'dart:async';
import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/firestore_service.dart';

/// Inherited widget that provides the active [UserProfile] to the widget tree.
///
/// ## Why InheritedWidget instead of ChangeNotifier + Provider?
///
/// [ProfileProvider] uses the InheritedWidget pattern deliberately:
///
/// 1. **Stream-driven updates** — Profile data comes from two Firestore
///    streams (`getProfiles()` and `getActiveProfileId()`).  The wrapper
///    [ProfileProviderWrapper] is a [StatefulWidget] that listens to those
///    streams and calls `setState`, which rebuilds the [ProfileProvider]
///    InheritedWidget.  Consumers that call `ProfileProvider.of(context)`
///    automatically re-render when `updateShouldNotify` returns `true`.
///
/// 2. **Granular rebuild control** — `updateShouldNotify` checks only the
///    fields that matter (profile id, name, budget, tab count), avoiding
///    unnecessary rebuilds for unchanged data.
///
/// 3. **No external dependency** — Unlike `package:provider`, the
///    InheritedWidget approach requires zero additional packages and
///    integrates naturally with the existing widget tree.
///
/// If the app later adopts `package:provider` or `package:riverpod`,
/// this can be converted to a `ChangeNotifierProvider` with minimal
/// effort — the public API (`of`, `maybeOf`, fields) stays the same.
///
/// Usage:
///   final profile = ProfileProvider.of(context).profile;
///   final provider = ProfileProvider.maybeOf(context);
class ProfileProvider extends InheritedWidget {
  final UserProfile? profile;
  final List<UserProfile> profiles;
  final void Function(String id) switchProfile;
  final bool loading;

  const ProfileProvider({
    super.key,
    required super.child,
    required this.profile,
    required this.profiles,
    required this.switchProfile,
    this.loading = false,
  });

  /// Convenience accessor.
  static ProfileProvider? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ProfileProvider>();
  }

  static ProfileProvider of(BuildContext context) {
    final result = maybeOf(context);
    assert(result != null, 'No ProfileProvider found in context');
    return result!;
  }

  /// Returns the list of enabled tab identifiers for the active profile.
  List<String> get enabledTabs => profile?.enabledTabs ?? UserProfile.presetOther.enabledTabs;

  /// Returns the list of tracked game ids (empty = all games).
  List<String> get trackedGames => profile?.trackedGames ?? [];

  @override
  bool updateShouldNotify(ProfileProvider oldWidget) {
    // Compare all mutable profile properties to ensure UI updates
    final oldProfile = oldWidget.profile;
    final newProfile = profile;
    
    if (profiles.length != oldWidget.profiles.length) return true;
    if (loading != oldWidget.loading) return true;
    if (newProfile?.id != oldProfile?.id) return true;
    if (newProfile?.name != oldProfile?.name) return true;
    if (newProfile?.budgetMonthly != oldProfile?.budgetMonthly) return true;
    if (newProfile?.budgetSpent != oldProfile?.budgetSpent) return true;
    if (newProfile?.autoInventory != oldProfile?.autoInventory) return true;
    if (newProfile?.collectionTarget != oldProfile?.collectionTarget) return true;
    if (newProfile?.enabledTabs.length != oldProfile?.enabledTabs.length) return true;
    if (newProfile?.trackedGames.length != oldProfile?.trackedGames.length) return true;
    
    // Deep compare lists for actual content changes
    if (newProfile != null && oldProfile != null) {
      for (int i = 0; i < newProfile.enabledTabs.length; i++) {
        if (i >= oldProfile.enabledTabs.length || 
            newProfile.enabledTabs[i] != oldProfile.enabledTabs[i]) return true;
      }
      for (int i = 0; i < newProfile.trackedGames.length; i++) {
        if (i >= oldProfile.trackedGames.length || 
            newProfile.trackedGames[i] != oldProfile.trackedGames[i]) return true;
      }
    }
    
    return false;
  }
}

/// Wrapper widget that manages the profile state and provides it via
/// [ProfileProvider].
class ProfileProviderWrapper extends StatefulWidget {
  final Widget child;

  const ProfileProviderWrapper({super.key, required this.child});

  @override
  State<ProfileProviderWrapper> createState() => _ProfileProviderWrapperState();
}

class _ProfileProviderWrapperState extends State<ProfileProviderWrapper> {
  final FirestoreService _fs = FirestoreService();

  List<UserProfile> _profiles = [];
  String? _activeProfileId;
  bool _loading = true;

  // Local override for demo mode where Firestore writes are no-ops
  String? _localActiveProfileId;

  StreamSubscription? _profilesSub;
  StreamSubscription? _activeIdSub;

  @override
  void initState() {
    super.initState();
    _listen();
  }

  void _listen() {
    _profilesSub = _fs.getProfiles().listen((profiles) {
      if (mounted) setState(() => _profiles = profiles);
    });
    _activeIdSub = _fs.getActiveProfileId().listen((id) {
      if (mounted) {
        setState(() {
          _activeProfileId = id;
          _loading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _profilesSub?.cancel();
    _activeIdSub?.cancel();
    super.dispose();
  }

  void _switchProfile(String id) {
    if (FirestoreService.demoMode) {
      // In demo mode, store selection locally since Firestore writes are no-ops
      setState(() => _localActiveProfileId = id);
    } else {
      _fs.setActiveProfile(id);
    }
  }

  String? get _effectiveActiveProfileId =>
      _localActiveProfileId ?? _activeProfileId;

  UserProfile? get _activeProfile {
    if (_profiles.isEmpty || _effectiveActiveProfileId == null) return null;
    try {
      return _profiles.firstWhere((p) => p.id == _effectiveActiveProfileId);
    } catch (_) {
      return _profiles.isNotEmpty ? _profiles.first : null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ProfileProvider(
      profile: _activeProfile,
      profiles: _profiles,
      switchProfile: _switchProfile,
      loading: _loading,
      child: widget.child,
    );
  }
}
