import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/repositories/remote/spoonacular_receta_repository.dart';
import '../../../data/repositories/remote/supabase_favorito_repository.dart';
import '../../../data/repositories/remote/supabase_profile_repository.dart';
import '../../../data/utils/supabase_client.dart';
import '../../../domain/entities/padecimiento.dart';
import '../../../domain/entities/receta.dart';
import '../../../domain/usecases/usecases.dart';
import '../detalle/detalle_page.dart';
import '../favoritos/favoritos_page.dart';
import '../perfil/perfil_page.dart';

class RecetasPage extends StatefulWidget {
  const RecetasPage({super.key});

  @override
  State<RecetasPage> createState() => _RecetasPageState();
}

class _RecetasPageState extends State<RecetasPage> {
  final _recetaRepo = SpoonacularRecetaRepository();
  final _favoritoRepo = SupabaseFavoritoRepository();
  final _profileRepo = SupabaseProfileRepository();

  List<Receta> _recetas = [];
  List<Padecimiento> _padecimientos = [];
  double? _imc;
  int _indiceActual = 0;
  bool _loading = true;
  String? _error;
  int _navIndex = 0;

  @override
  void initState() {
    super.initState();
    _cargarTodo();
  }

  Future<void> _cargarTodo() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final userId = supabase.auth.currentUser!.id;
      final profile = await _profileRepo.getProfile(userId);
      final pads = await _profileRepo.getUserPadecimientos(userId);

      final recetas = await GetRecetasUseCase(_recetaRepo).execute(
        padecimientos: pads,
        imc: profile?.imc,
      );

      // Marcar las que ya son favoritas
      final favIds = await supabase
          .from('favoritos')
          .select('spoonacular_id')
          .eq('usuario_id', userId);
      final favSet =
          (favIds as List).map((r) => r['spoonacular_id'] as int).toSet();
      for (final r in recetas) {
        r.esFavorito = favSet.contains(r.spoonacularId);
      }

      setState(() {
        _padecimientos = pads;
        _imc = profile?.imc;
        _recetas = recetas;
        _indiceActual = 0;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _toggleFavorito(Receta receta) async {
    final userId = supabase.auth.currentUser!.id;
    final nuevoEstado =
        await ToggleFavoritoUseCase(_favoritoRepo).execute(userId, receta);
    setState(() => receta.esFavorito = nuevoEstado);
  }

  void _siguiente() {
    if (_indiceActual < _recetas.length - 1) {
      setState(() => _indiceActual++);
    } else {
      _cargarTodo();
    }
  }

  void _anterior() {
    if (_indiceActual > 0) setState(() => _indiceActual--);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
                color: Color(0xFF7BBF3A), shape: BoxShape.circle),
            child:
                const Center(child: Text('🌿', style: TextStyle(fontSize: 14))),
          ),
          const SizedBox(width: 8),
          const Text('Ratatui'),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarTodo,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _recetas.isEmpty
                  ? _buildVacio()
                  : _buildSwipeCard(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _navIndex,
        selectedItemColor: const Color(0xFF2D5016),
        onTap: (i) {
          if (i == 0) {
            setState(() => _navIndex = 0);
          } else if (i == 1) {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const FavoritosPage()));
          } else if (i == 2) {
            Navigator.push(
                context, MaterialPageRoute(builder: (_) => const PerfilPage()));
          }
        },
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.restaurant_menu), label: 'Recetas'),
          BottomNavigationBarItem(
              icon: Icon(Icons.favorite_border), label: 'Favoritos'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline), label: 'Perfil'),
        ],
      ),
    );
  }

  Widget _buildSwipeCard() {
    final receta = _recetas[_indiceActual];
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recomendadas para ti',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              Text(
                '${_indiceActual + 1} / ${_recetas.length}',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ],
          ),
        ),
        Expanded(
          child: GestureDetector(
            onHorizontalDragEnd: (details) {
              if (details.primaryVelocity! < -200) _siguiente();
              if (details.primaryVelocity! > 200) _anterior();
            },
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DetallePage(receta: receta),
                  ),
                ).then((_) => setState(() {})),
                child: _RecetaCard(
                  receta: receta,
                  onFavorito: () => _toggleFavorito(receta),
                  onSiguiente: _siguiente,
                  onAnterior: _indiceActual > 0 ? _anterior : null,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildError() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                  onPressed: _cargarTodo, child: const Text('Reintentar')),
            ],
          ),
        ),
      );

  Widget _buildVacio() => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🥗', style: TextStyle(fontSize: 48)),
            SizedBox(height: 12),
            Text('No se encontraron recetas', style: TextStyle(fontSize: 16)),
            SizedBox(height: 8),
            Text('Intenta ajustar tu perfil',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
}

class _RecetaCard extends StatelessWidget {
  final Receta receta;
  final VoidCallback onFavorito;
  final VoidCallback onSiguiente;
  final VoidCallback? onAnterior;

  const _RecetaCard({
    required this.receta,
    required this.onFavorito,
    required this.onSiguiente,
    this.onAnterior,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Imagen
          Expanded(
            flex: 5,
            child: Stack(
              fit: StackFit.expand,
              children: [
                receta.imagenUrl.isNotEmpty
                    ? Image.network(receta.imagenUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder())
                    : _placeholder(),
                // Botón favorito
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: onFavorito,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        receta.esFavorito
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: Colors.red,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Info
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    receta.nombre,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(children: [
                    _Nutriente(
                        valor: receta.kcal, unidad: 'kcal', label: 'Calorías'),
                    const SizedBox(width: 8),
                    _Nutriente(
                        valor: receta.proteinaG,
                        unidad: 'g',
                        label: 'Proteína'),
                    const SizedBox(width: 8),
                    _Nutriente(
                        valor: receta.fibraG, unidad: 'g', label: 'Fibra'),
                  ]),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: onAnterior,
                        icon: Icon(
                          Icons.arrow_back_ios,
                          color: onAnterior != null
                              ? const Color(0xFF2D5016)
                              : Colors.grey[300],
                        ),
                      ),
                      Text(
                        'Toca para ver detalle',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                      IconButton(
                        onPressed: onSiguiente,
                        icon: const Icon(Icons.arrow_forward_ios,
                            color: Color(0xFF2D5016)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
        color: const Color(0xFFC0DD97),
        child: const Center(child: Text('🥗', style: TextStyle(fontSize: 48))),
      );
}

class _Nutriente extends StatelessWidget {
  final double? valor;
  final String unidad;
  final String label;

  const _Nutriente(
      {required this.valor, required this.unidad, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F7E6),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              valor != null ? '${valor!.toStringAsFixed(1)}$unidad' : '-',
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Color(0xFF2D5016)),
            ),
            Text(label,
                style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
