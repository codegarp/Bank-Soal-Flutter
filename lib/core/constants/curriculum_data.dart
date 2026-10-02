class CurriculumData {
  static const List<String> curriculums = [
    'Kurikulum Merdeka',
    'Kurikulum 2013 (K13 Revisi)',
  ];

  static const List<String> educationLevels = [
    'SD / MI (Sekolah Dasar)',
    'SMP / MTs (Sekolah Menengah Pertama)',
    'SMA / MA (Sekolah Menengah Atas)',
    'SMK (Sekolah Menengah Kejuruan)',
  ];

  static const Map<String, List<String>> gradesByLevel = {
    'SD / MI (Sekolah Dasar)': [
      'Kelas 1 (Fase A)',
      'Kelas 2 (Fase A)',
      'Kelas 3 (Fase B)',
      'Kelas 4 (Fase B)',
      'Kelas 5 (Fase C)',
      'Kelas 6 (Fase C)',
    ],
    'SMP / MTs (Sekolah Menengah Pertama)': [
      'Kelas 7 (Fase D)',
      'Kelas 8 (Fase D)',
      'Kelas 9 (Fase D)',
    ],
    'SMA / MA (Sekolah Menengah Atas)': [
      'Kelas 10 (Fase E)',
      'Kelas 11 (Fase F)',
      'Kelas 12 (Fase F)',
    ],
    'SMK (Sekolah Menengah Kejuruan)': [
      'Kelas 10 (Fase E)',
      'Kelas 11 (Fase F)',
      'Kelas 12 (Fase F)',
    ],
  };

  static const Map<String, List<String>> subjectsByLevel = {
    'SD / MI (Sekolah Dasar)': [
      'Matematika',
      'Bahasa Indonesia',
      'Ilmu Pengetahuan Alam & Sosial (IPAS)',
      'Pendidikan Pancasila / PPKn',
      'Pendidikan Agama Islam & Budi Pekerti',
      'Pendidikan Agama Kristen & Budi Pekerti',
      'Bahasa Inggris',
      'Seni Rupa & Seni Musik',
      'PJOK (Pendidikan Jasmani)',
    ],
    'SMP / MTs (Sekolah Menengah Pertama)': [
      'Matematika',
      'IPA (Ilmu Pengetahuan Alam)',
      'IPS (Ilmu Pengetahuan Sosial)',
      'Bahasa Indonesia',
      'Bahasa Inggris',
      'Pendidikan Pancasila / PPKn',
      'Informatika',
      'Pendidikan Agama Islam & Budi Pekerti',
      'Pendidikan Agama Kristen & Budi Pekerti',
      'Seni Budaya',
      'PJOK',
      'Prakarya',
    ],
    'SMA / MA (Sekolah Menengah Atas)': [
      'Matematika Umum',
      'Matematika Tingkat Lanjut',
      'Fisika',
      'Kimia',
      'Biologi',
      'Bahasa Indonesia',
      'Bahasa Inggris',
      'Ekonomi',
      'Geografi',
      'Sosiologi',
      'Sejarah',
      'Pendidikan Pancasila / PPKn',
      'Informatika',
      'Pendidikan Agama Islam & Budi Pekerti',
      'Seni Budaya',
      'PJOK',
    ],
    'SMK (Sekolah Menengah Kejuruan)': [
      'Matematika Terapan',
      'Bahasa Indonesia',
      'Bahasa Inggris',
      'Dasar-Dasar Teknik Informatika / RPL',
      'Dasar-Dasar Teknik Mesin',
      'Dasar-Dasar Akuntansi & Keuangan',
      'Dasar-Dasar Desain Komunikasi Visual',
      'Pendidikan Pancasila / PPKn',
      'Projek IPAS',
      'Pendidikan Agama Islam',
      'Produk Kreatif & Kewirausahaan (PKK)',
    ],
  };

  static const List<String> questionTypes = [
    'Pilihan Ganda (PG)',
    'Uraian / Essay',
    'Isian Singkat',
    'Kombinasi (Pilihan Ganda & Essay)',
  ];

  static const List<String> difficultyLevels = [
    'Mudah (LOTS - Mengingat & Memahami)',
    'Sedang (MOTS - Menerapkan & Menganalisis)',
    'Sulit (HOTS - Evaluasi & Kreasi)',
    'Campuran Proporsional (30% Mudah, 50% Sedang, 20% Sulit)',
  ];

  static const List<int> questionCountOptions = [
    5,
    10,
    15,
    20,
    25,
    30,
    35,
    40,
    50,
  ];

  // Example topic suggestions for popular subjects
  static const Map<String, List<String>> suggestedTopics = {
    'Matematika': [
      'Aljabar & Persamaan Linear',
      'Teorema Pythagoras',
      'Trigonometri',
      'Statistika & Peluang',
      'Bangun Datar & Bangun Ruang',
      'Pecahan & Bilangan Bulat',
      'Matriks & Vektor',
      'Kalkulus & Turunan',
    ],
    'IPA (Ilmu Pengetahuan Alam)': [
      'Sistem Pencernaan Manusia',
      'Sistem Peredaran Darah',
      'Hukum Newton tentang Gerak',
      'Listrik Dinamis & Hukum Ohm',
      'Tata Surya & Karakteristik Planet',
      'Fotosintesis & Struktur Tumbuhan',
      'Kemagnetan & Induksi Elektromagnetik',
    ],
    'Fisika': [
      'Kinematika Gerak Lurus',
      'Dinamika Partikel & Gaya Gesek',
      'Usaha, Energi, & Daya',
      'Fluida Statis & Dinamis',
      'Termodinamika',
      'Gelombang Bunyi & Cahaya',
      'Fisika Modern & Relativitas',
    ],
    'Kimia': [
      'Struktur Atom & Tabel Periodik',
      'Ikatan Kimia & Bentuk Molekul',
      'Stoikiometri & Konsep Mol',
      'Larutan Asam Basa & pH',
      'Termokimia & Entalpi',
      'Laju Reaksi & Kesetimbangan',
      'Kimia Karbon & Polimer',
    ],
    'Biologi': [
      'Sel & Organel Sel',
      'Genetika & Hukum Mendel',
      'Evolusi & Mutasi',
      'Ekosistem & Interaksi Makhluk Hidup',
      'Bioteknologi Konvensional & Modern',
      'Sistem Imun & Pertahanan Tubuh',
    ],
    'Bahasa Indonesia': [
      'Teks Laporan Hasil Observasi (LHO)',
      'Teks Eksplanasi & Kaidah Kebahasaan',
      'Teks Prosedur Kompleks',
      'Cerita Pendek (Unsur Intrinsik & Ekstrinsik)',
      'Surat Resmi & Surat Lamaran Pekerjaan',
      'Kritik & Esai Sastra',
      'Kalimat Efektif & Ejaan EYD V',
    ],
    'Bahasa Inggris': [
      'Narrative Text & Moral Values',
      'Procedure Text & Connectives',
      'Analytical Exposition Text',
      'Simple Past vs Present Perfect Tense',
      'Conditional Sentences (Type 1, 2, 3)',
      'Passive Voice in Scientific Context',
      'Formal & Informal Letters / Emails',
    ],
    'Ilmu Pengetahuan Alam & Sosial (IPAS)': [
      'Wujud Zat dan Perubahannya',
      'Gaya di Sekitar Kita',
      'Indonesiaku Kaya Hayati',
      'Kearifan Lokal Nusantara',
      'Kenampakan Alam dan Peta Wilayah',
      'Norma dan Adat Istiadat',
    ],
  };
}
