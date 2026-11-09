import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/services/auth_service.dart';
import '../../../app/services/deep_link_service.dart';
import '../../../app/services/push_notification_service.dart';
import '../../../app/widgets/app_snackbar.dart';
import '../../../app/utils/app_logger.dart';

class OtpController extends GetxController {
  static const codeLength = 6;
  static const _resendCooldown = 60;

  OtpController({
    required this.phone,
    required this.verificationId,
    required this.mode,
    this.name,
    this.cnic,
  });

  final String phone;
  final String mode; // 'signUp', 'login' or 'admin'
  final String? name;
  final String? cnic;

  /// Reassigned on resend, since Firebase issues a new verification id per
  /// SMS attempt.
  String verificationId;

  final _authService = Get.find<AuthService>();
  final _pushService = Get.find<PushNotificationService>();
  final _deepLinkService = Get.find<DeepLinkService>();

  final digitControllers = List.generate(codeLength, (_) => TextEditingController());
  final focusNodes = List.generate(codeLength, (_) => FocusNode());

  final isVerifying = false.obs;
  final secondsRemaining = _resendCooldown.obs;

  Timer? _timer;
  StreamSubscription<String>? _autoVerifiedSub;

  /// Set once sign-in has gone through, so Android's automatic sign-in and
  /// a tap on Verify can't both run the steps after it.
  bool _finishing = false;

  @override
  void onInit() {
    super.onInit();
    _startCountdown();
    // Android can verify the number by itself and sign the resident in;
    // carry on from there instead of making them type an already-used code.
    _autoVerifiedSub = _authService.autoVerifiedSignIns.listen(_onAutoVerified);
  }

  @override
  void onReady() {
    super.onReady();
    // It may have happened before this screen opened.
    if (_authService.autoVerifiedUid case final uid?) _onAutoVerified(uid);
  }

  Future<void> _onAutoVerified(String uid) async {
    if (_finishing || isClosed) return;
    AppLogger.debug('PhoneAuth', 'OTP screen: signed in by auto-verification');
    isVerifying.value = true;
    try {
      await _finishSignIn(uid);
    } catch (e, stack) {
      AppLogger.debug('PhoneAuth', 'finishing auto sign-in failed: $e\n$stack');
      _finishing = false;
      isVerifying.value = false;
      AppSnackbar.show('Something went wrong', 'Please try again.');
    }
  }

  bool get canResend => secondsRemaining.value == 0;

  String get _enteredCode => digitControllers.map((c) => c.text).join();

  void _startCountdown() {
    secondsRemaining.value = _resendCooldown;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (secondsRemaining.value == 0) {
        timer.cancel();
        return;
      }
      secondsRemaining.value--;
    });
  }

  void onDigitChanged(int index, String value) {
    if (value.isNotEmpty && index < codeLength - 1) {
      focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      focusNodes[index - 1].requestFocus();
    }
  }

  Future<void> resend() async {
    if (!canResend) return;
    for (final c in digitControllers) {
      c.clear();
    }
    focusNodes.first.requestFocus();

    await _authService.sendOtp(
      e164Phone: '+92$phone',
      onCodeSent: (id) {
        verificationId = id;
        _startCountdown();
        AppSnackbar.show('Code resent', 'A new code was sent to +92 $phone.');
      },
      onError: (message) => AppSnackbar.show('Could not resend', message),
    );
  }

  Future<void> verify() async {
    if (_enteredCode.length != codeLength) {
      AppSnackbar.show('Enter the full code', 'The verification code is $codeLength digits.');
      return;
    }
    if (_finishing || isVerifying.value) return;
    isVerifying.value = true;
    try {
      final uid = await _authService.confirmOtp(verificationId: verificationId, smsCode: _enteredCode);
      // Auto-verification may have finished sign-in while this was in flight.
      if (_finishing) return;
      await _finishSignIn(uid);
    } on FirebaseAuthException catch (e, stack) {
      AppLogger.debug(
        'PhoneAuth',
        'verify failed\n'
            '  code: ${e.code}\n'
            '  message: ${e.message}\n$stack',
      );
      _finishing = false;
      isVerifying.value = false;
      final wrongCode =
          e.code == 'invalid-verification-code' || e.code == 'session-expired';
      AppSnackbar.show(
        'Verification failed',
        wrongCode
            ? 'The code was incorrect or expired. Please try again.'
            : describeAuthFailure(e),
      );
    } catch (e, stack) {
      // Not an OTP problem — e.g. saving the profile or push token failed
      // after sign-in succeeded — so don't blame the code.
      AppLogger.debug('PhoneAuth', 'verify failed (after sign-in): $e\n$stack');
      _finishing = false;
      isVerifying.value = false;
      AppSnackbar.show('Something went wrong', 'Please try again.');
    }
  }

  /// Everything after a successful sign-in: the admin role, the new
  /// profile, the push token, and where to go next.
  Future<void> _finishSignIn(String uid) async {
    _finishing = true;
    if (mode == 'admin') {
      await _authService.claimAdminRole();
      await _pushService.syncToken();
      isVerifying.value = false;
      Get.offAllNamed(AppRoutes.admin);
      return;
    }
    if (mode == 'signUp') {
      await _authService.createResidentProfile(uid: uid, name: name ?? '', phone: '+92$phone', cnic: cnic);
    }

    // A QR/deep-link scan that brought this resident here to
    // register/log in must not just dump them on the home screen — it
    // takes priority over the usual post-auth routing (commPreference
    // for a fresh sign-up, dashboard for a login) and resumes straight
    // into the chat that link pointed at.
    final pendingScan = _deepLinkService.consumePendingVehicleScan();
    if (pendingScan != null) {
      await _pushService.syncToken();
      isVerifying.value = false;
      Get.offAllNamed(AppRoutes.dashboard);
      await _deepLinkService.resolveAndOpenChat(pendingScan);
      return;
    }

    isVerifying.value = false;
    if (mode == 'signUp') {
      Get.offAllNamed(AppRoutes.commPreference);
    } else {
      await _pushService.syncToken();
      Get.offAllNamed(AppRoutes.dashboard);
    }
  }

  @override
  void onClose() {
    _timer?.cancel();
    _autoVerifiedSub?.cancel();
    for (final c in digitControllers) {
      c.dispose();
    }
    for (final f in focusNodes) {
      f.dispose();
    }
    super.onClose();
  }
}
