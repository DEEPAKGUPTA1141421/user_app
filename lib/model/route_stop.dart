class RouteStop {
  final String assignmentId;
  final int sequenceNumber;
  final String status; // ASSIGNED | PICKED | DELIVERED | FAILED
  final String destAddress;
  final double destLat;
  final double destLng;
  final String orderId;
  final String orderNo;
  final String? estimatedArrivalAt;

  const RouteStop({
    required this.assignmentId,
    required this.sequenceNumber,
    required this.status,
    required this.destAddress,
    required this.destLat,
    required this.destLng,
    required this.orderId,
    required this.orderNo,
    this.estimatedArrivalAt,
  });

  factory RouteStop.fromJson(Map<String, dynamic> j) => RouteStop(
        assignmentId: j['assignmentId'] as String,
        sequenceNumber: j['sequenceNumber'] as int,
        status: j['status'] as String,
        destAddress: j['destAddress'] as String? ?? '',
        destLat: (j['destLat'] as num).toDouble(),
        destLng: (j['destLng'] as num).toDouble(),
        orderId: j['orderId'] as String,
        orderNo: j['orderNo'] as String? ?? j['orderId'] as String,
        estimatedArrivalAt: j['estimatedArrivalAt'] as String?,
      );

  RouteStop copyWith({String? status}) => RouteStop(
        assignmentId: assignmentId,
        sequenceNumber: sequenceNumber,
        status: status ?? this.status,
        destAddress: destAddress,
        destLat: destLat,
        destLng: destLng,
        orderId: orderId,
        orderNo: orderNo,
        estimatedArrivalAt: estimatedArrivalAt,
      );

  bool get isActive => status == 'ASSIGNED' || status == 'PICKED';
  bool get isDone   => status == 'DELIVERED' || status == 'FAILED';
}
