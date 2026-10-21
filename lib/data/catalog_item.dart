/// Un contenido del catálogo (serie o película) para el buscador y las listas.
class CatalogItem {
  final String title;
  final String genre;
  final int year;
  final String language;
  final int durationMinutes;

  const CatalogItem({
    required this.title,
    required this.genre,
    required this.year,
    this.language = 'Español',
    this.durationMinutes = 90,
  });
}
const List<CatalogItem> sampleCatalog = [
  CatalogItem(title: 'Risas en el aire', genre: 'Comedia', year: 2024, language: 'Español', durationMinutes: 85),
  CatalogItem(title: 'La última broma', genre: 'Comedia', year: 2022, language: 'Inglés', durationMinutes: 92),
  CatalogItem(title: 'El silencio del lago', genre: 'Suspenso', year: 2025, language: 'Francés', durationMinutes: 119),
  CatalogItem(title: 'Sombras en la niebla', genre: 'Suspenso', year: 2021, language: 'Español', durationMinutes: 126),
  CatalogItem(title: 'Furia desatada', genre: 'Acción', year: 2026, language: 'Inglés', durationMinutes: 128),
  CatalogItem(title: 'Operación relámpago', genre: 'Acción', year: 2023, language: 'Francés', durationMinutes: 135),
  CatalogItem(title: 'Aventuras de Pipo', genre: 'Infantil', year: 2024, language: 'Español', durationMinutes: 45),
  CatalogItem(title: 'El reino de los juguetes', genre: 'Infantil', year: 2020, language: 'Inglés', durationMinutes: 52),
  CatalogItem(title: 'Cartas al atardecer', genre: 'Romance', year: 2025, language: 'Francés', durationMinutes: 104),
  CatalogItem(title: 'Un café contigo', genre: 'Romance', year: 2022, language: 'Español', durationMinutes: 90),
  CatalogItem(title: 'Vecinos sin remedio', genre: 'Comedia', year: 2022, language: 'Inglés', durationMinutes: 91),
  CatalogItem(title: 'La oficina del caos', genre: 'Comedia', year: 2023, language: 'Francés', durationMinutes: 98),
  CatalogItem(title: 'Familia de otro mundo', genre: 'Comedia', year: 2024, language: 'Español', durationMinutes: 89),
  CatalogItem(title: 'Turno de risas', genre: 'Comedia', year: 2025, language: 'Inglés', durationMinutes: 96),
  CatalogItem(title: 'Un lío de amigos', genre: 'Comedia', year: 2026, language: 'Francés', durationMinutes: 87),
  CatalogItem(title: 'La casa del acantilado', genre: 'Suspenso', year: 2022, language: 'Español', durationMinutes: 106),
  CatalogItem(title: 'El último testigo', genre: 'Suspenso', year: 2023, language: 'Inglés', durationMinutes: 113),
  CatalogItem(title: 'Habitación 309', genre: 'Suspenso', year: 2024, language: 'Francés', durationMinutes: 120),
  CatalogItem(title: 'Detrás del espejo', genre: 'Suspenso', year: 2025, language: 'Español', durationMinutes: 127),
  CatalogItem(title: 'Código de silencio', genre: 'Suspenso', year: 2026, language: 'Inglés', durationMinutes: 108),
  CatalogItem(title: 'Frontera de fuego', genre: 'Acción', year: 2022, language: 'Francés', durationMinutes: 132),
  CatalogItem(title: 'Unidad especial', genre: 'Acción', year: 2023, language: 'Español', durationMinutes: 103),
  CatalogItem(title: 'Ruta de escape', genre: 'Acción', year: 2024, language: 'Inglés', durationMinutes: 110),
  CatalogItem(title: 'Cuenta regresiva', genre: 'Acción', year: 2025, language: 'Francés', durationMinutes: 117),
  CatalogItem(title: 'Misión horizonte', genre: 'Acción', year: 2026, language: 'Español', durationMinutes: 124),
  CatalogItem(title: 'Los amigos del bosque', genre: 'Infantil', year: 2022, language: 'Inglés', durationMinutes: 52),
  CatalogItem(title: 'Luna y las estrellas', genre: 'Infantil', year: 2023, language: 'Francés', durationMinutes: 59),
  CatalogItem(title: 'El tren de los colores', genre: 'Infantil', year: 2024, language: 'Español', durationMinutes: 45),
  CatalogItem(title: 'Pequeños exploradores', genre: 'Infantil', year: 2025, language: 'Inglés', durationMinutes: 52),
  CatalogItem(title: 'La isla de las nubes', genre: 'Infantil', year: 2026, language: 'Francés', durationMinutes: 59),
  CatalogItem(title: 'Después de la lluvia', genre: 'Romance', year: 2022, language: 'Español', durationMinutes: 90),
  CatalogItem(title: 'Nuestro próximo verano', genre: 'Romance', year: 2023, language: 'Inglés', durationMinutes: 97),
  CatalogItem(title: 'Dos destinos', genre: 'Romance', year: 2024, language: 'Francés', durationMinutes: 104),
  CatalogItem(title: 'La librería del amor', genre: 'Romance', year: 2025, language: 'Español', durationMinutes: 90),
  CatalogItem(title: 'Promesas de abril', genre: 'Romance', year: 2026, language: 'Inglés', durationMinutes: 97),
];
