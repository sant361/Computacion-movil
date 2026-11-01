class CatalogEpisode {
  const CatalogEpisode(
      {this.id = '',
      required this.title,
      required this.videoUrl,
      this.subtitleUrl = '',
      this.season = 1,
      this.number = 1,
      this.durationMinutes = 24});

  final String id;
  final String title;
  final String videoUrl;
  final String subtitleUrl;
  final int season;
  final int number;
  final int durationMinutes;

  String progressKey(String contentTitle) =>
      '$contentTitle · T$season E$number · $title';

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'videoUrl': videoUrl,
        'subtitleUrl': subtitleUrl,
        'season': season,
        'number': number,
        'durationMinutes': durationMinutes
      };

  factory CatalogEpisode.fromJson(Map<String, dynamic> json) => CatalogEpisode(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      videoUrl: json['videoUrl'] as String? ?? '',
      subtitleUrl: json['subtitleUrl'] as String? ?? '',
      season: (json['season'] as num?)?.toInt() ?? 1,
      number: (json['number'] as num?)?.toInt() ?? 1,
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 24);

  CatalogEpisode copyWith(
          {String? id,
          String? title,
          String? videoUrl,
          String? subtitleUrl,
          int? season,
          int? number,
          int? durationMinutes}) =>
      CatalogEpisode(
          id: id ?? this.id,
          title: title ?? this.title,
          videoUrl: videoUrl ?? this.videoUrl,
          subtitleUrl: subtitleUrl ?? this.subtitleUrl,
          season: season ?? this.season,
          number: number ?? this.number,
          durationMinutes: durationMinutes ?? this.durationMinutes);
}

class CatalogItem {
  final String id;
  final String title;
  final String genre;
  final int year;
  final String language;
  final int durationMinutes;
  final String description;
  final String videoUrl;
  final String trailerUrl;
  final String posterUrl;
  final String subtitleUrl;
  final String? ageRating;
  final List<CatalogEpisode> episodes;

  const CatalogItem(
      {this.id = '',
      required this.title,
      required this.genre,
      required this.year,
      this.language = 'Español',
      this.durationMinutes = 90,
      this.description = '',
      this.videoUrl = '',
      this.trailerUrl = '',
      this.posterUrl = '',
      this.subtitleUrl = '',
      this.ageRating,
      this.episodes = const []});

  String get rating => ageRating != null
      ? (parentalRatings.contains(ageRating) ? ageRating! : '+18')
      : switch (genre) {
          'Infantil' || 'Comedia' => 'TP',
          'Romance' || 'Acción' => '+14',
          _ => '+18',
        };

  String? get validationError {
    if (title.trim().isEmpty) return 'Escribe un título.';
    if (genre.trim().isEmpty || language.trim().isEmpty) {
      return 'Completa el género y el idioma.';
    }
    if (year < 1900 || year > DateTime.now().year + 1 || durationMinutes < 1) {
      return 'Revisa el año y la duración.';
    }
    if (ageRating != null && !parentalRatings.contains(ageRating)) {
      return 'Revisa la clasificación por edad.';
    }
    bool validUrl(String value) {
      if (value.isEmpty) return true;
      final uri = Uri.tryParse(value);
      return uri != null &&
          ['http', 'https'].contains(uri.scheme) &&
          uri.host.isNotEmpty;
    }

    if (![videoUrl, trailerUrl, posterUrl, subtitleUrl].every(validUrl)) {
      return 'Revisa las direcciones de los archivos multimedia.';
    }
    if (videoUrl.isEmpty && episodes.isEmpty) {
      return 'Agrega un video o al menos un episodio.';
    }
    final numbers = <String>{};
    final ids = <String>{};
    for (final episode in episodes) {
      if (episode.title.trim().isEmpty ||
          episode.season < 1 ||
          episode.number < 1 ||
          episode.durationMinutes < 1 ||
          episode.videoUrl.isEmpty ||
          !validUrl(episode.videoUrl) ||
          !validUrl(episode.subtitleUrl)) {
        return 'Revisa los datos de los episodios.';
      }
      if (!numbers.add('${episode.season}:${episode.number}') ||
          (episode.id.isNotEmpty && !ids.add(episode.id))) {
        return 'No puede haber episodios repetidos.';
      }
    }
    return null;
  }

