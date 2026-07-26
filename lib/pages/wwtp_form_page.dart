import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:famzlog_flutter/models/wwtp.dart';
import 'package:famzlog_flutter/services/wwtp_service.dart';
import 'package:famzlog_flutter/services/warehouse_service.dart';
import 'package:famzlog_flutter/services/material_service.dart';
import 'package:famzlog_flutter/widgets/modern_snackbar.dart';

class WwtpFormPage extends StatefulWidget {
  final Wwtp? wwtp;

  const WwtpFormPage({super.key, this.wwtp});

  @override
  State<WwtpFormPage> createState() => _WwtpFormPageState();
}

class _WwtpFormPageState extends State<WwtpFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _pickerNameController = TextEditingController();
  final _wwtpInController = TextEditingController();
  final _wwtpOutController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  int? _selectedMaterialId;
  List<MaterialModel> _materials = [];
  bool _loadingMaterials = true;

  @override
  void initState() {
    super.initState();
    _loadMaterials();
    
    if (widget.wwtp != null) {
      _pickerNameController.text = widget.wwtp!.pickerName;
      _wwtpInController.text = widget.wwtp!.wwtpIn.toString();
      _wwtpOutController.text = widget.wwtp!.wwtpOut.toString();
      _selectedDate = DateTime.parse(widget.wwtp!.date);
      _selectedMaterialId = widget.wwtp!.materialId;
    }
  }

  @override
  void dispose() {
    _pickerNameController.dispose();
    _wwtpInController.dispose();
    _wwtpOutController.dispose();
    super.dispose();
  }

  Future<void> _loadMaterials() async {
    try {
      final materials = await MaterialService.getMaterials();
      if (mounted) {
        setState(() {
          _materials = materials;
          _loadingMaterials = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingMaterials = false);
        showModernSnackBar(
          context,
          title: 'Error',
          message: 'Gagal memuat data material: $e',
          success: false,
        );
      }
    }
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedMaterialId == null) {
      showModernSnackBar(
        context,
        title: 'Error',
        message: 'Silakan pilih material',
        success: false,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final warehouseId = await WarehouseService.getSelectedWarehouseId();
      if (warehouseId == null) {
        throw Exception('Warehouse belum dipilih');
      }

      final data = {
        'warehouse_id': warehouseId,
        'material_id': _selectedMaterialId,
        'picker_name': _pickerNameController.text,
        'wwtp_in': int.parse(_wwtpInController.text),
        'wwtp_out': int.parse(_wwtpOutController.text),
        'date': DateFormat('yyyy-MM-dd').format(_selectedDate),
      };

      if (widget.wwtp != null) {
        await WwtpService.updateWwtp(widget.wwtp!.id, data);
        if (mounted) {
          showModernSnackBar(
            context,
            title: 'Berhasil',
            message: 'Data WWTP berhasil diupdate',
            success: true,
          );
        }
      } else {
        await WwtpService.createWwtp(data);
        if (mounted) {
          showModernSnackBar(
            context,
            title: 'Berhasil',
            message: 'Data WWTP berhasil disimpan',
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
          widget.wwtp != null ? 'Edit WWTP' : 'Tambah WWTP',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Date Picker
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: InkWell(
                onTap: _selectDate,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Color(0xFF1580C1)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Tanggal',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('dd MMMM yyyy').format(_selectedDate),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Material Dropdown
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
                      'Material',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _loadingMaterials
                        ? const Center(child: CircularProgressIndicator())
                        : DropdownButtonFormField<int>(
                            value: _selectedMaterialId,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            hint: const Text('Pilih Material'),
                            items: _materials.map((material) {
                              return DropdownMenuItem<int>(
                                value: material.id,
                                child: Text('${material.nama} (${material.uom ?? '-'})'),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedMaterialId = value;
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'Silakan pilih material';
                              }
                              return null;
                            },
                          ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Picker Name
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
                      'Nama Picker',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _pickerNameController,
                      decoration: InputDecoration(
                        hintText: 'Masukkan nama picker',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Nama picker tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // WWTP IN and OUT
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
                      'Informasi WWTP',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _wwtpInController,
                      decoration: InputDecoration(
                        labelText: 'WWTP IN *',
                        prefixIcon: const Icon(
                          Icons.arrow_downward,
                          size: 20,
                          color: Colors.green,
                        ),
                        suffixText: 'Pcs',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'WWTP IN wajib diisi';
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
                      controller: _wwtpOutController,
                      decoration: InputDecoration(
                        labelText: 'WWTP OUT *',
                        prefixIcon: const Icon(
                          Icons.arrow_upward,
                          size: 20,
                          color: Colors.red,
                        ),
                        suffixText: 'Pcs',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'WWTP OUT wajib diisi';
                        }
                        final number = int.tryParse(value);
                        if (number == null || number < 0) {
                          return 'Masukkan angka valid (>= 0)';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1580C1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
                        widget.wwtp != null ? 'Update Data' : 'Simpan Data',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
