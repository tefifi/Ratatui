import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/repositories/remote/spoonacular_receta_repository.dart';
import '../../../data/repositories/remote/supabase_favorito_repository.dart';
import '../../../data/utils/supabase_client.dart';
import '../../../domain/entities/receta.dart';
import '../../../domain/usecases/usecases.dart';
import '../../styles/app_theme.dart';

class DetallePage extends StatefulWidget {
  final Receta receta;
  const DetallePage({super.key, required this.receta});

  @override
  State<DetallePage> createState() => _DetallePageState();
}

class _DetallePageState extends State<DetallePage> {
  final _recetaRepo = SpoonacularRecetaRepository();
  final _favoritoRepo = SupabaseFavoritoRepository();

  Receta? _detalle;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarDetalle();
  }

  Future<void> _cargarDetalle() async {
    try {
      final detalle = await GetRecetaDetalleUseCase(_recetaRepo)
          .execute(widget.receta.spoonacularId);
      detalle.esFavorito = widget.receta.esFavorito;
      setState(() {
        _detalle = detalle;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _toggleFavorito() async {
    if (_detalle == null) return;
    final userId = supabase.auth.currentUser!.id;
    final nuevoEstado =
        await ToggleFavoritoUseCase(_favoritoRepo).execute(userId, _detalle!);
    setState(() => _detalle!.esFavorito = nuevoEstado);
    // Actualiza el estado en la pantalla anterior
    widget.receta.esFavorito = nuevoEstado;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lino,
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.bosque))
          : _error != null
              ? Center(
                  child: Text(_error!,
                      style: const TextStyle(color: AppTheme.grisTexto)))
              : _buildDetalle(context),
    );
  }

  Widget _buildDetalle(BuildContext context) {
    final r = _detalle!;
    return CustomScrollView(
      slivers: [
        // App bar con imagen
        SliverAppBar(
          expandedHeight: 280,
          pinned: true,
          backgroundColor: AppTheme.lino,
          surfaceTintColor: Colors.transparent,
          leading: Padding(
            padding: const EdgeInsets.all(8),
            child: _CircleButton(
              icon: Icons.arrow_back_rounded,
              onTap: () => Navigator.pop(context),
            ),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                r.imagenUrl.isNotEmpty
                    ? Image.network(r.imagenUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder())
                    : _placeholder(),
                // Gradiente para legibilidad del AppBar
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.35),
                        Colors.transparent,
                        Colors.black.withOpacity(0.15),
                      ],
                      stops: const [0, 0.5, 1],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
              child: _CircleButton(
                icon: r.esFavorito
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                iconColor: r.esFavorito ? AppTheme.mostaza : AppTheme.grisTexto,
                onTap: _toggleFavorito,
              ),
            ),
          ],
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('RECETA RECOMENDADA', style: AppTheme.eyebrow),
                const SizedBox(height: 6),
                // Nombre
                Text(r.nombre,
                    style: Theme.of(context).textTheme.displayMedium),
                const SizedBox(height: 20),

                // Nutrientes
                Row(children: [
                  _NutrienteChip(
                      valor: r.kcal,
                      unidad: 'kcal',
                      label: 'Calorías',
                      icono: Icons.local_fire_department_rounded),
                  const SizedBox(width: 10),
                  _NutrienteChip(
                      valor: r.proteinaG,
                      unidad: 'g',
                      label: 'Proteína',
                      icono: Icons.bolt_rounded),
                  const SizedBox(width: 10),
                  _NutrienteChip(
                      valor: r.fibraG,
                      unidad: 'g',
                      label: 'Fibra',
                      icono: Icons.eco_rounded),
                ]),
                const SizedBox(height: 28),

                // Ingredientes / Preparación
                _SeccionTabs(
                  ingredientes: r.ingredientes,
                  instrucciones: r.instrucciones,
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _placeholder() => Container(
        color: AppTheme.salvia,
        child: const Center(child: Text('🥗', style: TextStyle(fontSize: 64))),
      );
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final VoidCallback onTap;
  const _CircleButton(
      {required this.icon, required this.onTap, this.iconColor});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(
                color: Color(0x22000000), blurRadius: 8, offset: Offset(0, 2)),
          ],
        ),
        child: Icon(icon, size: 20, color: iconColor ?? AppTheme.bosque),
      ),
    );
  }
}

