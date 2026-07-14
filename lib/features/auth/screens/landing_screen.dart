import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/pricing_model.dart';
import '../../../core/services/pricing_service.dart';

/// Public marketing homepage served at '/'. Full bilingual (AR/EN) PowerFit
/// site — hero, features, how-it-works, screenshots, testimonials, pricing,
/// FAQ, and a role gateway. Matches the PowerFit Landing design. Staff and
/// Admin share the same login form (backend resolves the role), so both route
/// to '/login'; members go to the client app.
class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

// Palette (mirrors the design canvas / AppTheme).
const _bg = Color(0xFF121212);
const _bg2 = Color(0xFF1A1A1A);
const _card = Color(0xFF2A2A2A);
const _red = Color(0xFFDC2626);
const _red2 = Color(0xFFEF4444);
const _red3 = Color(0xFFF87171);
const _crimson = Color(0xFFDC143C);
const _gold = Color(0xFFF59E0B);
const _emerald = Color(0xFF10B981);
const _muted = Color(0xFFB0B0B0);
const _subtle = Color(0xFF808080);

class _LandingScreenState extends State<LandingScreen> {
  final _scrollController = ScrollController();
  final _featuresKey = GlobalKey();
  final _howKey = GlobalKey();
  final _pricingKey = GlobalKey();
  final _faqKey = GlobalKey();
  final _gatewayKey = GlobalKey();

  // Persisted at the class level (not the widget instance) so the choice
  // survives navigating away from and back to the landing route — GoRouter
  // rebuilds a fresh LandingScreen/State each time this route is visited.
  static bool _lastSelectedAr = true;

  late bool _ar = _lastSelectedAr;
  int _faqOpen = -1;

  void _toggleLang() => setState(() {
    _ar = !_ar;
    _lastSelectedAr = _ar;
  });

  Map<String, String> get _t => _ar ? _arText : _enText;

