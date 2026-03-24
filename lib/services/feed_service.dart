import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../config/api_config.dart';
import 'api_service.dart';

const List<String> _imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp'];

/// Returns image MediaType from filename or default image/jpeg.
MediaType _imageContentType(String? filename) {
  final ext = (filename ?? '').toLowerCase().split('.').lastOrNull;
  switch (ext) {
    case 'png':
      return MediaType('image', 'png');
    case 'gif':
      return MediaType('image', 'gif');
    case 'webp':
      return MediaType('image', 'webp');
    case 'jpg':
    case 'jpeg':
    default:
      return MediaType('image', 'jpeg');
  }
}

/// Returns video MediaType from filename or default video/mp4.
MediaType _videoContentType(String? filename) {
  final ext = (filename ?? '').toLowerCase().split('.').lastOrNull;
  switch (ext) {
    case 'webm':
      return MediaType('video', 'webm');
    case 'mov':
      return MediaType('video', 'quicktime');
    case 'avi':
      return MediaType('video', 'x-msvideo');
    case 'mkv':
      return MediaType('video', 'x-matroska');
    case '3gp':
      return MediaType('video', '3gpp');
    case '3g2':
      return MediaType('video', '3gpp2');
    case 'mpeg':
    case 'mpg':
      return MediaType('video', 'mpeg');
    case 'ogg':
    case 'ogv':
      return MediaType('video', 'ogg');
    default:
      return MediaType('video', 'mp4');
  }
}

/// Ensures filename has a valid image extension (web picker may return "blob").
String _ensureImageFilename(String? filename) {
  final f = filename ?? 'image.jpg';
  final ext = f.toLowerCase().split('.').lastOrNull ?? '';
  if (_imageExtensions.contains(ext)) return f;
  return 'image.jpg';
}

/// Feed/Community API service. Handles posts, likes, comments, saves.
/// Secured: each user's likes/saves are stored per account on the backend.
class FeedService {
  FeedService._();
  static final FeedService _instance = FeedService._();
  static FeedService get instance => _instance;