class _NutrienteChip extends StatelessWidget {
  final double? valor;
  final String unidad;
  final String label;
  final IconData icono;

  const _NutrienteChip(
      {required this.valor,
      required this.unidad,
      required this.label,
      required this.icono});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.salvia,
          borderRadius: BorderRadius.circular(AppTheme.radioChico),
        ),
        child: Column(
          children: [
            Icon(icono, size: 17, color: AppTheme.musgo),
            const SizedBox(height: 4),
            Text(
              valor != null ? '${valor!.toStringAsFixed(1)}$unidad' : '-',
              style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: AppTheme.bosque),
            ),
            Text(label,
                style:
                    const TextStyle(fontSize: 10.5, color: AppTheme.grisTexto)),
          ],
        ),
      ),
    );
  }
}

/// Selector de "Ingredientes" / "Preparación" en pestañas, siguiendo la
/// referencia: dos etiquetas lado a lado con una línea indicadora bajo la
/// pestaña activa, y debajo solo el contenido de la sección seleccionada.
class _SeccionTabs extends StatefulWidget {
  final List<String> ingredientes;
  final String? instrucciones;

  const _SeccionTabs({required this.ingredientes, required this.instrucciones});

  @override
  State<_SeccionTabs> createState() => _SeccionTabsState();
}

class _SeccionTabsState extends State<_SeccionTabs> {
  int _tab = 0; // 0 = ingredientes, 1 = preparación

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _TabLabel(
              texto: 'Ingredientes',
              activo: _tab == 0,
              onTap: () => setState(() => _tab = 0),
            ),
            const SizedBox(width: 28),
            _TabLabel(
              texto: 'Preparación',
              activo: _tab == 1,
              onTap: () => setState(() => _tab = 1),
            ),
          ],
        ),
        const SizedBox(height: 2),
        const Divider(height: 1),
        const SizedBox(height: 18),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radioTarjeta),
            boxShadow: AppTheme.sombraSuave,
          ),
          child: _tab == 0 ? _buildIngredientes() : _buildPreparacion(),
        ),
      ],
    );
  }

  Widget _buildIngredientes() {
    if (widget.ingredientes.isEmpty) {
      return const Text('Sin información',
          style: TextStyle(color: AppTheme.grisTexto));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widget.ingredientes
          .map((ing) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 3),
                      child:
                          Icon(Icons.circle, size: 6, color: AppTheme.mostaza),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(ing,
                          style: const TextStyle(fontSize: 14, height: 1.4)),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }

  Widget _buildPreparacion() {
    if (widget.instrucciones == null || widget.instrucciones!.isEmpty) {
      return const Text('Sin información',
          style: TextStyle(color: AppTheme.grisTexto));
    }
    return Text(
      widget.instrucciones!,
      style: const TextStyle(fontSize: 14, height: 1.7, color: AppTheme.carbon),
    );
  }
}

class _TabLabel extends StatelessWidget {
  final String texto;
  final bool activo;
  final VoidCallback onTap;

  const _TabLabel(
      {required this.texto, required this.activo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(
          children: [
            Text(
              texto,
              style: TextStyle(
                fontSize: 15,
                fontWeight: activo ? FontWeight.w700 : FontWeight.w500,
                color: activo ? AppTheme.bosque : AppTheme.grisTexto,
              ),
            ),
            const SizedBox(height: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 3,
              width: activo ? 28 : 0,
              decoration: BoxDecoration(
                color: AppTheme.mostaza,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
