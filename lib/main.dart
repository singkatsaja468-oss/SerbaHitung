
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

void main() {
  runApp(const SerbaHitungApp());
}

class AreaItem {
  String name;
  String shape;
  double area;
  double a;
  double b;
  double c;

  AreaItem(this.name, this.shape, this.area,
      this.a, this.b, this.c);

  Map<String, dynamic> toJson() => {
    'name': name, 'shape': shape, 'area': area,
    'a': a, 'b': b, 'c': c
  };

  factory AreaItem.fromJson(Map<String, dynamic> j) =>
      AreaItem(j['name'], j['shape'],
        (j['area'] as num).toDouble(),
        (j['a'] as num).toDouble(),
        (j['b'] as num).toDouble(),
        (j['c'] as num).toDouble());
}

class Project {
  String name;
  List<AreaItem> areas;

  Project(this.name, this.areas);

  double get total =>
      areas.fold(0, (sum, item) => sum + item.area);

  Map<String, dynamic> toJson() => {
    'name': name,
    'areas': areas.map((e) => e.toJson()).toList()
  };

  factory Project.fromJson(Map<String, dynamic> j) =>
      Project(j['name'],
        (j['areas'] as List)
          .map((e) => AreaItem.fromJson(e)).toList());
}

class SerbaHitungApp extends StatelessWidget {
  const SerbaHitungApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SerbaHitung',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xfff5f6fa),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Project> projects = [];
  int selected = 0;
  bool loading = true;

  Project? get project =>
      projects.isEmpty ? null : projects[selected];

  @override
  void initState() {
    super.initState();
    loadProjects();
  }

