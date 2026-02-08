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
  String _condition = 'USED_EXCELLENT';
  bool _submitting = false;

  static const _conditions = {
    'NEW': 'Nuovo',
    'LIKE_NEW': 'Come nuovo',
    'USED_EXCELLENT': 'Usato - Eccellente',
    'USED_VERY_GOOD': 'Usato - Molto buono',
    'USED_GOOD': 'Usato - Buono',
    'USED_ACCEPTABLE': 'Usato - Accettabile',
  };

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
    // TCG cards category on eBay Italy
    _categoryController = TextEditingController(text: '183454');
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
    setState(() => _submitting = true);
    try {
      final imageUrls = <String>[];
      if (widget.product.displayImageUrl.isNotEmpty) {
        imageUrls.add(widget.product.displayImageUrl);
      }

      await widget.ebayService.createListing({
        'productId': widget.product.id ?? '',
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': double.tryParse(_priceController.text) ?? 0,
        'quantity': int.tryParse(_quantityController.text) ?? 1,
        'condition': _condition,
        'categoryId': _categoryController.text.trim(),
        'imageUrls': imageUrls,
      });

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
              // Preview
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
                  Expanded(child: _field('Quantità', _quantityController,
                      keyboardType: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 12),
              const Text('Condizione',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _condition,
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
              const SizedBox(height: 12),
              _field('Categoria eBay ID', _categoryController),
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
      {int maxLines = 1, TextInputType? keyboardType}) {
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
