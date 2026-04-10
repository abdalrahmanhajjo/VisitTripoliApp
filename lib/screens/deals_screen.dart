import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../config/api_config.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../services/deals_service.dart';
import '../theme/app_theme.dart';
import '../utils/snackbar_utils.dart';
import '../widgets/app_bottom_nav.dart';

class DealsScreen extends StatefulWidget {
  const DealsScreen({super.key});

  @override
  State<DealsScreen> createState() => _DealsScreenState();
}

class _DealsScreenState extends State<DealsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Coupon> _coupons = [];
  List<PlaceOffer> _offers = [];
  List<OfferProposal> _proposals = [];
  bool _loading = true;
  String? _error;
  final _codeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final auth = context.read<AuthProvider>();
    final token = auth.isLoggedIn && !auth.isGuest ? auth.authToken : null;
    try {
      final couponsFuture = DealsService.instance
          .getCoupons(authToken: token)
          .catchError((_) => <Coupon>[]);
      final offersFuture =
          DealsService.instance.getOffers().catchError((_) => <PlaceOffer>[]);
      final proposalsFuture = token != null
          ? DealsService.instance
              .getMyProposals(token)
              .catchError((_) => <OfferProposal>[])
          : Future.value(<OfferProposal>[]);
      final results = await Future.wait([
        couponsFuture,
        offersFuture,
        proposalsFuture,
      ]);
      if (mounted) {
        var coupons = results[0] as List<Coupon>;
        coupons = _sortCoupons(coupons);
        setState(() {
          _coupons = coupons;
          _offers = results[1] as List<PlaceOffer>;
          _proposals = results[2] as List<OfferProposal>;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  List<Coupon> _sortCoupons(List<Coupon> list) {
    final sorted = List<Coupon>.from(list);
    sorted.sort((a, b) {
      if (a.usedByMe != b.usedByMe) return a.usedByMe ? 1 : -1;
      final aExp = a.validUntil ?? '';
      final bExp = b.validUntil ?? '';
      if (aExp != bExp) return aExp.compareTo(bExp);
      return b.discountValue.compareTo(a.discountValue);
    });
    return sorted;
  }

  Future<void> _redeemCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn || auth.isGuest) {
      context.go('/login?redirect=${Uri.encodeComponent('/deals')}');
      return;
    }
    try {
      final res = await DealsService.instance.redeemCoupon(code, auth.authToken!);
      if (mounted) {
        _codeController.clear();
        _load();
        _showRedeemSuccess(context, res);
      }
    } catch (e) {
      if (mounted) AppSnackBars.showError(context, e.toString().replaceAll('API Exception: ', ''));
    }
  }

  void _showRedeemSuccess(BuildContext context, Map<String, dynamic> res) {
    SystemSound.play(SystemSoundType.click);
    final l10n = AppLocalizations.of(context)!;
    final redemptionId = res['redemption_id']?.toString() ?? '';
    final code = res['code'] as String? ?? '';
    final coupon = res['coupon'] as Map<String, dynamic>?;
    final displayValue = coupon != null
        ? (coupon['discount_type'] == 'percent'
            ? l10n.dealsPercentOff((coupon['discount_value'] as num?)?.toInt() ?? 0)
            : l10n.dealsAmountOff('\$${coupon['discount_value']}'))
        : code;
    final qrData = 'TRIPOLI:$code:$redemptionId';
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, size: 48, color: AppTheme.primaryColor),
              ),
              const SizedBox(height: 16),
              Text(l10n.dealsRedeemedTitle, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 22, color: AppTheme.textPrimary)),
              const SizedBox(height: 4),
              Text(displayValue, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: AppTheme.primaryColor)),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.textPrimary.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 160,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: AppTheme.primaryColor),
                  dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: AppTheme.primaryColor),
                ),
              ),
              const SizedBox(height: 12),
              Text(l10n.dealsShowQrAtCheckout, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
              const SizedBox(height: 8),
              Text(code, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, letterSpacing: 2, color: AppTheme.textPrimary)),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => Navigator.pop(ctx),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(l10n.done),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          l10n.dealsAndOffers,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 22),
        ),
        elevation: 0,
        backgroundColor: AppTheme.surfaceColor,
        surfaceTintColor: Colors.transparent,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryColor,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textSecondary,
          tabs: [
            Tab(text: l10n.coupons),
            Tab(text: l10n.dealsTabRestaurantOffers),
            Tab(text: l10n.dealsTabMyProposals),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 48, color: AppTheme.textTertiary),
                          const SizedBox(height: 16),
                          Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.textSecondary)),
                          const SizedBox(height: 24),
                          FilledButton(onPressed: _load, child: Text(l10n.retry)),
                        ],
                      ),
                    ),
                  )
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _CouponsTab(
                        coupons: _coupons,
                        codeController: _codeController,
                        onRedeem: _redeemCode,
                        isLoggedIn: context.watch<AuthProvider>().isLoggedIn && !context.watch<AuthProvider>().isGuest,
                      ),
                      _OffersTab(offers: _offers),
                      _ProposalsTab(
                        proposals: _proposals,
                        isLoggedIn: context.watch<AuthProvider>().isLoggedIn && !context.watch<AuthProvider>().isGuest,
                        onRefresh: _load,
                      ),
                    ],
                  ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
    );
  }
}