  // ── Region-aware pricing (auto-detected only, no manual override) ───────
  final _pricingService = PricingService();
  PricingData? _pricing;
  bool _pricingLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPricing();
  }

  Future<void> _loadPricing() async {
    setState(() => _pricingLoading = true);
    final data = await _pricingService.fetchPricing();
    if (!mounted) return;
    setState(() {
      _pricing = data;
      _pricingLoading = false;
    });
  }

  void _scrollTo(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  bool _isWide(BuildContext c) => MediaQuery.of(c).size.width >= 900;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _ar ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: _bg,
        body: Column(
          children: [
            _Header(
              t: _t,
              langLabel: _ar ? 'EN' : 'ع',
              onToggleLang: _toggleLang,
              onNavFeatures: () => _scrollTo(_featuresKey),
              onNavHow: () => _scrollTo(_howKey),
              onNavPricing: () => _scrollTo(_pricingKey),
              onNavFaq: () => _scrollTo(_faqKey),
              onLogin: () => _scrollTo(_gatewayKey),
              wide: _isWide(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  children: [
                    _hero(context),
                    _trustBar(context),
                    _RevealOnScroll(child: _features(context)),
                    _RevealOnScroll(child: _how(context)),
                    _RevealOnScroll(child: _screenshots(context)),
                    _RevealOnScroll(child: _testimonials(context)),
                    _RevealOnScroll(child: _pricingSection(context)),
                    _RevealOnScroll(child: _faq(context)),
                    _gateway(context),
                    _footer(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Section shell ────────────────────────────────────────────────────────
  Widget _section({
    required Widget child,
    Color? color,
    Key? key,
    double vPad = 100,
  }) {
    return Container(
      key: key,
      width: double.infinity,
      color: color,
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: vPad),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: child,
        ),
      ),
    );
  }

  // ── Hero ─────────────────────────────────────────────────────────────────
  Widget _hero(BuildContext context) {
    final wide = _isWide(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: wide ? 100 : 64),
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -1.1),
          radius: 1.2,
          colors: [Color(0xFF1E1E1E), _bg],
          stops: [0.0, 0.7],
        ),
      ),
      child: _HeroFadeIn(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              children: [
                _pill(_t['heroBadge']!),
                const SizedBox(height: 24),
                Text(
                  _t['heroHead']!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: wide ? 58 : 38,
                    height: 1.15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  _t['heroSub']!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 18,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 36),
                Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  alignment: WrapAlignment.center,
                  children: [
                    _primaryCta(_t['cta1']!, () => _scrollTo(_gatewayKey)),
                    _outlineCta(_t['cta2']!, () => _scrollTo(_howKey)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _pill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: BoxDecoration(
        color: _red.withValues(alpha: 0.14),
        border: Border.all(color: _red.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: _red3,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _primaryCta(String label, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: _red,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 18),
        elevation: 8,
        shadowColor: _red.withValues(alpha: 0.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
      ),
      child: Text(label),
    );
  }

  Widget _outlineCta(String label, VoidCallback onTap) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: BorderSide(color: Colors.white.withValues(alpha: 0.24)),
        padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
      ),
      child: Text(label),
    );
  }

  // ── Trust bar ────────────────────────────────────────────────────────────
  static const _trustIcons = [
    Icons.fitness_center,
    Icons.sports_gymnastics,
    Icons.sports_martial_arts,
    Icons.pool,
    Icons.sports_score,
  ];

  Widget _trustBar(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF151515),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 34),
      child: Center(
        child: Wrap(
          spacing: 34,
          runSpacing: 16,
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              _t['trust']!,
              style: const TextStyle(
                color: _subtle,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            for (final icon in _trustIcons)
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: const Color(0xFF8A8A8A), size: 22),
              ),
          ],
        ),
      ),
    );
  }

  // ── Features ─────────────────────────────────────────────────────────────
  Widget _features(BuildContext context) {
    final features = [
      (Icons.qr_code_2, _t['f1t']!, _t['f1d']!),
      (Icons.card_membership, _t['f2t']!, _t['f2d']!),
      (Icons.store, _t['f3t']!, _t['f3d']!),
      (Icons.bar_chart, _t['f4t']!, _t['f4d']!),
      (Icons.notifications_active, _t['f5t']!, _t['f5d']!),
      (Icons.groups, _t['f6t']!, _t['f6d']!),
    ];
    return _section(
      key: _featuresKey,
      child: Column(
        children: [
          _sectionHead(_t['featHead']!, _t['featSub']),
          const SizedBox(height: 56),
          _responsiveGrid(context, [
            for (final f in features) _featureCard(f.$1, f.$2, f.$3),
          ]),
        ],
      ),
    );
  }

  Widget _featureCard(IconData icon, String title, String desc) {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: _card,
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 26,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _red.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: _red2, size: 26),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            desc,
            style: const TextStyle(color: _muted, fontSize: 15, height: 1.6),
          ),
        ],
      ),
    );
  }

  // ── How it works ─────────────────────────────────────────────────────────
  Widget _how(BuildContext context) {
    final steps = [
      ('1', _t['s1t']!, _t['s1d']!),
      ('2', _t['s2t']!, _t['s2d']!),
      ('3', _t['s3t']!, _t['s3d']!),
    ];
    return _section(
      key: _howKey,
      color: _bg2,
      child: Column(
        children: [
          Text(
            _t['howHead']!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 40,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 56),
          _responsiveGrid(context, [
            for (final s in steps) _stepCard(s.$1, s.$2, s.$3),
          ]),
        ],
      ),
    );
  }

  Widget _stepCard(String n, String title, String desc) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: _red,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _red.withValues(alpha: 0.4),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            n,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 22),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          desc,
          textAlign: TextAlign.center,
          style: const TextStyle(color: _muted, fontSize: 15, height: 1.6),
        ),
      ],
    );
  }

  // ── Screenshots ──────────────────────────────────────────────────────────
  Widget _screenshots(BuildContext context) {
    return _section(
      child: Column(
        children: [
          _sectionHead(_t['shotHead']!, _t['shotSub']),
          const SizedBox(height: 56),
          Wrap(
            spacing: 32,
            runSpacing: 32,
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [_dashboardMock(), _phoneMock()],
          ),
        ],
      ),
    );
  }

  Widget _dashboardMock() {
    Widget kpi(String label, String value, {Color? valueColor}) => Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: _subtle, fontSize: 12)),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: valueColor ?? Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
    Widget bar(double h, {bool accent = false}) => Expanded(
      child: Container(
        height: 150 * h,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: accent
                ? const [_red2, Color(0xFF991B1B)]
                : const [_red, Color(0xFF7F1D1D)],
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
        ),
      ),
    );
    return Container(
      constraints: const BoxConstraints(maxWidth: 620, minWidth: 300),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 60,
            offset: const Offset(0, 24),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
              ),
            ),
            child: Row(
              children: [
                _dot(_red),
                const SizedBox(width: 7),
                _dot(_gold),
                const SizedBox(width: 7),
                _dot(_emerald),
                const Spacer(),
                Text(
                  _t['shotDash']!,
                  style: const TextStyle(
                    color: _subtle,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              children: [
                Row(
                  children: [
                    kpi(_t['kRevenue']!, '₪128k'),
                    const SizedBox(width: 12),
                    kpi(_t['kMembers']!, '1,284'),
                    const SizedBox(width: 12),
                    kpi(_t['kToday']!, '342', valueColor: _emerald),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: _card,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SizedBox(
                    height: 150,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        bar(0.45),
                        const SizedBox(width: 12),
                        bar(0.70),
                        const SizedBox(width: 12),
                        bar(0.55),
                        const SizedBox(width: 12),
                        bar(0.88),
                        const SizedBox(width: 12),
                        bar(0.62),
                        const SizedBox(width: 12),
                        bar(0.78),
                        const SizedBox(width: 12),
                        bar(1.0, accent: true),
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

  Widget _dot(Color c) => Container(
    width: 11,
    height: 11,
    decoration: BoxDecoration(color: c, shape: BoxShape.circle),
  );

  Widget _phoneMock() {
    return Container(
      width: 270,
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(color: Colors.black, width: 8),
        borderRadius: BorderRadius.circular(38),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 60,
            offset: const Offset(0, 24),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Container(
        color: _bg,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 22, 18, 14),
              child: Column(
                children: [
                  Text(
                    _t['phGreet']!,
                    style: const TextStyle(color: _subtle, fontSize: 12),
                  ),
                  Text(
                    _t['phName']!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_crimson, Color(0xFF7F1D1D)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _t['phPlan']!,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 13,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _emerald,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          _t['phActive']!,
                          style: const TextStyle(
                            color: Color(0xFF04231A),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '24 ${_t['phDays']!}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _t['phLeft']!,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.qr_code_2,
                      size: 78,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _t['phScan']!,
                    style: const TextStyle(color: _muted, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Testimonials ─────────────────────────────────────────────────────────
  Widget _testimonials(BuildContext context) {
    final quotes = [
      (_t['q1']!, 'A', _t['n1']!, _t['g1']!),
      (_t['q2']!, 'B', _t['n2']!, _t['g2']!),
      (_t['q3']!, 'C', _t['n3']!, _t['g3']!),
    ];
    return _section(
      color: _bg2,
      child: Column(
        children: [
          Text(
            _t['testHead']!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 40,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 56),
          _responsiveGrid(context, [
            for (final q in quotes) _quoteCard(q.$1, q.$2, q.$3, q.$4),
          ]),
          const SizedBox(height: 22),
          Text(
            _t['placeholderNote']!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF5A5A5A),
              fontFamily: 'monospace',
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _quoteCard(String quote, String initial, String name, String gym) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: _card,
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '“$quote”',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              height: 1.7,
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: _red,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    gym,
                    style: const TextStyle(color: _subtle, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Pricing ──────────────────────────────────────────────────────────────
  bool _billingAnnual = false;

  Widget _pricingSection(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final data = _pricing;

    Widget priceRowFor(PricingTier? tier) {
      if (_pricingLoading) return const _PriceSkeleton();
      if (data == null || tier == null) {
        return const Text(
          '—',
          style: TextStyle(
            color: Colors.white,
            fontSize: 38,
            fontWeight: FontWeight.w900,
          ),
        );
      }
      final amount =
          _billingAnnual ? tier.annualMonthlyEquivalent : tier.monthly;
      return Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        mainAxisSize: MainAxisSize.min,
        children: [
          Directionality(
            textDirection: TextDirection.ltr,
            child: Text(
              data.format(amount),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 38,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Text(
            ' ${_t['perMo']!}',
            style: const TextStyle(color: _subtle, fontSize: 15),
          ),
        ],
      );
    }

    Widget? trialHintFor(bool trialEligible) {
      if (!trialEligible || data == null) return null;
      final label = _ar
          ? '${data.trialDays} يوماً مجاناً · ${_t['noCardRequired']!}'
          : '${data.trialDays}-day free trial · ${_t['noCardRequired']!}';
      return Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(color: _subtle, fontSize: 11.5),
        ),
      );
    }

    Widget? annualNoteFor(PricingTier? tier) {
      if (!_billingAnnual || tier == null) return null;
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          _t['billingAnnualNote']!,
          style: const TextStyle(color: _subtle, fontSize: 11.5),
        ),
      );
    }

    final cards = [
      _priceCard(
        name: _t['p1name']!,
        desc: _t['p1desc']!,
        priceRow: priceRowFor(data?.starter),
        priceSubtitle: annualNoteFor(data?.starter),
        features: [_t['p1f1']!, _t['p1f2']!, _t['p1f3']!, _t['p1f4']!],
        ctaLabel: _t['cta1']!,
        highlighted: false,
        trialHint: trialHintFor(data?.starter.trialEligible ?? false),
      ),
      _priceCard(
        name: _t['p2name']!,
        desc: _t['p2desc']!,
        priceRow: priceRowFor(data?.growth),
        priceSubtitle: annualNoteFor(data?.growth),
        features: [
          _t['p2f1']!,
          _t['p2f2']!,
          _t['p2f3']!,
          _t['p2f4']!,
          _t['p2f5']!,
        ],
        ctaLabel: _t['cta1']!,
        highlighted: true,
        badge: _t['mostPopular']!,
        trialHint: trialHintFor(data?.growth.trialEligible ?? false),
      ),
      _priceCard(
        name: _t['p3name']!,
        desc: _t['p3desc']!,
        priceRow: priceRowFor(data?.pro),
        priceSubtitle: annualNoteFor(data?.pro),
        features: [_t['p3f1']!, _t['p3f2']!, _t['p3f3']!, _t['p3f4']!],
        ctaLabel: _t['cta1']!,
        highlighted: false,
      ),
      _priceCard(
        name: _t['p4name']!,
        desc: _t['p4desc']!,
        priceRow: Text(
          _t['enterprisePriceLabel']!,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 34,
            fontWeight: FontWeight.w900,
          ),
        ),
        priceSubtitle: data == null
            ? null
            : Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(
                    '${_t['enterpriseFrom']!} ${data.format(data.enterprisePerBranchFrom)}${_t['perBranchMonthly']!}',
                    style: const TextStyle(color: _subtle, fontSize: 12.5),
                  ),
                ),
              ),
        features: [_t['p4f1']!, _t['p4f2']!, _t['p4f3']!, _t['p4f4']!],
        ctaLabel: _t['contactSales']!,
        highlighted: false,
      ),
    ];

    Widget layout;
    if (width >= 1300) {
      layout = IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < cards.length; i++) ...[
              Expanded(child: cards[i]),
              if (i < cards.length - 1) const SizedBox(width: 20),
            ],
          ],
        ),
      );
    } else if (width >= 700) {
      layout = Column(
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: cards[0]),
                const SizedBox(width: 20),
                Expanded(child: cards[1]),
              ],
            ),
          ),
          const SizedBox(height: 20),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: cards[2]),
                const SizedBox(width: 20),
                Expanded(child: cards[3]),
              ],
            ),
          ),
        ],
      );
    } else {
      layout = Column(
        children: [
          for (final c in cards) ...[c, const SizedBox(height: 20)],
        ],
      );
    }

    return _section(
      key: _pricingKey,
      child: Column(
        children: [
          Text(
            _t['pricingHead']!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 40,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 22),
          Center(child: _billingToggle()),
          const SizedBox(height: 40),
          layout,
          if (data != null && !data.isFinalized) ...[
            const SizedBox(height: 20),
            Text(
              _t['pricingDisclaimerUsd']!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _subtle, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }

  Widget _billingToggle() {
    final savePct = _pricing?.annualDiscountPercent;
    final annualLabel = savePct == null
        ? _t['billingAnnual']!
        : '${_t['billingAnnual']!} · ${_ar ? "وفّر" : "Save"} $savePct%';
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _billingPill(
            _t['billingMonthly']!,
            !_billingAnnual,
            () => setState(() => _billingAnnual = false),
          ),
          _billingPill(
            annualLabel,
            _billingAnnual,
            () => setState(() => _billingAnnual = true),
          ),
        ],
      ),
    );
  }

  Widget _billingPill(String label, bool selected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? _red : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : _muted,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _priceCard({
    required String name,
    required String desc,
    required Widget priceRow,
    Widget? priceSubtitle,
    required List<String> features,
    required String ctaLabel,
    required bool highlighted,
    String? badge,
    Widget? trialHint,
  }) {
    final card = Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: highlighted
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF241416), _card],
              )
            : null,
        color: highlighted ? null : _card,
        border: Border.all(
          color: highlighted ? _red : Colors.white.withValues(alpha: 0.08),
          width: highlighted ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: highlighted
            ? [
                BoxShadow(
                  color: _red.withValues(alpha: 0.22),
                  blurRadius: 50,
                  offset: const Offset(0, 20),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(desc, style: const TextStyle(color: _muted, fontSize: 14)),
          const SizedBox(height: 18),
          priceRow,
          ?priceSubtitle,
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: highlighted
                ? _primaryCta(ctaLabel, () => _scrollTo(_gatewayKey))
                : _outlineCta(ctaLabel, () => _scrollTo(_gatewayKey)),
          ),
          ?trialHint,
          const SizedBox(height: 22),
          for (final f in features)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '✓',
                    style: TextStyle(color: _red2, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      f,
                      style: TextStyle(
                        color: highlighted
                            ? Colors.white
                            : const Color(0xFFD4D4D4),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );

    if (badge == null) return card;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Padding(padding: const EdgeInsets.only(top: 13), child: card),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: _red,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                badge,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── FAQ ──────────────────────────────────────────────────────────────────
  Widget _faq(BuildContext context) {
    final items = [
      (_t['faq0q']!, _t['faq0a']!),
      (_t['faq1q']!, _t['faq1a']!),
      (_t['faq2q']!, _t['faq2a']!),
      (_t['faq3q']!, _t['faq3a']!),
      (_t['faq4q']!, _t['faq4a']!),
    ];
    return _section(
      key: _faqKey,
      color: _bg2,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Column(
            children: [
              Text(
                _t['faqHead']!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 48),
              for (var i = 0; i < items.length; i++) ...[
                _faqItem(i, items[i].$1, items[i].$2),
                const SizedBox(height: 14),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _faqItem(int i, String q, String a) {
    final open = _faqOpen == i;
    return Container(
      decoration: BoxDecoration(
        color: _card,
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _faqOpen = open ? -1 : i),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      q,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    open ? '−' : '+',
                    style: const TextStyle(color: _red2, fontSize: 24),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 22),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  a,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 15,
                    height: 1.6,
                  ),
                ),
              ),
            ),
            crossFadeState: open
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 220),
          ),
        ],
      ),
    );
  }

  // ── Gateway / final CTA ──────────────────────────────────────────────────
  Widget _gateway(BuildContext context) {
    return Container(
      key: _gatewayKey,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 104),
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, 1.3),
          radius: 1.1,
          colors: [Color(0xFF1E1E1E), _bg],
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            children: [
              Text(
                _t['finalHead']!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 44,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                _t['finalSub']!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: _muted, fontSize: 19),
              ),
              const SizedBox(height: 48),
              _responsiveGrid(context, [
                _roleCard(
                  Icons.person,
                  _crimson,
                  _t['roleMember']!,
                  _t['roleMemberD']!,
                  () => context.go('/client/welcome'),
                ),
                _roleCard(
                  Icons.badge,
                  _red,
                  _t['roleStaff']!,
                  _t['roleStaffD']!,
                  () => context.go('/login'),
                ),
                _roleCard(
                  Icons.admin_panel_settings,
                  _gold,
                  _t['roleAdmin']!,
                  _t['roleAdminD']!,
                  () => context.go('/login'),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roleCard(
    IconData icon,
    Color color,
    String title,
    String desc,
    VoidCallback onTap,
  ) {
    return _HoverLift(
      builder: (hovering) => Material(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.5)),
            ),
            child: Column(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: color, size: 26),
                ),
                const SizedBox(height: 18),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  desc,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: _muted, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Footer ───────────────────────────────────────────────────────────────
  Widget _footer(BuildContext context) {
    return Container(
      width: double.infinity,
      color: _bg,
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 40),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0x12FFFFFF))),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Wrap(
            spacing: 24,
            runSpacing: 20,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _logoMark(30),
                  const SizedBox(width: 10),
                  const Text(
                    'PowerFit',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              Wrap(
                spacing: 24,
                runSpacing: 8,
                children: [
                  _footerLink(
                    _t['navFeatures']!,
                    () => _scrollTo(_featuresKey),
                  ),
                  _footerLink(_t['navPricing']!, () => _scrollTo(_pricingKey)),
                  _footerLink(_t['navFaq']!, () => _scrollTo(_faqKey)),
                  _footerLink(_t['login']!, () => _scrollTo(_gatewayKey)),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _langButton(),
                  const SizedBox(width: 16),
                  const Text(
                    '© 2026 PowerFit',
                    style: TextStyle(color: Color(0xFF5A5A5A), fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _footerLink(String text, VoidCallback onTap) => InkWell(
    onTap: onTap,
    child: Text(text, style: const TextStyle(color: _muted, fontSize: 14)),
  );

  Widget _langButton() => OutlinedButton(
    onPressed: _toggleLang,
    style: OutlinedButton.styleFrom(
      foregroundColor: Colors.white,
      side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      minimumSize: Size.zero,
    ),
    child: Text(
      _ar ? 'EN' : 'ع',
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
    ),
  );

  // ── Shared bits ──────────────────────────────────────────────────────────
  Widget _sectionHead(String head, String? sub) {
    return Column(
      children: [
        Text(
          head,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 40,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.4,
          ),
        ),
        if (sub != null) ...[
          const SizedBox(height: 12),
          Text(
            sub,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _muted, fontSize: 18),
          ),
        ],
      ],
    );
  }

  /// Lays children into a 3-col grid on wide screens, 1-col on narrow.
  Widget _responsiveGrid(BuildContext context, List<Widget> children) {
    final width = MediaQuery.of(context).size.width;
    final cols = width >= 900 ? 3 : (width >= 620 ? 2 : 1);
    const gap = 22.0;
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += cols) {
      final rowChildren = <Widget>[];
      for (var j = 0; j < cols; j++) {
        final idx = i + j;
        rowChildren.add(
          Expanded(
            child: idx < children.length ? children[idx] : const SizedBox(),
          ),
        );
        if (j < cols - 1) rowChildren.add(const SizedBox(width: gap));
      }
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: rowChildren,
          ),
        ),
      );
      if (i + cols < children.length) rows.add(const SizedBox(height: gap));
    }
    return Column(children: rows);
  }
}

