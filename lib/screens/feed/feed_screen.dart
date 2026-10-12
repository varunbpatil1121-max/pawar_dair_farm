import 'package:flutter/material.dart';

import '../../data/store.dart';
import '../../models/models.dart';
import '../../services/media.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../../widgets/media_view.dart';
import 'hygiene_screen.dart';

/// "Farm Diary": photos, videos and notes from the farm. The admin posts and
/// manages; customers watch and like.
class FeedScreen extends StatefulWidget {
  final bool admin;
  final bool showBack;
  const FeedScreen({super.key, required this.admin, this.showBack = false});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  String? _cat;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final posts = store.feed
        .where((p) => _cat == null || p.category == _cat)
        .toList();

    return Scaffold(
      floatingActionButton: widget.admin
          ? FloatingActionButton.extended(
              heroTag: null,
              onPressed: () => openComposer(context),
              icon: const Icon(Icons.add_a_photo_outlined),
              label: const Text('New post'),
            )
          : null,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            automaticallyImplyLeading: widget.showBack,
            expandedHeight: 110,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: EdgeInsetsDirectional.only(
                start: widget.showBack ? 56 : 20,
                bottom: 14,
              ),
              title: Text(
                'Farm Diary',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.admin
                        ? 'Show customers how clean and caring your farm is.'
                        : 'See exactly how your milk is produced, every day.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TrustCard(admin: widget.admin),
                  const SizedBox(height: 14),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 42,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _chip(null, 'All', '✨'),
                  for (final c in postCategories)
                    _chip(c.key, c.label, c.emoji),
                ],
              ),
            ),
          ),
          if (posts.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                icon: Icons.photo_library_outlined,
                title: 'No posts yet',
                message: widget.admin
                    ? 'Tap "New post" to share a cleaning or milking video'
                    : 'The farm will share updates here soon',
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 120),
              sliver: SliverList.separated(
                itemCount: posts.length,
                separatorBuilder: (_, _) => const SizedBox(height: 16),
                itemBuilder: (_, i) =>
                    PostCard(post: posts[i], admin: widget.admin),
              ),
            ),
        ],
      ),
    );
  }

  Widget _chip(String? key, String label, String emoji) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: ChoiceChip(
      avatar: Text(emoji),
      label: Text(label),
      selected: _cat == key,
      showCheckmark: false,
      onSelected: (_) => setState(() => _cat = key),
    ),
  );
}

