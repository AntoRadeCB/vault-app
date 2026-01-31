import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_widgets.dart';
import '../models/product.dart';
import '../services/firestore_service.dart';

class EditProductScreen extends StatefulWidget {
  final Product product;
  final VoidCallback? onBack;
  final VoidCallback? onSaved;

  const EditProductScreen({
    super.key,
    required this.product,
    this.onBack,
    this.onSaved,
  });

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _brandController;
  late final TextEditingController _priceController;
  late final TextEditingController _quantityController;
  late String _selectedStatus;
  bool _saving = false;
  bool _hasChanges = false;
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product.name);
    _brandController = TextEditingController(text: widget.product.brand);
    _priceController = TextEditingController(text: widget.product.price.toString());
    _quantityController = TextEditingController(text: widget.product.quantity.toString());
    _selectedStatus = _statusToString(widget.product.status);

    // Track changes
    _nameController.addListener(_markChanged);
    _brandController.addListener(_markChanged);
    _priceController.addListener(_markChanged);
    _quantityController.addListener(_markChanged);
  }

  void _markChanged() {
    if (!_hasChanges) setState(() => _hasChanges = true);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  String _statusToString(ProductStatus status) {
    switch (status) {
      case ProductStatus.shipped:
        return 'shipped';
      case ProductStatus.inInventory:
        return 'inInventory';
      case ProductStatus.listed:
        return 'listed';
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);

    try {
      final updates = <String, dynamic>{
        'name': _nameController.text.trim(),
        'brand': _brandController.text.trim().toUpperCase(),
        'price': double.parse(_priceController.text.trim()),
        'quantity': double.parse(_quantityController.text.trim()),
        'status': _selectedStatus,
      };

      await _firestoreService.updateProduct(widget.product.id!, updates);

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
              const Text(
                'Prodotto aggiornato!',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          backgroundColor: AppColors.accentGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
        ),
      );

      widget.onSaved?.call();
      widget.onBack?.call();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore: ${e.toString()}'),
          backgroundColor: AppColors.accentRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _confirmDiscard() {
    if (!_hasChanges) {
      widget.onBack?.call();
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Modifiche non salvate',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          'Hai delle modifiche non salvate. Vuoi uscire senza salvare?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Resta', style: TextStyle(color: AppColors.accentBlue)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.onBack?.call();
            },
            child: const Text('Esci',
                style: TextStyle(color: AppColors.accentRed, fontWeight: FontWeight.bold)),
          ),
        ],
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
                    onTap: _confirmDiscard,
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
                  const Expanded(
                    child: Text(
                      'Modifica Prodotto',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  if (_hasChanges)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.accentOrange.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.accentOrange.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Text(
                        'MODIFICATO',
                        style: TextStyle(
                          color: AppColors.accentOrange,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Name
            StaggeredFadeSlide(
              index: 1,
              child: _buildField(
                label: 'Nome Oggetto',
                child: _GlowTextField(
                  controller: _nameController,
                  hintText: 'Es. Nike Air Max 90',
                  validator: (v) => (v == null || v.isEmpty) ? 'Campo obbligatorio' : null,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Brand
            StaggeredFadeSlide(
              index: 2,
              child: _buildField(
                label: 'Brand',
                child: _GlowTextField(
                  controller: _brandController,
                  hintText: 'Es. Nike, Adidas, Stone Island',
                  validator: (v) => (v == null || v.isEmpty) ? 'Campo obbligatorio' : null,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Price
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

            // Quantity
            StaggeredFadeSlide(
              index: 4,
              child: _buildField(
                label: 'Quantità',
                child: _GlowTextField(
                  controller: _quantityController,
                  hintText: '1',
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Inserisci una quantità';
                    if (double.tryParse(v) == null) return 'Quantità non valida';
                    return null;
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Status
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
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textMuted),
                      items: const [
                        DropdownMenuItem(value: 'inInventory', child: Text('In Inventario')),
                        DropdownMenuItem(value: 'shipped', child: Text('Spedito')),
                        DropdownMenuItem(value: 'listed', child: Text('In Vendita')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedStatus = value;
                            _hasChanges = true;
                          });
                        }
                      },
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Save button
            StaggeredFadeSlide(
              index: 6,
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
                        const Icon(Icons.save_outlined, color: Colors.white, size: 22),
                        const SizedBox(width: 10),
                        const Text(
                          'Salva Modifiche',
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
// Reusable glow text field
// ──────────────────────────────────────────────────
class _GlowTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final String? prefixText;
  final String? Function(String?)? validator;

  const _GlowTextField({
    required this.controller,
    required this.hintText,
    this.keyboardType,
    this.prefixText,
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
