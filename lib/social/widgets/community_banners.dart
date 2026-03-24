import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../models/place.dart';
import '../../providers/places_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_image.dart';

class CommunityDealsBanner extends StatelessWidget {
  const CommunityDealsBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/deals'),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withValues(alpha: 0.15),
                  AppTheme.primaryColor.withValues(alpha: 0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.25)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 18,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.local_offer_rounded, size: 28, color: AppTheme.primaryColor),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Deals & Offers',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppTheme.textPrimary),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Coupons, restaurant offers & more',
                        style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppTheme.primaryColor, size: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ignore: unused_element
class CommunityPlaceStoriesBar extends StatelessWidget {
  const CommunityPlaceStoriesBar({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final placesProvider = context.watch<PlacesProvider>();
    final places = placesProvider.places;

    final title = l10n.popularPicks;

    final sorted =
        places.isEmpty ? const <Place>[] : (List<Place>.from(places)..sort((a, b) {
              final ar = a.rating ?? 0;
              final br = b.rating ?? 0;
              return br.compareTo(ar);
            }));
    final picks = sorted.take(6).toList();
    final storyCount = picks.isNotEmpty ? picks.length : 6;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Text(
              'Handpicked top spots based on your activity.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                    height: 1.4,
                  ),
            ),
          ),
          GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: storyCount,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemBuilder: (ctx, idx) {
              final place = picks.isNotEmpty ? picks[idx] : null;
              if (place == null) return const MosaicTileSkeleton();

              final image = place.images.isNotEmpty ? place.images.first : null;
              final rating = place.rating;
              final initial = place.name.isNotEmpty ? place.name[0].toUpperCase() : '?';

              return GestureDetector(
                onTap: () => context.push('/place/${place.id}/posts'),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceVariant,
                      border: Border.all(color: AppTheme.borderColor, width: 0.8),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (image != null)
                          AppImage(
                            src: image,
                            fit: BoxFit.cover,
                            cacheWidth: 420,
                            cacheHeight: 320,
                            placeholder: (_, __) => Container(
                              color: AppTheme.surfaceVariant,
                            ),
                            errorWidget: (_, __, ___) => Container(
                              color: AppTheme.surfaceVariant,
                              child: Center(
                                child: Text(
                                  initial,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 22,
                                  ),
                                ),
                              ),
                            ),
                          )
                        else
                          Container(
                            color: AppTheme.surfaceVariant,
                            child: Center(
                              child: Text(
                                initial,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 22,
                                ),
                              ),
                            ),
                          ),
                        Positioned(
                          left: 12,
                          right: 12,
                          bottom: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.black.withValues(alpha: 0.55),
                                  Colors.black.withValues(alpha: 0.18),
                                ],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  place.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    height: 1.2,
                                  ),
                                ),
                                if (rating != null)
                                  Row(
                                    children: [
                                      const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                                      const SizedBox(width: 6),
                                      Text(
                                        rating.toStringAsFixed(1),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class MosaicTileSkeleton extends StatelessWidget {
  const MosaicTileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        color: AppTheme.surfaceVariant,
      ),
    );
  }
}
