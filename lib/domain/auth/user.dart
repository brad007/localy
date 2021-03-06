import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:localy/domain/core/value_objects.dart';

part 'user.freezed.dart';

@freezed
abstract class UserEntity with _$UserEntity {
  const factory UserEntity({
    @required UniqueId id,
  }) = _UserEntity;
}
