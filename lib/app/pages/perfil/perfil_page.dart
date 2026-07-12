import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/repositories/remote/supabase_padecimiento_repository.dart';
import '../../../data/repositories/remote/supabase_profile_repository.dart';
import '../../../data/utils/supabase_client.dart';
import '../../../domain/entities/padecimiento.dart';
import '../../../domain/entities/profile.dart';
import '../../../domain/usecases/usecases.dart';
import '../../styles/app_theme.dart';
import '../recetas/recetas_page.dart';

class PerfilPage extends StatefulWidget {
  final bool esPrimeraVez;
  const PerfilPage({super.key, this.esPrimeraVez = false});

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  final _pesoCtrl   = TextEditingController();
  final _alturaCtrl = TextEditingController();

  final _profileRepo      = SupabaseProfileRepository();
  final _padecimientoRepo = SupabasePadecimientoRepository();

  Profile? _profile;
  List<Padecimiento> _todosLosPadecimientos = [];
  Set<int> _seleccionados = {};
  bool _loading = true;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final userId = supabase.auth.currentUser!.id;
    final profile = await _profileRepo.getProfile(userId);
    final todos   = await GetPadecimientosUseCase(_padecimientoRepo).execute();
    final actuales = await _profileRepo.getUserPadecimientos(userId);

    setState(() {
      _profile = profile;
      _todosLosPadecimientos = todos;
      _seleccionados = actuales.map((p) => p.id).toSet();
      if (profile?.pesoKg != null) _pesoCtrl.text = profile!.pesoKg!.toString();
      if (profile?.alturaCm != null) _alturaCtrl.text = profile!.alturaCm!.toString();
      _loading = false;
    });
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    try {
      final userId = supabase.auth.currentUser!.id;
      final peso   = double.tryParse(_pesoCtrl.text);
      final altura = double.tryParse(_alturaCtrl.text);

      await SaveProfileUseCase(_profileRepo).execute(
        profile: Profile(
          id: userId,
          nombre: _profile?.nombre ?? '',
          pesoKg: peso,
          alturaCm: altura,
        ),
        padecimientoIds: _seleccionados.toList(),
      );

      if (mounted) {
        if (widget.esPrimeraVez) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const RecetasPage()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Perfil guardado')),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<void> _cerrarSesion() async {
    await supabase.auth.signOut();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
    }
  }

  @override
  void dispose() {
    _pesoCtrl.dispose();
    _alturaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.esPrimeraVez ? 'Configura tu perfil' : 'Mi perfil'),
        automaticallyImplyLeading: !widget.esPrimeraVez,
        actions: [
          if (!widget.esPrimeraVez)
            IconButton(
              icon: const Icon(Icons.logout_rounded),
              onPressed: _cerrarSesion,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.bosque))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar y nombre
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 84, height: 84,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.bosque,
                            boxShadow: AppTheme.sombraSuave,
                          ),
                          child: Center(
                            child: Text(
                              (_profile?.nombre.isNotEmpty == true)
                                  ? _profile!.nombre[0].toUpperCase()
                                  : '?',
                              style: Theme.of(context).textTheme.displayMedium
                                  ?.copyWith(color: Colors.white, fontSize: 32),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _profile?.nombre ?? '',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        if (_profile?.imc != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.salvia,
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              'IMC ${_profile!.imc!.toStringAsFixed(1)} · ${_profile!.imcCategoria}',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.bosque,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Medidas
                  Text('MEDIDAS', style: AppTheme.eyebrow),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: TextField(
                        controller: _pesoCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Peso (kg)',
                          prefixIcon: Icon(Icons.monitor_weight_outlined, color: AppTheme.musgo),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _alturaCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Altura (cm)',
                          prefixIcon: Icon(Icons.height_rounded, color: AppTheme.musgo),
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 28),

                  // Padecimientos
                  Text('MIS PADECIMIENTOS', style: AppTheme.eyebrow),
                  const SizedBox(height: 6),
                  const Text(
                    'Selecciona todos los que apliquen',
                    style: TextStyle(color: AppTheme.grisTexto, fontSize: 13),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _todosLosPadecimientos.map((p) {
                      final activo = _seleccionados.contains(p.id);
                      return FilterChip(
                        label: Text(p.label),
                        selected: activo,
                        onSelected: (val) {
                          setState(() {
                            if (val) {
                              _seleccionados.add(p.id);
                            } else {
                              _seleccionados.remove(p.id);
                            }
                          });
                        },
                        backgroundColor: Colors.white,
                        selectedColor: AppTheme.bosque,
                        checkmarkColor: Colors.white,
                        side: BorderSide(color: activo ? AppTheme.bosque : AppTheme.borde),
                        labelStyle: TextStyle(
                          color: activo ? Colors.white : AppTheme.carbon,
                          fontWeight: activo ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 13,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 36),

                  // Botón guardar
                  ElevatedButton(
                    onPressed: _guardando ? null : _guardar,
                    child: _guardando
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Text(widget.esPrimeraVez
                            ? 'Guardar y continuar →'
                            : 'Guardar cambios'),
                  ),
                ],
              ),
            ),
    );
  }
}
