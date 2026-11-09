import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../app/theme/theme_controller.dart';
import '../../../app/utils/auth_input.dart';
import '../../../app/widgets/bound_view.dart';
import '../../../app/widgets/dot_grid_background.dart';
import '../../../app/widgets/motion.dart';
import '../../../app/widgets/shimmer.dart';
import '../../auth/widgets/auth_primary_button.dart';
import '../../vehicle/widgets/vehicle_form_field.dart';
import '../controllers/home_tab_controller.dart';
import '../controllers/inbox_controller.dart';
import '../controllers/profile_controller.dart';

const _danger = Color(0xFFE5675E);

/// Fixed deep-indigo hero gradient (same as Home): dark enough in both
/// themes for white text.
const _heroTop = Color(0xFF6366F1);
const _heroBottom = Color(0xFF3730A3);

/// Icon tints for settings rows, so each group reads at a glance.
const _tintEmerald = Color(0xFF10B981);
const _tintSky = Color(0xFF0EA5E9);
const _tintAmber = Color(0xFFF59E0B);
const _tintSlate = Color(0xFF64748B);

class ProfileView extends BoundView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget buildWith(BuildContext context, ProfileController controller) {
    return Obx(() {
      if (controller.isLoading.value) return const _LoadingState();
      return _ProfileForm(
        controller: controller,
        phone: controller.phoneNumber.value,
        cnic: controller.cnic.value,
      );
    });
  }
}

class _ProfileForm extends StatelessWidget {
  const _ProfileForm({required this.controller, required this.phone, required this.cnic});

  final ProfileController controller;
  final String phone;
  final String cnic;

