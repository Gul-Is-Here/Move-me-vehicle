import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../app/widgets/bound_view.dart';
import '../../../app/widgets/dot_grid_background.dart';
import '../../../app/widgets/motion.dart';
import '../../../app/widgets/shimmer.dart';
import '../../../app/widgets/viewfinder_painter.dart';
import '../controllers/dashboard_controller.dart';
import '../controllers/home_tab_controller.dart';
import '../models/vehicle_model.dart';
import '../widgets/vehicle_card.dart';
import '../widgets/vehicle_qr_thumb.dart';

/// Home: a gradient hero with who you are and a live glance at your
/// vehicles and unread messages, the scan action, quick shortcuts, and the
/// vehicles you own.
///
/// Every value shown comes from the existing controller — the resident's
/// first name, their vehicle documents, and the unread state the Inbox tab
/// is already listening to. Nothing on this screen is generated.
class HomeTabView extends BoundView<HomeTabController> {
  const HomeTabView({super.key});

  @override
  Widget buildWith(BuildContext context, HomeTabController controller) {
    return RefreshIndicator(
      onRefresh: controller.reload,
      color: AppColors.yellow,
      backgroundColor: AppColors.surface,
      child: CustomScrollView(
        // Always scrollable so pull-to-refresh still works on the empty
        // and error states, which are shorter than the viewport.
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            sliver: SliverToBoxAdapter(
              child: RiseIn(order: 0, child: _HeroCard(controller: controller)),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            sliver: SliverToBoxAdapter(
              child: RiseIn(
                order: 1,
                child: _ScanCard(onTap: () => Get.toNamed(AppRoutes.qrScanner)),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            sliver: SliverToBoxAdapter(
              child: RiseIn(order: 2, child: _QuickActions(controller: controller)),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 28, 16, 14),
            sliver: SliverToBoxAdapter(
              child: RiseIn(order: 3, child: _SectionHeader(controller: controller)),
            ),
          ),
          SliverPadding(
            // The bottom inset clears the floating nav dock, which the
            // dashboard lets content scroll behind.
            padding: EdgeInsets.fromLTRB(16, 0, 16, 28 + MediaQuery.paddingOf(context).bottom),
            sliver: Obx(() {
              if (controller.hasError.value) {
                return SliverToBoxAdapter(child: _ErrorState(controller: controller));
              }
              if (controller.isLoading.value) {
                return const SliverToBoxAdapter(child: _VehiclesSkeleton());
              }

              final vehicles = controller.vehicles;
              if (vehicles.isEmpty) {
                return SliverToBoxAdapter(
                  child: RiseIn(order: 4, child: _EmptyState(controller: controller)),
                );
              }

              return SliverList.separated(
                itemCount: vehicles.length,
                separatorBuilder: (_, _) => const SizedBox(height: 14),
                itemBuilder: (context, index) => RiseIn(
                  key: ValueKey(vehicles[index].id),
                  order: 4 + index.clamp(0, 5),
                  child: Pressable(
                    child: _ReactiveVehicleCard(controller: controller, vehicle: vehicles[index]),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

/// Switches the dashboard tab, when Home is mounted inside the dashboard.
void _goToTab(int index) {
  if (Get.isRegistered<DashboardController>()) {
    Get.find<DashboardController>().changeTab(index);
  }
}

/// Fixed deep-indigo hero gradient: dark enough in both themes for white
/// text (the light dark-mode accent isn't).
const _heroTop = Color(0xFF6366F1);
const _heroBottom = Color(0xFF3730A3);

/// Only the unread state reacts here, so a new message repaints one card
/// rather than the whole list.
class _ReactiveVehicleCard extends StatelessWidget {
  const _ReactiveVehicleCard({required this.controller, required this.vehicle});

  final HomeTabController controller;
  final VehicleModel vehicle;

  @override
  Widget build(BuildContext context) {
    if (!controller.hasUnreadSource) return VehicleCard(vehicle: vehicle);
    return Obx(() => VehicleCard(vehicle: vehicle, hasUnread: controller.hasUnreadFor(vehicle.id)));
  }
}

// ---------------------------------------------------------------------------
// Hero
// ---------------------------------------------------------------------------

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.controller});

  final HomeTabController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_heroTop, _heroBottom],
        ),
        boxShadow: [
          BoxShadow(color: _heroBottom.withValues(alpha: 0.35), blurRadius: 30, offset: const Offset(0, 14)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          const Positioned.fill(
            child: DotGridBackground(color: Colors.white, center: Alignment(0.95, -0.9), radius: 0.9),
          ),
          Positioned(right: -70, top: -90, child: _orb(220, 0.10)),
          Positioned(left: -40, bottom: -80, child: _orb(160, 0.07)),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(_greetingIcon, size: 15, color: Colors.white.withValues(alpha: 0.85)),
                              const SizedBox(width: 6),
                              Text(
                                controller.greeting,
                                style: AppTextStyles.label.copyWith(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  letterSpacing: 0,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Obx(
                            () => Text(
                              controller.residentFirstName.value.isEmpty ? 'there' : controller.residentFirstName.value,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.displayLg.copyWith(color: Colors.white, fontSize: 30, height: 1.1),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Obx(() => _Avatar(name: controller.residentFirstName.value)),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Obx(
                        () => _GlassStat(
                          icon: Icons.directions_car_filled_rounded,
                          label: 'Vehicles',
                          value: controller.isLoading.value || controller.hasError.value
                              ? null
                              : controller.vehicles.length,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: controller.hasUnreadSource
                          ? Obx(() => _unreadStat(controller.unreadCount))
                          : _unreadStat(0),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _unreadStat(int count) => _GlassStat(
    icon: Icons.mark_chat_unread_rounded,
    label: 'Unread',
    value: count,
    highlight: count > 0,
    onTap: () => _goToTab(1),
  );

  static Widget _orb(double size, double alpha) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: alpha)),
  );

  IconData get _greetingIcon {
    final hour = DateTime.now().hour;
    if (hour < 12) return Icons.wb_sunny_outlined;
    if (hour < 17) return Icons.wb_cloudy_outlined;
    return Icons.nightlight_outlined;
  }
}

/// The resident's initial in a frosted circle; opens the Profile tab.
class _Avatar extends StatelessWidget {
  const _Avatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final hasName = name.isNotEmpty && name != 'there';

    return Semantics(
      button: true,
      label: 'Open profile',
      child: Pressable(
        onTap: () => _goToTab(2),
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.45), width: 1.5),
          ),
          child: Center(
            child: hasName
                ? Text(name.characters.first.toUpperCase(), style: AppTextStyles.headingSm.copyWith(color: Colors.white))
                : const Icon(Icons.person_rounded, color: Colors.white, size: 22),
          ),
        ),
      ),
    );
  }
}

/// A frosted number tile that sits on the hero gradient.
class _GlassStat extends StatelessWidget {
  const _GlassStat({required this.icon, required this.label, required this.value, this.highlight = false, this.onTap});

  final IconData icon;
  final String label;

  /// Null while the number isn't known yet (loading or errored).
  final int? value;
  final bool highlight;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final valueStyle = AppTextStyles.headingLg.copyWith(color: Colors.white, fontSize: 22, height: 1.1);

    final tile = AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: highlight ? 0.24 : 0.14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: highlight ? 0.5 : 0.22)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(11)),
            child: Icon(icon, size: 18, color: _heroBottom),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                value == null
                    ? Text('–', style: valueStyle)
                    : TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: value!.toDouble()),
                        duration: const Duration(milliseconds: 900),
                        curve: Curves.easeOutCubic,
                        builder: (context, v, _) => Text('${v.round()}', style: valueStyle),
                      ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(color: Colors.white.withValues(alpha: 0.85), fontSize: 11.5, height: 1.2),
                ),
              ],
            ),
          ),
          if (onTap != null) Icon(Icons.chevron_right_rounded, size: 18, color: Colors.white.withValues(alpha: 0.8)),
        ],
      ),
    );

    if (onTap == null) return tile;
    return Semantics(button: true, label: '$value $label messages', child: Pressable(onTap: onTap, child: tile));
  }
}

