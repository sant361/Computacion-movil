import 'package:flutter/material.dart';
import '../data/catalog_item.dart';
import '../state/app_state.dart';
import 'catalog/downloads_screen.dart';
import 'catalog/notifications_screen.dart';
import 'content_detail_screen.dart';
import 'menu_screen.dart';
import 'payments/subscription_screen.dart';
import 'search_screen.dart';
import 'tokens/tokens_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCategory = 'Todo';

  void _openItem(BuildContext context, CatalogItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ContentDetailScreen(title: item.title),
      ),
    );
  }

  void _openSearch(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SearchScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFF07111F);

    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) => _buildScaffold(context, background),
    );
  }

  Widget _buildScaffold(BuildContext context, Color background) {
    final catalog = appState.catalog;
    final featured = catalog.take(8).toList();
    final continueWatching = catalog.skip(5).take(4).toList();
    final recommended = catalog.reversed.take(8).toList();
    final featuredItem = catalog.isEmpty ? null : catalog[20 % catalog.length];

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        foregroundColor: Colors.white,
        titleSpacing: 20,
        title: const Row(
          children: [
            Text(
              'MF',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            Text(
              '+',
              style: TextStyle(
                color: Color(0xFF35D0C4),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Buscar',
            onPressed: () => _openSearch(context),
            icon: const Icon(Icons.search_rounded),
          ),
          IconButton(
            tooltip: 'Descargas',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const DownloadsScreen(),
              ),
            ),
            icon: const Icon(Icons.download_for_offline_outlined),
          ),
          PopupMenuButton<String>(
            tooltip: 'Más opciones',
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              final Widget screen;
              switch (value) {
                case 'menu':
                  screen = const MenuScreen();
                case 'notifications':
                  screen = const NotificationsScreen();
                case 'tokens':
                  screen = const TokensScreen();
                default:
                  screen = const SubscriptionScreen();
              }
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => screen),
              );
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'menu', child: Text('Categorías')),
              PopupMenuItem(
                value: 'notifications',
                child: Text('Notificaciones'),
              ),
              PopupMenuItem(value: 'tokens', child: Text('Mis tokens')),
              PopupMenuItem(
                value: 'subscription',
                child: Text('Mi suscripción'),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        children: [
          _CategoryStrip(
            selected: _selectedCategory,
            onSelected: (genre) => setState(() => _selectedCategory = genre),
          ),
          const SizedBox(height: 16),
          if (_selectedCategory == 'Todo') ...[
            if (featuredItem != null) ...[
              _FeaturedCard(item: featuredItem, onTap: () {
                _openItem(context, featuredItem);
              }),
              const SizedBox(height: 28),
            ],
            _PosterSection(
              title: 'Series que podrían gustarte',
              action: 'Ver todo',
              items: featured,
              onItemTap: (item) => _openItem(context, item),
              onActionTap: () => _openSearch(context),
            ),
            const SizedBox(height: 12),
            _ContinueWatchingSection(
              items: continueWatching,
              onItemTap: (item) => _openItem(context, item),
            ),
            const SizedBox(height: 12),
            _PosterSection(
              title: 'Elegidas para ti',
              action: 'Explorar',
              items: recommended,
              onItemTap: (item) => _openItem(context, item),
              onActionTap: () => _openSearch(context),
            ),
          ] else
            _CategoryGrid(
              items: catalog.where((item) => item.genre == _selectedCategory).toList(),
              onItemTap: (item) => _openItem(context, item),
            ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF0B1929),
        indicatorColor: const Color(0xFF17354A),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_rounded),
            label: 'Buscar',
          ),
          NavigationDestination(
            icon: Icon(Icons.file_download_outlined),
            label: 'Descargas',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            label: 'Mi espacio',
          ),
        ],
        selectedIndex: 0,
        onDestinationSelected: (index) {
          final Widget? screen = switch (index) {
            1 => const SearchScreen(),
            2 => const DownloadsScreen(),
            3 => const SubscriptionScreen(),
            _ => null,
          };
          if (screen != null) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => screen),
            );
          }
        },
      ),
    );
  }
}

class _CategoryStrip extends StatelessWidget {
  const _CategoryStrip({required this.selected, required this.onSelected});

