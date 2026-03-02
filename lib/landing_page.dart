// lib/landing_page.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bgController;
  late final Animation<double> _bgAnim;

  int _fabCount = 0;
  int _activeStep = 0;
  int? _hoverIndex;

  final List<Map<String, String>> _timeline = const [
    {"title": "Foundation", "desc": "Firebase setup, auth, secure architecture."},
    {"title": "Discovery", "desc": "Trainer profiles, filtering, availability."},
    {"title": "Booking", "desc": "Atomic booking & race-free flow."},
    {"title": "Wellness", "desc": "Simple logging, weekly summary."},
    {"title": "Launch", "desc": "Pilot users and validation metrics."},
  ];

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);

    _bgAnim = CurvedAnimation(parent: _bgController, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _bgController.dispose();
    super.dispose();
  }

  void _incrementFab() {
    setState(() => _fabCount++);

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text('FAB clicked $_fabCount ${_fabCount == 1 ? 'time' : 'times'}'),
        ),
      );
  }

  void _onBeginValidation() {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        const SnackBar(content: Text('Begin Validation — placeholder action')),
      );
  }

  @override
  Widget build(BuildContext context) {
    const Color a = Color(0xFF0F1724);
    const Color b = Color(0xFF102A43);
    const Color c = Color(0xFF164E63);

    return Scaffold(
      body: AnimatedBuilder(
        animation: _bgAnim,
        builder: (context, _) {
          final t = _bgAnim.value;
          final color1 = Color.lerp(a, b, (math.sin(t * math.pi) + 1) / 2)!;
          final color2 = Color.lerp(b, c, (math.cos(t * math.pi) + 1) / 2)!;

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: const Alignment(-0.9, -0.6),
                end: const Alignment(0.7, 0.9),
                colors: [color1, color2],
              ),
            ),
            child: SafeArea(child: _pageContent(context)),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementFab,
        tooltip: 'Increment counter',
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(Icons.add),
            if (_fabCount > 0)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 255, 69, 58),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$_fabCount',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _pageContent(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 760;

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _headerRow(),
                  const SizedBox(height: 32),
                  Expanded(
                    child: isWide ? _horizontalLayout() : _verticalLayout(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _headerRow() {
    return Row(
      children: [
        // constrained logo placeholder with explicit size (avoids AspectRatio issues)
        SizedBox(
          height: 60,
          width: 180,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white24),
              color: const Color.fromARGB(8, 255, 255, 255),
            ),
            child: Row(
              children: const [
                Icon(Icons.sports_gymnastics, size: 28, color: Colors.white70),
                SizedBox(width: 12),
                Text(
                  'WellPath',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 20),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'A web-first fitness marketplace',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Discover trainers, book safely, and track wellness — no app install required.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        ElevatedButton(
          onPressed: _onBeginValidation,
          style: ElevatedButton.styleFrom(
            elevation: 6,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          ),
          child: const Text('Begin Validation'),
        ),
      ],
    );
  }

  Widget _horizontalLayout() {
    return Row(
      children: [
        SizedBox(
          width: 520,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Roadmap',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 220,
                child: _buildTimeline(scrollDirection: Axis.horizontal),
              ),
            ],
          ),
        ),
        const SizedBox(width: 28),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: _detailCard(_activeStep),
          ),
        ),
      ],
    );
  }

  Widget _verticalLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Roadmap',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Expanded(child: _buildTimeline()),
      ],
    );
  }

  Widget _buildTimeline({Axis scrollDirection = Axis.vertical}) {
    if (scrollDirection == Axis.horizontal) {
      return ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
        itemBuilder: (context, index) {
          final item = _timeline[index];
          return _timelineCard(index, item['title']!, item['desc']!, compact: true);
        },
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemCount: _timeline.length,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 6),
      itemBuilder: (context, index) {
        final item = _timeline[index];
        return _timelineCard(index, item['title']!, item['desc']!, compact: false);
      },
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemCount: _timeline.length,
    );
  }

  Widget _timelineCard(int index, String title, String desc, {required bool compact}) {
    final isActive = index == _activeStep;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoverIndex = index),
      onExit: (_) => setState(() => _hoverIndex = null),
      child: GestureDetector(
        onTap: () => setState(() => _activeStep = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          width: compact ? 240 : null,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isActive
                ? const Color.fromARGB(15, 255, 255, 255)
                : const Color.fromARGB(5, 255, 255, 255),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? Colors.white24 : Colors.white10,
            ),
            boxShadow: _hoverIndex == index
                ? [
                    BoxShadow(
                      color: const Color.fromARGB(64, 0, 0, 0),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    )
                  ]
                : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(top: 4, right: 12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive ? Colors.tealAccent : Colors.white24,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: isActive ? Colors.white : Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      desc,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailCard(int i) {
    final item = _timeline[i];

    return Container(
      key: ValueKey('detail-$i'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color.fromARGB(8, 255, 255, 255),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item['title']!,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            item['desc']!,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: _onBeginValidation,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start this step'),
          ),
        ],
      ),
    );
  }
}
