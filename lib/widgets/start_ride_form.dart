import 'package:flutter/material.dart';
import 'package:famzlog_flutter/services/driver_dc_service.dart';
import 'package:famzlog_flutter/services/driver_location_service.dart';
import 'package:famzlog_flutter/services/auth_service.dart';
import 'package:famzlog_flutter/models/driver_dc_record.dart';
import 'package:famzlog_flutter/models/store.dart';
import 'package:famzlog_flutter/widgets/modern_snackbar.dart';

class StartRideForm extends StatefulWidget {
  const StartRideForm({super.key});

  @override
  State<StartRideForm> createState() => _StartRideFormState();
}

class _StartRideFormState extends State<StartRideForm> {
  static const _primary = Color(0xFF1580C1);

  final _formKey = GlobalKey<FormState>();
  final _nopolController = TextEditingController();
  final _routeController = TextEditingController();
  final _customRouteNameController = TextEditingController();
  final _searchStoreController = TextEditingController();

  List<VehicleOption> _vehicles = [];
  List<RouteOption> _routes = [];
  List<StoreOption> _allStores = [];
  List<StoreOption> _filteredStores = [];
  List<int> _selectedStoreIds = [];
  
  bool _loading = false;
  bool _submitting = false;
  bool _isCustomRoute = false; // Toggle state

  @override
  void initState() {
    super.initState();
    _loadOptions();
    _searchStoreController.addListener(_filterStores);
  }

  @override
  void dispose() {
    _nopolController.dispose();
    _routeController.dispose();
    _customRouteNameController.dispose();
    _searchStoreController.dispose();
    super.dispose();
  }

