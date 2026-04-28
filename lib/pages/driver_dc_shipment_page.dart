import 'dart:convert';
import 'dart:typed_data';
import 'package:famzlog_flutter/models/driver_dc_shipment.dart';
import 'package:famzlog_flutter/models/driver_dc_record.dart';
import 'package:famzlog_flutter/services/driver_dc_service.dart';
import 'package:famzlog_flutter/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import 'package:famzlog_flutter/widgets/skeletons.dart';
import 'package:famzlog_flutter/widgets/modern_snackbar.dart';

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
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _loadShipment();
  }

  void _loadUserRole() {
    // Assuming AuthService has a way to get the current user synchronously or cached
    // If not, we might need to fetch it. Based on provided AuthService, it has currentUser getter.
    final user = AuthService.currentUser;
    if (user != null) {
      setState(() {
        _userRole = user.role.toLowerCase().trim();
      });
    }
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
        showModernSnackBar(
          context,
          title: 'Error',
          message: 'Error loading shipment: $e',
          success: false,
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
        'dc_container': TextEditingController(
          text: store.dcContainer?.toString() ?? '',
        ),
        'dc_koli': TextEditingController(text: store.dcKoli?.toString() ?? ''),
        'dc_container_rokok': TextEditingController(
          text: store.dcContainerRokok?.toString() ?? '',
        ),
        'ops_container': TextEditingController(
          text: store.opsContainer?.toString() ?? '',
        ),
        'ops_koli': TextEditingController(
          text: store.opsKoli?.toString() ?? '',
        ),
        'team_shipment': TextEditingController(text: store.teamShipment ?? ''),
        'qty_status': TextEditingController(text: store.qtyStatus ?? ''),
        'ttd_signature': TextEditingController(text: store.ttdSignature ?? ''),
        'driver_signature': TextEditingController(
          text: store.driverSignature ?? '',
        ),
        'driver_notes': TextEditingController(
          text: store.qtyStatus == 'Tidak Sesuai'
              ? (store.driverNotes ?? '')
              : '',
        ),
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

        // Validation for driver_notes if qty_status is 'Tidak Sesuai'
        if (ctrls['qty_status']!.text == 'Tidak Sesuai' &&
            ctrls['driver_notes']!.text.trim().isEmpty) {
          if (mounted) {
            showModernSnackBar(
              context,
              title: 'Error',
              message:
                  'Keterangan wajib diisi untuk toko ${store.storeName} (Status: ${ctrls['qty_status']!.text})',
              success: false,
            );
          }
          setState(() => _saving = false);
          return;
        }

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
          'driver_signature': ctrls['driver_signature']!.text,
          'driver_notes': ctrls['driver_notes']!.text,
        });
      }

      await DriverDcService.updateShipment(widget.recordId, storesData);

      if (mounted) {
        showModernSnackBar(
          context,
          title: 'Berhasil',
          message: 'Data shipment berhasil disimpan',
          success: true,
        );
        Navigator.pop(
          context,
          true,
        ); // Return true to indicate success/refresh needed
      }
    } catch (e) {
      if (mounted) {
        showModernSnackBar(
          context,
          title: 'Error',
          message: 'Gagal menyimpan data: $e',
          success: false,
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
          ? const ShipmentSkeleton()
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
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
    final isShipment = _userRole == 'shipment';
    final isDriver = _userRole == 'driver';
    // If role is undefined or something else, maybe default to read-only or admin access?
    // For now, let's assume if not shipment/driver, they might be admin or viewer.
    // If we want to allow admin to edit everything: final canEditAll = _userRole == 'admin' || _userRole == 'superadmin';

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
          // const Text(
          //   'Distribution Center (DC)',
          //   style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
          // ),
          // const SizedBox(height: 8),
          // Row(
          //   children: [
          //     Expanded(
          //       child: _buildTextField(
          //         ctrls['dc_container']!,
          //         'Container',
          //         isNumber: true,
          //         readOnly: !isShipment,
          //       ),
          //     ),
          //     const SizedBox(width: 12),
          //     Expanded(
          //       child: _buildTextField(
          //         ctrls['dc_koli']!,
          //         'Koli',
          //         isNumber: true,
          //         readOnly: !isShipment,
          //       ),
          //     ),
          //   ],
          // ),
          // const SizedBox(height: 12),
          // _buildTextField(
          //   ctrls['dc_container_rokok']!,
          //   'Container Rokok',
          //   isNumber: true,
          //   readOnly: !isShipment,
          // ),

          // const SizedBox(height: 16),
          // const Text(
          //   'Operations (OPS)',
          //   style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
          // ),
          // const SizedBox(height: 8),
          // Row(
          //   children: [
          //     Expanded(
          //       child: _buildTextField(
          //         ctrls['ops_container']!,
          //         'Container',
          //         isNumber: true,
          //         readOnly: !isShipment,
          //       ),
          //     ),
          //     const SizedBox(width: 12),
          //     Expanded(
          //       child: _buildTextField(
          //         ctrls['ops_koli']!,
          //         'Koli',
          //         isNumber: true,
          //         readOnly: !isShipment,
          //       ),
          //     ),
          //   ],
          // ),

          // const SizedBox(height: 16),
          // const Text(
          //   'Validation (Shipment)',
          //   style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
          // ),
          // const SizedBox(height: 8),
          // _buildTextField(
          //   ctrls['team_shipment']!,
          //   'Team Shipment Name',
          //   readOnly: !isShipment,
          // ),
          // const SizedBox(height: 12),
          // _buildSignatureField(
          //   ctrls['ttd_signature']!,
          //   'Shipment Signature',
          //   enabled: isShipment,
          // ),

          // const SizedBox(height: 16),
          const Text(
            'Validation (Driver)',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple),
          ),
          const SizedBox(height: 8),

          if (isDriver)
            _buildDropdownField(
              ctrls['qty_status']!,
              'Qty Status',
              ['Sesuai', 'Tidak Sesuai', 'Ritase'],
              onChanged: (value) {
                if (value != 'Tidak Sesuai') {
                  ctrls['driver_notes']!.clear();
                }
                setState(() {}); // Refresh to show/hide notes
              },
            )
          else
            _buildTextField(ctrls['qty_status']!, 'Qty Status', readOnly: true),

          if (ctrls['qty_status']!.text == 'Tidak Sesuai') ...[
            const SizedBox(height: 12),
            _buildTextField(
              ctrls['driver_notes']!,
              'Keterangan (Wajib)',
              readOnly: !isDriver,
              maxLines: 2,
            ),
          ],

          const SizedBox(height: 12),
          _buildSignatureField(
            ctrls['driver_signature']!,
            'Driver Signature',
            enabled: isDriver,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool isNumber = false,
    bool readOnly = false,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        filled: readOnly,
        fillColor: readOnly ? Colors.grey.shade100 : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
    );
  }

  Widget _buildDropdownField(
    TextEditingController controller,
    String label,
    List<String> items, {
    void Function(String?)? onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: items.contains(controller.text) ? controller.text : null,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
      items: items.map((String value) {
        return DropdownMenuItem<String>(value: value, child: Text(value));
      }).toList(),
      onChanged: (newValue) {
        if (newValue != null) {
          controller.text = newValue;
          if (onChanged != null) onChanged(newValue);
        }
      },
    );
  }

  Uint8List? _safeDecodeBase64(String value) {
    if (value.isEmpty) return null;
    try {
      final cleanValue = value.contains(',') ? value.split(',').last : value;
      return base64Decode(cleanValue.trim());
    } catch (e) {
      debugPrint('Error decoding base64 signature: $e');
      return null;
    }
  }

  Widget _buildSignatureField(
    TextEditingController controller,
    String label, {
    bool enabled = true,
  }) {
    final hasSignature = controller.text.isNotEmpty;
    Uint8List? signatureBytes;

    if (hasSignature) {
      signatureBytes = _safeDecodeBase64(controller.text);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 8),
        Container(
          height: 120,
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
            color: enabled ? Colors.white : Colors.grey.shade100,
          ),
          child: hasSignature && signatureBytes != null
              ? Stack(
                  children: [
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Image.memory(
                          signatureBytes,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Text('Invalid Signature Data'),
                            );
                          },
                        ),
                      ),
                    ),
                    if (enabled)
                      Positioned(
                        right: 4,
                        top: 4,
                        child: IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _showSignatureDialog(controller),
                          tooltip: 'Edit Signature',
                        ),
                      ),
                  ],
                )
              : Center(
                  child: enabled
                      ? ElevatedButton.icon(
                          onPressed: () => _showSignatureDialog(controller),
                          icon: const Icon(Icons.edit),
                          label:
                              hasSignature // Failed to decode but has text
                              ? const Text('Resign (Invalid Data)')
                              : const Text('Sign Here'),
                        )
                      : Text(
                          hasSignature ? 'Invalid Signature' : 'No Signature',
                          style: const TextStyle(color: Colors.grey),
                        ),
                ),
        ),
      ],
    );
  }

  Future<void> _showSignatureDialog(TextEditingController controller) async {
    final SignatureController signatureController = SignatureController(
      penStrokeWidth: 3,
      penColor: Colors.black,
      exportBackgroundColor: Colors.white,
    );

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Sign Here'),
          content: Container(
            width: double.maxFinite,
            height: 300,
            decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
            child: Signature(
              controller: signatureController,
              backgroundColor: Colors.white,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                signatureController.clear();
              },
              child: const Text('Clear'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (signatureController.isNotEmpty) {
                  final Uint8List? data = await signatureController
                      .toPngBytes();
                  if (data != null) {
                    final base64String = base64Encode(data);
                    controller.text = base64String;
                  }
                }
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    signatureController.dispose();
    setState(() {}); // Refresh to show new signature
  }
}
