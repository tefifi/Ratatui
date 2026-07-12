import 'package:flutter/material.dart';

import '../styles/app_theme.dart';

/// Fila de estadísticas nutricionales con anillos de progreso, inspirada en
/// tarjetas de apps de fitness: cada nutriente muestra un anillo coloreado
/// cuyo relleno representa el % de un valor de referencia diario aproximado,
/// separados por líneas divisoras finas dentro de una sola tarjeta.
class NutrienteRingRow extends StatelessWidget {
  final double? kcal;
  final double? proteinaG;
  final double? fibraG;

  const NutrienteRingRow({
    super.key,
    required this.kcal,
    required this.proteinaG,
    required this.fibraG,
  });

  // Valores de referencia diaria aproximados, solo para dar contexto visual
  // al llenado del anillo (no son una recomendación médica).
  static const double _refKcal = 2000;
  static const double _refProteina = 50;
  static const double _refFibra = 25;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radioTarjeta),
        border: Border.all(color: AppTheme.borde),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: _NutrienteRing(
              valor: kcal,
              unidad: '',
              label: 'Calorías',
              color: AppTheme.mostaza,
              porcentaje:
                  kcal != null ? (kcal! / _refKcal).clamp(0.04, 1.0) : 0,
            ),
          ),
          const _DivisorVertical(),
          Expanded(
            child: _NutrienteRing(
              valor: proteinaG,
              unidad: 'g',
              label: 'Proteína',
              color: AppTheme.bosque,
              porcentaje: proteinaG != null
                  ? (proteinaG! / _refProteina).clamp(0.04, 1.0)
                  : 0,
            ),
          ),
          const _DivisorVertical(),
          Expanded(
            child: _NutrienteRing(
              valor: fibraG,
              unidad: 'g',
              label: 'Fibra',
              color: AppTheme.musgo,
              porcentaje:
                  fibraG != null ? (fibraG! / _refFibra).clamp(0.04, 1.0) : 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _DivisorVertical extends StatelessWidget {
  const _DivisorVertical();
  @override
  Widget build(BuildContext context) => const SizedBox(
        height: 56,
        child: VerticalDivider(color: AppTheme.borde, thickness: 1, width: 1),
      );
}

class _NutrienteRing extends StatelessWidget {
  final double? valor;
  final String unidad;
  final String label;
  final Color color;
  final double porcentaje;

  const _NutrienteRing({
    required this.valor,
    required this.unidad,
    required this.label,
    required this.color,
    required this.porcentaje,
  });

  @override
  Widget build(BuildContext context) {
    final texto = valor != null
        ? (unidad.isEmpty
            ? valor!.toStringAsFixed(0)
            : '${valor!.toStringAsFixed(1)}$unidad')
        : '-';
    return Column(
      children: [
        SizedBox(
          width: 52,
          height: 52,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 52,
                height: 52,
                child: CircularProgressIndicator(
                  value: porcentaje,
                  strokeWidth: 4.5,
                  strokeCap: StrokeCap.round,
                  backgroundColor: color.withOpacity(0.15),
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
              Text(
                texto,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.carbon,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(label,
            style: const TextStyle(fontSize: 11.5, color: AppTheme.grisTexto)),
      ],
    );
  }
}
