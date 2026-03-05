import 'driver_dc_record.dart';

class DriverDcShipment {
  final DriverDcRecord record;
  final List<ShipmentStore> stores;

  DriverDcShipment({required this.record, required this.stores});

  factory DriverDcShipment.fromJson(Map<String, dynamic> json) {
    return DriverDcShipment(
      record: DriverDcRecord.fromJson(json['record'] as Map<String, dynamic>),
      stores: (json['stores'] as List<dynamic>)
          .map((e) => ShipmentStore.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ShipmentStore {
  final int id;
  final String storeName;
  final int sequence;
  final int? dcContainer;
  final int? dcKoli;
  final int? dcContainerRokok;
  final int? opsContainer;
  final int? opsKoli;
  final String? ttdSignature;
  final String? driverSignature;
  final String? teamShipment;
  final String? qtyStatus;
  final String? driverNotes;

  ShipmentStore({
    required this.id,
    required this.storeName,
    required this.sequence,
    this.dcContainer,
    this.dcKoli,
    this.dcContainerRokok,
    this.opsContainer,
    this.opsKoli,
    this.ttdSignature,
    this.driverSignature,
    this.teamShipment,
    this.qtyStatus,
    this.driverNotes,
  });

  factory ShipmentStore.fromJson(Map<String, dynamic> json) {
    return ShipmentStore(
      id: json['id'] as int,
      storeName: json['store_name'] as String,
      sequence: json['sequence'] as int,
      dcContainer: json['dc_container'] as int?,
      dcKoli: json['dc_koli'] as int?,
      dcContainerRokok: json['dc_container_rokok'] as int?,
      opsContainer: json['ops_container'] as int?,
      opsKoli: json['ops_koli'] as int?,
      ttdSignature: json['ttd_signature'] as String?,
      driverSignature: json['driver_signature'] as String?,
      teamShipment: json['team_shipment'] as String?,
      qtyStatus: json['qty_status'] as String?,
      driverNotes: json['driver_notes'] as String?,
    );
  }
}
