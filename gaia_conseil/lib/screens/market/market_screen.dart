import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../data/mock_data.dart';

class MarketScreen extends StatelessWidget {
  const MarketScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final price = mockCacaoPrice;
    final fmt = DateFormat('dd/MM/yyyy HH:mm');
    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      body: Column(
        children: [
          _AppBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PriceSection(price: price, fmt: fmt),
                  const SizedBox(height: 20),
                  Text(
                    'Actualités Agricoles',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...mockNews.map((n) => _NewsCard(article: n)),
                  const SizedBox(height: 24),
                ],
              ),
            ),
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
    return Container(
      color: AppTheme.primaryGreen,
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
          // Price cards row
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
          // Explanatory box
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
          // Stats row
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
                const Icon(Icons.trending_up,
                    color: AppTheme.accentGold, size: 16),
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

// ─── News Card ────────────────────────────────────────────────────────────────

class _NewsCard extends StatelessWidget {
  const _NewsCard({required this.article});
  final NewsArticle article;

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd MMM yyyy', 'fr_FR');
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Placeholder image
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              bottomLeft: Radius.circular(16),
            ),
            child: Container(
              width: 90,
              height: 90,
              color: AppTheme.primaryGreen.withValues(alpha: 0.12),
              child: const Icon(
                Icons.agriculture,
                color: AppTheme.primaryGreen,
                size: 36,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.title,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[850],
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${article.source}  ·  ${article.region}  ·  ${dateFmt.format(article.date)}',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: Colors.grey[500],
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
}
