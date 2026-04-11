import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../cache/app_cache_manager.dart';
import '../../l10n/app_localizations.dart';
import '../../services/feed_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/snackbar_utils.dart';
import '../community_tokens.dart';

class EditPostSheet extends StatefulWidget {
  final FeedPost post;
  final String authToken;
  final List<OwnedPlace> placeOptions;

  const EditPostSheet({
    super.key,
    required this.post,
    required this.authToken,
    required this.placeOptions,
  });

  @override
  State<EditPostSheet> createState() => EditPostSheetState();
}

class EditPostSheetState extends State<EditPostSheet> {
  late TextEditingController _captionController;
  bool _removeImage = false;
  bool _saving = false;
  String? _selectedPlaceId;

  @override
  void initState() {
    super.initState();
    _captionController = TextEditingController(text: widget.post.caption ?? '');
    _selectedPlaceId = widget.post.authorPlaceId;
    if ((_selectedPlaceId == null || _selectedPlaceId!.isEmpty) &&
        widget.placeOptions.isNotEmpty) {
      _selectedPlaceId = widget.placeOptions.first.id;
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_selectedPlaceId == null || _selectedPlaceId!.isEmpty) {
      AppSnackBars.showError(context, 'Please link this post to a place');
      return;
    }
    setState(() => _saving = true);
    try {
      final updated = await FeedService.instance.updatePost(
        authToken: widget.authToken,
        postId: widget.post.id,
        placeId: _selectedPlaceId!,
        caption: _captionController.text.trim(),
        removeImage: _removeImage,
      );
      if (mounted) Navigator.pop(context, updated);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        AppSnackBars.showError(context, e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: CommunityTokens.pageBackground,
      appBar: AppBar(
        title: Text(
          l10n.edit,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, letterSpacing: -0.3),
        ),
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.2),
                    )
                  : Text(
                      l10n.saveChanges,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Linked place',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textSecondary,
                  ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _selectedPlaceId,
              isExpanded: true,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppTheme.borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      BorderSide(color: AppTheme.borderColor.withValues(alpha: 0.9)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(color: AppTheme.primaryColor, width: 1.5),
                ),
              ),
              items: widget.placeOptions
                  .map((p) => DropdownMenuItem<String>(
                        value: p.id,
                        child: Text(p.name),
                      ))
                  .toList(growable: false),
              onChanged: (v) => setState(() => _selectedPlaceId = v),
            ),
            const SizedBox(height: 22),
            Text(
              l10n.whatsOnYourMind,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textSecondary,
                  ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _captionController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: l10n.whatsOnYourMind,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppTheme.borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppTheme.borderColor.withValues(alpha: 0.9)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            if (widget.post.imageUrl != null && !_removeImage) ...[
              const SizedBox(height: 22),
              Text(
                'Photo',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textSecondary,
                    ),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    CachedNetworkImage(
                      imageUrl: widget.post.imageUrl!,
                      height: 220,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      cacheManager: AppImageCacheManager.instance,
                      memCacheWidth: 600,
                      memCacheHeight: 400,
                      maxWidthDiskCache: 600,
                      maxHeightDiskCache: 400,
                      fadeInDuration: const Duration(milliseconds: 140),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Material(
                        color: Colors.black54,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => setState(() => _removeImage = true),
                          child: const Padding(
                            padding: EdgeInsets.all(8),
                            child: Icon(Icons.close_rounded, color: Colors.white, size: 22),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
