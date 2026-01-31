import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/shipment.dart';

/// Optional tracking code input with carrier auto-detection.
/// Returns tracking code and detected carrier via controllers.
class TrackingInput extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<CarrierInfo?>? onCarrierDetected;

  const TrackingInput({
    super.key,
    required this.controller,
    this.onCarrierDetected,
  });

  @override
  State<TrackingInput> createState() => _TrackingInputState();
}

class _TrackingInputState extends State<TrackingInput> {
  bool _expanded = false;
  CarrierInfo? _carrier;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final text = widget.controller.text.trim();
    if (text.length >= 6) {
      final detected = Shipment.detectCarrier(text);
      if (_carrier?.id != detected.id) {
        setState(() => _carrier = detected);
        widget.onCarrierDetected?.call(detected);
      }
    } else if (_carrier != null) {
      setState(() => _carrier = null);
      widget.onCarrierDetected?.call(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_expanded) {
      return GestureDetector(
        onTap: () => setState(() => _expanded = true),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.local_shipping_outlined,
                  color: AppColors.textMuted.withValues(alpha: 0.7), size: 18),
              const SizedBox(width: 8),
              Text(
                '+ Aggiungi Tracking (facoltativo)',
                style: TextStyle(
                  color: AppColors.textMuted.withValues(alpha: 0.7),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.local_shipping_outlined, color: AppColors.accentTeal, size: 16),
            const SizedBox(width: 6),
            const Text(
              'TRACKING SPEDIZIONE',
              style: TextStyle(
                color: AppColors.accentTeal,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () {
                widget.controller.clear();
                setState(() {
                  _expanded = false;
                  _carrier = null;
                });
                widget.onCarrierDetected?.call(null);
              },
              child: const Text(
                'Rimuovi',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Focus(
          onFocusChange: (f) => setState(() => _focused = f),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: _focused
                  ? [
                      BoxShadow(
                        color: AppColors.accentTeal.withValues(alpha: 0.15),
                        blurRadius: 16,
                      ),
                    ]
                  : [],
            ),
            child: TextField(
              controller: widget.controller,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontFamily: 'monospace',
                letterSpacing: 1.5,
              ),
              decoration: InputDecoration(
                hintText: 'Es. RR123456789IT',
                hintStyle: const TextStyle(color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.surface,
                prefixIcon: const Icon(Icons.qr_code, color: AppColors.accentTeal, size: 20),
                suffixIcon: _carrier != null
                    ? Padding(
                        padding: const EdgeInsets.all(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.accentTeal.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _carrier!.name,
                            style: const TextStyle(
                              color: AppColors.accentTeal,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      )
                    : null,
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
                  borderSide: const BorderSide(color: AppColors.accentTeal, width: 1.5),
                ),
              ),
            ),
          ),
        ),
        if (_carrier != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.check_circle, color: AppColors.accentGreen, size: 14),
              const SizedBox(width: 6),
              Text(
                'Corriere rilevato: ${_carrier!.name}',
                style: const TextStyle(
                  color: AppColors.accentGreen,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
