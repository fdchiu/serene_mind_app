import 'package:flutter/material.dart';

import '../widgets/youtube_video_grid.dart';

class VideosScreen extends StatelessWidget {
  const VideosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Guided Videos',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            Text(
              'Curated guided meditations from YouTube.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 20),
            const YouTubeVideoGrid(),
          ],
        ),
      ),
    );
  }
}
