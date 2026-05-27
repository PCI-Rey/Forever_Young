import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_text.dart';
import '../models/onboarding_model.dart';
import '../providers/settings_provider.dart';
import '../routes/app_routes.dart';
import '../utils/responsive_helper.dart';
import '../widgets/custom_button.dart';
import '../widgets/onboarding_card.dart';

/// Onboarding Carousel Screen — 3 slides introducing the app.
/// Uses PageView with dot indicators and Next/Get Started buttons.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNextPressed() {
    if (_currentPage < OnboardingModel.slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _completeOnboarding() async {
    // Mark setup as done so this flow never appears again
    final settings = context.read<SettingsProvider>();
    final navigator = Navigator.of(context);
    await settings.markSetupComplete();
    if (mounted) {
      navigator.pushNamedAndRemoveUntil(AppRoutes.scan, (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final lang = settings.languageCode;
    final isLastPage = _currentPage == OnboardingModel.slides.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              children: [
                // ─── Skip Button ───
                if (!isLastPage)
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: EdgeInsets.only(top: 16.rh, right: 20.rw),
                      child: TextButton(
                        onPressed: () async {
                          // Skip directly to Scan Product & mark setup complete
                          final settings = context.read<SettingsProvider>();
                          final navigator = Navigator.of(context);
                          await settings.markSetupComplete();
                          if (mounted) {
                            navigator.pushNamedAndRemoveUntil(
                              AppRoutes.scan,
                              (route) => false,
                            );
                          }
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: 20.rw,
                            vertical: 12.rh,
                          ),
                        ),
                        child: Text(
                          settings.tr(AppText.skipEn, AppText.skipId),
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  SizedBox(height: 64.rh), // Maintain layout height when skipped button is hidden

                // ─── Page Content ───
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: OnboardingModel.slides.length,
                    onPageChanged: (index) {
                      setState(() => _currentPage = index);
                    },
                    itemBuilder: (context, index) {
                      return OnboardingCard(
                        data: OnboardingModel.slides[index],
                        languageCode: lang,
                      );
                    },
                  ),
                ),

                // ─── Dot Indicators ───
                Padding(
                  padding: EdgeInsets.only(bottom: 24.rh),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      OnboardingModel.slides.length,
                      (index) => _buildDot(context, index),
                    ),
                  ),
                ),

                // ─── Navigation Button ───
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 28.rw),
                  child: CustomButton(
                    text: isLastPage
                        ? settings.tr(AppText.getStartedEn, AppText.getStartedId)
                        : settings.tr(AppText.nextButtonEn, AppText.nextButtonId),
                    icon: isLastPage
                        ? Icons.check_circle_rounded
                        : Icons.arrow_forward_rounded,
                    onPressed: _onNextPressed,
                  ),
                ),

                SizedBox(height: 32.rh),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDot(BuildContext context, int index) {
    final isActive = index == _currentPage;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: EdgeInsets.symmetric(horizontal: 6.rw),
      width: isActive ? 28.rw : 10.rw,
      height: 10.rw,
      decoration: BoxDecoration(
        color: isActive
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.primary.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(5.r),
      ),
    );
  }
}
