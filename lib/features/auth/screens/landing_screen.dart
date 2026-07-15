import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/models/pricing_model.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/services/pricing_service.dart';

const _contactEmail = 'yamen.mahmoud912@gmail.com';

/// Public marketing homepage served at '/'. Full bilingual (AR/EN) PowerFit
/// site, repositioned around the two pillars a gym business actually buys:
/// accounting/financial control and business intelligence. Everything else
/// (check-in, subscriptions, staff) is presented as the plumbing that feeds
/// those two. Members, staff, and admins all share the unified login at
/// '/login' — the backend resolves the account kind after submit.
class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

// ── Instrument-panel palette ─────────────────────────────────────────────────
// Deep charcoal-navy base + off-white sections. Brand red survives from the
// PowerFit logo but is confined to the logo and primary CTAs; money-positive
// numbers are emerald, KPI/insight callouts are gold, and electric blue is
// reserved exclusively for chart marks (validated against _panel surface).
const _navy = Color(0xFF0E1425); // dark section base
const _navyDeep = Color(0xFF0A0F1D); // footer / deepest band
const _panel = Color(0xFF16203A); // raised panels on navy
const _edgeOnNavy = Color(0xFF243050); // hairlines on navy
const _paper = Color(0xFFF6F7F9); // light section base
const _cardOnPaper = Colors.white;
const _edgeOnPaper = Color(0xFFE2E5EC); // hairlines on paper
const _ink = Color(0xFF141A2A); // headings on paper
const _body = Color(0xFF3A4356); // body text on paper
const _mutedNavy = Color(0xFF9AA3B8); // body text on navy
const _subtleNavy = Color(0xFF6B7590); // captions on navy
const _red = Color(0xFFDC2626); // brand red — logo + primary CTA only
const _emerald = Color(0xFF1F7A5C); // accent on paper
const _emeraldUp = Color(0xFF34C48E); // positive deltas on navy
const _gold = Color(0xFFD4A73D); // KPI / insight moments, sparingly
const _blue = Color(0xFF4C6FFF); // charts only
const _blueDeep = Color(0xFF2B49C9); // charts only
const _bluePale = Color(0xFF8FA5FF); // charts only
const _chartNeutral = Color(0xFF55607A); // labeled "other" slice
const _monoFamily = 'IBMPlexMono';

/// Every number, metric, and data label on the page wears the mono face.
/// Cairo fallback keeps Arabic words legible inside mono-styled labels.
TextStyle _mono({
  double size = 13,
  Color color = Colors.white,
  FontWeight weight = FontWeight.w400,
  double? spacing,
  double? height,
}) {
  return TextStyle(
    fontFamily: _monoFamily,
    fontFamilyFallback: const ['Cairo'],
    fontSize: size,
    color: color,
    fontWeight: weight,
    letterSpacing: spacing,
    height: height,
  );
}

class _LandingScreenState extends State<LandingScreen> {
  final _scrollController = ScrollController();
  final _pillar1Key = GlobalKey();
  final _pillar2Key = GlobalKey();
  final _pricingKey = GlobalKey();
  final _faqKey = GlobalKey();

  // Reads through the app-wide LocaleProvider (persisted via
  // SharedPreferences) rather than owning local state, so the choice
  // survives both navigating away from this route and a full page reload.
  bool get _ar => context.watch<LocaleProvider>().isArabic;
  int _faqOpen = -1;

  void _toggleLang() {
    final locale = context.read<LocaleProvider>();
    locale.setArabic(!locale.isArabic);
  }

  Map<String, String> get _t => _ar ? _arText : _enText;

  // Arabic script must never be letterspaced; Latin eyebrows/labels are.
  double get _ls => _ar ? 0 : 1.6;

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

