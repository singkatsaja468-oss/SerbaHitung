import 'dark:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:convert';

void main() {
  runApp(const SerbaHitungApp());
}

class SerbaHitungApp extends StatelessWidget {
  const SerbaHitungApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SerbaHitung',
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class AreaItem {
  String name;
  double value;

  AreaItem(this.name, this.value);

  Map<String, dynamic> toJson() =>
      {'name': name, 'value': value};
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<AreaItem> areas = [];
  final nameController = TextEditingController();
  final aController = TextEditingController();
  final bController = TextEditingController();
  String shape = 'Persegi panjang';

  double get total =>
      areas.fold(0, (sum, item) => sum + item.value);

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('areas');
    if (data != null) {
      final list = jsonDecode(data) as List;
      setState(() {
        areas.addAll(list.map((e) =>
          AreaItem(e['name'], (e['value'] as num).toDouble())));
      });
    }
  }

  Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'areas',
      jsonEncode(areas.map((e) => e.toJson()).toList()),
    );
  }

  void addArea() {
    final a = double.tryParse(aController.text) ?? 0;
    final b = double.tryParse(bController.text) ?? 0;
    if (a <= 0 || b <= 0) return;

    double result;
    if (shape == 'Segitiga') {
      result = a * b / 2;
    } else if (shape == 'Trapesium') {
      result = (a + b) * 0.5;
    } else {
      result = a * b;
    }

    setState(() {
      areas.add(AreaItem(
        nameController.text.isEmpty
            ? 'Area ${areas.length + 1}'
            : nameController.text,
        result,
      ));
    });

    nameController.clear();
    aController.clear();
    bController.clear();
    saveData();
  }

  Future<void> exportPdf() async {
    final doc = pw.Document();
    doc.addPage(pw.Page(
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Laporan SerbaHitung',
              style: pw.TextStyle(fontSize: 22)),
          pw.SizedBox(height: 16),
          ...areas.map((e) => pw.Text(
            '${e.name}: ${e.value.toStringAsFixed(2)} m2')),
          pw.Divider(),
          pw.Text('Total: ${total.toStringAsFixed(2)} m2'),
        ],
      ),
    ));
    await Printing.layoutPdf(
      onLayout: (format) async => doc.save(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SerbaHitung'),
        actions: [
          IconButton(
            onPressed: exportPdf,
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Buat PDF',
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text('TOTAL LUAS',
                      style: TextStyle(fontSize: 16)),
                  Text(
                    '${total.toStringAsFixed(2)} m²',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Tambah perhitungan',
              style: TextStyle(fontSize: 20,
                  fontWeight: FontWeight.bold)),
          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Nama ruangan / area',
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: shape,
            decoration: const InputDecoration(
              labelText: 'Bentuk area',
            ),
            items: [
              'Persegi panjang',
              'Segitiga',
              'Trapesium'
            ].map((s) => DropdownMenuItem(
              value: s, child: Text(s),
            )).toList(),
            onChanged: (v) =>
                setState(() => shape = v!),
          ),
          TextField(
            controller: aController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Panjang / sisi A (meter)',
            ),
          ),
          TextField(
            controller: bController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Lebar / sisi B (meter)',
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: addArea,
            icon: const Icon(Icons.add),
            label: const Text('Hitung dan simpan area'),
          ),
          const SizedBox(height: 20),
          const Text('Daftar area',
              style: TextStyle(fontSize: 20,
                  fontWeight: FontWeight.bold)),
          ...areas.asMap().entries.map((entry) {
            final i = entry.key;
            final item = entry.value;
            return Card(
              child: ListTile(
                title: Text(item.name),
                subtitle: Text(
                  '${item.value.toStringAsFixed(2)} m²'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    setState(() => areas.removeAt(i));
                    saveData();
                  },
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
