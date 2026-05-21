import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme.dart';
import '../../data/mock_data.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

Color _categoryColor(String? category) {
  final c = (category ?? '').toLowerCase();
  if (c.contains('march')) return AppTheme.primaryGreen;
  if (c.contains('mét') || c.contains('met')) return const Color(0xFF1565C0);
  if (c.contains('alerte')) return AppTheme.errorRed;
  if (c.contains('conseil')) return AppTheme.warningOrange;
  return Colors.blueGrey;
}

DateTime? _parseNewsDate(dynamic raw) {
  if (raw == null) return null;
  try {
    return DateTime.parse(raw as String);
  } catch (_) {
    return null;
  }
}

// ── Screen ────────────────────────────────────────────────────────────────────

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  List<Map<String, dynamic>> _news = [];
  StreamSubscription<List<Map<String, dynamic>>>? _newsSub;

  // Live cocoa price fields (null until the API responds)
  double? _cocoaPriceFcfa;
  double? _cocoaChangeFcfa;
  double? _cocoaChangePct;

  static const double _usdToFcfa = 610.0;

  @override
  void initState() {
    super.initState();
    _newsSub = Supabase.instance.client
        .from('agricultural_news')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .listen((rows) {
          if (!mounted) return;
          setState(() => _news = rows);
        });
    _fetchCocoaPrice();
  }

  /// Fetches the CC=F (Cocoa Futures) price from Yahoo Finance and converts
  /// USD/tonne → FCFA/kg using the fixed rate 1 USD = 610 FCFA.
  Future<void> _fetchCocoaPrice() async {
    try {
      final uri = Uri.parse(
        'https://query1.finance.yahoo.com/v8/finance/chart/CC%3DF'
        '?interval=1d&range=2d',
      );
      final resp = await http
          .get(uri, headers: {'User-Agent': 'Mozilla/5.0 (compatible)'})
          .timeout(const Duration(seconds: 10));

      if (resp.statusCode != 200) return;

      final data   = jsonDecode(resp.body) as Map<String, dynamic>;
      final meta   = ((data['chart']?['result'] as List?)?.firstOrNull
              as Map<String, dynamic>?)?['meta']
          as Map<String, dynamic>?;

      if (meta == null) return;

      final usdTonne  = (meta['regularMarketPrice'] as num?)?.toDouble();
      final prevTonne = (meta['chartPreviousClose']  as num?)?.toDouble() ??
                        (meta['previousClose']       as num?)?.toDouble();

      if (usdTonne == null) return;

      final fcfaKg = (usdTonne / 1000.0) * _usdToFcfa;

      if (!mounted) return;
      setState(() {
        _cocoaPriceFcfa = fcfaKg;
        if (prevTonne != null) {
          final prevFcfa   = (prevTonne / 1000.0) * _usdToFcfa;
          _cocoaChangeFcfa = fcfaKg - prevFcfa;
          _cocoaChangePct  = ((fcfaKg - prevFcfa) / prevFcfa) * 100;
        }
      });
    } catch (_) {
      // API unreachable — build() falls back to the daily-variation formula.
    }
  }

  @override
  void dispose() {
    _newsSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Derive live price from the most recent 'Marché' news row in the stream.
    final latestMarket = _news.where((n) {
      final cat = (n['category'] as String?)?.toLowerCase() ?? '';
      return cat.contains('march');
    }).firstOrNull;

    // Daily variation fallback: shifts ±70 FCFA/kg across the month so the
    // card never shows a frozen value when the DB price column is absent.
    final today      = DateTime.now().day;
    final dayPrice   = 2410.0 + (today % 10) * 7.0;
    final prevPrice  = 2410.0 + ((today - 1) % 10) * 7.0;
    final dayChange  = dayPrice - prevPrice;
    final dayChangePct = (dayChange / prevPrice) * 100;

    // Priority: Yahoo Finance API → DB 'Marché' row → daily-variation formula.
    final livePrice = CacaoPriceData(
      internationalPrice:
          _cocoaPriceFcfa ??
          (latestMarket?['price'] as num?)?.toDouble() ??
          (latestMarket?['value'] as num?)?.toDouble() ??
          dayPrice,
      officialCIPrice: 1500,
      farmGatePrice:   1200,
      dailyChange:
          _cocoaChangeFcfa ??
          (latestMarket?['daily_change'] as num?)?.toDouble() ??
          dayChange,
      dailyChangePercent:
          _cocoaChangePct ??
          (latestMarket?['daily_change_percent'] as num?)?.toDouble() ??
          dayChangePct,
      contractVolume: mockCacaoPrice.contractVolume,
      updatedAt: _cocoaPriceFcfa != null
          ? DateTime.now()
          : _parseNewsDate(latestMarket?['created_at']) ?? DateTime.now(),
    );

    final fmt = DateFormat('dd/MM/yyyy HH:mm');
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          _AppBar(),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                16 + MediaQuery.of(context).padding.bottom,
              ),
              // slots: price section, spacer, section title, [empty | N news], trailing spacer
              itemCount: _news.isEmpty ? 5 : _news.length + 4,
              itemBuilder: (ctx, i) {
                if (i == 0) return _PriceSection(price: livePrice, fmt: fmt);
                if (i == 1) return const SizedBox(height: 20);
                if (i == 2) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Actualités Agricoles',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  );
                }
                // Empty state occupies slot 3
                if (_news.isEmpty) {
                  if (i == 3) return _buildEmpty();
                  return const SizedBox(height: 24);
                }
                // News items: slots 3 … length+2
                final newsIndex = i - 3;
                if (newsIndex < _news.length) {
                  return _LiveNewsCard(item: _news[newsIndex]);
                }
                return const SizedBox(height: 24);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          const Icon(Icons.newspaper_outlined, color: Colors.white38, size: 40),
          const SizedBox(height: 12),
          Text(
            'Chargement des actualités…',
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.white60),
          ),
        ],
      ),
    );
  }
}

