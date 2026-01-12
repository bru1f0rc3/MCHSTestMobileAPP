import 'package:flutter/material.dart';
import 'package:mchs_mobile_app/core/theme/app_theme.dart';

class CustomCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? color;
  final double? elevation;

  const CustomCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.color,
    this.elevation,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: elevation ?? 0,
      color: color ?? context.surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.borderRadiusLg,
        side: BorderSide(color: context.borderColor, width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.borderRadiusLg,
        child: Padding(
          padding: padding ?? AppSpacing.paddingMd,
          child: child,
        ),
      ),
    );
  }
}