  final String selected;
  final ValueChanged<String> onSelected;
  static const _categories = [
    'Todo',
    'Acción',
    'Comedia',
    'Suspenso',
    'Infantil',
    'Romance',
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 9),
        itemBuilder: (_, index) {
          final category = _categories[index];
          final isSelected = category == selected;
          return ChoiceChip(
            label: Text(category),
            selected: isSelected,
            showCheckmark: false,
            onSelected: (_) => onSelected(category),
            labelStyle: TextStyle(
              color: isSelected ? const Color(0xFF07111F) : Colors.white70,
              fontWeight: FontWeight.w600,
            ),
            selectedColor: const Color(0xFF35D0C4),
            backgroundColor: const Color(0xFF142338),
            side: BorderSide.none,
            padding: const EdgeInsets.symmetric(horizontal: 5),
          );
        },
      ),
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({required this.item, required this.onTap});

  final CatalogItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height < 600 ? 280.0 : 390.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: const Color(0xFF102339),
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: height,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [
                        Color(0xFF267C83),
                        Color(0xFF173B54),
                        Color(0xFF101A31),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  right: -24,
                  top: 22,
                  child: Container(
                    width: 245,
                    height: 245,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF65D5C4).withValues(alpha: 0.16),
                    ),
                  ),
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Color(0x22101931),
                        Color(0xF510192D),
                      ],
                      stops: [0.24, 0.52, 1],
                    ),
                  ),
                ),
                Positioned(
                  left: 22,
                  right: 22,
                  bottom: 22,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF35D0C4),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'MF+ ORIGINAL',
                          style: TextStyle(
                            color: Color(0xFF07111F),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          height: 1.05,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 9),
                      Text(
                        '${item.year}  ·  ${item.genre}  ·  Serie',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          FilledButton.icon(
                            onPressed: onTap,
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF07111F),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                            icon: const Icon(Icons.play_arrow_rounded),
                            label: const Text(
                              'Reproducir',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(width: 10),
                          IconButton.filledTonal(
                            tooltip: 'Ver detalles',
                            onPressed: onTap,
                            style: IconButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.white.withValues(alpha: 0.16),
                            ),
                            icon: const Icon(Icons.add_rounded),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PosterSection extends StatelessWidget {
  const _PosterSection({
    required this.title,
    required this.action,
    required this.items,
    required this.onItemTap,
    required this.onActionTap,
  });

  final String title;
  final String action;
  final List<CatalogItem> items;
  final ValueChanged<CatalogItem> onItemTap;
  final VoidCallback onActionTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton(
                onPressed: onActionTap,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF35D0C4),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
                child: Text(action),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 240,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, index) {
              final item = items[index];
              final colors = _genreColors(item.genre);
              return SizedBox(
                width: 142,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => onItemTap(item),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: colors,
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 11,
                                top: 11,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.35),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'MF+',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.7,
                                    ),
                                  ),
                                ),
                              ),
                              const Positioned(
                                right: 10,
                                bottom: 10,
                                child: Icon(
                                  Icons.play_circle_fill_rounded,
                                  color: Colors.white,
                                  size: 30,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${item.genre}  ·  ${item.year}',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ContinueWatchingSection extends StatelessWidget {
  const _ContinueWatchingSection({
    required this.items,
    required this.onItemTap,
  });

  final List<CatalogItem> items;
  final ValueChanged<CatalogItem> onItemTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Text(
            'Seguir viendo',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        SizedBox(
          height: 174,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (_, index) {
              final item = items[index];
              final colors = _genreColors(item.genre);
              return SizedBox(
                width: 260,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => onItemTap(item),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: colors,
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                ),
                              ),
                              const Center(
                                child: Icon(
                                  Icons.play_circle_fill_rounded,
                                  size: 44,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 7),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: 0.28 + index * 0.16,
                          minHeight: 4,
                          backgroundColor: Colors.white12,
                          valueColor: const AlwaysStoppedAnimation(
                            Color(0xFF35D0C4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Resultados al tocar una categoría arriba de Inicio (Acción, Comedia...):
/// filtra ahí mismo en vez de llevar a otra pantalla.
class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({required this.items, required this.onItemTap});

  final List<CatalogItem> items;
  final ValueChanged<CatalogItem> onItemTap;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: Text(
            'No hay contenido en esta categoría todavía',
            style: TextStyle(color: Colors.white54),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.78,
        ),
        itemBuilder: (_, index) {
          final item = items[index];
          final colors = _genreColors(item.genre);
          return InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => onItemTap(item),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: colors,
                        ),
                      ),
                      child: const Center(
                        child: Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 36),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 3),
                Text(
                  '${item.genre}  ·  ${item.year}',
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

List<Color> _genreColors(String genre) {
  return switch (genre) {
    'Comedia' => const [Color(0xFF8B4A80), Color(0xFF382653)],
    'Suspenso' => const [Color(0xFF427C92), Color(0xFF182843)],
    'Acción' => const [Color(0xFFCA7146), Color(0xFF512D48)],
    'Infantil' => const [Color(0xFF36A6A1), Color(0xFF24517C)],
    'Romance' => const [Color(0xFFBF637D), Color(0xFF593954)],
    _ => const [Color(0xFF5570A6), Color(0xFF28314F)],
  };
}
