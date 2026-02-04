// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Vault - Reselling Tracker';

  @override
  String get vault => 'Vault';

  @override
  String get resellingTracker => 'Reselling Tracker';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get inventory => 'Inventory';

  @override
  String get shipments => 'Shipments';

  @override
  String get reports => 'Reports';

  @override
  String get settings => 'Settings';

  @override
  String get notifications => 'Notifications';

  @override
  String get home => 'Home';

  @override
  String get systemOnline => 'System Online';

  @override
  String get searchItemsReports => 'Search items, reports...';

  @override
  String get newItem => 'New Item';

  @override
  String get online => 'ONLINE';

  @override
  String get login => 'Login';

  @override
  String get register => 'Register';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get createAccount => 'Create Account';

  @override
  String get enterEmailAndPassword => 'Enter email and password.';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match.';

  @override
  String get passwordMinLength => 'Password must be at least 6 characters.';

  @override
  String get userNotFound => 'No user found with this email.';

  @override
  String get wrongPassword => 'Wrong password.';

  @override
  String get invalidEmail => 'Invalid email.';

  @override
  String get accountDisabled => 'Account disabled.';

  @override
  String get emailAlreadyInUse => 'Email already registered.';

  @override
  String get weakPassword => 'Password too weak (minimum 6 characters).';

  @override
  String get invalidCredential => 'Invalid credentials.';

  @override
  String get unknownError => 'Unknown error.';

  @override
  String get resellingVinted2025 => 'Reselling Vinted 2025';

  @override
  String nItems(int count) {
    return '$count items';
  }

  @override
  String get capitaleImmobilizzato => 'Tied-up Capital';

  @override
  String get ordiniInArrivo => 'Incoming Orders';

  @override
  String get capitaleSpedito => 'Shipped Capital';

  @override
  String get profittoConsolidato => 'Consolidated Profit';

  @override
  String get totalSpent => 'Total Spent';

  @override
  String get totalRevenue => 'Total Revenue';

  @override
  String get avgProfit => 'Average Profit';

  @override
  String get newPurchase => 'New Purchase';

  @override
  String get registerSale => 'Register Sale';

  @override
  String get recentSales => 'Recent Sales';

  @override
  String nTotal(int count) {
    return '$count total';
  }

  @override
  String get noSalesRegistered => 'No sales registered';

  @override
  String get recentPurchases => 'Recent Purchases';

  @override
  String get noPurchasesRegistered => 'No purchases registered';

  @override
  String get operationalStatus => 'Operational Status';

  @override
  String nShipmentsInTransit(int count) {
    return '$count shipments in transit';
  }

  @override
  String nProductsOnSale(int count) {
    return '$count products on sale';
  }

  @override
  String lowStockProduct(String name) {
    return 'Low stock: $name';
  }

  @override
  String get noActiveAlerts => 'No active alerts';

  @override
  String nRecords(int count) {
    return '$count RECORDS';
  }

  @override
  String get historicalRecords => 'Historical Records';

  @override
  String get productSummary => 'Product Summary';

  @override
  String get searchProduct => 'Search product...';

  @override
  String get noProducts => 'No products';

  @override
  String get addYourFirstProduct => 'Add your first product!';

  @override
  String get deleteProduct => 'Delete Product';

  @override
  String confirmDeleteProduct(String name) {
    return 'Are you sure you want to delete \"$name\"?';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String productDeleted(String name) {
    return '$name deleted';
  }

  @override
  String get totalInventoryValue => 'Total Inventory Value';

  @override
  String get shippedProducts => 'Shipped Products';

  @override
  String get inInventory => 'In Inventory';

  @override
  String get onSale => 'On Sale';

  @override
  String get itemName => 'Item Name';

  @override
  String get itemNameHint => 'E.g. Nike Air Max 90';

  @override
  String get brand => 'Brand';

  @override
  String get brandHint => 'E.g. Nike, Adidas, Stone Island';

  @override
  String get purchasePrice => 'Purchase Price (€)';

  @override
  String get quantity => 'Quantity';

  @override
  String get status => 'Status';

  @override
  String get workspace => 'Workspace';

  @override
  String get shipped => 'Shipped';

  @override
  String get registerPurchase => 'Register Purchase';

  @override
  String get purchaseRegistered => 'Purchase registered successfully!';

  @override
  String get requiredField => 'Required field';

  @override
  String get enterPrice => 'Enter a price';

  @override
  String get invalidPrice => 'Invalid price';

  @override
  String get enterQuantity => 'Enter a quantity';

  @override
  String get invalidQuantity => 'Invalid quantity';

  @override
  String get barcode => 'BARCODE';

  @override
  String productFound(String name) {
    return 'Product found: $name';
  }

  @override
  String barcodeScanned(String code) {
    return 'Barcode: $code — fill in the product details';
  }

  @override
  String get product => 'Product';

  @override
  String get scanBarcodeProduct => 'Scan Product Barcode';

  @override
  String get selectProduct => 'Select product...';

  @override
  String get noProductsInInventory => 'No products in inventory';

  @override
  String get salePrice => 'Sale Price (€)';

  @override
  String get enterSalePrice => 'Enter the sale price';

  @override
  String get feesShipping => 'Fees / Shipping (€)';

  @override
  String get invalidValue => 'Invalid value';

  @override
  String get removeFromInventory => 'Remove from inventory';

  @override
  String get scaleOneUnit => 'Deduct 1 unit from the product';

  @override
  String get saleSummary => 'SALE SUMMARY';

  @override
  String get salePriceLabel => 'Sale price';

  @override
  String get purchaseCost => 'Purchase cost';

  @override
  String get fees => 'Fees';

  @override
  String get profit => 'PROFIT';

  @override
  String get confirmSale => 'Confirm Sale';

  @override
  String saleRegistered(String profit) {
    return 'Sale registered! Profit: €$profit';
  }

  @override
  String get selectProductToSell => 'Select a product to sell.';

  @override
  String found(String name) {
    return 'Found: $name';
  }

  @override
  String noProductFoundBarcode(String code) {
    return 'No product found with barcode: $code';
  }

  @override
  String get editProduct => 'Edit Product';

  @override
  String get modified => 'MODIFIED';

  @override
  String get unsavedChanges => 'Unsaved changes';

  @override
  String get unsavedChangesMessage =>
      'You have unsaved changes. Do you want to leave without saving?';

  @override
  String get stay => 'Stay';

  @override
  String get exit => 'Exit';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get productUpdated => 'Product updated!';

  @override
  String nActive(int count) {
    return '$count ACTIVE';
  }

  @override
  String get all => 'All';

  @override
  String get inProgress => 'In Progress';

  @override
  String get delivered => 'Delivered';

  @override
  String get noShipments => 'No shipments';

  @override
  String get addTrackingWhenRegistering =>
      'Add a tracking code when registering\na purchase or a sale';

  @override
  String get deleteShipment => 'Delete Shipment';

  @override
  String confirmDeleteShipment(String code) {
    return 'Delete shipment $code?';
  }

  @override
  String get codeCopied => 'Code copied!';

  @override
  String get track => 'Track';

  @override
  String get ship24 => 'SHIP24';

  @override
  String lastUpdate(String time) {
    return 'Last update: $time';
  }

  @override
  String updated(String status) {
    return 'Updated: $status';
  }

  @override
  String get purchase => 'PURCHASE';

  @override
  String get sale => 'SALE';

  @override
  String get tracking => 'Tracking';

  @override
  String get refreshFromShip24 => 'Refresh from Ship24';

  @override
  String get trackingTimeline => 'TRACKING TIMELINE';

  @override
  String nEvents(int count) {
    return '$count events';
  }

  @override
  String get noTrackingEvents => 'No tracking events';

  @override
  String get pressRefreshToUpdate =>
      'Press the 🔄 button to refresh\nthe status from Ship24';

  @override
  String openOn(String carrier) {
    return 'Open on $carrier';
  }

  @override
  String statusUpdated(String status) {
    return 'Status updated: $status';
  }

  @override
  String get pending => 'Pending';

  @override
  String get inTransit => 'In transit';

  @override
  String get deliveredStatus => 'Delivered';

  @override
  String get problem => 'Problem';

  @override
  String get unknown => 'Unknown';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get now => 'Now';

  @override
  String minutesAgo(int count) {
    return '${count}m ago';
  }

  @override
  String hoursAgo(int count) {
    return '${count}h ago';
  }

  @override
  String daysAgo(int count) {
    return '${count}d ago';
  }

  @override
  String error(String message) {
    return 'Error: $message';
  }

  @override
  String get financialOverview => 'Financial Overview';

  @override
  String get totalRevenueLabel => 'Total Revenue';

  @override
  String get totalSpentLabel => 'Total Spent';

  @override
  String get netProfit => 'Net Profit';

  @override
  String get roi => 'ROI';

  @override
  String get salesSection => 'Sales';

  @override
  String get salesCount => 'No. of Sales';

  @override
  String get avgProfitLabel => 'Average Profit';

  @override
  String get totalFees => 'Total Fees';

  @override
  String get bestSale => 'BEST SALE';

  @override
  String get purchasesSection => 'Purchases';

  @override
  String get purchasesCount => 'No. of Purchases';

  @override
  String get inventoryValue => 'Inventory Value';

  @override
  String get totalPieces => 'Total Pieces';

  @override
  String get financialBreakdown => 'Financial Breakdown';

  @override
  String get salesRevenue => 'Sales revenue';

  @override
  String get purchaseCosts => 'Purchase costs';

  @override
  String get feesPaid => 'Fees paid';

  @override
  String get netProfitLabel => 'NET PROFIT';

  @override
  String get costsLegend => 'Costs';

  @override
  String get feesLegend => 'Fees';

  @override
  String get profitLegend => 'Profit';

  @override
  String get fullOverview => 'Full overview of purchases and sales';

  @override
  String get export => 'Export';

  @override
  String get csvFullHistory => 'CSV Full History';

  @override
  String get pdfTaxSummary => 'PDF Tax Summary';

  @override
  String get monthlySalesLog => 'Monthly Sales Log';

  @override
  String get salesHistory => 'Sales History';

  @override
  String get purchasesHistory => 'Purchases History';

  @override
  String get account => 'Account';

  @override
  String get resetViaEmail => 'Reset via email';

  @override
  String get twoFactorAuth => '2FA Authentication';

  @override
  String get notAvailable => 'Not available';

  @override
  String get twoFactorTitle => 'Two-Factor Authentication';

  @override
  String get twoFactorDescription =>
      '2FA will be available in a future update.\n\nFor now, make sure to use a strong password.';

  @override
  String get workspaceActive => 'Active Workspace';

  @override
  String get selectWorkspace => 'Select Workspace';

  @override
  String get autoBackup => 'Auto Backup';

  @override
  String get syncDataCloud => 'Sync data to cloud';

  @override
  String get exportAllData => 'Export All Data';

  @override
  String get csvPdfJson => 'CSV, PDF, JSON';

  @override
  String get notificationsInApp => 'In-App Notifications';

  @override
  String get salesShipmentAlerts => 'Sales and shipment alerts';

  @override
  String get pushNotifications => 'Push Notifications';

  @override
  String get receiveOnMobile => 'Receive on mobile';

  @override
  String get emailDigest => 'Email Digest';

  @override
  String get weeklyReport => 'Weekly report';

  @override
  String get appearance => 'Appearance';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get useDarkTheme => 'Use dark theme';

  @override
  String get fontSize => 'Font Size';

  @override
  String get accentColor => 'Accent Color';

  @override
  String get blueViolet => 'Blue-Violet';

  @override
  String get green => 'Green';

  @override
  String get orange => 'Orange';

  @override
  String get info => 'Info';

  @override
  String get version => 'Version';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get reportBug => 'Report a Bug';

  @override
  String get describeProblem => 'Describe the problem...';

  @override
  String get logout => 'Logout';

  @override
  String get confirmLogout =>
      'Are you sure you want to log out of your account?';

  @override
  String get proPlan => 'PRO PLAN';

  @override
  String get userName => 'Username';

  @override
  String get close => 'Close';

  @override
  String get save => 'Save';

  @override
  String fieldUpdated(String field) {
    return '$field updated!';
  }

  @override
  String get verificationSent => 'Verification sent to the new email';

  @override
  String resetEmailSent(String email) {
    return 'Reset email sent to $email';
  }

  @override
  String exportStarted(String format) {
    return '$format export started!';
  }

  @override
  String get exportData => 'Export Data';

  @override
  String get chooseExportFormat => 'Choose the export format';

  @override
  String get allRecordsCsv => 'All records in CSV format';

  @override
  String get formattedReport => 'Formatted report for printing';

  @override
  String get rawDataJson => 'Raw data in JSON format';

  @override
  String get termsContent =>
      'Vault Reselling Tracker — Terms of Service\n\nBy using this app you agree to the following terms:\n\n1. The app is provided \"as is\" without warranties.\n2. The data you enter is your responsibility.\n3. We are not liable for losses arising from the use of the app.\n4. Data is stored on Firebase Cloud.\n5. You can export and delete your data at any time.\n\nLast updated: January 2025';

  @override
  String get privacyContent =>
      'Your privacy is important to us.\n\n• Data is stored securely on Firebase\n• Authentication is managed by Firebase Auth\n• We do not share information with third parties\n• You can request data deletion at any time\n\nFor questions: privacy@vault-app.com';

  @override
  String nUnread(int count) {
    return '$count UNREAD';
  }

  @override
  String get markAllRead => 'Mark all as read';

  @override
  String get clearAll => 'Clear All';

  @override
  String get deleteAll => 'Delete all';

  @override
  String get deleteAllNotifications => 'Delete all notifications?';

  @override
  String get noNotifications => 'No notifications';

  @override
  String get notificationsWillAppearHere =>
      'Tracking and sales notifications\nwill appear here';

  @override
  String get shipmentType => 'SHIPMENT';

  @override
  String get saleType => 'SALE';

  @override
  String get lowStockType => 'LOW STOCK';

  @override
  String get systemType => 'SYSTEM';

  @override
  String get addTracking => '+ Add Tracking (optional)';

  @override
  String get trackingShipment => 'SHIPMENT TRACKING';

  @override
  String get remove => 'Remove';

  @override
  String carrierDetected(String name) {
    return 'Carrier detected: $name';
  }

  @override
  String get trackingHint => 'E.g. RR123456789IT';

  @override
  String soldAt(String price) {
    return 'Sold at €$price';
  }

  @override
  String costLabel(String price) {
    return 'Cost €$price';
  }

  @override
  String feeLabel(String price) {
    return 'Fee €$price';
  }

  @override
  String get costUpperCase => 'COST';

  @override
  String qty(String qty) {
    return 'Qty: $qty';
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
