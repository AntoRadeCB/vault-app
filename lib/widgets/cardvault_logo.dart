import 'package:flutter/material.dart';

class CardVaultLogo extends StatelessWidget {
  final double size;
  
  const CardVaultLogo({super.key, this.size = 80});
  
  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Image.asset(
        'assets/images/cardvault_logo.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );
  }
}
