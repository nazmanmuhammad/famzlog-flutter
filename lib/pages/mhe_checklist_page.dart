import 'package:flutter/material.dart';
import '../models/mhe_checklist.dart';
import '../services/mhe_checklist_service.dart';
import '../services/warehouse_service.dart';
import '../widgets/modern_snackbar.dart';

class MheChecklistPage extends StatefulWidget {
  final String equipmentType;
  final String equipmentName;

  const MheChecklistPage({
    Key? key,
    required this.equipmentType,
    required this.equipmentName,
  }) : super(key: key);

  @override
  State<MheChecklistPage> createState() => _MheChecklistPageState();
}

class _MheChecklistPageState extends State<MheChecklistPage> {
  final MheChecklistService _service = MheChecklistService();
  List<MheChecklistTable> _checklistTables = [];
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  final List<String> _monthNames = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  @override
  void initState() {
    super.initState();
    _loadChecklists();
  }

  Future<void> _loadChecklists() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final warehouseId = await WarehouseService.getSelectedWarehouseId();
      if (warehouseId == null) {
        throw Exception('Warehouse belum dipilih');
      }

      final tables = await _service.getChecklists(
        widget.equipmentType,
        _selectedMonth,
        _selectedYear,
        warehouseId: warehouseId,
      );
      setState(() {
        _checklistTables = tables;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading checklists: $e');
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _saveAllChecklists() async {
    setState(() => _isSaving = true);

    try {
      for (var table in _checklistTables) {
        await _service.updateChecklist(
          table.id,
          table.warehouseId,
          table.tasks,
        );
      }

      if (mounted) {
        showModernSnackBar(
          context,
          title: 'Berhasil',
          message: 'Semua checklist berhasil disimpan',
          success: true,
        );
      }
    } catch (e) {
      if (mounted) {
        showModernSnackBar(
          context,
          title: 'Gagal',
          message: 'Gagal menyimpan: ${e.toString()}',
          success: false,
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _showAddTableDialog() async {
    final TextEditingController nameController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Tambah Table Checklist',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Nama Equipment',
                  hintText: 'Contoh: RT-001',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.label_outline),
                ),
                textCapitalization: TextCapitalization.characters,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) {
                  showModernSnackBar(
                    context,
                    title: 'Peringatan',
                    message: 'Nama equipment harus diisi',
                    success: false,
                  );
                  return;
                }

                Navigator.pop(context);
                await _createNewTable(nameController.text.trim());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1580C1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Tambah',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _createNewTable(String equipmentName) async {
    setState(() => _isLoading = true);

    try {
      final warehouseId = await WarehouseService.getSelectedWarehouseId();
      if (warehouseId == null) {
        throw Exception('Warehouse belum dipilih');
      }

      final newTable = await _service.createChecklist(
        equipmentType: widget.equipmentType,
        equipmentName: equipmentName,
        month: _selectedMonth,
        year: _selectedYear,
        warehouseId: warehouseId,
      );

      setState(() {
        _checklistTables.add(newTable);
        _isLoading = false;
      });

      if (mounted) {
        showModernSnackBar(
          context,
          title: 'Berhasil',
          message: 'Table checklist berhasil ditambahkan',
          success: true,
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        showModernSnackBar(
          context,
          title: 'Gagal',
          message: e.toString().replaceAll('Exception: ', ''),
          success: false,
        );
      }
    }
  }

  Future<void> _deleteTable(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Konfirmasi Hapus'),
        content: Text(
          'Apakah Anda yakin ingin menghapus checklist "${_checklistTables[index].equipmentName}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final success = await _service.deleteChecklist(
          _checklistTables[index].id,
        );
        if (success) {
          setState(() {
            _checklistTables.removeAt(index);
          });
          if (mounted) {
            showModernSnackBar(
              context,
              title: 'Berhasil',
              message: 'Checklist berhasil dihapus',
              success: true,
            );
          }
        }
      } catch (e) {
        if (mounted) {
          showModernSnackBar(
            context,
            title: 'Gagal',
            message: 'Gagal menghapus: ${e.toString()}',
            success: false,
          );
        }
      }
    }
  }

  void _showMonthYearPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        int tempMonth = _selectedMonth;
        int tempYear = _selectedYear;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Pilih Bulan & Tahun',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: tempMonth,
                          decoration: const InputDecoration(
                            labelText: 'Bulan',
                            border: OutlineInputBorder(),
                          ),
                          items: List.generate(12, (index) {
                            return DropdownMenuItem(
                              value: index + 1,
                              child: Text(_monthNames[index]),
                            );
                          }),
                          onChanged: (value) {
                            setModalState(() => tempMonth = value!);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: tempYear,
                          decoration: const InputDecoration(
                            labelText: 'Tahun',
                            border: OutlineInputBorder(),
                          ),
                          items: List.generate(10, (index) {
                            int year = DateTime.now().year - 2 + index;
                            return DropdownMenuItem(
                              value: year,
                              child: Text(year.toString()),
                            );
                          }),
                          onChanged: (value) {
                            setModalState(() => tempYear = value!);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedMonth = tempMonth;
                          _selectedYear = tempYear;
                        });
                        Navigator.pop(context);
                        _loadChecklists();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF276CB1),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Terapkan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: Text(
          widget.equipmentName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: const Color(0xFF1580C1),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: _showAddTableDialog,
            tooltip: 'Tambah Table',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? _buildErrorWidget()
                : _buildChecklistContent(),
          ),
        ],
      ),
      bottomNavigationBar: _checklistTables.isNotEmpty
          ? _buildBottomBar()
          : null,
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Periode Checklist',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _showMonthYearPicker,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1580C1), Color(0xFF42A5F5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1580C1).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.calendar_today_rounded,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _monthNames[_selectedMonth - 1],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '$_selectedYear',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.arrow_drop_down_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Gagal memuat checklist',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Terjadi kesalahan',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _loadChecklists,
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text(
                'Coba Lagi',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1580C1),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChecklistContent() {
    if (_checklistTables.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inbox_outlined,
                size: 48,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Belum ada checklist',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _showAddTableDialog,
              icon: const Icon(Icons.add),
              label: const Text('Tambah Checklist'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF1580C1),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _checklistTables.length,
      itemBuilder: (context, index) {
        return _buildTableCard(_checklistTables[index], index);
      },
    );
  }

  Widget _buildTableCard(MheChecklistTable table, int tableIndex) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1580C1).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1580C1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.assignment_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    table.equipmentName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _deleteTable(tableIndex),
                  tooltip: 'Hapus',
                ),
              ],
            ),
          ),
          // Tasks
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: table.tasks.length,
            itemBuilder: (context, taskIndex) {
              return _buildTaskRow(table.tasks[taskIndex], taskIndex);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTaskRow(MheChecklistTask task, int index) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFF1580C1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1580C1),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  task.taskDescription,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(5, (weekIndex) {
              int weekNum = weekIndex + 1;
              WeekData? weekData = task.weeks[weekNum];

              return Expanded(
                child: Container(
                  margin: EdgeInsets.symmetric(
                    horizontal: weekIndex == 0 || weekIndex == 4 ? 0 : 2,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _getRomanNumeral(weekNum),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1580C1),
                        ),
                      ),
                      const SizedBox(height: 4),
                      _buildSmallCheckbox(
                        value: weekData?.ttdOperator ?? false,
                        onChanged: (value) {
                          setState(() {
                            if (weekData != null) {
                              weekData.ttdOperator = value!;
                            }
                          });
                        },
                        label: 'Op',
                      ),
                      const SizedBox(height: 4),
                      _buildSmallCheckbox(
                        value: weekData?.ttdLeader ?? false,
                        onChanged: (value) {
                          setState(() {
                            if (weekData != null) {
                              weekData.ttdLeader = value!;
                            }
                          });
                        },
                        label: 'Ld',
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: TextEditingController(text: task.notes),
            decoration: InputDecoration(
              hintText: 'Catatan...',
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 12),
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              isDense: true,
            ),
            style: const TextStyle(fontSize: 12),
            maxLines: 1,
            onChanged: (value) {
              setState(() {
                task.notes = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSmallCheckbox({
    required bool value,
    required Function(bool?) onChanged,
    required String label,
  }) {
    return Column(
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF276CB1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(3),
            ),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 8, color: Colors.grey)),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveAllChecklists,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1580C1),
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              disabledBackgroundColor: Colors.grey[300],
              elevation: 0,
            ),
            child: _isSaving
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(
                        Icons.check_circle_outline_rounded,
                        size: 22,
                        color: Colors.white,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Simpan Semua Checklist',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  String _getRomanNumeral(int number) {
    switch (number) {
      case 1:
        return 'I';
      case 2:
        return 'II';
      case 3:
        return 'III';
      case 4:
        return 'IV';
      case 5:
        return 'V';
      default:
        return number.toString();
    }
  }
}
