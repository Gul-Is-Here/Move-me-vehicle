import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../vehicle_details/widgets/number_plate.dart';
import '../models/vehicle_model.dart';
import 'vehicle_image_thumb.dart';

/// One owned vehicle on the Home tab. Shows only fields the vehicle
/// document actually carries — photo, nickname, make/model, colour and
/// plate — and a shortcut to its QR code, which is the point of the app.
class VehicleCard extends StatelessWidget {
  const VehicleCard({super.key, required this.vehicle, this.hasUnread = false});

  final VehicleModel vehicle;

  /// Driven by the Inbox listener rather than [VehicleModel.hasUnread],
  /// which is never populated anywhere in the app.
  final bool hasUnread;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.yellow;
    final title = vehicle.nickname.isEmpty ? vehicle.makeModel : vehicle.nickname;
    final subtitle = vehicle.nickname.isNotEmpty ? vehicle.makeModel : '';

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: () => Get.toNamed(AppRoutes.vehicleDetails, arguments: vehicle),
        borderRadius: BorderRadius.circular(24),
        splashColor: accent.withValues(alpha: 0.06),
        highlightColor: accent.withValues(alpha: 0.04),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: hasUnread ? accent.withValues(alpha: 0.55) : AppColors.border),
            boxShadow: [
              BoxShadow(
                color: hasUnread ? accent.withValues(alpha: 0.16) : Colors.black.withValues(alpha: 0.07),
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  VehicleImageThumb(photoPaths: vehicle.photoPaths),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.headingSm.copyWith(color: AppColors.ink, fontSize: 16.5, letterSpacing: 0),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: vehicle.color,
                                border: Border.all(color: AppColors.border),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                [subtitle, vehicle.colorName].where((s) => s.isNotEmpty).join(' · '),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.caption.copyWith(color: AppColors.muted, fontSize: 12.5),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (hasUnread) const _UnreadBadge() else Icon(Icons.chevron_right_rounded, color: AppColors.faint),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: NumberPlate(plate: vehicle.plateNumber, compact: true),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.qr_code_2_rounded, size: 18, color: accent),
                        const SizedBox(width: 6),
                        Text('Show QR', style: AppTextStyles.label.copyWith(color: accent, letterSpacing: 0, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Paired with the accent card border, so "has unread" is never carried by
/// colour alone.
class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge();

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.yellow;
    return Semantics(
      label: 'Unread messages',
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.4), blurRadius: 8)],
          ),
          child: Text(
            'New',
            style: AppTextStyles.label.copyWith(color: AppColors.background, letterSpacing: 0, fontWeight: FontWeight.w800, fontSize: 11),
          ),
        ),
      ),
    );
  }
}
