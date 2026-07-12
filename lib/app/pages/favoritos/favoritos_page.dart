import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/repositories/remote/supabase_favorito_repository.dart';
import '../../../data/utils/supabase_client.dart';
import '../../../domain/entities/receta.dart';
import '../../../domain/usecases/usecases.dart';
import '../../styles/app_theme.dart';
import '../detalle/detalle_page.dart';

class FavoritosPage extends StatefulWidget {
  const FavoritosPage({super.key});

  @override
  State<FavoritosPage> createState() => _FavoritosPageState();
}

class _FavoritosPageState extends State<FavoritosPage> {
  final _favoritoRepo = SupabaseFavoritoRepository();

  List<Receta> _favoritos = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _cargarFavoritos();
  }

  Future<void> _cargarFavoritos() async {
    setState(() => _loading = true);
    final userId = supabase.auth.currentUser!.id;
    final favs = await GetFavoritosUseCase(_favoritoRepo).execute(userId);
    setState(() { _favoritos = favs; _loading = false; });
  }

  Future<void> _quitarFavorito(Receta receta) async {
    final userId = supabase.auth.currentUser!.id;
    await ToggleFavoritoUseCase(_favoritoRepo).execute(userId, receta);
    setState(() => _favoritos.remove(receta));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis favoritos'),
        actions: [
          if (!_loading)
            Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.salvia,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    '${_favoritos.length} recetas',
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.musgo, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.bosque))
          : _favoritos.isEmpty
              ? _buildVacio()
              : _buildLista(),
    );
  }

  Widget _buildLista() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      itemCount: _favoritos.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final receta = _favoritos[i];
        return Dismissible(
          key: Key(receta.spoonacularId.toString()),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            decoration: BoxDecoration(
              color: const Color(0xFFF6DCDC),
              borderRadius: BorderRadius.circular(AppTheme.radioTarjeta),
            ),
            child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFB3261E)),
          ),
          onDismissed: (_) => _quitarFavorito(receta),
          child: GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => DetallePage(receta: receta)),
            ).then((_) => _cargarFavoritos()),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.radioTarjeta),
                boxShadow: AppTheme.sombraSuave,
              ),
              child: Row(
                children: [
                  // Thumbnail
                  ClipRRect(
                    borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(AppTheme.radioTarjeta)),
                    child: SizedBox(
                      width: 84,
                      height: 84,
                      child: receta.imagenUrl.isNotEmpty
                          ? Image.network(receta.imagenUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _thumbPlaceholder())
                          : _thumbPlaceholder(),
                    ),
                  ),
                  // Info
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            receta.nombre,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14.5,
                                color: AppTheme.carbon),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            [
                              if (receta.kcal != null)
                                '${receta.kcal!.toStringAsFixed(0)} kcal',
                              if (receta.proteinaG != null)
                                '${receta.proteinaG!.toStringAsFixed(1)}g prot',
                            ].join('  ·  '),
                            style: const TextStyle(
                                color: AppTheme.grisTexto, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      color: AppTheme.grisTexto, size: 22),
                  const SizedBox(width: 10),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _thumbPlaceholder() => Container(
        color: AppTheme.salvia,
        child: const Center(
            child: Text('🥗', style: TextStyle(fontSize: 24))),
      );

  Widget _buildVacio() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🤍', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 14),
              const Text('Sin favoritos aún',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.carbon)),
              const SizedBox(height: 8),
              const Text('Guarda recetas tocando el corazón',
                  style: TextStyle(color: AppTheme.grisTexto, fontSize: 13)),
            ],
          ),
        ),
      );
}
