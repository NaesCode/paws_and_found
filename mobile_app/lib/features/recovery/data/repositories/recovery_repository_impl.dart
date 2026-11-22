import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/recovery_claim_model.dart';
import 'dart:typed_data';

typedef UserProfileSummary = Map<String, dynamic>;

class ClaimRepository {
  final SupabaseClient _client = Supabase.instance.client;

  /// Streams all active claims for a report in real time
  Stream<List<PetClaim>> watchClaimsForReport(String reportId) {
    return _client
        .from('pet_claims')
        .stream(primaryKey: ['id'])
        .eq('report_id', reportId)
        .order('created_at')
        .map((rows) => rows.map((row) => PetClaim.fromJson(row)).toList());
  }

  /// Stage 1: Finder approves or declines
  Future<void> respondToStage1(String claimId, {required bool approve}) async {
    if (approve) {
      await _client.from('pet_claims').update({
        'stage1_approved': true,
        'current_stage': 2,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', claimId);
    } else {
      await _client.from('pet_claims').update({
        'status': 'declined',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', claimId);
    }
  }

  /// Stage 2: Finder approves verification
  Future<void> approveStage2(String claimId) async {
    await _client.from('pet_claims').update({
      'stage2_approved': true,
      'current_stage': 3,
      'stage2_feedback': null,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', claimId);
  }

  /// Stage 3: Propose meetup
  Future<void> proposeMeetup({
    required String claimId,
    required String placeName,
    required double lat,
    required double lng,
    required String time,
    required bool isFinder,
  }) async {
    final userId = _client.auth.currentUser?.id;
    await _client.from('pet_claims').update({
      'meetup_place': placeName,
      'meetup_lat': lat,
      'meetup_lng': lng,
      'meetup_time': time,
      'meetup_proposed_by': userId,
      'meetup_confirmed_by_finder': isFinder,
      'meetup_confirmed_by_claimer': !isFinder,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', claimId);
  }

  Future<void> confirmMeetup({
    required String claimId,
    required bool isFinder,
  }) async {
    await _client.from('pet_claims').update({
      if (isFinder) 'meetup_confirmed_by_finder': true,
      if (!isFinder) 'meetup_confirmed_by_claimer': true,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', claimId);
  }

  /// Stage 3: Confirm handover & auto-close report if both confirmed
  Future<void> confirmHandover(PetClaim claim, {required bool isFinder}) async {
    final nowBothConfirmed = isFinder
        ? claim.claimerConfirmedHandover
        : claim.finderConfirmedHandover;

    final Map<String, dynamic> updates = {
      if (isFinder) 'finder_confirmed_handover': true,
      if (!isFinder) 'claimer_confirmed_handover': true,
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (nowBothConfirmed) {
      updates['status'] = 'completed';
    }

    await _client
        .from('pet_claims')
        .update(updates)
        .eq('id', claim.id);
  }

  /// Fetches the reporter/owner ID of a report
  Future<String> getReportOwnerId(String reportId) async {
    final data = await _client
        .from('reports')
        .select('reporter_id')
        .eq('id', reportId)
        .maybeSingle();

    if (data == null || data['reporter_id'] == null) {
      throw Exception('Could not find report owner for report ID: $reportId');
    }

    return data['reporter_id'].toString();
  }

  /// Claimer initiates a new claim request (auto-resolves finderId if empty)
  Future<void> createClaimRequest({
    required String reportId,
    String? finderId,
    required String claimerId,
  }) async {
    final resolvedFinderId = (finderId != null && finderId.isNotEmpty)
        ? finderId
        : await getReportOwnerId(reportId);

    if (resolvedFinderId == claimerId) {
      throw Exception('You cannot submit a claim on your own report.');
    }

    await _client.from('pet_claims').insert({
      'report_id': reportId,
      'finder_id': resolvedFinderId,
      'claimer_id': claimerId,
      'current_stage': 1,
      'stage1_request_sent': true,
    });
  }

  Future<UserProfileSummary> getUserProfileSummary(String userId) async {
    try {
      final profile = await _client
          .from('profiles')
          .select('id, name, email, phone_number, profile_photo_url, created_at')
          .eq('id', userId)
          .maybeSingle();

      // total reports
      final reports = await _client
          .from('reports')
          .select('id')
          .eq('reporter_id', userId);
      final totalReports = (reports as List).length;

      // claims that are completed and verified by both parties
      final completedClaims = await _client
          .from('pet_claims')
          .select('id')
          .or('finder_id.eq.$userId,claimer_id.eq.$userId')
          .eq('status', 'completed')
          .eq('finder_confirmed_handover', true)
          .eq('claimer_confirmed_handover', true);
      final verifiedReunions = (completedClaims as List).length;

      String joinedText = 'Community Member';
      if (profile?['created_at'] != null) {
        final date = DateTime.tryParse(profile!['created_at'].toString());
        if (date != null) {
          const months = [
            'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
            'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
          ];
          joinedText = 'Member since ${months[date.month - 1]} ${date.year}';
        }
      }

      return {
        'name': profile?['name'] ?? 'Community Member',
        'email': profile?['email'] ?? 'No email provided',
        'phone': profile?['phone_number'] ?? 'No phone number provided',
        'avatarUrl': profile?['profile_photo_url'] ?? '',
        'joinedText': joinedText,
        'totalReports': totalReports,
        'verifiedReunions': verifiedReunions,
      };
    } catch (e) {
      return {
        'name': 'Community Member',
        'email': 'No email provided',
        'phone': 'No phone number provided',
        'avatarUrl': '',
        'joinedText': 'Community Member',
        'totalReports': 0,
        'verifiedReunions': 0,
      };
    }
  }
  
Future<String> uploadClaimProofFile({
    required String claimId,
    required Uint8List bytes,
    required String fileName,
    required String folder, // 'photos' or 'docs'
  }) async {
    final userId = _client.auth.currentUser?.id ?? 'anonymous';
    final sanitizedName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final storagePath =
        '$userId/claims/$claimId/$folder/${DateTime.now().millisecondsSinceEpoch}_$sanitizedName';

    final ext = sanitizedName.split('.').last.toLowerCase();
    final contentType = switch (ext) {
      'pdf' => 'application/pdf',
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };

    await _client.storage.from('recovery-proofs').uploadBinary(
          storagePath,
          bytes,
          fileOptions: FileOptions(
            upsert: true,
            contentType: contentType,
          ),
        );

    return _client.storage.from('recovery-proofs').getPublicUrl(storagePath);
  }

  Future<void> cleanupClaimProofFiles(PetClaim claim) async {
    const token = '/storage/v1/object/public/recovery-proofs/';
    final allUrls = [...claim.proofImageUrls, ...claim.docUrls];
    final pathsToRemove = <String>[];

    for (final url in allUrls) {
      if (url.contains(token)) {
        pathsToRemove.add(url.split(token).last);
      }
    }

    if (pathsToRemove.isNotEmpty) {
      await _client.storage.from('recovery-proofs').remove(pathsToRemove);
    }
  }

  Future<void> requestMoreStage2Info({
    required String claimId,
    required String feedbackMessage,
  }) async {
    await _client.from('pet_claims').update({
      'stage2_proof_submitted': false,
      'stage2_feedback': feedbackMessage,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', claimId);
  }

  Future<void> submitStage2Proof({
    required String claimId,
    required String note,
    required List<String> proofUrls,
    required List<String> docUrls,
  }) async {
    await _client.from('pet_claims').update({
      'unique_features_note': note,
      'proof_image_urls': proofUrls,
      'doc_urls': docUrls,
      'stage2_proof_submitted': true,
      'stage2_feedback': null,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', claimId);
  }

  
}