Widget _logoMark(double size) => Container(
  width: size,
  height: size,
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(size * 0.28),
    boxShadow: [
      BoxShadow(
        color: _red.withValues(alpha: 0.5),
        blurRadius: 14,
        offset: const Offset(0, 4),
      ),
    ],
  ),
  child: ClipRRect(
    borderRadius: BorderRadius.circular(size * 0.28),
    child: Image.asset('assets/icon/powerfit.jpeg', fit: BoxFit.cover),
  ),
);

// ── Header ───────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final Map<String, String> t;
  final String langLabel;
  final VoidCallback onToggleLang;
  final VoidCallback onNavFeatures, onNavHow, onNavPricing, onNavFaq, onLogin;
  final bool wide;

  const _Header({
    required this.t,
    required this.langLabel,
    required this.onToggleLang,
    required this.onNavFeatures,
    required this.onNavHow,
    required this.onNavPricing,
    required this.onNavFaq,
    required this.onLogin,
    required this.wide,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _bg.withValues(alpha: 0.9),
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.07)),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              child: Row(
                children: [
                  _logoMark(32),
                  const SizedBox(width: 10),
                  const Text(
                    'PowerFit',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  if (wide) ...[
                    _navLink(t['navFeatures']!, onNavFeatures),
                    const SizedBox(width: 26),
                    _navLink(t['navHow']!, onNavHow),
                    const SizedBox(width: 26),
                    _navLink(t['navPricing']!, onNavPricing),
                    const SizedBox(width: 26),
                    _navLink(t['navFaq']!, onNavFaq),
                    const SizedBox(width: 24),
                  ],
                  OutlinedButton(
                    onPressed: onToggleLang,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                      minimumSize: Size.zero,
                    ),
                    child: Text(
                      langLabel,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: onLogin,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.24),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(t['login']!),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _navLink(String text, VoidCallback onTap) => InkWell(
    onTap: onTap,
    child: Text(
      text,
      style: const TextStyle(
        color: _muted,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

/// Fades + slides its child up on first build.
class _HeroFadeIn extends StatefulWidget {
  final Widget child;
  const _HeroFadeIn({required this.child});
  @override
  State<_HeroFadeIn> createState() => _HeroFadeInState();
}

class _HeroFadeInState extends State<_HeroFadeIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  )..forward();
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = Curves.easeOutCubic.transform(_c.value);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 24),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Fades a section in the first time it scrolls into view.
class _RevealOnScroll extends StatefulWidget {
  final Widget child;
  const _RevealOnScroll({required this.child});
  @override
  State<_RevealOnScroll> createState() => _RevealOnScrollState();
}

class _RevealOnScrollState extends State<_RevealOnScroll>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 550),
  );
  ScrollPosition? _position;
  bool _revealed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final p = Scrollable.of(context).position;
    if (p != _position) {
      _position?.removeListener(_maybeReveal);
      _position = p;
      _position?.addListener(_maybeReveal);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeReveal());
  }

  void _maybeReveal() {
    if (_revealed || !mounted) return;
    final ro = context.findRenderObject();
    if (ro is! RenderBox || !ro.attached) return;
    final top = ro.localToGlobal(Offset.zero).dy;
    final vh = MediaQuery.of(context).size.height;
    if (top < vh * 0.9) {
      _revealed = true;
      _c.forward();
    }
  }

  @override
  void dispose() {
    _position?.removeListener(_maybeReveal);
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = Curves.easeOut.transform(_c.value);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 24),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Lifts its child slightly on hover (desktop web).
class _HoverLift extends StatefulWidget {
  final Widget Function(bool hovering) builder;
  const _HoverLift({required this.builder});
  @override
  State<_HoverLift> createState() => _HoverLiftState();
}

class _HoverLiftState extends State<_HoverLift> {
  bool _hovering = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        transform: Matrix4.translationValues(0, _hovering ? -6 : 0, 0),
        child: widget.builder(_hovering),
      ),
    );
  }
}