class _CouponsTab extends StatelessWidget {
  final List<Coupon> coupons;
  final TextEditingController codeController;
  final VoidCallback onRedeem;
  final bool isLoggedIn;

  const _CouponsTab({
    required this.coupons,
    required this.codeController,
    required this.onRedeem,
    required this.isLoggedIn,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.dealsHavePromoCode,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: codeController,
                      decoration: InputDecoration(
                        hintText: l10n.dealsEnterCodeHint,
                        filled: true,
                        fillColor: AppTheme.surfaceColor,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      textCapitalization: TextCapitalization.characters,
                      onSubmitted: (_) => onRedeem(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: onRedeem,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(l10n.dealsRedeem),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          l10n.dealsActiveCoupons,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 12),
        if (coupons.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.textPrimary.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Column(
              children: [
                const Icon(Icons.local_offer_outlined, size: 48, color: AppTheme.textTertiary),
                const SizedBox(height: 16),
                Text(
                  l10n.dealsNoActiveCoupons,
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 15),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ...coupons.map((c) => _CouponCard(coupon: c)),
      ],
    );
  }
}

class _CouponCard extends StatelessWidget {
  final Coupon coupon;

  const _CouponCard({required this.coupon});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final target = coupon.placeName ?? coupon.tourName ?? coupon.eventName ?? l10n.dealsPlaceVarious;
    final used = coupon.usedByMe;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.textPrimary.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
        border: used ? Border.all(color: AppTheme.textTertiary.withValues(alpha: 0.4), width: 1) : null,
      ),
      child: Stack(
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: used ? AppTheme.textTertiary.withValues(alpha: 0.15) : AppTheme.primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    coupon.code.substring(0, coupon.code.length.clamp(0, 4)),
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: used ? AppTheme.textTertiary : AppTheme.primaryColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          coupon.displayValue,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: used ? AppTheme.textTertiary : null,
                            decoration: used ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        if (used) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.textTertiary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(l10n.dealsUsedLabel, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(target, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                    if (coupon.validUntil != null)
                      Text(l10n.dealsValidUntil(coupon.validUntil!.substring(0, 10)), style: const TextStyle(color: AppTheme.textTertiary, fontSize: 12)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy_outlined),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: coupon.code));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.dealsCodeCopied(coupon.code)), duration: const Duration(seconds: 2), behavior: SnackBarBehavior.floating),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OffersTab extends StatelessWidget {
  final List<PlaceOffer> offers;

  const _OffersTab({required this.offers});

  String _imageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return '${ApiConfig.effectiveBaseUrl}${path.startsWith('/') ? '' : '/'}$path';
  }

  Widget _offerChip({required IconData icon, required String label, bool primary = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: primary ? AppTheme.primaryColor.withValues(alpha: 0.12) : AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(999),
        border: primary ? Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: primary ? AppTheme.primaryColor : AppTheme.textSecondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: primary ? FontWeight.w700 : FontWeight.w500,
              color: primary ? AppTheme.primaryColor : AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _openProposeOffer(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn || auth.isGuest) {
      context.go('/login?redirect=${Uri.encodeComponent('/deals')}');
      return;
    }
    var places = <Map<String, String>>[];
    final seen = <String>{};
    for (final o in offers) {
      if (!seen.contains(o.placeId) && o.placeName != null) {
        seen.add(o.placeId);
        places.add({'id': o.placeId, 'name': o.placeName!});
      }
    }
    if (places.isEmpty) {
      try {
        places = await DealsService.instance.getPlacesForPropose();
      } catch (_) {}
    }
    if (!context.mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ProposeOfferSheet(places: places),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.read<AuthProvider>();
    final canPropose = auth.isLoggedIn && !auth.isGuest;
    if (offers.isEmpty && !canPropose) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.restaurant_outlined, size: 64, color: AppTheme.textTertiary),
            const SizedBox(height: 16),
            Text(
              l10n.dealsNoRestaurantOffers,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 15),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (canPropose)
          GestureDetector(
            onTap: () => _openProposeOffer(context),
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF2D5A4A).withValues(alpha: 0.12),
                    const Color(0xFF2D5A4A).withValues(alpha: 0.06),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF2D5A4A).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D5A4A).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.send_rounded, size: 28, color: Color(0xFF2D5A4A)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.dealsSendOfferTitle, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppTheme.textPrimary)),
                        const SizedBox(height: 4),
                        Text(l10n.dealsSendOfferSubtitle, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: Color(0xFF2D5A4A), size: 28),
                ],
              ),
            ),
          ),
        if (offers.isEmpty)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.restaurant_outlined, size: 64, color: AppTheme.textTertiary),
                const SizedBox(height: 16),
                Text(l10n.dealsNoRestaurantOffersShort, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 15), textAlign: TextAlign.center),
              ],
            ),
          )
        else
          ...List.generate(offers.length, (i) => _buildOfferCard(context, offers[i])),
      ],
    );
  }

  void _showOfferDetails(BuildContext context, PlaceOffer o) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        decoration: const BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.borderColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Hero image + discount pill
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Stack(
                    children: [
                      AspectRatio(
                        aspectRatio: 16 / 9,
                        child: o.placeImages.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: _imageUrl(o.placeImages.first),
                                fit: BoxFit.cover,
                              )
                            : Container(
                                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                child: const Center(
                                  child: Icon(Icons.restaurant, size: 60, color: AppTheme.primaryColor),
                                ),
                              ),
                      ),
                      Positioned(
                        left: 12,
                        top: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            o.displayValue,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  o.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                if (o.placeName != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.restaurant_menu_rounded, size: 16, color: AppTheme.textSecondary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          o.placeName!,
                          style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (o.discountValue != null)
                      _offerChip(
                        icon: Icons.local_offer_rounded,
                        label: o.displayValue,
                        primary: true,
                      ),
                    if (o.expiresAt != null)
                      _offerChip(
                        icon: Icons.schedule_rounded,
                        label: l10n.dealsValidUntil(o.expiresAt!.substring(0, 10)),
                      ),
                    _offerChip(
                      icon: Icons.group_rounded,
                      label: l10n.dealsInRestaurantOnly,
                    ),
                  ],
                ),
                if (o.description != null && o.description!.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(
                    l10n.dealsWhatYouGet,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    o.description!,
                    style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary, height: 1.4),
                  ),
                ],
                const SizedBox(height: 16),
                Text(
                  l10n.dealsHowToUseOffer,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.dealsHowToUseOfferSteps,
                  style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.5),
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.push('/place/${o.placeId}');
                  },
                  icon: const Icon(Icons.info_rounded, size: 20),
                  label: Text(l10n.dealsViewRestaurantDetails),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    side: const BorderSide(color: AppTheme.primaryColor),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOfferCard(BuildContext context, PlaceOffer o) {
    final l10n = AppLocalizations.of(context)!;
    final imgUrl = o.placeImages.isNotEmpty ? _imageUrl(o.placeImages.first) : null;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppTheme.textPrimary.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showOfferDetails(context, o),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: imgUrl != null && imgUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: imgUrl,
                           fit: BoxFit.cover,
                          )
                        : Container(
                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                            child: Icon(Icons.restaurant, size: 48, color: AppTheme.primaryColor.withValues(alpha: 0.6)),
                          ),
                  ),
                  Positioned(
                    left: 10,
                    top: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        o.displayValue,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            o.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: AppTheme.textPrimary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (o.placeName != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              o.placeName!,
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          if (o.expiresAt != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              l10n.dealsValidUntil(o.expiresAt!.substring(0, 10)),
                              style: const TextStyle(
                                color: AppTheme.textTertiary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right_rounded, color: AppTheme.textTertiary),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProposalsTab extends StatelessWidget {
  final List<OfferProposal> proposals;
  final bool isLoggedIn;
  final VoidCallback onRefresh;

  const _ProposalsTab({
    required this.proposals,
    required this.isLoggedIn,
    required this.onRefresh,
  });

  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      final d = DateTime.parse(iso);
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return iso.length > 10 ? iso.substring(0, 10) : iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (!isLoggedIn) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.send_rounded, size: 64, color: AppTheme.primaryColor.withValues(alpha: 0.5)),
              const SizedBox(height: 20),
              Text(
                l10n.dealsLoginToSeeProposals,
                style: const TextStyle(fontSize: 16, color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.dealsProposalsLoginSubtitle,
                style: const TextStyle(fontSize: 14, color: AppTheme.textTertiary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.go('/login?redirect=${Uri.encodeComponent('/deals')}'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(l10n.dealsLogIn),
              ),
            ],
          ),
        ),
      );
    }
    if (proposals.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox_outlined, size: 64, color: AppTheme.textTertiary.withValues(alpha: 0.6)),
              const SizedBox(height: 20),
              Text(
                l10n.dealsNoProposalsYet,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.dealsNoProposalsSubtitle,
                style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: proposals.length,
      itemBuilder: (context, i) {
        final p = proposals[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.textPrimary.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.restaurant_rounded, color: AppTheme.primaryColor, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.placeName ?? l10n.dealsRestaurantDefault,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppTheme.textPrimary),
                          ),
                          Text(
                            _formatDate(p.createdAt),
                            style: const TextStyle(fontSize: 13, color: AppTheme.textTertiary),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: p.hasResponse
                            ? AppTheme.successColor.withValues(alpha: 0.15)
                            : Colors.orange.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        p.hasResponse ? l10n.dealsProposalStatusReplied : l10n.dealsProposalStatusPending,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: p.hasResponse ? AppTheme.successColor : Colors.orange.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  p.message,
                  style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary, height: 1.4),
                ),
                if (p.hasResponse) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.reply_rounded, size: 18, color: AppTheme.primaryColor),
                            const SizedBox(width: 6),
                            Text(
                              l10n.dealsRestaurantResponse,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.primaryColor),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          p.restaurantResponse!,
                          style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => context.push('/place/${p.placeId}'),
                  icon: const Icon(Icons.directions_rounded, size: 18),
                  label: Text(l10n.dealsViewRestaurant),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    side: const BorderSide(color: AppTheme.primaryColor),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProposeOfferSheet extends StatefulWidget {
  final List<Map<String, String>> places;

  const _ProposeOfferSheet({required this.places});

  @override
  State<_ProposeOfferSheet> createState() => _ProposeOfferSheetState();
}

