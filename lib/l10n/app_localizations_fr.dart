// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Vault - Reselling Tracker';

  @override
  String get vault => 'Vault';

  @override
  String get resellingTracker => 'Reselling Tracker';

  @override
  String get dashboard => 'Tableau de bord';

  @override
  String get inventory => 'Inventaire';

  @override
  String get shipments => 'Expéditions';

  @override
  String get reports => 'Rapports';

  @override
  String get settings => 'Paramètres';

  @override
  String get notifications => 'Notifications';

  @override
  String get home => 'Accueil';

  @override
  String get systemOnline => 'Système en ligne';

  @override
  String get searchItemsReports => 'Rechercher articles, rapports...';

  @override
  String get newItem => 'Nouvel Article';

  @override
  String get online => 'ONLINE';

  @override
  String get login => 'Connexion';

  @override
  String get register => 'S\'inscrire';

  @override
  String get email => 'Email';

  @override
  String get password => 'Mot de passe';

  @override
  String get confirmPassword => 'Confirmer le mot de passe';

  @override
  String get createAccount => 'Créer un Compte';

  @override
  String get enterEmailAndPassword => 'Entrez email et mot de passe.';

  @override
  String get passwordsDoNotMatch => 'Les mots de passe ne correspondent pas.';

  @override
  String get passwordMinLength =>
      'Le mot de passe doit contenir au moins 6 caractères.';

  @override
  String get userNotFound => 'Aucun utilisateur trouvé avec cet email.';

  @override
  String get wrongPassword => 'Mot de passe incorrect.';

  @override
  String get invalidEmail => 'Email non valide.';

  @override
  String get accountDisabled => 'Compte désactivé.';

  @override
  String get emailAlreadyInUse => 'Email déjà enregistré.';

  @override
  String get weakPassword => 'Mot de passe trop faible (minimum 6 caractères).';

  @override
  String get invalidCredential => 'Identifiants non valides.';

  @override
  String get unknownError => 'Erreur inconnue.';

  @override
  String get resellingVinted2025 => 'Reselling Vinted 2025';

  @override
  String nItems(int count) {
    return '$count articles';
  }

  @override
  String get capitaleImmobilizzato => 'Capital Immobilisé';

  @override
  String get ordiniInArrivo => 'Commandes Entrantes';

  @override
  String get capitaleSpedito => 'Capital Expédié';

  @override
  String get profittoConsolidato => 'Bénéfice Consolidé';

  @override
  String get totalSpent => 'Total Dépensé';

  @override
  String get totalRevenue => 'Revenus Totaux';

  @override
  String get avgProfit => 'Bénéfice Moyen';

  @override
  String get newPurchase => 'Nouvel Achat';

  @override
  String get registerSale => 'Enregistrer une Vente';

  @override
  String get recentSales => 'Ventes Récentes';

  @override
  String nTotal(int count) {
    return '$count au total';
  }

  @override
  String get noSalesRegistered => 'Aucune vente enregistrée';

  @override
  String get recentPurchases => 'Achats Récents';

  @override
  String get noPurchasesRegistered => 'Aucun achat enregistré';

  @override
  String get operationalStatus => 'État Opérationnel';

  @override
  String nShipmentsInTransit(int count) {
    return '$count expéditions en transit';
  }

  @override
  String nProductsOnSale(int count) {
    return '$count produits en vente';
  }

  @override
  String lowStockProduct(String name) {
    return 'Stock bas : $name';
  }

  @override
  String get noActiveAlerts => 'Aucune alerte active';

  @override
  String nRecords(int count) {
    return '$count ENREGISTREMENTS';
  }

  @override
  String get historicalRecords => 'Historique des Enregistrements';

  @override
  String get productSummary => 'Résumé des Produits';

  @override
  String get searchProduct => 'Rechercher un produit...';

  @override
  String get noProducts => 'Aucun produit';

  @override
  String get addYourFirstProduct => 'Ajoutez votre premier produit !';

  @override
  String get deleteProduct => 'Supprimer le Produit';

  @override
  String confirmDeleteProduct(String name) {
    return 'Êtes-vous sûr de vouloir supprimer \"$name\" ?';
  }

  @override
  String get cancel => 'Annuler';

  @override
  String get delete => 'Supprimer';

  @override
  String productDeleted(String name) {
    return '$name supprimé';
  }

  @override
  String get totalInventoryValue => 'Valeur Totale de l\'Inventaire';

  @override
  String get shippedProducts => 'Produits Expédiés';

  @override
  String get inInventory => 'En Inventaire';

  @override
  String get onSale => 'En Vente';

  @override
  String get itemName => 'Nom de l\'Article';

  @override
  String get itemNameHint => 'Ex. Nike Air Max 90';

  @override
  String get brand => 'Marque';

  @override
  String get brandHint => 'Ex. Nike, Adidas, Stone Island';

  @override
  String get purchasePrice => 'Prix d\'Achat (€)';

  @override
  String get quantity => 'Quantité';

  @override
  String get status => 'Statut';

  @override
  String get workspace => 'Workspace';

  @override
  String get shipped => 'Expédié';

  @override
  String get registerPurchase => 'Enregistrer l\'Achat';

  @override
  String get purchaseRegistered => 'Achat enregistré avec succès !';

  @override
  String get requiredField => 'Champ obligatoire';

  @override
  String get enterPrice => 'Entrez un prix';

  @override
  String get invalidPrice => 'Prix non valide';

  @override
  String get enterQuantity => 'Entrez une quantité';

  @override
  String get invalidQuantity => 'Quantité non valide';

  @override
  String get barcode => 'BARCODE';

  @override
  String productFound(String name) {
    return 'Produit trouvé : $name';
  }

  @override
  String barcodeScanned(String code) {
    return 'Barcode : $code — remplissez les données du produit';
  }

  @override
  String get product => 'Produit';

  @override
  String get scanBarcodeProduct => 'Scanner le Barcode du Produit';

  @override
  String get selectProduct => 'Sélectionner un produit...';

  @override
  String get noProductsInInventory => 'Aucun produit en inventaire';

  @override
  String get salePrice => 'Prix de Vente (€)';

  @override
  String get enterSalePrice => 'Entrez le prix de vente';

  @override
  String get feesShipping => 'Commissions / Expédition (€)';

  @override
  String get invalidValue => 'Valeur non valide';

  @override
  String get removeFromInventory => 'Retirer de l\'inventaire';

  @override
  String get scaleOneUnit => 'Déduire 1 unité du produit';

  @override
  String get saleSummary => 'RÉSUMÉ DE LA VENTE';

  @override
  String get salePriceLabel => 'Prix de vente';

  @override
  String get purchaseCost => 'Coût d\'achat';

  @override
  String get fees => 'Commissions';

  @override
  String get profit => 'BÉNÉFICE';

  @override
  String get confirmSale => 'Confirmer la Vente';

  @override
  String saleRegistered(String profit) {
    return 'Vente enregistrée ! Bénéfice : €$profit';
  }

  @override
  String get selectProductToSell => 'Sélectionnez un produit à vendre.';

  @override
  String found(String name) {
    return 'Trouvé : $name';
  }

  @override
  String noProductFoundBarcode(String code) {
    return 'Aucun produit trouvé avec le barcode : $code';
  }

  @override
  String get editProduct => 'Modifier le Produit';

  @override
  String get modified => 'MODIFIÉ';

  @override
  String get unsavedChanges => 'Modifications non enregistrées';

  @override
  String get unsavedChangesMessage =>
      'Vous avez des modifications non enregistrées. Voulez-vous quitter sans enregistrer ?';

  @override
  String get stay => 'Rester';

  @override
  String get exit => 'Quitter';

  @override
  String get saveChanges => 'Enregistrer les Modifications';

  @override
  String get productUpdated => 'Produit mis à jour !';

  @override
  String nActive(int count) {
    return '$count ACTIFS';
  }

  @override
  String get all => 'Toutes';

  @override
  String get inProgress => 'En Cours';

  @override
  String get delivered => 'Livrées';

  @override
  String get noShipments => 'Aucune expédition';

  @override
  String get addTrackingWhenRegistering =>
      'Ajoutez un code de suivi lors de l\'enregistrement\nd\'un achat ou d\'une vente';

  @override
  String get deleteShipment => 'Supprimer l\'Expédition';

  @override
  String confirmDeleteShipment(String code) {
    return 'Supprimer l\'expédition $code ?';
  }

  @override
  String get codeCopied => 'Code copié !';

  @override
  String get track => 'Suivre';

  @override
  String get ship24 => 'SHIP24';

  @override
  String lastUpdate(String time) {
    return 'Dernière maj : $time';
  }

  @override
  String updated(String status) {
    return 'Mis à jour : $status';
  }

  @override
  String get purchase => 'ACHAT';

  @override
  String get sale => 'VENTE';

  @override
  String get tracking => 'Suivi';

  @override
  String get refreshFromShip24 => 'Actualiser depuis Ship24';

  @override
  String get trackingTimeline => 'CHRONOLOGIE DU SUIVI';

  @override
  String nEvents(int count) {
    return '$count événements';
  }

  @override
  String get noTrackingEvents => 'Aucun événement de suivi';

  @override
  String get pressRefreshToUpdate =>
      'Appuyez sur le bouton 🔄 pour actualiser\nle statut depuis Ship24';

  @override
  String openOn(String carrier) {
    return 'Ouvrir sur $carrier';
  }

  @override
  String statusUpdated(String status) {
    return 'Statut mis à jour : $status';
  }

  @override
  String get pending => 'En attente';

  @override
  String get inTransit => 'En transit';

  @override
  String get deliveredStatus => 'Livré';

  @override
  String get problem => 'Problème';

  @override
  String get unknown => 'Inconnu';

  @override
  String get today => 'Aujourd\'hui';

  @override
  String get yesterday => 'Hier';

  @override
  String get now => 'Maintenant';

  @override
  String minutesAgo(int count) {
    return 'il y a ${count}m';
  }

  @override
  String hoursAgo(int count) {
    return 'il y a ${count}h';
  }

  @override
  String daysAgo(int count) {
    return 'il y a ${count}j';
  }

  @override
  String error(String message) {
    return 'Erreur : $message';
  }

  @override
  String get financialOverview => 'Aperçu Financier';

  @override
  String get totalRevenueLabel => 'Revenus Totaux';

  @override
  String get totalSpentLabel => 'Total Dépensé';

  @override
  String get netProfit => 'Bénéfice Net';

  @override
  String get roi => 'ROI';

  @override
  String get salesSection => 'Ventes';

  @override
  String get salesCount => 'Nb de Ventes';

  @override
  String get avgProfitLabel => 'Bénéfice Moyen';

  @override
  String get totalFees => 'Total Commissions';

  @override
  String get bestSale => 'MEILLEURE VENTE';

  @override
  String get purchasesSection => 'Achats';

  @override
  String get purchasesCount => 'Nb d\'Achats';

  @override
  String get inventoryValue => 'Valeur de l\'Inventaire';

  @override
  String get totalPieces => 'Pièces Totales';

  @override
  String get financialBreakdown => 'Ventilation Financière';

  @override
  String get salesRevenue => 'Revenus des ventes';

  @override
  String get purchaseCosts => 'Coûts d\'achat';

  @override
  String get feesPaid => 'Commissions payées';

  @override
  String get netProfitLabel => 'BÉNÉFICE NET';

  @override
  String get costsLegend => 'Coûts';

  @override
  String get feesLegend => 'Commissions';

  @override
  String get profitLegend => 'Bénéfice';

  @override
  String get fullOverview => 'Aperçu complet des achats et des ventes';

  @override
  String get export => 'Exporter';

  @override
  String get csvFullHistory => 'CSV Full History';

  @override
  String get pdfTaxSummary => 'PDF Tax Summary';

  @override
  String get monthlySalesLog => 'Monthly Sales Log';

  @override
  String get salesHistory => 'Historique des Ventes';

  @override
  String get purchasesHistory => 'Historique des Achats';

  @override
  String get account => 'Compte';

  @override
  String get resetViaEmail => 'Réinitialiser par email';

  @override
  String get forgotPassword => 'Mot de passe oublié ?';

  @override
  String get twoFactorAuth => 'Authentification 2FA';

  @override
  String get notAvailable => 'Non disponible';

  @override
  String get twoFactorTitle => 'Authentification à Deux Facteurs';

  @override
  String get twoFactorDescription =>
      'La 2FA sera disponible dans une mise à jour future.\n\nPour l\'instant, assurez-vous d\'utiliser un mot de passe fort.';

  @override
  String get workspaceActive => 'Workspace Actif';

  @override
  String get selectWorkspace => 'Sélectionner Workspace';

  @override
  String get autoBackup => 'Sauvegarde Automatique';

  @override
  String get syncDataCloud => 'Synchroniser les données sur le cloud';

  @override
  String get exportAllData => 'Exporter Toutes les Données';

  @override
  String get csvPdfJson => 'CSV, PDF, JSON';

  @override
  String get notificationsInApp => 'Notifications dans l\'App';

  @override
  String get salesShipmentAlerts => 'Alertes ventes et expéditions';

  @override
  String get pushNotifications => 'Notifications Push';

  @override
  String get receiveOnMobile => 'Recevoir sur mobile';

  @override
  String get emailDigest => 'Email Digest';

  @override
  String get weeklyReport => 'Rapport hebdomadaire';

  @override
  String get appearance => 'Apparence';

  @override
  String get darkMode => 'Mode Sombre';

  @override
  String get useDarkTheme => 'Utiliser le thème sombre';

  @override
  String get fontSize => 'Taille de Police';

  @override
  String get accentColor => 'Couleur d\'Accent';

  @override
  String get blueViolet => 'Bleu-Violet';

  @override
  String get green => 'Vert';

  @override
  String get orange => 'Orange';

  @override
  String get info => 'Info';

  @override
  String get version => 'Version';

  @override
  String get termsOfService => 'Conditions d\'Utilisation';

  @override
  String get privacyPolicy => 'Politique de Confidentialité';

  @override
  String get reportBug => 'Signaler un Bug';

  @override
  String get describeProblem => 'Décrivez le problème...';

  @override
  String get logout => 'Déconnexion';

  @override
  String get confirmLogout => 'Êtes-vous sûr de vouloir vous déconnecter ?';

  @override
  String get proPlan => 'PRO PLAN';

  @override
  String get userName => 'Nom d\'Utilisateur';

  @override
  String get close => 'Fermer';

  @override
  String get save => 'Enregistrer';

  @override
  String fieldUpdated(String field) {
    return '$field mis à jour !';
  }

  @override
  String get verificationSent => 'Vérification envoyée au nouvel email';

  @override
  String resetEmailSent(String email) {
    return 'Email de réinitialisation envoyé à $email';
  }

  @override
  String exportStarted(String format) {
    return 'Exportation $format lancée !';
  }

  @override
  String get exportData => 'Exporter les Données';

  @override
  String get chooseExportFormat => 'Choisissez le format d\'exportation';

  @override
  String get allRecordsCsv => 'Tous les enregistrements au format CSV';

  @override
  String get formattedReport => 'Rapport formaté pour l\'impression';

  @override
  String get rawDataJson => 'Données brutes au format JSON';

  @override
  String get termsContent =>
      'Vault Reselling Tracker — Conditions d\'Utilisation\n\nEn utilisant cette app, vous acceptez les conditions suivantes :\n\n1. L\'app est fournie « telle quelle » sans garantie.\n2. Les données saisies sont sous votre responsabilité.\n3. Nous ne sommes pas responsables des pertes résultant de l\'utilisation de l\'app.\n4. Les données sont stockées sur Firebase Cloud.\n5. Vous pouvez exporter et supprimer vos données à tout moment.\n\nDernière mise à jour : Janvier 2025';

  @override
  String get privacyContent =>
      'Votre vie privée est importante pour nous.\n\n• Les données sont stockées en toute sécurité sur Firebase\n• L\'authentification est gérée par Firebase Auth\n• Nous ne partageons pas les informations avec des tiers\n• Vous pouvez demander la suppression des données à tout moment\n\nPour toute question : privacy@vault-app.com';

  @override
  String nUnread(int count) {
    return '$count NON LUES';
  }

  @override
  String get markAllRead => 'Tout marquer comme lu';

  @override
  String get clearAll => 'Tout Effacer';

  @override
  String get deleteAll => 'Tout supprimer';

  @override
  String get deleteAllNotifications => 'Supprimer toutes les notifications ?';

  @override
  String get noNotifications => 'Aucune notification';

  @override
  String get notificationsWillAppearHere =>
      'Les notifications de suivi et de ventes\napparaîtront ici';

  @override
  String get shipmentType => 'EXPÉDITION';

  @override
  String get saleType => 'VENTE';

  @override
  String get lowStockType => 'STOCK BAS';

  @override
  String get systemType => 'SYSTÈME';

  @override
  String get addTracking => '+ Ajouter un Suivi (facultatif)';

  @override
  String get trackingShipment => 'SUIVI D\'EXPÉDITION';

  @override
  String get remove => 'Supprimer';

  @override
  String carrierDetected(String name) {
    return 'Transporteur détecté : $name';
  }

  @override
  String get trackingHint => 'Ex. RR123456789IT';

  @override
  String soldAt(String price) {
    return 'Vendu à €$price';
  }

  @override
  String costLabel(String price) {
    return 'Coût €$price';
  }

  @override
  String feeLabel(String price) {
    return 'Fee €$price';
  }

  @override
  String get costUpperCase => 'COÛT';

  @override
  String qty(String qty) {
    return 'Qté : $qty';
  }

  @override
  String get small => 'Small';

  @override
  String get medium => 'Medium';

  @override
  String get large => 'Large';

  @override
  String get extraLarge => 'Extra Large';
}
