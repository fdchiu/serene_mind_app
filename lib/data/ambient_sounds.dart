class AmbientTrack {
  const AmbientTrack({
    required this.id,
    required this.title,
    required this.url,
    this.durationLabel,
  });

  final String id;
  final String title;
  final String url;
  final String? durationLabel;
}

class AmbientSoundCategory {
  const AmbientSoundCategory({
    required this.id,
    required this.label,
    required this.icon,
    required this.tracks,
  });

  final String id;
  final String label;
  final String icon;
  final List<AmbientTrack> tracks;
}

const ambientSoundCategories = [
  AmbientSoundCategory(
    id: 'water',
    label: 'Water & Rain',
    icon: '🌧️',
    tracks: [
      AmbientTrack(
        id: 'rainy-night',
        title: 'Rainy Night Downpour',
        url:
            'https://cdn.pixabay.com/download/audio/2022/03/15/audio_6fa353a811.mp3?filename=rainy-night-110837.mp3',
        durationLabel: '2:30',
      ),
      AmbientTrack(
        id: 'ocean-wave',
        title: 'Gentle Ocean Waves',
        url:
            'https://cdn.pixabay.com/download/audio/2022/03/15/audio_8671facb0b.mp3?filename=ocean-wave-110751.mp3',
        durationLabel: '1:52',
      ),
    ],
  ),
  AmbientSoundCategory(
    id: 'wind',
    label: 'Wind & Night',
    icon: '🌬️',
    tracks: [
      AmbientTrack(
        id: 'strong-wind',
        title: 'Highland Gusts',
        url:
            'https://cdn.pixabay.com/download/audio/2022/03/15/audio_73218f63ba.mp3?filename=strong-wind-110748.mp3',
        durationLabel: '1:08',
      ),
      AmbientTrack(
        id: 'night-insects',
        title: 'Night Insect Chorus',
        url:
            'https://cdn.pixabay.com/download/audio/2021/09/16/audio_5f9c1921cf.mp3?filename=night-insect-chorus-87815.mp3',
        durationLabel: '2:07',
      ),
    ],
  ),
  AmbientSoundCategory(
    id: 'forest',
    label: 'Forest & Garden',
    icon: '🌿',
    tracks: [
      AmbientTrack(
        id: 'birds-singing',
        title: 'Morning Birds',
        url:
            'https://cdn.pixabay.com/download/audio/2021/09/16/audio_101582bebe.mp3?filename=birds-singing-ambient-87816.mp3',
        durationLabel: '1:20',
      ),
      AmbientTrack(
        id: 'nature-ambience',
        title: 'Garden Ambience',
        url:
            'https://cdn.pixabay.com/download/audio/2022/03/15/audio_39a9a01b14.mp3?filename=nature-ambience-110739.mp3',
        durationLabel: '1:40',
      ),
    ],
  ),
  AmbientSoundCategory(
    id: 'focus',
    label: 'Focus & Hearth',
    icon: '🔥',
    tracks: [
      AmbientTrack(
        id: 'binaural-focus',
        title: 'Binaural Focus',
        url:
            'https://cdn.pixabay.com/download/audio/2021/08/09/audio_7b9426a075.mp3?filename=binaural-beat-technology-75549.mp3',
        durationLabel: '3:12',
      ),
      AmbientTrack(
        id: 'campfire',
        title: 'Campfire Crackle',
        url:
            'https://cdn.pixabay.com/download/audio/2022/08/11/audio_71181b3dd8.mp3?filename=campfire-ambient-115374.mp3',
        durationLabel: '2:05',
      ),
    ],
  ),
];