  List<CatalogEpisode> get orderedEpisodes => [...episodes]..sort((a, b) {
      final season = a.season.compareTo(b.season);
      return season != 0 ? season : a.number.compareTo(b.number);
    });

  Map<String, dynamic> toJson() => {
        'title': title,
        'genre': genre,
        'year': year,
        'language': language,
        'durationMinutes': durationMinutes,
        'description': description,
        'videoUrl': videoUrl,
        'trailerUrl': trailerUrl,
        'posterUrl': posterUrl,
        'subtitleUrl': subtitleUrl,
        if (ageRating != null) 'ageRating': ageRating,
        'episodes': episodes.map((episode) => episode.toJson()).toList(),
      };

  factory CatalogItem.fromJson(Map<String, dynamic> json, {String id = ''}) =>
      CatalogItem(
          id: id.isNotEmpty ? id : json['id'] as String? ?? '',
          title: json['title'] as String? ?? '',
          genre: json['genre'] as String? ?? '',
          year: (json['year'] as num?)?.toInt() ?? 0,
          language: json['language'] as String? ?? 'Español',
          durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 90,
          description: json['description'] as String? ?? '',
          videoUrl: json['videoUrl'] as String? ?? '',
          trailerUrl: json['trailerUrl'] as String? ?? '',
          posterUrl: json['posterUrl'] as String? ?? '',
          subtitleUrl: json['subtitleUrl'] as String? ?? '',
          ageRating: json['ageRating'] as String?,
          episodes: (json['episodes'] as List? ?? [])
              .whereType<Map>()
              .map((episode) =>
                  CatalogEpisode.fromJson(Map<String, dynamic>.from(episode)))
              .toList());

  CatalogItem copyWith(
          {String? id,
          String? title,
          String? genre,
          int? year,
          String? language,
          int? durationMinutes,
          String? description,
          String? videoUrl,
          String? trailerUrl,
          String? posterUrl,
          String? subtitleUrl,
          String? ageRating,
          List<CatalogEpisode>? episodes}) =>
      CatalogItem(
          id: id ?? this.id,
          title: title ?? this.title,
          genre: genre ?? this.genre,
          year: year ?? this.year,
          language: language ?? this.language,
          durationMinutes: durationMinutes ?? this.durationMinutes,
          description: description ?? this.description,
          videoUrl: videoUrl ?? this.videoUrl,
          trailerUrl: trailerUrl ?? this.trailerUrl,
          posterUrl: posterUrl ?? this.posterUrl,
          subtitleUrl: subtitleUrl ?? this.subtitleUrl,
          ageRating: ageRating ?? this.ageRating,
          episodes: episodes ?? this.episodes);
}

