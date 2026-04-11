import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import '../community_tokens.dart';
import '../../services/api_service.dart';
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
  String _placeQuery = '';
  final _overlayTextController = TextEditingController();
  final _tagSearchController = TextEditingController();
  final _locationController = TextEditingController();
  final _soundNameController = TextEditingController();
  String _creativeEffect = 'none';
  String _stickerLabel = 'none';
  List<Map<String, dynamic>> _peopleCatalog = const [];
  List<Map<String, dynamic>> _peopleResults = const [];
  final List<Map<String, dynamic>> _selectedPeople = [];
  bool _loadingPeople = false;

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
    _tagSearchController.addListener(_refreshTagSearchResults);
    _loadPeopleCatalog();
  }

  @override
  void dispose() {
    _captionController.dispose();
    _overlayTextController.dispose();
    _tagSearchController.dispose();
    _locationController.dispose();
    _soundNameController.dispose();
    super.dispose();
  }

  Future<void> _loadPeopleCatalog() async {
    setState(() => _loadingPeople = true);
    try {
      final users =
          await ApiService.instance.getTripShareUsers(widget.authToken);
      if (!mounted) return;
      setState(() {
        _peopleCatalog = users;
        _loadingPeople = false;
      });
      _refreshTagSearchResults();
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingPeople = false);
    }
  }

  void _refreshTagSearchResults() {
    final q = _tagSearchController.text.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() => _peopleResults = const []);
      return;
    }
    final selectedIds = _selectedPeople
        .map((p) => p['id']?.toString() ?? '')
        .toSet();
    final matches = _peopleCatalog.where((u) {
      final id = (u['id'] ?? '').toString();
      if (selectedIds.contains(id)) return false;
      final name = (u['name'] ?? '').toString().toLowerCase();
      final email = (u['email'] ?? '').toString().toLowerCase();
      return name.contains(q) || email.contains(q);
    }).take(8).toList(growable: false);
    setState(() => _peopleResults = matches);
  }

  void _addTaggedPerson(Map<String, dynamic> person) {
    final id = (person['id'] ?? '').toString();
    if (id.isEmpty) return;
    if (_selectedPeople.any((p) => (p['id'] ?? '').toString() == id)) return;
    setState(() {
      _selectedPeople.add(person);
      _tagSearchController.clear();
      _peopleResults = const [];
    });
  }

  void _removeTaggedPerson(String id) {
    setState(() {
      _selectedPeople.removeWhere((p) => (p['id'] ?? '').toString() == id);
    });
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
    if (_selectedPlaceId == null || _selectedPlaceId!.isEmpty) {
      AppSnackBars.showError(context, 'Please link this post to a place');
      return;
    }

    setState(() => _posting = true);
    try {
      final placeId = _selectedPlaceId;
      List<({List<int> bytes, String? filename})>? imageFiles;

      if (!isVideoMode) {
        imageFiles = [
          for (var i = 0; i < _imageBytesList.length; i++)
            (
              bytes: _applyCreativeEdits(_imageBytesList[i]).toList(),
              filename: _imageFilenames[i],
            ),
        ];
      }

      final post = await FeedService.instance.createPost(
        authToken: widget.authToken,
        placeId: placeId!,
        caption: _captionController.text.trim(),
        authorName: widget.userName,
        imageFiles: imageFiles ?? (_coverBytes != null ? [(bytes: _coverBytes!.toList(), filename: _coverFilename)] : null),
        videoBytes: isVideoMode ? _videoBytes!.toList() : null,
        videoFilename: isVideoMode ? _videoFilename : null,
        taggedPeopleCsv: _selectedPeople
            .map((p) {
              final raw = ((p['name'] ?? p['email'] ?? p['id']) ?? '')
                  .toString()
                  .trim();
              return raw.replaceAll(',', ' ');
            })
            .where((s) => s.isNotEmpty)
            .join(','),
        customLocation: _locationController.text.trim(),
        soundName: _soundNameController.text.trim(),
        creativeEffect: _creativeEffect,
        stickerLabel: _stickerLabel,
        overlayText: _overlayTextController.text.trim(),
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

  Uint8List? _transformImage(
    Uint8List source,
    img.Image Function(img.Image image) op,
  ) {
    try {
      final decoded = img.decodeImage(source);
      if (decoded == null) return null;
      final out = op(decoded);
      return Uint8List.fromList(
        img.encodeJpg(out, quality: _instagramQuality),
      );
    } catch (_) {
      return null;
    }
  }

  Uint8List _applyCreativeEdits(Uint8List source) {
    final decoded = img.decodeImage(source);
    if (decoded == null) return source;
    var out = decoded;
    switch (_creativeEffect) {
      case 'bw':
        out = img.grayscale(out);
        break;
      case 'sepia':
        out = img.sepia(out);
        break;
      case 'vivid':
        for (var y = 0; y < out.height; y++) {
          for (var x = 0; x < out.width; x++) {
            final p = out.getPixel(x, y);
            final r = (p.r * 1.08).clamp(0, 255).toInt();
            final g = (p.g * 1.05).clamp(0, 255).toInt();
            final b = (p.b * 1.08).clamp(0, 255).toInt();
            out.setPixelRgba(x, y, r, g, b, p.a);
          }
        }
        break;
      case 'cool':
        for (var y = 0; y < out.height; y++) {
          for (var x = 0; x < out.width; x++) {
            final p = out.getPixel(x, y);
            final r = (p.r * 0.95).clamp(0, 255).toInt();
            final g = p.g.clamp(0, 255).toInt();
            final b = (p.b * 1.12).clamp(0, 255).toInt();
            out.setPixelRgba(x, y, r, g, b, p.a);
          }
        }
        break;
    }

    final overlay = _overlayTextController.text.trim();
    if (overlay.isNotEmpty) {
      final y = (out.height - 56).clamp(4, out.height - 24).toInt();
      img.fillRect(
        out,
        x1: 0,
        y1: y - 6,
        x2: out.width,
        y2: out.height,
        color: img.ColorRgba8(0, 0, 0, 110),
      );
      img.drawString(
        out,
        overlay,
        font: img.arial24,
        x: 14,
        y: y,
        color: img.ColorRgb8(255, 255, 255),
      );
    }

    if (_stickerLabel != 'none') {
      final stickerText = _stickerLabel == 'travel'
          ? '[TRAVEL]'
          : _stickerLabel == 'wow'
              ? '[WOW]'
              : '[FUN]';
      img.drawString(
        out,
        stickerText,
        font: img.arial24,
        x: 14,
        y: 14,
        color: img.ColorRgb8(255, 255, 255),
      );
    }
    return Uint8List.fromList(img.encodeJpg(out, quality: _instagramQuality));
  }

  ColorFilter? _previewFilter() {
    switch (_creativeEffect) {
      case 'bw':
        return const ColorFilter.matrix(<double>[
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0, 0, 0, 1, 0,
        ]);
      case 'sepia':
        return const ColorFilter.matrix(<double>[
          0.393, 0.769, 0.189, 0, 0,
          0.349, 0.686, 0.168, 0, 0,
          0.272, 0.534, 0.131, 0, 0,
          0, 0, 0, 1, 0,
        ]);
      case 'vivid':
        return const ColorFilter.matrix(<double>[
          1.1, 0, 0, 0, 0,
          0, 1.1, 0, 0, 0,
          0, 0, 1.1, 0, 0,
          0, 0, 0, 1, 0,
        ]);
      case 'cool':
        return const ColorFilter.matrix(<double>[
          0.95, 0, 0, 0, 0,
          0, 1.0, 0, 0, 0,
          0, 0, 1.12, 0, 0,
          0, 0, 0, 1, 0,
        ]);
      default:
        return null;
    }
  }

  String _stickerText() {
    switch (_stickerLabel) {
      case 'travel':
        return 'TRAVEL';
      case 'wow':
        return 'WOW';
      case 'fun':
        return 'FUN';
      default:
        return '';
    }
  }

  Future<void> _editImageAt(int index) async {
    if (index < 0 || index >= _imageBytesList.length) return;
    final pickedAction = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        child: Container(
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.rotate_right_rounded),
                title: const Text('Rotate right'),
                onTap: () => Navigator.pop(ctx, 'rotate_right'),
              ),
              ListTile(
                leading: const Icon(Icons.rotate_left_rounded),
                title: const Text('Rotate left'),
                onTap: () => Navigator.pop(ctx, 'rotate_left'),
              ),
              ListTile(
                leading: const Icon(Icons.flip_rounded),
                title: const Text('Flip horizontal'),
                onTap: () => Navigator.pop(ctx, 'flip_h'),
              ),
              ListTile(
                leading: const Icon(Icons.crop_square_rounded),
                title: const Text('Crop square'),
                onTap: () => Navigator.pop(ctx, 'crop_square'),
              ),
              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    );
    if (!mounted || pickedAction == null) return;

    final original = _imageBytesList[index];
    Uint8List? transformed;
    switch (pickedAction) {
      case 'rotate_right':
        transformed = _transformImage(
          original,
          (image) => img.copyRotate(image, angle: 90),
        );
        break;
      case 'rotate_left':
        transformed = _transformImage(
          original,
          (image) => img.copyRotate(image, angle: -90),
        );
        break;
      case 'flip_h':
        transformed = _transformImage(
          original,
          (image) => img.flipHorizontal(image),
        );
        break;
      case 'crop_square':
        transformed = _transformImage(original, (image) {
          final side = image.width < image.height ? image.width : image.height;
          final x = (image.width - side) ~/ 2;
          final y = (image.height - side) ~/ 2;
          return img.copyCrop(image, x: x, y: y, width: side, height: side);
        });
        break;
    }
    if (transformed == null) {
      if (mounted) AppSnackBars.showError(context, 'Could not edit image');
      return;
    }
    setState(() => _imageBytesList[index] = transformed!);
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
            // Required place link for all posts/reels.
            if (widget.ownedPlaces.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(
                    Icons.place_rounded,
                    size: 20,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Link post to place (required)',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textSecondary,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                onChanged: (v) => setState(() => _placeQuery = v.trim().toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Search place',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppTheme.borderColor),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String?>(
                initialValue: _selectedPlaceId,
                isExpanded: true,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppTheme.borderColor),
                  ),
                ),
                items: [
                  ...widget.ownedPlaces
                      .where((p) => _placeQuery.isEmpty ||
                          p.name.toLowerCase().contains(_placeQuery))
                      .map((p) => DropdownMenuItem<String?>(
                            value: p.id,
                            child: Text(p.name),
                          )),
                ],
                onChanged: (v) => setState(() => _selectedPlaceId = v),
              ),
              const SizedBox(height: 20),
            ] else ...[
              const Text(
                'No places available to link. Contact admin.',
                style: TextStyle(color: AppTheme.errorColor, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 14),
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
            Container(
              padding: const EdgeInsets.all(12),
              decoration: CommunityTokens.surfaceSectionDecoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Creative tools',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _overlayTextController,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Text on image',
                      hintText: 'Add a short overlay text',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _creativeEffect,
                          decoration: const InputDecoration(labelText: 'Effect'),
                          items: const [
                            DropdownMenuItem(value: 'none', child: Text('None')),
                            DropdownMenuItem(value: 'bw', child: Text('B&W')),
                            DropdownMenuItem(value: 'sepia', child: Text('Sepia')),
                            DropdownMenuItem(value: 'vivid', child: Text('Vivid')),
                            DropdownMenuItem(value: 'cool', child: Text('Cool')),
                          ],
                          onChanged: (v) =>
                              setState(() => _creativeEffect = v ?? 'none'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _stickerLabel,
                          decoration: const InputDecoration(labelText: 'Sticker'),
                          items: const [
                            DropdownMenuItem(value: 'none', child: Text('None')),
                            DropdownMenuItem(value: 'travel', child: Text('Travel')),
                            DropdownMenuItem(value: 'wow', child: Text('Wow')),
                            DropdownMenuItem(value: 'fun', child: Text('Fun')),
                          ],
                          onChanged: (v) =>
                              setState(() => _stickerLabel = v ?? 'none'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (_selectedPeople.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _selectedPeople.map((p) {
                        final id = (p['id'] ?? '').toString();
                        final name = (p['name'] ?? p['email'] ?? 'User').toString();
                        return Chip(
                          label: Text('@$name'),
                          onDeleted: () => _removeTaggedPerson(id),
                        );
                      }).toList(),
                    ),
                  if (_selectedPeople.isNotEmpty) const SizedBox(height: 8),
                  TextField(
                    controller: _tagSearchController,
                    decoration: InputDecoration(
                      labelText: 'Tag people',
                      hintText: 'Search people by name',
                      prefixIcon: const Icon(Icons.alternate_email_rounded),
                      suffixIcon: _loadingPeople
                          ? const Padding(
                              padding: EdgeInsets.all(10),
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : null,
                    ),
                  ),
                  if (_peopleResults.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 180),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: AppTheme.borderColor),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _peopleResults.length,
                        itemBuilder: (context, i) {
                          final u = _peopleResults[i];
                          final name = (u['name'] ?? 'User').toString();
                          final email = (u['email'] ?? '').toString();
                          return ListTile(
                            dense: true,
                            leading: CircleAvatar(
                              radius: 14,
                              backgroundColor:
                                  AppTheme.primaryColor.withValues(alpha: 0.15),
                              child: Text(
                                name.isNotEmpty ? name[0].toUpperCase() : '?',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ),
                            title: Text(name),
                            subtitle: email.isEmpty ? null : Text(email),
                            onTap: () => _addTaggedPerson(u),
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  TextField(
                    controller: _locationController,
                    decoration: const InputDecoration(
                      labelText: 'Location label',
                      hintText: 'Old City, Tripoli',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                  ),
                  if (_isReel) ...[
                    const SizedBox(height: 10),
                    TextField(
                      controller: _soundNameController,
                      decoration: const InputDecoration(
                        labelText: 'Sound',
                        hintText: 'Add reel sound title',
                        prefixIcon: Icon(Icons.music_note_rounded),
                      ),
                    ),
                  ],
                ],
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
                                        child: InkWell(
                                          onTap: () => _editImageAt(i),
                                          child: Stack(
                                            fit: StackFit.expand,
                                            children: [
                                              ColorFiltered(
                                                colorFilter: _previewFilter() ??
                                                    const ColorFilter.mode(
                                                        Colors.transparent,
                                                        BlendMode.srcOver),
                                                child: Image.memory(
                                                  _imageBytesList[i],
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                              if (_stickerText().isNotEmpty)
                                                Positioned(
                                                  top: 10,
                                                  left: 10,
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: Colors.black
                                                          .withValues(
                                                              alpha: 0.45),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              999),
                                                    ),
                                                    child: Text(
                                                      _stickerText(),
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        fontSize: 11,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              if (_overlayTextController.text
                                                  .trim()
                                                  .isNotEmpty)
                                                Positioned(
                                                  left: 0,
                                                  right: 0,
                                                  bottom: 0,
                                                  child: Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 10,
                                                        vertical: 7),
                                                    color: Colors.black
                                                        .withValues(
                                                            alpha: 0.4),
                                                    child: Text(
                                                      _overlayTextController
                                                          .text
                                                          .trim(),
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                      maxLines: 2,
                                                      overflow: TextOverflow
                                                          .ellipsis,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
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
