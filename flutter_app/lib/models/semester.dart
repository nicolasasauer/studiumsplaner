import 'lecture.dart';

class Semester {
  final String id;
  int number;
  String season; // 'winter' | 'summer'
  List<Lecture> lectures;

  Semester({
    required this.id,
    required this.number,
    required this.season,
    List<Lecture>? lectures,
  }) : lectures = lectures ?? [];

  factory Semester.fromJson(Map<String, dynamic> json) => Semester(
        id: json['id'] as String,
        number: (json['number'] as num).toInt(),
        season: json['season'] as String,
        lectures: ((json['lectures'] as List<dynamic>?) ?? const [])
            .whereType<Map>()
            .map((l) {
              final lecture = Lecture.fromJson(Map<String, dynamic>.from(l));
              return lecture.semesterId == json['id']
                  ? lecture
                  : lecture.copyWith(semesterId: json['id'] as String);
            })
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'number': number,
        'season': season,
        'lectures': lectures.map((l) => l.toJson()).toList(),
      };

  int get totalEcts => lectures.fold(0, (s, l) => s + l.ects);
  int get passedEcts =>
      lectures.where((l) => l.passed).fold(0, (s, l) => s + l.ects);

  double? averageGrade({bool weightedByEcts = false}) {
    final graded = lectures.where((l) => l.passed && l.grade != null).toList();
    if (graded.isEmpty) return null;
    if (!weightedByEcts) {
      return graded.fold(0.0, (sum, lecture) => sum + lecture.grade!) /
          graded.length;
    }

    final totalWeightedEcts =
        graded.fold<int>(0, (sum, lecture) => sum + lecture.ects);
    if (totalWeightedEcts == 0) return null;

    final weightedTotal = graded.fold<double>(
      0.0,
      (sum, lecture) => sum + (lecture.grade! * lecture.ects),
    );
    return weightedTotal / totalWeightedEcts;
  }
}
