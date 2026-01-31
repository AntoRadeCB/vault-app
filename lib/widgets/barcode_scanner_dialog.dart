import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../theme/app_theme.dart';

/// Full-screen barcode scanner overlay.
/// Returns the scanned barcode string via Navigator.pop.
class BarcodeScannerDialog extends StatefulWidget {
  const BarcodeScannerDialog({super.key});

  /// Show the scanner and return the scanned barcode, or null if cancelled.
  static Future<String?> scan(BuildContext context) {
    return Navigator.of(context).push<String>(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) => const BarcodeScannerDialog(),
        transitionsBuilder: (_, anim, __, child) {
          return FadeTransition(opacity: anim, child: child);
        },
        transitionDuration: const Duration(milliseconds: 250),
      ),
    );
  }

  @override
  State<BarcodeScannerDialog> createState() => _BarcodeScannerDialogState();
}

class _BarcodeScannerDialogState extends State<BarcodeScannerDialog> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );
  bool _scanned = false;
  String? _lastCode;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_scanned) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    setState(() {
      _scanned = true;
      _lastCode = barcode.rawValue!;
    });

    // Short delay so the user sees the detected code, then pop
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) Navigator.of(context).pop(_lastCode);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera feed
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),

          // Dark overlay with cutout
          _ScanOverlay(scanned: _scanned),

          // Top bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    _circleButton(
                      icon: Icons.close,
                      onTap: () => Navigator.of(context).pop(null),
                    ),
                    const Expanded(
                      child: Text(
                        'Scansiona Barcode',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _circleButton(
                      icon: Icons.flash_on,
                      onTap: () => _controller.toggleTorch(),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom info
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: _scanned
                      ? AppColors.accentGreen.withValues(alpha: 0.9)
                      : AppColors.surface.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _scanned
                        ? AppColors.accentGreen.withValues(alpha: 0.5)
                        : Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _scanned ? Icons.check_circle : Icons.qr_code_scanner,
                      color: Colors.white,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        _scanned
                            ? 'Codice: $_lastCode'
                            : 'Inquadra il codice a barre del prodotto',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}

/// Draws a dark overlay with a transparent scanning window
class _ScanOverlay extends StatelessWidget {
  final bool scanned;
  const _ScanOverlay({required this.scanned});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scanSize = constraints.maxWidth * 0.7;
        final top = (constraints.maxHeight - scanSize) / 2;
        final left = (constraints.maxWidth - scanSize) / 2;

        return Stack(
          children: [
            // Dark overlay
            ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withValues(alpha: 0.6),
                BlendMode.srcOut,
              ),
              child: Stack(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      backgroundBlendMode: BlendMode.dstOut,
                    ),
                  ),
                  Positioned(
                    top: top,
                    left: left,
                    child: Container(
                      width: scanSize,
                      height: scanSize,
                      decoration: BoxDecoration(
                        color: Colors.red, // any color, will be cut out
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Corner markers
            Positioned(
              top: top - 2,
              left: left - 2,
              child: _corner(scanned, topLeft: true),
            ),
            Positioned(
              top: top - 2,
              right: left - 2,
              child: _corner(scanned, topRight: true),
            ),
            Positioned(
              bottom: constraints.maxHeight - top - scanSize - 2,
              left: left - 2,
              child: _corner(scanned, bottomLeft: true),
            ),
            Positioned(
              bottom: constraints.maxHeight - top - scanSize - 2,
              right: left - 2,
              child: _corner(scanned, bottomRight: true),
            ),
          ],
        );
      },
    );
  }

  Widget _corner(bool scanned,
      {bool topLeft = false,
      bool topRight = false,
      bool bottomLeft = false,
      bool bottomRight = false}) {
    final color = scanned ? AppColors.accentGreen : AppColors.accentBlue;
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        border: Border(
          top: (topLeft || topRight)
              ? BorderSide(color: color, width: 3)
              : BorderSide.none,
          bottom: (bottomLeft || bottomRight)
              ? BorderSide(color: color, width: 3)
              : BorderSide.none,
          left: (topLeft || bottomLeft)
              ? BorderSide(color: color, width: 3)
              : BorderSide.none,
          right: (topRight || bottomRight)
              ? BorderSide(color: color, width: 3)
              : BorderSide.none,
        ),
      ),
    );
  }
}
