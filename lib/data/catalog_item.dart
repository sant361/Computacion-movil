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
];