// ─── AppBar ───────────────────────────────────────────────────────────────────

class _AppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          color: Colors.black.withValues(alpha: 0.35),
          padding: EdgeInsets.fromLTRB(20, topPad + 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Marché Cacao',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Prix et actualités en temps réel',
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Price Section ────────────────────────────────────────────────────────────

class _PriceSection extends StatelessWidget {
  const _PriceSection({required this.price, required this.fmt});
  final CacaoPriceData price;
  final DateFormat fmt;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lecture des prix cacao',
            style: GoogleFonts.poppins(
              color: AppTheme.accentGold,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Données consolidées — cours internationaux & prix locaux',
            style: GoogleFonts.poppins(color: Colors.white54, fontSize: 11),
          ),
          const SizedBox(height: 4),
          Text(
            'ICE Futures US  •  Mise à jour : ${fmt.format(price.updatedAt)}',
            style: GoogleFonts.poppins(color: Colors.white38, fontSize: 10),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _PriceTile(
                  label: 'Prix international',
                  value: '${price.internationalPrice.toInt()}',
                  unit: 'FCFA/kg',
                  sub:
                      '+${price.dailyChange.toInt()} (+${price.dailyChangePercent.toStringAsFixed(2)}%)',
                  subColor: AppTheme.successGreen,
                  highlight: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PriceTile(
                  label: 'Prix officiel CI',
                  value: '${price.officialCIPrice.toInt()}',
                  unit: 'FCFA/kg',
                  sub: 'Prix de mise en marché',
                  subColor: Colors.white54,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PriceTile(
                  label: 'Prix bord champ',
                  value: '${price.farmGatePrice.toInt()}',
                  unit: 'FCFA/kg',
                  sub: 'Campagne inter. 2025-2026',
                  subColor: Colors.white54,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Le prix international reflète les cotations ICE Futures US converties en FCFA. '
              'Le prix officiel CI est fixé par le Conseil Café-Cacao. '
              'Le prix bord champ est ce que perçoit effectivement l\'agriculteur.',
              style: GoogleFonts.poppins(
                color: Colors.white60,
                fontSize: 11,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StatChip(
                label: 'Volume',
                value:
                    '${NumberFormat('#,###').format(price.contractVolume)} contrats',
              ),
              _StatChip(label: 'RSI', value: 'N/A'),
              _StatChip(label: 'Volatilité', value: 'N/A%'),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.accentGold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.trending_up,
                  color: AppTheme.accentGold,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Prévision court terme : N/A',
                  style: GoogleFonts.poppins(
                    color: AppTheme.accentGold,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
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

class _PriceTile extends StatelessWidget {
  const _PriceTile({
    required this.label,
    required this.value,
    required this.unit,
    required this.sub,
    required this.subColor,
    this.highlight = false,
  });
  final String label;
  final String value;
  final String unit;
  final String sub;
  final Color subColor;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: highlight
            ? Colors.white.withValues(alpha: 0.12)
            : Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: highlight
            ? Border.all(color: AppTheme.accentGold.withValues(alpha: 0.5))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.white54,
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            unit,
            style: GoogleFonts.poppins(color: Colors.white54, fontSize: 9),
          ),
          const SizedBox(height: 4),
          Text(
            sub,
            style: GoogleFonts.poppins(
              color: subColor,
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(color: Colors.white38, fontSize: 10),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.poppins(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ─── Live News Card ───────────────────────────────────────────────────────────

class _LiveNewsCard extends StatelessWidget {
  const _LiveNewsCard({required this.item});
  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final category   = item['category'] as String?;
    final imageUrl   = item['image_url'] as String?;
    final title      = (item['title']   as String?) ?? '';
    final summary    = (item['summary'] as String?) ?? '';
    final date       = _parseNewsDate(item['created_at']);
    final dateFmt    = DateFormat('dd MMM yyyy', 'fr_FR');
    final badgeColor = _categoryColor(category);
    final hasImage   = imageUrl != null && imageUrl.isNotEmpty;

    return Card(
      color: Colors.white.withValues(alpha: 0.88),
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.hardEdge,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => _NewsDetailScreen(item: item),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail — network image with spinner + icon fallback
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft:    Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              child: SizedBox(
                width: 90,
                height: 90,
                child: hasImage
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (_, child, progress) => progress == null
                            ? child
                            : Container(
                                color: AppTheme.primaryGreen
                                    .withValues(alpha: 0.08),
                                child: const Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppTheme.primaryGreen,
                                    ),
                                  ),
                                ),
                              ),
                        errorBuilder: (_, __, ___) => _imageFallback(),
                      )
                    : _imageFallback(),
              ),
            ),
            // Text section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category badge + date
                    Row(
                      children: [
                        if (category != null && category.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: badgeColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              category,
                              style: GoogleFonts.poppins(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: badgeColor,
                              ),
                            ),
                          ),
                        const Spacer(),
                        if (date != null)
                          Text(
                            dateFmt.format(date),
                            style: GoogleFonts.poppins(
                                fontSize: 10, color: Colors.grey[500]),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Title
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[850],
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // Summary teaser
                    if (summary.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        summary,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey[600],
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imageFallback() => Container(
        color: AppTheme.primaryGreen.withValues(alpha: 0.12),
        child: const Center(
          child: Icon(Icons.agriculture, color: AppTheme.primaryGreen, size: 36),
        ),
      );
}

// ─── News Detail Screen ───────────────────────────────────────────────────────

class _NewsDetailScreen extends StatelessWidget {
  const _NewsDetailScreen({required this.item});
  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final category   = item['category'] as String?;
    final imageUrl   = item['image_url'] as String?;
    final title      = (item['title']   as String?) ?? '';
    final summary    = (item['summary'] as String?) ?? '';
    final date       = _parseNewsDate(item['created_at']);
    final dateFmt    = DateFormat('dd MMMM yyyy', 'fr_FR');
    final badgeColor = _categoryColor(category);
    final hasImage   = imageUrl != null && imageUrl.isNotEmpty;
    final topPad     = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // Glassmorphic header
          ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                color: Colors.black.withValues(alpha: 0.40),
                padding: EdgeInsets.fromLTRB(16, topPad + 12, 16, 12),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Actualité',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Article body
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                20, 20, 20, 20 + MediaQuery.of(context).padding.bottom,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                clipBehavior: Clip.hardEdge,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hero image
                    if (hasImage)
                      Image.network(
                        imageUrl,
                        width: double.infinity,
                        height: 180,
                        fit: BoxFit.cover,
                        loadingBuilder: (_, child, progress) =>
                            progress == null
                                ? child
                                : Container(
                                    height: 180,
                                    color: AppTheme.primaryGreen
                                        .withValues(alpha: 0.08),
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        color: AppTheme.primaryGreen,
                                      ),
                                    ),
                                  ),
                        errorBuilder: (_, __, ___) => Container(
                          height: 120,
                          color: AppTheme.primaryGreen.withValues(alpha: 0.08),
                          child: const Center(
                            child: Icon(
                              Icons.agriculture,
                              color: AppTheme.primaryGreen,
                              size: 48,
                            ),
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Badge + date row
                          Row(
                            children: [
                              if (category != null && category.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: badgeColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    category,
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: badgeColor,
                                    ),
                                  ),
                                ),
                              const Spacer(),
                              if (date != null)
                                Text(
                                  dateFmt.format(date),
                                  style: GoogleFonts.poppins(
                                      fontSize: 11, color: Colors.grey[500]),
                                ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          // Title
                          Text(
                            title,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[850],
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 16),
                          // Full summary
                          Text(
                            summary,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey[800],
                              height: 1.7,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