/// Pulsing placeholder shown in place of a price number while
/// GET /api/pricing is in flight — sized to roughly match the real price
/// text so nothing jumps when the real number arrives.
class _PriceSkeleton extends StatefulWidget {
  const _PriceSkeleton();
  @override
  State<_PriceSkeleton> createState() => _PriceSkeletonState();
}

class _PriceSkeletonState extends State<_PriceSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        return Opacity(
          opacity: 0.35 + (_c.value * 0.35),
          child: Container(
            width: 96,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      },
    );
  }
}

// ── Content ────────────────────────────────────────────────────────────────
const Map<String, String> _arText = {
  'navFeatures': 'الميزات',
  'navHow': 'كيف يعمل',
  'navPricing': 'الأسعار',
  'navFaq': 'الأسئلة',
  'login': 'تسجيل الدخول',
  'heroBadge': 'نظام إدارة النوادي الرياضية',
  'heroHead': 'أدر ناديك بالكامل من مكان واحد',
  'heroSub':
      'إدارة كاملة للاشتراكات والفروع والدخول عبر رمز QR — لأعضاء النادي والموظفين والإدارة، في مكان واحد.',
  'cta1': 'ابدأ الآن',
  'cta2': 'شاهد كيف يعمل',
  'trust': 'يثق به نوادٍ في المنطقة',
  'featHead': 'كل ما يحتاجه ناديك في مكان واحد',
  'featSub': 'أدوات متكاملة للإدارة والفروع والأعضاء.',
  'f1t': 'دخول سريع عبر QR',
  'f1d': 'سجّل حضور الأعضاء في ثوانٍ عبر مسح رمز QR.',
  'f2t': 'متابعة الاشتراكات',
  'f2d': 'تجديد وتجميد وإيقاف مع تنبيهات قبل الانتهاء.',
  'f3t': 'إدارة متعددة الفروع',
  'f3d': 'لوحة منفصلة لكل فرع ومقارنات فورية.',
  'f4t': 'تقارير مالية دقيقة',
  'f4d': 'إيرادات ومصروفات وإقفال يومي بضغطة واحدة.',
  'f5t': 'تنبيهات ذكية',
  'f5d': 'تنبيهات فورية للاشتراكات المنتهية والخلل التشغيلي.',
  'f6t': 'إدارة الموظفين',
  'f6d': 'صلاحيات لكل دور وتتبّع أداء الفريق.',
  'howHead': 'كيف يعمل',
  's1t': 'سجّل ناديك وفروعك',
  's1d': 'أنشئ حسابك وأضف فروعك في دقائق.',
  's2t': 'أضف الأعضاء والموظفين',
  's2d': 'استورد أعضاءك ومنح كل موظف دوره.',
  's3t': 'تابع كل شيء لحظياً',
  's3d': 'راقب الحضور والإيرادات من لوحة واحدة.',
  'shotHead': 'مصمّم لكل شاشة',
  'shotSub': 'كونسول الموظفين وتطبيق الأعضاء بلغة تصميم واحدة.',
  'shotDash': 'لوحة المالك',
  'kRevenue': 'الإيرادات',
  'kMembers': 'الأعضاء',
  'kToday': 'دخول اليوم',
  'phGreet': 'مرحباً بعودتك',
  'phName': 'أحمد',
  'phPlan': 'اشتراكك',
  'phActive': 'نشط',
  'phDays': 'يوم',
  'phLeft': 'متبقٍ على انتهاء الاشتراك',
  'phScan': 'امسح للدخول',
  'testHead': 'يحبّه أصحاب النوادي',
  'q1': 'باور فِت استبدل ثلاث أدوات كنا نتنقل بينها. الدخول صار فورياً.',
  'q2': 'إدارة خمسة فروع من شاشة واحدة غيّرت طريقة عملنا.',
  'q3': 'التقارير المالية توفّر عليّ ساعات كل أسبوع.',
  'n1': 'اسم تجريبي',
  'g1': 'نادي آيرون هاوس',
  'n2': 'اسم تجريبي',
  'g2': 'بيك فِتنس',
  'n3': 'اسم تجريبي',
  'g3': 'نادي تيتان',
  'placeholderNote': 'أسماء وشهادات تجريبية — استبدلها بعملائك.',
  'pricingHead': 'أسعار بسيطة تنمو معك',
  'mostPopular': 'الأكثر شيوعاً',
  'perMo': '/شهرياً',
  'contactSales': 'تواصل معنا',
  'billingMonthly': 'شهري',
  'billingAnnual': 'سنوي',
  'billingAnnualNote': 'يُحاسب سنوياً',
  'noCardRequired': 'بدون بطاقة ائتمان',
  'pricingDisclaimerUsd':
      'الأسعار معروضة بالدولار الأمريكي — تواصل معنا للعملات المحلية',
  'enterprisePriceLabel': 'مخصّص',
  'enterpriseFrom': 'ابتداءً من',
  'perBranchMonthly': '/فرع شهرياً',
  'p1name': 'المبتدئ',
  'p1desc': 'فرع واحد',
  'p1f1': 'فرع واحد · حتى 150 عضو',
  'p1f2': 'لوحة تحكم المالك',
  'p1f3': 'تطبيق مخصص لأعضاء ناديك',
  'p1f4': 'تسجيل الدخول، الاشتراكات، وسجل الدفع',
  'p2name': 'النمو',
  'p2desc': 'فرع واحد، أدوات أذكى',
  'p2f1': 'كل مزايا المبتدئ',
  'p2f2': 'حتى 450 عضو',
  'p2f3': 'أتمتة التجديد عبر واتساب / SMS',
  'p2f4': 'جدولة المدربين والحصص',
  'p2f5': 'تحليلات الإيرادات',
  'p3name': 'الاحترافي',
  'p3desc': 'حتى 3 فروع',
  'p3f1': 'كل مزايا النمو',
  'p3f2': 'حتى 3 فروع وحتى 1,200 عضو',
  'p3f3': 'تقارير متعددة الفروع',
  'p3f4': 'علامة تجارية مخصصة ودعم ذو أولوية',
  'p4name': 'المؤسسات',
  'p4desc': '4 فروع فأكثر',
  'p4f1': '4 فروع فأكثر · أعضاء غير محدودين',
  'p4f2': 'مدير حساب مخصص',
  'p4f3': 'وصول عبر API',
  'p4f4': 'خصم على الحجم',
  'faqHead': 'الأسئلة الشائعة',
  'faq0q': 'كيف يعمل الدخول عبر QR؟',
  'faq0a':
      'يمسح العضو رمز QR عند الباب فيسجّل النظام الحضور فوراً دون أي انتظار.',
  'faq1q': 'كم فرعاً يمكنني إدارته؟',
  'faq1a': 'أي عدد تحتاجه — لكل فرع لوحته الخاصة مع مقارنات فورية بين الفروع.',
  'faq2q': 'هل بياناتي آمنة؟',
  'faq2a': 'نعم، البيانات مشفّرة والوصول محكوم بصلاحيات حسب دور كل موظف.',
  'faq3q': 'هل يوجد تطبيق للأعضاء؟',
  'faq3a': 'نعم، للأعضاء تطبيق خاص للاشتراكات والدخول عبر QR وسجل الزيارات.',
  'faq4q': 'هل يمكنني التجربة أولاً؟',
  'faq4a': 'ابدأ مجاناً وارتقِ بالخطة متى شئت دون التزام.',
  'finalHead': 'جاهز لإدارة ناديك بذكاء؟',
  'finalSub': 'اختر كيف تريد الدخول.',
  'roleMember': 'عميل',
  'roleMemberD': 'ادخل إلى تطبيق الأعضاء',
  'roleStaff': 'موظف',
  'roleStaffD': 'سجّل الدخول إلى الكونسول',
  'roleAdmin': 'مسؤول النظام',
  'roleAdminD': 'إدارة النظام',
};

