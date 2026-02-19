class BidItem {
  const BidItem({
    required this.id,
    required this.jobId,
    required this.workerId,
    required this.bidAmount,
    required this.status,
    this.partnerName,
    this.partnerFee,
    this.notes,
  });

  final int id;
  final int jobId;
  final int workerId;
  final double bidAmount;
  final String status;
  final String? partnerName;
  final double? partnerFee;
  final String? notes;

  factory BidItem.fromMap(Map<String, dynamic> map) {
    return BidItem(
      id: _asInt(map['id']),
      jobId: _asInt(map['jobId']),
      workerId: _asInt(map['workerId']),
      bidAmount: _asDouble(map['bidAmount']),
      status: map['status']?.toString() ?? 'PENDING',
      partnerName: map['partnerName']?.toString(),
      partnerFee: _asNullableDouble(map['partnerFee']),
      notes: map['notes']?.toString(),
    );
  }
}

class JobCodeInfo {
  const JobCodeInfo({
    required this.id,
    required this.jobId,
    required this.status,
    this.startCode,
    this.releaseCode,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final int jobId;
  final String status;
  final String? startCode;
  final String? releaseCode;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory JobCodeInfo.fromMap(Map<String, dynamic> map) {
    return JobCodeInfo(
      id: _asInt(map['id']),
      jobId: _asInt(map['jobId']),
      status: map['status']?.toString() ?? 'START_PENDING',
      startCode: map['startCode']?.toString(),
      releaseCode: map['releaseCode']?.toString(),
      createdAt: _asDateTime(map['createdAt']),
      updatedAt: _asDateTime(map['updatedAt']),
    );
  }
}

class PaymentInfo {
  const PaymentInfo({
    required this.id,
    required this.jobId,
    required this.clientId,
    required this.workerId,
    required this.amount,
    required this.paymentMode,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final int jobId;
  final int clientId;
  final int workerId;
  final double amount;
  final String paymentMode;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory PaymentInfo.fromMap(Map<String, dynamic> map) {
    return PaymentInfo(
      id: _asInt(map['id']),
      jobId: _asInt(map['jobId']),
      clientId: _asInt(map['clientId']),
      workerId: _asInt(map['workerId']),
      amount: _asDouble(map['amount']),
      paymentMode: map['paymentMode']?.toString() ?? 'OFFLINE',
      status: map['status']?.toString() ?? 'PENDING_ESCROW',
      createdAt: _asDateTime(map['createdAt']),
      updatedAt: _asDateTime(map['updatedAt']),
    );
  }
}

int _asInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _asDouble(Object? value) {
  if (value is double) {
    return value;
  }
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

double? _asNullableDouble(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is double) {
    return value;
  }
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value.toString());
}

DateTime? _asDateTime(Object? value) {
  if (value == null) {
    return null;
  }
  return DateTime.tryParse(value.toString());
}
