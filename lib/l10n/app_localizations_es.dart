// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Vault - Reselling Tracker';

  @override
  String get vault => 'Vault';

  @override
  String get resellingTracker => 'Reselling Tracker';

  @override
  String get dashboard => 'Panel';

  @override
  String get inventory => 'Inventario';

  @override
  String get shipments => 'Envíos';

  @override
  String get reports => 'Informes';

  @override
  String get settings => 'Ajustes';

  @override
  String get notifications => 'Notificaciones';

  @override
  String get home => 'Inicio';

  @override
  String get systemOnline => 'Sistema en línea';

  @override
  String get searchItemsReports => 'Buscar artículos, informes...';

  @override
  String get newItem => 'Nuevo Artículo';

  @override
  String get online => 'ONLINE';

  @override
  String get login => 'Iniciar sesión';

  @override
  String get register => 'Registrarse';

  @override
  String get email => 'Email';

  @override
  String get password => 'Contraseña';

  @override
  String get confirmPassword => 'Confirmar Contraseña';

  @override
  String get createAccount => 'Crear Cuenta';

  @override
  String get enterEmailAndPassword => 'Introduce email y contraseña.';

  @override
  String get passwordsDoNotMatch => 'Las contraseñas no coinciden.';

  @override
  String get passwordMinLength =>
      'La contraseña debe tener al menos 6 caracteres.';

  @override
  String get userNotFound => 'No se encontró ningún usuario con este email.';

  @override
  String get wrongPassword => 'Contraseña incorrecta.';

  @override
  String get invalidEmail => 'Email no válido.';

  @override
  String get accountDisabled => 'Cuenta deshabilitada.';

  @override
  String get emailAlreadyInUse => 'Email ya registrado.';

  @override
  String get weakPassword =>
      'Contraseña demasiado débil (mínimo 6 caracteres).';

  @override
  String get invalidCredential => 'Credenciales no válidas.';

  @override
  String get unknownError => 'Error desconocido.';

  @override
  String get resellingVinted2025 => 'Reselling Vinted 2025';

  @override
  String nItems(int count) {
    return '$count artículos';
  }

  @override
  String get capitaleImmobilizzato => 'Capital Inmovilizado';

  @override
  String get ordiniInArrivo => 'Pedidos Entrantes';

  @override
  String get capitaleSpedito => 'Capital Enviado';

  @override
  String get profittoConsolidato => 'Beneficio Consolidado';

  @override
  String get totalSpent => 'Total Gastado';

  @override
  String get totalRevenue => 'Ingresos Totales';

  @override
  String get avgProfit => 'Beneficio Medio';

  @override
  String get newPurchase => 'Nueva Compra';

  @override
  String get registerSale => 'Registrar Venta';

  @override
  String get recentSales => 'Ventas Recientes';

  @override
  String nTotal(int count) {
    return '$count totales';
  }

  @override
  String get noSalesRegistered => 'No hay ventas registradas';

  @override
  String get recentPurchases => 'Compras Recientes';

  @override
  String get noPurchasesRegistered => 'No hay compras registradas';

  @override
  String get operationalStatus => 'Estado Operativo';

  @override
  String nShipmentsInTransit(int count) {
    return '$count envíos en tránsito';
  }

  @override
  String nProductsOnSale(int count) {
    return '$count productos en venta';
  }

  @override
  String lowStockProduct(String name) {
    return 'Stock bajo: $name';
  }

  @override
  String get noActiveAlerts => 'Sin alertas activas';

  @override
  String nRecords(int count) {
    return '$count REGISTROS';
  }

  @override
  String get historicalRecords => 'Historial de Registros';

  @override
  String get productSummary => 'Resumen de Productos';

  @override
  String get searchProduct => 'Buscar producto...';

  @override
  String get noProducts => 'Sin productos';

  @override
  String get addYourFirstProduct => '¡Añade tu primer producto!';

  @override
  String get deleteProduct => 'Eliminar Producto';

  @override
  String confirmDeleteProduct(String name) {
    return '¿Estás seguro de que quieres eliminar \"$name\"?';
  }

  @override
  String get cancel => 'Cancelar';

  @override
  String get delete => 'Eliminar';

  @override
  String productDeleted(String name) {
    return '$name eliminado';
  }

  @override
  String get totalInventoryValue => 'Valor Total del Inventario';

  @override
  String get shippedProducts => 'Productos Enviados';

  @override
  String get inInventory => 'En Inventario';

  @override
  String get onSale => 'En Venta';

  @override
  String get itemName => 'Nombre del Artículo';

  @override
  String get itemNameHint => 'Ej. Nike Air Max 90';

  @override
  String get brand => 'Marca';

  @override
  String get brandHint => 'Ej. Nike, Adidas, Stone Island';

  @override
  String get purchasePrice => 'Precio de Compra (€)';

  @override
  String get quantity => 'Cantidad';

  @override
  String get status => 'Estado';

  @override
  String get workspace => 'Workspace';

  @override
  String get shipped => 'Enviado';

  @override
  String get registerPurchase => 'Registrar Compra';

  @override
  String get purchaseRegistered => '¡Compra registrada con éxito!';

  @override
  String get requiredField => 'Campo obligatorio';

  @override
  String get enterPrice => 'Introduce un precio';

  @override
  String get invalidPrice => 'Precio no válido';

  @override
  String get enterQuantity => 'Introduce una cantidad';

  @override
  String get invalidQuantity => 'Cantidad no válida';

  @override
  String get barcode => 'BARCODE';

  @override
  String productFound(String name) {
    return 'Producto encontrado: $name';
  }

  @override
  String barcodeScanned(String code) {
    return 'Barcode: $code — completa los datos del producto';
  }

  @override
  String get product => 'Producto';

  @override
  String get scanBarcodeProduct => 'Escanear Barcode del Producto';

  @override
  String get selectProduct => 'Seleccionar producto...';

  @override
  String get noProductsInInventory => 'No hay productos en inventario';

  @override
  String get salePrice => 'Precio de Venta (€)';

  @override
  String get enterSalePrice => 'Introduce el precio de venta';

  @override
  String get feesShipping => 'Comisiones / Envío (€)';

  @override
  String get invalidValue => 'Valor no válido';

  @override
  String get removeFromInventory => 'Eliminar del inventario';

  @override
  String get scaleOneUnit => 'Descontar 1 unidad del producto';

  @override
  String get saleSummary => 'RESUMEN DE VENTA';

  @override
  String get salePriceLabel => 'Precio de venta';

  @override
  String get purchaseCost => 'Coste de compra';

  @override
  String get fees => 'Comisiones';

  @override
  String get profit => 'BENEFICIO';

  @override
  String get confirmSale => 'Confirmar Venta';

  @override
  String saleRegistered(String profit) {
    return '¡Venta registrada! Beneficio: €$profit';
  }

  @override
  String get selectProductToSell => 'Selecciona un producto para vender.';

  @override
  String found(String name) {
    return 'Encontrado: $name';
  }

  @override
  String noProductFoundBarcode(String code) {
    return 'Ningún producto encontrado con barcode: $code';
  }

  @override
  String get editProduct => 'Editar Producto';

  @override
  String get modified => 'MODIFICADO';

  @override
  String get unsavedChanges => 'Cambios sin guardar';

  @override
  String get unsavedChangesMessage =>
      'Tienes cambios sin guardar. ¿Quieres salir sin guardar?';

  @override
  String get stay => 'Quedarse';

  @override
  String get exit => 'Salir';

  @override
  String get saveChanges => 'Guardar Cambios';

  @override
  String get productUpdated => '¡Producto actualizado!';

  @override
  String nActive(int count) {
    return '$count ACTIVOS';
  }

  @override
  String get all => 'Todos';

  @override
  String get inProgress => 'En Curso';

  @override
  String get delivered => 'Entregados';

  @override
  String get noShipments => 'Sin envíos';

  @override
  String get addTrackingWhenRegistering =>
      'Añade un código de seguimiento al registrar\nuna compra o una venta';

  @override
  String get deleteShipment => 'Eliminar Envío';

  @override
  String confirmDeleteShipment(String code) {
    return '¿Eliminar el envío $code?';
  }

  @override
  String get codeCopied => '¡Código copiado!';

  @override
  String get track => 'Rastrear';

  @override
  String get ship24 => 'SHIP24';

  @override
  String lastUpdate(String time) {
    return 'Última act.: $time';
  }

  @override
  String updated(String status) {
    return 'Actualizado: $status';
  }

  @override
  String get purchase => 'COMPRA';

  @override
  String get sale => 'VENTA';

  @override
  String get tracking => 'Seguimiento';

  @override
  String get refreshFromShip24 => 'Actualizar desde Ship24';

  @override
  String get trackingTimeline => 'CRONOLOGÍA DE SEGUIMIENTO';

  @override
  String nEvents(int count) {
    return '$count eventos';
  }

  @override
  String get noTrackingEvents => 'Sin eventos de seguimiento';

  @override
  String get pressRefreshToUpdate =>
      'Pulsa el botón 🔄 para actualizar\nel estado desde Ship24';

  @override
  String openOn(String carrier) {
    return 'Abrir en $carrier';
  }

  @override
  String statusUpdated(String status) {
    return 'Estado actualizado: $status';
  }

  @override
  String get pending => 'Pendiente';

  @override
  String get inTransit => 'En tránsito';

  @override
  String get deliveredStatus => 'Entregado';

  @override
  String get problem => 'Problema';

  @override
  String get unknown => 'Desconocido';

  @override
  String get today => 'Hoy';

  @override
  String get yesterday => 'Ayer';

  @override
  String get now => 'Ahora';

  @override
  String minutesAgo(int count) {
    return 'hace ${count}m';
  }

  @override
  String hoursAgo(int count) {
    return 'hace ${count}h';
  }

  @override
  String daysAgo(int count) {
    return 'hace ${count}d';
  }

  @override
  String error(String message) {
    return 'Error: $message';
  }

  @override
  String get financialOverview => 'Resumen Financiero';

  @override
  String get totalRevenueLabel => 'Ingresos Totales';

  @override
  String get totalSpentLabel => 'Total Gastado';

  @override
  String get netProfit => 'Beneficio Neto';

  @override
  String get roi => 'ROI';

  @override
  String get salesSection => 'Ventas';

  @override
  String get salesCount => 'N° de Ventas';

  @override
  String get avgProfitLabel => 'Beneficio Medio';

  @override
  String get totalFees => 'Total Comisiones';

  @override
  String get bestSale => 'MEJOR VENTA';

  @override
  String get purchasesSection => 'Compras';

  @override
  String get purchasesCount => 'N° de Compras';

  @override
  String get inventoryValue => 'Valor del Inventario';

  @override
  String get totalPieces => 'Piezas Totales';

  @override
  String get financialBreakdown => 'Desglose Financiero';

  @override
  String get salesRevenue => 'Ingresos por ventas';

  @override
  String get purchaseCosts => 'Costes de compra';

  @override
  String get feesPaid => 'Comisiones pagadas';

  @override
  String get netProfitLabel => 'BENEFICIO NETO';

  @override
  String get costsLegend => 'Costes';

  @override
  String get feesLegend => 'Comisiones';

  @override
  String get profitLegend => 'Beneficio';

  @override
  String get fullOverview => 'Resumen completo de compras y ventas';

  @override
  String get export => 'Exportar';

  @override
  String get csvFullHistory => 'CSV Full History';

  @override
  String get pdfTaxSummary => 'PDF Tax Summary';

  @override
  String get monthlySalesLog => 'Monthly Sales Log';

  @override
  String get salesHistory => 'Historial de Ventas';

  @override
  String get purchasesHistory => 'Historial de Compras';

  @override
  String get account => 'Cuenta';

  @override
  String get resetViaEmail => 'Restablecer vía email';

  @override
  String get forgotPassword => '¿Olvidaste tu contraseña?';

  @override
  String get twoFactorAuth => 'Autenticación 2FA';

  @override
  String get notAvailable => 'No disponible';

  @override
  String get twoFactorTitle => 'Autenticación de Dos Factores';

  @override
  String get twoFactorDescription =>
      'La 2FA estará disponible en una futura actualización.\n\nPor ahora, asegúrate de usar una contraseña segura.';

  @override
  String get workspaceActive => 'Workspace Activo';

  @override
  String get selectWorkspace => 'Seleccionar Workspace';

  @override
  String get autoBackup => 'Copia de Seguridad Automática';

  @override
  String get syncDataCloud => 'Sincronizar datos en la nube';

  @override
  String get exportAllData => 'Exportar Todos los Datos';

  @override
  String get csvPdfJson => 'CSV, PDF, JSON';

  @override
  String get notificationsInApp => 'Notificaciones en la App';

  @override
  String get salesShipmentAlerts => 'Alertas de ventas y envíos';

  @override
  String get pushNotifications => 'Notificaciones Push';

  @override
  String get receiveOnMobile => 'Recibir en el móvil';

  @override
  String get emailDigest => 'Email Digest';

  @override
  String get weeklyReport => 'Informe semanal';

  @override
  String get appearance => 'Apariencia';

  @override
  String get darkMode => 'Modo Oscuro';

  @override
  String get useDarkTheme => 'Usar tema oscuro';

  @override
  String get fontSize => 'Tamaño de Fuente';

  @override
  String get accentColor => 'Color de Acento';

  @override
  String get blueViolet => 'Azul-Violeta';

  @override
  String get green => 'Verde';

  @override
  String get orange => 'Naranja';

  @override
  String get info => 'Info';

  @override
  String get version => 'Versión';

  @override
  String get termsOfService => 'Términos de Servicio';

  @override
  String get privacyPolicy => 'Política de Privacidad';

  @override
  String get reportBug => 'Reportar un Error';

  @override
  String get describeProblem => 'Describe el problema...';

  @override
  String get logout => 'Cerrar sesión';

  @override
  String get confirmLogout => '¿Estás seguro de que quieres cerrar sesión?';

  @override
  String get proPlan => 'PRO PLAN';

  @override
  String get userName => 'Nombre de Usuario';

  @override
  String get close => 'Cerrar';

  @override
  String get save => 'Guardar';

  @override
  String fieldUpdated(String field) {
    return '¡$field actualizado!';
  }

  @override
  String get verificationSent => 'Verificación enviada al nuevo email';

  @override
  String resetEmailSent(String email) {
    return 'Email de restablecimiento enviado a $email';
  }

  @override
  String exportStarted(String format) {
    return '¡Exportación $format iniciada!';
  }

  @override
  String get exportData => 'Exportar Datos';

  @override
  String get chooseExportFormat => 'Elige el formato de exportación';

  @override
  String get allRecordsCsv => 'Todos los registros en formato CSV';

  @override
  String get formattedReport => 'Informe formateado para impresión';

  @override
  String get rawDataJson => 'Datos brutos en formato JSON';

  @override
  String get termsContent =>
      'Vault Reselling Tracker — Términos de Servicio\n\nAl usar esta app aceptas los siguientes términos:\n\n1. La app se proporciona \"tal cual\" sin garantías.\n2. Los datos introducidos son tu responsabilidad.\n3. No somos responsables de pérdidas derivadas del uso de la app.\n4. Los datos se almacenan en Firebase Cloud.\n5. Puedes exportar y eliminar tus datos en cualquier momento.\n\nÚltima actualización: Enero 2025';

  @override
  String get privacyContent =>
      'Tu privacidad es importante para nosotros.\n\n• Los datos se guardan de forma segura en Firebase\n• La autenticación es gestionada por Firebase Auth\n• No compartimos información con terceros\n• Puedes solicitar la eliminación de datos en cualquier momento\n\nPara consultas: privacy@vault-app.com';

  @override
  String nUnread(int count) {
    return '$count SIN LEER';
  }

  @override
  String get markAllRead => 'Marcar todas como leídas';

  @override
  String get clearAll => 'Borrar Todas';

  @override
  String get deleteAll => 'Eliminar todo';

  @override
  String get deleteAllNotifications => '¿Eliminar todas las notificaciones?';

  @override
  String get noNotifications => 'Sin notificaciones';

  @override
  String get notificationsWillAppearHere =>
      'Las notificaciones de seguimiento y ventas\naparecerán aquí';

  @override
  String get shipmentType => 'ENVÍO';

  @override
  String get saleType => 'VENTA';

  @override
  String get lowStockType => 'STOCK BAJO';

  @override
  String get systemType => 'SISTEMA';

  @override
  String get addTracking => '+ Añadir Seguimiento (opcional)';

  @override
  String get trackingShipment => 'SEGUIMIENTO DE ENVÍO';

  @override
  String get remove => 'Eliminar';

  @override
  String carrierDetected(String name) {
    return 'Transportista detectado: $name';
  }

  @override
  String get trackingHint => 'Ej. RR123456789IT';

  @override
  String soldAt(String price) {
    return 'Vendido a €$price';
  }

  @override
  String costLabel(String price) {
    return 'Coste €$price';
  }

  @override
  String feeLabel(String price) {
    return 'Fee €$price';
  }

  @override
  String get costUpperCase => 'COSTE';

  @override
  String qty(String qty) {
    return 'Cant: $qty';
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
