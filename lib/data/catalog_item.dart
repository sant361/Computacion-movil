/// Un contenido del catálogo (serie o película) para el buscador y las listas.
/// TODO: reemplazar este catálogo de muestra por datos reales del backend.
class CatalogItem {
  final String title;
  final String genre;
  final int year;

  const CatalogItem({required this.title, required this.genre, required this.year});
}
const List<CatalogItem> sampleCatalog = [
  CatalogItem(title: 'Risas en el aire', genre: 'Comedia', year: 2024),
  CatalogItem(title: 'La última broma', genre: 'Comedia', year: 2022),
  CatalogItem(title: 'El silencio del lago', genre: 'Suspenso', year: 2025),
  CatalogItem(title: 'Sombras en la niebla', genre: 'Suspenso', year: 2021),
  CatalogItem(title: 'Furia desatada', genre: 'Acción', year: 2026),
  CatalogItem(title: 'Operación relámpago', genre: 'Acción', year: 2023),
  CatalogItem(title: 'Aventuras de Pipo', genre: 'Infantil', year: 2024),
  CatalogItem(title: 'El reino de los juguetes', genre: 'Infantil', year: 2020),
  CatalogItem(title: 'Cartas al atardecer', genre: 'Romance', year: 2025),
  CatalogItem(title: 'Un café contigo', genre: 'Romance', year: 2022),
  CatalogItem(title: 'Vecinos sin remedio', genre: 'Comedia', year: 2022),
  CatalogItem(title: 'La oficina del caos', genre: 'Comedia', year: 2023),
  CatalogItem(title: 'Familia de otro mundo', genre: 'Comedia', year: 2024),
  CatalogItem(title: 'Turno de risas', genre: 'Comedia', year: 2025),
  CatalogItem(title: 'Un lío de amigos', genre: 'Comedia', year: 2026),
  CatalogItem(title: 'La casa del acantilado', genre: 'Suspenso', year: 2022),
  CatalogItem(title: 'El último testigo', genre: 'Suspenso', year: 2023),
  CatalogItem(title: 'Habitación 309', genre: 'Suspenso', year: 2024),
  CatalogItem(title: 'Detrás del espejo', genre: 'Suspenso', year: 2025),
  CatalogItem(title: 'Código de silencio', genre: 'Suspenso', year: 2026),
  CatalogItem(title: 'Frontera de fuego', genre: 'Acción', year: 2022),
  CatalogItem(title: 'Unidad especial', genre: 'Acción', year: 2023),
  CatalogItem(title: 'Ruta de escape', genre: 'Acción', year: 2024),
  CatalogItem(title: 'Cuenta regresiva', genre: 'Acción', year: 2025),
  CatalogItem(title: 'Misión horizonte', genre: 'Acción', year: 2026),
  CatalogItem(title: 'Los amigos del bosque', genre: 'Infantil', year: 2022),
  CatalogItem(title: 'Luna y las estrellas', genre: 'Infantil', year: 2023),
  CatalogItem(title: 'El tren de los colores', genre: 'Infantil', year: 2024),
  CatalogItem(title: 'Pequeños exploradores', genre: 'Infantil', year: 2025),
  CatalogItem(title: 'La isla de las nubes', genre: 'Infantil', year: 2026),
  CatalogItem(title: 'Después de la lluvia', genre: 'Romance', year: 2022),
  CatalogItem(title: 'Nuestro próximo verano', genre: 'Romance', year: 2023),
  CatalogItem(title: 'Dos destinos', genre: 'Romance', year: 2024),
  CatalogItem(title: 'La librería del amor', genre: 'Romance', year: 2025),
  CatalogItem(title: 'Promesas de abril', genre: 'Romance', year: 2026),
];
