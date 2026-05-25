class Profile {
  final String id;
  final String nombre;
  final double? pesoKg;
  final double? alturaCm;
  final double? imc;

  const Profile({
    required this.id,
    required this.nombre,
    this.pesoKg,
    this.alturaCm,
    this.imc,
  });

  String get imcCategoria {
    if (imc == null) return 'Sin calcular';
    if (imc! < 18.5) return 'Bajo peso';
    if (imc! < 25.0) return 'Normal';
    if (imc! < 30.0) return 'Sobrepeso';
    return 'Obesidad';
  }

  Profile copyWith({String? nombre, double? pesoKg, double? alturaCm}) {
    return Profile(
      id: id,
      nombre: nombre ?? this.nombre,
      pesoKg: pesoKg ?? this.pesoKg,
      alturaCm: alturaCm ?? this.alturaCm,
      imc: imc,
    );
  }

  factory Profile.fromMap(Map<String, dynamic> map) => Profile(
        id: map['id'] as String,
        nombre: map['nombre'] as String,
        pesoKg: (map['peso_kg'] as num?)?.toDouble(),
        alturaCm: (map['altura_cm'] as num?)?.toDouble(),
        imc: (map['imc'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'nombre': nombre,
        if (pesoKg != null) 'peso_kg': pesoKg,
        if (alturaCm != null) 'altura_cm': alturaCm,
      };
}
