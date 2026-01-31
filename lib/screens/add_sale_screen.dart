import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_widgets.dart';
import '../widgets/barcode_scanner_dialog.dart';
import '../widgets/tracking_input.dart';
import '../models/product.dart';
import '../models/sale.dart';
import '../models/shipment.dart';
import '../services/firestore_service.dart';
import '../services/sendcloud_service.dart';

class AddSaleScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const AddSaleScreen({super.key, this.onBack});

  @override
  State<AddSaleScreen> createState() => _AddSaleScreenState();
}

class _AddSaleScreenState extends State<AddSaleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _salePriceController = TextEditingController();
  final _feesController = TextEditingController(text: '0');
  final FirestoreService _firestoreService = FirestoreService();

  final _trackingController = TextEditingController();
  CarrierInfo? _detectedCarrier;
  Product? _selectedProduct;
  bool _saving = false;
  bool _markAsSold = true;
  bool _scanLoading = false;
  final SendcloudService _sendcloudService = SendcloudService();

  @override
  void dispose() {
    _salePriceController.dispose();
    _feesController.dispose();
    _trackingController.dispose();
    super.dispose();
  }

  double get _salePrice => double.tryParse(_salePriceController.text.trim()) ?? 0;
  double get _fees => double.tryParse(_feesController.text.trim()) ?? 0;
  double get _purchasePrice => _selectedProduct?.price ?? 0;
  double get _profit => _salePrice - _purchasePrice - _fees;

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedProduct == null) {
      _showError('Seleziona un prodotto da vendere.');
      return;
    }

    setState(() => _saving = true);

    try {
      final sale = Sale(
        productName: _selectedProduct!.name,
        salePrice: _salePrice,
        purchasePrice: _purchasePrice,
        fees: _fees,
        date: DateTime.now(),
      );

      await _firestoreService.addSale(sale);

      // Create shipment if tracking code provided
      final trackingCode = _trackingController.text.trim();
      if (trackingCode.isNotEmpty) {
        final carrier = _detectedCarrier ?? Shipment.detectCarrier(trackingCode);

        // Auto-register on Ship24
        String? trackerId;
        try {
          final result = await _sendcloudService.registerTracking(
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
          type: ShipmentType.sale,
          productName: _selectedProduct!.name,
          productId: _selectedProduct!.id,
          status: ShipmentStatus.pending,
          createdAt: DateTime.now(),
          sendcloudId: null,
          sendcloudTrackingUrl: trackerId != null ? 'https://t.ship24.com/t/$trackingCode' : null,
          sendcloudStatus: null,
        );
        await _firestoreService.addShipment(shipment);
      }

      // Optionally remove from inventory or update status
      if (_markAsSold && _selectedProduct!.id != null) {
        if (_selectedProduct!.quantity <= 1) {
          await _firestoreService.deleteProduct(_selectedProduct!.id!);
        } else {
          await _firestoreService.updateProduct(_selectedProduct!.id!, {
            'quantity': _selectedProduct!.quantity - 1,
          });
        }
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
                child: const Icon(Icons.check, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Vendita registrata! Profitto: €${_profit.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.accentGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ),
      );
      widget.onBack?.call();
    } catch (e) {
      if (!mounted) return;
      _showError('Errore: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _scanBarcode() async {
    final code = await BarcodeScannerDialog.scan(context);
    if (code == null || !mounted) return;

    setState(() => _scanLoading = true);

    try {
      final product = await _firestoreService.getProductByBarcode(code);
      if (!mounted) return;

      if (product != null) {
        setState(() => _selectedProduct = product);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Trovato: ${product.name}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.accentGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      } else {
        _showError('Nessun prodotto trovato con barcode: $code');
      }
    } catch (e) {
      if (mounted) _showError('Errore scansione: $e');
    }

    if (mounted) setState(() => _scanLoading = false);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        backgroundColor: AppColors.accentRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
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
            // Header
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
                      child: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Text(
                    'Registra Vendita',
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

            // Product selector
            StaggeredFadeSlide(
              index: 1,
              child: _buildField(
                label: 'Prodotto',
                child: Column(
                  children: [
                    // Scan barcode button
                    GestureDetector(
                      onTap: _scanLoading ? null : _scanBarcode,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppColors.accentTeal.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.accentTeal.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_scanLoading)
                              const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.accentTeal,
                                ),
                              )
                            else
                              const Icon(Icons.qr_code_scanner,
                                  color: AppColors.accentTeal, size: 20),
                            const SizedBox(width: 10),
                            const Text(
                              'Scansiona Barcode Prodotto',
                              style: TextStyle(
                                color: AppColors.accentTeal,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Dropdown
                    StreamBuilder<List<Product>>(
                  stream: _firestoreService.getProducts(),
                  builder: (context, snapshot) {
                    final products = snapshot.data ?? [];
                    if (products.isEmpty) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.accentOrange.withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.warning_amber, color: AppColors.accentOrange, size: 20),
                            SizedBox(width: 10),
                            Text(
                              'Nessun prodotto in inventario',
                              style: TextStyle(color: AppColors.accentOrange, fontSize: 14),
                            ),
                          ],
                        ),
                      );
                    }

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selectedProduct != null
                              ? AppColors.accentGreen.withValues(alpha: 0.3)
                              : Colors.white.withValues(alpha: 0.06),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedProduct?.id,
                          isExpanded: true,
                          hint: const Text(
                            'Seleziona prodotto...',
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                          dropdownColor: AppColors.surface,
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textMuted),
                          items: products.map((p) {
                            return DropdownMenuItem<String>(
                              value: p.id,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      p.name,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${p.formattedPrice} × ${p.formattedQuantity}',
                                    style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedProduct = products.firstWhere((p) => p.id == value);
                            });
                          },
                        ),
                      ),
                    );
                  },
                ),
                  ],
                ),
              ),
            ),

            // Selected product info card
            if (_selectedProduct != null) ...[
              const SizedBox(height: 16),
              StaggeredFadeSlide(
                index: 2,
                child: GlassCard(
                  padding: const EdgeInsets.all(16),
                  glowColor: AppColors.accentTeal,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.accentTeal.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.inventory_2, color: AppColors.accentTeal, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedProduct!.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_selectedProduct!.brand} · Qta: ${_selectedProduct!.formattedQuantity}',
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'COSTO',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _selectedProduct!.formattedPrice,
                            style: const TextStyle(
                              color: AppColors.accentTeal,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),

            // Sale price
            StaggeredFadeSlide(
              index: 3,
              child: _buildField(
                label: 'Prezzo di Vendita (€)',
                child: _GlowTextField(
                  controller: _salePriceController,
                  hintText: '0.00',
                  keyboardType: TextInputType.number,
                  prefixText: '€ ',
                  onChanged: (_) => setState(() {}),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Inserisci il prezzo di vendita';
                    if (double.tryParse(v) == null) return 'Prezzo non valido';
                    return null;
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Fees
            StaggeredFadeSlide(
              index: 4,
              child: _buildField(
                label: 'Commissioni / Spedizione (€)',
                child: _GlowTextField(
                  controller: _feesController,
                  hintText: '0.00',
                  keyboardType: TextInputType.number,
                  prefixText: '€ ',
                  onChanged: (_) => setState(() {}),
                  validator: (v) {
                    if (v != null && v.isNotEmpty && double.tryParse(v) == null) {
                      return 'Valore non valido';
                    }
                    return null;
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Remove from inventory toggle
            StaggeredFadeSlide(
              index: 5,
              child: GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.accentOrange.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.remove_shopping_cart, color: AppColors.accentOrange, size: 18),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rimuovi da inventario',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Scala 1 unità dal prodotto',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _markAsSold,
                      onChanged: (v) => setState(() => _markAsSold = v),
                      activeColor: AppColors.accentBlue,
                      activeTrackColor: AppColors.accentBlue.withValues(alpha: 0.3),
                      inactiveThumbColor: AppColors.textMuted,
                      inactiveTrackColor: AppColors.surface,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Profit preview card
            if (_selectedProduct != null && _salePriceController.text.isNotEmpty) ...[
              StaggeredFadeSlide(
                index: 6,
                child: GlassCard(
                  padding: const EdgeInsets.all(20),
                  glowColor: _profit >= 0 ? AppColors.accentGreen : AppColors.accentRed,
                  child: Column(
                    children: [
                      const Text(
                        'RIEPILOGO VENDITA',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildSummaryRow('Prezzo vendita', '+€${_salePrice.toStringAsFixed(2)}', AppColors.accentGreen),
                      const SizedBox(height: 8),
                      _buildSummaryRow('Costo acquisto', '-€${_purchasePrice.toStringAsFixed(2)}', AppColors.accentRed),
                      if (_fees > 0) ...[
                        const SizedBox(height: 8),
                        _buildSummaryRow('Commissioni', '-€${_fees.toStringAsFixed(2)}', AppColors.accentOrange),
                      ],
                      const SizedBox(height: 12),
                      Divider(color: Colors.white.withValues(alpha: 0.08)),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'PROFITTO',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            '${_profit >= 0 ? '+' : ''}€${_profit.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: _profit >= 0 ? AppColors.accentGreen : AppColors.accentRed,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ] else
              const SizedBox(height: 8),

            // Submit button
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
            const SizedBox(height: 24),

            StaggeredFadeSlide(
              index: 8,
              child: ShimmerButton(
                baseGradient: const LinearGradient(
                  colors: [Color(0xFF43A047), Color(0xFF2E7D32)],
                ),
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
                        const Icon(Icons.sell, color: Colors.white, size: 22),
                        const SizedBox(width: 10),
                        const Text(
                          'Conferma Vendita',
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

  Widget _buildSummaryRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
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
// Reusable glow text field (same pattern as add_item)
// ──────────────────────────────────────────────────
class _GlowTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final String? prefixText;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;

  const _GlowTextField({
    required this.controller,
    required this.hintText,
    this.keyboardType,
    this.prefixText,
    this.validator,
    this.onChanged,
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
          onChanged: widget.onChanged,
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
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.accentBlue, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.accentRed, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.accentRed, width: 1.5),
            ),
            errorStyle: const TextStyle(color: AppColors.accentRed, fontSize: 12),
          ),
        ),
      ),
    );
  }
}
