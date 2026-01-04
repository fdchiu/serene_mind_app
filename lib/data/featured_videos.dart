class FeaturedVideo {
  const FeaturedVideo({
    required this.id,
    required this.title,
    required this.channel,
  });

  final String id;
  final String title;
  final String channel;

  String get thumbnail => 'https://img.youtube.com/vi/$id/mqdefault.jpg';

  Uri get url => Uri.parse('https://www.youtube.com/watch?v=$id');
}

const featuredVideos = [
  FeaturedVideo(
    id: '1ZYbU82GVz4',
    title: '10-Minute Meditation For Beginners',
    channel: 'Goodful',
  ),
  FeaturedVideo(
    id: 'O-6f5wQXSu8',
    title: '15 Minute Guided Meditation',
    channel: 'Great Meditation',
  ),
  FeaturedVideo(
    id: 'ZToicYcHIOU',
    title: 'Calm Sleep Stories',
    channel: 'Calm',
  ),
  FeaturedVideo(
    id: 'inpok4MKVLM',
    title: '5-Minute Meditation You Can Do Anywhere',
    channel: 'Goodful',
  ),
  FeaturedVideo(
    id: 'ez3GgRqhNvA',
    title: 'Relaxing Nature Sounds',
    channel: 'Relaxing White Noise',
  ),
  FeaturedVideo(
    id: 'aXItOY0sLRY',
    title: 'Tibetan Healing Sounds',
    channel: 'Healing Vibrations',
  ),
];