// ---------------------------------------------------------------------------
// Scan card
// ---------------------------------------------------------------------------

/// The primary action: "blocked in? scan their sticker". A live viewfinder
/// sweeps a scan line over a QR glyph a few times, then rests.
class _ScanCard extends StatefulWidget {
  const _ScanCard({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_ScanCard> createState() => _ScanCardState();
}

class _ScanCardState extends State<_ScanCard> with SingleTickerProviderStateMixin {
  late final _loop = AnimationController(vsync: this, duration: const Duration(milliseconds: 2800));
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    // A few sweeps to draw the eye, then rest — no endless animation
    // burning battery on the app's most-visited screen.
    if (!MediaQuery.of(context).disableAnimations) _loop.repeat(count: 3);
  }

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.yellow;

    return Semantics(
      button: true,
      label: 'Scan a vehicle QR code to message its owner',
      child: Pressable(
        scale: 0.98,
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onTap();
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 18, offset: const Offset(0, 6))],
          ),
          child: Row(
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(child: ExcludeSemantics(child: _LiveScanGlyph(loop: _loop, color: accent))),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Blocked in?', style: AppTextStyles.headingSm.copyWith(color: AppColors.ink, fontSize: 18)),
                    const SizedBox(height: 4),
                    Text(
                      "Scan the car's sticker to message its owner — privately.",
                      style: AppTextStyles.caption.copyWith(color: AppColors.muted, fontSize: 12.5, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [accent, AppColors.accentDeep]),
                  boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.35), blurRadius: 14, offset: const Offset(0, 6))],
                ),
                child: Icon(Icons.qr_code_scanner_rounded, size: 21, color: AppColors.background),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LiveScanGlyph extends StatelessWidget {
  const _LiveScanGlyph({required this.loop, required this.color});

  final Animation<double> loop;
  final Color color;

  static const _size = 52.0;
  static const _inner = 8.0;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: loop,
      builder: (context, _) {
        final v = loop.value;
        final scanning = loop.isAnimating;
        // Down and back up, easing at both ends.
        final sweep = (1 - math.cos(v * 2 * math.pi)) / 2;
        final breathe = 1.5 * math.sin(v * 2 * math.pi);

        return SizedBox.square(
          dimension: _size,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              CustomPaint(
                size: const Size.square(_size),
                painter: ViewfinderPainter(gap: breathe, color: color, arm: 12, radius: 7, strokeWidth: 2.5),
              ),
              Center(
                child: CustomPaint(size: const Size.square(26), painter: QrGlyphPainter(color: color)),
              ),
              if (scanning)
                Positioned(
                  left: _inner - 3,
                  right: _inner - 3,
                  top: _inner + sweep * (_size - _inner * 2) - 1,
                  height: 2,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      gradient: LinearGradient(colors: [color.withValues(alpha: 0), color, color.withValues(alpha: 0)]),
                      boxShadow: [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 8, spreadRadius: 1)],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Quick actions
// ---------------------------------------------------------------------------

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.controller});

  final HomeTabController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _QuickAction(icon: Icons.add_rounded, label: 'Add vehicle', onTap: controller.addVehicle)),
        const SizedBox(width: 10),
        Expanded(child: _QuickAction(icon: Icons.chat_bubble_outline_rounded, label: 'Messages', onTap: () => _goToTab(1))),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickAction(
            icon: Icons.receipt_long_outlined,
            label: 'My orders',
            onTap: () => Get.toNamed(AppRoutes.myOrders),
          ),
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.yellow;
    return Semantics(
      button: true,
      label: label,
      child: Pressable(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: accent.withValues(alpha: 0.12), shape: BoxShape.circle),
                child: Icon(icon, size: 20, color: accent),
              ),
              const SizedBox(height: 8),
              ExcludeSemantics(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.label.copyWith(color: AppColors.ink, letterSpacing: 0, fontSize: 12.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Vehicles section
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.controller});

  final HomeTabController controller;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.yellow;
    return Row(
      children: [
        Text('Your vehicles', style: AppTextStyles.headingSm.copyWith(color: AppColors.ink, fontSize: 19)),
        const SizedBox(width: 8),
        Obx(() {
          if (controller.isLoading.value || controller.hasError.value || controller.vehicles.isEmpty) {
            return const SizedBox.shrink();
          }
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(color: accent.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(20)),
            child: Text(
              '${controller.vehicles.length}',
              style: AppTextStyles.label.copyWith(color: accent, letterSpacing: 0, fontWeight: FontWeight.w800),
            ),
          );
        }),
        const Spacer(),
        _AddVehicleButton(onTap: controller.addVehicle),
      ],
    );
  }
}

