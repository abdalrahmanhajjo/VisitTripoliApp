import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../community_tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../services/feed_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/snackbar_utils.dart';
import '../feed_image_utils.dart';

class CreatePostSheet extends StatefulWidget {
  final List<OwnedPlace> ownedPlaces;
  final bool isAdmin;
  /// True when user earned feed access via 15+ check-ins (posts are moderated).
  final bool isDiscoverableContributor;
  final String authToken;
  final String? userName;

  const CreatePostSheet({super.key, 
    required this.ownedPlaces,
    required this.isAdmin,
    this.isDiscoverableContributor = false,
    required this.authToken,
    this.userName,
  });

  @override
  State<CreatePostSheet> createState() => CreatePostSheetState();
}

class CreatePostSheetState extends State<CreatePostSheet> {
  final _captionController = TextEditingController();
  final _imagePicker = ImagePicker();
  String? _selectedPlaceId;
  final List<Uint8List> _imageBytesList = [];
  final List<String> _imageFilenames = [];
  bool _isReel = false;
  Uint8List? _videoBytes;
  String? _videoFilename;
  Uint8List? _coverBytes;
  String? _coverFilename;
  bool _posting = false;

  // Instagram-like "Advanced" controls.
  bool _hideLikes = false;
  bool _commentsDisabled = false;
  bool get _suggestCoverImage => _isReel && _videoBytes != null;

  static const int _maxImages = 10;
  // Instagram-like: 1080px max on longest side, 85% JPEG quality.
  static const int _instagramMaxSize = 1080;
  static const int _instagramQuality = 85;
  static const int _maxVideoSizeBytes = 100 * 1024 * 1024; // Align with backend generous limit

  @override
  void initState() {
    super.initState();
    if (widget.ownedPlaces.isNotEmpty) {
      _selectedPlaceId = widget.ownedPlaces.first.id;
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      if (_isReel) return;
      final picked = await _imagePicker.pickMultiImage(
        maxWidth: _instagramMaxSize.toDouble(),
        maxHeight: _instagramMaxSize.toDouble(),
        imageQuality: _instagramQuality,
      );
      if (picked.isEmpty || !mounted) return;
      final toAdd = picked.take(_maxImages - _imageBytesList.length).toList();
      for (final x in toAdd) {
        final raw = await x.readAsBytes();
        if (raw.isEmpty) continue;
        final name = x.name;
        // Instagram-like quality on all platforms (picker params are ignored on web).
        final processed = resizeAndCompressForPost(
          Uint8List.fromList(raw),
          maxSize: _instagramMaxSize,
          quality: _instagramQuality,
        );
        final bytes = processed ?? Uint8List.fromList(raw);
        if (!mounted) return;
        setState(() {
          _imageBytesList.add(bytes);
          _imageFilenames.add(name.isNotEmpty ? name : 'image.jpg');
        });
      }
    } catch (e) {
      if (mounted) AppSnackBars.showError(context, e.toString());
    }
  }

  void _removeImageAt(int index) {
    setState(() {
      _imageBytesList.removeAt(index);
      _imageFilenames.removeAt(index);
    });
  }

