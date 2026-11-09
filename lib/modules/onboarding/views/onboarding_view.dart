import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../app/widgets/motion.dart';
import '../../auth/widgets/auth_brand_mark.dart';
import '../controllers/onboarding_controller.dart';
import '../models/onboarding_page_data.dart';
import '../widgets/onboarding_dots.dart';
import '../widgets/onboarding_illustrations.dart';

class OnboardingView extends GetView<OnboardingController> {
  const OnboardingView({super.key});

  static final _pages = [
    OnboardingPageData(
      headline: 'Put a tag on\nyour car',
      body: "Register your vehicle and order your Park Vehicle QR sticker. Stick it on your windshield — it's all anyone needs to reach you.",
      illustrationBuilder: (_) => const TagCarIllustration(),
    ),
    OnboardingPageData(
      headline: 'Get notified,\nnever exposed',
      body: 'Anyone blocked in can scan your sticker and send you a message instantly. Your phone number is never shown to anyone.',
      illustrationBuilder: (_) => const NotifiedIllustration(),
    ),
    OnboardingPageData(
      headline: 'Chat, resolve,\nmove on',
      body: "Reply right from the app, mark the issue resolved when you're done, and get back to your day — no notes on windshields.",
      illustrationBuilder: (_) => const ResolveIllustration(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Soft accent glow behind the illustration area.
          Positioned(
            top: -160,
            left: -80,
            right: -80,
            height: 520,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [AppColors.yellow.withValues(alpha: 0.18), AppColors.yellow.withValues(alpha: 0)],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 20, 0),
                  child: Row(
                    children: [
                      const AuthBrandMark(),
                      const Spacer(),
                      Obx(() => _SkipButton(hidden: controller.isLastPage, onTap: controller.skip)),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: controller.pageController,
                    onPageChanged: controller.onPageChanged,
                    itemCount: _pages.length,
                    itemBuilder: (context, index) => _OnboardingPage(data: _pages[index], step: index + 1, total: _pages.length),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 8, 24, 28),
                  child: Obx(
                    () => Row(
                      children: [
                        OnboardingDots(count: OnboardingController.pageCount, index: controller.currentPage.value),
                        const Spacer(),
                        _NextButton(isLast: controller.isLastPage, onTap: controller.next),
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

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.data, required this.step, required this.total});

  final OnboardingPageData data;
  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Center(
            child: FittedBox(fit: BoxFit.scaleDown, child: data.illustrationBuilder(context)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 0, 28, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RiseIn(
                order: 0,
                child: Text(
                  'STEP $step OF $total',
                  style: AppTextStyles.overline.copyWith(color: AppColors.yellow, letterSpacing: 1.6),
                ),
              ),
              const SizedBox(height: 10),
              RiseIn(
                order: 1,
                child: Text(
                  data.headline,
                  style: AppTextStyles.displayLg.copyWith(color: AppColors.ink, fontSize: 32, height: 1.1),
                ),
              ),
              const SizedBox(height: 14),
              RiseIn(
                order: 2,
                child: Text(
                  data.body,
                  style: AppTextStyles.subtitle.copyWith(color: AppColors.muted, fontSize: 15, height: 1.5),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SkipButton extends StatelessWidget {
  const _SkipButton({required this.hidden, required this.onTap});

  final bool hidden;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: hidden,
      child: AnimatedOpacity(
        opacity: hidden ? 0 : 1,
        duration: const Duration(milliseconds: 200),
        child: Pressable(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Text('Skip', style: AppTextStyles.label.copyWith(color: AppColors.muted)),
          ),
        ),
      ),
    );
  }
}

/// A round arrow button that widens into "Get started" on the last page.
class _NextButton extends StatelessWidget {
  const _NextButton({required this.isLast, required this.onTap});

  final bool isLast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: isLast ? 'Get started' : 'Next',
      child: Pressable(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          width: isLast ? 180 : 62,
          height: 62,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.yellow, AppColors.accentDeep],
            ),
            borderRadius: BorderRadius.circular(31),
            boxShadow: [
              BoxShadow(color: AppColors.yellow.withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 10)),
            ],
          ),
          child: ClipRect(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLast) ...[
                  Flexible(
                    child: Text(
                      'Get started',
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                      style: AppTextStyles.buttonLabel.copyWith(color: AppColors.background, fontSize: 15.5),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Icon(Icons.arrow_forward_rounded, size: 22, color: AppColors.background),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
