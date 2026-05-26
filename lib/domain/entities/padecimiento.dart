class Padecimiento {
  final int id;
  final String nombre;
  final String label;

  const Padecimiento({
    required this.id,
    required this.nombre,
    required this.label,
  });

  String? get spoonacularIntolerance => const {
        'intolerante_lactosa': 'dairy',
        'celiaco': 'gluten',
      }[nombre];

  String? get spoonacularDiet => const {
        'vegano': 'vegan',
        'vegetariano': 'vegetarian',
      }[nombre];

  // Padecimientos que Spoonacular no tiene como intolerance/diet,
  // se filtran vía el parámetro `query` de complexSearch.
  String? get spoonacularQuery => const {
        'diabetes_tipo2': 'healthy low sugar',
        'hipertension': 'low sodium',
        'hipotiroidismo': 'healthy',
      }[nombre];

  factory Padecimiento.fromMap(Map<String, dynamic> map) => Padecimiento(
        id: map['id'] as int,
        nombre: map['nombre'] as String,
        label: map['label'] as String,
      );
}