  String get _baseUrl {
    var url = ApiConfig.effectiveBaseUrl;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      url = url.replaceFirst('localhost', '10.0.2.2');
    }
    return url;
  }

  Map<String, String> _authHeaders(String? authToken) {
    final headers = <String, String>{
      'Accept': 'application/json',
    };
    if (authToken != null && authToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $authToken';
    }
    return headers;
  }

  /// GET requests: auth + [Accept-Language] + `lang` query (matches [ApiService] / backend [getRequestLang]).
  Map<String, String> _feedGetHeaders(String? authToken) {
    final h = _authHeaders(authToken);
    final loc = ApiService.instance.currentLocale;
    if (loc != null && loc.isNotEmpty) {
      h['Accept-Language'] = loc;
    }
    return h;
  }

  Map<String, String> _queryWithLang(Map<String, String> query) {
    final loc = ApiService.instance.currentLocale;
    if (loc != null && loc.isNotEmpty) {
      return {...query, 'lang': loc};
    }
    return query;
  }

  /// GET /api/feed — Paginated feed. Optional auth for liked/saved.
  /// [sort] `recent` (default) uses cursor [before]; `trending` uses [offset].
  Future<FeedResponse> getFeed({
    String? authToken,
    String? before,
    int limit = 20,
    String sort = 'recent',
    int? offset,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/feed').replace(
      queryParameters: _queryWithLang({
        if (before != null && sort == 'recent') 'before': before,
        if (offset != null && sort == 'trending') 'offset': offset.toString(),
        'limit': limit.toString(),
        'sort': sort,
      }),
    );
    final response = await http.get(uri, headers: _feedGetHeaders(authToken));
    if (response.statusCode != 200) {
      throw FeedException(response.statusCode, _parseError(response.body));
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return FeedResponse.fromJson(json);
  }

  /// GET /api/feed/reels - Paginated feed strictly for videos. Optional auth.
  Future<FeedResponse> getReels({
    String? authToken,
    String? before,
    int limit = 20,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/feed/reels').replace(
      queryParameters: _queryWithLang({
        if (before != null) 'before': before,
        'limit': limit.toString(),
      }),
    );
    final response = await http.get(uri, headers: _feedGetHeaders(authToken));
    if (response.statusCode != 200) {
      throw FeedException(response.statusCode, _parseError(response.body));
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return FeedResponse.fromJson(json);
  }

  /// GET /api/feed/place/:placeId - Posts for a place (Instagram/TikTok profile-style).
  Future<PlaceFeedResponse> getPlacePosts({
    required String placeId,
    String? authToken,
    String? before,
    int limit = 20,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/feed/place/$placeId').replace(
      queryParameters: _queryWithLang({
        if (before != null) 'before': before,
        'limit': limit.toString(),
      }),
    );
    final response = await http.get(uri, headers: _feedGetHeaders(authToken));
    if (response.statusCode != 200) {
      throw FeedException(response.statusCode, _parseError(response.body));
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return PlaceFeedResponse.fromJson(json);
  }

  /// GET /api/feed/saved - Paginated saved feed. Auth required.
  Future<FeedResponse> getSavedFeed({
    required String authToken,
    String? before,
    int limit = 20,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/feed/saved').replace(
      queryParameters: _queryWithLang({
        if (before != null) 'before': before,
        'limit': limit.toString(),
      }),
    );
    final response = await http.get(uri, headers: _feedGetHeaders(authToken));
    if (response.statusCode != 200) {
      throw FeedException(response.statusCode, _parseError(response.body));
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return FeedResponse.fromJson(json);
  }

  /// GET /api/feed/liked - Paginated liked feed. Auth required.
  Future<FeedResponse> getLikedFeed({
    required String authToken,
    String? before,
    int limit = 20,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/feed/liked').replace(
      queryParameters: _queryWithLang({
        if (before != null) 'before': before,
        'limit': limit.toString(),
      }),
    );
    final response = await http.get(uri, headers: _feedGetHeaders(authToken));
    if (response.statusCode != 200) {
      throw FeedException(response.statusCode, _parseError(response.body));
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return FeedResponse.fromJson(json);
  }

  /// GET /api/feed/can-post - Check if user can post (business owner/admin).
  Future<CanPostResponse> canPost(String authToken) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/feed/can-post').replace(
        queryParameters: _queryWithLang({}),
      ),
      headers: _feedGetHeaders(authToken),
    );
    if (response.statusCode != 200) {
      throw FeedException(response.statusCode, _parseError(response.body));
    }
    return CanPostResponse.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }

  /// POST /api/feed - Create post (business owner/admin only). Multipart.
  /// placeId required for business owners; optional for admins.
  /// [imageFiles]: multiple images for carousel (each: bytes + optional filename).
  Future<FeedPost> createPost({
    required String authToken,
    String? placeId,
    String? caption,
    String? authorName,
    List<int>? imageBytes,
    String? imageFilename,
    String? imagePath,
    List<({List<int> bytes, String? filename})>? imageFiles,
    List<int>? videoBytes,
    String? videoFilename,
  }) async {
    final request =
        http.MultipartRequest('POST', Uri.parse('$_baseUrl/api/feed'));
    request.headers['Authorization'] = 'Bearer $authToken';
    request.headers['Accept'] = 'application/json';
    if (placeId != null && placeId.isNotEmpty) {
      request.fields['placeId'] = placeId;
    }
    if (caption != null && caption.isNotEmpty) {
      request.fields['caption'] = caption;
    }
    if (authorName != null && authorName.isNotEmpty) {
      request.fields['authorName'] = authorName;
    }

    if (imageFiles != null && imageFiles.isNotEmpty) {
      for (var i = 0; i < imageFiles.length; i++) {
        final f = imageFiles[i];
        if (f.bytes.isEmpty) {
          continue;
        }
        final fn = _ensureImageFilename(f.filename ?? 'image_$i.jpg');
        request.files.add(http.MultipartFile.fromBytes(
          'image',
          f.bytes,
          filename: fn,
          contentType: _imageContentType(fn),
        ));
      }
    } else if (imageBytes != null && imageBytes.isNotEmpty) {
      final fn = _ensureImageFilename(imageFilename);
      request.files.add(http.MultipartFile.fromBytes(
        'image',
        imageBytes,
        filename: fn,
        contentType: _imageContentType(fn),
      ));
    } else if (imagePath != null && imagePath.isNotEmpty) {
      request.files.add(await http.MultipartFile.fromPath('image', imagePath));
    }

    if (videoBytes != null && videoBytes.isNotEmpty) {
      final vn = videoFilename ?? 'video.mp4';
      request.files.add(http.MultipartFile.fromBytes(
        'video',
        videoBytes,
        filename: vn,
        contentType: _videoContentType(vn),
      ));
    }

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw FeedException(response.statusCode, _parseError(response.body));
    }
    return FeedPost.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  /// PUT /api/feed/:id - Edit post (author only).
  Future<FeedPost> updatePost({
    required String authToken,
    required String postId,
    String? caption,
    bool removeImage = false,
    List<int>? imageBytes,
    String? imageFilename,
  }) async {
    final request =
        http.MultipartRequest('PUT', Uri.parse('$_baseUrl/api/feed/$postId'));
    request.headers['Authorization'] = 'Bearer $authToken';
    request.headers['Accept'] = 'application/json';
    request.fields['caption'] = caption ?? '';
    request.fields['removeImage'] = removeImage.toString();

    if (imageBytes != null && imageBytes.isNotEmpty) {
      final fn = _ensureImageFilename(imageFilename);
      request.files.add(http.MultipartFile.fromBytes(
        'image',
        imageBytes,
        filename: fn,
        contentType: _imageContentType(fn),
      ));
    }

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode != 200) {
      throw FeedException(response.statusCode, _parseError(response.body));
    }
    return FeedPost.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  /// PATCH /api/feed/:id/options - Update post options (hideLikes, commentsDisabled). Author only.
  Future<FeedPost> updatePostOptions({
    required String authToken,
    required String postId,
    bool? hideLikes,
    bool? commentsDisabled,
  }) async {
    final body = <String, dynamic>{};
    if (hideLikes != null) {
      body['hideLikes'] = hideLikes;
    }
    if (commentsDisabled != null) {
      body['commentsDisabled'] = commentsDisabled;
    }
    if (body.isEmpty) {
      throw FeedException(400, 'Provide hideLikes and/or commentsDisabled');
    }
    final response = await http.patch(
      Uri.parse('$_baseUrl/api/feed/$postId/options'),
      headers: {..._authHeaders(authToken), 'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (response.statusCode != 200) {
      throw FeedException(response.statusCode, _parseError(response.body));
    }
    return FeedPost.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  /// DELETE /api/feed/:id — image/news: author or admin; video: admin or place owner.
  Future<void> deletePost({
    required String authToken,
    required String postId,
  }) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/api/feed/$postId'),
      headers: {..._authHeaders(authToken), 'Content-Type': 'application/json'},
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw FeedException(response.statusCode, _parseError(response.body));
    }
  }

  /// POST /api/feed/:id/like - Toggle like (auth required). Per-user.
  Future<LikeResponse> toggleLike({
    required String authToken,
    required String postId,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/feed/$postId/like'),
      headers: {..._authHeaders(authToken), 'Content-Type': 'application/json'},
      body: '{}',
    );
    if (response.statusCode != 200) {
      throw FeedException(response.statusCode, _parseError(response.body));
    }
    return LikeResponse.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }

  /// POST /api/feed/:id/save - Toggle save/bookmark (auth required). Per-user.
  Future<SaveResponse> toggleSave({
    required String authToken,
    required String postId,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/feed/$postId/save'),
      headers: {..._authHeaders(authToken), 'Content-Type': 'application/json'},
      body: '{}',
    );
    if (response.statusCode != 200) {
      throw FeedException(response.statusCode, _parseError(response.body));
    }
    return SaveResponse.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }

  /// GET /api/feed/:id/comments — Paginated (oldest first).
  Future<CommentsPage> getComments({
    required String postId,
    String? authToken,
    int limit = 40,
    int offset = 0,
    /// `desc` = newest first from API (reverse to chronological ASC in UI).
    String order = 'desc',
  }) async {
    final uri = Uri.parse('$_baseUrl/api/feed/$postId/comments').replace(
      queryParameters: _queryWithLang({
        'limit': limit.toString(),
        'offset': offset.toString(),
        'order': order,
      }),
    );
    final response = await http.get(uri, headers: _feedGetHeaders(authToken));
    if (response.statusCode != 200) {
      throw FeedException(response.statusCode, _parseError(response.body));
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final list = json['comments'] as List<dynamic>? ?? [];
    return CommentsPage(
      comments: list
          .map((e) => FeedComment.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num?)?.toInt(),
      nextOffset: (json['nextOffset'] as num?)?.toInt(),
      hasMore: json['hasMore'] as bool? ?? false,
    );
  }

  /// POST /api/feed/:id/comments - Add comment (auth required).
  Future<FeedComment> addComment({
    required String authToken,
    required String postId,
    required String body,
    String? parentCommentId,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/feed/$postId/comments'),
      headers: {..._authHeaders(authToken), 'Content-Type': 'application/json'},
      body: jsonEncode(
        <String, dynamic>{'body': body, if (parentCommentId != null) 'parentCommentId': parentCommentId},
      ),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw FeedException(response.statusCode, _parseError(response.body));
    }
    return FeedComment.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }

  /// POST /api/feed/comments/:commentId/like - Toggle like (auth required).
  Future<LikeResponse> toggleCommentLike({
    required String authToken,
    required String commentId,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/feed/comments/$commentId/like'),
      headers: {..._authHeaders(authToken), 'Content-Type': 'application/json'},
      body: jsonEncode({}),
    );
    if (response.statusCode != 200) {
      throw FeedException(response.statusCode, _parseError(response.body));
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return LikeResponse.fromJson(json);
  }

  /// PATCH /api/feed/comments/:commentId - Edit comment. Auth required.
  Future<FeedComment> editComment({
    required String authToken,
    required String commentId,
    required String body,
  }) async {
    final response = await http.patch(
      Uri.parse('$_baseUrl/api/feed/comments/$commentId'),
      headers: {..._authHeaders(authToken), 'Content-Type': 'application/json'},
      body: jsonEncode({'body': body, 'text': body}),
    );
    if (response.statusCode != 200) {
      throw FeedException(response.statusCode, _parseError(response.body));
    }
    return FeedComment.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }

  /// POST /api/feed/:id/report - Report post (auth required).
  Future<void> reportPost({
    required String authToken,
    required String postId,
    String? reason,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/feed/$postId/report'),
      headers: {..._authHeaders(authToken), 'Content-Type': 'application/json'},
      body: jsonEncode({'reason': reason ?? 'inappropriate'}),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw FeedException(response.statusCode, _parseError(response.body));
    }
  }

  /// DELETE /api/feed/comments/:commentId - Delete own comment or (post owner) any comment on your post.
  Future<void> deleteComment({
    required String authToken,
    required String commentId,
  }) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/api/feed/comments/$commentId'),
      headers: _authHeaders(authToken),
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw FeedException(response.statusCode, _parseError(response.body));
    }
  }

  static String _parseError(String body) {
    try {
      final m = jsonDecode(body) as Map<String, dynamic>?;
      final err = m?['error']?.toString();
      final detail = m?['detail']?.toString();
      if (err == null) return body;
      if (detail != null && detail.isNotEmpty) return '$err. $detail';
      return err;
    } catch (_) {
      return body;
    }
  }
}

class FeedException implements Exception {
  final int statusCode;
  final String message;
  FeedException(this.statusCode, this.message);
  @override
  String toString() => 'Feed $statusCode: $message';
}

class FeedPost {
  final String id;
  final String? authorId;
  final String? authorName;
  final String? authorPlaceId;
  final String? authorPlaceName;
  final String? authorPlaceImage;
  final String? authorRole;
  final String? caption;
  final String? imageUrl;
  /// Multiple images (carousel). First item matches [imageUrl] when set.
  final List<String> imageUrls;
  final String? videoUrl;
  final String type;
  final String createdAt;
  final int likeCount;
  final int commentCount;
  final bool likedByMe;
  final bool savedByMe;
  final bool hideLikes;
  final bool commentsDisabled;
  /// `pending` until admin approves (discoverer posts); `approved` / `rejected` otherwise.
  final String moderationStatus;

  FeedPost({
    required this.id,
    this.authorId,
    this.authorName,
    this.authorPlaceId,
    this.authorPlaceName,
    this.authorPlaceImage,
    this.authorRole,
    this.caption,
    this.imageUrl,
    this.imageUrls = const [],
    this.videoUrl,
    this.type = 'image',
    required this.createdAt,
    this.likeCount = 0,
    this.commentCount = 0,
    this.likedByMe = false,
    this.savedByMe = false,
    this.hideLikes = false,
    this.commentsDisabled = false,
    this.moderationStatus = 'approved',
  });

  /// Ordered list of image URLs to show (carousel or single).
  List<String> get displayImageUrls {
    if (imageUrls.isNotEmpty) return imageUrls;
    if (imageUrl != null && imageUrl!.isNotEmpty) return [imageUrl!];
    return [];
  }

  factory FeedPost.fromJson(Map<String, dynamic> json) {
    String? imageUrl = json['imageUrl'] as String?;
    String? videoUrl = json['videoUrl'] as String?;
    String? authorPlaceImage = json['authorPlaceImage'] as String?;
    List<String> imageUrls = [];
    final raw = json['imageUrls'];
    if (raw is List) {
      for (final e in raw) {
        final s = e?.toString();
        if (s != null && s.isNotEmpty) {
          final url = s.startsWith('http') ? s : '${ApiConfig.effectiveBaseUrl}$s';
          imageUrls.add(url);
        }
      }
    }
    if (imageUrl != null &&
        !imageUrl.startsWith('http') &&
        imageUrl.startsWith('/')) {
      imageUrl = '${ApiConfig.effectiveBaseUrl}$imageUrl';
    }
    if (imageUrls.isEmpty && imageUrl != null) imageUrls = [imageUrl];
    if (imageUrl == null && imageUrls.isNotEmpty) imageUrl = imageUrls.first;

    if (videoUrl != null &&
        !videoUrl.startsWith('http') &&
        videoUrl.startsWith('/')) {
      videoUrl = '${ApiConfig.effectiveBaseUrl}$videoUrl';
    }
    if (authorPlaceImage != null &&
        !authorPlaceImage.startsWith('http') &&
        authorPlaceImage.startsWith('/')) {
      authorPlaceImage = '${ApiConfig.effectiveBaseUrl}$authorPlaceImage';
    }
    return FeedPost(
      id: json['id']?.toString() ?? '',
      authorId: json['authorId']?.toString(),
      authorName: json['authorName'] as String?,
      authorPlaceId: json['authorPlaceId']?.toString(),
      authorPlaceName: json['authorPlaceName'] as String?,
      authorPlaceImage: authorPlaceImage,
      authorRole: json['authorRole'] as String?,
      caption: json['caption'] as String?,
      imageUrl: imageUrl,
      imageUrls: imageUrls,
      videoUrl: videoUrl,
      type: json['type'] as String? ?? 'image',
      createdAt: json['createdAt'] as String? ?? '',
      likeCount: (json['likeCount'] as num?)?.toInt() ?? 0,
      commentCount: (json['commentCount'] as num?)?.toInt() ?? 0,
      likedByMe: json['likedByMe'] as bool? ?? false,
      savedByMe: json['savedByMe'] as bool? ?? false,
      hideLikes: json['hideLikes'] as bool? ?? false,
      commentsDisabled: json['commentsDisabled'] as bool? ?? false,
      moderationStatus: json['moderationStatus'] as String? ?? 'approved',
    );
  }

  FeedPost copyWith({
    int? likeCount,
    int? commentCount,
    bool? likedByMe,
    bool? savedByMe,
    bool? hideLikes,
    bool? commentsDisabled,
    String? moderationStatus,
    String? caption,
    String? imageUrl,
    List<String>? imageUrls,
    String? videoUrl,
  }) {
    return FeedPost(
      id: id,
      authorId: authorId,
      authorName: authorName,
      authorPlaceId: authorPlaceId,
      authorPlaceName: authorPlaceName,
      authorPlaceImage: authorPlaceImage,
      authorRole: authorRole,
      caption: caption ?? this.caption,
      imageUrl: imageUrl ?? this.imageUrl,
      imageUrls: imageUrls ?? this.imageUrls,
      videoUrl: videoUrl ?? this.videoUrl,
      type: type,
      createdAt: createdAt,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      likedByMe: likedByMe ?? this.likedByMe,
      savedByMe: savedByMe ?? this.savedByMe,
      hideLikes: hideLikes ?? this.hideLikes,
      commentsDisabled: commentsDisabled ?? this.commentsDisabled,
      moderationStatus: moderationStatus ?? this.moderationStatus,
    );
  }

  bool get isPendingModeration => moderationStatus == 'pending';
}

class FeedComment {
  final String id;
  final String postId;
  final String? userId;
  final String authorName;
  /// Public handle without `@` when set.
  final String? authorUsername;
  final String? authorAvatarUrl;
  final String? authorFullName;
  final String body;
  final String createdAt;
  final String? parentCommentId;
  final String? parentAuthorName;
  final String? parentAuthorUsername;
  final int likeCount;
  final bool likedByMe;

  FeedComment({
    required this.id,
    required this.postId,
    this.userId,
    required this.authorName,
    this.authorUsername,
    this.authorAvatarUrl,
    this.authorFullName,
    required this.body,
    required this.createdAt,
    this.parentCommentId,
    this.parentAuthorName,
    this.parentAuthorUsername,
    this.likeCount = 0,
    this.likedByMe = false,
  });

  /// Full name when present; otherwise `@username` or [authorName].
  String get displayAuthorName {
    final full = authorFullName?.trim();
    if (full != null && full.isNotEmpty) return full;
    final u = authorUsername?.trim();
    if (u != null && u.isNotEmpty) return '@$u';
    return authorName;
  }

  String get displayAuthorInitial {
    final n = displayAuthorName;
    if (n.isEmpty) return '?';
    if (n.startsWith('@') && n.length > 1) {
      return n.substring(1, 2).toUpperCase();
    }
    return n[0].toUpperCase();
  }

  String get parentDisplayLabel {
    final u = parentAuthorUsername?.trim();
    if (u != null && u.isNotEmpty) return '@$u';
    return parentAuthorName ?? 'comment';
  }

  factory FeedComment.fromJson(Map<String, dynamic> json) => FeedComment(
        id: json['id']?.toString() ?? '',
        postId: json['postId']?.toString() ?? '',
        userId: json['userId']?.toString(),
        authorName: json['authorName'] as String? ?? 'User',
        authorUsername: json['authorUsername']?.toString(),
        authorAvatarUrl: json['authorAvatarUrl']?.toString(),
        authorFullName: json['authorFullName']?.toString(),
        body: json['body'] as String? ?? '',
        createdAt: json['createdAt'] as String? ?? '',
        parentCommentId: json['parentCommentId']?.toString(),
        parentAuthorName: json['parentAuthorName'] as String?,
        parentAuthorUsername: json['parentAuthorUsername']?.toString(),
        likeCount: (json['likeCount'] as num?)?.toInt() ?? 0,
        likedByMe: json['likedByMe'] as bool? ?? false,
      );
}

class FeedResponse {
  final List<FeedPost> posts;
  final String? nextCursor;
  final int? nextOffset;
  final bool hasMore;
  final String sort;

  FeedResponse({
    required this.posts,
    this.nextCursor,
    this.nextOffset,
    this.hasMore = false,
    this.sort = 'recent',
  });

  factory FeedResponse.fromJson(Map<String, dynamic> json) => FeedResponse(
        posts: (json['posts'] as List<dynamic>?)
                ?.map((e) => FeedPost.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        nextCursor: json['nextCursor']?.toString(),
        nextOffset: (json['nextOffset'] as num?)?.toInt(),
        hasMore: json['hasMore'] as bool? ?? false,
        sort: json['sort']?.toString() ?? 'recent',
      );
}

/// One page of comments from GET /api/feed/:id/comments
class CommentsPage {
  final List<FeedComment> comments;
  final int? total;
  final int? nextOffset;
  final bool hasMore;

  CommentsPage({
    required this.comments,
    this.total,
    this.nextOffset,
    this.hasMore = false,
  });
}

/// Response for place posts (includes place info for header).
class PlaceFeedResponse {
  final List<FeedPost> posts;
  final String? nextCursor;
  final bool hasMore;
  final PlaceFeedInfo? place;

  PlaceFeedResponse({
    required this.posts,
    this.nextCursor,
    this.hasMore = false,
    this.place,
  });

  factory PlaceFeedResponse.fromJson(Map<String, dynamic> json) {
    PlaceFeedInfo? place;
    final p = json['place'];
    if (p is Map<String, dynamic>) {
      place = PlaceFeedInfo(
        name: p['name'] as String? ?? 'Place',
        image: p['image'] as String?,
      );
    }
    return PlaceFeedResponse(
      posts: (json['posts'] as List<dynamic>?)
              ?.map((e) => FeedPost.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      nextCursor: json['nextCursor']?.toString(),
      hasMore: json['hasMore'] as bool? ?? false,
      place: place,
    );
  }
}

class PlaceFeedInfo {
  final String name;
  final String? image;

  PlaceFeedInfo({required this.name, this.image});
}

class CanPostResponse {
  final bool canPost;
  final bool isAdmin;
  final bool isBusinessOwner;
  /// User has 15+ distinct check-ins; posts go to admin review first.
  final bool isDiscoverableContributor;
  final bool requiresModeration;
  final List<OwnedPlace> ownedPlaces;

  CanPostResponse({
    required this.canPost,
    this.isAdmin = false,
    this.isBusinessOwner = false,
    this.isDiscoverableContributor = false,
    this.requiresModeration = false,
    this.ownedPlaces = const [],
  });

  factory CanPostResponse.fromJson(Map<String, dynamic> json) =>
      CanPostResponse(
        canPost: json['canPost'] as bool? ?? false,
        isAdmin: json['isAdmin'] as bool? ?? false,
        isBusinessOwner: json['isBusinessOwner'] as bool? ?? false,
        isDiscoverableContributor:
            json['isDiscoverableContributor'] as bool? ?? false,
        requiresModeration: json['requiresModeration'] as bool? ?? false,
        ownedPlaces: (json['ownedPlaces'] as List<dynamic>?)
                ?.map((e) => OwnedPlace.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

class OwnedPlace {
  final String id;
  final String name;

  OwnedPlace({required this.id, required this.name});

  factory OwnedPlace.fromJson(Map<String, dynamic> json) => OwnedPlace(
        id: json['id']?.toString() ?? '',
        name: json['name'] as String? ?? '',
      );
}

class LikeResponse {
  final bool liked;
  final int likeCount;

  LikeResponse({required this.liked, required this.likeCount});

  factory LikeResponse.fromJson(Map<String, dynamic> json) => LikeResponse(
        liked: json['liked'] as bool? ?? false,
        likeCount: (json['likeCount'] as num?)?.toInt() ?? 0,
      );
}

class SaveResponse {
  final bool saved;

  SaveResponse({required this.saved});

  factory SaveResponse.fromJson(Map<String, dynamic> json) =>
      SaveResponse(saved: json['saved'] as bool? ?? false);
}
