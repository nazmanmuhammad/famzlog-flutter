import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:famzlog_flutter/models/empty_jerrycan.dart';
import 'package:famzlog_flutter/services/empty_jerrycan_service.dart';
import 'package:famzlog_flutter/services/warehouse_service.dart';
import 'package:famzlog_flutter/widgets/modern_snackbar.dart';

class EmptyJerrycanFormPage extends StatefulWidget {
  final EmptyJerrycan? emptyJerrycan;

  const EmptyJerrycanFormPage({super.key, this.emptyJerrycan});

  @override
  State<EmptyJerrycanFormPage> createState() => _EmptyJerrycanFormPageState();
}

class _EmptyJerrycanFormPageState extends State<EmptyJerrycanFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _kodeTokoController = TextEditingController();
  final _namaTokoController = TextEditingController();
  final _nopolController = TextEditingController();
  final _namaDriverController = TextEditingController();
  final _noPoController = TextEditingController();
  final _jerrycanInController = TextEditingController();
  final _jerrycanOutController = TextEditingController();
  final _keteranganController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.emptyJerrycan != null) {
      _kodeTokoController.text = widget.emptyJerrycan!.kodeToko ?? '';
      _namaTokoController.text = widget.emptyJerrycan!.namaToko;
      _nopolController.text = widget.emptyJerrycan!.nopol;
      _namaDriverController.text = widget.emptyJerrycan!.namaDriver;
      _noPoController.text = widget.emptyJerrycan!.noPo ?? '';
      _jerrycanInController.text = widget.emptyJerrycan!.jerrycanIn.toString();
      _jerrycanOutController.text = widget.emptyJerrycan!.jerrycanOut.toString();
      _keteranganController.text = widget.emptyJerrycan!.keterangan ?? '';
      
      _selectedDate = DateTime.parse(widget.emptyJerrycan!.tanggal);
      final timeParts = widget.emptyJerrycan!.jam.split(':');
      _selectedTime = TimeOfDay(
        hour: int.parse(timeParts[0]),
        minute: int.parse(timeParts[1]),
      );
    }
  }

  @override
  void dispose() {
    _kodeTokoController.dispose();
    _namaTokoController.dispose();
    _nopolController.dispose();
    _namaDriverController.dispose();
    _noPoController.dispose();
    _jerrycanInController.dispose();
    _jerrycanOutController.dispose();
    _keteranganController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final warehouseId = await WarehouseService.getSelectedWarehouseId();
      if (warehouseId == null) {
        throw Exception('Warehouse tidak ditemukan');
      }

      final data = {
        'warehouse_id': warehouseId,
        'tanggal': DateFormat('yyyy-MM-dd').format(_selectedDate),
        'jam': '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
        'kode_toko': _kodeTokoController.text.trim().isEmpty ? null : _kodeTokoController.text.trim(),
        'nama_toko': _namaTokoController.text.trim(),
        'nopol': _nopolController.text.trim(),
        'nama_driver': _namaDriverController.text.trim(),
        'no_po': _noPoController.text.trim().isEmpty ? null : _noPoController.text.trim(),
        'jerrycan_in': int.tryParse(_jerrycanInController.text.trim()) ?? 0,
        'jerrycan_out': int.tryParse(_jerrycanOutController.text.trim()) ?? 0,
        'keterangan': _keteranganController.text.trim().isEmpty ? null : _keteranganController.text.trim(),
      };

      if (widget.emptyJerrycan != null) {
        await EmptyJerrycanService.updateEmptyJerrycan(widget.emptyJerrycan!.id, data);
        if (mounted) {
          showModernSnackBar(
            context,
            title: 'Berhasil',
            message: 'Data berhasil diupdate',
            success: true,
          );
        }
      } else {
        await EmptyJerrycanService.createEmptyJerrycan(data);
        if (mounted) {
          showModernSnackBar(
            context,
            title: 'Berhasil',
            message: 'Data berhasil disimpan',
            success: true,
          );
        }
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        showModernSnackBar(
          context,
          title: 'Error',
          message: e.toString(),
          success: false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1580C1),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.emptyJerrycan != null ? 'Edit Jerigen Kosong' : 'Tambah Jerigen Kosong',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
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
                      const Text(
                        'Informasi Waktu',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: _selectDate,
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'Tanggal',
                                  prefixIcon: const Icon(Icons.calendar_today, size: 20),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                ),
                                child: Text(
                                  DateFormat('dd MMM yyyy').format(_selectedDate),
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: _selectTime,
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'Jam',
                                  prefixIcon: const Icon(Icons.access_time, size: 20),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                ),
                                child: Text(
                                  _selectedTime.format(context),
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
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
                      const Text(
                        'Informasi Toko',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _kodeTokoController,
                        decoration: InputDecoration(
                          labelText: 'Kode Toko (Opsional)',
                          prefixIcon: const Icon(Icons.qr_code, size: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _namaTokoController,
                        decoration: InputDecoration(
                          labelText: 'Nama Toko *',
                          prefixIcon: const Icon(Icons.store, size: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Nama toko wajib diisi';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
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
                      const Text(
                        'Informasi Kendaraan & Driver',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nopolController,
                        decoration: InputDecoration(
                          labelText: 'Nopol *',
                          prefixIcon: const Icon(Icons.local_shipping, size: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Nopol wajib diisi';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _namaDriverController,
                        decoration: InputDecoration(
                          labelText: 'Nama Driver *',
                          prefixIcon: const Icon(Icons.person, size: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Nama driver wajib diisi';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _noPoController,
                        decoration: InputDecoration(
                          labelText: 'No. PO (Opsional)',
                          prefixIcon: const Icon(Icons.receipt, size: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
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
                      const Text(
                        'Informasi Jerigen Kosong',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _jerrycanInController,
                        decoration: InputDecoration(
                          labelText: 'Jerigen IN *',
                          prefixIcon: const Icon(Icons.arrow_downward, size: 20, color: Colors.green),
                          suffixText: 'Unit',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Jerigen IN wajib diisi';
                          }
                          final number = int.tryParse(value);
                          if (number == null || number < 0) {
                            return 'Masukkan angka valid (>= 0)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _jerrycanOutController,
                        decoration: InputDecoration(
                          labelText: 'Jerigen OUT *',
                          prefixIcon: const Icon(Icons.arrow_upward, size: 20, color: Colors.red),
                          suffixText: 'Unit',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Jerigen OUT wajib diisi';
                          }
                          final number = int.tryParse(value);
                          if (number == null || number < 0) {
                            return 'Masukkan angka valid (>= 0)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _keteranganController,
                        decoration: InputDecoration(
                          labelText: 'Keterangan (Opsional)',
                          prefixIcon: const Icon(Icons.note, size: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                        maxLines: 3,
                        maxLength: 500,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1580C1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        widget.emptyJerrycan != null ? 'Update Data' : 'Simpan Data',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              const SizedBox(height: 8),
              if (!_isLoading)
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
