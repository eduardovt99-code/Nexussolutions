class Worksite {
  final String id;
  final String ownerId;
  final String name;
  final String clientName;
  final String address;
  final double locationLat;
  final double locationLng;
  final String status; // 'quoting', 'active', 'completed'
  final DateTime createdAt;
  final DateTime? plannedStart;
  final DateTime? plannedEnd;

  Worksite({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.clientName,
    this.address = '',
    required this.locationLat,
    required this.locationLng,
    required this.status,
    required this.createdAt,
    this.plannedStart,
    this.plannedEnd,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'ownerId': ownerId,
    'name': name,
    'clientName': clientName,
    'address': address,
    'locationLat': locationLat,
    'locationLng': locationLng,
    'status': status,
    'createdAt': createdAt.toIso8601String(),
    if (plannedStart != null) 'plannedStart': plannedStart!.toIso8601String(),
    if (plannedEnd != null) 'plannedEnd': plannedEnd!.toIso8601String(),
  };

  factory Worksite.fromJson(Map<String, dynamic> json) => Worksite(
    id: json['id'],
    ownerId: json['ownerId'] ?? '',
    name: json['name'],
    clientName: json['clientName'],
    address: json['address'] ?? '',
    locationLat: (json['locationLat'] as num?)?.toDouble() ?? 0.0,
    locationLng: (json['locationLng'] as num?)?.toDouble() ?? 0.0,
    status: json['status'],
    createdAt: DateTime.parse(json['createdAt']),
    plannedStart: json['plannedStart'] != null ? DateTime.parse(json['plannedStart']) : null,
    plannedEnd: json['plannedEnd'] != null ? DateTime.parse(json['plannedEnd']) : null,
  );
}

class BudgetItem {
  final String description;
  final double quantity;
  final String unit;
  final double unitPrice;
  final double subtotal;

  BudgetItem({
    required this.description,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
    required this.subtotal,
  });

  Map<String, dynamic> toJson() => {
    'description': description,
    'quantity': quantity,
    'unit': unit,
    'unitPrice': unitPrice,
    'subtotal': subtotal,
  };

  factory BudgetItem.fromJson(Map<String, dynamic> json) => BudgetItem(
    description: json['description'],
    quantity: json['quantity'].toDouble(),
    unit: json['unit'],
    unitPrice: json['unitPrice'].toDouble(),
    subtotal: json['subtotal'].toDouble(),
  );
}

class Budget {
  final String id;
  final String ownerId;
  final String worksiteId;
  final double totalAmount;
  final List<BudgetItem> items;
  final String status;

  Budget({
    required this.id,
    required this.ownerId,
    required this.worksiteId,
    required this.totalAmount,
    required this.items,
    required this.status,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'ownerId': ownerId,
    'worksiteId': worksiteId,
    'totalAmount': totalAmount,
    'items': items.map((e) => e.toJson()).toList(),
    'status': status,
  };

  factory Budget.fromJson(Map<String, dynamic> json) => Budget(
    id: json['id'],
    ownerId: json['ownerId'] ?? '',
    worksiteId: json['worksiteId'],
    totalAmount: json['totalAmount'].toDouble(),
    items: (json['items'] as List).map((e) => BudgetItem.fromJson(e)).toList(),
    status: json['status'],
  );
}

class TimeLog {
  final String id;
  final String ownerId;
  final String userId;
  final String worksiteId;
  final DateTime checkIn;
  final DateTime? checkOut;
  final double checkInLat;
  final double checkInLng;
  final double laborCostCalculated;

  TimeLog({
    required this.id,
    required this.ownerId,
    required this.userId,
    required this.worksiteId,
    required this.checkIn,
    this.checkOut,
    required this.checkInLat,
    required this.checkInLng,
    required this.laborCostCalculated,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'ownerId': ownerId,
    'userId': userId,
    'worksiteId': worksiteId,
    'checkIn': checkIn.toIso8601String(),
    'checkOut': checkOut?.toIso8601String(),
    'checkInLat': checkInLat,
    'checkInLng': checkInLng,
    'laborCostCalculated': laborCostCalculated,
  };

  factory TimeLog.fromJson(Map<String, dynamic> json) => TimeLog(
    id: json['id'],
    ownerId: json['ownerId'] ?? '',
    userId: json['userId'],
    worksiteId: json['worksiteId'],
    checkIn: DateTime.parse(json['checkIn']),
    checkOut: json['checkOut'] != null ? DateTime.parse(json['checkOut']) : null,
    checkInLat: json['checkInLat'].toDouble(),
    checkInLng: json['checkInLng'].toDouble(),
    laborCostCalculated: json['laborCostCalculated'].toDouble(),
  );
}

/// Profesiones de la cuadrilla (clave interna → etiqueta en UI).
class WorkerProfession {
  static const String albanileria = 'albanileria';
  static const String fontaneria = 'fontaneria';
  static const String electricidad = 'electricidad';
  static const String pintura = 'pintura';
  static const String general = 'general';

  static const Map<String, String> labels = {
    albanileria: 'Albañilería',
    fontaneria: 'Fontanería',
    electricidad: 'Electricidad',
    pintura: 'Pintura',
    general: 'Oficio general',
  };

  static String label(String key) => labels[key] ?? key;
}

class Worker {
  final String id;
  final String ownerId;
  final String name;
  final String profession;
  final double weeklyCapacityHours;

  Worker({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.profession,
    this.weeklyCapacityHours = 40,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'ownerId': ownerId,
    'name': name,
    'profession': profession,
    'weeklyCapacityHours': weeklyCapacityHours,
  };

  factory Worker.fromJson(Map<String, dynamic> json) => Worker(
    id: json['id'],
    ownerId: json['ownerId'] ?? '',
    name: json['name'],
    profession: json['profession'],
    weeklyCapacityHours: (json['weeklyCapacityHours'] as num?)?.toDouble() ?? 40,
  );
}
