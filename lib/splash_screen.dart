import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'app_style.dart';
import 'student_list_page.dart';

/// Shows the branded loading video once, then reveals the class dashboard.
class SplashGate extends StatefulWidget {
  const SplashGate({super.key});

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  bool _ready = false;

  void _finishSplash() {
    if (_ready || !mounted) return;
    setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 450),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: _ready
          ? const StudentListPage(key: ValueKey('student-list'))
          : SplashScreen(
              key: const ValueKey('splash-screen'),
              onFinished: _finishSplash,
            ),
    );
  }
}

/// Full-screen splash that plays `assets/images/videos/loading.mp4`.
///
/// The app always moves on, even when the video cannot be prepared (for
/// example on a platform without video support or when the asset is missing).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const _videoAsset = 'assets/images/videos/loading.mp4';
  static const _maximumSplashDuration = Duration(seconds: 12);
  static const _splashBackground = Color(0xFFF2F6FC);

  VideoPlayerController? _controller;
  Timer? _safetyTimer;
  bool _finishing = false;

  @override
  void initState() {
    super.initState();
    _safetyTimer = Timer(_maximumSplashDuration, _finish);
    _prepareVideo();
  }

  Future<void> _prepareVideo() async {
    final controller = VideoPlayerController.asset(_videoAsset);
    _controller = controller;

    try {
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }

      controller.addListener(_handleVideoProgress);
      await controller.setLooping(false);
      await controller.setVolume(0);
      await controller.play();
      if (mounted) {
        setState(() {});
      }
    } catch (_) {
      // Leave the splash gracefully when playback is unavailable.
      _finish();
    }
  }

  void _handleVideoProgress() {
    final controller = _controller;
    if (controller == null || _finishing) {
      return;
    }

    final value = controller.value;
    final hasEnded =
        value.isInitialized &&
        value.duration > Duration.zero &&
        !value.isPlaying &&
        value.position >= value.duration;
    if (hasEnded) {
      _finish();
    }
  }

  void _finish() {
    if (_finishing) {
      return;
    }
    _finishing = true;
    _safetyTimer?.cancel();
    widget.onFinished();
  }

  @override
  void dispose() {
    _safetyTimer?.cancel();
    final controller = _controller;
    if (controller != null) {
      controller.removeListener(_handleVideoProgress);
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final isReady = controller?.value.isInitialized ?? false;

    return Scaffold(
      backgroundColor: _splashBackground,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (isReady)
            _SplashVideo(controller: controller!)
          else
            const _SplashPlaceholder(),
          const Positioned(
            left: 0,
            right: 0,
            bottom: 28,
            child: _SplashCaption(),
          ),
        ],
      ),
    );
  }
}

class _SplashVideo extends StatelessWidget {
  const _SplashVideo({required this.controller});

  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    final videoSize = controller.value.size;
    final screenSize = MediaQuery.sizeOf(context);
    final videoAspect = videoSize.width / videoSize.height;
    final screenAspect = screenSize.width / screenSize.height;

    // Fill phone screens, but keep the whole frame on wide displays so the
    // animation is never cropped beyond recognition.
    final fit = screenAspect > videoAspect ? BoxFit.contain : BoxFit.cover;

    return FittedBox(
      fit: fit,
      clipBehavior: Clip.hardEdge,
      child: SizedBox(
        width: videoSize.width,
        height: videoSize.height,
        child: VideoPlayer(controller),
      ),
    );
  }
}

class _SplashPlaceholder extends StatelessWidget {
  const _SplashPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 42,
        height: 42,
        child: CircularProgressIndicator(
          strokeWidth: 2.4,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.terracotta),
        ),
      ),
    );
  }
}

class _SplashCaption extends StatelessWidget {
  const _SplashCaption();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xD9FFFCF6),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0x33DED3C2)),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'DATA SISWA XII RPL',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 3.2,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'Menyiapkan buku kelas…',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.inkSoft,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
