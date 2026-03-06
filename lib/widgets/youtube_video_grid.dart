import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_theme.dart';
import '../data/featured_videos.dart';

class YouTubeVideoGrid extends StatefulWidget {
  const YouTubeVideoGrid({super.key});

  @override
  State<YouTubeVideoGrid> createState() => _YouTubeVideoGridState();
}

class _YouTubeVideoGridState extends State<YouTubeVideoGrid> {
  String _query = '';
  FeaturedVideo? _selected;

  @override
  Widget build(BuildContext context) {
    final filtered = featuredVideos
        .where(
          (video) =>
              video.title.toLowerCase().contains(_query.toLowerCase()) ||
              video.channel.toLowerCase().contains(_query.toLowerCase()),
        )
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            hintText: 'Search meditation videos...',
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.08),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
          ),
          onChanged: (value) => setState(() => _query = value),
        ),
        if (_selected != null) ...[
          const SizedBox(height: 16),
          Container(
            decoration: glassDecoration(context),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    _selected!.thumbnail,
                    fit: BoxFit.cover,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selected!.title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        _selected!.channel,
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(color: Colors.white70),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () => launchUrl(
                          _selected!.url,
                          mode: LaunchMode.externalApplication,
                        ),
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Play on YouTube'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filtered.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.95,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
          ),
          itemBuilder: (context, index) {
            final video = filtered[index];
            final isSelected = video.id == _selected?.id;
            final baseDecoration = glassDecoration(context);
            return GestureDetector(
              onTap: () => setState(() => _selected = video),
              child: Container(
                decoration: baseDecoration.copyWith(
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.transparent,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Image.network(
                          video.thumbnail,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            video.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          Text(
                            video.channel,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
