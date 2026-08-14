import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String name;
  final String phone;
  final String role; // 'admin' | 'owner' | 'customer'
  final String fcmToken;

  const UserEntity({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    this.fcmToken = '',
  });

  bool get isAdmin => role == 'admin';
  bool get isOwner => role == 'owner';
  bool get isCustomer => role == 'customer';

  @override
  List<Object?> get props => [id, name, phone, role, fcmToken];
}
