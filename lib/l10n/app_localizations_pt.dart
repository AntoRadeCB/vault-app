// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Vault - Reselling Tracker';

  @override
  String get vault => 'Vault';

  @override
  String get resellingTracker => 'Reselling Tracker';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get inventory => 'Inventário';

  @override
  String get shipments => 'Envios';

  @override
  String get reports => 'Relatórios';

  @override
  String get settings => 'Configurações';

  @override
  String get notifications => 'Notificações';

  @override
  String get home => 'Início';

  @override
  String get systemOnline => 'Sistema Online';

  @override
  String get searchItemsReports => 'Pesquisar itens, relatórios...';

  @override
  String get newItem => 'Novo Item';

  @override
  String get online => 'ONLINE';

  @override
  String get login => 'Entrar';

  @override
  String get register => 'Registrar';

  @override
  String get email => 'Email';

  @override
  String get password => 'Senha';

  @override
  String get confirmPassword => 'Confirmar Senha';

  @override
  String get createAccount => 'Criar Conta';

  @override
  String get enterEmailAndPassword => 'Insira email e senha.';

  @override
  String get passwordsDoNotMatch => 'As senhas não coincidem.';

  @override
  String get passwordMinLength => 'A senha deve ter pelo menos 6 caracteres.';

  @override
  String get userNotFound => 'Nenhum utilizador encontrado com este email.';

  @override
  String get wrongPassword => 'Senha incorreta.';

  @override
  String get invalidEmail => 'Email inválido.';

  @override
  String get accountDisabled => 'Conta desativada.';

  @override
  String get emailAlreadyInUse => 'Email já registado.';

  @override
  String get weakPassword => 'Senha demasiado fraca (mínimo 6 caracteres).';

  @override
  String get invalidCredential => 'Credenciais inválidas.';

  @override
  String get unknownError => 'Erro desconhecido.';

  @override
  String get resellingVinted2025 => 'Reselling Vinted 2025';

  @override
  String nItems(int count) {
    return '$count itens';
  }

  @override
  String get capitaleImmobilizzato => 'Capital Imobilizado';

  @override
  String get ordiniInArrivo => 'Encomendas a Chegar';

  @override
  String get capitaleSpedito => 'Capital Enviado';

  @override
  String get profittoConsolidato => 'Lucro Consolidado';

  @override
  String get totalSpent => 'Total Gasto';

  @override
  String get totalRevenue => 'Receita Total';

  @override
  String get avgProfit => 'Lucro Médio';

  @override
  String get newPurchase => 'Nova Compra';

  @override
  String get registerSale => 'Registar Venda';

  @override
  String get recentSales => 'Vendas Recentes';

  @override
  String nTotal(int count) {
    return '$count totais';
  }

  @override
  String get noSalesRegistered => 'Nenhuma venda registada';

  @override
  String get recentPurchases => 'Compras Recentes';

  @override
  String get noPurchasesRegistered => 'Nenhuma compra registada';

  @override
  String get operationalStatus => 'Estado Operacional';

  @override
  String nShipmentsInTransit(int count) {
    return '$count envios em trânsito';
  }

  @override
  String nProductsOnSale(int count) {
    return '$count produtos à venda';
  }

  @override
  String lowStockProduct(String name) {
    return 'Stock baixo: $name';
  }

  @override
  String get noActiveAlerts => 'Nenhum alerta ativo';

  @override
  String nRecords(int count) {
    return '$count REGISTOS';
  }

  @override
  String get historicalRecords => 'Histórico de Registos';

  @override
  String get productSummary => 'Resumo de Produtos';

  @override
  String get searchProduct => 'Pesquisar produto...';

  @override
  String get noProducts => 'Sem produtos';

  @override
  String get addYourFirstProduct => 'Adicione o seu primeiro produto!';

  @override
  String get deleteProduct => 'Eliminar Produto';

  @override
  String confirmDeleteProduct(String name) {
    return 'Tem a certeza que quer eliminar \"$name\"?';
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
  String get totalInventoryValue => 'Valor Total do Inventário';

  @override
  String get shippedProducts => 'Produtos Enviados';

  @override
  String get inInventory => 'Em Inventário';

  @override
  String get onSale => 'À Venda';

  @override
  String get itemName => 'Nome do Item';

  @override
  String get itemNameHint => 'Ex. Nike Air Max 90';

  @override
  String get brand => 'Marca';

  @override
  String get brandHint => 'Ex. Nike, Adidas, Stone Island';

  @override
  String get purchasePrice => 'Preço de Compra (€)';

  @override
  String get quantity => 'Quantidade';

  @override
  String get status => 'Estado';

  @override
  String get workspace => 'Workspace';

  @override
  String get shipped => 'Enviado';

  @override
  String get registerPurchase => 'Registar Compra';

  @override
  String get purchaseRegistered => 'Compra registada com sucesso!';

  @override
  String get requiredField => 'Campo obrigatório';

  @override
  String get enterPrice => 'Insira um preço';

  @override
  String get invalidPrice => 'Preço inválido';

  @override
  String get enterQuantity => 'Insira uma quantidade';

  @override
  String get invalidQuantity => 'Quantidade inválida';

  @override
  String get barcode => 'CÓDIGO DE BARRAS';

  @override
  String productFound(String name) {
    return 'Produto encontrado: $name';
  }

  @override
  String barcodeScanned(String code) {
    return 'Código de barras: $code — preencha os dados do produto';
  }

  @override
  String get product => 'Produto';

  @override
  String get scanBarcodeProduct => 'Escanear Código de Barras';

  @override
  String get selectProduct => 'Selecionar produto...';

  @override
  String get noProductsInInventory => 'Nenhum produto em inventário';

  @override
  String get salePrice => 'Preço de Venda (€)';

  @override
  String get enterSalePrice => 'Insira o preço de venda';

  @override
  String get feesShipping => 'Comissões / Envio (€)';

  @override
  String get invalidValue => 'Valor inválido';

  @override
  String get removeFromInventory => 'Remover do inventário';

  @override
  String get scaleOneUnit => 'Descontar 1 unidade do produto';

  @override
  String get saleSummary => 'RESUMO DA VENDA';

  @override
  String get salePriceLabel => 'Preço de venda';

  @override
  String get purchaseCost => 'Custo de compra';

  @override
  String get fees => 'Comissões';

  @override
  String get profit => 'LUCRO';

  @override
  String get confirmSale => 'Confirmar Venda';

  @override
  String saleRegistered(String profit) {
    return 'Venda registada! Lucro: €$profit';
  }

  @override
  String get selectProductToSell => 'Selecione um produto para vender.';

  @override
  String found(String name) {
    return 'Encontrado: $name';
  }

  @override
  String noProductFoundBarcode(String code) {
    return 'Nenhum produto encontrado com código de barras: $code';
  }

  @override
  String get editProduct => 'Editar Produto';

  @override
  String get modified => 'MODIFICADO';

  @override
  String get unsavedChanges => 'Alterações não guardadas';

  @override
  String get unsavedChangesMessage =>
      'Tem alterações não guardadas. Deseja sair sem guardar?';

  @override
  String get stay => 'Ficar';

  @override
  String get exit => 'Sair';

  @override
  String get saveChanges => 'Guardar Alterações';

  @override
  String get productUpdated => 'Produto atualizado!';

  @override
  String nActive(int count) {
    return '$count ATIVOS';
  }

  @override
  String get all => 'Todos';

  @override
  String get inProgress => 'Em Curso';

  @override
  String get delivered => 'Entregues';

  @override
  String get noShipments => 'Sem envios';

  @override
  String get addTrackingWhenRegistering =>
      'Adicione um código de rastreio ao registar\numa compra ou venda';

  @override
  String get deleteShipment => 'Eliminar Envio';

  @override
  String confirmDeleteShipment(String code) {
    return 'Eliminar o envio $code?';
  }

  @override
  String get codeCopied => 'Código copiado!';

  @override
  String get track => 'Rastrear';

  @override
  String get ship24 => 'SHIP24';

  @override
  String lastUpdate(String time) {
    return 'Última atualização: $time';
  }

  @override
  String updated(String status) {
    return 'Atualizado: $status';
  }

  @override
  String get purchase => 'COMPRA';

  @override
  String get sale => 'VENDA';

  @override
  String get tracking => 'Rastreamento';

  @override
  String get refreshFromShip24 => 'Atualizar via Ship24';

  @override
  String get trackingTimeline => 'CRONOLOGIA DE RASTREIO';

  @override
  String nEvents(int count) {
    return '$count eventos';
  }

  @override
  String get noTrackingEvents => 'Sem eventos de rastreio';

  @override
  String get pressRefreshToUpdate =>
      'Prima o botão 🔄 para atualizar\no estado via Ship24';

  @override
  String openOn(String carrier) {
    return 'Abrir em $carrier';
  }

  @override
  String statusUpdated(String status) {
    return 'Estado atualizado: $status';
  }

  @override
  String get pending => 'Pendente';

  @override
  String get inTransit => 'Em trânsito';

  @override
  String get deliveredStatus => 'Entregue';

  @override
  String get problem => 'Problema';

  @override
  String get unknown => 'Desconhecido';

  @override
  String get today => 'Hoje';

  @override
  String get yesterday => 'Ontem';

  @override
  String get now => 'Agora';

  @override
  String minutesAgo(int count) {
    return 'há ${count}m';
  }

  @override
  String hoursAgo(int count) {
    return 'há ${count}h';
  }

  @override
  String daysAgo(int count) {
    return 'há ${count}d';
  }

  @override
  String error(String message) {
    return 'Erro: $message';
  }

  @override
  String get financialOverview => 'Resumo Financeiro';

  @override
  String get totalRevenueLabel => 'Receita Total';

  @override
  String get totalSpentLabel => 'Total Gasto';

  @override
  String get netProfit => 'Lucro Líquido';

  @override
  String get roi => 'ROI';

  @override
  String get salesSection => 'Vendas';

  @override
  String get salesCount => 'Nº Vendas';

  @override
  String get avgProfitLabel => 'Lucro Médio';

  @override
  String get totalFees => 'Total Comissões';

  @override
  String get bestSale => 'MELHOR VENDA';

  @override
  String get purchasesSection => 'Compras';

  @override
  String get purchasesCount => 'Nº Compras';

  @override
  String get inventoryValue => 'Valor do Inventário';

  @override
  String get totalPieces => 'Total de Peças';

  @override
  String get financialBreakdown => 'Detalhamento Financeiro';

  @override
  String get salesRevenue => 'Receita de vendas';

  @override
  String get purchaseCosts => 'Custos de compra';

  @override
  String get feesPaid => 'Comissões pagas';

  @override
  String get netProfitLabel => 'LUCRO LÍQUIDO';

  @override
  String get costsLegend => 'Custos';

  @override
  String get feesLegend => 'Comissões';

  @override
  String get profitLegend => 'Lucro';

  @override
  String get fullOverview => 'Resumo completo de compras e vendas';

  @override
  String get export => 'Exportar';

  @override
  String get csvFullHistory => 'CSV Histórico Completo';

  @override
  String get pdfTaxSummary => 'PDF Resumo Fiscal';

  @override
  String get monthlySalesLog => 'Registo Mensal de Vendas';

  @override
  String get salesHistory => 'Histórico de Vendas';

  @override
  String get purchasesHistory => 'Histórico de Compras';

  @override
  String get account => 'Conta';

  @override
  String get resetViaEmail => 'Redefinir por email';

  @override
  String get forgotPassword => 'Esqueceu a senha?';

  @override
  String get twoFactorAuth => 'Autenticação 2FA';

  @override
  String get notAvailable => 'Não disponível';

  @override
  String get twoFactorTitle => 'Autenticação de Dois Fatores';

  @override
  String get twoFactorDescription =>
      'A 2FA estará disponível numa próxima atualização.\n\nPor agora, certifique-se de usar uma senha segura.';

  @override
  String get workspaceActive => 'Workspace Ativo';

  @override
  String get selectWorkspace => 'Selecionar Workspace';

  @override
  String get autoBackup => 'Backup Automático';

  @override
  String get syncDataCloud => 'Sincronizar dados na nuvem';

  @override
  String get exportAllData => 'Exportar Todos os Dados';

  @override
  String get csvPdfJson => 'CSV, PDF, JSON';

  @override
  String get notificationsInApp => 'Notificações In-App';

  @override
  String get salesShipmentAlerts => 'Alertas de vendas e envios';

  @override
  String get pushNotifications => 'Notificações Push';

  @override
  String get receiveOnMobile => 'Receber no telemóvel';

  @override
  String get emailDigest => 'Resumo por Email';

  @override
  String get weeklyReport => 'Relatório semanal';

  @override
  String get appearance => 'Aparência';

  @override
  String get darkMode => 'Modo Escuro';

  @override
  String get useDarkTheme => 'Usar tema escuro';

  @override
  String get fontSize => 'Tamanho da Fonte';

  @override
  String get accentColor => 'Cor de Destaque';

  @override
  String get blueViolet => 'Azul-Violeta';

  @override
  String get green => 'Verde';

  @override
  String get orange => 'Laranja';

  @override
  String get info => 'Info';

  @override
  String get version => 'Versão';

  @override
  String get termsOfService => 'Termos de Serviço';

  @override
  String get privacyPolicy => 'Política de Privacidade';

  @override
  String get reportBug => 'Reportar um Erro';

  @override
  String get describeProblem => 'Descreva o problema...';

  @override
  String get logout => 'Sair';

  @override
  String get confirmLogout => 'Tem a certeza que deseja sair da sua conta?';

  @override
  String get proPlan => 'PLANO PRO';

  @override
  String get userName => 'Nome de Utilizador';

  @override
  String get close => 'Fechar';

  @override
  String get save => 'Guardar';

  @override
  String fieldUpdated(String field) {
    return '$field atualizado!';
  }

  @override
  String get verificationSent => 'Verificação enviada para o novo email';

  @override
  String resetEmailSent(String email) {
    return 'Email de redefinição enviado para $email';
  }

  @override
  String exportStarted(String format) {
    return 'Exportação $format iniciada!';
  }

  @override
  String get exportData => 'Exportar Dados';

  @override
  String get chooseExportFormat => 'Escolha o formato de exportação';

  @override
  String get allRecordsCsv => 'Todos os registos em formato CSV';

  @override
  String get formattedReport => 'Relatório formatado para impressão';

  @override
  String get rawDataJson => 'Dados brutos em formato JSON';

  @override
  String get termsContent =>
      'Vault Reselling Tracker — Termos de Serviço\n\nAo usar esta app aceita os seguintes termos:\n\n1. A app é fornecida \"tal como está\" sem garantias.\n2. Os dados inseridos são da sua responsabilidade.\n3. Não somos responsáveis por perdas derivadas do uso da app.\n4. Os dados são armazenados no Firebase Cloud.\n5. Pode exportar e eliminar os seus dados em qualquer momento.\n\nÚltima atualização: Janeiro 2025';

  @override
  String get privacyContent =>
      'A sua privacidade é importante para nós.\n\n• Os dados são guardados de forma segura no Firebase\n• A autenticação é gerida pelo Firebase Auth\n• Não partilhamos informações com terceiros\n• Pode solicitar a eliminação dos seus dados em qualquer momento\n\nPara questões: privacy@vault-app.com';

  @override
  String nUnread(int count) {
    return '$count NÃO LIDAS';
  }

  @override
  String get markAllRead => 'Marcar todas como lidas';

  @override
  String get clearAll => 'Limpar Todas';

  @override
  String get deleteAll => 'Eliminar tudo';

  @override
  String get deleteAllNotifications => 'Eliminar todas as notificações?';

  @override
  String get noNotifications => 'Sem notificações';

  @override
  String get notificationsWillAppearHere =>
      'As notificações de rastreio e vendas\naparecerão aqui';

  @override
  String get shipmentType => 'ENVIO';

  @override
  String get saleType => 'VENDA';

  @override
  String get lowStockType => 'STOCK BAIXO';

  @override
  String get systemType => 'SISTEMA';

  @override
  String get addTracking => '+ Adicionar Rastreio (opcional)';

  @override
  String get trackingShipment => 'RASTREIO DE ENVIO';

  @override
  String get remove => 'Remover';

  @override
  String carrierDetected(String name) {
    return 'Transportadora detetada: $name';
  }

  @override
  String get trackingHint => 'Ex. RR123456789IT';

  @override
  String soldAt(String price) {
    return 'Vendido a €$price';
  }

  @override
  String costLabel(String price) {
    return 'Custo €$price';
  }

  @override
  String feeLabel(String price) {
    return 'Comissão €$price';
  }

  @override
  String get costUpperCase => 'CUSTO';

  @override
  String qty(String qty) {
    return 'Qtd: $qty';
  }

  @override
  String get small => 'Pequeno';

  @override
  String get medium => 'Médio';

  @override
  String get large => 'Grande';

  @override
  String get extraLarge => 'Extra Grande';
}
