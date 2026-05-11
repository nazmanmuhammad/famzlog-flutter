import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/temperature_record.dart';
import '../services/temperature_service.dart';

class TemperatureFormPage extends StatefulWidget {
  final List<Room> rooms;
  final TemperatureRecord? record;

  const TemperatureFormPage({
    Key? key,
    required this.rooms,
    this.record,
  }) : super(key: key);

  @override
  State<TemperatureFormPage> createState() => _TemperatureFormPageState();
}

class _TemperatureFormPageState extends State<TemperatureFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _temperatureController = TextEditingController();
  final _notesController = TextEditingController();

  int? _selectedRoomId;
  DateTime _selectedDateTime = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.record != null) {
      _selectedRoomId = widget.record!.roomId;
      _temperatureController.text = widget.record!.temperature.toString();
      _notesController.text = widget.record!.notes ?? '';
      _selectedDateTime = widget.record!.recordedAt;
    }
  }

  @override
  void dispose() {
    _temperatureController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      );

      if (time != null) {
        setState(() {
          _selectedDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  void _showRoomSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _RoomSelectorSheet(
        rooms: widget.rooms,
        selectedRoomId: _selectedRoomId,
        onRoomSelected: (roomId) {
          setState(() {
            _selectedRoomId = roomId;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedRoomId == null) {
      _showSnackBar('Pilih ruangan terlebih dahulu', Colors.red);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final temperature = double.parse(_temperatureController.text);
      final notes = _notesController.text.trim();

      if (widget.record != null) {
        // Update existing record
        await TemperatureService.updateRecord(
          id: widget.record!.id,
          roomId: _selectedRoomId,
          temperature: temperature,
          notes: notes.isEmpty ? null : notes,
          recordedAt: _selectedDateTime,
        );
        _showSnackBar('Data berhasil diupdate', Colors.green);
      } else {
        // Create new record
        await TemperatureService.createRecord(
          roomId: _selectedRoomId!,
          temperature: temperature,
          notes: notes.isEmpty ? null : notes,
          recordedAt: _selectedDateTime,
        );
        _showSnackBar('Data berhasil disimpan', Colors.green);
      }

      Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Gagal menyimpan data: $e', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.record != null ? 'Edit Suhu Ruangan' : 'Input Suhu Ruangan',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Informasi Suhu',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Searchable Room Selector
                      InkWell(
                        onTap: () => _showRoomSelector(),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Ruangan *',
                            prefixIcon: const Icon(Icons.meeting_room),
                            suffixIcon: const Icon(Icons.arrow_drop_down),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            errorText: _selectedRoomId == null && _formKey.currentState?.validate() == false
                                ? 'Pilih ruangan'
                                : null,
                          ),
                          child: _selectedRoomId == null
                              ? const Text(
                                  'Pilih ruangan...',
                                  style: TextStyle(color: Colors.grey),
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      widget.rooms
                                          .firstWhere((r) => r.id == _selectedRoomId)
                                          .roomName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      'PIC: ${widget.rooms.firstWhere((r) => r.id == _selectedRoomId).picName}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _temperatureController,
                        decoration: InputDecoration(
                          labelText: 'Suhu (°C) *',
                          prefixIcon: const Icon(Icons.thermostat),
                          suffixText: '°C',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          helperText: 'Range: -50°C sampai 100°C',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Masukkan suhu';
                          }
                          final temp = double.tryParse(value);
                          if (temp == null) {
                            return 'Suhu harus berupa angka';
                          }
                          if (temp < -50 || temp > 100) {
                            return 'Suhu harus antara -50°C dan 100°C';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: _selectDateTime,
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Waktu Pencatatan',
                            prefixIcon: const Icon(Icons.access_time),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                DateFormat('dd/MM/yyyy HH:mm')
                                    .format(_selectedDateTime),
                              ),
                              const Icon(Icons.calendar_today, size: 18),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _notesController,
                        decoration: InputDecoration(
                          labelText: 'Catatan (Opsional)',
                          prefixIcon: const Icon(Icons.note),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          helperText: 'Maksimal 500 karakter',
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
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        widget.record != null ? 'Update Data' : 'Simpan Data',
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

// Searchable Room Selector Bottom Sheet
class _RoomSelectorSheet extends StatefulWidget {
  final List<Room> rooms;
  final int? selectedRoomId;
  final Function(int) onRoomSelected;

  const _RoomSelectorSheet({
    required this.rooms,
    required this.selectedRoomId,
    required this.onRoomSelected,
  });

  @override
  State<_RoomSelectorSheet> createState() => _RoomSelectorSheetState();
}

class _RoomSelectorSheetState extends State<_RoomSelectorSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<Room> _filteredRooms = [];

  @override
  void initState() {
    super.initState();
    _filteredRooms = widget.rooms;
    _searchController.addListener(_filterRooms);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterRooms() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredRooms = widget.rooms;
      } else {
        _filteredRooms = widget.rooms.where((room) {
          return room.roomName.toLowerCase().contains(query) ||
              room.picName.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 16),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Title
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Pilih Ruangan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Search field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Cari ruangan atau PIC...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Room list
            Expanded(
              child: _filteredRooms.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Ruangan tidak ditemukan',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: _filteredRooms.length,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemBuilder: (context, index) {
                        final room = _filteredRooms[index];
                        final isSelected = room.id == widget.selectedRoomId;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          elevation: isSelected ? 4 : 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isSelected
                                  ? Colors.blue
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            leading: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.blue
                                    : Colors.grey[200],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.meeting_room,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.grey[600],
                              ),
                            ),
                            title: Text(
                              room.roomName,
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isSelected ? Colors.blue : Colors.black,
                              ),
                            ),
                            subtitle: Text(
                              'PIC: ${room.picName}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            trailing: isSelected
                                ? const Icon(
                                    Icons.check_circle,
                                    color: Colors.blue,
                                  )
                                : null,
                            onTap: () => widget.onRoomSelected(room.id),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}
