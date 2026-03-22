import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/map_launcher.dart';

/// Result of route origin selection: coordinates + travel mode + display name.
typedef RouteOriginResult = ({
  double lat,
  double lng,
  String travelMode,
  String originName,
  /// When true, the map uses a fresh GPS fix for routing and live navigation (heading/position).
  bool fromMyLocation,
  /// When true, user will tap the map to choose a start point (coordinates here are ignored).
  bool chooseStartOnMap,
});

/// Bottom sheet to pick origin and travel mode for in-app directions.
/// Defaults to **current GPS location**; optional **tap on map** for a custom start.
class RouteOriginPicker extends StatefulWidget {
  final (double lat, double lng)? myLocationCoords;
  final VoidCallback onClose;
  final String? destinationName;

  const RouteOriginPicker({
    super.key,
    this.myLocationCoords,
    required this.onClose,
    this.destinationName,
  });

  @override
  State<RouteOriginPicker> createState() => _RouteOriginPickerState();
}

class _RouteOriginPickerState extends State<RouteOriginPicker> {
  String _travelMode = MapLauncher.driving;

  void _pop(
    double lat,
    double lng,
    String originName, {
    required bool fromMyLocation,
    required bool chooseStartOnMap,
  }) {
    Navigator.pop<RouteOriginResult>(
      context,
      (
        lat: lat,
        lng: lng,
        travelMode: _travelMode,
        originName: originName,
        fromMyLocation: fromMyLocation,
        chooseStartOnMap: chooseStartOnMap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Get directions',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                      ),
                      if (widget.destinationName != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'To ${widget.destinationName!}',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        'Starts from your live location. Optional: pick any start point on the map.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textTertiary,
                              fontSize: 13,
                            ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: widget.onClose,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey.shade100,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Travel by',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _TravelModeChip(
                    icon: Icons.directions_car_rounded,
                    label: 'Drive',
                    selected: _travelMode == MapLauncher.driving,
                    onTap: () =>
                        setState(() => _travelMode = MapLauncher.driving),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _TravelModeChip(
                    icon: Icons.directions_walk_rounded,
                    label: 'Walk',
                    selected: _travelMode == MapLauncher.walking,
                    onTap: () =>
                        setState(() => _travelMode = MapLauncher.walking),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Starting from',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
            ),
            const SizedBox(height: 12),
            _OriginTile(
              icon: Icons.my_location_rounded,
              iconBg: AppTheme.primaryColor.withValues(alpha: 0.12),
              iconColor: AppTheme.primaryColor,
              title: 'My current location',
              subtitle: widget.myLocationCoords != null
                  ? 'Uses live GPS & direction when you start navigation'
                  : 'We’ll request your location when you continue',
              onTap: () {
                final c = widget.myLocationCoords;
                _pop(
                  c?.$1 ?? 0,
                  c?.$2 ?? 0,
                  'My Location',
                  fromMyLocation: true,
                  chooseStartOnMap: false,
                );
              },
            ),
            const SizedBox(height: 8),
            _OriginTile(
              icon: Icons.touch_app_rounded,
              iconBg: Colors.orange.shade50,
              iconColor: Colors.deepOrange,
              title: 'Choose point on map',
              subtitle: 'Tap anywhere on the map to set your start',
              onTap: () => _pop(
                0,
                0,
                'Map pick',
                fromMyLocation: false,
                chooseStartOnMap: true,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 20, color: AppTheme.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Routes no longer start from saved landmarks by default — only from you or a point you choose.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                            height: 1.35,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TravelModeChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TravelModeChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppTheme.primaryColor.withValues(alpha: 0.12)
          : Colors.grey.shade100,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color:
                    selected ? AppTheme.primaryColor : AppTheme.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color:
                      selected ? AppTheme.primaryColor : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OriginTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _OriginTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.grey.shade50,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(icon, color: iconColor, size: 22),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.textTertiary,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
