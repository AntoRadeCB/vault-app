import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_widgets.dart';
import '../widgets/barcode_scanner_dialog.dart';
import '../widgets/tracking_input.dart';
import '../widgets/card_search_field.dart';
import '../widgets/card_browser_sheet.dart';
import '../widgets/glow_text_field.dart';
import '../models/product.dart';
import '../models/purchase.dart';
import '../models/shipment.dart';
import '../models/card_blueprint.dart';
import '../services/firestore_service.dart';
import '../services/tracking_service.dart';
import '../l10n/app_localizations.dart';

class AddItemScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const AddItemScreen({super.key, this.onBack});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _barcodeController = TextEditingController();
  final _trackingController = TextEditingController();
  CarrierInfo? _detectedCarrier;
  CardBlueprint? _selectedCard;
  String _selectedWorkspace = 'Reselling Vinted 2025';
  String _selectedStatus = 'inInventory';
  bool _saving = false;
  bool _barcodeLoading = false;
  final FirestoreService _firestoreService = FirestoreService();
  final TrackingService _trackingService = TrackingService();

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _barcodeController.dispose();
    _trackingController.dispose();
    super.dispose();
  }

  Future<void> _scanBarcode() async {
    final code = await BarcodeScannerDialog.scan(context);
    if (code == null || !mounted) return;

    setState(() {
      _barcodeController.text = code;
      _barcodeLoading = true;
    });

    // Check if product with this barcode already exists
    try {
      final existing = await _firestoreService.getProductByBarcode(code);
      if (!mounted) return;

      if (existing != null) {
        // Auto-fill from existing product
        _nameController.text = existing.name;
        _brandController.text = existing.brand;
        _priceController.text = existing.price.toString();

        final l = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l.productFound(existing.name),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.accentBlue,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      } else {
        final l = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.qr_code, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l.barcodeScanned(code),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.accentOrange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (_) {}

    if (mounted) setState(() => _barcodeLoading = false);
  }

  void _applyCardSelection(CardBlueprint card) {
    setState(() {
      _selectedCard = card;
      _nameController.text = card.name;
      _brandController.text = card.expansionName ?? 'RIFTBOUND';
      if (card.marketPrice != null) {
        _priceController.text =
            (card.marketPrice!.cents / 100).toStringAsFixed(2);
      }
    });
  }

  Future<void> _openCardBrowser() async {
    final card = await CardBrowserSheet.show(context);
    if (card != null && mounted) {
      _applyCardSelection(card);
    }
  }

  Widget _buildSelectedCardPreview() {
    final card = _selectedCard!;
    return GlassCard(
      padding: const EdgeInsets.all(12),
      glowColor: card.rarityColor,
      child: Row(
        children: [
          // Card image
          Container(
            width: 56,
            height: 78,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: card.rarityColor.withValues(alpha: 0.4),
              ),
              boxShadow: [
                BoxShadow(
                  color: card.rarityColor.withValues(alpha: 0.2),
                  blurRadius: 8,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: card.imageUrl != null
                  ? Image.network(card.imageUrl!, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: card.rarityColor.withValues(alpha: 0.1),
                        child: Icon(Icons.style, color: card.rarityColor, size: 24),
                      ),
                    )
                  : Container(
                      color: card.rarityColor.withValues(alpha: 0.1),
                      child: Icon(Icons.style, color: card.rarityColor, size: 24),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  card.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (card.expansionName != null) ...[
                      Flexible(
                        child: Text(
                          card.expansionName!,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    if (card.rarity != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: card.rarityColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          card.rarity!,
                          style: TextStyle(
                            color: card.rarityColor,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                if (card.marketPrice != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Market: ${card.formattedPrice}',
                    style: const TextStyle(
                      color: AppColors.accentGreen,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Remove button
          ScaleOnPress(
            onTap: () => setState(() => _selectedCard = null),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.accentRed.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.close, color: AppColors.accentRed, size: 16),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);

    try {
      final product = Product(
        name: _nameController.text.trim(),
        brand: _brandController.text.trim().toUpperCase(),
        price: double.parse(_priceController.text.trim()),
        quantity: double.parse(_quantityController.text.trim()),
        status: _selectedStatus == 'shipped'
            ? ProductStatus.shipped
            : _selectedStatus == 'listed'
                ? ProductStatus.listed
                : ProductStatus.inInventory,
        barcode: _barcodeController.text.trim().isNotEmpty
            ? _barcodeController.text.trim()
            : null,
        createdAt: DateTime.now(),
        cardBlueprintId: _selectedCard?.id,
        cardImageUrl: _selectedCard?.imageUrl,
        cardExpansion: _selectedCard?.expansionName,
        cardRarity: _selectedCard?.rarity,
        marketPrice: _selectedCard?.marketPrice != null
            ? _selectedCard!.marketPrice!.cents / 100
            : null,
      );

      final productRef = await _firestoreService.addProduct(product);

      // Also log as a purchase
      final purchase = Purchase(
        productName: product.name,
        price: product.price,
        quantity: product.quantity,
        date: DateTime.now(),
        workspace: _selectedWorkspace,
      );
      await _firestoreService.addPurchase(purchase);

      // Create shipment if tracking code provided
      final trackingCode = _trackingController.text.trim();
      if (trackingCode.isNotEmpty) {
        final carrier = _detectedCarrier ?? Shipment.detectCarrier(trackingCode);

        // Auto-register on Ship24
        String? trackerId;
        try {
          final result = await _trackingService.registerTracking(
            trackingCode,
            carrier: carrier.id != 'generic' ? carrier.id : null,
          );
          trackerId = result['trackerId'];
        } catch (_) {
          // Ship24 registration failed — continue without it
        }

        final shipment = Shipment(
          trackingCode: trackingCode,
          carrier: carrier.id,
          carrierName: carrier.name,
          type: ShipmentType.purchase,
          productName: product.name,
          productId: productRef.id,
          status: ShipmentStatus.pending,
          createdAt: DateTime.now(),
          trackerId: trackerId,
          externalTrackingUrl: trackerId != null ? 'https://t.ship24.com/t/$trackingCode' : null,
          trackingApiStatus: null,
        );
        await _firestoreService.addShipment(shipment);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child:
                    const Icon(Icons.check, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 12),
              Text(
                AppLocalizations.of(context)!.purchaseRegistered,
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          backgroundColor: AppColors.accentGreen,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
        ),
      );
      widget.onBack?.call();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore: ${e.toString()}'),
          backgroundColor: AppColors.accentRed,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StaggeredFadeSlide(
              index: 0,
              child: Row(
                children: [
                  ScaleOnPress(
                    onTap: widget.onBack,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    l.newPurchase,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            StaggeredFadeSlide(
              index: 1,
              child: _buildField(
                label: l.itemName,
                child: CardSearchField(
                  controller: _nameController,
                  hintText: l.itemNameHint,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? l.requiredField : null,
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Browse catalog button
                      ScaleOnPress(
                        onTap: _openCardBrowser,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF764ba2), Color(0xFF667eea)],
                            ),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accentPurple.withValues(alpha: 0.3),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.style,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      // Barcode scanner button
                      ScaleOnPress(
                        onTap: _barcodeLoading ? null : _scanBarcode,
                        child: Container(
                          margin: const EdgeInsets.fromLTRB(0, 8, 8, 8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: AppColors.blueButtonGradient,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    AppColors.accentBlue.withValues(alpha: 0.3),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: _barcodeLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons.qr_code_scanner,
                                  color: Colors.white,
                                  size: 20,
                                ),
                        ),
                      ),
                    ],
                  ),
                  onCardSelected: _applyCardSelection,
                ),
              ),
            ),
            // Selected card preview
            if (_selectedCard != null) ...[
              const SizedBox(height: 12),
              StaggeredFadeSlide(
                index: 1,
                child: _buildSelectedCardPreview(),
              ),
            ],
            // Barcode field (shown when scanned)
            if (_barcodeController.text.isNotEmpty) ...[
              const SizedBox(height: 16),
              StaggeredFadeSlide(
                index: 2,
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  glowColor: AppColors.accentTeal,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.accentTeal.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.qr_code, color: AppColors.accentTeal, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l.barcode,
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _barcodeController.text,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                      ScaleOnPress(
                        onTap: () {
                          setState(() => _barcodeController.clear());
                        },
                        child: const Icon(Icons.close, color: AppColors.textMuted, size: 18),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            StaggeredFadeSlide(
              index: 3,
              child: _buildField(
                label: l.brand,
                child: GlowTextField(
                  controller: _brandController,
                  hintText: l.brandHint,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? l.requiredField : null,
                ),
              ),
            ),
            const SizedBox(height: 24),
            StaggeredFadeSlide(
              index: 3,
              child: _buildField(
                label: l.purchasePrice,
                child: GlowTextField(
                  controller: _priceController,
                  hintText: '0.00',
                  keyboardType: TextInputType.number,
                  prefixText: '€ ',
                  validator: (v) {
                    if (v == null || v.isEmpty) return l.enterPrice;
                    if (double.tryParse(v) == null) return l.invalidPrice;
                    return null;
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
            StaggeredFadeSlide(
              index: 4,
              child: _buildField(
                label: l.quantity,
                child: GlowTextField(
                  controller: _quantityController,
                  hintText: '1',
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return l.enterQuantity;
                    }
                    if (double.tryParse(v) == null) {
                      return l.invalidQuantity;
                    }
                    return null;
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
            StaggeredFadeSlide(
              index: 5,
              child: _buildField(
                label: l.status,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedStatus,
                      isExpanded: true,
                      dropdownColor: AppColors.surface,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 16),
                      icon: const Icon(Icons.keyboard_arrow_down,
                          color: AppColors.textMuted),
                      items: [
                        DropdownMenuItem(
                            value: 'inInventory',
                            child: Text(l.inInventory)),
                        DropdownMenuItem(
                            value: 'shipped',
                            child: Text(l.shipped)),
                        DropdownMenuItem(
                            value: 'listed',
                            child: Text(l.onSale)),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedStatus = value);
                        }
                      },
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            StaggeredFadeSlide(
              index: 6,
              child: _buildField(
                label: l.workspace,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedWorkspace,
                      isExpanded: true,
                      dropdownColor: AppColors.surface,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 16),
                      icon: const Icon(Icons.keyboard_arrow_down,
                          color: AppColors.textMuted),
                      items: const [
                        DropdownMenuItem(
                          value: 'Reselling Vinted 2025',
                          child: Text('Reselling Vinted 2025'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedWorkspace = value);
                        }
                      },
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Tracking code (optional)
            StaggeredFadeSlide(
              index: 7,
              child: TrackingInput(
                controller: _trackingController,
                onCarrierDetected: (carrier) {
                  _detectedCarrier = carrier;
                },
              ),
            ),
            const SizedBox(height: 32),
            StaggeredFadeSlide(
              index: 8,
              child: ShimmerButton(
                baseGradient: AppColors.blueButtonGradient,
                onTap: _saving ? null : _submit,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_saving)
                        const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      else ...[
                        const Icon(Icons.check_circle_outline,
                            color: Colors.white, size: 22),
                        const SizedBox(width: 10),
                        Text(
                          l.registerPurchase,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}
