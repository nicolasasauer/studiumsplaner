import 'lecture.dart';
import 'semester.dart';

class StudyPlan {
  String planName;
  int regularSemesters;
  String startSeason; // 'winter' | 'summer'
  bool isConfigured;
  List<Semester> semesters;
  List<Lecture> parkingLot;

  StudyPlan({
    this.planName = 'Mein Studienplan',
    this.regularSemesters = 6,
    this.startSeason = 'winter',
    this.isConfigured = false,
    List<Semester>? semesters,
    List<Lecture>? parkingLot,
  })  : semesters = semesters ?? [],
        parkingLot = parkingLot ?? [];

  factory StudyPlan.fromJson(Map<String, dynamic> json) {
    final semesters = (json['semesters'] as List<dynamic>?)
            ?.whereType<Map>()
            .map((s) => Semester.fromJson(Map<String, dynamic>.from(s)))
            .toList() ??
        [];
    final parkingLot = (json['parkingLot'] as List<dynamic>?)
            ?.whereType<Map>()
            .map((l) => Lecture.fromJson(Map<String, dynamic>.from(l)))
            .toList() ??
        [];
    final inferredConfigured =
        semesters.isNotEmpty || parkingLot.isNotEmpty;

    return StudyPlan(
      planName: json['planName'] as String? ?? 'Mein Studienplan',
      regularSemesters: (json['regularSemesters'] as num?)?.toInt() ?? 6,
      startSeason: json['startSeason'] as String? ?? 'winter',
      isConfigured: json.containsKey('isConfigured')
          ? json['isConfigured'] as bool? ?? inferredConfigured
          : inferredConfigured,
      semesters: semesters,
      parkingLot: parkingLot,
    );
  }

  Map<String, dynamic> toJson() => {
        'planName': planName,
        'regularSemesters': regularSemesters,
        'startSeason': startSeason,
        'isConfigured': isConfigured,
        'semesters': semesters.map((s) => s.toJson()).toList(),
        'parkingLot': parkingLot.map((l) => l.toJson()).toList(),
      };

  bool get isEffectivelyConfigured =>
      isConfigured || semesters.isNotEmpty || parkingLot.isNotEmpty;

  int get totalEcts {
    final semEcts = semesters.fold(0, (s, sem) => s + sem.totalEcts);
    return semEcts + parkingLot.fold(0, (s, l) => s + l.ects);
  }

  int get passedEcts {
    final semPassed = semesters.fold(0, (s, sem) => s + sem.passedEcts);
    return semPassed +
        parkingLot.where((l) => l.passed).fold(0, (s, l) => s + l.ects);
  }

  double? get averageGrade {
    final graded = <Lecture>[];
    for (final sem in semesters) {
      graded.addAll(sem.lectures.where((l) => l.passed && l.grade != null));
    }
    graded.addAll(parkingLot.where((l) => l.passed && l.grade != null));
    if (graded.isEmpty) return null;
    return graded.fold(0.0, (s, l) => s + l.grade!) / graded.length;
  }
}
