import 'package:flutter/material.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  static const _primary = Color(0xFF1580C1);
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _pages = [
    {
      'title': 'Sistem Manajemen Distribusi',
      'subtitle':
          'Solusi lengkap untuk monitoring delivery dan manajemen distribusi yang terintegrasi.',
      'icon': Icons.hub_outlined,
      'illustration': _DistributionIllustration(),
    },
    {
      'title': 'Fleet Management',
      'subtitle':
          'Pantau lokasi armada secara real-time dan kelola status kendaraan dengan efisien.',
      'icon': Icons.local_shipping_outlined,
      'illustration': _FleetIllustration(),
    },
    {
      'title': 'Proof of Delivery',
      'subtitle':
          'Validasi pengiriman digital dengan bukti foto dan tanda tangan penerima yang akurat.',
      'icon': Icons.assignment_turned_in_outlined,
      'illustration': _PodIllustration(),
    },
  ];

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed('/login');
                  },
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),

            // PageView
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Column(
                    children: [
                      SizedBox(height: screenHeight * 0.02),
                      // Illustration Area
                      SizedBox(
                        height: screenHeight * 0.45,
                        width: double.infinity,
                        child: page['illustration'] as Widget,
                      ),
                      const SizedBox(height: 32),
                      // Text Area
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _primary.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                page['icon'] as IconData,
                                color: _primary,
                                size: 32,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              page['title'] as String,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1A1A2E),
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              page['subtitle'] as String,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // Indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? _primary
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                  ),
                  onPressed: () {
                    if (_currentPage < _pages.length - 1) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      Navigator.of(context).pushNamed('/login');
                    }
                  },
                  child: Text(
                    _currentPage == _pages.length - 1 ? 'Get Started' : 'Next',
                    style: const TextStyle(
                      fontSize: 16,
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

// ─────────────────────────────────────────────────────────────────────────────
// CUSTOM ILLUSTRATIONS
// ─────────────────────────────────────────────────────────────────────────────

class _DistributionIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF1580C1);
    return Stack(
      alignment: Alignment.center,
      children: [
        _CircleBg(size: 280, opacity: 0.05),
        _CircleBg(size: 220, opacity: 0.1),
        // Central Logo
        Container(
          width: 100,
          height: 100,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Image.asset('assets/famzlog.png', fit: BoxFit.contain),
        ),
        // Orbiting items
        Positioned(
          top: 40,
          right: 60,
          child: _IconCard(Icons.inventory_2_outlined, Colors.orange),
        ),
        Positioned(
          bottom: 60,
          left: 50,
          child: _IconCard(Icons.storefront_outlined, Colors.green),
        ),
        Positioned(
          top: 80,
          left: 40,
          child: _IconCard(Icons.fork_right_rounded, Colors.purple),
        ),
        // Decorative dots
        Positioned(
          top: 30,
          left: 30,
          child: _Dot(6, primary.withOpacity(0.3)),
        ),
        Positioned(
          bottom: 40,
          right: 40,
          child: _Dot(8, primary.withOpacity(0.2)),
        ),
      ],
    );
  }
}

class _FleetIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF1580C1);
    return Stack(
      alignment: Alignment.center,
      children: [
        _CircleBg(size: 260, opacity: 0.05),
        // Map-like background lines
        SizedBox(
          width: 260,
          height: 260,
          child: CustomPaint(painter: _MapGridPainter()),
        ),
        // Central Truck
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: primary.withOpacity(0.1), width: 1),
            boxShadow: [
              BoxShadow(
                color: primary.withOpacity(0.15),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.local_shipping_rounded,
              size: 56, color: primary),
        ),
        // Location markers
        Positioned(
          top: 60,
          right: 50,
          child: _IconCard(Icons.location_on, Colors.red, size: 36, iconSize: 20),
        ),
        Positioned(
          bottom: 70,
          left: 40,
          child:
              _IconCard(Icons.location_on, Colors.blue, size: 36, iconSize: 20),
        ),
        // Speed
        Positioned(
          bottom: 40,
          right: 80,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.speed, size: 14, color: Colors.orange),
                SizedBox(width: 4),
                Text('60 km/h', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PodIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF1580C1);
    return Stack(
      alignment: Alignment.center,
      children: [
        _CircleBg(size: 280, opacity: 0.05),
        // Document Card
        Container(
          width: 180,
          height: 220,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Center(
                  child: Icon(Icons.image_outlined,
                      size: 48, color: Colors.grey.shade400),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 8,
                      width: 80,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 8,
                      width: 120,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Icon(Icons.check_circle, size: 20, color: Colors.green),
                        const SizedBox(width: 8),
                        const Text('Delivered',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Check badge
        Positioned(
          bottom: 40,
          right: 60,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
              ],
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 24),
          ),
        ),
        // Signature Pen
        Positioned(
          bottom: 80,
          left: 60,
          child: _IconCard(Icons.draw_outlined, primary),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────────────────────────────────────

class _CircleBg extends StatelessWidget {
  final double size;
  final double opacity;
  const _CircleBg({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF1580C1).withOpacity(opacity),
      ),
    );
  }
}

class _IconCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final double iconSize;

  const _IconCard(this.icon, this.color, {this.size = 48, this.iconSize = 24});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, color: color, size: iconSize),
    );
  }
}

class _Dot extends StatelessWidget {
  final double size;
  final Color color;
  const _Dot(this.size, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.15)
      ..strokeWidth = 1.0;

    const spacing = 30.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
