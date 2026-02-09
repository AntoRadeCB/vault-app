import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/product.dart';
import '../services/ebay_service.dart';

class EbayListingDialog extends StatefulWidget {
  final Product product;
  final EbayService ebayService;

  const EbayListingDialog({
    super.key,
    required this.product,
    required this.ebayService,
  });

  @override
  State<EbayListingDialog> createState() => _EbayListingDialogState();
}

class _EbayListingDialogState extends State<EbayListingDialog> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _quantityController;
  late TextEditingController _categoryController;
  String _condition = 'UNGRADED';
  String _cardCondition = 'Near Mint or Better';
  bool _submitting = false;
  int _availableQty = 0;
  int _alreadyListed = 0;
  bool _loadingQty = true;

  // Per TCG (183454): eBay usa Condition Descriptors
  // Condition = "Ungraded" (4000), poi Card Condition come descriptor
  static const _cardConditions = {
    'Near Mint or Better': 'Near Mint o migliore',
    'Lightly Played (Excellent)': 'Lightly Played (Eccellente)',
    'Moderately Played (Very Good)': 'Moderately Played (Molto buono)',
    'Heavily Played (Poor)': 'Heavily Played (Scarso)',
  };

  // Condizioni generiche per categorie non-TCG
  static const _genericConditions = {
    'NEW': 'Nuovo',
    'NEW_OTHER': 'Nuovo: altro',
    'LIKE_NEW': 'Come nuovo',
    'USED_EXCELLENT': 'Usato - Eccellente',
    'USED_VERY_GOOD': 'Usato - Molto buono',
    'USED_GOOD': 'Usato - Buono',
    'USED_ACCEPTABLE': 'Usato - Accettabile',
  };

  bool get _isTcg {
    final cat = _categoryController.text.trim();
    return ['183454', '183456', '183457'].contains(cat);
  }

  Map<String, String> get _conditions => _isTcg
      ? const {'UNGRADED': 'Carta non gradata'}
      : _genericConditions;

  // Per TCG, la condizione carta è sempre richiesta
  bool get _needsCardCondition => _isTcg;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _titleController = TextEditingController(
      text: '${p.name}${p.cardExpansion != null ? ' - ${p.cardExpansion}' : ''}',
    );
    _descriptionController = TextEditingController(
      text: 'Carta ${p.name}'
          '${p.cardExpansion != null ? ' dall\'espansione ${p.cardExpansion}' : ''}'
          '${p.cardRarity != null ? '. Rarità: ${p.cardRarity}' : ''}'
          '. Condizioni eccellenti.',
    );
    _priceController = TextEditingController(
      text: p.effectiveSellPrice.toStringAsFixed(2),
    );
    _quantityController = TextEditingController(text: '1');
    _categoryController = TextEditingController(text: '183454');
    _cardCondition = 'Near Mint or Better';
    _loadAvailableQty();
  }

  Future<void> _loadAvailableQty() async {
    try {
      final listings = await widget.ebayService.getListings();
      int listed = 0;
      for (final l in listings) {
        if (l.productId == widget.product.id && l.status != 'ended') {
          listed += l.quantity;
        }
      }
      final invQty = widget.product.inventoryQty > 0 
          ? widget.product.inventoryQty.toInt() 
          : widget.product.quantity.toInt();
      if (mounted) {
        setState(() {
          _alreadyListed = listed;
          _availableQty = (invQty - listed).clamp(0, 9999);
          _loadingQty = false;
          // Set default quantity to available
          if (_availableQty > 0) {
            _quantityController.text = _availableQty > 1 ? '1' : '1';
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingQty = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // Validate quantity
    final requestedQty = int.tryParse(_quantityController.text) ?? 1;
    if (requestedQty > _availableQty && !_loadingQty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Puoi listare al massimo $_availableQty ${_availableQty == 1 ? "copia" : "copie"}'),
          backgroundColor: AppColors.accentOrange,
        ),
      );
      return;
    }
    
    setState(() => _submitting = true);
    try {
      final imageUrls = <String>[];
      if (widget.product.displayImageUrl.isNotEmpty) {
        imageUrls.add(widget.product.displayImageUrl);
      }

      final data = <String, dynamic>{
        'productId': widget.product.id ?? '',
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': double.tryParse(_priceController.text) ?? 0,
        'quantity': int.tryParse(_quantityController.text) ?? 1,
        'condition': _condition,
        'categoryId': _categoryController.text.trim(),
        'imageUrls': imageUrls,
      };

      // Passa la condizione carta per TCG (sempre richiesta)
      if (_needsCardCondition) {
        data['cardCondition'] = _cardCondition;
      }

      await widget.ebayService.createListing(data);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Inserzione creata!'),
            backgroundColor: AppColors.accentGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore: $e'), backgroundColor: AppColors.accentRed),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: AppColors.headerGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.sell, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('Vendi su eBay',
                        style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.bold)),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: AppColors.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (widget.product.displayImageUrl.isNotEmpty)
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(widget.product.displayImageUrl,
                        height: 120, fit: BoxFit.contain),
                  ),
                ),
              const SizedBox(height: 16),
              _field('Titolo', _titleController),
              const SizedBox(height: 12),
              _field('Descrizione', _descriptionController, maxLines: 3),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _field('Prezzo (€)', _priceController,
                      keyboardType: TextInputType.number)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _field('Quantità', _quantityController,
                          keyboardType: TextInputType.number),
                      const SizedBox(height: 4),
                      if (!_loadingQty)
                        Text(
                          _alreadyListed > 0
                            ? 'Disponibili: $_availableQty (${_alreadyListed} già listat${_alreadyListed == 1 ? "o" : "i"})'
                            : 'Disponibili: $_availableQty',
                          style: TextStyle(
                            color: _availableQty <= 0 ? AppColors.accentRed : AppColors.textMuted,
                            fontSize: 10,
                          ),
                        ),
                    ],
                  )),
                ],
              ),
              const SizedBox(height: 12),
              const Text('Condizione',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _conditions.containsKey(_condition) ? _condition : _conditions.keys.first,
                dropdownColor: AppColors.surface,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.cardDark,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                items: _conditions.entries
                    .map((e) => DropdownMenuItem(
                        value: e.key,
                        child: Text(e.value)))
                    .toList(),
                onChanged: (v) => setState(() => _condition = v!),
              ),
              // Condizione carta (solo per TCG + Usato)
              if (_needsCardCondition) ...[
                const SizedBox(height: 12),
                const Text('Condizione della carta',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _cardCondition,
                  dropdownColor: AppColors.surface,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.cardDark,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  items: _cardConditions.entries
                      .map((e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value)))
                      .toList(),
                  onChanged: (v) => setState(() => _cardCondition = v ?? _cardCondition),
                ),
              ],
              const SizedBox(height: 12),
              _field('Categoria eBay ID', _categoryController, onChanged: (_) => setState(() {
                // Reset condition se non più valida per la nuova categoria
                if (!_conditions.containsKey(_condition)) {
                  _condition = _conditions.keys.first;
                }
              })),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: AppColors.blueButtonGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('Pubblica inserzione',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController controller,
      {int maxLines = 1, TextInputType? keyboardType, ValueChanged<String>? onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          onChanged: onChanged,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.cardDark,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }
}
