import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/place.dart';
import 'app_image.dart';
import '../providers/activity_log_provider.dart';
import '../providers/places_provider.dart';
import '../theme/app_theme.dart';
import '../utils/feedback_utils.dart';

class PlaceCard extends StatelessWidget {
  final Place place;
  final VoidCallback onTap;

  const PlaceCard({
    super.key,
    required this.place,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Selector<PlacesProvider, bool>(
      selector: (_, p) => p.isPlaceSaved(place.id),
      builder: (context, isSaved, _) {
        final placesProvider = Provider.of<PlacesProvider>(context, listen: false);
        return GestureDetector(
      onTap: onTap,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  place.images.isNotEmpty
                      ? AppImage(
                          src: place.images.first,
                          fit: BoxFit.cover,
                          cacheWidth: 400,
                          cacheHeight: 300,
                          placeholder: (_, __) => Container(
                            color: AppTheme.surfaceVariant,
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (_, __, e) => Container(
                            color: AppTheme.surfaceVariant,
                            child: const Icon(Icons.image_not_supported,
                                color: AppTheme.textTertiary),
                          ),
                        )
                      : Container(
                          color: AppTheme.surfaceVariant,
                          child: const Icon(Icons.image_outlined,
                              size: 48, color: AppTheme.textTertiary),
                        ),
                  // Save button
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      icon: Icon(
                        isSaved ? Icons.favorite : Icons.favorite_border,
                        color: isSaved ? Colors.red : Colors.white,
                      ),
                      onPressed: () async {
                        AppFeedback.tap();
                        try {
                          await placesProvider.toggleSavePlace(place);
                          if (context.mounted) {
                            final saved = placesProvider.isPlaceSaved(place.id);
                            if (saved) {
                              Provider.of<ActivityLogProvider>(context, listen: false).placeSaved(place.name);
                            } else {
                              Provider.of<ActivityLogProvider>(context, listen: false).placeUnsaved(place.name);
                            }
                            AppFeedback.success(context, saved ? 'Saved to favourites' : 'Removed from saved');
                          }
                        } catch (_) {
                          if (context.mounted) {
                            AppFeedback.error(context, 'Couldn\'t save place');
                          }
                        }
                      },
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.95),
                        padding: const EdgeInsets.all(8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 14, color: AppTheme.textSecondary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            place.location,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppTheme.textSecondary,
                                      fontSize: 12,
                                    ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (place.rating != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              size: 16, color: AppTheme.accentColor),
                          const SizedBox(width: 4),
                          Text(
                            place.rating!.toStringAsFixed(1),
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(
                                  fontSize: 13,
                                  color: AppTheme.textPrimary,
                                ),
                          ),
                        ],
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
      },
    );
  }
}
