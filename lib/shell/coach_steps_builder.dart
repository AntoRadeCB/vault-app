import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../widgets/coach_mark_overlay.dart';

/// Lightweight value object describing a tab in the shell.
class TabDef {
  final String id;
  final IconData icon;
  final IconData selectedIcon;

  const TabDef({
    required this.id,
    required this.icon,
    required this.selectedIcon,
  });
}

/// All tab definitions (order matters for display).
const List<TabDef> allTabDefs = <TabDef>[
  TabDef(
    id: 'dashboard',
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard,
  ),
  TabDef(
    id: 'collection',
    icon: Icons.collections_bookmark_outlined,
    selectedIcon: Icons.collections_bookmark,
  ),
  TabDef(
    id: 'marketplace',
    icon: Icons.storefront_outlined,
    selectedIcon: Icons.storefront,
  ),
  TabDef(
    id: 'shipments',
    icon: Icons.local_shipping_outlined,
    selectedIcon: Icons.local_shipping,
  ),
];

/// Utility class that builds interactive coach-mark [CoachStep]s
/// targeting real UI elements.
class CoachStepsBuilder {
  CoachStepsBuilder._();

  /// Returns a localised label for the given tab [id].
  static String tabLabel(BuildContext context, String id) {
    final l = AppLocalizations.of(context)!;
    switch (id) {
      case 'dashboard':
        return l.home;
      case 'collection':
        return 'Collezione';
      case 'marketplace':
        return 'Marketplace';
      case 'shipments':
        return l.shipments;
      default:
        return id;
    }
  }

  /// Coach-mark accent colour per tab [id].
  static Color tabAccent(String id) {
    switch (id) {
      case 'dashboard':
        return AppColors.accentBlue;
      case 'collection':
        return const Color(0xFF667eea);
      case 'marketplace':
        return AppColors.accentGreen;
      case 'shipments':
        return AppColors.accentTeal;
      default:
        return AppColors.accentBlue;
    }
  }

  /// Coach-step description (Italian) per tab [id].
  static String tabCoachDesc(String id) {
    switch (id) {
      case 'dashboard':
        return 'Il tuo centro di controllo. Qui vedi il riepilogo della collezione: '
            'valore carte, budget e attività recente.';
      case 'collection':
        return 'Sfoglia la tua collezione come un raccoglitore di carte. '
            'Vedi il progresso per ogni espansione e il valore delle tue carte.';
      case 'marketplace':
        return 'Vendi le tue carte su eBay e Cardmarket. '
            'Gestisci inventario di vendita, inserzioni, ordini e spedizioni.';
      case 'shipments':
        return 'Traccia ogni pacco automaticamente. Inserisci il tracking '
            'e CardVault monitora corriere, stato e notifiche.';
      default:
        return '';
    }
  }

  /// Build interactive coach-mark steps targeting real UI elements.
  ///
  /// [isWide] – `true` for desktop (sidebar keys), `false` for mobile
  /// (bottom-nav keys).
  ///
  /// Key resolution delegates are provided so that the caller owns the
  /// [GlobalKey]s (they live in the shell state).
  static List<CoachStep> build({
    required BuildContext context,
    required bool isWide,
    required List<TabDef> visibleTabs,
    required GlobalKey Function(String id) mobileNavKey,
    required GlobalKey Function(String id) sidebarKey,
    required GlobalKey fabKey,
    required GlobalKey notificationsKey,
  }) {
    final steps = <CoachStep>[];

    for (final tab in visibleTabs) {
      steps.add(CoachStep(
        id: tab.id,
        targetKey: isWide ? sidebarKey(tab.id) : mobileNavKey(tab.id),
        title: tabLabel(context, tab.id),
        description: tabCoachDesc(tab.id),
        icon: tab.selectedIcon,
        accentColor: tabAccent(tab.id),
      ));

      // Insert FAB + Notifications steps after inventory in mobile
      if (!isWide && tab.id == 'marketplace') {
        steps.add(CoachStep(
          id: 'fab',
          targetKey: fabKey,
          title: 'Aggiungi Nuovo',
          description:
              'Tocca qui per aggiungere una nuova carta, busta o box '
              'alla tua collezione.',
          icon: Icons.add_circle,
          accentColor: AppColors.accentBlue,
          preferredPosition: TooltipPosition.above,
        ));
      }
    }

    // Add notifications step for mobile (at end)
    if (!isWide) {
      steps.add(CoachStep(
        id: 'notifications',
        targetKey: notificationsKey,
        title: 'Notifiche',
        description:
            'Aggiornamenti sulle spedizioni e avvisi importanti. '
            'Il badge mostra quante ne hai da leggere.',
        icon: Icons.notifications,
        accentColor: AppColors.accentOrange,
        preferredPosition: TooltipPosition.below,
      ));
    }

    return steps;
  }
}
