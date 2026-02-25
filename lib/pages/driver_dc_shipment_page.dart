import 'package:famzlog_flutter/models/driver_dc_shipment.dart';
import 'package:famzlog_flutter/models/driver_dc_record.dart';
import 'package:famzlog_flutter/services/driver_dc_service.dart';
import 'package:flutter/material.dart';

class DriverDcShipmentPage extends StatefulWidget {
  final int recordId;

  const DriverDcShipmentPage({super.key, required this.recordId});

  @override
  State<DriverDcShipmentPage> createState() => _DriverDcShipmentPageState();
}

class _DriverDcShipmentPageState extends State<DriverDcShipmentPage> {
  bool _loading = true;
  bool _saving = false;
  DriverDcShipment? _shipment;
  final Map<int, Map<String, TextEditingController>> _controllers = {};

  @override
  void initState() {
    super.initState();
    _loadShipment();
  }

  @override
  void dispose() {
    for (var storeControllers in _controllers.values) {
      for (var controller in storeControllers.values) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  Future<void> _loadShipment() async {
    setState(() => _loading = true);
    try {
      final shipment = await DriverDcService.fetchShipment(widget.recordId);
      setState(() {
        _shipment = shipment;
        _initControllers();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading shipment: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _initControllers() {
    if (_shipment == null) return;
    for (var store in _shipment!.stores) {
      _controllers[store.id] = {
        'dc_container': TextEditingController(text: store.dcContainer?.toString() ?? ''),
        'dc_koli': TextEditingController(text: store.dcKoli?.toString() ?? ''),
        'dc_container_rokok': TextEditingController(text: store.dcContainerRokok?.toString() ?? ''),
        'ops_container': TextEditingController(text: store.opsContainer?.toString() ?? ''),
        'ops_koli': TextEditingController(text: store.opsKoli?.toString() ?? ''),
        'team_shipment': TextEditingController(text: store.teamShipment ?? ''),
        'qty_status': TextEditingController(text: store.qtyStatus ?? ''),
        'ttd_signature': TextEditingController(text: store.ttdSignature ?? ''),
      };
    }
  }

  Future<void> _saveShipment() async {
    if (_shipment == null) return;

    setState(() => _saving = true);
    try {
      final List<Map<String, dynamic>> storesData = [];
      for (var store in _shipment!.stores) {
        final ctrls = _controllers[store.id]!;
        storesData.add({
          'id': store.id,
          'dc_container': int.tryParse(ctrls['dc_container']!.text),
          'dc_koli': int.tryParse(ctrls['dc_koli']!.text),
          'dc_container_rokok': int.tryParse(ctrls['dc_container_rokok']!.text),
          'ops_container': int.tryParse(ctrls['ops_container']!.text),
          'ops_koli': int.tryParse(ctrls['ops_koli']!.text),
          'team_shipment': ctrls['team_shipment']!.text,
          'qty_status': ctrls['qty_status']!.text,
          'ttd_signature': ctrls['ttd_signature']!.text,
        });
      }

      await DriverDcService.updateShipment(widget.recordId, storesData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Shipment data saved successfully')),
        );
        Navigator.pop(context, true); // Return true to indicate success/refresh needed
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving shipment: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Shipment Detail',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            onPressed: _saving ? null : _saveShipment,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _shipment == null
              ? const Center(child: Text('No shipment data found'))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 20),
                    ..._shipment!.stores.map(_buildStoreCard),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _saveShipment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1580C1),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                'Simpan Data Shipment',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
    );
  }

  Widget _buildHeader() {
    final record = _shipment!.record;
    return Card(
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  record.licensePlate,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    record.routeCode,
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            if (record.transporterName != null) ...[
              const SizedBox(height: 8),
              Text(
                'Transporter: ${record.transporterName}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStoreCard(ShipmentStore store) {
    final ctrls = _controllers[store.id]!;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ExpansionTile(
        title: Text(
          '${store.sequence}. ${store.storeName}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Tap to edit details',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const SizedBox(height: 8),
          const Text('Distribution Center (DC)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildTextField(ctrls['dc_container']!, 'Container', isNumber: true)),
              const SizedBox(width: 12),
              Expanded(child: _buildTextField(ctrls['dc_koli']!, 'Koli', isNumber: true)),
            ],
          ),
          const SizedBox(height: 12),
          _buildTextField(ctrls['dc_container_rokok']!, 'Container Rokok', isNumber: true),
          
          const SizedBox(height: 16),
          const Text('Operations (OPS)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildTextField(ctrls['ops_container']!, 'Container', isNumber: true)),
              const SizedBox(width: 12),
              Expanded(child: _buildTextField(ctrls['ops_koli']!, 'Koli', isNumber: true)),
            ],
          ),
          
          const SizedBox(height: 16),
          const Text('Validation', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
          const SizedBox(height: 8),
          _buildTextField(ctrls['team_shipment']!, 'Team Shipment Name'),
          const SizedBox(height: 12),
          _buildTextField(ctrls['qty_status']!, 'Qty Status (e.g. OK, Less)'),
          const SizedBox(height: 12),
          _buildTextField(ctrls['ttd_signature']!, 'Signature (Text for now)'),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }
}