  void _filterStores() {
    final query = _searchStoreController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredStores = List.of(_allStores);
      } else {
        _filteredStores = _allStores
            .where((store) => store.storeName.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  Future<void> _loadOptions() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        DriverDcService.fetchVehicles(),
        DriverDcService.fetchRoutes(),
        DriverDcService.fetchStores(),
      ]);
      if (!mounted) return;
      setState(() {
        _vehicles = results[0] as List<VehicleOption>;
        _routes = results[1] as List<RouteOption>;
        _allStores = results[2] as List<StoreOption>;
        _filteredStores = List.of(_allStores);
      });
    } catch (e) {
      if (!mounted) return;
      showModernSnackBar(
        context,
        title: 'Error',
        message: 'Gagal memuat data: ${e.toString()}',
        success: false,
      );
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    
    // Additional validation for custom route
    if (_isCustomRoute) {
      if (_customRouteNameController.text.trim().isEmpty) {
        showModernSnackBar(
          context,
          title: 'Error',
          message: 'Nama route wajib diisi',
          success: false,
        );
        return;
      }
      if (_selectedStoreIds.isEmpty) {
        showModernSnackBar(
          context,
          title: 'Error',
          message: 'Pilih minimal 1 store',
          success: false,
        );
        return;
      }
    }

    setState(() => _submitting = true);
    try {
      DriverDcRecord record;
      
      if (_isCustomRoute) {
        record = await DriverDcService.createRecordWithCustomRoute(
          licensePlate: _nopolController.text.trim(),
          customRouteName: _customRouteNameController.text.trim(),
          storeIds: _selectedStoreIds,
        );
      } else {
        record = await DriverDcService.createRecord(
          licensePlate: _nopolController.text.trim(),
          routeCode: _routeController.text.trim(),
        );
      }
      
      if (!mounted) return;
      showModernSnackBar(
        context,
        title: 'Berhasil',
        message: _isCustomRoute 
            ? 'Custom route berhasil dibuat'
            : 'Driver DC berhasil ditambahkan',
        success: true,
      );
      Navigator.of(context).pop(record);
    } on ApiException catch (e) {
      if (!mounted) return;
      showModernSnackBar(
        context,
        title: 'Error',
        message: e.message,
        success: false,
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      showModernSnackBar(
        context,
        title: 'Error',
        message: e.message,
        success: false,
      );
    } catch (e) {
      if (!mounted) return;
      showModernSnackBar(
        context,
        title: 'Error',
        message: e.toString(),
        success: false,
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _pickVehicle() async {
    final selected = await showModalBottomSheet<VehicleOption>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _VehiclePickerSheet(vehicles: _vehicles),
    );
    if (selected != null) {
      _nopolController.text = selected.licensePlate;
    }
  }

  void _pickRoute() async {
    final selected = await showModalBottomSheet<RouteOption>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _RoutePickerSheet(routes: _routes),
    );
    if (selected != null) {
      _routeController.text = selected.code;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Center(
                child: Text(
                  'Start New Ride',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  'Input vehicle plate number and route',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                ),
              ),
              const SizedBox(height: 24),

              if (_loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                )
              else ...[
                // Nopol field
                TextFormField(
                  controller: _nopolController,
                  readOnly: _vehicles.isNotEmpty,
                  onTap: _vehicles.isNotEmpty ? _pickVehicle : null,
                  decoration: InputDecoration(
                    labelText: 'Nopol',
                    hintText: _vehicles.isNotEmpty
                        ? 'Tap to select'
                        : 'Enter nopol',
                    prefixIcon: Icon(
                      Icons.local_shipping_outlined,
                      color: Colors.grey.shade500,
                      size: 20,
                    ),
                    suffixIcon: _vehicles.isNotEmpty
                        ? const Icon(Icons.arrow_drop_down)
                        : null,
                    filled: true,
                    fillColor: const Color(0xFFE3F2FD).withOpacity(0.3),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: _primary.withOpacity(0.3),
                        width: 1.2,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: _primary, width: 1.6),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Colors.red, width: 1.2),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Colors.red, width: 1.6),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 16,
                    ),
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Nopol wajib diisi' : null,
                ),
                const SizedBox(height: 20),

                // Route Mode Toggle
                const Text(
                  'Route Mode',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _isCustomRoute = false;
                              _routeController.clear();
                              _customRouteNameController.clear();
                              _selectedStoreIds.clear();
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: !_isCustomRoute ? _primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Select Route',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: !_isCustomRoute ? Colors.white : Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _isCustomRoute = true;
                              _routeController.clear();
                              _customRouteNameController.clear();
                              _selectedStoreIds.clear();
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _isCustomRoute ? _primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Custom Route',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _isCustomRoute ? Colors.white : Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Conditional content based on mode
                if (!_isCustomRoute) ...[
                  // Existing Route Selection
                  TextFormField(
                    controller: _routeController,
                    readOnly: _routes.isNotEmpty,
                    onTap: _routes.isNotEmpty ? _pickRoute : null,
                    decoration: InputDecoration(
                      labelText: 'Route',
                      hintText: _routes.isNotEmpty
                          ? 'Tap to select'
                          : 'Enter route',
                      prefixIcon: Icon(
                        Icons.route_outlined,
                        color: Colors.grey.shade500,
                        size: 20,
                      ),
                      suffixIcon: _routes.isNotEmpty
                          ? const Icon(Icons.arrow_drop_down)
                          : null,
                      filled: true,
                      fillColor: const Color(0xFFE3F2FD).withOpacity(0.3),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: _primary.withOpacity(0.3),
                          width: 1.2,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: _primary, width: 1.6),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Colors.red, width: 1.2),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Colors.red, width: 1.6),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 16,
                      ),
                    ),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Route wajib diisi' : null,
                  ),
                ] else ...[
                  // Custom Route Form
                  TextFormField(
                    controller: _customRouteNameController,
                    decoration: InputDecoration(
                      labelText: 'Route Name',
                      hintText: 'e.g., My Custom Route',
                      prefixIcon: Icon(
                        Icons.edit_road_outlined,
                        color: Colors.grey.shade500,
                        size: 20,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFE3F2FD).withOpacity(0.3),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: _primary.withOpacity(0.3),
                          width: 1.2,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: _primary, width: 1.6),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Store selection
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Select Stores',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_selectedStoreIds.length} selected',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Search field
                  TextField(
                    controller: _searchStoreController,
                    decoration: InputDecoration(
                      hintText: 'Search stores...',
                      prefixIcon: Icon(
                        Icons.search,
                        color: Colors.grey.shade500,
                        size: 20,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Store list
                  Container(
                    height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _filteredStores.isEmpty
                        ? Center(
                            child: Text(
                              'No stores found',
                              style: TextStyle(color: Colors.grey.shade500),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _filteredStores.length,
                            itemBuilder: (context, index) {
                              final store = _filteredStores[index];
                              final isSelected = _selectedStoreIds.contains(store.id);
                              
                              return CheckboxListTile(
                                title: Text(
                                  store.storeName,
                                  style: const TextStyle(fontSize: 14),
                                ),
                                value: isSelected,
                                activeColor: _primary,
                                onChanged: (checked) {
                                  setState(() {
                                    if (checked!) {
                                      _selectedStoreIds.add(store.id);
                                    } else {
                                      _selectedStoreIds.remove(store.id);
                                    }
                                  });
                                },
                              );
                            },
                          ),
                  ),
                  
                  // Selected stores preview
                  if (_selectedStoreIds.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Selected Stores (in order):',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 120),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _selectedStoreIds.length,
                        itemBuilder: (context, index) {
                          final storeId = _selectedStoreIds[index];
                          final store = _allStores.firstWhere((s) => s.id == storeId);
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: _primary.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _primary.withOpacity(0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: _primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${index + 1}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    store.storeName,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 18),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () {
                                    setState(() => _selectedStoreIds.remove(storeId));
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
                
                const SizedBox(height: 24),

                // Submit button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            'Confirm Ride',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// Vehicle Picker Sheet
class _VehiclePickerSheet extends StatefulWidget {
  const _VehiclePickerSheet({required this.vehicles});
  final List<VehicleOption> vehicles;

  @override
  State<_VehiclePickerSheet> createState() => _VehiclePickerSheetState();
}

class _VehiclePickerSheetState extends State<_VehiclePickerSheet> {
  static const _primary = Color(0xFF1580C1);
  final TextEditingController _searchController = TextEditingController();
  List<VehicleOption> _filteredVehicles = [];

  @override
  void initState() {
    super.initState();
    _filteredVehicles = List.of(widget.vehicles);
    _searchController.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchController.removeListener(_applyFilter);
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilter() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredVehicles = List.of(widget.vehicles);
      } else {
        _filteredVehicles = widget.vehicles
            .where((vehicle) => vehicle.licensePlate.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            children: [
              const SizedBox(height: 16),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Pilih Nopol',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: _filteredVehicles.length,
                  itemBuilder: (context, index) {
                    final vehicle = _filteredVehicles[index];
                    return ListTile(
                      leading: const Icon(Icons.local_shipping, color: _primary),
                      title: Text(vehicle.licensePlate),
                      onTap: () => Navigator.pop(context, vehicle),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Route Picker Sheet
class _RoutePickerSheet extends StatefulWidget {
  const _RoutePickerSheet({required this.routes});
  final List<RouteOption> routes;

  @override
  State<_RoutePickerSheet> createState() => _RoutePickerSheetState();
}

class _RoutePickerSheetState extends State<_RoutePickerSheet> {
  static const _primary = Color(0xFF1580C1);
  final TextEditingController _searchController = TextEditingController();
  List<RouteOption> _filteredRoutes = [];

  @override
  void initState() {
    super.initState();
    _filteredRoutes = List.of(widget.routes);
    _searchController.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchController.removeListener(_applyFilter);
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilter() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredRoutes = List.of(widget.routes);
      } else {
        _filteredRoutes = widget.routes
            .where((route) =>
                route.code.toLowerCase().contains(query) ||
                route.name.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            children: [
              const SizedBox(height: 16),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Pilih Route',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: _filteredRoutes.length,
                  itemBuilder: (context, index) {
                    final route = _filteredRoutes[index];
                    return ListTile(
                      leading: const Icon(Icons.route, color: _primary),
                      title: Text(route.code),
                      subtitle: Text(route.name),
                      onTap: () => Navigator.pop(context, route),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