class _ProposeOfferSheetState extends State<_ProposeOfferSheet> {
  final _messageController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _selectedPlaceId;
  bool _sending = false;

  @override
  void dispose() {
    _messageController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final placeId = _selectedPlaceId;
    final msg = _messageController.text.trim();
    final phone = _phoneController.text.trim();
    if (placeId == null || msg.isEmpty) return;
    if (phone.isEmpty) {
      AppSnackBars.showError(context, AppLocalizations.of(context)!.dealsEnterPhoneRequired);
      return;
    }
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn || auth.isGuest) return;
    setState(() => _sending = true);
    try {
      await DealsService.instance.proposeOfferToRestaurant(auth.authToken!, placeId, msg, phone);
      if (mounted) {
        Navigator.pop(context);
        AppSnackBars.showSuccess(context, AppLocalizations.of(context)!.dealsProposalSentSuccess);
      }
    } catch (e) {
      if (mounted) AppSnackBars.showError(context, e.toString().replaceAll('API Exception: ', ''));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppTheme.borderColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.send_rounded, color: Color(0xFF2D5A4A), size: 28),
                  const SizedBox(width: 12),
                  Text(l10n.dealsSendOfferDialogTitle, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 20, color: AppTheme.textPrimary)),
                ],
              ),
              const SizedBox(height: 8),
              Text(l10n.dealsSendOfferDialogSubtitle, style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
              const SizedBox(height: 24),
              Text(l10n.dealsSelectRestaurant, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.textPrimary)),
              const SizedBox(height: 8),
              if (widget.places.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(l10n.dealsNoRestaurantsAvailable, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                )
              else
                DropdownButtonFormField<String>(
                  initialValue: _selectedPlaceId,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppTheme.surfaceVariant.withValues(alpha: 0.5),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  hint: Text(l10n.dealsChooseRestaurantHint),
                  items: widget.places.map((p) => DropdownMenuItem(value: p['id'], child: Text(p['name']!, overflow: TextOverflow.ellipsis))).toList(),
                  onChanged: (v) => setState(() => _selectedPlaceId = v),
                ),
              const SizedBox(height: 20),
              Text(l10n.dealsYourPhone, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.textPrimary)),
              const SizedBox(height: 8),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: l10n.dealsPhoneHintExample,
                  filled: true,
                  fillColor: AppTheme.surfaceVariant.withValues(alpha: 0.5),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 20),
              Text(l10n.dealsYourMessage, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.textPrimary)),
              const SizedBox(height: 8),
              TextField(
                controller: _messageController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: l10n.dealsMessageHintExample,
                  filled: true,
                  fillColor: AppTheme.surfaceVariant.withValues(alpha: 0.5),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _sending ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2D5A4A),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _sending ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(l10n.dealsSendProposal),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
