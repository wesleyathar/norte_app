import 'package:flutter/material.dart';

import '../../../domain/models/institution.dart';

/// Logo circular da instituição: usa as iniciais sobre a cor da marca.
class InstitutionLogo extends StatelessWidget {
  const InstitutionLogo({
    super.key,
    required this.institution,
    this.size = 44,
  });

  final FinancialInstitution institution;
  final double size;

  @override
  Widget build(BuildContext context) {
    final brightness = ThemeData.estimateBrightnessForColor(
      institution.brandColor,
    );
    final onBrand =
        brightness == Brightness.dark ? Colors.white : Colors.black87;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: institution.brandColor,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        institution.logoAsset,
        style: TextStyle(
          color: onBrand,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.34,
        ),
      ),
    );
  }
}