  Future<void> _pickVideo() async {
    try {
      if (!_isReel) return;
      final picked = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
      );
      if (picked == null || !mounted) return;

      final bytes = await picked.readAsBytes();
      if (bytes.isEmpty) return;
      if (bytes.length > _maxVideoSizeBytes) {
        if (mounted) {
          AppSnackBars.showError(
            context,
            'Video too large. Max ${_maxVideoSizeBytes ~/ (1024 * 1024)}MB',
          );
        }
        return;
      }

      // Ensure we pass a filename with an MP4/WebM extension to the backend.
      // Some platforms provide non-standard names (e.g. "blob"), and the backend
      // validates by MIME/extension.
      final rawName = (picked.name).trim();
      final lower = rawName.toLowerCase();
      final hasAllowedExt = lower.endsWith('.mp4') || lower.endsWith('.webm');
      final filename = hasAllowedExt ? rawName : (lower.contains('.') ? rawName : 'reel.mp4');

      setState(() {
        _videoBytes = bytes;
        _videoFilename = filename;
      });
    } catch (e) {
      if (mounted) AppSnackBars.showError(context, e.toString());
    }
  }

  void _removeVideo() {
    setState(() {
      _videoBytes = null;
      _videoFilename = null;
      _coverBytes = null;
      _coverFilename = null;
    });
  }

  Future<void> _pickCoverImage() async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,
        maxHeight: 1920,
      );
      if (picked == null || !mounted) return;
      final bytes = await picked.readAsBytes();
      setState(() {
        _coverBytes = bytes;
        _coverFilename = picked.name;
      });
    } catch (e) {
      if (mounted) AppSnackBars.showError(context, e.toString());
    }
  }

  void _removeCover() {
    setState(() {
      _coverBytes = null;
      _coverFilename = null;
    });
  }

  Future<void> _submit() async {
    if (_selectedPlaceId == null && !widget.isAdmin) {
      AppSnackBars.showError(context, AppLocalizations.of(context)!.selectPlaceToPost);
      return;
    }
    if (!widget.isAdmin && _selectedPlaceId == null) return;

    final isVideoMode = _isReel;
    if (isVideoMode) {
      if (_videoBytes == null || _videoBytes!.isEmpty) {
        AppSnackBars.showError(context, 'Add a video for reels');
        return;
      }
    } else {
      if (_imageBytesList.isEmpty) {
        AppSnackBars.showError(context, 'Add at least one photo');
        return;
      }
    }
    if (_captionController.text.trim().isEmpty) {
      AppSnackBars.showError(context, AppLocalizations.of(context)!.postCaptionRequired);
      return;
    }

    setState(() => _posting = true);
    try {
      final placeId = _selectedPlaceId ?? (widget.ownedPlaces.isNotEmpty ? widget.ownedPlaces.first.id : null);
      List<({List<int> bytes, String? filename})>? imageFiles;

      if (!isVideoMode) {
        imageFiles = [
          for (var i = 0; i < _imageBytesList.length; i++)
            (
              bytes: _imageBytesList[i].toList(),
              filename: _imageFilenames[i],
            ),
        ];
      }

      final post = await FeedService.instance.createPost(
        authToken: widget.authToken,
        placeId: placeId,
        caption: _captionController.text.trim(),
        authorName: widget.userName,
        imageFiles: imageFiles ?? (_coverBytes != null ? [(bytes: _coverBytes!.toList(), filename: _coverFilename)] : null),
        videoBytes: isVideoMode ? _videoBytes!.toList() : null,
        videoFilename: isVideoMode ? _videoFilename : null,
      );

      // Apply advanced options after creation (Instagram-like).
      FeedPost finalPost = post;
      if (_hideLikes != false || _commentsDisabled != false) {
        finalPost = await FeedService.instance.updatePostOptions(
          authToken: widget.authToken,
          postId: post.id,
          hideLikes: _hideLikes,
          commentsDisabled: _commentsDisabled,
        );
      }

      if (mounted) Navigator.pop(context, finalPost);
    } catch (e) {
      if (mounted) {
        setState(() => _posting = false);
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
          l10n.createPost,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: (_posting ||
                      (_isReel ? (_videoBytes == null || _videoBytes!.isEmpty) : _imageBytesList.isEmpty))
                  ? null
                  : _submit,
              child: _posting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      l10n.post,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
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
            // Place selector for business owners; all places for discoverable contributors (15+ check-ins).
            if (!widget.isAdmin) ...[
              Row(
                children: [
                  Icon(
                    widget.isDiscoverableContributor
                        ? Icons.place_rounded
                        : Icons.store_rounded,
                    size: 20,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    widget.isDiscoverableContributor ? 'Place' : 'Business',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textSecondary,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (widget.ownedPlaces.isEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: CommunityTokens.surfaceSectionDecoration,
                  child: Text(
                    'No business available for this account',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ] else if (widget.ownedPlaces.length == 1) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: CommunityTokens.surfaceSectionDecoration,
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, size: 20, color: AppTheme.primaryColor),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.ownedPlaces.first.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                DropdownButtonFormField<String>(
                  initialValue: _selectedPlaceId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppTheme.borderColor),
                    ),
                  ),
                  items: widget.ownedPlaces
                      .map((p) => DropdownMenuItem(
                            value: p.id,
                            child: Text(p.name),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _selectedPlaceId = v);
                  },
                ),
              ],
              const SizedBox(height: 20),
            ],
            // Instagram-like: choose between Post (images) and Reel (video).
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 16),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        setState(() {
                          _isReel = false;
                          _videoBytes = null;
                          _videoFilename = null;
                          _coverBytes = null;
                          _coverFilename = null;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: !_isReel ? AppTheme.primaryColor.withValues(alpha: 0.1) : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: !_isReel ? AppTheme.primaryColor : AppTheme.borderColor,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.image_rounded,
                                size: 18,
                                color: !_isReel ? AppTheme.primaryColor : AppTheme.textSecondary),
                            const SizedBox(width: 10),
                            Text(
                              'Post',
                              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: !_isReel ? AppTheme.primaryColor : AppTheme.textSecondary,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        setState(() {
                          _isReel = true;
                          _imageBytesList.clear();
                          _imageFilenames.clear();
                          _videoBytes = null;
                          _videoFilename = null;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: _isReel ? AppTheme.primaryColor.withValues(alpha: 0.1) : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _isReel ? AppTheme.primaryColor : AppTheme.borderColor,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.videocam_rounded,
                                size: 18,
                                color: _isReel ? AppTheme.primaryColor : AppTheme.textSecondary),
                            const SizedBox(width: 10),
                            Text(
                              'Reel',
                              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: _isReel ? AppTheme.primaryColor : AppTheme.textSecondary,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              l10n.whatsNewCaption,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _captionController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: l10n.whatsOnYourMind,
                helperText: l10n.postCaptionHelper,
                helperMaxLines: 2,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppTheme.borderColor),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 14),
            Theme(
              data: Theme.of(context).copyWith(
                dividerColor: Colors.transparent,
              ),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                collapsedIconColor: AppTheme.textSecondary,
                iconColor: AppTheme.textSecondary,
                title: Row(
                  children: [
                    const Icon(Icons.tune_rounded, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Advanced settings',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textSecondary,
                          ),
                    ),
                  ],
                ),
                childrenPadding: EdgeInsets.zero,
                children: [
                  SwitchListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                    title: Text(
                      'Hide likes',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary,
                          ),
                    ),
                    value: _hideLikes,
                    onChanged: (v) => setState(() => _hideLikes = v),
                  ),
                  SwitchListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                    title: Text(
                      'Turn off comments',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary,
                          ),
                    ),
                    value: _commentsDisabled,
                    onChanged: (v) => setState(() => _commentsDisabled = v),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              _isReel ? 'Add reel video' : l10n.addMedia,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 220,
              child: _isReel
                  ? (_videoBytes == null || _videoBytes!.isEmpty
                      ? GestureDetector(
                          onTap: _pickVideo,
                          child: Container(
                            width: double.infinity,
                            decoration: CommunityTokens.surfaceSectionDecoration.copyWith(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.videocam_rounded,
                                    size: 44,
                                    color: AppTheme.primaryColor.withValues(alpha: 0.8),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Add a video for Reels',
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : Stack(
                          children: [
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppTheme.borderColor, width: 1.5),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.play_circle_filled_rounded,
                                    color: AppTheme.primaryColor,
                                    size: 58,
                                  ),
                                  const SizedBox(height: 12),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Text(
                                      _videoFilename ?? 'Reel video selected',
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Positioned(
                              top: 10,
                              right: 10,
                              child: Material(
                                color: Colors.black54,
                                shape: const CircleBorder(),
                                child: InkWell(
                                  onTap: _removeVideo,
                                  customBorder: const CircleBorder(),
                                  child: const Padding(
                                    padding: EdgeInsets.all(6),
                                    child: Icon(Icons.close_rounded, color: Colors.white, size: 20),
                                  ),
                                ),
                              ),
                            ),
                            if (_suggestCoverImage && _coverBytes == null)
                              Positioned(
                                bottom: 10,
                                right: 10,
                                child: Material(
                                  color: AppTheme.primaryColor,
                                  shape: const CircleBorder(),
                                  child: InkWell(
                                    onTap: _pickCoverImage,
                                    customBorder: const CircleBorder(),
                                    child: const Padding(
                                      padding: EdgeInsets.all(6),
                                      child: Icon(Icons.image_rounded, color: Colors.white, size: 20),
                                    ),
                                  ),
                                ),
                              ),
                            if (_coverBytes != null)
                              Positioned(
                                bottom: 10,
                                right: 10,
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.memory(
                                        _coverBytes!,
                                        width: 60,
                                        height: 80,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Positioned(
                                      top: 2,
                                      right: 2,
                                      child: GestureDetector(
                                        onTap: _removeCover,
                                        child: Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                          child: const Icon(Icons.close_rounded, color: Colors.white, size: 14),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ))
                  : (_imageBytesList.isEmpty
                      ? GestureDetector(
                          onTap: _pickImages,
                          child: Container(
                            width: double.infinity,
                            decoration: CommunityTokens.surfaceSectionDecoration.copyWith(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.add_photo_alternate_rounded,
                                    size: 44,
                                    color: AppTheme.primaryColor.withValues(alpha: 0.8),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Add one or more photos (up to $_maxImages)',
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            for (var i = 0; i < _imageBytesList.length; i++)
                              Padding(
                                padding: EdgeInsets.only(
                                    right: i < _imageBytesList.length - 1 ? 12 : 0),
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: SizedBox(
                                        width: 220,
                                        height: 220,
                                        child: Image.memory(
                                          _imageBytesList[i],
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: Material(
                                        color: Colors.black54,
                                        shape: const CircleBorder(),
                                        child: InkWell(
                                          onTap: () => _removeImageAt(i),
                                          customBorder: const CircleBorder(),
                                          child: const Padding(
                                            padding: EdgeInsets.all(6),
                                            child: Icon(
                                              Icons.close_rounded,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (_imageBytesList.length < _maxImages)
                              GestureDetector(
                                onTap: _pickImages,
                                child: Container(
                                  width: 120,
                                  decoration: BoxDecoration(
                                    color: AppTheme.surfaceVariant,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: AppTheme.borderColor),
                                  ),
                                  child: const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.add_rounded,
                                        size: 36,
                                        color: AppTheme.textTertiary,
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Add',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: AppTheme.textTertiary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        )),
            ),
          ],
        ),
      ),
    );
  }
}