  @override
  Widget build(BuildContext context) {
    return ListView(
      // The bottom inset clears the floating nav dock.
      padding: EdgeInsets.fromLTRB(16, 8, 16, 40 + MediaQuery.paddingOf(context).bottom),
      children: [
        RiseIn(order: 0, child: _HeroCard(controller: controller, phone: phone)),

        // No exit animation on purpose: once permission is granted the
        // banner is gone in the same frame.
        Obx(
          () => controller.notificationsPermitted.value
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: RiseIn(
                    order: 1,
                    child: _NotificationsOffBanner(onTapRecheck: controller.recheckNotificationPermission),
                  ),
                ),
        ),

        RiseIn(
          order: 1,
          child: _Group(
            title: 'Personal info',
            children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    VehicleFormField(
                      label: 'Full Name',
                      controller: controller.name,
                      fillColor: AppColors.background,
                      inputFormatters: nameInputFormatters,
                    ),
                    const SizedBox(height: 12),
                    Obx(
                      () => AuthPrimaryButton(
                        label: 'Save Changes',
                        isLoading: controller.isSaving.value,
                        onPressed: controller.save,
                        height: 50,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        RiseIn(
          order: 2,
          child: _Group(
            title: 'Verified identity',
            children: [
              _SettingsRow(
                icon: Icons.phone_iphone_rounded,
                tint: _tintEmerald,
                title: phone.isEmpty ? 'Not available' : phone,
                subtitle: "Phone number · can't be changed without re-verification",
                trailing: const _VerifiedBadge(),
              ),
              if (cnic.isNotEmpty)
                // CNIC — read-only, used for identity verification only (FR-01.1).
                _SettingsRow(
                  icon: Icons.badge_outlined,
                  tint: _tintSky,
                  title: cnic,
                  subtitle: 'CNIC · used for identity verification only',
                  trailing: Icon(Icons.lock_outline_rounded, size: 17, color: AppColors.faint),
                ),
            ],
          ),
        ),

        RiseIn(order: 3, child: _ReachPreferenceGroup(controller: controller)),

        const RiseIn(order: 3, child: _AppearanceGroup()),

        RiseIn(
          order: 4,
          child: _Group(
            title: 'QR stickers',
            children: [
              _SettingsRow(
                icon: Icons.local_shipping_outlined,
                tint: _tintAmber,
                title: 'My Orders',
                subtitle: 'Track your QR sticker orders',
                onTap: controller.openMyOrders,
              ),
            ],
          ),
        ),

        RiseIn(
          order: 5,
          child: _Group(
            title: 'Account',
            children: [
              _SettingsRow(
                icon: Icons.logout_rounded,
                tint: _tintSlate,
                title: 'Log Out',
                subtitle: 'Sign out of Park Vehicle on this phone',
                onTap: controller.logout,
              ),
              Obx(
                () => _SettingsRow(
                  icon: Icons.delete_outline_rounded,
                  tint: _danger,
                  title: controller.isDeleting.value ? 'Deleting account…' : 'Delete Account',
                  subtitle: 'Permanently remove your account and data',
                  danger: true,
                  busy: controller.isDeleting.value,
                  onTap: controller.isDeleting.value ? null : controller.deleteAccount,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        const RiseIn(order: 6, child: _Footer()),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Hero
// ---------------------------------------------------------------------------

/// Gradient header with the resident's avatar, live name (it follows the
/// Full Name field as it's edited), verified badge, phone, and a glance at
/// their vehicles and conversations when those tabs are loaded.
class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.controller, required this.phone});

  final ProfileController controller;
  final String phone;

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
        boxShadow: [BoxShadow(color: _heroBottom.withValues(alpha: 0.35), blurRadius: 30, offset: const Offset(0, 14))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          const Positioned.fill(
            child: DotGridBackground(color: Colors.white, center: Alignment(0, -1), radius: 1.0),
          ),
          Positioned(right: -70, top: -90, child: _orb(220, 0.10)),
          Positioned(left: -50, bottom: -90, child: _orb(180, 0.07)),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 24, 18, 18),
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller.name,
              builder: (context, value, _) {
                final name = value.text.trim();
                return Column(
                  children: [
                    _Avatar(initials: _initialsOf(name)),
                    const SizedBox(height: 14),
                    Text(
                      name.isEmpty ? 'Your name' : name,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.displayLg.copyWith(color: Colors.white, fontSize: 26, height: 1.15),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _HeroChip(icon: Icons.verified_rounded, label: 'Verified Resident'),
                        if (phone.isNotEmpty) _HeroChip(icon: Icons.phone_rounded, label: phone),
                      ],
                    ),
                    const _HeroStats(),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static Widget _orb(double size, double alpha) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: alpha)),
  );

  static String _initialsOf(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first).toUpperCase();
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTextStyles.label.copyWith(color: Colors.white, letterSpacing: 0, fontWeight: FontWeight.w700, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

/// White initials disc inside a ring that sweeps once around on arrival.
class _Avatar extends StatelessWidget {
  const _Avatar({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: reduceMotion ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 1400),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => CustomPaint(painter: _RingPainter(progress: t), child: child),
      child: Container(
        width: 92,
        height: 92,
        padding: const EdgeInsets.all(6),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 16, offset: const Offset(0, 6))],
          ),
          alignment: Alignment.center,
          child: initials.isEmpty
              ? const Icon(Icons.person_rounded, size: 36, color: _heroBottom)
              : Text(initials, style: AppTextStyles.headingLg.copyWith(color: _heroBottom, fontSize: 28)),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(1.5);
    canvas.drawArc(
      rect,
      0,
      2 * math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = Colors.white.withValues(alpha: 0.25),
    );
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.progress != progress;
}

/// Vehicles and conversations counts, read from the Home and Inbox tabs'
/// existing listeners — shown only when those are loaded (the profile is
/// also rendered standalone).
class _HeroStats extends StatelessWidget {
  const _HeroStats();

  @override
  Widget build(BuildContext context) {
    final home = Get.isRegistered<HomeTabController>() ? Get.find<HomeTabController>() : null;
    final inbox = Get.isRegistered<InboxController>() ? Get.find<InboxController>() : null;
    if (home == null && inbox == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Obx(
        () => Row(
          children: [
            if (home != null)
              Expanded(
                child: _StatPill(
                  icon: Icons.directions_car_filled_rounded,
                  value: home.vehicles.length,
                  label: home.vehicles.length == 1 ? 'Vehicle' : 'Vehicles',
                ),
              ),
            if (home != null && inbox != null) const SizedBox(width: 10),
            if (inbox != null)
              Expanded(
                child: _StatPill(
                  icon: Icons.forum_rounded,
                  value: inbox.threads.length + inbox.sentThreads.length,
                  label: inbox.threads.length + inbox.sentThreads.length == 1 ? 'Conversation' : 'Conversations',
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.icon, required this.value, required this.label});

  final IconData icon;
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 17, color: _heroBottom),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: value.toDouble()),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutCubic,
                  builder: (context, v, _) => Text(
                    '${v.round()}',
                    style: AppTextStyles.headingSm.copyWith(color: Colors.white, fontSize: 18, height: 1.1),
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(color: Colors.white.withValues(alpha: 0.85), fontSize: 11.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Settings groups
// ---------------------------------------------------------------------------

/// A titled, rounded group of rows separated by hairlines — the building
/// block for every section below the hero.
class _Group extends StatelessWidget {
  const _Group({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 6, bottom: 8),
            child: Text(
              title.toUpperCase(),
              style: AppTextStyles.overline.copyWith(color: AppColors.muted, letterSpacing: 1.2, fontSize: 11),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.border),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, 6))],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0) Divider(height: 1, thickness: 1, indent: 64, color: AppColors.border),
                  children[i],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.tint,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
    this.danger = false,
    this.busy = false,
  });

  final IconData icon;
  final Color tint;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool danger;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: const EdgeInsets.fromLTRB(14, 13, 12, 13),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: tint.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(12)),
            child: busy
                ? Padding(
                    padding: const EdgeInsets.all(11),
                    child: CircularProgressIndicator(strokeWidth: 2, color: tint),
                  )
                : Icon(icon, size: 19, color: tint),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.buttonLabel.copyWith(color: danger ? _danger : AppColors.ink, fontSize: 15),
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTextStyles.caption.copyWith(color: AppColors.muted, fontSize: 11.5, height: 1.3)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          trailing ?? (onTap == null ? const SizedBox.shrink() : Icon(Icons.chevron_right_rounded, color: danger ? _danger : AppColors.faint)),
        ],
      ),
    );

    if (onTap == null && !busy) return row;
    return Semantics(
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          splashColor: tint.withValues(alpha: 0.08),
          highlightColor: tint.withValues(alpha: 0.05),
          child: row,
        ),
      ),
    );
  }
}

class _VerifiedBadge extends StatelessWidget {
  const _VerifiedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.successSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.successBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_rounded, size: 12, color: AppColors.success),
          const SizedBox(width: 4),
          Text('Verified', style: AppTextStyles.overline.copyWith(color: AppColors.success, letterSpacing: 0.2, fontSize: 11)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// How should we reach you?
// ---------------------------------------------------------------------------

class _ReachPreferenceGroup extends StatelessWidget {
  const _ReachPreferenceGroup({required this.controller});

  final ProfileController controller;

  @override
  Widget build(BuildContext context) {
    return _Group(
      title: 'How should we reach you?',
      children: [
        Obx(() {
          final selected = controller.communicationPreference.value;
          return Column(
            children: [
              _ReachOption(
                icon: Icons.notifications_active_outlined,
                title: 'In this app',
                subtitle: 'Push notifications when someone messages you (recommended)',
                selected: selected == 'app',
                onTap: () => controller.setCommunicationPreference('app'),
              ),
              Divider(height: 1, thickness: 1, indent: 64, color: AppColors.border),
              _ReachOption(
                icon: Icons.link_rounded,
                title: 'On the web link',
                subtitle: "For when you'd rather not keep the app installed",
                selected: selected == 'web',
                onTap: () => controller.setCommunicationPreference('web'),
              ),
            ],
          );
        }),
      ],
    );
  }
}

class _ReachOption extends StatelessWidget {
  const _ReachOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.yellow;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            color: selected ? accent.withValues(alpha: 0.07) : Colors.transparent,
            padding: const EdgeInsets.fromLTRB(14, 13, 12, 13),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: (selected ? accent : _tintSlate).withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 19, color: selected ? accent : _tintSlate),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTextStyles.buttonLabel.copyWith(color: AppColors.ink, fontSize: 15)),
                      const SizedBox(height: 2),
                      Text(subtitle, style: AppTextStyles.caption.copyWith(color: AppColors.muted, fontSize: 11.5, height: 1.3)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? accent : Colors.transparent,
                    border: Border.all(color: selected ? accent : AppColors.faint, width: 2),
                  ),
                  child: selected ? Icon(Icons.check_rounded, size: 14, color: AppColors.background) : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Appearance
// ---------------------------------------------------------------------------

/// Lets the resident switch between the app's dark (default) and light
/// palettes — [ThemeController] persists the choice and repaints every
/// screen via [Get.forceAppUpdate]. A sliding highlight marks the choice.
class _AppearanceGroup extends StatelessWidget {
  const _AppearanceGroup();

  static const _modes = [
    (mode: AppThemeMode.light, icon: Icons.light_mode_rounded, label: 'Light'),
    (mode: AppThemeMode.dark, icon: Icons.dark_mode_rounded, label: 'Dark'),
    (mode: AppThemeMode.system, icon: Icons.brightness_auto_rounded, label: 'Auto'),
  ];

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.yellow;

    return _Group(
      title: 'Appearance',
      children: [
        Padding(
          padding: const EdgeInsets.all(10),
          child: Obx(() {
            final mode = ThemeController.to.mode.value;
            final index = _modes.indexWhere((m) => m.mode == mode);

            return Container(
              height: 52,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(16)),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final segment = constraints.maxWidth / _modes.length;
                  return Stack(
                    children: [
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 380),
                        curve: Curves.easeOutBack,
                        left: index * segment,
                        width: segment,
                        top: 0,
                        bottom: 0,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: LinearGradient(colors: [accent, AppColors.accentDeep]),
                            boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          for (final m in _modes)
                            Expanded(
                              child: _ThemeOption(
                                icon: m.icon,
                                label: m.label,
                                selected: m.mode == mode,
                                onTap: () => ThemeController.to.setMode(m.mode),
                              ),
                            ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({required this.icon, required this.label, required this.selected, required this.onTap});

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Text on the accent highlight uses the background color, like every
    // other accent button, so it stays readable in both themes.
    final fg = selected ? AppColors.background : AppColors.muted;

    return Semantics(
      button: true,
      selected: selected,
      label: '$label theme',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: ExcludeSemantics(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Spins in when picked.
              TweenAnimationBuilder<double>(
                key: ValueKey(selected),
                tween: Tween(begin: selected ? -0.5 : 0, end: 0),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutBack,
                builder: (context, turns, child) => Transform.rotate(angle: turns * 2 * math.pi, child: child),
                child: Icon(icon, size: 18, color: fg),
              ),
              const SizedBox(width: 6),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 220),
                style: AppTextStyles.label.copyWith(
                  color: fg,
                  letterSpacing: 0,
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Footer & loading
// ---------------------------------------------------------------------------

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.asset('assets/Applogo.png', width: 36, height: 36),
        ),
        const SizedBox(height: 8),
        Text.rich(
          TextSpan(
            style: AppTextStyles.headingSm.copyWith(color: AppColors.muted, fontSize: 14),
            children: [
              const TextSpan(text: 'Park '),
              TextSpan(text: 'Vehicle', style: TextStyle(color: AppColors.yellow)),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Text('Scan. Message. Move on.', style: AppTextStyles.caption.copyWith(color: AppColors.faint)),
      ],
    );
  }
}

/// Skeleton in the page's own shape, instead of a bare spinner.
class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    Widget card(double height) => Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
    );

    return Shimmer(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(18, 24, 18, 18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: AppColors.border),
            ),
            child: const Column(
              children: [
                ShimmerBox(width: 92, height: 92, radius: 46),
                SizedBox(height: 14),
                ShimmerBox(width: 160, height: 22),
                SizedBox(height: 10),
                ShimmerBox(width: 200, height: 24, radius: 12),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Align(alignment: Alignment.centerLeft, child: ShimmerBox(width: 90, height: 11)),
          const SizedBox(height: 8),
          card(150),
          const SizedBox(height: 22),
          const Align(alignment: Alignment.centerLeft, child: ShimmerBox(width: 110, height: 11)),
          const SizedBox(height: 8),
          card(130),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Notifications banner
// ---------------------------------------------------------------------------

/// Only shown while [ProfileController.notificationsPermitted] is false.
///
/// Why this exists: FCM reports a push as "successfully delivered" the
/// moment it reaches the device, regardless of whether the OS is actually
/// allowed to show it. With notifications denied, that push is silently
/// discarded — from the backend's side (and from a resident just staring
/// at the app) it looks identical to a broken token, when the real cause
/// is a permission this app can only ask for once.
class _NotificationsOffBanner extends StatelessWidget {
  const _NotificationsOffBanner({required this.onTapRecheck});

  final VoidCallback onTapRecheck;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.yellow;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Color.alphaBlend(accent.withValues(alpha: 0.1), AppColors.surface),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: 0.15),
            ),
            child: Icon(Icons.notifications_off_outlined, color: accent, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notifications are turned off',
                  style: AppTextStyles.fieldValue.copyWith(color: AppColors.ink, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  "You won't be alerted when someone messages you. Enable "
                  'notifications for Park Vehicle in your phone\'s Settings app, '
                  'then come back here.',
                  style: AppTextStyles.subtitle.copyWith(color: AppColors.muted, fontSize: 12.5, height: 1.4),
                ),
                const SizedBox(height: 10),
                Pressable(
                  onTap: onTapRecheck,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.refresh_rounded, size: 15, color: AppColors.background),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            "I've enabled it — check again",
                            style: AppTextStyles.linkTextEmphasis.copyWith(color: AppColors.background, fontSize: 12.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
