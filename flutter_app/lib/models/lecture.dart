class Lecture {
  final String id;
  String name;
  int ects;
  String? examDate; // YYYY-MM-DD
  String season; // 'winter' | 'summer' | 'both'
  String description;
  String color; // hex, e.g. '#FF6B6B'
  String? semesterId;
  bool passed;
  double? grade;
  bool oralExam;

  Lecture({
    required this.id,
    required this.name,
    required this.ects,
    this.examDate,
    required this.season,
    this.description = '',
    required this.color,
    this.semesterId,
    this.passed = false,
    this.grade,
    this.oralExam = false,
  });

  factory Lecture.fromJson(Map<String, dynamic> json) => Lecture(
        id: json['id'] as String,
        name: json['name'] as String,
        ects: (json['ects'] as num).toInt(),
        examDate: json['examDate'] as String?,
        season: json['season'] as String? ?? 'both',
        description: json['description'] as String? ?? '',
        color: json['color'] as String? ?? '#4ECDC4',
        semesterId: json['semesterId'] as String?,
        passed: json['passed'] as bool? ?? false,
        grade:
            json['grade'] != null ? (json['grade'] as num).toDouble() : null,
        oralExam: json['oralExam'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'ects': ects,
        'examDate': examDate,
        'season': season,
        'description': description,
        'color': color,
        'semesterId': semesterId,
        'passed': passed,
        'grade': grade,
        'oralExam': oralExam,
      };

  // Sentinel object used to distinguish "not provided" from null in copyWith
  static const _keep = Object();

  Lecture copyWith({
    String? id,
    String? name,
    int? ects,
    Object? examDate = _keep,
    String? season,
    String? description,
    String? color,
    Object? semesterId = _keep,
    bool? passed,
    Object? grade = _keep,
    bool? oralExam,
  }) =>
      Lecture(
        id: id ?? this.id,
        name: name ?? this.name,
        ects: ects ?? this.ects,
        examDate: examDate == _keep ? this.examDate : examDate as String?,
        season: season ?? this.season,
        description: description ?? this.description,
        color: color ?? this.color,
        semesterId:
            semesterId == _keep ? this.semesterId : semesterId as String?,
        passed: passed ?? this.passed,
        grade: grade == _keep ? this.grade : grade as double?,
        oralExam: oralExam ?? this.oralExam,
      );
}
