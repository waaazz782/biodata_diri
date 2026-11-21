import 'package:flutter/material.dart';

class BiodataPage extends StatelessWidget {
  const BiodataPage({super.key});

  static const _navy = Color(0xFF102A43);
  static const _blue = Color(0xFF2878C8);
  static const _muted = Color(0xFF62758A);
  static final _galleryPhotos = List<String>.generate(47, (index) {
    final number = (index + 1).toString().padLeft(2, '0');
    final extension = number == '18' ? 'png' : 'jpeg';
    return 'assets/images/$number.$extension';
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Biodata Dewa Amriansyah',
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 28, 22, 36),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'PROFIL SISWA',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _blue,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.8,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Center(
                    child: Container(
                      width: 184,
                      height: 184,
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: [
                          BoxShadow(
                            color: _navy.withValues(alpha: 0.13),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(21),
                        child: Image.asset(
                          'assets/images/14.jpeg',
                          fit: BoxFit.cover,
                          semanticLabel: 'Foto Dewa Amriansyah',
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: const Color(0xFFE5EEF8),
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.person,
                                size: 78,
                                color: _blue,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'Dewa Amriansyah',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _navy,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'Biodata diri',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _muted, fontSize: 14),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'INFORMASI PRIBADI',
                    style: TextStyle(
                      color: _muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const _BiodataCard(
                    icon: Icons.person,
                    label: 'Nama',
                    value: 'Dewa Amriansyah',
                  ),
                  const SizedBox(height: 10),
                  const _BiodataCard(
                    icon: Icons.calendar_month,
                    label: 'Tempat dan Tanggal Lahir',
                    value: 'Jember, 05 Maret 2008',
                  ),
                  const SizedBox(height: 10),
                  const _BiodataCard(
                    icon: Icons.sports_esports,
                    label: 'Hobi',
                    value: 'Web & Mobile Development',
                  ),
                  const SizedBox(height: 10),
                  const _BiodataCard(
                    icon: Icons.cake,
                    label: 'Umur',
                    value: '18 Tahun',
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'GALERI FOTO',
                    style: TextStyle(
                      color: _muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final photoWidth = (constraints.maxWidth - 12) / 2;
                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: List<Widget>.generate(
                          _galleryPhotos.length,
                          (index) => SizedBox(
                            width: photoWidth,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: AspectRatio(
                                aspectRatio: 1,
                                child: Image.asset(
                                  _galleryPhotos[index],
                                  fit: BoxFit.cover,
                                  semanticLabel: 'Foto ${index + 1}',
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BiodataCard extends StatelessWidget {
  const _BiodataCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: Colors.white,
      elevation: 2,
      shadowColor: const Color(0xFF102A43).withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF2FB),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: const Color(0xFF2878C8), size: 23),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Color(0xFF62758A),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Color(0xFF102A43),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
