import 'dart:convert';
import 'package:flutter/foundation.dart';

class JobModel {
  final int id;
  final int posterId;
  final String title;
  final String description;
  final String? skillRequired;
  final String status;
  final String pricingType;
  final double price;
  final String genderPreference;
  final String urgency;
  final double? locationLat;
  final double? locationLon;
  final String? locationAddress;
  final bool isRemote;
  final double? estimatedHours;
  final String? requiredByTime;
  final String? attachmentUrls;
  final DateTime createdAt;
  final Map<String, dynamic>? poster;
  // Naya field jo AI matching ke liye zaroori hai
  final List<int> targetedSeekerIds;

  const JobModel({
    required this.id,
    required this.posterId,
    required this.title,
    required this.description,
    this.skillRequired,
    required this.status,
    required this.pricingType,
    required this.price,
    required this.genderPreference,
    required this.urgency,
    this.locationLat,
    this.locationLon,
    this.locationAddress,
    required this.isRemote,
    this.estimatedHours,
    this.requiredByTime,
    this.attachmentUrls,
    required this.createdAt,
    this.poster,
    this.targetedSeekerIds = const [],
  });

  factory JobModel.fromJson(Map<String, dynamic> j) {
    // targetedSeekerIds ki complex parsing taake error na aaye
    List<int> parsedIds = [];
    if (j['targetedSeekerIds'] != null) {
      var rawIds = j['targetedSeekerIds'];
      try {
        if (rawIds is String) {
          // Agar database se JSON string "[5,7]" aye
          var decoded = jsonDecode(rawIds);
          parsedIds = List<int>.from(decoded.map((x) => x as int));
        } else if (rawIds is List) {
          // Agar direct list aye
          parsedIds = List<int>.from(rawIds.map((x) => x as int));
        }
      } catch (e) {
        debugPrint("Error parsing targetedSeekerIds: $e");
      }
    }

    return JobModel(
      id: j['id'] ?? 0,
      posterId: j['posterId'] ?? 0,
      title: j['title'] ?? '',
      description: j['description'] ?? '',
      skillRequired: j['skillRequired'],
      status: j['status'] ?? 'open',
      pricingType: j['pricingType'] ?? 'fixed',
      price: (j['price'] as num?)?.toDouble() ?? 0,
      genderPreference: j['genderPreference'] ?? 'any',
      urgency: j['urgency'] ?? 'flexible',
      locationLat: (j['locationLat'] as num?)?.toDouble(),
      locationLon: (j['locationLon'] as num?)?.toDouble(),
      locationAddress: j['locationAddress'],
      isRemote: j['isRemote'] ?? false,
      estimatedHours: (j['estimatedHours'] as num?)?.toDouble(),
      requiredByTime: j['requiredByTime'],
      attachmentUrls: j['attachmentUrls'],
      createdAt: j['createdAt'] != null
          ? DateTime.tryParse(j['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      poster: j['poster'],
      targetedSeekerIds: parsedIds,
    );
  }
}

class BidModel {
  final int id;
  final int jobId;
  final int seekerId;
  final double offeredPrice;
  final String status;
  final String? message;
  final DateTime createdAt;
  final Map<String, dynamic>? seeker;

  const BidModel({
    required this.id,
    required this.jobId,
    required this.seekerId,
    required this.offeredPrice,
    required this.status,
    this.message,
    required this.createdAt,
    this.seeker,
  });

  factory BidModel.fromJson(Map<String, dynamic> j) => BidModel(
        id: j['id'] ?? 0,
        jobId: j['jobId'] ?? 0,
        seekerId: j['seekerId'] ?? 0,
        offeredPrice: (j['offeredPrice'] as num?)?.toDouble() ?? 0,
        status: j['status'] ?? 'pending',
        message: j['message'],
        createdAt: j['createdAt'] != null
            ? DateTime.tryParse(j['createdAt']) ?? DateTime.now()
            : DateTime.now(),
        seeker: j['seeker'],
      );
}

class ChatMessageModel {
  final int id;
  final int jobId;
  final int senderId;
  final int receiverId;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  const ChatMessageModel({
    required this.id,
    required this.jobId,
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> j) => ChatMessageModel(
        id: j['id'] ?? 0,
        jobId: j['jobId'] ?? 0,
        senderId: j['senderId'] ?? 0,
        receiverId: j['receiverId'] ?? 0,
        message: j['message'] ?? '',
        isRead: j['isRead'] ?? false,
        createdAt: j['createdAt'] != null
            ? DateTime.tryParse(j['createdAt']) ?? DateTime.now()
            : DateTime.now(),
      );
}
