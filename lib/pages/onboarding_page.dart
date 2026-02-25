import 'package:flutter/material.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF1580C1);
    const primaryLight = Color(0xFFE3F2FD);
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top illustration area
            SizedBox(
              height: screenHeight * 0.50,
              width: double.infinity,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Background decorative dots top-left
                  Positioned(
                    top: 20,
                    left: 20,
                    child: _decorativeDot(8, primary.withOpacity(0.3)),
                  ),
                  Positioned(
                    top: 40,
                    left: 50,
                    child: _decorativeDot(5, primary.withOpacity(0.2)),
                  ),
                  // Background decorative dots top-right
                  Positioned(
                    top: 30,
                    right: 30,
                    child: _decorativeStar(primary.withOpacity(0.15)),
                  ),
                  Positioned(
                    top: 60,
                    right: 60,
                    child: _decorativeDot(6, primary.withOpacity(0.25)),
                  ),
                  // Large pink circle background
                  Positioned(
                    top: screenHeight * 0.04,
                    child: Container(
                      width: 260,
                      height: 260,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: primary.withOpacity(0.12),
                      ),
                    ),
                  ),
                  // Inner darker pink circle
                  Positioned(
                    top: screenHeight * 0.06,
                    child: Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: primary.withOpacity(0.2),
                      ),
                    ),
                  ),
                  // Center logo
                  Positioned(
                    top: screenHeight * 0.10,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x20000000),
                            blurRadius: 16,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Image.asset(
                        'assets/famzlog.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  // Delivery icon - left
                  Positioned(
                    top: screenHeight * 0.08,
                    left: 30,
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.local_shipping_outlined,
                        color: primary,
                        size: 28,
                      ),
                    ),
                  ),
                  // Location icon - right
                  Positioned(
                    top: screenHeight * 0.12,
                    right: 30,
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.location_on_outlined,
                        color: primary,
                        size: 28,
                      ),
                    ),
                  ),
                  // Tracking icon - bottom left
                  Positioned(
                    bottom: screenHeight * 0.08,
                    left: 50,
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: primaryLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.route_outlined,
                        color: primary,
                        size: 24,
                      ),
                    ),
                  ),
                  // Speed icon - bottom right
                  Positioned(
                    bottom: screenHeight * 0.06,
                    right: 50,
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: primaryLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.speed_outlined,
                        color: primary,
                        size: 24,
                      ),
                    ),
                  ),
                  // Small decorative dots scattered
                  Positioned(
                    bottom: 40,
                    left: 30,
                    child: _decorativeDot(5, primary.withOpacity(0.4)),
                  ),
                  Positioned(
                    bottom: 60,
                    right: 25,
                    child: _decorativeDot(7, primary.withOpacity(0.2)),
                  ),
                  Positioned(
                    top: 80,
                    left: 100,
                    child: _decorativeDot(4, primary.withOpacity(0.35)),
                  ),
                ],
              ),
            ),
            // Title
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Pickup Delivery\nat Your Door',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A2E),
                  height: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 14),
            // Subtitle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Our app can send you everywhere,\neven space. For only \$2.99 per month',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
            ),
            const Spacer(),
            // Get Started button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: primary, width: 2),
                    shape: const StadiumBorder(),
                    foregroundColor: primary,
                  ),
                  onPressed: () {
                    Navigator.of(context).pushNamed('/login');
                  },
                  child: const Text(
                    'Get Started',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

Widget _decorativeDot(double size, Color color) {
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: color,
    ),
  );
}

Widget _decorativeStar(Color color) {
  return Icon(
    Icons.star,
    size: 16,
    color: color,
  );
}
