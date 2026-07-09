class CouponModel {
  final int id;
  final String code;
  final double discountValue;
  final String type; // 'percentage' or 'fixed'
  final bool isActive;

  CouponModel({
    required this.id,
    required this.code,
    required this.discountValue,
    required this.type,
    required this.isActive,
  });

  factory CouponModel.fromJson(Map<String, dynamic> json) {
    return CouponModel(
      id: json['id'] as int,
      code: json['code'] as String,
      discountValue: (json['discount_value'] as num).toDouble(),
      type: json['type'] as String,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'discount_value': discountValue,
      'type': type,
      'is_active': isActive,
    };
  }
}