  Future<void> loadProjects() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('serbahitung_projects');
    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List;
        projects = list.map((e) =>
          Project.fromJson(e)).toList();
      } catch (_) {}
    }
    if (projects.isEmpty) {
      projects.add(Project('Proyek Pertama', []));
    }
    setState(() => loading = false);
    saveProjects();
  }

  Future<void> saveProjects() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'serbahitung_projects',
      jsonEncode(projects.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> addProject() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Buat proyek baru'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Nama proyek',
            hintText: 'Contoh: Rumah Pak Budi',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              ctx, controller.text.trim()),
            child: const Text('Buat'),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      setState(() {
        projects.add(Project(name, []));
        selected = projects.length - 1;
      });
      saveProjects();
    }
  }

  Future<void> addArea() async {
    final name = TextEditingController();
    final a = TextEditingController();
    final b = TextEditingController();
    final c = TextEditingController();
    String shape = 'Persegi panjang';

    final result = await showDialog<AreaItem>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, refresh) => AlertDialog(
          title: const Text('Tambah area'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  decoration: const InputDecoration(
                    labelText: 'Nama ruangan',
                    hintText: 'Contoh: Kamar tidur',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: shape,
                  decoration: const InputDecoration(
                    labelText: 'Bentuk area',
                  ),
                  items: [
                    'Persegi',
                    'Persegi panjang',
                    'Segitiga',
                    'Trapesium',
                    'Lingkaran',
                  ].map((s) => DropdownMenuItem(
                    value: s, child: Text(s),
                  )).toList(),
                  onChanged: (v) =>
                    refresh(() => shape = v!),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: a,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: shape == 'Lingkaran'
                      ? 'Jari-jari (meter)'
                      : shape == 'Trapesium'
                        ? 'Sisi sejajar pertama (meter)'
                        : 'Panjang / alas (meter)',
                  ),
                ),
                if (shape != 'Lingkaran')
                  TextField(
                    controller: b,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: shape == 'Trapesium'
                        ? 'Sisi sejajar kedua (meter)'
                        : shape == 'Persegi'
                          ? 'Tidak diperlukan untuk persegi'
                          : 'Lebar / tinggi (meter)',
                    ),
                  ),
                if (shape == 'Trapesium')
                  TextField(
                    controller: c,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Tinggi trapesium (meter)',
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  shape == 'Trapesium'
                    ? 'Luas = (sisi 1 + sisi 2) × tinggi ÷ 2'
                    : shape == 'Segitiga'
                      ? 'Luas = alas × tinggi ÷ 2'
                      : shape == 'Lingkaran'
                        ? 'Luas = 3,14 × jari-jari²'
                        : 'Luas = panjang × lebar',
                  style: const TextStyle(
                    fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                final x = double.tryParse(
                  a.text.replaceAll(',', '.')) ?? 0;
                final y = double.tryParse(
                  b.text.replaceAll(',', '.')) ?? 0;
                final z = double.tryParse(
                  c.text.replaceAll(',', '.')) ?? 0;
                double area = 0;

                if (shape == 'Lingkaran' && x > 0) {
                  area = 3.141592653589793 * x * x;
                } else if (shape == 'Persegi' && x > 0) {
                  area = x * x;
                } else if (shape == 'Persegi panjang'
                    && x > 0 && y > 0) {
                  area = x * y;
                } else if (shape == 'Segitiga'
                    && x > 0 && y > 0) {
                  area = x * y / 2;
                } else if (shape == 'Trapesium'
                    && x > 0 && y > 0 && z > 0) {
                  area = (x + y) * z / 2;
                }

                if (area <= 0) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text('Periksa ukuran yang dimasukkan'),
                    ),
                  );
                  return;
                }

                Navigator.pop(ctx, AreaItem(
                  name.text.trim().isEmpty
                    ? 'Area baru' : name.text.trim(),
                  shape, area, x, y, z,
                ));
              },
              child: const Text('Hitung'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      setState(() => project!.areas.add(result));
      saveProjects();
    }
  }

  Future<void> exportPdf() async {
    if (project == null) return;
    final doc = pw.Document();
    final p = project!;

    doc.addPage(pw.MultiPage(
      build: (ctx) => [
        pw.Text('LAPORAN SERBAHITUNG',
          style: pw.TextStyle(
            fontSize: 22, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.Text('Nama proyek: ${p.name}'),
        pw.Text('Tanggal: ${DateTime.now().toString().substring(0, 10)}'),
        pw.SizedBox(height: 20),
        pw.TableHelper.fromTextArray(
          headers: ['No', 'Nama area', 'Bentuk', 'Luas (m2)'],
          data: [
            for (int i = 0; i < p.areas.length; i++)
              [
                '${i + 1}',
                p.areas[i].name,
                p.areas[i].shape,
                p.areas[i].area.toStringAsFixed(2),
              ]
          ],
        ),
        pw.SizedBox(height: 20),
        pw.Text('TOTAL LUAS: ${p.total.toStringAsFixed(2)} m2',
          style: pw.TextStyle(
            fontSize: 18, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 12),
        pw.Text('Catatan: Hasil perhitungan berdasarkan ukuran yang dimasukkan.'),
      ],
    ));

    await Printing.layoutPdf(
      onLayout: (format) async => doc.save(),
    );
  }

  void deleteArea(int index) {
    setState(() => project!.areas.removeAt(index));
    saveProjects();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final p = project!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SerbaHitung',
          style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            tooltip: 'Laporan PDF',
            onPressed: exportPdf,
            icon: const Icon(Icons.picture_as_pdf),
          ),
          IconButton(
            tooltip: 'Proyek baru',
            onPressed: addProject,
            icon: const Icon(Icons.create_new_folder),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: addArea,
        icon: const Icon(Icons.add),
        label: const Text('Tambah area'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<int>(
            value: selected,
            decoration: const InputDecoration(
              labelText: 'Pilih proyek',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.folder),
            ),
            items: [
              for (int i = 0; i < projects.length; i++)
                DropdownMenuItem(
                  value: i,
                  child: Text(projects[i].name),
                )
            ],
            onChanged: (v) =>
              setState(() => selected = v ?? 0),
          ),
          const SizedBox(height: 16),
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('TOTAL LUAS PROYEK'),
                  const SizedBox(height: 8),
                  Text(
                    '${p.total.toStringAsFixed(2)} m²',
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text('${p.areas.length} area tercatat'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Denah skematis',
                style: TextStyle(
                  fontSize: 19, fontWeight: FontWeight.bold)),
              const Text('Tidak berdasarkan skala',
                style: TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.indigo, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: p.areas.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Text('Tambahkan area untuk melihat denah'),
                  ),
                )
              : Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final item in p.areas)
                      Container(
                        width: 105,
                        height: 76,
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.indigo.shade50,
                          border: Border.all(color: Colors.indigo),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.meeting_room, size: 19),
                            Text(item.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold)),
                            Text('${item.area.toStringAsFixed(1)} m²',
                              style: const TextStyle(fontSize: 10)),
                          ],
                        ),
                      ),
                  ],
                ),
          ),
          const SizedBox(height: 20),
          const Text('Daftar area',
            style: TextStyle(
              fontSize: 19, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (p.areas.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Center(
                  child: Text('Belum ada area. Tekan Tambah area.'),
                ),
              ),
            ),
          for (int i = 0; i < p.areas.length; i++)
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  child: Text('${i + 1}')),
                title: Text(p.areas[i].name),
                subtitle: Text(
                  '${p.areas[i].shape} • ${p.areas[i].area.toStringAsFixed(2)} m²'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => deleteArea(i),
                ),
              ),
            ),
          const SizedBox(height: 90),
        ],
      ),
    );
  }
}
