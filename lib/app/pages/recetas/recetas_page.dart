import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/repositories/remote/spoonacular_receta_repository.dart';
import '../../../data/repositories/remote/supabase_favorito_repository.dart';
import '../../../data/repositories/remote/supabase_profile_repository.dart';
import '../../../data/utils/supabase_client.dart';
import '../../../domain/entities/padecimiento.dart';
import '../../../domain/entities/receta.dart';
import '../../../domain/usecases/usecases.dart';
import '../../styles/app_theme.dart';
import '../../widgets/nutriente_ring.dart';
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
  bool _loadingMas = false; // ← carga silenciosa al paginar
  String? _error;
  int _navIndex = 0;
  int _offset = 0; // ← offset para paginación real

  @override
  void initState() {
    super.initState();
    _cargarTodo();
  }

  Future<void> _cargarTodo() async {
    setState(() {
      _loading = true;
      _error = null;
      _offset = 0;
    });
    try {
      final userId = supabase.auth.currentUser!.id;
      final profile = await _profileRepo.getProfile(userId);
      final pads = await _profileRepo.getUserPadecimientos(userId);

      final recetas = await GetRecetasUseCase(_recetaRepo).execute(
        padecimientos: pads,
        imc: profile?.imc,
        offset: 0,
      );

      await _marcarFavoritos(recetas);

      setState(() {
        _padecimientos = pads;
        _imc = profile?.imc;
        _recetas = recetas;
        _indiceActual = 0;
        _offset = recetas.length;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  // Carga más recetas en segundo plano sin reiniciar la lista
  Future<void> _cargarMas() async {
    if (_loadingMas) return;
    setState(() => _loadingMas = true);
    try {
      final nuevas = await GetRecetasUseCase(_recetaRepo).execute(
        padecimientos: _padecimientos,
        imc: _imc,
        offset: _offset,
      );
      await _marcarFavoritos(nuevas);
      setState(() {
        _recetas.addAll(nuevas);
        _offset += nuevas.length;
        _loadingMas = false;
      });
    } catch (_) {
      setState(() => _loadingMas = false);
    }
  }

  Future<void> _marcarFavoritos(List<Receta> recetas) async {
    final userId = supabase.auth.currentUser!.id;
    final favIds = await supabase
        .from('favoritos')
        .select('spoonacular_id')
        .eq('usuario_id', userId);
    final favSet =
        (favIds as List).map((r) => r['spoonacular_id'] as int).toSet();
    for (final r in recetas) {
      r.esFavorito = favSet.contains(r.spoonacularId);
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
      // Pre-cargar más cuando queden 5 recetas
      if (_indiceActual >= _recetas.length - 5) _cargarMas();
    } else {
      // Al final de todo, cargar más
      _cargarMas().then((_) {
        if (_indiceActual < _recetas.length - 1) {
          setState(() => _indiceActual++);
        }
      });
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
          ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: Image.asset(
              'assets/images/logo_ratatui.png',
              width: 30,
              height: 30,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 10),
          const Text('Ratatui'),
        ]),
        actions: [
          if (_loadingMas)
            const Padding(
              padding: EdgeInsets.only(right: 20),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppTheme.bosque),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _cargarTodo,
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.bosque))
          : _error != null
              ? _buildError()
              : _recetas.isEmpty
                  ? _buildVacio()
                  : _buildSwipeCard(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _navIndex,
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
              icon: Icon(Icons.restaurant_menu_rounded), label: 'Recetas'),
          BottomNavigationBarItem(
              icon: Icon(Icons.favorite_border_rounded), label: 'Favoritos'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded), label: 'Perfil'),
        ],
      ),
    );
  }

  Widget _buildSwipeCard() {
    final receta = _recetas[_indiceActual];
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('RECOMENDADAS PARA TI', style: AppTheme.eyebrow),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.salvia,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '${_indiceActual + 1} / ${_recetas.length}',
                  style: const TextStyle(
                      color: AppTheme.musgo,
                      fontSize: 12,
                      fontWeight: FontWeight.w700),
                ),
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
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
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
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFFBEAEA),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.wifi_off_rounded,
                    size: 28, color: Color(0xFFB3261E)),
              ),
              const SizedBox(height: 16),
              Text('No pudimos cargar tus recetas',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center),
              const SizedBox(height: 6),
              Text(_error!,
                  style: const TextStyle(
                      color: AppTheme.grisTexto, fontSize: 12.5),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 20),
              SizedBox(
                width: 180,
                child: ElevatedButton(
                    onPressed: _cargarTodo, child: const Text('Reintentar')),
              ),
            ],
          ),
        ),
      );

  Widget _buildVacio() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🥗', style: TextStyle(fontSize: 52)),
              const SizedBox(height: 14),
              Text('No se encontraron recetas',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 6),
              const Text('Intenta ajustar tu perfil o tus condiciones',
                  style: TextStyle(color: AppTheme.grisTexto)),
            ],
          ),
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
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radioTarjeta),
        boxShadow: AppTheme.sombraSuave,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Capa de fondo: la misma foto, agrandada y difuminada, para
          // llenar toda la tarjeta sin dejar bordes vacíos.
          receta.imagenUrl.isNotEmpty
              ? ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                  child: Transform.scale(
                    scale: 1.15, // evita el borde translúcido del blur
                    child: Image.network(
                      receta.imagenUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(),
                    ),
                  ),
                )
              : _placeholder(),

          // Capa media: la foto completa, sin recortar, centrada.
          receta.imagenUrl.isNotEmpty
              ? Center(
                  child: Image.network(
                    receta.imagenUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (_, child, progress) => progress == null
                        ? child
                        : const SizedBox(
                            width: 40,
                            height: 40,
                            child:
                                CircularProgressIndicator(color: Colors.white),
                          ),
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                )
              : const SizedBox.shrink(),

          // Degradado inferior para que el texto y los anillos sean legibles.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.15),
                    Colors.black.withOpacity(0.78),
                  ],
                  stops: const [0, 0.45, 1],
                ),
              ),
            ),
          ),

          // Capa superior: botón de favorito flotante.
          Positioned(
            top: 14,
            right: 14,
            child: GestureDetector(
              onTap: onFavorito,
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x22000000),
                        blurRadius: 8,
                        offset: Offset(0, 2)),
                  ],
                ),
                child: Icon(
                  receta.esFavorito
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color:
                      receta.esFavorito ? AppTheme.mostaza : AppTheme.grisTexto,
                  size: 22,
                ),
              ),
            ),
          ),

          // Capa superior: nombre, anillos y navegación, sobre el degradado.
          Positioned(
            left: 20,
            right: 20,
            bottom: 18,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  receta.nombre,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(color: Colors.white),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 14),
                NutrienteRingRow(
                  kcal: receta.kcal,
                  proteinaG: receta.proteinaG,
                  fibraG: receta.fibraG,
                  sobreImagen: true,
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _NavCircle(
                      icon: Icons.arrow_back_ios_new_rounded,
                      enabled: onAnterior != null,
                      onTap: onAnterior,
                      sobreImagen: true,
                    ),
                    Text(
                      'Toca para ver el detalle',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 12,
                          fontStyle: FontStyle.italic),
                    ),
                    _NavCircle(
                      icon: Icons.arrow_forward_ios_rounded,
                      enabled: true,
                      onTap: onSiguiente,
                      sobreImagen: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
        color: AppTheme.salvia,
        child: const Center(child: Text('🥗', style: TextStyle(fontSize: 48))),
      );
}

class _NavCircle extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback? onTap;
  final bool sobreImagen;
  const _NavCircle({
    required this.icon,
    required this.enabled,
    required this.onTap,
    this.sobreImagen = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg = sobreImagen
        ? (enabled ? Colors.white.withOpacity(0.22) : Colors.transparent)
        : (enabled ? AppTheme.salvia : Colors.transparent);
    final Color fg = sobreImagen
        ? (enabled ? Colors.white : Colors.white.withOpacity(0.35))
        : (enabled ? AppTheme.bosque : const Color(0xFFD8D8D0));
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: Icon(icon, size: 16, color: fg),
      ),
    );
  }
}
