import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';
import 'package:geoflutterfire/geoflutterfire.dart';
import 'package:injectable/injectable.dart';
import 'package:kt_dart/kt.dart';
import 'package:localy/domain/store/i_store_repository.dart';
import 'package:localy/domain/store/restaurant.dart';
import 'package:localy/domain/store/store_failure.dart';
import 'package:localy/infrastructure/core/firestore_helpers.dart';
import 'package:localy/infrastructure/stores/store_dtos.dart';
import 'package:location/location.dart';

@prod
@LazySingleton(as: IStoreRepository)
class StoreRepository implements IStoreRepository {
  StoreRepository(this._firestore, this._firebaseStorage);

  final FirebaseFirestore _firestore;
  final FirebaseStorage _firebaseStorage;

  @override
  Future<Either<StoreFailure, Unit>> create(Restaurant store) async {
    try {
      final userDoc = await _firestore.userDocument();
      final token = await FirebaseMessaging().getToken();

      var storeDTO = StoreDTO.fromDomain(store);
      storeDTO = storeDTO.copyWith(
        ownerID: userDoc.id,
        token: token,
      );

      storeDTO = await _uploadImages(
        store.coverImageUrl,
        storeDTO,
      );

      await _firestore.storeCollection.doc(storeDTO.id).set(storeDTO.toJson());

      return right(unit);
    } on PlatformException catch (e) {
      if (e.message.contains('PERMISSION_DENIED')) {
        return left(const StoreFailure.insufficientPermission());
      } else {
        return left(const StoreFailure.unexpected());
      }
    }
  }

  @override
  Future<Either<StoreFailure, Unit>> delete(Restaurant store) async {
    try {
      final storeId = store.id.getOrCrash();

      await _firestore.storeCollection.doc(storeId).delete();

      return right(unit);
    } on PlatformException catch (e) {
      if (e.message.contains('PERMISSION_DENIED')) {
        return left(const StoreFailure.insufficientPermission());
      } else if (e.message.contains('NOT_FOUND')) {
        return left(const StoreFailure.unableToUpdate());
      } else {
        return left(const StoreFailure.unexpected());
      }
    }
  }

  @override
  Future<Either<StoreFailure, Unit>> update(Restaurant store) async {
    try {
      var storeDTO = StoreDTO.fromDomain(store);

      storeDTO = await _uploadImages(
        store.coverImageUrl,
        storeDTO,
      );

      await _firestore.storeCollection
          .doc(storeDTO.id)
          .update(storeDTO.toJson());

      return right(unit);
    } on PlatformException catch (e) {
      if (e.message.contains('PERMISSION_DENIED')) {
        return left(const StoreFailure.insufficientPermission());
      } else if (e.message.contains('NOT_FOUND')) {
        return left(const StoreFailure.unableToUpdate());
      } else {
        return left(const StoreFailure.unexpected());
      }
    }
  }

  @override
  Stream<Either<StoreFailure, KtList<Restaurant>>> watchAll() async* {
    final userDoc = await _firestore.userDocument();
    yield* _firestore.storeCollection
        .where('ownerID', isEqualTo: userDoc.id)
        .orderBy('serverTimeStamp', descending: true)
        .snapshots()
        .map(
          (snapshots) => right<StoreFailure, KtList<Restaurant>>(
            snapshots.docs
                .map((doc) => StoreDTO.fromFirestore(doc).toDomain())
                .toImmutableList(),
          ),
        );
  }

  @override
  Stream<Either<StoreFailure, KtList<Restaurant>>> watchAllInRadius() async* {
    final location = await Location().getLocation();

    final center = GeoFirePoint(location.latitude, location.longitude)
        .hash
        .substring(0, 4);

    yield* _firestore.storeCollection
        .where('coordinates.geohash', isGreaterThanOrEqualTo: center)
        .where('coordinates.geohash', isLessThanOrEqualTo: '$center\uf8ff')
        .where('open', isEqualTo: true)
        .where('active', isEqualTo: true)
        .orderBy('coordinates.geohash', descending: true)
        .snapshots()
        .map(
          (snapshots) => right<StoreFailure, KtList<Restaurant>>(
            snapshots.docs
                .map((doc) => StoreDTO.fromFirestore(doc).toDomain())
                .toImmutableList(),
          ),
        );
  }

  Future<StoreDTO> _uploadImages(
      String coverImageUrl, StoreDTO storeDTO) async {
    var store = storeDTO;

    if ((coverImageUrl != null && coverImageUrl.isNotEmpty) &&
        !coverImageUrl.contains('http')) {
      final uploadTask =
          _firebaseStorage.storeStorageReference.putFile(File(coverImageUrl));

      final downloadUrl =  uploadTask.snapshot;

      final imageUrl = await downloadUrl.ref.getDownloadURL();

      store = store.copyWith(coverImageUrl: imageUrl);
    }

    return store;
  }
}
