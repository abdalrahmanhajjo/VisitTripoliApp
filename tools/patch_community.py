from pathlib import Path

root = Path(__file__).resolve().parent.parent

p = root / "lib/community/feed_image_utils.dart"
t = p.read_text(encoding="utf-8")
t = t.replace('import "dart:typed_data"', "import 'dart:typed_data'")
t = t.replace('import "package:image/image.dart"', "import 'package:image/image.dart'")
p.write_text(t, encoding="utf-8")

b = root / "lib/community/widgets/community_banners.dart"
body = b.read_text(encoding="utf-8")
body = body.replace("class _DealsBanner", "class CommunityDealsBanner")
body = body.replace("class _PlaceStoriesBar", "class CommunityPlaceStoriesBar")
body = body.replace("const _PlaceStoriesBar()", "const CommunityPlaceStoriesBar()")
body = body.replace("return const _MosaicTileSkeleton()", "return const MosaicTileSkeleton()")
body = body.replace("class _MosaicTileSkeleton", "class MosaicTileSkeleton")
body = body.replace("const _MosaicTileSkeleton()", "const MosaicTileSkeleton()")
header = """import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/place.dart';
import '../../providers/places_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_image.dart';

"""
b.write_text(header + body, encoding="utf-8")

h = root / "lib/community/widgets/community_feed_header.dart"
ht = h.read_text(encoding="utf-8")
ht = ht.replace("_FeedSort", "CommunityFeedSort")
ht = ht.replace("class _CommunityHeader", "class CommunityFeedHeader")
ht = ht.replace("const _CommunityHeader", "const CommunityFeedHeader")
ht = ht.replace("class _TikTokTab", "class CommunityFeedTab")
ht = ht.replace("const _TikTokTab", "const CommunityFeedTab")
ht = ht.replace("child: _TikTokTab", "child: CommunityFeedTab")
hh = """import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_theme.dart';
import '../community_feed_sort.dart';

"""
h.write_text(hh + ht, encoding="utf-8")

s = root / "lib/community/widgets/community_feed_states.dart"
st = s.read_text(encoding="utf-8")
st = st.replace("class _SavedEmptyState", "class CommunitySavedEmptyState")
st = st.replace("const _SavedEmptyState()", "const CommunitySavedEmptyState()")
st = st.replace("class _LoadingState", "class CommunityFeedLoadingState")
st = st.replace("const _LoadingState()", "const CommunityFeedLoadingState()")
st = st.replace("const _SkeletonPostCard()", "const CommunitySkeletonPostCard()")
st = st.replace("class _SkeletonPostCard", "class CommunitySkeletonPostCard")
st = st.replace("class _EmptyState", "class CommunityFeedEmptyState")
st = st.replace("const _EmptyState", "const CommunityFeedEmptyState")
st = st.replace("class _ErrorBanner", "class CommunityFeedErrorBanner")
st = st.replace("const _ErrorBanner", "const CommunityFeedErrorBanner")
sh = """import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/feed_provider.dart';
import '../../theme/app_theme.dart';

"""
s.write_text(sh + st, encoding="utf-8")

f = root / "lib/community/widgets/feed_post_card.dart"
ft = f.read_text(encoding="utf-8")
ft = ft.replace("class _FeedPostCard", "class FeedPostCard")
ft = ft.replace("const _FeedPostCard", "const FeedPostCard")
fh = """import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../services/feed_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/feed_video_autoplay_controller.dart';
import '../../widgets/reel_video.dart';

"""
f.write_text(fh + ft, encoding="utf-8")

c = root / "lib/community/widgets/comments_sheet.dart"
ct = c.read_text(encoding="utf-8")
ct = ct.replace("class _CommentsSheet", "class CommentsSheet")
ct = ct.replace("const _CommentsSheet", "const CommentsSheet")
ct = ct.replace("State<_CommentsSheet>", "State<CommentsSheet>")
ct = ct.replace(
    "class _CommentsSheetState extends State<_CommentsSheet>",
    "class CommentsSheetState extends State<CommentsSheet>",
)
ct = ct.replace("State<_CommentsSheet> createState", "State<CommentsSheet> createState")
ct = ct.replace("covariant _CommentsSheet", "covariant CommentsSheet")
ch = """import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/place.dart';
import '../../providers/auth_provider.dart';
import '../../providers/feed_provider.dart';
import '../../services/feed_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/snackbar_utils.dart';
import '../../widgets/app_image.dart';

"""
c.write_text(ch + ct, encoding="utf-8")