  bool _isWide(BuildContext c) => MediaQuery.of(c).size.width >= 980;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _ar ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: _navy,
        body: Column(
          children: [
            _Header(
              t: _t,
              langLabel: _ar ? 'EN' : 'ع',
              onToggleLang: _toggleLang,
              onNavP1: () => _scrollTo(_pillar1Key),
              onNavP2: () => _scrollTo(_pillar2Key),
              onNavPricing: () => _scrollTo(_pricingKey),
              onNavFaq: () => _scrollTo(_faqKey),
              onLogin: () => context.go('/login'),
              wide: _isWide(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  children: [
                    _hero(context),
                    _capStrip(context),
                    _RevealOnScroll(child: _problem(context)),
                    _RevealOnScroll(child: _pillar1(context)),
                    _RevealOnScroll(child: _pillar2(context)),
                    _RevealOnScroll(child: _supporting(context)),
                    _RevealOnScroll(child: _proof(context)),
                    _RevealOnScroll(child: _pricingSection(context)),
                    _RevealOnScroll(child: _faq(context)),
                    _finalCta(context),
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
    double vPad = 96,
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

  /// Pillar eyebrow — the one place section labels are allowed, because the
  /// two pillars are genuinely distinct product areas.
  Widget _eyebrow(String text, {required bool onDark}) {
    return Text(
      text,
      style: _mono(
        size: 12.5,
        weight: FontWeight.w600,
        color: onDark ? _emeraldUp : _emerald,
        spacing: _ls,
      ),
    );
  }

  Widget _sectionHead(String head, String? sub, {required bool onDark}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          head,
          style: TextStyle(
            color: onDark ? Colors.white : _ink,
            fontSize: 36,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.4,
            height: 1.2,
          ),
        ),
        if (sub != null) ...[
          const SizedBox(height: 14),
          Text(
            sub,
            style: TextStyle(
              color: onDark ? _mutedNavy : _body,
              fontSize: 17,
              height: 1.6,
            ),
          ),
        ],
      ],
    );
  }

  // ── Hero ─────────────────────────────────────────────────────────────────
  Widget _hero(BuildContext context) {
    final wide = _isWide(context);

    final copy = Column(
      crossAxisAlignment:
          wide ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Text(
          _t['heroEyebrow']!,
          textAlign: wide ? null : TextAlign.center,
          style: _mono(
            size: 12.5,
            weight: FontWeight.w600,
            color: _emeraldUp,
            spacing: _ls,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          _t['heroHead']!,
          textAlign: wide ? null : TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: wide ? 52 : 36,
            height: 1.12,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          _t['heroSub']!,
          textAlign: wide ? null : TextAlign.center,
          style: const TextStyle(color: _mutedNavy, fontSize: 17, height: 1.65),
        ),
        const SizedBox(height: 32),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          alignment: wide ? WrapAlignment.start : WrapAlignment.center,
          children: [
            _primaryCta(_t['cta1']!, () => context.go('/login')),
            _outlineCta(
              _t['cta2']!,
              () => _scrollTo(_pillar2Key),
              onDark: true,
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          _t['heroNote']!,
          style: _mono(size: 12, color: _subtleNavy, spacing: _ar ? 0 : 0.6),
        ),
      ],
    );

    final mock = _DashboardMock(t: _t, ar: _ar);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: wide ? 88 : 56),
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(-0.6, -1.2),
          radius: 1.6,
          colors: [Color(0xFF17223E), _navy],
          stops: [0.0, 0.72],
        ),
      ),
      child: _HeroFadeIn(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(flex: 6, child: copy),
                      const SizedBox(width: 56),
                      Expanded(flex: 5, child: Center(child: mock)),
                    ],
                  )
                : Column(
                    children: [copy, const SizedBox(height: 48), mock],
                  ),
          ),
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
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 18),
        elevation: 6,
        shadowColor: _red.withValues(alpha: 0.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          fontFamily: 'Cairo',
        ),
      ),
      child: Text(label),
    );
  }

  Widget _outlineCta(String label, VoidCallback onTap, {required bool onDark}) {
    final fg = onDark ? Colors.white : _ink;
    final side = onDark
        ? Colors.white.withValues(alpha: 0.28)
        : _ink.withValues(alpha: 0.3);
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: fg,
        side: BorderSide(color: side),
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          fontFamily: 'Cairo',
        ),
      ),
      child: Text(label),
    );
  }

  // ── Capability strip (replaces the fake trust bar with real product areas) ─
  Widget _capStrip(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: const BoxDecoration(
        color: _navyDeep,
        border: Border(
          top: BorderSide(color: _edgeOnNavy),
          bottom: BorderSide(color: _edgeOnNavy),
        ),
      ),
      child: Center(
        child: Text(
          _t['capStrip']!,
          textAlign: TextAlign.center,
          style: _mono(
            size: 12,
            color: _subtleNavy,
            weight: FontWeight.w600,
            spacing: _ar ? 0 : 2,
            height: 1.8,
          ),
        ),
      ),
    );
  }

  // ── Problem framing ──────────────────────────────────────────────────────
  Widget _problem(BuildContext context) {
    final pains = [
      (Icons.help_outline, _t['prob1t']!, _t['prob1d']!),
      (Icons.receipt_long_outlined, _t['prob2t']!, _t['prob2d']!),
      (Icons.call_split, _t['prob3t']!, _t['prob3d']!),
    ];
    return _section(
      color: _paper,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: _sectionHead(_t['probHead']!, _t['probSub'], onDark: false),
          ),
          const SizedBox(height: 48),
          _responsiveGrid(context, [
            for (final p in pains) _painCard(p.$1, p.$2, p.$3),
          ]),
        ],
      ),
    );
  }

  Widget _painCard(IconData icon, String title, String desc) {
    return _HoverCard(
      baseBorder: _edgeOnPaper,
      hoverBorder: _emerald.withValues(alpha: 0.45),
      color: _cardOnPaper,
      padding: const EdgeInsets.all(26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _body.withValues(alpha: 0.7), size: 24),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: _ink,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            desc,
            style: const TextStyle(color: _body, fontSize: 14.5, height: 1.65),
          ),
        ],
      ),
    );
  }

  // ── Pillar 1 — Accounting & financial control ────────────────────────────
  Widget _pillar1(BuildContext context) {
    final wide = _isWide(context);
    final caps = [
      (Icons.receipt_long, _t['p1c1t']!, _t['p1c1d']!),
      (Icons.fact_check_outlined, _t['p1c2t']!, _t['p1c2d']!),
      (Icons.account_balance_outlined, _t['p1c3t']!, _t['p1c3d']!),
      (Icons.point_of_sale, _t['p1c4t']!, _t['p1c4d']!),
      (Icons.description_outlined, _t['p1c5t']!, _t['p1c5d']!),
    ];

    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _eyebrow(_t['p1Eyebrow']!, onDark: false),
        const SizedBox(height: 14),
        _sectionHead(_t['p1Head']!, _t['p1Sub'], onDark: false),
        const SizedBox(height: 30),
        for (final c in caps) _capabilityRow(c.$1, c.$2, c.$3, onDark: false),
      ],
    );

    final visual = _LedgerPanel(t: _t, ar: _ar);

    return _section(
      key: _pillar1Key,
      color: _paper,
      child: wide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(flex: 6, child: copy),
                const SizedBox(width: 64),
                Expanded(flex: 5, child: Center(child: visual)),
              ],
            )
          : Column(children: [copy, const SizedBox(height: 48), visual]),
    );
  }

  // ── Pillar 2 — Business intelligence ─────────────────────────────────────
  Widget _pillar2(BuildContext context) {
    final wide = _isWide(context);
    final caps = [
      (Icons.speed, _t['p2c1t']!, _t['p2c1d']!),
      (Icons.compare_arrows, _t['p2c2t']!, _t['p2c2d']!),
      (Icons.group_outlined, _t['p2c3t']!, _t['p2c3d']!),
      (Icons.notifications_active_outlined, _t['p2c4t']!, _t['p2c4d']!),
    ];

    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _eyebrow(_t['p2Eyebrow']!, onDark: true),
        const SizedBox(height: 14),
        _sectionHead(_t['p2Head']!, _t['p2Sub'], onDark: true),
        const SizedBox(height: 30),
        for (final c in caps) _capabilityRow(c.$1, c.$2, c.$3, onDark: true),
      ],
    );

    final visual = _BiPanel(t: _t, ar: _ar);

    return _section(
      key: _pillar2Key,
      color: _navy,
      child: wide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(flex: 5, child: Center(child: visual)),
                const SizedBox(width: 64),
                Expanded(flex: 6, child: copy),
              ],
            )
          : Column(children: [copy, const SizedBox(height: 48), visual]),
    );
  }

  Widget _capabilityRow(
    IconData icon,
    String title,
    String desc, {
    required bool onDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: onDark
                  ? _panel
                  : _emerald.withValues(alpha: 0.09),
              border: Border.all(
                color: onDark ? _edgeOnNavy : _emerald.withValues(alpha: 0.2),
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 20,
              color: onDark ? _emeraldUp : _emerald,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: onDark ? Colors.white : _ink,
                    fontSize: 16.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: TextStyle(
                    color: onDark ? _mutedNavy : _body,
                    fontSize: 14.5,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Supporting features (deliberately secondary) ─────────────────────────
  Widget _supporting(BuildContext context) {
    final features = [
      (Icons.qr_code_2, _t['s1t']!, _t['s1d']!),
      (Icons.card_membership, _t['s2t']!, _t['s2d']!),
      (Icons.store_outlined, _t['s3t']!, _t['s3d']!),
      (Icons.badge_outlined, _t['s4t']!, _t['s4d']!),
      (Icons.smartphone, _t['s5t']!, _t['s5d']!),
      (Icons.notifications_none, _t['s6t']!, _t['s6d']!),
    ];
    return _section(
      color: _paper,
      vPad: 80,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _t['supHead']!,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _t['supSub']!,
                  style: const TextStyle(
                    color: _body,
                    fontSize: 15.5,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 36),
          _responsiveGrid(context, [
            for (final f in features) _supportCard(f.$1, f.$2, f.$3),
          ]),
        ],
      ),
    );
  }

  Widget _supportCard(IconData icon, String title, String desc) {
    return _HoverCard(
      baseBorder: _edgeOnPaper,
      hoverBorder: _emerald.withValues(alpha: 0.4),
      color: _cardOnPaper,
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: _body.withValues(alpha: 0.75)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: const TextStyle(
                    color: _body,
                    fontSize: 13.5,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Proof (placeholder-flagged until real customer data exists) ──────────
  Widget _proof(BuildContext context) {
    final quotes = [
      (_t['q1']!, 'A', _t['n1']!, _t['g1']!),
      (_t['q2']!, 'B', _t['n2']!, _t['g2']!),
      (_t['q3']!, 'C', _t['n3']!, _t['g3']!),
    ];
    return _section(
      color: _paper,
      vPad: 80,
      child: Column(
        children: [
          Text(
            _t['proofHead']!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _ink,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 44),
          _responsiveGrid(context, [
            for (final q in quotes) _quoteCard(q.$1, q.$2, q.$3, q.$4),
          ]),
          const SizedBox(height: 24),
          // Honesty marker: no real customer data yet — keep this visible
          // until genuine quotes/metrics replace the placeholders.
          Text(
            _t['placeholderNote']!,
            textAlign: TextAlign.center,
            style: _mono(size: 12, color: const Color(0xFF8A93A5)),
          ),
        ],
      ),
    );
  }

  Widget _quoteCard(String quote, String initial, String name, String gym) {
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: _cardOnPaper,
        border: Border.all(color: _edgeOnPaper),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '“$quote”',
            style: const TextStyle(color: _ink, fontSize: 15.5, height: 1.7),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _emerald.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _emerald.withValues(alpha: 0.3),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: _emerald,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      gym,
                      style: const TextStyle(
                        color: Color(0xFF6E7787),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
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
        return Text('—', style: _mono(size: 36, weight: FontWeight.w600));
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
              style: _mono(size: 36, weight: FontWeight.w600),
            ),
          ),
          Text(
            ' ${_t['perMo']!}',
            style: const TextStyle(color: _subtleNavy, fontSize: 14),
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
          style: const TextStyle(color: _subtleNavy, fontSize: 11.5),
        ),
      );
    }

    Widget? annualNoteFor(PricingTier? tier) {
      if (!_billingAnnual || tier == null) return null;
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          _t['billingAnnualNote']!,
          style: const TextStyle(color: _subtleNavy, fontSize: 11.5),
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
        ctaLabel: _t['ctaPlan']!,
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
        ctaLabel: _t['ctaPlan']!,
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
        ctaLabel: _t['ctaPlan']!,
        highlighted: false,
      ),
      _priceCard(
        name: _t['p4name']!,
        desc: _t['p4desc']!,
        priceRow: Text(
          _t['enterprisePriceLabel']!,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
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
                    style: _mono(size: 12, color: _subtleNavy),
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
      color: _navy,
      child: Column(
        children: [
          Text(
            _t['pricingHead']!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 38,
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
              style: const TextStyle(color: _subtleNavy, fontSize: 13),
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
        color: _panel,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _edgeOnNavy),
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
            color: selected ? Colors.white : _mutedNavy,
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
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: _panel,
        border: Border.all(
          color: highlighted ? _red : _edgeOnNavy,
          width: highlighted ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: highlighted
            ? [
                BoxShadow(
                  color: _red.withValues(alpha: 0.18),
                  blurRadius: 44,
                  offset: const Offset(0, 18),
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
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(desc, style: const TextStyle(color: _mutedNavy, fontSize: 14)),
          const SizedBox(height: 18),
          priceRow,
          ?priceSubtitle,
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: highlighted
                ? _primaryCta(ctaLabel, () => context.go('/login'))
                : _outlineCta(
                    ctaLabel,
                    () => context.go('/login'),
                    onDark: true,
                  ),
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
                    style: TextStyle(
                      color: _emeraldUp,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      f,
                      style: TextStyle(
                        color: highlighted
                            ? Colors.white
                            : const Color(0xFFCBD2E0),
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
      color: _paper,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Column(
            children: [
              Text(
                _t['faqHead']!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 44),
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
        color: _cardOnPaper,
        border: Border.all(color: _edgeOnPaper),
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _faqOpen = open ? -1 : i),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      q,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 16.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    open ? '−' : '+',
                    style: const TextStyle(color: _emerald, fontSize: 24),
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
                    color: _body,
                    fontSize: 15,
                    height: 1.65,
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

  // ── Final CTA ────────────────────────────────────────────────────────────
  Widget _finalCta(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 100),
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, 1.4),
          radius: 1.3,
          colors: [Color(0xFF17223E), _navy],
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Column(
            children: [
              Text(
                _t['finalHead']!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                _t['finalSub']!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _mutedNavy,
                  fontSize: 18,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 36),
              // Single login entry — the form itself detects whether the
              // account is a member, staff, or admin and routes onward.
              _primaryCta(_t['login']!, () => context.go('/login')),
              const SizedBox(height: 20),
              Text(
                _t['finalStrip']!,
                textAlign: TextAlign.center,
                style: _mono(
                  size: 11.5,
                  color: _subtleNavy,
                  weight: FontWeight.w600,
                  spacing: _ar ? 0 : 1.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Footer ───────────────────────────────────────────────────────────────
  Widget _footer(BuildContext context) {
    final wide = _isWide(context);
    final brand = _footerBrand();
    final links = _footerLinksColumn();
    final contact = _footerContactBox();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 56, 24, 32),
      decoration: const BoxDecoration(
        color: _navyDeep,
        border: Border(top: BorderSide(color: _edgeOnNavy)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (wide)
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 4, child: brand),
                      const SizedBox(width: 32),
                      Expanded(flex: 3, child: links),
                      const SizedBox(width: 32),
                      Expanded(flex: 4, child: contact),
                    ],
                  ),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    brand,
                    const SizedBox(height: 32),
                    links,
                    const SizedBox(height: 32),
                    contact,
                  ],
                ),
              const SizedBox(height: 40),
              const Divider(color: _edgeOnNavy, height: 1),
              const SizedBox(height: 20),
              Wrap(
                spacing: 16,
                runSpacing: 12,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    '© 2026 PowerFit',
                    style: _mono(size: 12, color: _subtleNavy),
                  ),
                  _langButton(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _footerBrand() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
        const SizedBox(height: 14),
        Text(
          _t['footerTagline']!,
          style: const TextStyle(color: _mutedNavy, fontSize: 14, height: 1.6),
        ),
      ],
    );
  }

  Widget _footerLinksColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _t['footerLinksHead']!,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        _footerLink(_t['navP1']!, () => _scrollTo(_pillar1Key)),
        const SizedBox(height: 10),
        _footerLink(_t['navP2']!, () => _scrollTo(_pillar2Key)),
        const SizedBox(height: 10),
        _footerLink(_t['navPricing']!, () => _scrollTo(_pricingKey)),
        const SizedBox(height: 10),
        _footerLink(_t['navFaq']!, () => _scrollTo(_faqKey)),
        const SizedBox(height: 10),
        _footerLink(_t['login']!, () => context.go('/login')),
      ],
    );
  }

  Widget _footerContactBox() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _panel,
        border: Border.all(color: _edgeOnNavy),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _emeraldUp.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.mail_outline,
                  color: _emeraldUp,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _t['contactUsHead']!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _t['contactUsDesc']!,
            style: const TextStyle(
              color: _mutedNavy,
              fontSize: 13.5,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => launchUrl(Uri(scheme: 'mailto', path: _contactEmail)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: _navyDeep,
                border: Border.all(color: _edgeOnNavy),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(
                        _contactEmail,
                        overflow: TextOverflow.ellipsis,
                        style: _mono(size: 12.5, weight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Tooltip(
                    message: _t['copyEmail']!,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: () => _copyEmail(),
                      child: const Padding(
                        padding: EdgeInsets.all(2),
                        child: Icon(
                          Icons.copy_rounded,
                          size: 16,
                          color: _mutedNavy,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _copyEmail() {
    Clipboard.setData(const ClipboardData(text: _contactEmail));
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.showSnackBar(SnackBar(content: Text(_t['emailCopied']!)));
  }

  Widget _footerLink(String text, VoidCallback onTap) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(6),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        text,
        style: const TextStyle(color: _mutedNavy, fontSize: 14),
      ),
    ),
  );

  Widget _langButton() => OutlinedButton(
    onPressed: _toggleLang,
    style: OutlinedButton.styleFrom(
      foregroundColor: Colors.white,
      side: const BorderSide(color: _edgeOnNavy),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      minimumSize: Size.zero,
    ),
    child: Text(
      _ar ? 'EN' : 'ع',
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
    ),
  );

  /// Lays children into a 3-col grid on wide screens, 1-col on narrow.
  Widget _responsiveGrid(BuildContext context, List<Widget> children) {
    final width = MediaQuery.of(context).size.width;
    final cols = width >= 900 ? 3 : (width >= 620 ? 2 : 1);
    const gap = 20.0;
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
        color: _red.withValues(alpha: 0.4),
        blurRadius: 12,
        offset: const Offset(0, 3),
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
  final VoidCallback onNavP1, onNavP2, onNavPricing, onNavFaq, onLogin;
  final bool wide;

  const _Header({
    required this.t,
    required this.langLabel,
    required this.onToggleLang,
    required this.onNavP1,
    required this.onNavP2,
    required this.onNavPricing,
    required this.onNavFaq,
    required this.onLogin,
    required this.wide,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _navy.withValues(alpha: 0.92),
        border: const Border(bottom: BorderSide(color: _edgeOnNavy)),
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
                    _navLink(t['navP1']!, onNavP1),
                    const SizedBox(width: 22),
                    _navLink(t['navP2']!, onNavP2),
                    const SizedBox(width: 22),
                    _navLink(t['navPricing']!, onNavPricing),
                    const SizedBox(width: 22),
                    _navLink(t['navFaq']!, onNavFaq),
                    const SizedBox(width: 22),
                  ],
                  OutlinedButton(
                    onPressed: onToggleLang,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: _edgeOnNavy),
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
                        color: Colors.white.withValues(alpha: 0.28),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
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
    borderRadius: BorderRadius.circular(6),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Text(
        text,
        style: const TextStyle(
          color: _mutedNavy,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}

// ── Hero dashboard mock — the page's one bold visual ─────────────────────────
// A live-feeling owner console: revenue counting up, an expense donut drawing
// itself in, a net-profit callout, and ledger entries. Every number is mono.
class _DashboardMock extends StatefulWidget {
  final Map<String, String> t;
  final bool ar;
  const _DashboardMock({required this.t, required this.ar});

  @override
  State<_DashboardMock> createState() => _DashboardMockState();
}

class _DashboardMockState extends State<_DashboardMock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );
  bool _started = false;

  static const _revenue = 48250;
  // Expense slices — ordinal blue ramp (magnitude, one hue) + labeled neutral,
  // validated against the _panel surface with the dataviz palette checker.
  static const _slices = [
    (0.46, _blueDeep),
    (0.27, _blue),
    (0.17, _bluePale),
    (0.10, _chartNeutral),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.of(context).disableAnimations) {
      _c.value = 1;
    } else {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  static String _fmt(int v) => v.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+$)'),
        (m) => '${m[1]},',
      );

  @override
  Widget build(BuildContext context) {
    final t = widget.t;
    return Container(
      constraints: const BoxConstraints(maxWidth: 460),
      decoration: BoxDecoration(
        color: _panel,
        border: Border.all(color: _edgeOnNavy),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 60,
            offset: const Offset(0, 28),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Console header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: _edgeOnNavy)),
            ),
            child: Row(
              children: [
                Text(
                  t['mockTitle']!,
                  style: _mono(
                    size: 12,
                    color: _mutedNavy,
                    weight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: _emeraldUp,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  t['mockLive']!,
                  style: _mono(
                    size: 11,
                    color: _emeraldUp,
                    weight: FontWeight.w600,
                    spacing: widget.ar ? 0 : 1.2,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: AnimatedBuilder(
              animation: _c,
              builder: (context, _) {
                final tv = Curves.easeOutCubic.transform(_c.value);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Revenue counter
                    Text(
                      t['mockRevLabel']!,
                      style: _mono(
                        size: 10.5,
                        color: _subtleNavy,
                        weight: FontWeight.w600,
                        spacing: widget.ar ? 0 : 1.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 10,
                      children: [
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: Text(
                            '\$${_fmt((_revenue * tv).round())}',
                            style: _mono(size: 34, weight: FontWeight.w600),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: _emeraldUp.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Directionality(
                                textDirection: TextDirection.ltr,
                                child: Text(
                                  '▲ ${t['mockDeltaVal']!}',
                                  style: _mono(
                                    size: 11,
                                    color: _emeraldUp,
                                    weight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                t['mockDeltaSuffix']!,
                                style: _mono(
                                  size: 11,
                                  color: _emeraldUp,
                                  weight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Expense donut + legend
                    Text(
                      t['mockExpLabel']!,
                      style: _mono(
                        size: 10.5,
                        color: _subtleNavy,
                        weight: FontWeight.w600,
                        spacing: widget.ar ? 0 : 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        SizedBox(
                          width: 110,
                          height: 110,
                          child: CustomPaint(
                            painter: _DonutPainter(
                              progress: tv,
                              slices: _slices,
                            ),
                            child: Center(
                              child: Text(
                                '\$35.2k',
                                style: _mono(
                                  size: 13,
                                  weight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            children: [
                              _legendRow(t['legSalaries']!, '46%', _blueDeep),
                              _legendRow(t['legRent']!, '27%', _blue),
                              _legendRow(t['legEquip']!, '17%', _bluePale),
                              _legendRow(t['legOther']!, '10%', _chartNeutral),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    // Net profit callout — the gold "insight" moment
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: _gold.withValues(alpha: 0.07),
                        border: BorderDirectional(
                          start: const BorderSide(color: _gold, width: 3),
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t['mockProfitLabel']!,
                            style: _mono(
                              size: 10.5,
                              color: _subtleNavy,
                              weight: FontWeight.w600,
                              spacing: widget.ar ? 0 : 1.4,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Directionality(
                                textDirection: TextDirection.ltr,
                                child: Text(
                                  '\$${_fmt((13090 * tv).round())}',
                                  style: _mono(
                                    size: 21,
                                    color: _gold,
                                    weight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                t['mockMargin']!,
                                style: _mono(size: 11.5, color: _mutedNavy),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    // Ledger feed
                    Text(
                      t['mockLedgerLabel']!,
                      style: _mono(
                        size: 10.5,
                        color: _subtleNavy,
                        weight: FontWeight.w600,
                        spacing: widget.ar ? 0 : 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _ledgerRow('19:42', t['lr1d']!, '+\$45', up: true),
                    _ledgerRow('19:36', t['lr2d']!, '+\$8', up: true),
                    _ledgerRow('19:14', t['lr3d']!, '−\$220', up: false),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendRow(String name, String pct, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(color: _mutedNavy, fontSize: 12.5),
            ),
          ),
          Text(pct, style: _mono(size: 12, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _ledgerRow(String time, String desc, String amount,
      {required bool up}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Directionality(
            textDirection: TextDirection.ltr,
            child: Text(time, style: _mono(size: 11, color: _subtleNavy)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              desc,
              style: const TextStyle(color: _mutedNavy, fontSize: 12.5),
            ),
          ),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Text(
              amount,
              style: _mono(
                size: 12.5,
                color: up ? _emeraldUp : _mutedNavy,
                weight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Expense-breakdown donut. Slices sweep in with [progress]; a 2px-equivalent
/// angular gap separates fills, per the mark spec.
class _DonutPainter extends CustomPainter {
  final double progress;
  final List<(double, Color)> slices;
  _DonutPainter({required this.progress, required this.slices});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 10;
    const stroke = 18.0;
    const gap = 0.055; // radians ≈ 2px at this radius
    final total = 2 * math.pi - gap * slices.length;
    var start = -math.pi / 2;
    for (final (frac, color) in slices) {
      final sweep = total * frac * progress;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = color;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        sweep,
        false,
        paint,
      );
      start += total * frac + gap;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.progress != progress || old.slices != slices;
}

// ── Pillar 1 visual — the self-writing ledger ────────────────────────────────
class _LedgerPanel extends StatelessWidget {
  final Map<String, String> t;
  final bool ar;
  const _LedgerPanel({required this.t, required this.ar});

  @override
  Widget build(BuildContext context) {
    Widget row(String label, String? count, String value,
        {Color valueColor = _ink, Widget? trailing}) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(color: _body, fontSize: 14),
              ),
            ),
            if (count != null) ...[
              Directionality(
                textDirection: TextDirection.ltr,
                child: Text(
                  count,
                  style: _mono(size: 12, color: const Color(0xFF8A93A5)),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Directionality(
              textDirection: TextDirection.ltr,
              child: Text(
                value,
                style: _mono(
                  size: 14,
                  color: valueColor,
                  weight: FontWeight.w600,
                ),
              ),
            ),
            ?trailing,
          ],
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxWidth: 440),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _cardOnPaper,
        border: Border.all(color: _edgeOnPaper),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF141A2A).withValues(alpha: 0.06),
            blurRadius: 34,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t['lpTitle']!,
            style: _mono(
              size: 11,
              color: const Color(0xFF8A93A5),
              weight: FontWeight.w600,
              spacing: ar ? 0 : 1.4,
            ),
          ),
          const SizedBox(height: 12),
          row(t['lp1']!, '×34', '+\$2,180', valueColor: _emerald),
          const Divider(color: _edgeOnPaper, height: 1),
          row(t['lp2']!, '×6', '−\$640'),
          const Divider(color: _edgeOnPaper, height: 1),
          row(
            t['lp3']!,
            '×2',
            '\$310',
            valueColor: const Color(0xFFA07A18),
            trailing: Padding(
              padding: const EdgeInsetsDirectional.only(start: 10),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: _gold.withValues(alpha: 0.12),
                  border: Border.all(color: _gold.withValues(alpha: 0.4)),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  t['lpPending']!,
                  style: _mono(
                    size: 9.5,
                    color: const Color(0xFFA07A18),
                    weight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: _emerald.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    t['lpNet']!,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(
                    '+\$1,540',
                    style: _mono(
                      size: 17,
                      color: _emerald,
                      weight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.check_circle_outline,
                  size: 15, color: _emerald),
              const SizedBox(width: 6),
              Text(
                t['lpChip']!,
                style: const TextStyle(
                  color: _emerald,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Pillar 2 visual — dashboards that answer questions ───────────────────────
class _BiPanel extends StatelessWidget {
  final Map<String, String> t;
  final bool ar;
  const _BiPanel({required this.t, required this.ar});

  // Six months of revenue, in $k — matches the hero's $48.2k current month.
  static const _points = [33.5, 36.2, 34.8, 39.9, 43.1, 48.2];
  static const _branches = [
    ('bn1', '\$21.6k', 1.0, true),
    ('bn2', '\$14.9k', 0.69, false),
    ('bn3', '\$11.7k', 0.54, false),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 460),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _panel,
        border: Border.all(color: _edgeOnNavy),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 50,
            offset: const Offset(0, 22),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t['biChartTitle']!,
            style: _mono(
              size: 11,
              color: _subtleNavy,
              weight: FontWeight.w600,
              spacing: ar ? 0 : 1.4,
            ),
          ),
          const SizedBox(height: 14),
          // Chart draws itself in the first time it scrolls into view.
          _ChartReveal(
            builder: (progress) => SizedBox(
              height: 130,
              width: double.infinity,
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: CustomPaint(
                  painter: _LineChartPainter(
                    progress: progress,
                    points: _points,
                    lastLabel: '\$48.2k',
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final m in const ['02', '03', '04', '05', '06', '07'])
                  Text(m, style: _mono(size: 10, color: _subtleNavy)),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Text(
            t['biBranchTitle']!,
            style: _mono(
              size: 11,
              color: _subtleNavy,
              weight: FontWeight.w600,
              spacing: ar ? 0 : 1.4,
            ),
          ),
          const SizedBox(height: 12),
          for (final (key, value, frac, top) in _branches)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          t[key]!,
                          style: const TextStyle(
                            color: _mutedNavy,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      if (top) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _gold.withValues(alpha: 0.55),
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            t['biTop']!,
                            style: _mono(
                              size: 9,
                              color: _gold,
                              weight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text(
                          value,
                          style: _mono(size: 12.5, weight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: Container(
                      height: 6,
                      color: _navyDeep,
                      child: FractionallySizedBox(
                        alignment: AlignmentDirectional.centerStart,
                        widthFactor: frac,
                        child: Container(color: _blue),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 6),
          // Smart alert — real product behavior (revenue-decline detection).
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: _gold.withValues(alpha: 0.07),
              border: Border.all(color: _gold.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    size: 15, color: _gold),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    t['biAlert']!,
                    style: const TextStyle(
                      color: _mutedNavy,
                      fontSize: 12,
                      height: 1.4,
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

/// Revenue trend line — 2px blue stroke that trims in with [progress], a soft
/// area fill, recessive hairline grid, and a single direct label on the
/// latest point (gold ring = the "now" insight).
class _LineChartPainter extends CustomPainter {
  final double progress;
  final List<double> points;
  final String lastLabel;
  _LineChartPainter({
    required this.progress,
    required this.points,
    required this.lastLabel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final min = points.reduce(math.min) * 0.9;
    final max = points.reduce(math.max) * 1.05;
    Offset pt(int i) => Offset(
          i / (points.length - 1) * size.width,
          size.height - (points[i] - min) / (max - min) * size.height,
        );

    // Recessive grid — 3 hairlines.
    final grid = Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
      ..strokeWidth = 1;
    for (var g = 1; g <= 3; g++) {
      final y = size.height * g / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final path = Path()..moveTo(pt(0).dx, pt(0).dy);
    for (var i = 1; i < points.length; i++) {
      final p0 = pt(i - 1);
      final p1 = pt(i);
      final cx = (p0.dx + p1.dx) / 2;
      path.cubicTo(cx, p0.dy, cx, p1.dy, p1.dx, p1.dy);
    }

    // Trim the path to the reveal progress.
    final metrics = path.computeMetrics().toList();
    final drawn = Path();
    for (final m in metrics) {
      drawn.addPath(m.extractPath(0, m.length * progress), Offset.zero);
    }

    // Area fill under the drawn portion.
    if (progress > 0.01) {
      final endX = size.width * progress;
      final area = Path.from(drawn)
        ..lineTo(endX, size.height)
        ..lineTo(0, size.height)
        ..close();
      canvas.drawPath(
        area,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _blue.withValues(alpha: 0.20),
              _blue.withValues(alpha: 0.0),
            ],
          ).createShader(Offset.zero & size),
      );
    }

    canvas.drawPath(
      drawn,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..color = _blue,
    );

    // Direct label on the latest point once the line arrives.
    if (progress > 0.97) {
      final last = pt(points.length - 1);
      canvas.drawCircle(last, 4, Paint()..color = _blue);
      canvas.drawCircle(
        last,
        6.5,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = _gold,
      );
      final tp = TextPainter(
        text: TextSpan(
          text: lastLabel,
          style: const TextStyle(
            fontFamily: _monoFamily,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(last.dx - tp.width - 10, last.dy - tp.height - 6),
      );
    }
  }

  @override
  bool shouldRepaint(_LineChartPainter old) => old.progress != progress;
}

// ── Motion helpers (all respect reduced-motion) ──────────────────────────────

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
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.of(context).disableAnimations) {
      _c.value = 1;
    } else {
      _c.forward();
    }
  }

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
      if (MediaQuery.of(context).disableAnimations) {
        _c.value = 1;
      } else {
        _c.forward();
      }
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

/// Hands a 0→1 progress value to [builder] the first time the widget scrolls
/// into view — used for charts that draw themselves in.
class _ChartReveal extends StatefulWidget {
  final Widget Function(double progress) builder;
  const _ChartReveal({required this.builder});
  @override
  State<_ChartReveal> createState() => _ChartRevealState();
}

class _ChartRevealState extends State<_ChartReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
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
      if (MediaQuery.of(context).disableAnimations) {
        _c.value = 1;
      } else {
        _c.forward();
      }
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
      builder: (context, _) =>
          widget.builder(Curves.easeInOut.transform(_c.value)),
    );
  }
}

/// Card with a border that warms up on hover — the page's only per-card
/// micro-interaction.
class _HoverCard extends StatefulWidget {
  final Widget child;
  final Color baseBorder;
  final Color hoverBorder;
  final Color color;
  final EdgeInsets padding;
  const _HoverCard({
    required this.child,
    required this.baseBorder,
    required this.hoverBorder,
    required this.color,
    required this.padding,
  });

  @override
  State<_HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<_HoverCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: widget.padding,
        decoration: BoxDecoration(
          color: widget.color,
          border: Border.all(
            color: _hover ? widget.hoverBorder : widget.baseBorder,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: widget.child,
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
  'navP1': 'المحاسبة',
  'navP2': 'لوحات المتابعة',
  'navPricing': 'الأسعار',
  'navFaq': 'الأسئلة',
  'login': 'تسجيل الدخول',

  // Hero
  'heroEyebrow': 'المالية وذكاء الأعمال للنوادي الرياضية',
  'heroHead': 'اعرف بالضبط كم يُدخل ناديك — وأين تذهب أموالك.',
  'heroSub':
      'يسجّل باور فِت كل دفعة اشتراك وكل مصروف في جميع فروعك، ويحوّلها إلى لوحات متابعة حيّة — الإيرادات والمصروفات وصافي الربح أمامك لتتصرف في اليوم نفسه، لا بعد فوات الأوان.',
  'cta1': 'شاهد أرقامك خلال 5 دقائق',
  'cta2': 'استكشف لوحات المتابعة',
  'heroNote': 'ابدأ مجاناً · بدون بطاقة ائتمان',

  // Hero dashboard mock
  'mockTitle': 'لوحة المالك',
  'mockLive': 'مباشر',
  'mockRevLabel': 'الإيرادات — هذا الشهر',
  'mockDeltaVal': '+12.4%',
  'mockDeltaSuffix': 'عن الشهر الماضي',
  'mockExpLabel': 'المصروفات',
  'legSalaries': 'رواتب',
  'legRent': 'إيجار',
  'legEquip': 'معدات',
  'legOther': 'أخرى',
  'mockProfitLabel': 'صافي الربح',
  'mockMargin': 'هامش 27%',
  'mockLedgerLabel': 'دفتر الحركات — الآن',
  'lr1d': 'تجديد اشتراك',
  'lr2d': 'تذكرة يومية',
  'lr3d': 'فاتورة معدات',

  'capStrip':
      'الفواتير · المصروفات · صافي الربح · الإقفال اليومي · لوحات المتابعة · التنبيهات',

  // Problem framing
  'probHead': 'إدارة النادي بجداول إكسل تعني التخمين.',
  'probSub': 'معظم المالكين يعرفون نتيجة الشهر بعد انتهائه — حين يفوت أوان التصحيح.',
  'prob1t': 'الربح مفاجأة نهاية الشهر',
  'prob1d':
      'الإيراد في الدرج والمصروفات في ملف، ولا أحد يعرف الهامش الحقيقي حتى يُعاد بناء الجدول يدوياً.',
  'prob2t': 'المصروفات تتسرّب',
  'prob2d':
      'مشتريات صغيرة بلا موافقة، وفواتير مسجّلة مرتين، وإيصالات لا تصل إلى الملف أبداً.',
  'prob3t': 'كل فرع يروي قصة مختلفة',
  'prob3d':
      'ثلاثة فروع، ثلاثة دفاتر، ثلاث نسخ من الحقيقة — ولا طريقة لمقارنتها على شاشة واحدة.',

  // Pillar 1 — accounting
  'p1Eyebrow': '01 · المحاسبة والإدارة المالية',
  'p1Head': 'كل قرش، مسجَّل تلقائياً.',
  'p1Sub':
      'باور فِت هو دفتر الحسابات الذي يكتبه ناديك بنفسه — الداخل والخارج، لحظة حدوثه، في كل فرع.',
  'p1c1t': 'فوترة الأعضاء مدمجة',
  'p1c1d':
      'كل تجديد وتذكرة ودفعة تتحول إلى قيد محاسبي لحظة تحصيلها — دون إعادة إدخال في نهاية الشهر.',
  'p1c2t': 'تسجيل المصروفات مع الموافقات',
  'p1c2d':
      'يسجّل الموظفون الإيجار والمعدات والخدمات في ثوانٍ، ولا يدخل شيء إلى الدفاتر قبل موافقتك.',
  'p1c3t': 'صافي الربح، لا الإيراد فقط',
  'p1c3d':
      'الدخل ناقص المصروفات، شهرياً ولكل فرع — الرقم الذي تُدار به الأعمال فعلاً.',
  'p1c4t': 'الإقفال اليومي',
  'p1c4d':
      'طابق إيرادات اليوم مع الدفتر كل ليلة بضغطة واحدة — لا مرة واحدة في الشهر.',
  'p1c5t': 'تقارير يفهمها محاسبك',
  'p1c5d': 'تقارير شهرية للإيرادات والمصروفات، مصنّفة وجاهزة للتسليم.',

  // Ledger panel
  'lpTitle': 'اليوم — الإقفال اليومي',
  'lp1': 'دفعات الاشتراكات',
  'lp2': 'مصروفات — معتمدة',
  'lp3': 'مصروفات — قيد الموافقة',
  'lpPending': 'بانتظار الموافقة',
  'lpNet': 'صافي اليوم',
  'lpChip': 'مُطابَق مع الصندوق',

  // Pillar 2 — BI
  'p2Eyebrow': '02 · ذكاء الأعمال والتحليلات',
  'p2Head': 'شاهد نشاطك التجاري، لا جدول بياناتك.',
  'p2Sub':
      'كل قيد في الدفتر يغذّي لوحات متابعة حيّة — الأسئلة التي كانت تكلّفك عطلة نهاية أسبوع صارت تُجاب بنظرة.',
  'p2c1t': 'لوحة مالك حيّة',
  'p2c1d':
      'الإيرادات والدخول وصافي الربح تتحدّث مع مجريات اليوم — من هاتفك أو من مكتب الاستقبال.',
  'p2c2t': 'فرع مقابل فرع',
  'p2c2d': 'المقاييس نفسها على الشاشة نفسها. اعرف أي فرع يحمل البقية — ولماذا.',
  'p2c3t': 'الاحتفاظ ومؤشرات الموظفين',
  'p2c3d':
      'نسبة احتفاظ وإيراد لكل موظف، مرتّبة — لتبدأ نقاشات الأداء من الأرقام لا الانطباعات.',
  'p2c4t': 'تنبيهات قبل أن تخسر',
  'p2c4d':
      'انخفاض الإيراد أو موجة اشتراكات على وشك الانتهاء تصلك تلقائياً — لا تكتشفها في تقرير بعد ثلاثة أسابيع.',

  // BI panel
  'biChartTitle': 'الإيرادات — آخر 6 أشهر',
  'biBranchTitle': 'الإيرادات حسب الفرع — هذا الشهر',
  'bn1': 'وسط المدينة',
  'bn2': 'الفرع الغربي',
  'bn3': 'المارينا',
  'biTop': 'الأعلى',
  'biAlert': 'انخفاض الإيراد 4.1% في فرع المارينا — تنبيه تلقائي',

  // Supporting features
  'supHead': 'وبقية النادي يعمل هنا أيضاً.',
  'supSub':
      'الدخول والتجديدات ومناوبات الموظفين تغذّي الدفاتر تلقائياً — التشغيل والمحاسبة نظام واحد، فلا يُدخَل شيء مرتين.',
  's1t': 'دخول عبر QR',
  's1d': 'يمسح العضو الرمز عند الباب، فيتحدّث الحضور والإيراد تلقائياً.',
  's2t': 'إدارة الاشتراكات',
  's2d': 'تجديد وتجميد وإيقاف، مع تنبيهات قبل الانتهاء.',
  's3t': 'تعدد الفروع',
  's3d': 'وحدة تحكم واحدة، ودفتر ولوحة متابعة لكل فرع.',
  's4t': 'الموظفون والصلاحيات',
  's4d': 'صلاحيات حسب الدور، وكل إجراء منسوب لصاحبه.',
  's5t': 'تطبيق الأعضاء',
  's5d': 'تطبيق بهوية ناديك للاشتراكات والدفعات والدخول عبر QR.',
  's6t': 'تنبيهات ذكية',
  's6d': 'الاشتراكات المنتهية والأرقام الشاذة تُرفع إليك قبل أن تكلّفك.',

  // Proof
  'proofHead': 'ماذا يقول المالكون',
  'q1':
      'أفتح باور فِت قبل بريدي الإلكتروني. الإيرادات والدخول والمصروفات — شاشة واحدة لفروعي الثلاثة.',
  'q2': 'كان إقفال الشهر يستهلك عطلة كاملة. الآن الإقفال اليومي ينجزه أولاً بأول.',
  'q3':
      'مقارنة الفروع كشفت أن فرعاً واحداً يلتهم ربح الفرعين الآخرين. أعدنا التفاوض على الإيجار خلال شهر.',
  'n1': 'اسم تجريبي',
  'g1': 'نادي آيرون هاوس',
  'n2': 'اسم تجريبي',
  'g2': 'بيك فِتنس',
  'n3': 'اسم تجريبي',
  'g3': 'نادي تيتان',
  'placeholderNote': 'اقتباسات تجريبية — استبدلها بنتائج عملاء حقيقيين قبل الإطلاق.',

  // Pricing
  'pricingHead': 'أسعار بسيطة تنمو معك',
  'mostPopular': 'الأكثر شيوعاً',
  'perMo': '/شهرياً',
  'ctaPlan': 'ابدأ الآن',
  'contactSales': 'تواصل معنا',
  'billingMonthly': 'شهري',
  'billingAnnual': 'سنوي',
  'billingAnnualNote': 'يُحاسب سنوياً',
  'noCardRequired': 'بدون بطاقة ائتمان',
  'pricingDisclaimerUsd':
      'الأسعار تحويل تقديري — تواصل معنا لتأكيد السعر بعملتك',
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

  // FAQ
  'faqHead': 'الأسئلة الشائعة',
  'faq0q': 'من أين تأتي أرقام لوحات المتابعة؟',
  'faq0a':
      'من عملياتك نفسها. كل دخول وتجديد ومصروف يسجّله موظفوك يتحول فوراً إلى قيد في الدفتر — واللوحات تقرأ من الدفتر ذاته، فهناك نسخة واحدة من الحقيقة.',
  'faq1q': 'هل أتحكم بمن يصرف المال؟',
  'faq1a':
      'نعم. تدخل المصروفات بحالة «قيد الموافقة» ولا تُحتسب قبل اعتماد المالك أو المحاسب، وكل إجراء منسوب لدور موظف محدد.',
  'faq2q': 'كم فرعاً يمكنني إدارته؟',
  'faq2a': 'أي عدد تحتاجه — لكل فرع لوحته الخاصة مع مقارنات فورية بين الفروع.',
  'faq3q': 'هل بياناتي آمنة؟',
  'faq3a': 'نعم، البيانات مشفّرة والوصول محكوم بصلاحيات حسب دور كل موظف.',
  'faq4q': 'هل يمكنني التجربة أولاً؟',
  'faq4a': 'ابدأ مجاناً وارتقِ بالخطة متى شئت دون التزام.',

  // Final CTA
  'finalHead': 'توقف عن تخمين هوامشك.',
  'finalSub': 'سجّل الدخول وشاهد إيرادات هذا الشهر ومصروفاته وصافي ربحه — مباشرة.',
  'finalStrip': 'الإيرادات · المصروفات · صافي الربح — تحديث مباشر',

  // Footer
  'footerTagline':
      'المحرك المالي خلف ناديك — الفواتير والمصروفات وصافي الربح ولوحات متابعة حيّة لكل فرع.',
  'footerLinksHead': 'روابط سريعة',
  'contactUsHead': 'تواصل معنا',
  'contactUsDesc':
      'لديك سؤال أو تريد طلب عرض توضيحي؟ راسلنا مباشرة وسنرد عليك في أقرب وقت.',
  'copyEmail': 'نسخ البريد الإلكتروني',
  'emailCopied': 'تم نسخ البريد الإلكتروني',
};

const Map<String, String> _enText = {
  'navP1': 'Accounting',
  'navP2': 'Dashboards',
  'navPricing': 'Pricing',
  'navFaq': 'FAQ',
  'login': 'Log in',

  // Hero
  'heroEyebrow': 'GYM FINANCE & BUSINESS INTELLIGENCE',
  'heroHead': 'Know exactly what your gym makes — and where it goes.',
  'heroSub':
      'PowerFit records every membership payment and every expense across all your branches, and turns them into live dashboards — revenue, costs, and net profit you can act on the same day.',
  'cta1': 'See your numbers in 5 minutes',
  'cta2': 'Explore the dashboards',
  'heroNote': 'Free to start · No credit card required',

  // Hero dashboard mock
  'mockTitle': 'Owner console',
  'mockLive': 'LIVE',
  'mockRevLabel': 'REVENUE — THIS MONTH',
  'mockDeltaVal': '+12.4%',
  'mockDeltaSuffix': 'vs last month',
  'mockExpLabel': 'EXPENSES',
  'legSalaries': 'Salaries',
  'legRent': 'Rent',
  'legEquip': 'Equipment',
  'legOther': 'Other',
  'mockProfitLabel': 'NET PROFIT',
  'mockMargin': 'margin 27%',
  'mockLedgerLabel': 'LEDGER — JUST NOW',
  'lr1d': 'Membership renewal',
  'lr2d': 'Day pass',
  'lr3d': 'Equipment invoice',

  'capStrip': 'BILLING · EXPENSES · NET PROFIT · CLOSE-OUT · DASHBOARDS · ALERTS',

  // Problem framing
  'probHead': 'Running a gym on spreadsheets means guessing.',
  'probSub':
      "Most owners learn how the month went after it's over — when it's too late to fix anything.",
  'prob1t': 'Profit is a month-end surprise',
  'prob1d':
      'Revenue sits in the till, expenses in a drawer. Nobody knows the real margin until someone rebuilds the spreadsheet.',
  'prob2t': 'Expenses leak',
  'prob2d':
      'Small purchases nobody approved, invoices logged twice, receipts that never make it to the file.',
  'prob3t': 'Every branch tells a different story',
  'prob3d':
      'Three locations, three notebooks, three versions of the truth — and no way to compare them on one screen.',

  // Pillar 1 — accounting
  'p1Eyebrow': '01 · ACCOUNTING & FINANCIAL CONTROL',
  'p1Head': 'Every dollar, tracked automatically.',
  'p1Sub':
      'PowerFit is the ledger your gym writes by itself. Money in, money out — recorded the moment it happens, at every branch.',
  'p1c1t': 'Member billing, built in',
  'p1c1d':
      "Every renewal, day pass, and payment becomes a ledger entry the second it's taken — no re-typing at month end.",
  'p1c2t': 'Expense capture with approval',
  'p1c2d':
      'Staff log rent, equipment, and utilities in seconds. Nothing hits the books until you approve it.',
  'p1c3t': 'Net profit, not just revenue',
  'p1c3d':
      'Income minus expenses, per month and per branch — the number you actually run the business on.',
  'p1c4t': 'Daily close-out',
  'p1c4d':
      "Reconcile the day's takings against the ledger every night in one click — not once a month.",
  'p1c5t': 'Reports your accountant can use',
  'p1c5d':
      'Monthly revenue and expense reports, categorized and ready to hand over.',

  // Ledger panel
  'lpTitle': "TODAY — CLOSE-OUT",
  'lp1': 'Membership payments',
  'lp2': 'Expenses — approved',
  'lp3': 'Expenses — pending',
  'lpPending': 'AWAITING APPROVAL',
  'lpNet': 'Net today',
  'lpChip': 'Reconciled with till',

  // Pillar 2 — BI
  'p2Eyebrow': '02 · BUSINESS INTELLIGENCE',
  'p2Head': 'See your business, not just your spreadsheet.',
  'p2Sub':
      'Every ledger entry feeds live dashboards. Questions that used to cost you a weekend now take a glance.',
  'p2c1t': 'A live owner dashboard',
  'p2c1d':
      'Revenue, entries, and net profit updating as the day happens — from your phone or the front desk.',
  'p2c2t': 'Branch vs branch',
  'p2c2d':
      'Same metrics, same screen. See which location carries the others — and why.',
  'p2c3t': 'Retention & staff KPIs',
  'p2c3d':
      'Retention rate and revenue per staff member, ranked — so coaching conversations start from numbers, not impressions.',
  'p2c4t': 'Alerts before it hurts',
  'p2c4d':
      'A revenue dip or a wave of expiring subscriptions gets flagged to you automatically — not discovered in a report three weeks later.',

  // BI panel
  'biChartTitle': 'REVENUE — LAST 6 MONTHS',
  'biBranchTitle': 'REVENUE BY BRANCH — THIS MONTH',
  'bn1': 'Downtown',
  'bn2': 'Westside',
  'bn3': 'Marina',
  'biTop': 'TOP',
  'biAlert': 'Revenue down 4.1% at Marina — flagged automatically',

  // Supporting features
  'supHead': 'The rest of your gym runs here too.',
  'supSub':
      'Check-ins, renewals, and staff shifts feed the books on their own — operations and accounting are one system, so nothing is entered twice.',
  's1t': 'QR check-in',
  's1d': 'Members scan at the door; attendance and revenue update themselves.',
  's2t': 'Subscription control',
  's2d': 'Renew, freeze, stop — with alerts before expiry.',
  's3t': 'Multi-branch',
  's3d': 'One console, with a ledger and dashboard per branch.',
  's4t': 'Staff & roles',
  's4d': 'Role-based permissions; every action attributed to a person.',
  's5t': 'Member app',
  's5d': 'A branded app for plans, payments, and QR entry.',
  's6t': 'Smart alerts',
  's6d': 'Expiring plans and odd numbers flagged before they cost you.',

  // Proof
  'proofHead': 'What owners say',
  'q1':
      'I open PowerFit before my inbox. Revenue, entries, expenses — one screen for all three branches.',
  'q2':
      'Month-end used to take a weekend. Now the daily close-out does it as we go.',
  'q3':
      'The branch comparison showed one location was eating the profit of the other two. We renegotiated that rent within a month.',
  'n1': 'Placeholder name',
  'g1': 'Iron House Gym',
  'n2': 'Placeholder name',
  'g2': 'Peak Fitness',
  'n3': 'Placeholder name',
  'g3': 'Titan Club',
  'placeholderNote':
      'Placeholder quotes — replace with real customer results before launch.',

  // Pricing
  'pricingHead': 'Simple pricing that scales',
  'mostPopular': 'Most popular',
  'perMo': '/mo',
  'ctaPlan': 'Get started',
  'contactSales': 'Contact sales',
  'billingMonthly': 'Monthly',
  'billingAnnual': 'Annual',
  'billingAnnualNote': 'billed annually',
  'noCardRequired': 'No credit card required',
  'pricingDisclaimerUsd':
      'Prices are an estimated conversion — contact us to confirm pricing in your currency',
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

  // FAQ
  'faqHead': 'Frequently asked questions',
  'faq0q': 'Where do the dashboard numbers come from?',
  'faq0a':
      "From your own operations. Every check-in, renewal, and expense your staff records becomes a ledger entry instantly — the dashboards read from that same ledger, so there's one version of the truth.",
  'faq1q': 'Can I control who spends money?',
  'faq1a':
      'Yes. Expenses enter as pending and only count after an owner or accountant approves them, and every action is tied to a named staff role.',
  'faq2q': 'How many branches can I manage?',
  'faq2a':
      'As many as you need — each branch gets its own dashboard with instant cross-branch comparisons.',
  'faq3q': 'Is my data secure?',
  'faq3a':
      'Yes. Data is encrypted and access is controlled by role-based permissions per employee.',
  'faq4q': 'Can I try it first?',
  'faq4a': 'Start free and upgrade whenever you are ready, no commitment.',

  // Final CTA
  'finalHead': 'Stop guessing your margins.',
  'finalSub':
      "Log in and see this month's revenue, expenses, and net profit — live.",
  'finalStrip': 'REVENUE · EXPENSES · NET PROFIT — UPDATED LIVE',

  // Footer
  'footerTagline':
      'The financial engine behind your gym — billing, expenses, net profit, and live dashboards for every branch.',
  'footerLinksHead': 'Quick links',
  'contactUsHead': 'Contact us',
  'contactUsDesc':
      "Have a question or want a demo? Reach out directly and we'll get back to you soon.",
  'copyEmail': 'Copy email',
  'emailCopied': 'Email copied to clipboard',
};