class _AddVehicleButton extends StatelessWidget {
  const _AddVehicleButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.yellow;

    return Semantics(
      button: true,
      label: 'Add a vehicle',
      child: Pressable(
        onTap: onTap,
        child: Container(
          height: 36,
          padding: const EdgeInsets.fromLTRB(10, 0, 14, 0),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accent.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded, size: 17, color: accent),
              const SizedBox(width: 4),
              Text('Add', style: AppTextStyles.label.copyWith(color: accent, letterSpacing: 0, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mirrors [VehicleCard]'s geometry — same radius, padding, thumb and plate
/// row — so the real cards drop in without the list shifting.
class _VehiclesSkeleton extends StatelessWidget {
  const _VehiclesSkeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: Column(
        children: [
          for (var i = 0; i < 3; i++) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const ShimmerBox(width: 56, height: 56, radius: 16),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            ShimmerBox(width: 130, height: 15),
                            SizedBox(height: 7),
                            ShimmerBox(width: 92, height: 12),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Row(
                    children: [
                      ShimmerBox(width: 150, height: 40, radius: 10),
                      Spacer(),
                      ShimmerBox(width: 92, height: 36, radius: 18),
                    ],
                  ),
                ],
              ),
            ),
            if (i != 2) const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.controller});

  final HomeTabController controller;

  @override
  Widget build(BuildContext context) {
    return HomeStateBlock(
      icon: Icons.directions_car_filled_outlined,
      title: 'No vehicles yet',
      subtitle:
          'Add your first vehicle and Park Vehicle generates a QR sticker for it. '
          'Anyone who scans it can message you without seeing your number.',
      action: _AddVehicleButton(onTap: controller.addVehicle),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.controller});

  final HomeTabController controller;

  @override
  Widget build(BuildContext context) {
    return HomeStateBlock(
      icon: Icons.wifi_off_rounded,
      title: 'Something went wrong',
      subtitle: "We couldn't load your vehicles. Check your connection and try again.",
      action: Semantics(
        button: true,
        child: Material(
          color: AppColors.yellow,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: controller.reload,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Text('Try again', style: AppTextStyles.buttonLabel.copyWith(color: AppColors.background, fontSize: 14)),
            ),
          ),
        ),
      ),
    );
  }
}
