// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'Vault - Reselling Tracker';

  @override
  String get vault => 'Vault';

  @override
  String get resellingTracker => 'Reselling Tracker';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get inventory => 'Inventario';

  @override
  String get shipments => 'Spedizioni';

  @override
  String get reports => 'Reports';

  @override
  String get settings => 'Settings';

  @override
  String get notifications => 'Notifiche';

  @override
  String get home => 'Home';

  @override
  String get systemOnline => 'System Online';

  @override
  String get searchItemsReports => 'Cerca oggetti, report...';

  @override
  String get newItem => 'Nuovo Oggetto';

  @override
  String get online => 'ONLINE';

  @override
  String get login => 'Accedi';

  @override
  String get register => 'Registrati';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get confirmPassword => 'Conferma Password';

  @override
  String get createAccount => 'Crea Account';

  @override
  String get enterEmailAndPassword => 'Inserisci email e password.';

  @override
  String get passwordsDoNotMatch => 'Le password non corrispondono.';

  @override
  String get passwordMinLength => 'La password deve avere almeno 6 caratteri.';

  @override
  String get userNotFound => 'Nessun utente trovato con questa email.';

  @override
  String get wrongPassword => 'Password errata.';

  @override
  String get invalidEmail => 'Email non valida.';

  @override
  String get accountDisabled => 'Account disabilitato.';

  @override
  String get emailAlreadyInUse => 'Email già registrata.';

  @override
  String get weakPassword => 'Password troppo debole (minimo 6 caratteri).';

  @override
  String get invalidCredential => 'Credenziali non valide.';

  @override
  String get unknownError => 'Errore sconosciuto.';

  @override
  String get resellingVinted2025 => 'Reselling Vinted 2025';

  @override
  String nItems(int count) {
    return '$count items';
  }

  @override
  String get capitaleImmobilizzato => 'Capitale Immobilizzato';

  @override
  String get ordiniInArrivo => 'Ordini in Arrivo';

  @override
  String get capitaleSpedito => 'Capitale Spedito';

  @override
  String get profittoConsolidato => 'Profitto Consolidato';

  @override
  String get totalSpent => 'Totale Speso';

  @override
  String get totalRevenue => 'Totale Ricavi';

  @override
  String get avgProfit => 'Media Profitto';

  @override
  String get newPurchase => 'Nuovo Acquisto';

  @override
  String get registerSale => 'Registra Vendita';

  @override
  String get recentSales => 'Ultime Vendite';

  @override
  String nTotal(int count) {
    return '$count totali';
  }

  @override
  String get noSalesRegistered => 'Nessuna vendita registrata';

  @override
  String get recentPurchases => 'Ultimi Acquisti';

  @override
  String get noPurchasesRegistered => 'Nessun acquisto registrato';

  @override
  String get operationalStatus => 'Stato Operativo';

  @override
  String nShipmentsInTransit(int count) {
    return '$count spedizioni in transito';
  }

  @override
  String nProductsOnSale(int count) {
    return '$count prodotti in vendita';
  }

  @override
  String lowStockProduct(String name) {
    return 'Stock basso: $name';
  }

  @override
  String get noActiveAlerts => 'Nessun avviso attivo';

  @override
  String nRecords(int count) {
    return '$count RECORDS';
  }

  @override
  String get historicalRecords => 'Storico Record';

  @override
  String get productSummary => 'Riepilogo Prodotti';

  @override
  String get searchProduct => 'Cerca prodotto...';

  @override
  String get noProducts => 'Nessun prodotto';

  @override
  String get addYourFirstProduct => 'Aggiungi il tuo primo prodotto!';

  @override
  String get deleteProduct => 'Elimina Prodotto';

  @override
  String confirmDeleteProduct(String name) {
    return 'Sei sicuro di voler eliminare \"$name\"?';
  }

  @override
  String get cancel => 'Annulla';

  @override
  String get delete => 'Elimina';

  @override
  String productDeleted(String name) {
    return '$name eliminato';
  }

  @override
  String get totalInventoryValue => 'Valore Totale Inventario';

  @override
  String get shippedProducts => 'Prodotti Spediti';

  @override
  String get inInventory => 'In Inventario';

  @override
  String get onSale => 'In Vendita';

  @override
  String get itemName => 'Nome Oggetto';

  @override
  String get itemNameHint => 'Es. Nike Air Max 90';

  @override
  String get brand => 'Brand';

  @override
  String get brandHint => 'Es. Nike, Adidas, Stone Island';

  @override
  String get purchasePrice => 'Prezzo Acquisto (€)';

  @override
  String get quantity => 'Quantità';

  @override
  String get status => 'Stato';

  @override
  String get workspace => 'Workspace';

  @override
  String get shipped => 'Spedito';

  @override
  String get registerPurchase => 'Registra Acquisto';

  @override
  String get purchaseRegistered => 'Acquisto registrato con successo!';

  @override
  String get requiredField => 'Campo obbligatorio';

  @override
  String get enterPrice => 'Inserisci un prezzo';

  @override
  String get invalidPrice => 'Prezzo non valido';

  @override
  String get enterQuantity => 'Inserisci una quantità';

  @override
  String get invalidQuantity => 'Quantità non valida';

  @override
  String get barcode => 'BARCODE';

  @override
  String productFound(String name) {
    return 'Prodotto trovato: $name';
  }

  @override
  String barcodeScanned(String code) {
    return 'Barcode: $code — compila i dati del prodotto';
  }

  @override
  String get product => 'Prodotto';

  @override
  String get scanBarcodeProduct => 'Scansiona Barcode Prodotto';

  @override
  String get selectProduct => 'Seleziona prodotto...';

  @override
  String get noProductsInInventory => 'Nessun prodotto in inventario';

  @override
  String get salePrice => 'Prezzo di Vendita (€)';

  @override
  String get enterSalePrice => 'Inserisci il prezzo di vendita';

  @override
  String get feesShipping => 'Commissioni / Spedizione (€)';

  @override
  String get invalidValue => 'Valore non valido';

  @override
  String get removeFromInventory => 'Rimuovi da inventario';

  @override
  String get scaleOneUnit => 'Scala 1 unità dal prodotto';

  @override
  String get saleSummary => 'RIEPILOGO VENDITA';

  @override
  String get salePriceLabel => 'Prezzo vendita';

  @override
  String get purchaseCost => 'Costo acquisto';

  @override
  String get fees => 'Commissioni';

  @override
  String get profit => 'PROFITTO';

  @override
  String get confirmSale => 'Conferma Vendita';

  @override
  String saleRegistered(String profit) {
    return 'Vendita registrata! Profitto: €$profit';
  }

  @override
  String get selectProductToSell => 'Seleziona un prodotto da vendere.';

  @override
  String found(String name) {
    return 'Trovato: $name';
  }

  @override
  String noProductFoundBarcode(String code) {
    return 'Nessun prodotto trovato con barcode: $code';
  }

  @override
  String get editProduct => 'Modifica Prodotto';

  @override
  String get modified => 'MODIFICATO';

  @override
  String get unsavedChanges => 'Modifiche non salvate';

  @override
  String get unsavedChangesMessage =>
      'Hai delle modifiche non salvate. Vuoi uscire senza salvare?';

  @override
  String get stay => 'Resta';

  @override
  String get exit => 'Esci';

  @override
  String get saveChanges => 'Salva Modifiche';

  @override
  String get productUpdated => 'Prodotto aggiornato!';

  @override
  String nActive(int count) {
    return '$count ATTIVE';
  }

  @override
  String get all => 'Tutte';

  @override
  String get inProgress => 'In Corso';

  @override
  String get delivered => 'Consegnate';

  @override
  String get noShipments => 'Nessuna spedizione';

  @override
  String get addTrackingWhenRegistering =>
      'Aggiungi un codice tracking quando registri\nun acquisto o una vendita';

  @override
  String get deleteShipment => 'Elimina Spedizione';

  @override
  String confirmDeleteShipment(String code) {
    return 'Eliminare la spedizione $code?';
  }

  @override
  String get codeCopied => 'Codice copiato!';

  @override
  String get track => 'Traccia';

  @override
  String get ship24 => 'SHIP24';

  @override
  String lastUpdate(String time) {
    return 'Ultimo agg: $time';
  }

  @override
  String updated(String status) {
    return 'Aggiornato: $status';
  }

  @override
  String get purchase => 'ACQUISTO';

  @override
  String get sale => 'VENDITA';

  @override
  String get tracking => 'Tracciamento';

  @override
  String get refreshFromShip24 => 'Aggiorna da Ship24';

  @override
  String get trackingTimeline => 'CRONOLOGIA TRACKING';

  @override
  String nEvents(int count) {
    return '$count eventi';
  }

  @override
  String get noTrackingEvents => 'Nessun evento di tracking';

  @override
  String get pressRefreshToUpdate =>
      'Premi il bottone 🔄 per aggiornare\nlo stato da Ship24';

  @override
  String openOn(String carrier) {
    return 'Apri su $carrier';
  }

  @override
  String statusUpdated(String status) {
    return 'Stato aggiornato: $status';
  }

  @override
  String get pending => 'In attesa';

  @override
  String get inTransit => 'In transito';

  @override
  String get deliveredStatus => 'Consegnato';

  @override
  String get problem => 'Problema';

  @override
  String get unknown => 'Sconosciuto';

  @override
  String get today => 'Oggi';

  @override
  String get yesterday => 'Ieri';

  @override
  String get now => 'Adesso';

  @override
  String minutesAgo(int count) {
    return '${count}m fa';
  }

  @override
  String hoursAgo(int count) {
    return '${count}h fa';
  }

  @override
  String daysAgo(int count) {
    return '${count}g fa';
  }

  @override
  String error(String message) {
    return 'Errore: $message';
  }

  @override
  String get financialOverview => 'Overview Finanziaria';

  @override
  String get totalRevenueLabel => 'Ricavi Totali';

  @override
  String get totalSpentLabel => 'Totale Speso';

  @override
  String get netProfit => 'Profitto Netto';

  @override
  String get roi => 'ROI';

  @override
  String get salesSection => 'Vendite';

  @override
  String get salesCount => 'N° Vendite';

  @override
  String get avgProfitLabel => 'Media Profitto';

  @override
  String get totalFees => 'Totale Fee';

  @override
  String get bestSale => 'MIGLIOR VENDITA';

  @override
  String get purchasesSection => 'Acquisti';

  @override
  String get purchasesCount => 'N° Acquisti';

  @override
  String get inventoryValue => 'Valore Inventario';

  @override
  String get totalPieces => 'Pezzi Totali';

  @override
  String get financialBreakdown => 'Breakdown Finanziario';

  @override
  String get salesRevenue => 'Ricavi vendite';

  @override
  String get purchaseCosts => 'Costi acquisto';

  @override
  String get feesPaid => 'Commissioni pagate';

  @override
  String get netProfitLabel => 'PROFITTO NETTO';

  @override
  String get costsLegend => 'Costi';

  @override
  String get feesLegend => 'Fee';

  @override
  String get profitLegend => 'Profitto';

  @override
  String get fullOverview => 'Panoramica completa acquisti e vendite';

  @override
  String get export => 'Esporta';

  @override
  String get csvFullHistory => 'CSV Full History';

  @override
  String get pdfTaxSummary => 'PDF Tax Summary';

  @override
  String get monthlySalesLog => 'Monthly Sales Log';

  @override
  String get salesHistory => 'Storico Vendite';

  @override
  String get purchasesHistory => 'Storico Acquisti';

  @override
  String get account => 'Account';

  @override
  String get resetViaEmail => 'Reset via email';

  @override
  String get twoFactorAuth => '2FA Authentication';

  @override
  String get notAvailable => 'Non disponibile';

  @override
  String get twoFactorTitle => 'Autenticazione a 2 Fattori';

  @override
  String get twoFactorDescription =>
      'La 2FA sarà disponibile in un prossimo aggiornamento.\n\nPer ora, assicurati di usare una password sicura.';

  @override
  String get workspaceActive => 'Workspace Attivo';

  @override
  String get selectWorkspace => 'Seleziona Workspace';

  @override
  String get autoBackup => 'Auto Backup';

  @override
  String get syncDataCloud => 'Sincronizza dati su cloud';

  @override
  String get exportAllData => 'Esporta Tutti i Dati';

  @override
  String get csvPdfJson => 'CSV, PDF, JSON';

  @override
  String get notificationsInApp => 'Notifiche In-App';

  @override
  String get salesShipmentAlerts => 'Avvisi vendite e spedizioni';

  @override
  String get pushNotifications => 'Push Notifications';

  @override
  String get receiveOnMobile => 'Ricevi su mobile';

  @override
  String get emailDigest => 'Email Digest';

  @override
  String get weeklyReport => 'Report settimanale';

  @override
  String get appearance => 'Aspetto';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get useDarkTheme => 'Usa tema scuro';

  @override
  String get fontSize => 'Dimensione Font';

  @override
  String get accentColor => 'Colore Accento';

  @override
  String get blueViolet => 'Blu-Viola';

  @override
  String get green => 'Verde';

  @override
  String get orange => 'Arancione';

  @override
  String get info => 'Info';

  @override
  String get version => 'Versione';

  @override
  String get termsOfService => 'Termini di Servizio';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get reportBug => 'Segnala un Bug';

  @override
  String get describeProblem => 'Descrivi il problema...';

  @override
  String get logout => 'Logout';

  @override
  String get confirmLogout => 'Sei sicuro di voler uscire dal tuo account?';

  @override
  String get proPlan => 'PRO PLAN';

  @override
  String get userName => 'Nome Utente';

  @override
  String get close => 'Chiudi';

  @override
  String get save => 'Salva';

  @override
  String fieldUpdated(String field) {
    return '$field aggiornato!';
  }

  @override
  String get verificationSent => 'Verifica inviata alla nuova email';

  @override
  String resetEmailSent(String email) {
    return 'Email di reset inviata a $email';
  }

  @override
  String exportStarted(String format) {
    return 'Esportazione $format avviata!';
  }

  @override
  String get exportData => 'Esporta Dati';

  @override
  String get chooseExportFormat => 'Scegli il formato di esportazione';

  @override
  String get allRecordsCsv => 'Tutti i record in formato CSV';

  @override
  String get formattedReport => 'Report formattato per stampa';

  @override
  String get rawDataJson => 'Dati grezzi in formato JSON';

  @override
  String get termsContent =>
      'Vault Reselling Tracker — Termini di Servizio\n\nUtilizzando questa app accetti i seguenti termini:\n\n1. L\'app è fornita \"così com\'è\" senza garanzie.\n2. I dati inseriti sono di tua responsabilità.\n3. Non siamo responsabili per perdite derivanti dall\'uso dell\'app.\n4. I dati sono archiviati su Firebase Cloud.\n5. Puoi esportare e cancellare i tuoi dati in qualsiasi momento.\n\nUltimo aggiornamento: Gennaio 2025';

  @override
  String get privacyContent =>
      'La tua privacy è importante per noi.\n\n• I dati sono salvati in modo sicuro su Firebase\n• L\'autenticazione è gestita da Firebase Auth\n• Non condividiamo informazioni con terzi\n• Puoi richiedere la cancellazione dei dati in qualsiasi momento\n\nPer domande: privacy@vault-app.com';

  @override
  String nUnread(int count) {
    return '$count NON LETTE';
  }

  @override
  String get markAllRead => 'Segna tutte lette';

  @override
  String get clearAll => 'Cancella Tutte';

  @override
  String get deleteAll => 'Elimina tutto';

  @override
  String get deleteAllNotifications => 'Eliminare tutte le notifiche?';

  @override
  String get noNotifications => 'Nessuna notifica';

  @override
  String get notificationsWillAppearHere =>
      'Le notifiche di tracking e vendite\nappariranno qui';

  @override
  String get shipmentType => 'SPEDIZIONE';

  @override
  String get saleType => 'VENDITA';

  @override
  String get lowStockType => 'STOCK BASSO';

  @override
  String get systemType => 'SISTEMA';

  @override
  String get addTracking => '+ Aggiungi Tracking (facoltativo)';

  @override
  String get trackingShipment => 'TRACKING SPEDIZIONE';

  @override
  String get remove => 'Rimuovi';

  @override
  String carrierDetected(String name) {
    return 'Corriere rilevato: $name';
  }

  @override
  String get trackingHint => 'Es. RR123456789IT';

  @override
  String soldAt(String price) {
    return 'Venduto a €$price';
  }

  @override
  String costLabel(String price) {
    return 'Costo €$price';
  }

  @override
  String feeLabel(String price) {
    return 'Fee €$price';
  }

  @override
  String get costUpperCase => 'COSTO';

  @override
  String qty(String qty) {
    return 'Qta: $qty';
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