class PostCard extends StatefulWidget {
  final FarmPost post;
  final bool admin;
  const PostCard({super.key, required this.post, required this.admin});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final p = widget.post;
    final cat = categoryOf(p.category);
    final me = store.currentUser!;
    final liked = p.likes.contains(me.id);
    final cs = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 6, 10),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [AppColors.greenDark, AppColors.green],
                    ),
                  ),
                  child: const Text('🐄', style: TextStyle(fontSize: 20)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        store.farmName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        timeAgo(p.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (p.pinned)
                  const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: Icon(
                      Icons.push_pin,
                      size: 18,
                      color: AppColors.amber,
                    ),
                  ),
                Pill('${cat.emoji} ${cat.label}', color: Color(cat.color)),
                if (widget.admin)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (v) async {
                      switch (v) {
                        case 'edit':
                          openComposer(context, existing: p);
                        case 'pin':
                          p.pinned = !p.pinned;
                          store.save();
                        case 'delete':
                          if (await confirm(
                            context,
                            'Delete post?',
                            'Customers will no longer see it.',
                          )) {
                            store.deletePost(p);
                          }
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(
                        value: 'pin',
                        child: Text(p.pinned ? 'Unpin' : 'Pin to top'),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
                    ],
                  )
                else
                  const SizedBox(width: 8),
              ],
            ),
          ),
          PostMedia(post: p),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Text(
              p.title,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 17,
                letterSpacing: -0.2,
              ),
            ),
          ),
          if (p.note.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GestureDetector(
                onTap: () => setState(() => _expanded = !_expanded),
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  alignment: Alignment.topCenter,
                  child: Text(
                    p.note,
                    maxLines: _expanded ? null : 3,
                    overflow: _expanded ? null : TextOverflow.ellipsis,
                    style: TextStyle(height: 1.45, color: cs.onSurfaceVariant),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 4, 12, 6),
            child: Row(
              children: [
                if (widget.admin)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.favorite,
                            color: AppColors.rose,
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              '${p.likes.length} customer${p.likes.length == 1 ? '' : 's'} liked this',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  TextButton.icon(
                    onPressed: () => store.toggleLike(p, me.id),
                    style: TextButton.styleFrom(
                      foregroundColor: liked
                          ? AppColors.rose
                          : cs.onSurfaceVariant,
                    ),
                    icon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      transitionBuilder: (c, a) =>
                          ScaleTransition(scale: a, child: c),
                      child: Icon(
                        liked ? Icons.favorite : Icons.favorite_border,
                        key: ValueKey(liked),
                      ),
                    ),
                    label: Text(
                      '${p.likes.length}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                if (!widget.admin) const Spacer(),
                if (p.note.length > 120)
                  TextButton(
                    onPressed: () => setState(() => _expanded = !_expanded),
                    child: Text(_expanded ? 'Show less' : 'Read more'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Hygiene score, clean-days streak and milk fat — the "why trust us" card.
class TrustCard extends StatelessWidget {
  final bool admin;
  const TrustCard({super.key, required this.admin});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final log = store.hygieneOn(DateTime.now());
    final score = log?.score ?? 0;
    final total = hygieneItems.length;
    final streak = store.hygieneStreak;
    final fat = store.averageFat();

    return HeroCard(
      padding: const EdgeInsets.all(18),
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => HygieneScreen(editable: admin)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 74,
              height: 74,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: score / total),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOutCubic,
                    builder: (_, v, _) => CircularProgressIndicator(
                      value: v,
                      strokeWidth: 7,
                      strokeCap: StrokeCap.round,
                      color: AppColors.leaf,
                      backgroundColor: Colors.white24,
                    ),
                  ),
                  Center(
                    child: Text(
                      '$score/$total',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    admin
                        ? 'Today\'s hygiene checklist'
                        : 'Today\'s hygiene score',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    score == total
                        ? 'All cleanliness steps done ✓'
                        : admin
                        ? '${total - score} steps left — tap to tick'
                        : '$score of $total cleanliness steps done',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _badge('🔥 $streak-day clean streak'),
                      if (fat != null)
                        _badge('🥛 ${fat.toStringAsFixed(1)}% fat'),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white70),
          ],
        ),
      ),
    );
  }

  Widget _badge(String t) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      t,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

void openComposer(BuildContext context, {FarmPost? existing}) {
  Navigator.of(context).push(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => PostComposer(existing: existing),
    ),
  );
}

class PostComposer extends StatefulWidget {
  final FarmPost? existing;
  const PostComposer({super.key, this.existing});

  @override
  State<PostComposer> createState() => _PostComposerState();
}

class _PostComposerState extends State<PostComposer> {
  late final _title = TextEditingController(text: widget.existing?.title);
  late final _note = TextEditingController(text: widget.existing?.note);
  late String _category = widget.existing?.category ?? 'cleaning';
  late MediaType _type = widget.existing?.mediaType ?? MediaType.none;
  late String? _path = widget.existing?.mediaPath;
  late bool _pinned = widget.existing?.pinned ?? false;
  final _formKey = GlobalKey<FormState>();
  bool _busy = false;
  bool _saved = false;
  final List<String> _pickedThisSession = [];

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pick(MediaType type, bool camera) async {
    setState(() => _busy = true);
    try {
      final m = await pickMedia(type: type, fromCamera: camera);
      if (m != null) {
        setState(() {
          _type = m.type;
          _path = m.path;
        });
        _pickedThisSession.add(m.path);
      }
    } catch (e) {
      if (mounted) {
        toast(context, 'Could not open ${camera ? 'camera' : 'gallery'}: $e');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final store = StoreScope.read(context);
    final old = widget.existing;
    // Clean up files that were picked or replaced but not kept.
    for (final f in _pickedThisSession) {
      if (f != _path) deleteMediaFile(f);
    }
    if (old?.mediaPath != null && old!.mediaPath != _path) {
      deleteMediaFile(old.mediaPath!);
    }

    final post = FarmPost(
      id: old?.id ?? store.newId(),
      title: _title.text.trim(),
      note: _note.text.trim(),
      category: _category,
      mediaType: _path == null ? MediaType.none : _type,
      mediaPath: _path,
      createdAt: old?.createdAt ?? DateTime.now(),
      pinned: _pinned,
      likes: old?.likes,
    );
    store.upsert(store.posts, post, (x) => x.id == post.id);
    _saved = true;
    Navigator.pop(context);
    toast(
      context,
      old == null ? 'Posted! Customers can see it now 🎉' : 'Post updated',
    );
  }

  @override
  Widget build(BuildContext context) {
    final preview = FarmPost(
      id: 'preview',
      title: '',
      note: '',
      category: _category,
      mediaType: _path == null ? MediaType.none : _type,
      mediaPath: _path,
      createdAt: DateTime.now(),
    );
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop || _saved) return;
        for (final f in _pickedThisSession) {
          if (f != widget.existing?.mediaPath) deleteMediaFile(f);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.existing == null ? 'New post' : 'Edit post'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
                onPressed: _busy ? null : _save,
                child: const Text('Post'),
              ),
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Stack(
                  children: [
                    PostMedia(
                      key: ValueKey('$_path-$_category'),
                      post: preview,
                      aspectRatio: 16 / 10,
                      interactive: false,
                    ),
                    if (_busy)
                      const Positioned.fill(
                        child: ColoredBox(
                          color: Colors.black38,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    if (_path != null)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: IconButton.filled(
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black54,
                          ),
                          icon: const Icon(Icons.close),
                          onPressed: () => setState(() {
                            _path = null;
                            _type = MediaType.none;
                          }),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _MediaButton(
                    Icons.videocam_outlined,
                    'Record\nvideo',
                    AppColors.rose,
                    () => _pick(MediaType.video, true),
                  ),
                  _MediaButton(
                    Icons.video_library_outlined,
                    'Video from\ngallery',
                    AppColors.violet,
                    () => _pick(MediaType.video, false),
                  ),
                  _MediaButton(
                    Icons.photo_camera_outlined,
                    'Take\nphoto',
                    AppColors.sky,
                    () => _pick(MediaType.image, true),
                  ),
                  _MediaButton(
                    Icons.photo_library_outlined,
                    'Photo from\ngallery',
                    AppColors.teal,
                    () => _pick(MediaType.image, false),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'No photo? The post shows a colourful cover instead. Videos up to 3 minutes.',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SectionHeader('What is this about?'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in postCategories)
                    ChoiceChip(
                      avatar: Text(c.emoji),
                      label: Text(c.label),
                      showCheckmark: false,
                      selected: _category == c.key,
                      onSelected: (_) => setState(() => _category = c.key),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _title,
                validator: requiredField,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'e.g. Morning shed wash done',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _note,
                minLines: 4,
                maxLines: 8,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Notes for customers',
                  hintText:
                      'Explain what you are doing and why it keeps the milk pure…',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final s in _suggestions[_category] ?? const <String>[])
                    ActionChip(
                      label: Text(s, style: const TextStyle(fontSize: 12)),
                      onPressed: () => setState(() {
                        if (_title.text.isEmpty) _title.text = s;
                      }),
                    ),
                ],
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Pin to top',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: const Text(
                  'Keep important notices first in the feed',
                ),
                value: _pinned,
                onChanged: (v) => setState(() => _pinned = v),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

const _suggestions = {
  'cleaning': [
    'Morning shed wash done ✨',
    'Cans sterilised in hot water',
    'Fresh bedding for cows',
  ],
  'milking': [
    'Hygienic milking routine',
    'Udder cleaning before milking',
    'Milk filtered & chilled',
  ],
  'feeding': [
    'Fresh green fodder today',
    'Mineral mix for strong cows',
    'Clean drinking water',
  ],
  'health': ['Vet check-up today', 'Vaccination done', 'New calf born 🐮'],
  'farm': ['Meet our cows', 'Sunrise at the farm', 'Our family at work'],
  'notice': [
    'No delivery tomorrow',
    'Milk rate update',
    'Festival special: ghee & paneer',
  ],
};

class _MediaButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _MediaButton(this.icon, this.label, this.color, this.onTap);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              child: Column(
                children: [
                  IconTile(icon, color: color, size: 40),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
