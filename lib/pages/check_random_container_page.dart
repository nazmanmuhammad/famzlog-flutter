import 'package:flutter/material.dart';
import 'package:famzlog_flutter/models/check_random_container.dart';
import 'package:famzlog_flutter/services/check_random_container_service.dart';
import 'package:famzlog_flutter/pages/check_random_container_form_page.dart';
import 'package:famzlog_flutter/widgets/modern_snackbar.dart';
import 'package:intl/intl.dart';

class CheckRandomContainerPage extends StatefulWidget {
  const CheckRandomContainerPage({super.key});

  @override
  State<CheckRandomContainerPage> createState() =>
      _CheckRandomContainerPageState();
}

class _CheckRandomContainerPageState extends State<CheckRandomContainerPage> {
  List<CheckRandomContainer> _records = [];
  CheckRandomContainerStatistics? _statistics;
  bool _loading = true;
  String? _selectedDate;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        CheckRandomContainerService.fetchRecords(
          search: _searchController.text.isNotEmpty ? _searchController.text : null,
          date: _selectedDate,
        ),
        CheckRandomContainerService.fetchStatistics(date: _selectedDate),
      ]);

      if (mounted) {
        setState(() {
          _records = results[0] as List<CheckRandomContainer>;
          _statistics = results[1] as CheckRandomContainerStatistics;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        showModernSnackBar(context,
            title: 'Error', message: e.toString().replaceAll('Exception: ', ''), success: false);
      }
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          _selectedDate != null ? DateTime.parse(_selectedDate!) : DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() =>
          _selectedDate = DateFormat('yyyy-MM-dd').format(picked));
      _loadData();
    }
  }

  Future<void> _deleteRecord(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: const Text('Yakin ingin menghapus data ini?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child:
                const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await CheckRandomContainerService.deleteRecord(id);
        if (mounted) {
          showModernSnackBar(context,
              title: 'Berhasil',
              message: 'Data berhasil dihapus',
              success: true);
          _loadData();
        }
      } catch (e) {
        if (mounted) {
          showModernSnackBar(context,
              title: 'Error', message: e.toString(), success: false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C84C2),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Check Random Container',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Stats
          if (_statistics != null)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _statCard(
                      'Total Container',
                      NumberFormat('#,###', 'id_ID')
                          .format(_statistics!.totalContainers),
                      const Color(0xFF1C84C2),
                      Icons.inventory,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _statCard(
                      'Total Koli',
                      NumberFormat('#,###', 'id_ID')
                          .format(_statistics!.totalKoli),
                      Colors.orange,
                      Icons.inventory_2,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _statCard(
                      'Records',
                      NumberFormat('#,###', 'id_ID')
                          .format(_statistics!.totalRecords),
                      Colors.blue,
                      Icons.article,
                    ),
                  ),
                ],
              ),
            ),

          // Filters
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Cari operator...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                    onSubmitted: (_) => _loadData(),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _selectDate,
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: Text(
                    _selectedDate != null
                        ? DateFormat('dd MMM yyyy')
                            .format(DateTime.parse(_selectedDate!))
                        : 'Pilih Tanggal',
                    style: const TextStyle(fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12)),
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _records.isEmpty
                    ? const Center(
                        child: Text('Tidak ada data',
                            style: TextStyle(color: Colors.grey)))
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _records.length,
                          itemBuilder: (context, index) =>
                              _recordCard(_records[index]),
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CheckRandomContainerFormPage(),
            ),
          );
          if (result == true) _loadData();
        },
        backgroundColor: const Color(0xFF1C84C2),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _statCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: color.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w500),
              textAlign: TextAlign.center),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color)),
        ],
      ),
    );
  }

  Widget _recordCard(CheckRandomContainer record) {
    final dateFormatted =
        DateFormat('dd MMM yyyy').format(DateTime.parse(record.date));
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C84C2).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(dateFormatted,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1C84C2))),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            CheckRandomContainerFormPage(record: record),
                      ),
                    );
                    if (result == true) _loadData();
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                  onPressed: () => _deleteRecord(record.id),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _infoRow('Warehouse', record.warehouse?.name ?? '-', Icons.warehouse),
            _infoRow('Operator', record.operatorName, Icons.person),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Container',
                          style:
                              TextStyle(fontSize: 11, color: Colors.grey)),
                      Text(
                        '${NumberFormat('#,###', 'id_ID').format(record.containerCount)} Pcs',
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1C84C2)),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Koli',
                          style:
                              TextStyle(fontSize: 11, color: Colors.grey)),
                      Text(
                        '${NumberFormat('#,###', 'id_ID').format(record.koliCount)} Pcs',
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text('$label: ',
              style: const TextStyle(fontSize: 13, color: Colors.grey)),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