/// Clasificaciones de menor a mayor restricción.
const List<String> parentalRatings = ['TP', '+14', '+18'];
const List<CatalogItem> sampleCatalog = [
  CatalogItem(
      title: 'Risas en el aire',
      genre: 'Comedia',
      year: 2024,
      language: 'Español',
      durationMinutes: 85),
  CatalogItem(
      title: 'La última broma',
      genre: 'Comedia',
      year: 2022,
      language: 'Inglés',
      durationMinutes: 92),
  CatalogItem(
      title: 'El silencio del lago',
      genre: 'Suspenso',
      year: 2025,
      language: 'Francés',
      durationMinutes: 119),
  CatalogItem(
      title: 'Sombras en la niebla',
      genre: 'Suspenso',
      year: 2021,
      language: 'Español',
      durationMinutes: 126),
  CatalogItem(
      title: 'Furia desatada',
      genre: 'Acción',
      year: 2026,
      language: 'Inglés',
      durationMinutes: 128),
  CatalogItem(
      title: 'Operación relámpago',
      genre: 'Acción',
      year: 2023,
      language: 'Francés',
      durationMinutes: 135),
  CatalogItem(
      title: 'Aventuras de Pipo',
      genre: 'Infantil',
      year: 2024,
      language: 'Español',
      durationMinutes: 45),
  CatalogItem(
      title: 'El reino de los juguetes',
      genre: 'Infantil',
      year: 2020,
      language: 'Inglés',
      durationMinutes: 52),
  CatalogItem(
      title: 'Cartas al atardecer',
      genre: 'Romance',
      year: 2025,
      language: 'Francés',
      durationMinutes: 104),
  CatalogItem(
      title: 'Un café contigo',
      genre: 'Romance',
      year: 2022,
      language: 'Español',
      durationMinutes: 90),
  CatalogItem(
      title: 'Vecinos sin remedio',
      genre: 'Comedia',
      year: 2022,
      language: 'Inglés',
      durationMinutes: 91),
  CatalogItem(
      title: 'La oficina del caos',
      genre: 'Comedia',
      year: 2023,
      language: 'Francés',
      durationMinutes: 98),
  CatalogItem(
      title: 'Familia de otro mundo',
      genre: 'Comedia',
      year: 2024,
      language: 'Español',
      durationMinutes: 89),
  CatalogItem(
      title: 'Turno de risas',
      genre: 'Comedia',
      year: 2025,
      language: 'Inglés',
      durationMinutes: 96),
  CatalogItem(
      title: 'Un lío de amigos',
      genre: 'Comedia',
      year: 2026,
      language: 'Francés',
      durationMinutes: 87),
  CatalogItem(
      title: 'La casa del acantilado',
      genre: 'Suspenso',
      year: 2022,
      language: 'Español',
      durationMinutes: 106),
  CatalogItem(
      title: 'El último testigo',
      genre: 'Suspenso',
      year: 2023,
      language: 'Inglés',
      durationMinutes: 113),
  CatalogItem(
      title: 'Habitación 309',
      genre: 'Suspenso',
      year: 2024,
      language: 'Francés',
      durationMinutes: 120),
  CatalogItem(
      title: 'Detrás del espejo',
      genre: 'Suspenso',
      year: 2025,
      language: 'Español',
      durationMinutes: 127),
  CatalogItem(
      title: 'Código de silencio',
      genre: 'Suspenso',
      year: 2026,
      language: 'Inglés',
      durationMinutes: 108),
  CatalogItem(
      title: 'Frontera de fuego',
      genre: 'Acción',
      year: 2022,
      language: 'Francés',
      durationMinutes: 132),
  CatalogItem(
      title: 'Unidad especial',
      genre: 'Acción',
      year: 2023,
      language: 'Español',
      durationMinutes: 103),
  CatalogItem(
      title: 'Ruta de escape',
      genre: 'Acción',
      year: 2024,
      language: 'Inglés',
      durationMinutes: 110),
  CatalogItem(
      title: 'Cuenta regresiva',
      genre: 'Acción',
      year: 2025,
      language: 'Francés',
      durationMinutes: 117),
  CatalogItem(
      title: 'Misión horizonte',
      genre: 'Acción',
      year: 2026,
      language: 'Español',
      durationMinutes: 124),
  CatalogItem(
      title: 'Los amigos del bosque',
      genre: 'Infantil',
      year: 2022,
      language: 'Inglés',
      durationMinutes: 52),
  CatalogItem(
      title: 'Luna y las estrellas',
      genre: 'Infantil',
      year: 2023,
      language: 'Francés',
      durationMinutes: 59),
  CatalogItem(
      title: 'El tren de los colores',
      genre: 'Infantil',
      year: 2024,
      language: 'Español',
      durationMinutes: 45),
  CatalogItem(
      title: 'Pequeños exploradores',
      genre: 'Infantil',
      year: 2025,
      language: 'Inglés',
      durationMinutes: 52),
  CatalogItem(
      title: 'La isla de las nubes',
      genre: 'Infantil',
      year: 2026,
      language: 'Francés',
      durationMinutes: 59),
  CatalogItem(
      title: 'Después de la lluvia',
      genre: 'Romance',
      year: 2022,
      language: 'Español',
      durationMinutes: 90),
  CatalogItem(
      title: 'Nuestro próximo verano',
      genre: 'Romance',
      year: 2023,
      language: 'Inglés',
      durationMinutes: 97),
  CatalogItem(
      title: 'Dos destinos',
      genre: 'Romance',
      year: 2024,
      language: 'Francés',
      durationMinutes: 104),
  CatalogItem(
      title: 'La librería del amor',
      genre: 'Romance',
      year: 2025,
      language: 'Español',
      durationMinutes: 90),
  CatalogItem(
      title: 'Promesas de abril',
      genre: 'Romance',
      year: 2026,
      language: 'Inglés',
      durationMinutes: 97),
];
