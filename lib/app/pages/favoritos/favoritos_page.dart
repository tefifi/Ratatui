import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/repositories/remote/supabase_favorito_repository.dart';
import '../../../data/utils/supabase_client.dart';
import '../../../domain/entities/receta.dart';
import '../../../domain/usecases/usecases.dart';
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
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '${_favoritos.length} recetas',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _favoritos.isEmpty
              ? _buildVacio()
              : _buildLista(),
    );
  }

  Widget _buildLista() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _favoritos.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final receta = _favoritos[i];
        return Dismissible(
          key: Key(receta.spoonacularId.toString()),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.delete_outline, color: Colors.red),
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
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE8E8E8)),
              ),
              child: Row(
                children: [
                  // Thumbnail
                  ClipRRect(
                    borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(12)),
                    child: SizedBox(
                      width: 80,
                      height: 80,
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
                          horizontal: 12, vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            receta.nombre,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            [
                              if (receta.kcal != null)
                                '${receta.kcal!.toStringAsFixed(0)} kcal',
                              if (receta.proteinaG != null)
                                '${receta.proteinaG!.toStringAsFixed(1)}g prot',
                            ].join(' · '),
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right,
                      color: Colors.grey, size: 20),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _thumbPlaceholder() => Container(
        color: const Color(0xFFC0DD97),
        child: const Center(
            child: Text('🥗', style: TextStyle(fontSize: 24))),
      );

  Widget _buildVacio() => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🤍', style: TextStyle(fontSize: 48)),
            SizedBox(height: 12),
            Text('Sin favoritos aún',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            SizedBox(height: 8),
            Text('Guarda recetas tocando el corazón',
                style: TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
      );
}
