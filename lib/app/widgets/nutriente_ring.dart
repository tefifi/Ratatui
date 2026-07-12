import 'package:flutter/material.dart';

import '../styles/app_theme.dart';

/// Fila de estadísticas nutricionales con anillos de progreso, inspirada en
/// tarjetas de apps de fitness: cada nutriente muestra un anillo coloreado
/// cuyo relleno representa el % de un valor de referencia diario aproximado,
/// separados por líneas divisoras finas.
///
/// [sobreImagen] cambia la variante visual: tarjeta blanca con borde (uso
/// normal, ej. detalle de receta) o versión flotante translúcida con texto
/// blanco, pensada para superponerse directamente sobre una fotografía.
class NutrienteRingRow extends StatelessWidget {
  final double? kcal;
  final double? proteinaG;
  final double? fibraG;
  final bool sobreImagen;

  const NutrienteRingRow({
    super.key,
    required this.kcal,
    required this.proteinaG,
    required this.fibraG,
    this.sobreImagen = false,
  });

  // Valores de referencia diaria aproximados, solo para dar contexto visual
  // al llenado del anillo (no son una recomendación médica).
  static const double _refKcal = 2000;
  static const double _refProteina = 50;
  static const double _refFibra = 25;

  @override
  Widget build(BuildContext context) {
    final contenido = Row(
      children: [
        Expanded(
          child: _NutrienteRing(
            valor: kcal,
            unidad: '',
            label: 'Calorías',
            color: sobreImagen ? AppTheme.mostaza : AppTheme.mostaza,
            porcentaje: kcal != null ? (kcal! / _refKcal).clamp(0.04, 1.0) : 0,
            sobreImagen: sobreImagen,
          ),
        ),
        _DivisorVertical(sobreImagen: sobreImagen),
        Expanded(
          child: _NutrienteRing(
            valor: proteinaG,
            unidad: 'g',
            label: 'Proteína',
            color: sobreImagen ? const Color(0xFF8FD9B6) : AppTheme.bosque,
            porcentaje: proteinaG != null
                ? (proteinaG! / _refProteina).clamp(0.04, 1.0)
                : 0,
            sobreImagen: sobreImagen,
          ),
        ),
        _DivisorVertical(sobreImagen: sobreImagen),
        Expanded(
          child: _NutrienteRing(
            valor: fibraG,
            unidad: 'g',
            label: 'Fibra',
            color: sobreImagen ? const Color(0xFFBFE28A) : AppTheme.musgo,
            porcentaje:
                fibraG != null ? (fibraG! / _refFibra).clamp(0.04, 1.0) : 0,
            sobreImagen: sobreImagen,
          ),
        ),
      ],
    );

    if (!sobreImagen) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radioTarjeta),
          border: Border.all(color: AppTheme.borde),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: contenido,
      );
    }

    // Variante flotante translúcida sobre imagen (estilo "vidrio esmerilado").
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.28),
        borderRadius: BorderRadius.circular(AppTheme.radioChico),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: contenido,
    );
  }
}

class _DivisorVertical extends StatelessWidget {
  final bool sobreImagen;
  const _DivisorVertical({required this.sobreImagen});
  @override
  Widget build(BuildContext context) => SizedBox(
        height: sobreImagen ? 46 : 56,
        child: VerticalDivider(
          color: sobreImagen ? Colors.white.withOpacity(0.25) : AppTheme.borde,
          thickness: 1,
          width: 1,
        ),
      );
}

class _NutrienteRing extends StatelessWidget {
  final double? valor;
  final String unidad;
  final String label;
  final Color color;
  final double porcentaje;
  final bool sobreImagen;

  const _NutrienteRing({
    required this.valor,
    required this.unidad,
    required this.label,
    required this.color,
    required this.porcentaje,
    required this.sobreImagen,
  });

  @override
  Widget build(BuildContext context) {
    final texto = valor != null
        ? (unidad.isEmpty
            ? valor!.toStringAsFixed(0)
            : '${valor!.toStringAsFixed(1)}$unidad')
        : '-';
    final size = sobreImagen ? 44.0 : 52.0;
    return Column(
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: size,
                height: size,
                child: CircularProgressIndicator(
                  value: porcentaje,
                  strokeWidth: 4,
                  strokeCap: StrokeCap.round,
                  backgroundColor: sobreImagen
                      ? Colors.white.withOpacity(0.25)
                      : color.withOpacity(0.15),
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
              Text(
                texto,
                style: TextStyle(
                  fontSize: sobreImagen ? 10.5 : 11.5,
                  fontWeight: FontWeight.w800,
                  color: sobreImagen ? Colors.white : AppTheme.carbon,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            color: sobreImagen
                ? Colors.white.withOpacity(0.85)
                : AppTheme.grisTexto,
          ),
        ),
      ],
    );
  }
}
