import 'student_profile.dart';

StudentProfile studentByNumber(int number) {
  return studentProfiles.firstWhere((student) => student.number == number);
}

class ClassDaySchedule {
  const ClassDaySchedule({
    required this.day,
    required this.subjects,
    required this.picketNumbers,
  });

  final String day;
  final List<String> subjects;
  final List<int> picketNumbers;

  Map<String, dynamic> toJson() => {
    'day': day,
    'subjects': subjects,
    'picketNumbers': picketNumbers,
  };

  factory ClassDaySchedule.fromJson(Map<String, dynamic> json) =>
      ClassDaySchedule(
        day: json['day'] as String,
        subjects: List<String>.from(json['subjects'] as List<dynamic>),
        picketNumbers: List<int>.from(json['picketNumbers'] as List<dynamic>),
      );

  ClassDaySchedule copyWith({
    List<String>? subjects,
    List<int>? picketNumbers,
  }) => ClassDaySchedule(
    day: day,
    subjects: subjects ?? this.subjects,
    picketNumbers: picketNumbers ?? this.picketNumbers,
  );
}

const classDaySchedules = <ClassDaySchedule>[
  ClassDaySchedule(
    day: 'Senin',
    subjects: ['Upacara', 'Kejuruan RPL', 'Mobile Programming'],
    picketNumbers: [13, 17, 20, 32, 41, 18, 19, 5, 10, 46],
  ),
  ClassDaySchedule(
    day: 'Selasa',
    subjects: ['Mobile Programming', 'Bahasa Indonesia', 'Matematika'],
    picketNumbers: [1, 15, 16, 25, 33, 42, 44, 47, 36, 35],
  ),
  ClassDaySchedule(
    day: 'Rabu',
    subjects: ['Kejuruan RPL', 'PPKN', 'Matematika'],
    picketNumbers: [2, 3, 4, 7, 14, 23, 24, 28],
  ),
  ClassDaySchedule(
    day: 'Kamis',
    subjects: ['Kejuruan RPL', 'Bahasa Inggris', 'Agama'],
    picketNumbers: [6, 8, 9, 45, 40, 43, 37, 38, 39],
  ),
  ClassDaySchedule(
    day: 'Jumat',
    subjects: [
      'Bahasa Inggris',
      'PKK (Produk Kreatif dan Kewirausahaan)',
      'Kejuruan RPL',
    ],
    picketNumbers: [34, 11, 12, 21, 22, 26, 29, 30, 27, 31],
  ),
];

const waliKelasName = 'Bayu Ragiel Pamungkas, S.Kom';
const waliKelasPhoto = 'assets/images/prabowo.jpg';

const ketuaKelasNumber = 25;
const wakilKelasNumber = 9;
const sekretarisNumbers = [42, 33];
const bendaharaNumbers = [45, 40];