cr = root / "lib/community/widgets/create_post_sheet.dart"
crt = cr.read_text(encoding="utf-8")
crt = crt.replace("class _CreatePostSheet", "class CreatePostSheet")
crt = crt.replace("const _CreatePostSheet", "const CreatePostSheet")
crt = crt.replace("State<_CreatePostSheet>", "State<CreatePostSheet>")
crt = crt.replace(
    "class _CreatePostSheetState extends State<_CreatePostSheet>",
    "class CreatePostSheetState extends State<CreatePostSheet>",
)
crt = crt.replace("State<_CreatePostSheet> createState", "State<CreatePostSheet> createState")
crt = crt.replace("covariant _CreatePostSheet", "covariant CreatePostSheet")
crt = crt.replace("_resizeAndCompressForPost", "resizeAndCompressForPost")
crh = """import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/place.dart';
import '../../providers/auth_provider.dart';
import '../../providers/feed_provider.dart';
import '../../providers/places_provider.dart';
import '../../services/feed_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/snackbar_utils.dart';
import '../feed_image_utils.dart';

"""
cr.write_text(crh + crt, encoding="utf-8")

e = root / "lib/community/widgets/edit_post_sheet.dart"
et = e.read_text(encoding="utf-8")
et = et.replace("class _EditPostSheet", "class EditPostSheet")
et = et.replace("const _EditPostSheet", "const EditPostSheet")
et = et.replace("State<_EditPostSheet>", "State<EditPostSheet>")
et = et.replace(
    "class _EditPostSheetState extends State<_EditPostSheet>",
    "class EditPostSheetState extends State<EditPostSheet>",
)
et = et.replace("State<_EditPostSheet> createState", "State<EditPostSheet> createState")
et = et.replace("covariant _EditPostSheet", "covariant EditPostSheet")
eh = """import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../services/feed_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/snackbar_utils.dart';

"""
e.write_text(eh + et, encoding="utf-8")

# Slim community screen: wire imports + shared types
sc = root / "lib/screens/community_screen_new.dart"
if sc.exists():
    t = sc.read_text(encoding="utf-8")
    needle = "import '../widgets/reel_video.dart';\n"
    ins = needle + (
        "\nimport '../community/community_feed_sort.dart';\n"
        "import '../community/feed_image_utils.dart';\n"
        "import '../community/widgets/community_banners.dart';\n"
        "import '../community/widgets/community_feed_header.dart';\n"
        "import '../community/widgets/community_feed_states.dart';\n"
        "import '../community/widgets/feed_post_card.dart';\n"
        "import '../community/widgets/comments_sheet.dart';\n"
        "import '../community/widgets/create_post_sheet.dart';\n"
        "import '../community/widgets/edit_post_sheet.dart';\n"
    )
    if "community_feed_sort.dart" not in t:
        t = t.replace(needle, ins)
    t = t.replace("enum _FeedSort { newest, popular, saved }\n\n", "")
    t = t.replace("_FeedSort", "CommunityFeedSort")
    t = t.replace("_CommunityHeader", "CommunityFeedHeader")
    t = t.replace("_DealsBanner", "CommunityDealsBanner")
    t = t.replace("_LoadingState", "CommunityFeedLoadingState")
    t = t.replace("_ErrorBanner", "CommunityFeedErrorBanner")
    t = t.replace("_SavedEmptyState", "CommunitySavedEmptyState")
    t = t.replace("_EmptyState", "CommunityFeedEmptyState")
    t = t.replace("_FeedPostCard", "FeedPostCard")
    t = t.replace("_CommentsSheet", "CommentsSheet")
    t = t.replace("_CreatePostSheet", "CreatePostSheet")
    t = t.replace("_EditPostSheet", "EditPostSheet")
    t = t.replace("_videoPostIdsEqual", "videoPostIdsEqual")
    sc.write_text(t, encoding="utf-8")

print("ok")
