class Receta {
  final int spoonacularId;
  final String nombre;
  final String imagenUrl;
  final double? kcal;
  final double? proteinaG;
  final double? fibraG;
  final List<String> ingredientes;
  final String? instrucciones;
  bool esFavorito;

  Receta({
    required this.spoonacularId,
    required this.nombre,
    required this.imagenUrl,
    this.kcal,
    this.proteinaG,
    this.fibraG,
    this.ingredientes = const [],
    this.instrucciones,
    this.esFavorito = false,
  });

  // CORREGIDO: el dominio real es img.spoonacular.com/recipes/
  // complexSearch devuelve solo el nombre de archivo, detail devuelve URL completa
  static String _buildImageUrl(String raw) {
    if (raw.isEmpty) return '';
    if (raw.startsWith('http')) return raw;
    return 'https://img.spoonacular.com/recipes/$raw';
  }

  factory Receta.fromSpoonacularSearch(Map<String, dynamic> map) {
      final rawImage = map['image'] as String? ?? '';
  print('IMAGE RAW: $rawImage'); // ← agrega esto
    double? getNutrient(String name) {
      final nutrients =
          (map['nutrition']?['nutrients'] as List<dynamic>?) ?? [];
      final match = nutrients.firstWhere(
        (n) => (n['name'] as String).toLowerCase() == name.toLowerCase(),
        orElse: () => null,
      );
      return match != null ? (match['amount'] as num?)?.toDouble() : null;
    }

    return Receta(
      spoonacularId: map['id'] as int,
      nombre: map['title'] as String,
      imagenUrl: _buildImageUrl(map['image'] as String? ?? ''),
      kcal: getNutrient('Calories'),
      proteinaG: getNutrient('Protein'),
      fibraG: getNutrient('Fiber'),
    );
  }

  factory Receta.fromSpoonacularDetail(Map<String, dynamic> map) {
    double? getNutrient(String name) {
      final nutrients =
          (map['nutrition']?['nutrients'] as List<dynamic>?) ?? [];
      final match = nutrients.firstWhere(
        (n) => (n['name'] as String).toLowerCase() == name.toLowerCase(),
        orElse: () => null,
      );
      return match != null ? (match['amount'] as num?)?.toDouble() : null;
    }

    final ingredientes = (map['extendedIngredients'] as List<dynamic>? ?? [])
        .map((i) => i['original'] as String)
        .toList();

    final stepsRaw =
        (map['analyzedInstructions'] as List<dynamic>?)?.firstOrNull;
    String instrucciones = '';
    if (stepsRaw != null) {
      final steps = stepsRaw['steps'] as List<dynamic>? ?? [];
      instrucciones =
          steps.map((s) => '${s['number']}. ${s['step']}').join('\n');
    }

    return Receta(
      spoonacularId: map['id'] as int,
      nombre: map['title'] as String,
      imagenUrl: map['image'] as String? ?? '',
      kcal: getNutrient('Calories'),
      proteinaG: getNutrient('Protein'),
      fibraG: getNutrient('Fiber'),
      ingredientes: ingredientes,
      instrucciones: instrucciones,
    );
  }

  factory Receta.fromFavoritoMap(Map<String, dynamic> map) => Receta(
        spoonacularId: map['spoonacular_id'] as int,
        nombre: map['nombre_receta'] as String? ?? '',
        imagenUrl: map['imagen_url'] as String? ?? '',
        kcal: (map['kcal'] as num?)?.toDouble(),
        proteinaG: (map['proteina_g'] as num?)?.toDouble(),
        fibraG: (map['fibra_g'] as num?)?.toDouble(),
        esFavorito: true,
      );

  Map<String, dynamic> toFavoritoMap(String usuarioId) => {
        'usuario_id': usuarioId,
        'spoonacular_id': spoonacularId,
        'nombre_receta': nombre,
        'imagen_url': imagenUrl,
        if (kcal != null) 'kcal': kcal,
        if (proteinaG != null) 'proteina_g': proteinaG,
        if (fibraG != null) 'fibra_g': fibraG,
      };
}