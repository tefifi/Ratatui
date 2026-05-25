import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/repositories/remote/spoonacular_receta_repository.dart';
import '../../../data/repositories/remote/supabase_favorito_repository.dart';
import '../../../data/utils/supabase_client.dart';
import '../../../domain/entities/receta.dart';
import '../../../domain/usecases/usecases.dart';

class DetallePage extends StatefulWidget {
  final Receta receta;
  const DetallePage({super.key, required this.receta});

  @override
  State<DetallePage> createState() => _DetallePageState();
}

class _DetallePageState extends State<DetallePage> {
  final _recetaRepo   = SpoonacularRecetaRepository();
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
      setState(() { _detalle = detalle; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _toggleFavorito() async {
    if (_detalle == null) return;
    final userId = supabase.auth.currentUser!.id;
    final nuevoEstado = await ToggleFavoritoUseCase(_favoritoRepo)
        .execute(userId, _detalle!);
    setState(() => _detalle!.esFavorito = nuevoEstado);
    // Actualiza el estado en la pantalla anterior
    widget.receta.esFavorito = nuevoEstado;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _buildDetalle(),
    );
  }

  Widget _buildDetalle() {
    final r = _detalle!;
    return CustomScrollView(
      slivers: [
        // App bar con imagen
        SliverAppBar(
          expandedHeight: 260,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                r.imagenUrl.isNotEmpty
                    ? Image.network(r.imagenUrl, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder())
                    : _placeholder(),
                // Gradiente para legibilidad del AppBar
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.4),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(
                r.esFavorito ? Icons.favorite : Icons.favorite_border,
                color: Colors.white,
              ),
              onPressed: _toggleFavorito,
            ),
          ],
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nombre
                Text(r.nombre,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),

                // Nutrientes
                Row(children: [
                  _NutrienteChip(
                      valor: r.kcal, unidad: 'kcal', label: 'Calorías'),
                  const SizedBox(width: 8),
                  _NutrienteChip(
                      valor: r.proteinaG, unidad: 'g', label: 'Proteína'),
                  const SizedBox(width: 8),
                  _NutrienteChip(
                      valor: r.fibraG, unidad: 'g', label: 'Fibra'),
                ]),
                const SizedBox(height: 24),

                // Ingredientes
                _Acordeon(
                  titulo: 'Ingredientes',
                  icono: Icons.shopping_basket_outlined,
                  child: r.ingredientes.isEmpty
                      ? const Text('Sin información',
                          style: TextStyle(color: Colors.grey))
                      : Column(
                          children: r.ingredientes
                              .map((ing) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 5),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Icon(Icons.check_circle,
                                            size: 16,
                                            color: Color(0xFF7BBF3A)),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(ing,
                                              style: const TextStyle(
                                                  fontSize: 14)),
                                        ),
                                      ],
                                    ),
                                  ))
                              .toList(),
                        ),
                ),
                const SizedBox(height: 12),

                // Preparación
                _Acordeon(
                  titulo: 'Preparación',
                  icono: Icons.menu_book_outlined,
                  child: r.instrucciones == null || r.instrucciones!.isEmpty
                      ? const Text('Sin información',
                          style: TextStyle(color: Colors.grey))
                      : Text(
                          r.instrucciones!,
                          style: const TextStyle(
                              fontSize: 14, height: 1.6),
                        ),
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
        color: const Color(0xFFC0DD97),
        child: const Center(
            child: Text('🥗', style: TextStyle(fontSize: 64))),
      );
}

class _NutrienteChip extends StatelessWidget {
  final double? valor;
  final String unidad;
  final String label;

  const _NutrienteChip(
      {required this.valor, required this.unidad, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F7E6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              valor != null ? '${valor!.toStringAsFixed(1)}$unidad' : '-',
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF2D5016)),
            ),
            Text(label,
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class _Acordeon extends StatefulWidget {
  final String titulo;
  final IconData icono;
  final Widget child;

  const _Acordeon(
      {required this.titulo, required this.icono, required this.child});

  @override
  State<_Acordeon> createState() => _AcordeonState();
}

class _AcordeonState extends State<_Acordeon> {
  bool _abierto = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE0E0E0)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() => _abierto = !_abierto),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(widget.icono,
                      size: 20, color: const Color(0xFF2D5016)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(widget.titulo,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15)),
                  ),
                  Icon(
                    _abierto
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),
          if (_abierto)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: widget.child,
            ),
        ],
      ),
    );
  }
}
