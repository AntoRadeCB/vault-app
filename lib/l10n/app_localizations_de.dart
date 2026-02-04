// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Vault - Reselling Tracker';

  @override
  String get vault => 'Vault';

  @override
  String get resellingTracker => 'Reselling Tracker';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get inventory => 'Inventar';

  @override
  String get shipments => 'Sendungen';

  @override
  String get reports => 'Berichte';

  @override
  String get settings => 'Einstellungen';

  @override
  String get notifications => 'Benachrichtigungen';

  @override
  String get home => 'Startseite';

  @override
  String get systemOnline => 'System Online';

  @override
  String get searchItemsReports => 'Artikel, Berichte suchen...';

  @override
  String get newItem => 'Neuer Artikel';

  @override
  String get online => 'ONLINE';

  @override
  String get login => 'Anmelden';

  @override
  String get register => 'Registrieren';

  @override
  String get email => 'Email';

  @override
  String get password => 'Passwort';

  @override
  String get confirmPassword => 'Passwort bestätigen';

  @override
  String get createAccount => 'Konto erstellen';

  @override
  String get enterEmailAndPassword => 'Email und Passwort eingeben.';

  @override
  String get passwordsDoNotMatch => 'Passwörter stimmen nicht überein.';

  @override
  String get passwordMinLength =>
      'Das Passwort muss mindestens 6 Zeichen lang sein.';

  @override
  String get userNotFound => 'Kein Benutzer mit dieser Email gefunden.';

  @override
  String get wrongPassword => 'Falsches Passwort.';

  @override
  String get invalidEmail => 'Ungültige Email.';

  @override
  String get accountDisabled => 'Konto deaktiviert.';

  @override
  String get emailAlreadyInUse => 'Email bereits registriert.';

  @override
  String get weakPassword => 'Passwort zu schwach (mindestens 6 Zeichen).';

  @override
  String get invalidCredential => 'Ungültige Anmeldedaten.';

  @override
  String get unknownError => 'Unbekannter Fehler.';

  @override
  String get resellingVinted2025 => 'Reselling Vinted 2025';

  @override
  String nItems(int count) {
    return '$count Artikel';
  }

  @override
  String get capitaleImmobilizzato => 'Gebundenes Kapital';

  @override
  String get ordiniInArrivo => 'Eingehende Bestellungen';

  @override
  String get capitaleSpedito => 'Versendetes Kapital';

  @override
  String get profittoConsolidato => 'Konsolidierter Gewinn';

  @override
  String get totalSpent => 'Gesamtausgaben';

  @override
  String get totalRevenue => 'Gesamteinnahmen';

  @override
  String get avgProfit => 'Durchschnittlicher Gewinn';

  @override
  String get newPurchase => 'Neuer Einkauf';

  @override
  String get registerSale => 'Verkauf erfassen';

  @override
  String get recentSales => 'Letzte Verkäufe';

  @override
  String nTotal(int count) {
    return '$count gesamt';
  }

  @override
  String get noSalesRegistered => 'Keine Verkäufe registriert';

  @override
  String get recentPurchases => 'Letzte Einkäufe';

  @override
  String get noPurchasesRegistered => 'Keine Einkäufe registriert';

  @override
  String get operationalStatus => 'Betriebsstatus';

  @override
  String nShipmentsInTransit(int count) {
    return '$count Sendungen unterwegs';
  }

  @override
  String nProductsOnSale(int count) {
    return '$count Produkte im Verkauf';
  }

  @override
  String lowStockProduct(String name) {
    return 'Niedriger Bestand: $name';
  }

  @override
  String get noActiveAlerts => 'Keine aktiven Warnungen';

  @override
  String nRecords(int count) {
    return '$count EINTRÄGE';
  }

  @override
  String get historicalRecords => 'Historische Einträge';

  @override
  String get productSummary => 'Produktübersicht';

  @override
  String get searchProduct => 'Produkt suchen...';

  @override
  String get noProducts => 'Keine Produkte';

  @override
  String get addYourFirstProduct => 'Füge dein erstes Produkt hinzu!';

  @override
  String get deleteProduct => 'Produkt löschen';

  @override
  String confirmDeleteProduct(String name) {
    return 'Bist du sicher, dass du \"$name\" löschen möchtest?';
  }

  @override
  String get cancel => 'Abbrechen';

  @override
  String get delete => 'Löschen';

  @override
  String productDeleted(String name) {
    return '$name gelöscht';
  }

  @override
  String get totalInventoryValue => 'Gesamtwert des Inventars';

  @override
  String get shippedProducts => 'Versendete Produkte';

  @override
  String get inInventory => 'Im Inventar';

  @override
  String get onSale => 'Im Verkauf';

  @override
  String get itemName => 'Artikelname';

  @override
  String get itemNameHint => 'Z.B. Nike Air Max 90';

  @override
  String get brand => 'Marke';

  @override
  String get brandHint => 'Z.B. Nike, Adidas, Stone Island';

  @override
  String get purchasePrice => 'Einkaufspreis (€)';

  @override
  String get quantity => 'Menge';

  @override
  String get status => 'Status';

  @override
  String get workspace => 'Workspace';

  @override
  String get shipped => 'Versendet';

  @override
  String get registerPurchase => 'Einkauf erfassen';

  @override
  String get purchaseRegistered => 'Einkauf erfolgreich erfasst!';

  @override
  String get requiredField => 'Pflichtfeld';

  @override
  String get enterPrice => 'Preis eingeben';

  @override
  String get invalidPrice => 'Ungültiger Preis';

  @override
  String get enterQuantity => 'Menge eingeben';

  @override
  String get invalidQuantity => 'Ungültige Menge';

  @override
  String get barcode => 'BARCODE';

  @override
  String productFound(String name) {
    return 'Produkt gefunden: $name';
  }

  @override
  String barcodeScanned(String code) {
    return 'Barcode: $code — Produktdaten ausfüllen';
  }

  @override
  String get product => 'Produkt';

  @override
  String get scanBarcodeProduct => 'Produkt-Barcode scannen';

  @override
  String get selectProduct => 'Produkt auswählen...';

  @override
  String get noProductsInInventory => 'Keine Produkte im Inventar';

  @override
  String get salePrice => 'Verkaufspreis (€)';

  @override
  String get enterSalePrice => 'Verkaufspreis eingeben';

  @override
  String get feesShipping => 'Gebühren / Versand (€)';

  @override
  String get invalidValue => 'Ungültiger Wert';

  @override
  String get removeFromInventory => 'Aus dem Inventar entfernen';

  @override
  String get scaleOneUnit => '1 Einheit vom Produkt abziehen';

  @override
  String get saleSummary => 'VERKAUFSÜBERSICHT';

  @override
  String get salePriceLabel => 'Verkaufspreis';

  @override
  String get purchaseCost => 'Einkaufskosten';

  @override
  String get fees => 'Gebühren';

  @override
  String get profit => 'GEWINN';

  @override
  String get confirmSale => 'Verkauf bestätigen';

  @override
  String saleRegistered(String profit) {
    return 'Verkauf erfasst! Gewinn: €$profit';
  }

  @override
  String get selectProductToSell => 'Wähle ein Produkt zum Verkaufen.';

  @override
  String found(String name) {
    return 'Gefunden: $name';
  }

  @override
  String noProductFoundBarcode(String code) {
    return 'Kein Produkt mit Barcode gefunden: $code';
  }

  @override
  String get editProduct => 'Produkt bearbeiten';

  @override
  String get modified => 'GEÄNDERT';

  @override
  String get unsavedChanges => 'Ungespeicherte Änderungen';

  @override
  String get unsavedChangesMessage =>
      'Du hast ungespeicherte Änderungen. Möchtest du ohne Speichern verlassen?';

  @override
  String get stay => 'Bleiben';

  @override
  String get exit => 'Verlassen';

  @override
  String get saveChanges => 'Änderungen speichern';

  @override
  String get productUpdated => 'Produkt aktualisiert!';

  @override
  String nActive(int count) {
    return '$count AKTIV';
  }

  @override
  String get all => 'Alle';

  @override
  String get inProgress => 'In Bearbeitung';

  @override
  String get delivered => 'Zugestellt';

  @override
  String get noShipments => 'Keine Sendungen';

  @override
  String get addTrackingWhenRegistering =>
      'Füge einen Tracking-Code hinzu, wenn du\neinen Einkauf oder Verkauf erfasst';

  @override
  String get deleteShipment => 'Sendung löschen';

  @override
  String confirmDeleteShipment(String code) {
    return 'Sendung $code löschen?';
  }

  @override
  String get codeCopied => 'Code kopiert!';

  @override
  String get track => 'Verfolgen';

  @override
  String get ship24 => 'SHIP24';

  @override
  String lastUpdate(String time) {
    return 'Letzte Akt.: $time';
  }

  @override
  String updated(String status) {
    return 'Aktualisiert: $status';
  }

  @override
  String get purchase => 'EINKAUF';

  @override
  String get sale => 'VERKAUF';

  @override
  String get tracking => 'Sendungsverfolgung';

  @override
  String get refreshFromShip24 => 'Von Ship24 aktualisieren';

  @override
  String get trackingTimeline => 'TRACKING-VERLAUF';

  @override
  String nEvents(int count) {
    return '$count Ereignisse';
  }

  @override
  String get noTrackingEvents => 'Keine Tracking-Ereignisse';

  @override
  String get pressRefreshToUpdate =>
      'Drücke den 🔄-Button, um den\nStatus von Ship24 zu aktualisieren';

  @override
  String openOn(String carrier) {
    return 'Öffnen auf $carrier';
  }

  @override
  String statusUpdated(String status) {
    return 'Status aktualisiert: $status';
  }

  @override
  String get pending => 'Ausstehend';

  @override
  String get inTransit => 'Unterwegs';

  @override
  String get deliveredStatus => 'Zugestellt';

  @override
  String get problem => 'Problem';

  @override
  String get unknown => 'Unbekannt';

  @override
  String get today => 'Heute';

  @override
  String get yesterday => 'Gestern';

  @override
  String get now => 'Jetzt';

  @override
  String minutesAgo(int count) {
    return 'vor ${count}m';
  }

  @override
  String hoursAgo(int count) {
    return 'vor ${count}h';
  }

  @override
  String daysAgo(int count) {
    return 'vor ${count}T';
  }

  @override
  String error(String message) {
    return 'Fehler: $message';
  }

  @override
  String get financialOverview => 'Finanzübersicht';

  @override
  String get totalRevenueLabel => 'Gesamteinnahmen';

  @override
  String get totalSpentLabel => 'Gesamtausgaben';

  @override
  String get netProfit => 'Nettogewinn';

  @override
  String get roi => 'ROI';

  @override
  String get salesSection => 'Verkäufe';

  @override
  String get salesCount => 'Anz. Verkäufe';

  @override
  String get avgProfitLabel => 'Durchschnittlicher Gewinn';

  @override
  String get totalFees => 'Gesamtgebühren';

  @override
  String get bestSale => 'BESTER VERKAUF';

  @override
  String get purchasesSection => 'Einkäufe';

  @override
  String get purchasesCount => 'Anz. Einkäufe';

  @override
  String get inventoryValue => 'Inventarwert';

  @override
  String get totalPieces => 'Gesamtstücke';

  @override
  String get financialBreakdown => 'Finanzaufschlüsselung';

  @override
  String get salesRevenue => 'Verkaufseinnahmen';

  @override
  String get purchaseCosts => 'Einkaufskosten';

  @override
  String get feesPaid => 'Gezahlte Gebühren';

  @override
  String get netProfitLabel => 'NETTOGEWINN';

  @override
  String get costsLegend => 'Kosten';

  @override
  String get feesLegend => 'Gebühren';

  @override
  String get profitLegend => 'Gewinn';

  @override
  String get fullOverview =>
      'Vollständige Übersicht über Einkäufe und Verkäufe';

  @override
  String get export => 'Exportieren';

  @override
  String get csvFullHistory => 'CSV Full History';

  @override
  String get pdfTaxSummary => 'PDF Tax Summary';

  @override
  String get monthlySalesLog => 'Monthly Sales Log';

  @override
  String get salesHistory => 'Verkaufshistorie';

  @override
  String get purchasesHistory => 'Einkaufshistorie';

  @override
  String get account => 'Konto';

  @override
  String get resetViaEmail => 'Per Email zurücksetzen';

  @override
  String get twoFactorAuth => '2FA-Authentifizierung';

  @override
  String get notAvailable => 'Nicht verfügbar';

  @override
  String get twoFactorTitle => 'Zwei-Faktor-Authentifizierung';

  @override
  String get twoFactorDescription =>
      '2FA wird in einem zukünftigen Update verfügbar sein.\n\nVerwende bis dahin ein sicheres Passwort.';

  @override
  String get workspaceActive => 'Aktiver Workspace';

  @override
  String get selectWorkspace => 'Workspace auswählen';

  @override
  String get autoBackup => 'Automatische Sicherung';

  @override
  String get syncDataCloud => 'Daten in der Cloud synchronisieren';

  @override
  String get exportAllData => 'Alle Daten exportieren';

  @override
  String get csvPdfJson => 'CSV, PDF, JSON';

  @override
  String get notificationsInApp => 'In-App-Benachrichtigungen';

  @override
  String get salesShipmentAlerts => 'Verkaufs- und Versandwarnungen';

  @override
  String get pushNotifications => 'Push-Benachrichtigungen';

  @override
  String get receiveOnMobile => 'Auf dem Handy empfangen';

  @override
  String get emailDigest => 'Email Digest';

  @override
  String get weeklyReport => 'Wöchentlicher Bericht';

  @override
  String get appearance => 'Erscheinungsbild';

  @override
  String get darkMode => 'Dunkler Modus';

  @override
  String get useDarkTheme => 'Dunkles Design verwenden';

  @override
  String get fontSize => 'Schriftgröße';

  @override
  String get accentColor => 'Akzentfarbe';

  @override
  String get blueViolet => 'Blau-Violett';

  @override
  String get green => 'Grün';

  @override
  String get orange => 'Orange';

  @override
  String get info => 'Info';

  @override
  String get version => 'Version';

  @override
  String get termsOfService => 'Nutzungsbedingungen';

  @override
  String get privacyPolicy => 'Datenschutzrichtlinie';

  @override
  String get reportBug => 'Fehler melden';

  @override
  String get describeProblem => 'Beschreibe das Problem...';

  @override
  String get logout => 'Abmelden';

  @override
  String get confirmLogout => 'Bist du sicher, dass du dich abmelden möchtest?';

  @override
  String get proPlan => 'PRO PLAN';

  @override
  String get userName => 'Benutzername';

  @override
  String get close => 'Schließen';

  @override
  String get save => 'Speichern';

  @override
  String fieldUpdated(String field) {
    return '$field aktualisiert!';
  }

  @override
  String get verificationSent => 'Bestätigung an die neue Email gesendet';

  @override
  String resetEmailSent(String email) {
    return 'Zurücksetzungs-Email an $email gesendet';
  }

  @override
  String exportStarted(String format) {
    return '$format-Export gestartet!';
  }

  @override
  String get exportData => 'Daten exportieren';

  @override
  String get chooseExportFormat => 'Exportformat wählen';

  @override
  String get allRecordsCsv => 'Alle Einträge im CSV-Format';

  @override
  String get formattedReport => 'Formatierter Bericht zum Drucken';

  @override
  String get rawDataJson => 'Rohdaten im JSON-Format';

  @override
  String get termsContent =>
      'Vault Reselling Tracker — Nutzungsbedingungen\n\nDurch die Nutzung dieser App akzeptierst du die folgenden Bedingungen:\n\n1. Die App wird \"wie besehen\" ohne Garantien bereitgestellt.\n2. Die eingegebenen Daten liegen in deiner Verantwortung.\n3. Wir haften nicht für Verluste, die durch die Nutzung der App entstehen.\n4. Die Daten werden auf Firebase Cloud gespeichert.\n5. Du kannst deine Daten jederzeit exportieren und löschen.\n\nLetzte Aktualisierung: Januar 2025';

  @override
  String get privacyContent =>
      'Deine Privatsphäre ist uns wichtig.\n\n• Daten werden sicher auf Firebase gespeichert\n• Authentifizierung wird von Firebase Auth verwaltet\n• Wir teilen keine Informationen mit Dritten\n• Du kannst jederzeit die Löschung deiner Daten beantragen\n\nBei Fragen: privacy@vault-app.com';

  @override
  String nUnread(int count) {
    return '$count UNGELESEN';
  }

  @override
  String get markAllRead => 'Alle als gelesen markieren';

  @override
  String get clearAll => 'Alle löschen';

  @override
  String get deleteAll => 'Alles löschen';

  @override
  String get deleteAllNotifications => 'Alle Benachrichtigungen löschen?';

  @override
  String get noNotifications => 'Keine Benachrichtigungen';

  @override
  String get notificationsWillAppearHere =>
      'Tracking- und Verkaufsbenachrichtigungen\nwerden hier angezeigt';

  @override
  String get shipmentType => 'SENDUNG';

  @override
  String get saleType => 'VERKAUF';

  @override
  String get lowStockType => 'NIEDRIGER BESTAND';

  @override
  String get systemType => 'SYSTEM';

  @override
  String get addTracking => '+ Tracking hinzufügen (optional)';

  @override
  String get trackingShipment => 'SENDUNGSVERFOLGUNG';

  @override
  String get remove => 'Entfernen';

  @override
  String carrierDetected(String name) {
    return 'Versanddienstleister erkannt: $name';
  }

  @override
  String get trackingHint => 'Z.B. RR123456789IT';

  @override
  String soldAt(String price) {
    return 'Verkauft für €$price';
  }

  @override
  String costLabel(String price) {
    return 'Kosten €$price';
  }

  @override
  String feeLabel(String price) {
    return 'Fee €$price';
  }

  @override
  String get costUpperCase => 'KOSTEN';

  @override
  String qty(String qty) {
    return 'Menge: $qty';
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
