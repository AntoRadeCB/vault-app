import 'dart:async';
import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import 'firestore_service.dart';

/// Inherited widget that provides the active [UserProfile] to the widget tree.
///
/// Usage:
///   final profile = ProfileProvider.of(context);
///
/// Wraps a [StatefulWidget] that listens to Firestore streams for profiles
/// and the active profile id.
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
  List<String> get enabledTabs => profile?.enabledTabs ?? UserProfile.presetGenerico.enabledTabs;

  @override
  bool updateShouldNotify(ProfileProvider oldWidget) {
    return profile?.id != oldWidget.profile?.id ||
        profiles.length != oldWidget.profiles.length ||
        loading != oldWidget.loading ||
        profile?.name != oldWidget.profile?.name ||
        profile?.budgetMonthly != oldWidget.profile?.budgetMonthly ||
        profile?.budgetSpent != oldWidget.profile?.budgetSpent ||
        profile?.enabledTabs.length != oldWidget.profile?.enabledTabs.length;
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
    _fs.setActiveProfile(id);
  }

  UserProfile? get _activeProfile {
    if (_profiles.isEmpty || _activeProfileId == null) return null;
    try {
      return _profiles.firstWhere((p) => p.id == _activeProfileId);
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
