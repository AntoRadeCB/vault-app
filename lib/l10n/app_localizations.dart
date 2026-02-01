import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('it'),
    Locale('pt'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In it, this message translates to:
  /// **'Vault - Reselling Tracker'**
  String get appTitle;

  /// No description provided for @vault.
  ///
  /// In it, this message translates to:
  /// **'Vault'**
  String get vault;

  /// No description provided for @resellingTracker.
  ///
  /// In it, this message translates to:
  /// **'Reselling Tracker'**
  String get resellingTracker;

  /// No description provided for @dashboard.
  ///
  /// In it, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @inventory.
  ///
  /// In it, this message translates to:
  /// **'Inventario'**
  String get inventory;

  /// No description provided for @shipments.
  ///
  /// In it, this message translates to:
  /// **'Spedizioni'**
  String get shipments;

  /// No description provided for @reports.
  ///
  /// In it, this message translates to:
  /// **'Reports'**
  String get reports;

  /// No description provided for @settings.
  ///
  /// In it, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @notifications.
  ///
  /// In it, this message translates to:
  /// **'Notifiche'**
  String get notifications;

  /// No description provided for @home.
  ///
  /// In it, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @systemOnline.
  ///
  /// In it, this message translates to:
  /// **'System Online'**
  String get systemOnline;

  /// No description provided for @searchItemsReports.
  ///
  /// In it, this message translates to:
  /// **'Cerca oggetti, report...'**
  String get searchItemsReports;

  /// No description provided for @newItem.
  ///
  /// In it, this message translates to:
  /// **'Nuovo Oggetto'**
  String get newItem;

  /// No description provided for @online.
  ///
  /// In it, this message translates to:
  /// **'ONLINE'**
  String get online;

  /// No description provided for @login.
  ///
  /// In it, this message translates to:
  /// **'Accedi'**
  String get login;

  /// No description provided for @register.
  ///
  /// In it, this message translates to:
  /// **'Registrati'**
  String get register;

  /// No description provided for @email.
  ///
  /// In it, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In it, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @confirmPassword.
  ///
  /// In it, this message translates to:
  /// **'Conferma Password'**
  String get confirmPassword;

  /// No description provided for @createAccount.
  ///
  /// In it, this message translates to:
  /// **'Crea Account'**
  String get createAccount;

  /// No description provided for @enterEmailAndPassword.
  ///
  /// In it, this message translates to:
  /// **'Inserisci email e password.'**
  String get enterEmailAndPassword;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In it, this message translates to:
  /// **'Le password non corrispondono.'**
  String get passwordsDoNotMatch;

  /// No description provided for @passwordMinLength.
  ///
  /// In it, this message translates to:
  /// **'La password deve avere almeno 6 caratteri.'**
  String get passwordMinLength;

  /// No description provided for @userNotFound.
  ///
  /// In it, this message translates to:
  /// **'Nessun utente trovato con questa email.'**
  String get userNotFound;

  /// No description provided for @wrongPassword.
  ///
  /// In it, this message translates to:
  /// **'Password errata.'**
  String get wrongPassword;

  /// No description provided for @invalidEmail.
  ///
  /// In it, this message translates to:
  /// **'Email non valida.'**
  String get invalidEmail;

  /// No description provided for @accountDisabled.
  ///
  /// In it, this message translates to:
  /// **'Account disabilitato.'**
  String get accountDisabled;

  /// No description provided for @emailAlreadyInUse.
  ///
  /// In it, this message translates to:
  /// **'Email già registrata.'**
  String get emailAlreadyInUse;

  /// No description provided for @weakPassword.
  ///
  /// In it, this message translates to:
  /// **'Password troppo debole (minimo 6 caratteri).'**
  String get weakPassword;

  /// No description provided for @invalidCredential.
  ///
  /// In it, this message translates to:
  /// **'Credenziali non valide.'**
  String get invalidCredential;

  /// No description provided for @unknownError.
  ///
  /// In it, this message translates to:
  /// **'Errore sconosciuto.'**
  String get unknownError;

  /// No description provided for @resellingVinted2025.
  ///
  /// In it, this message translates to:
  /// **'Reselling Vinted 2025'**
  String get resellingVinted2025;

  /// No description provided for @nItems.
  ///
  /// In it, this message translates to:
  /// **'{count} items'**
  String nItems(int count);

  /// No description provided for @capitaleImmobilizzato.
  ///
  /// In it, this message translates to:
  /// **'Capitale Immobilizzato'**
  String get capitaleImmobilizzato;

  /// No description provided for @ordiniInArrivo.
  ///
  /// In it, this message translates to:
  /// **'Ordini in Arrivo'**
  String get ordiniInArrivo;

  /// No description provided for @capitaleSpedito.
  ///
  /// In it, this message translates to:
  /// **'Capitale Spedito'**
  String get capitaleSpedito;

  /// No description provided for @profittoConsolidato.
  ///
  /// In it, this message translates to:
  /// **'Profitto Consolidato'**
  String get profittoConsolidato;

  /// No description provided for @totalSpent.
  ///
  /// In it, this message translates to:
  /// **'Totale Speso'**
  String get totalSpent;

  /// No description provided for @totalRevenue.
  ///
  /// In it, this message translates to:
  /// **'Totale Ricavi'**
  String get totalRevenue;

  /// No description provided for @avgProfit.
  ///
  /// In it, this message translates to:
  /// **'Media Profitto'**
  String get avgProfit;

  /// No description provided for @newPurchase.
  ///
  /// In it, this message translates to:
  /// **'Nuovo Acquisto'**
  String get newPurchase;

  /// No description provided for @registerSale.
  ///
  /// In it, this message translates to:
  /// **'Registra Vendita'**
  String get registerSale;

  /// No description provided for @recentSales.
  ///
  /// In it, this message translates to:
  /// **'Ultime Vendite'**
  String get recentSales;

  /// No description provided for @nTotal.
  ///
  /// In it, this message translates to:
  /// **'{count} totali'**
  String nTotal(int count);

  /// No description provided for @noSalesRegistered.
  ///
  /// In it, this message translates to:
  /// **'Nessuna vendita registrata'**
  String get noSalesRegistered;

  /// No description provided for @recentPurchases.
  ///
  /// In it, this message translates to:
  /// **'Ultimi Acquisti'**
  String get recentPurchases;

  /// No description provided for @noPurchasesRegistered.
  ///
  /// In it, this message translates to:
  /// **'Nessun acquisto registrato'**
  String get noPurchasesRegistered;

  /// No description provided for @operationalStatus.
  ///
  /// In it, this message translates to:
  /// **'Stato Operativo'**
  String get operationalStatus;

  /// No description provided for @nShipmentsInTransit.
  ///
  /// In it, this message translates to:
  /// **'{count} spedizioni in transito'**
  String nShipmentsInTransit(int count);

  /// No description provided for @nProductsOnSale.
  ///
  /// In it, this message translates to:
  /// **'{count} prodotti in vendita'**
  String nProductsOnSale(int count);

  /// No description provided for @lowStockProduct.
  ///
  /// In it, this message translates to:
  /// **'Stock basso: {name}'**
  String lowStockProduct(String name);

  /// No description provided for @noActiveAlerts.
  ///
  /// In it, this message translates to:
  /// **'Nessun avviso attivo'**
  String get noActiveAlerts;

  /// No description provided for @nRecords.
  ///
  /// In it, this message translates to:
  /// **'{count} RECORDS'**
  String nRecords(int count);

  /// No description provided for @historicalRecords.
  ///
  /// In it, this message translates to:
  /// **'Storico Record'**
  String get historicalRecords;

  /// No description provided for @productSummary.
  ///
  /// In it, this message translates to:
  /// **'Riepilogo Prodotti'**
  String get productSummary;

  /// No description provided for @searchProduct.
  ///
  /// In it, this message translates to:
  /// **'Cerca prodotto...'**
  String get searchProduct;

  /// No description provided for @noProducts.
  ///
  /// In it, this message translates to:
  /// **'Nessun prodotto'**
  String get noProducts;

  /// No description provided for @addYourFirstProduct.
  ///
  /// In it, this message translates to:
  /// **'Aggiungi il tuo primo prodotto!'**
  String get addYourFirstProduct;

  /// No description provided for @deleteProduct.
  ///
  /// In it, this message translates to:
  /// **'Elimina Prodotto'**
  String get deleteProduct;

  /// No description provided for @confirmDeleteProduct.
  ///
  /// In it, this message translates to:
  /// **'Sei sicuro di voler eliminare \"{name}\"?'**
  String confirmDeleteProduct(String name);

  /// No description provided for @cancel.
  ///
  /// In it, this message translates to:
  /// **'Annulla'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In it, this message translates to:
  /// **'Elimina'**
  String get delete;

  /// No description provided for @productDeleted.
  ///
  /// In it, this message translates to:
  /// **'{name} eliminato'**
  String productDeleted(String name);

  /// No description provided for @totalInventoryValue.
  ///
  /// In it, this message translates to:
  /// **'Valore Totale Inventario'**
  String get totalInventoryValue;

  /// No description provided for @shippedProducts.
  ///
  /// In it, this message translates to:
  /// **'Prodotti Spediti'**
  String get shippedProducts;

  /// No description provided for @inInventory.
  ///
  /// In it, this message translates to:
  /// **'In Inventario'**
  String get inInventory;

  /// No description provided for @onSale.
  ///
  /// In it, this message translates to:
  /// **'In Vendita'**
  String get onSale;

  /// No description provided for @itemName.
  ///
  /// In it, this message translates to:
  /// **'Nome Oggetto'**
  String get itemName;

  /// No description provided for @itemNameHint.
  ///
  /// In it, this message translates to:
  /// **'Es. Nike Air Max 90'**
  String get itemNameHint;

  /// No description provided for @brand.
  ///
  /// In it, this message translates to:
  /// **'Brand'**
  String get brand;

  /// No description provided for @brandHint.
  ///
  /// In it, this message translates to:
  /// **'Es. Nike, Adidas, Stone Island'**
  String get brandHint;

  /// No description provided for @purchasePrice.
  ///
  /// In it, this message translates to:
  /// **'Prezzo Acquisto (€)'**
  String get purchasePrice;

  /// No description provided for @quantity.
  ///
  /// In it, this message translates to:
  /// **'Quantità'**
  String get quantity;

  /// No description provided for @status.
  ///
  /// In it, this message translates to:
  /// **'Stato'**
  String get status;

  /// No description provided for @workspace.
  ///
  /// In it, this message translates to:
  /// **'Workspace'**
  String get workspace;

  /// No description provided for @shipped.
  ///
  /// In it, this message translates to:
  /// **'Spedito'**
  String get shipped;

  /// No description provided for @registerPurchase.
  ///
  /// In it, this message translates to:
  /// **'Registra Acquisto'**
  String get registerPurchase;

  /// No description provided for @purchaseRegistered.
  ///
  /// In it, this message translates to:
  /// **'Acquisto registrato con successo!'**
  String get purchaseRegistered;

  /// No description provided for @requiredField.
  ///
  /// In it, this message translates to:
  /// **'Campo obbligatorio'**
  String get requiredField;

  /// No description provided for @enterPrice.
  ///
  /// In it, this message translates to:
  /// **'Inserisci un prezzo'**
  String get enterPrice;

  /// No description provided for @invalidPrice.
  ///
  /// In it, this message translates to:
  /// **'Prezzo non valido'**
  String get invalidPrice;

  /// No description provided for @enterQuantity.
  ///
  /// In it, this message translates to:
  /// **'Inserisci una quantità'**
  String get enterQuantity;

  /// No description provided for @invalidQuantity.
  ///
  /// In it, this message translates to:
  /// **'Quantità non valida'**
  String get invalidQuantity;

  /// No description provided for @barcode.
  ///
  /// In it, this message translates to:
  /// **'BARCODE'**
  String get barcode;

  /// No description provided for @productFound.
  ///
  /// In it, this message translates to:
  /// **'Prodotto trovato: {name}'**
  String productFound(String name);

  /// No description provided for @barcodeScanned.
  ///
  /// In it, this message translates to:
  /// **'Barcode: {code} — compila i dati del prodotto'**
  String barcodeScanned(String code);

  /// No description provided for @product.
  ///
  /// In it, this message translates to:
  /// **'Prodotto'**
  String get product;

  /// No description provided for @scanBarcodeProduct.
  ///
  /// In it, this message translates to:
  /// **'Scansiona Barcode Prodotto'**
  String get scanBarcodeProduct;

  /// No description provided for @selectProduct.
  ///
  /// In it, this message translates to:
  /// **'Seleziona prodotto...'**
  String get selectProduct;

  /// No description provided for @noProductsInInventory.
  ///
  /// In it, this message translates to:
  /// **'Nessun prodotto in inventario'**
  String get noProductsInInventory;

  /// No description provided for @salePrice.
  ///
  /// In it, this message translates to:
  /// **'Prezzo di Vendita (€)'**
  String get salePrice;

  /// No description provided for @enterSalePrice.
  ///
  /// In it, this message translates to:
  /// **'Inserisci il prezzo di vendita'**
  String get enterSalePrice;

  /// No description provided for @feesShipping.
  ///
  /// In it, this message translates to:
  /// **'Commissioni / Spedizione (€)'**
  String get feesShipping;

  /// No description provided for @invalidValue.
  ///
  /// In it, this message translates to:
  /// **'Valore non valido'**
  String get invalidValue;

  /// No description provided for @removeFromInventory.
  ///
  /// In it, this message translates to:
  /// **'Rimuovi da inventario'**
  String get removeFromInventory;

  /// No description provided for @scaleOneUnit.
  ///
  /// In it, this message translates to:
  /// **'Scala 1 unità dal prodotto'**
  String get scaleOneUnit;

  /// No description provided for @saleSummary.
  ///
  /// In it, this message translates to:
  /// **'RIEPILOGO VENDITA'**
  String get saleSummary;

  /// No description provided for @salePriceLabel.
  ///
  /// In it, this message translates to:
  /// **'Prezzo vendita'**
  String get salePriceLabel;

  /// No description provided for @purchaseCost.
  ///
  /// In it, this message translates to:
  /// **'Costo acquisto'**
  String get purchaseCost;

  /// No description provided for @fees.
  ///
  /// In it, this message translates to:
  /// **'Commissioni'**
  String get fees;

  /// No description provided for @profit.
  ///
  /// In it, this message translates to:
  /// **'PROFITTO'**
  String get profit;

  /// No description provided for @confirmSale.
  ///
  /// In it, this message translates to:
  /// **'Conferma Vendita'**
  String get confirmSale;

  /// No description provided for @saleRegistered.
  ///
  /// In it, this message translates to:
  /// **'Vendita registrata! Profitto: €{profit}'**
  String saleRegistered(String profit);

  /// No description provided for @selectProductToSell.
  ///
  /// In it, this message translates to:
  /// **'Seleziona un prodotto da vendere.'**
  String get selectProductToSell;

  /// No description provided for @found.
  ///
  /// In it, this message translates to:
  /// **'Trovato: {name}'**
  String found(String name);

  /// No description provided for @noProductFoundBarcode.
  ///
  /// In it, this message translates to:
  /// **'Nessun prodotto trovato con barcode: {code}'**
  String noProductFoundBarcode(String code);

  /// No description provided for @editProduct.
  ///
  /// In it, this message translates to:
  /// **'Modifica Prodotto'**
  String get editProduct;

  /// No description provided for @modified.
  ///
  /// In it, this message translates to:
  /// **'MODIFICATO'**
  String get modified;

  /// No description provided for @unsavedChanges.
  ///
  /// In it, this message translates to:
  /// **'Modifiche non salvate'**
  String get unsavedChanges;

  /// No description provided for @unsavedChangesMessage.
  ///
  /// In it, this message translates to:
  /// **'Hai delle modifiche non salvate. Vuoi uscire senza salvare?'**
  String get unsavedChangesMessage;

  /// No description provided for @stay.
  ///
  /// In it, this message translates to:
  /// **'Resta'**
  String get stay;

  /// No description provided for @exit.
  ///
  /// In it, this message translates to:
  /// **'Esci'**
  String get exit;

  /// No description provided for @saveChanges.
  ///
  /// In it, this message translates to:
  /// **'Salva Modifiche'**
  String get saveChanges;

  /// No description provided for @productUpdated.
  ///
  /// In it, this message translates to:
  /// **'Prodotto aggiornato!'**
  String get productUpdated;

  /// No description provided for @nActive.
  ///
  /// In it, this message translates to:
  /// **'{count} ATTIVE'**
  String nActive(int count);

  /// No description provided for @all.
  ///
  /// In it, this message translates to:
  /// **'Tutte'**
  String get all;

  /// No description provided for @inProgress.
  ///
  /// In it, this message translates to:
  /// **'In Corso'**
  String get inProgress;

  /// No description provided for @delivered.
  ///
  /// In it, this message translates to:
  /// **'Consegnate'**
  String get delivered;

  /// No description provided for @noShipments.
  ///
  /// In it, this message translates to:
  /// **'Nessuna spedizione'**
  String get noShipments;

  /// No description provided for @addTrackingWhenRegistering.
  ///
  /// In it, this message translates to:
  /// **'Aggiungi un codice tracking quando registri\nun acquisto o una vendita'**
  String get addTrackingWhenRegistering;

  /// No description provided for @deleteShipment.
  ///
  /// In it, this message translates to:
  /// **'Elimina Spedizione'**
  String get deleteShipment;

  /// No description provided for @confirmDeleteShipment.
  ///
  /// In it, this message translates to:
  /// **'Eliminare la spedizione {code}?'**
  String confirmDeleteShipment(String code);

  /// No description provided for @codeCopied.
  ///
  /// In it, this message translates to:
  /// **'Codice copiato!'**
  String get codeCopied;

  /// No description provided for @track.
  ///
  /// In it, this message translates to:
  /// **'Traccia'**
  String get track;

  /// No description provided for @ship24.
  ///
  /// In it, this message translates to:
  /// **'SHIP24'**
  String get ship24;

  /// No description provided for @lastUpdate.
  ///
  /// In it, this message translates to:
  /// **'Ultimo agg: {time}'**
  String lastUpdate(String time);

  /// No description provided for @updated.
  ///
  /// In it, this message translates to:
  /// **'Aggiornato: {status}'**
  String updated(String status);

  /// No description provided for @purchase.
  ///
  /// In it, this message translates to:
  /// **'ACQUISTO'**
  String get purchase;

  /// No description provided for @sale.
  ///
  /// In it, this message translates to:
  /// **'VENDITA'**
  String get sale;

  /// No description provided for @tracking.
  ///
  /// In it, this message translates to:
  /// **'Tracciamento'**
  String get tracking;

  /// No description provided for @refreshFromShip24.
  ///
  /// In it, this message translates to:
  /// **'Aggiorna da Ship24'**
  String get refreshFromShip24;

  /// No description provided for @trackingTimeline.
  ///
  /// In it, this message translates to:
  /// **'CRONOLOGIA TRACKING'**
  String get trackingTimeline;

  /// No description provided for @nEvents.
  ///
  /// In it, this message translates to:
  /// **'{count} eventi'**
  String nEvents(int count);

  /// No description provided for @noTrackingEvents.
  ///
  /// In it, this message translates to:
  /// **'Nessun evento di tracking'**
  String get noTrackingEvents;

  /// No description provided for @pressRefreshToUpdate.
  ///
  /// In it, this message translates to:
  /// **'Premi il bottone 🔄 per aggiornare\nlo stato da Ship24'**
  String get pressRefreshToUpdate;

  /// No description provided for @openOn.
  ///
  /// In it, this message translates to:
  /// **'Apri su {carrier}'**
  String openOn(String carrier);

  /// No description provided for @statusUpdated.
  ///
  /// In it, this message translates to:
  /// **'Stato aggiornato: {status}'**
  String statusUpdated(String status);

  /// No description provided for @pending.
  ///
  /// In it, this message translates to:
  /// **'In attesa'**
  String get pending;

  /// No description provided for @inTransit.
  ///
  /// In it, this message translates to:
  /// **'In transito'**
  String get inTransit;

  /// No description provided for @deliveredStatus.
  ///
  /// In it, this message translates to:
  /// **'Consegnato'**
  String get deliveredStatus;

  /// No description provided for @problem.
  ///
  /// In it, this message translates to:
  /// **'Problema'**
  String get problem;

  /// No description provided for @unknown.
  ///
  /// In it, this message translates to:
  /// **'Sconosciuto'**
  String get unknown;

  /// No description provided for @today.
  ///
  /// In it, this message translates to:
  /// **'Oggi'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In it, this message translates to:
  /// **'Ieri'**
  String get yesterday;

  /// No description provided for @now.
  ///
  /// In it, this message translates to:
  /// **'Adesso'**
  String get now;

  /// No description provided for @minutesAgo.
  ///
  /// In it, this message translates to:
  /// **'{count}m fa'**
  String minutesAgo(int count);

  /// No description provided for @hoursAgo.
  ///
  /// In it, this message translates to:
  /// **'{count}h fa'**
  String hoursAgo(int count);

  /// No description provided for @daysAgo.
  ///
  /// In it, this message translates to:
  /// **'{count}g fa'**
  String daysAgo(int count);

  /// No description provided for @error.
  ///
  /// In it, this message translates to:
  /// **'Errore: {message}'**
  String error(String message);

  /// No description provided for @financialOverview.
  ///
  /// In it, this message translates to:
  /// **'Overview Finanziaria'**
  String get financialOverview;

  /// No description provided for @totalRevenueLabel.
  ///
  /// In it, this message translates to:
  /// **'Ricavi Totali'**
  String get totalRevenueLabel;

  /// No description provided for @totalSpentLabel.
  ///
  /// In it, this message translates to:
  /// **'Totale Speso'**
  String get totalSpentLabel;

  /// No description provided for @netProfit.
  ///
  /// In it, this message translates to:
  /// **'Profitto Netto'**
  String get netProfit;

  /// No description provided for @roi.
  ///
  /// In it, this message translates to:
  /// **'ROI'**
  String get roi;

  /// No description provided for @salesSection.
  ///
  /// In it, this message translates to:
  /// **'Vendite'**
  String get salesSection;

  /// No description provided for @salesCount.
  ///
  /// In it, this message translates to:
  /// **'N° Vendite'**
  String get salesCount;

  /// No description provided for @avgProfitLabel.
  ///
  /// In it, this message translates to:
  /// **'Media Profitto'**
  String get avgProfitLabel;

  /// No description provided for @totalFees.
  ///
  /// In it, this message translates to:
  /// **'Totale Fee'**
  String get totalFees;

  /// No description provided for @bestSale.
  ///
  /// In it, this message translates to:
  /// **'MIGLIOR VENDITA'**
  String get bestSale;

  /// No description provided for @purchasesSection.
  ///
  /// In it, this message translates to:
  /// **'Acquisti'**
  String get purchasesSection;

  /// No description provided for @purchasesCount.
  ///
  /// In it, this message translates to:
  /// **'N° Acquisti'**
  String get purchasesCount;

  /// No description provided for @inventoryValue.
  ///
  /// In it, this message translates to:
  /// **'Valore Inventario'**
  String get inventoryValue;

  /// No description provided for @totalPieces.
  ///
  /// In it, this message translates to:
  /// **'Pezzi Totali'**
  String get totalPieces;

  /// No description provided for @financialBreakdown.
  ///
  /// In it, this message translates to:
  /// **'Breakdown Finanziario'**
  String get financialBreakdown;

  /// No description provided for @salesRevenue.
  ///
  /// In it, this message translates to:
  /// **'Ricavi vendite'**
  String get salesRevenue;

  /// No description provided for @purchaseCosts.
  ///
  /// In it, this message translates to:
  /// **'Costi acquisto'**
  String get purchaseCosts;

  /// No description provided for @feesPaid.
  ///
  /// In it, this message translates to:
  /// **'Commissioni pagate'**
  String get feesPaid;

  /// No description provided for @netProfitLabel.
  ///
  /// In it, this message translates to:
  /// **'PROFITTO NETTO'**
  String get netProfitLabel;

  /// No description provided for @costsLegend.
  ///
  /// In it, this message translates to:
  /// **'Costi'**
  String get costsLegend;

  /// No description provided for @feesLegend.
  ///
  /// In it, this message translates to:
  /// **'Fee'**
  String get feesLegend;

  /// No description provided for @profitLegend.
  ///
  /// In it, this message translates to:
  /// **'Profitto'**
  String get profitLegend;

  /// No description provided for @fullOverview.
  ///
  /// In it, this message translates to:
  /// **'Panoramica completa acquisti e vendite'**
  String get fullOverview;

  /// No description provided for @export.
  ///
  /// In it, this message translates to:
  /// **'Esporta'**
  String get export;

  /// No description provided for @csvFullHistory.
  ///
  /// In it, this message translates to:
  /// **'CSV Full History'**
  String get csvFullHistory;

  /// No description provided for @pdfTaxSummary.
  ///
  /// In it, this message translates to:
  /// **'PDF Tax Summary'**
  String get pdfTaxSummary;

  /// No description provided for @monthlySalesLog.
  ///
  /// In it, this message translates to:
  /// **'Monthly Sales Log'**
  String get monthlySalesLog;

  /// No description provided for @salesHistory.
  ///
  /// In it, this message translates to:
  /// **'Storico Vendite'**
  String get salesHistory;

  /// No description provided for @purchasesHistory.
  ///
  /// In it, this message translates to:
  /// **'Storico Acquisti'**
  String get purchasesHistory;

  /// No description provided for @account.
  ///
  /// In it, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @resetViaEmail.
  ///
  /// In it, this message translates to:
  /// **'Reset via email'**
  String get resetViaEmail;

  /// No description provided for @twoFactorAuth.
  ///
  /// In it, this message translates to:
  /// **'2FA Authentication'**
  String get twoFactorAuth;

  /// No description provided for @notAvailable.
  ///
  /// In it, this message translates to:
  /// **'Non disponibile'**
  String get notAvailable;

  /// No description provided for @twoFactorTitle.
  ///
  /// In it, this message translates to:
  /// **'Autenticazione a 2 Fattori'**
  String get twoFactorTitle;

  /// No description provided for @twoFactorDescription.
  ///
  /// In it, this message translates to:
  /// **'La 2FA sarà disponibile in un prossimo aggiornamento.\n\nPer ora, assicurati di usare una password sicura.'**
  String get twoFactorDescription;

  /// No description provided for @workspaceActive.
  ///
  /// In it, this message translates to:
  /// **'Workspace Attivo'**
  String get workspaceActive;

  /// No description provided for @selectWorkspace.
  ///
  /// In it, this message translates to:
  /// **'Seleziona Workspace'**
  String get selectWorkspace;

  /// No description provided for @autoBackup.
  ///
  /// In it, this message translates to:
  /// **'Auto Backup'**
  String get autoBackup;

  /// No description provided for @syncDataCloud.
  ///
  /// In it, this message translates to:
  /// **'Sincronizza dati su cloud'**
  String get syncDataCloud;

  /// No description provided for @exportAllData.
  ///
  /// In it, this message translates to:
  /// **'Esporta Tutti i Dati'**
  String get exportAllData;

  /// No description provided for @csvPdfJson.
  ///
  /// In it, this message translates to:
  /// **'CSV, PDF, JSON'**
  String get csvPdfJson;

  /// No description provided for @notificationsInApp.
  ///
  /// In it, this message translates to:
  /// **'Notifiche In-App'**
  String get notificationsInApp;

  /// No description provided for @salesShipmentAlerts.
  ///
  /// In it, this message translates to:
  /// **'Avvisi vendite e spedizioni'**
  String get salesShipmentAlerts;

  /// No description provided for @pushNotifications.
  ///
  /// In it, this message translates to:
  /// **'Push Notifications'**
  String get pushNotifications;

  /// No description provided for @receiveOnMobile.
  ///
  /// In it, this message translates to:
  /// **'Ricevi su mobile'**
  String get receiveOnMobile;

  /// No description provided for @emailDigest.
  ///
  /// In it, this message translates to:
  /// **'Email Digest'**
  String get emailDigest;

  /// No description provided for @weeklyReport.
  ///
  /// In it, this message translates to:
  /// **'Report settimanale'**
  String get weeklyReport;

  /// No description provided for @appearance.
  ///
  /// In it, this message translates to:
  /// **'Aspetto'**
  String get appearance;

  /// No description provided for @darkMode.
  ///
  /// In it, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @useDarkTheme.
  ///
  /// In it, this message translates to:
  /// **'Usa tema scuro'**
  String get useDarkTheme;

  /// No description provided for @fontSize.
  ///
  /// In it, this message translates to:
  /// **'Dimensione Font'**
  String get fontSize;

  /// No description provided for @accentColor.
  ///
  /// In it, this message translates to:
  /// **'Colore Accento'**
  String get accentColor;

  /// No description provided for @blueViolet.
  ///
  /// In it, this message translates to:
  /// **'Blu-Viola'**
  String get blueViolet;

  /// No description provided for @green.
  ///
  /// In it, this message translates to:
  /// **'Verde'**
  String get green;

  /// No description provided for @orange.
  ///
  /// In it, this message translates to:
  /// **'Arancione'**
  String get orange;

  /// No description provided for @info.
  ///
  /// In it, this message translates to:
  /// **'Info'**
  String get info;

  /// No description provided for @version.
  ///
  /// In it, this message translates to:
  /// **'Versione'**
  String get version;

  /// No description provided for @termsOfService.
  ///
  /// In it, this message translates to:
  /// **'Termini di Servizio'**
  String get termsOfService;

  /// No description provided for @privacyPolicy.
  ///
  /// In it, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @reportBug.
  ///
  /// In it, this message translates to:
  /// **'Segnala un Bug'**
  String get reportBug;

  /// No description provided for @describeProblem.
  ///
  /// In it, this message translates to:
  /// **'Descrivi il problema...'**
  String get describeProblem;

  /// No description provided for @logout.
  ///
  /// In it, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @confirmLogout.
  ///
  /// In it, this message translates to:
  /// **'Sei sicuro di voler uscire dal tuo account?'**
  String get confirmLogout;

  /// No description provided for @proPlan.
  ///
  /// In it, this message translates to:
  /// **'PRO PLAN'**
  String get proPlan;

  /// No description provided for @userName.
  ///
  /// In it, this message translates to:
  /// **'Nome Utente'**
  String get userName;

  /// No description provided for @close.
  ///
  /// In it, this message translates to:
  /// **'Chiudi'**
  String get close;

  /// No description provided for @save.
  ///
  /// In it, this message translates to:
  /// **'Salva'**
  String get save;

  /// No description provided for @fieldUpdated.
  ///
  /// In it, this message translates to:
  /// **'{field} aggiornato!'**
  String fieldUpdated(String field);

  /// No description provided for @verificationSent.
  ///
  /// In it, this message translates to:
  /// **'Verifica inviata alla nuova email'**
  String get verificationSent;

  /// No description provided for @resetEmailSent.
  ///
  /// In it, this message translates to:
  /// **'Email di reset inviata a {email}'**
  String resetEmailSent(String email);

  /// No description provided for @exportStarted.
  ///
  /// In it, this message translates to:
  /// **'Esportazione {format} avviata!'**
  String exportStarted(String format);

  /// No description provided for @exportData.
  ///
  /// In it, this message translates to:
  /// **'Esporta Dati'**
  String get exportData;

  /// No description provided for @chooseExportFormat.
  ///
  /// In it, this message translates to:
  /// **'Scegli il formato di esportazione'**
  String get chooseExportFormat;

  /// No description provided for @allRecordsCsv.
  ///
  /// In it, this message translates to:
  /// **'Tutti i record in formato CSV'**
  String get allRecordsCsv;

  /// No description provided for @formattedReport.
  ///
  /// In it, this message translates to:
  /// **'Report formattato per stampa'**
  String get formattedReport;

  /// No description provided for @rawDataJson.
  ///
  /// In it, this message translates to:
  /// **'Dati grezzi in formato JSON'**
  String get rawDataJson;

  /// No description provided for @termsContent.
  ///
  /// In it, this message translates to:
  /// **'Vault Reselling Tracker — Termini di Servizio\n\nUtilizzando questa app accetti i seguenti termini:\n\n1. L\'app è fornita \"così com\'è\" senza garanzie.\n2. I dati inseriti sono di tua responsabilità.\n3. Non siamo responsabili per perdite derivanti dall\'uso dell\'app.\n4. I dati sono archiviati su Firebase Cloud.\n5. Puoi esportare e cancellare i tuoi dati in qualsiasi momento.\n\nUltimo aggiornamento: Gennaio 2025'**
  String get termsContent;

  /// No description provided for @privacyContent.
  ///
  /// In it, this message translates to:
  /// **'La tua privacy è importante per noi.\n\n• I dati sono salvati in modo sicuro su Firebase\n• L\'autenticazione è gestita da Firebase Auth\n• Non condividiamo informazioni con terzi\n• Puoi richiedere la cancellazione dei dati in qualsiasi momento\n\nPer domande: privacy@vault-app.com'**
  String get privacyContent;

  /// No description provided for @nUnread.
  ///
  /// In it, this message translates to:
  /// **'{count} NON LETTE'**
  String nUnread(int count);

  /// No description provided for @markAllRead.
  ///
  /// In it, this message translates to:
  /// **'Segna tutte lette'**
  String get markAllRead;

  /// No description provided for @clearAll.
  ///
  /// In it, this message translates to:
  /// **'Cancella Tutte'**
  String get clearAll;

  /// No description provided for @deleteAll.
  ///
  /// In it, this message translates to:
  /// **'Elimina tutto'**
  String get deleteAll;

  /// No description provided for @deleteAllNotifications.
  ///
  /// In it, this message translates to:
  /// **'Eliminare tutte le notifiche?'**
  String get deleteAllNotifications;

  /// No description provided for @noNotifications.
  ///
  /// In it, this message translates to:
  /// **'Nessuna notifica'**
  String get noNotifications;

  /// No description provided for @notificationsWillAppearHere.
  ///
  /// In it, this message translates to:
  /// **'Le notifiche di tracking e vendite\nappariranno qui'**
  String get notificationsWillAppearHere;

  /// No description provided for @shipmentType.
  ///
  /// In it, this message translates to:
  /// **'SPEDIZIONE'**
  String get shipmentType;

  /// No description provided for @saleType.
  ///
  /// In it, this message translates to:
  /// **'VENDITA'**
  String get saleType;

  /// No description provided for @lowStockType.
  ///
  /// In it, this message translates to:
  /// **'STOCK BASSO'**
  String get lowStockType;

  /// No description provided for @systemType.
  ///
  /// In it, this message translates to:
  /// **'SISTEMA'**
  String get systemType;

  /// No description provided for @addTracking.
  ///
  /// In it, this message translates to:
  /// **'+ Aggiungi Tracking (facoltativo)'**
  String get addTracking;

  /// No description provided for @trackingShipment.
  ///
  /// In it, this message translates to:
  /// **'TRACKING SPEDIZIONE'**
  String get trackingShipment;

  /// No description provided for @remove.
  ///
  /// In it, this message translates to:
  /// **'Rimuovi'**
  String get remove;

  /// No description provided for @carrierDetected.
  ///
  /// In it, this message translates to:
  /// **'Corriere rilevato: {name}'**
  String carrierDetected(String name);

  /// No description provided for @trackingHint.
  ///
  /// In it, this message translates to:
  /// **'Es. RR123456789IT'**
  String get trackingHint;

  /// No description provided for @soldAt.
  ///
  /// In it, this message translates to:
  /// **'Venduto a €{price}'**
  String soldAt(String price);

  /// No description provided for @costLabel.
  ///
  /// In it, this message translates to:
  /// **'Costo €{price}'**
  String costLabel(String price);

  /// No description provided for @feeLabel.
  ///
  /// In it, this message translates to:
  /// **'Fee €{price}'**
  String feeLabel(String price);

  /// No description provided for @costUpperCase.
  ///
  /// In it, this message translates to:
  /// **'COSTO'**
  String get costUpperCase;

  /// No description provided for @qty.
  ///
  /// In it, this message translates to:
  /// **'Qta: {qty}'**
  String qty(String qty);

  /// No description provided for @small.
  ///
  /// In it, this message translates to:
  /// **'Small'**
  String get small;

  /// No description provided for @medium.
  ///
  /// In it, this message translates to:
  /// **'Medium'**
  String get medium;

  /// No description provided for @large.
  ///
  /// In it, this message translates to:
  /// **'Large'**
  String get large;

  /// No description provided for @extraLarge.
  ///
  /// In it, this message translates to:
  /// **'Extra Large'**
  String get extraLarge;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'de',
    'en',
    'es',
    'fr',
    'it',
    'pt',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'it':
      return AppLocalizationsIt();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
