import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_widgets.dart';
import '../widgets/barcode_scanner_dialog.dart';
import '../widgets/tracking_input.dart';
import '../models/product.dart';
import '../models/purchase.dart';
import '../models/shipment.dart';
import '../services/firestore_service.dart';

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
  String _selectedWorkspace = 'Reselling Vinted 2025';
  String _selectedStatus = 'inInventory';
  bool _saving = false;
  bool _barcodeLoading = false;
  final FirestoreService _firestoreService = FirestoreService();

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

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Prodotto trovato: ${existing.name}',
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.qr_code, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Barcode: $code — compila i dati del prodotto',
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
        final shipment = Shipment(
          trackingCode: trackingCode,
          carrier: carrier.id,
          carrierName: carrier.name,
          type: ShipmentType.purchase,
          productName: product.name,
          productId: productRef.id,
          status: ShipmentStatus.pending,
          createdAt: DateTime.now(),
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
              const Text(
                'Acquisto registrato con successo!',
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
                  const Text(
                    'Nuovo Acquisto',
                    style: TextStyle(
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
                label: 'Nome Oggetto',
                child: _GlowTextField(
                  controller: _nameController,
                  hintText: 'Es. Nike Air Max 90',
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Campo obbligatorio' : null,
                  suffixIcon: ScaleOnPress(
                    onTap: _barcodeLoading ? null : _scanBarcode,
                    child: Container(
                      margin: const EdgeInsets.all(8),
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
                ),
              ),
            ),
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
                            const Text(
                              'BARCODE',
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
                label: 'Brand',
                child: _GlowTextField(
                  controller: _brandController,
                  hintText: 'Es. Nike, Adidas, Stone Island',
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Campo obbligatorio' : null,
                ),
              ),
            ),
            const SizedBox(height: 24),
            StaggeredFadeSlide(
              index: 3,
              child: _buildField(
                label: 'Prezzo Acquisto (€)',
                child: _GlowTextField(
                  controller: _priceController,
                  hintText: '0.00',
                  keyboardType: TextInputType.number,
                  prefixText: '€ ',
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Inserisci un prezzo';
                    if (double.tryParse(v) == null) return 'Prezzo non valido';
                    return null;
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
            StaggeredFadeSlide(
              index: 4,
              child: _buildField(
                label: 'Quantità',
                child: _GlowTextField(
                  controller: _quantityController,
                  hintText: '1',
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Inserisci una quantità';
                    }
                    if (double.tryParse(v) == null) {
                      return 'Quantità non valida';
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
                label: 'Stato',
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
                      items: const [
                        DropdownMenuItem(
                            value: 'inInventory',
                            child: Text('In Inventario')),
                        DropdownMenuItem(
                            value: 'shipped',
                            child: Text('Spedito')),
                        DropdownMenuItem(
                            value: 'listed',
                            child: Text('In Vendita')),
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
                label: 'Workspace',
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
                        const Text(
                          'Registra Acquisto',
                          style: TextStyle(
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

// ──────────────────────────────────────────────────
// Text field with blue glow on focus
// ──────────────────────────────────────────────────
class _GlowTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final String? prefixText;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  const _GlowTextField({
    required this.controller,
    required this.hintText,
    this.keyboardType,
    this.prefixText,
    this.suffixIcon,
    this.validator,
  });

  @override
  State<_GlowTextField> createState() => _GlowTextFieldState();
}

class _GlowTextFieldState extends State<_GlowTextField> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (f) => setState(() => _focused = f),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: _focused
              ? [
                  BoxShadow(
                    color: AppColors.accentBlue.withValues(alpha: 0.15),
                    blurRadius: 16,
                  ),
                ]
              : [],
        ),
        child: TextFormField(
          controller: widget.controller,
          keyboardType: widget.keyboardType,
          validator: widget.validator,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          decoration: InputDecoration(
            hintText: widget.hintText,
            prefixText: widget.prefixText,
            prefixStyle: const TextStyle(
              color: AppColors.accentBlue,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            filled: true,
            fillColor: AppColors.surface,
            suffixIcon: widget.suffixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.accentBlue,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.accentRed,
                width: 1.5,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.accentRed,
                width: 1.5,
              ),
            ),
            errorStyle: const TextStyle(
              color: AppColors.accentRed,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
