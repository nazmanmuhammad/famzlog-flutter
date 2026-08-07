import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:famzlog_flutter/models/grouping_retur.dart';
import 'package:famzlog_flutter/services/grouping_retur_service.dart';
import 'package:famzlog_flutter/services/warehouse_service.dart';
import 'package:famzlog_flutter/services/auth_service.dart';
import 'package:famzlog_flutter/widgets/modern_snackbar.dart';

class GroupingReturFormPage extends StatefulWidget {
  final GroupingRetur? record;

  const GroupingReturFormPage({super.key, this.record});

  @override
  State<GroupingReturFormPage> createState() => _GroupingReturFormPageState();
}

class _GroupingReturFormPageState extends State<GroupingReturFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _operatorNameController = TextEditingController();
  final _supplierCountController = TextEditingController();
  final _qtyItemsController = TextEditingController();
  final _qtyPalletController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    
    // Auto-fill operator name dengan email user login
    _operatorNameController.text = AuthService.currentUser?.email ?? '';
    
    if (widget.record != null) {
      _supplierCountController.text = widget.record!.supplierCount.toString();
      _qtyItemsController.text = widget.record!.qtyItems.toString();
      _qtyPalletController.text = widget.record!.qtyPallet.toString();
      _selectedDate = DateTime.parse(widget.record!.date);
    }
  }

  @override
  void dispose() {
    _operatorNameController.dispose();
    _supplierCountController.dispose();
    _qtyItemsController.dispose();
    _qtyPalletController.dispose();
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final warehouseId = await WarehouseService.getSelectedWarehouseId();
      if (warehouseId == null) {
        throw Exception('Warehouse belum dipilih');
      }

      final supplierCount = int.parse(_supplierCountController.text);
      final qtyItems = int.parse(_qtyItemsController.text);
      final qtyPallet = int.parse(_qtyPalletController.text);

      // Format date explicitly without timezone conversion
      final dateString = '${_selectedDate.year.toString().padLeft(4, '0')}-'
          '${_selectedDate.month.toString().padLeft(2, '0')}-'
          '${_selectedDate.day.toString().padLeft(2, '0')}';

      final data = {
        'warehouse_id': warehouseId,
        'operator_name': _operatorNameController.text,
        'supplier_count': supplierCount,
        'qty_items': qtyItems,
        'qty_pallet': qtyPallet,
        'date': dateString,
      };

      if (widget.record != null) {
        await GroupingReturService.updateRecord(widget.record!.id, data);
        if (mounted) {
          showModernSnackBar(
            context,
            title: 'Berhasil',
            message: 'Data berhasil diupdate',
            success: true,
          );
        }
      } else {
        await GroupingReturService.createRecord(data);
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
        backgroundColor: const Color(0xFF1C84C2),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.record != null ? 'Edit Grouping Retur' : 'Tambah Grouping Retur',
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
                      const Icon(Icons.calendar_today, color: Color(0xFF1C84C2)),
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

            // Operator Name
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
                      'Nama Operator',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _operatorNameController,
                      readOnly: true,
                      decoration: InputDecoration(
                        hintText: 'Auto-filled dari user login',
                        filled: true,
                        fillColor: Colors.grey[100],
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
                          return 'Nama operator tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Supplier Count and Qty Items
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
                      'Informasi Grouping Retur',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _supplierCountController,
                      decoration: InputDecoration(
                        labelText: 'Jumlah Supplier *',
                        prefixIcon: const Icon(
                          Icons.assignment_return,
                          size: 20,
                          color: Color(0xFF1C84C2),
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
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Jumlah supplier wajib diisi';
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
                      controller: _qtyItemsController,
                      decoration: InputDecoration(
                        labelText: 'Qty Items *',
                        prefixIcon: const Icon(
                          Icons.inventory_2,
                          size: 20,
                          color: Colors.orange,
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
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Qty items wajib diisi';
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
                      controller: _qtyPalletController,
                      decoration: InputDecoration(
                        labelText: 'Qty Pallet *',
                        prefixIcon: const Icon(
                          Icons.view_in_ar,
                          size: 20,
                          color: Colors.purple,
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
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Qty pallet wajib diisi';
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
                  backgroundColor: const Color(0xFF1C84C2),
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
                        widget.record != null ? 'Update Data' : 'Simpan Data',
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
