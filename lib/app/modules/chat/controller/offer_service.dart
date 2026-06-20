import 'dart:convert';
import 'package:get/get.dart';
import 'package:wisper/app/core/others/get_storage.dart';
import 'package:wisper/app/modules/chat/model/offer_model.dart';
import 'package:wisper/app/urls.dart';

class OfferService extends GetxService {
  String? get _token => StorageUtil.getData(StorageUtil.userAccessToken);

  // Create a new offer
  Future<OfferModel> createOffer({
    required String receiverId,
    required String chatId,
    required double amount,
    required String description,
    required String duration,
  }) async {
    try {
      final response = await GetConnect().post(
        '${Urls.baseUrl}/offers',
        {
          'receiverId': receiverId,
          'chatId': chatId,
          'amount': amount,
          'description': description,
          'duration': duration,
        },
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return OfferModel.fromJson(response.body['data']);
      } else {
        throw Exception(response.body['message'] ?? 'Failed to create offer');
      }
    } catch (e) {
      throw Exception('Error creating offer: $e');
    }
  }

  // Get offers for a chat
  Future<List<OfferModel>> getOffersByChatId(String chatId) async {
    try {
      final response = await GetConnect().get(
        '${Urls.baseUrl}/offers/chat/$chatId',
        headers: {
          'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.body['data'];
        return data.map((json) => OfferModel.fromJson(json)).toList();
      } else {
        throw Exception(response.body['message'] ?? 'Failed to fetch offers');
      }
    } catch (e) {
      throw Exception('Error fetching offers: $e');
    }
  }

  // Get a single offer
  Future<OfferModel> getOfferById(String id) async {
    try {
      final response = await GetConnect().get(
        '${Urls.baseUrl}/offers/$id',
        headers: {
          'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode == 200) {
        return OfferModel.fromJson(response.body['data']);
      } else {
        throw Exception(response.body['message'] ?? 'Failed to fetch offer');
      }
    } catch (e) {
      throw Exception('Error fetching offer: $e');
    }
  }

  // Accept an offer
  Future<OfferModel> acceptOffer(String id) async {
    try {
      final response = await GetConnect().patch(
        '${Urls.baseUrl}/offers/$id/accept',
        {},
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return OfferModel.fromJson(response.body['data']);
      } else {
        throw Exception(response.body['message'] ?? 'Failed to accept offer');
      }
    } catch (e) {
      throw Exception('Error accepting offer: $e');
    }
  }

  // Decline an offer
  Future<OfferModel> declineOffer(String id) async {
    try {
      final response = await GetConnect().patch(
        '${Urls.baseUrl}/offers/$id/decline',
        {},
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return OfferModel.fromJson(response.body['data']);
      } else {
        throw Exception(response.body['message'] ?? 'Failed to decline offer');
      }
    } catch (e) {
      throw Exception('Error declining offer: $e');
    }
  }

  // Pay for an offer
  Future<OfferModel> payOffer(String id) async {
    try {
      final response = await GetConnect().post(
        '${Urls.baseUrl}/offers/$id/pay',
        {},
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return OfferModel.fromJson(response.body['data']);
      } else {
        throw Exception(
            response.body['message'] ?? 'Failed to pay for offer');
      }
    } catch (e) {
      throw Exception('Error paying for offer: $e');
    }
  }
}