const Map<String, String> _enText = {
  'navFeatures': 'Features',
  'navHow': 'How it works',
  'navPricing': 'Pricing',
  'navFaq': 'FAQ',
  'login': 'Log in',
  'heroBadge': 'Gym management system',
  'heroHead': 'Run your entire gym from one place',
  'heroSub':
      'Complete control of subscriptions, branches, and QR entry — for members, staff, and owners, all in one place.',
  'cta1': 'Get started',
  'cta2': 'See how it works',
  'trust': 'Trusted by gyms across the region',
  'featHead': 'Everything your gym needs, in one place.',
  'featSub': 'Integrated tools for management, branches, and members.',
  'f1t': 'Instant QR check-in',
  'f1d': 'Check members in within seconds by scanning a QR code.',
  'f2t': 'Subscription control',
  'f2d': 'Renew, freeze, stop — with alerts before expiry.',
  'f3t': 'Multi-branch',
  'f3d': 'A dashboard per branch, instant comparisons.',
  'f4t': 'Financial reports',
  'f4d': 'Revenue, expenses, daily close-out in one click.',
  'f5t': 'Smart alerts',
  'f5d': 'Real-time alerts for expiries and operational issues.',
  'f6t': 'Staff management',
  'f6d': 'Role-based permissions and team performance.',
  'howHead': 'How it works',
  's1t': 'Set up your gym & branches',
  's1d': 'Create your account and add branches in minutes.',
  's2t': 'Add members and staff',
  's2d': 'Import members and give each employee a role.',
  's3t': 'Track everything in real time',
  's3d': 'Monitor attendance and revenue from one dashboard.',
  'shotHead': 'Built for every screen',
  'shotSub': 'Staff console and member app, one design language.',
  'shotDash': 'Owner dashboard',
  'kRevenue': 'Revenue',
  'kMembers': 'Members',
  'kToday': 'Today’s entries',
  'phGreet': 'Welcome back',
  'phName': 'Ahmed',
  'phPlan': 'Your plan',
  'phActive': 'Active',
  'phDays': 'days',
  'phLeft': 'left until renewal',
  'phScan': 'Scan to enter',
  'testHead': 'Loved by gym owners',
  'q1':
      'PowerFit replaced three tools we used to juggle. Check-in is instant now.',
  'q2': 'Managing five branches from one screen changed how we operate.',
  'q3': 'The financial reports save me hours every week.',
  'n1': 'Placeholder name',
  'g1': 'Iron House Gym',
  'n2': 'Placeholder name',
  'g2': 'Peak Fitness',
  'n3': 'Placeholder name',
  'g3': 'Titan Club',
  'placeholderNote':
      'Placeholder names & quotes — replace with your customers.',
  'pricingHead': 'Simple pricing that scales',
  'mostPopular': 'Most popular',
  'perMo': '/mo',
  'contactSales': 'Contact sales',
  'billingMonthly': 'Monthly',
  'billingAnnual': 'Annual',
  'billingAnnualNote': 'billed annually',
  'noCardRequired': 'No credit card required',
  'pricingDisclaimerUsd':
      'Prices shown in USD — contact us for local currency options',
  'enterprisePriceLabel': 'Custom',
  'enterpriseFrom': 'From',
  'perBranchMonthly': '/branch monthly',
  'p1name': 'Starter',
  'p1desc': 'Single branch',
  'p1f1': '1 branch · up to 150 members',
  'p1f2': 'Owner dashboard',
  'p1f3': 'A branded app for your members',
  'p1f4': 'Check-in, subscriptions & payment history',
  'p2name': 'Growth',
  'p2desc': 'Single branch, smarter tools',
  'p2f1': 'Everything in Starter',
  'p2f2': 'Up to 450 members',
  'p2f3': 'WhatsApp/SMS renewal automation',
  'p2f4': 'Trainer & class scheduling',
  'p2f5': 'Revenue analytics',
  'p3name': 'Pro',
  'p3desc': 'Up to 3 branches',
  'p3f1': 'Everything in Growth',
  'p3f2': 'Up to 3 branches & 1,200 members',
  'p3f3': 'Multi-branch reporting',
  'p3f4': 'Custom branding & priority support',
  'p4name': 'Enterprise',
  'p4desc': '4+ branches',
  'p4f1': '4+ branches · unlimited members',
  'p4f2': 'Dedicated account manager',
  'p4f3': 'API access',
  'p4f4': 'Volume discount',
  'faqHead': 'Frequently asked questions',
  'faq0q': 'How does QR check-in work?',
  'faq0a':
      'Members scan a QR code at the door and the system logs attendance instantly, with no waiting.',
  'faq1q': 'How many branches can I manage?',
  'faq1a':
      'As many as you need — each branch gets its own dashboard with instant cross-branch comparisons.',
  'faq2q': 'Is my data secure?',
  'faq2a':
      'Yes. Data is encrypted and access is controlled by role-based permissions per employee.',
  'faq3q': 'Is there a member app?',
  'faq3a':
      'Yes — members get their own app for subscriptions, QR entry, and visit history.',
  'faq4q': 'Can I try it first?',
  'faq4a': 'Start free and upgrade whenever you are ready, no commitment.',
  'finalHead': 'Ready to run your gym the smart way?',
  'finalSub': 'Choose how you want to enter.',
  'roleMember': 'Member',
  'roleMemberD': 'Open the member app',
  'roleStaff': 'Staff',
  'roleStaffD': 'Log in to the console',
  'roleAdmin': 'System admin',
  'roleAdminD': 'System administration',
};
