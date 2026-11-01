import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:paws_and_found/core/services/ai_pre_match_service.dart';
import 'package:paws_and_found/features/report/data/models/ai_match_candidate.dart';
import 'package:paws_and_found/features/report/domain/entities/report.dart';
import 'package:paws_and_found/features/report/domain/repositories/report_repository.dart';
import 'package:paws_and_found/features/report/presentation/providers/camera_report_controller.dart';

class MockReportRepository implements ReportRepository {
  String? lastCreatedLinkedReportId;

  @override
  Future<List<SightingReport>> getNearbyReports({
    required double lat,
    required double lng,
    double radiusM = 5000,
    String? animalType,
    int limit = 200,
  }) async {
    return [];
  }

  @override
  Future<String> createReport({
    required String animalType,
    required String description,
    required String photoUrl,
    required double lat,
    required double lng,
    String status = 'stray',
    String? petId,
    String? locationName,
    String? linkedReportId,
  }) async {
    lastCreatedLinkedReportId = linkedReportId;
    return 'mock-report-123';
  }

  @override
  Future<String> uploadReportPhoto(Uint8List bytes, {String extension = 'jpg'}) async {
    return 'https://supabase.co/storage/mock.jpg';
  }

  @override
  Future<void> requestReportAnalysis(String reportId) async {}
}

class MockAiPreMatchService implements AiPreMatchService {
  List<AiMatchCandidate> mockCandidates = [];

  @override
  Future<List<AiMatchCandidate>> scanForCandidates({
    required Uint8List imageBytes,
    required double lat,
    required double lng,
    String? animalType,
  }) async {
    return mockCandidates;
  }
}

void main() {
  group('AiMatchCandidate Model Tests', () {
    test('deserializes from JSON correctly and calculates percentages', () {
      final json = {
        'pet_id': 'pet-1',
        'report_id': 'rep-missing-1',
        'pet_name': 'Luna',
        'species': 'Dog',
        'photo_url': 'https://example.com/luna.jpg',
        'similarity_score': 0.942,
        'distance_km': 1.45,
        'last_seen_location': 'Mandaue City',
        'owner_name': 'Maria Santos',
      };

      final candidate = AiMatchCandidate.fromJson(json);

      expect(candidate.petId, equals('pet-1'));
      expect(candidate.reportId, equals('rep-missing-1'));
      expect(candidate.petName, equals('Luna'));
      expect(candidate.species, equals('Dog'));
      expect(candidate.photoUrl, equals('https://example.com/luna.jpg'));
      expect(candidate.similarityScore, closeTo(0.942, 0.001));
      expect(candidate.similarityPercent, equals(94));
      expect(candidate.isHighConfidence, isTrue);
      expect(candidate.distanceKm, closeTo(1.45, 0.01));
      expect(candidate.lastSeenLocation, equals('Mandaue City'));
      expect(candidate.ownerName, equals('Maria Santos'));
    });

    test('isHighConfidence is false when similarity is below threshold', () {
      final candidate = AiMatchCandidate(
        petId: 'pet-2',
        reportId: 'rep-missing-2',
        petName: 'Milo',
        species: 'Cat',
        photoUrl: 'https://example.com/milo.jpg',
        similarityScore: 0.72,
      );

      expect(candidate.similarityPercent, equals(72));
      expect(candidate.isHighConfidence, isFalse);
    });

    test('toJson serializes all fields properly', () {
      final candidate = AiMatchCandidate(
        petId: 'pet-1',
        reportId: 'rep-missing-1',
        petName: 'Luna',
        species: 'Dog',
        photoUrl: 'https://example.com/luna.jpg',
        similarityScore: 0.91,
        distanceKm: 2.3,
        lastSeenLocation: 'Banilad',
        ownerName: 'Juan',
      );

      final json = candidate.toJson();
      expect(json['pet_id'], equals('pet-1'));
      expect(json['report_id'], equals('rep-missing-1'));
      expect(json['pet_name'], equals('Luna'));
      expect(json['similarity_score'], equals(0.91));
      expect(json['distance_km'], equals(2.3));
    });
  });

  group('CameraReportController with AI Pre-Matching Tests', () {
    late MockReportRepository mockRepo;
    late MockAiPreMatchService mockAiService;
    late CameraReportController controller;

    setUp(() {
      mockRepo = MockReportRepository();
      mockAiService = MockAiPreMatchService();
      controller = CameraReportController(
        repository: mockRepo,
        preMatchService: mockAiService,
      );
    });

    tearDown(() {
      controller.dispose();
    });

    test('initial AI state is idle and empty', () {
      expect(controller.isScanningAi, isFalse);
      expect(controller.aiCandidates, isEmpty);
      expect(controller.selectedAiCandidate, isNull);
      expect(controller.linkedThreadId, isNull);
    });

    test('selectAiCandidate sets linkedThreadId, petName and candidate', () {
      final candidate = AiMatchCandidate(
        petId: 'pet-luna',
        reportId: 'rep-luna-missing',
        petName: 'Luna',
        species: 'Dog',
        photoUrl: 'https://example.com/luna.jpg',
        similarityScore: 0.95,
      );

      controller.selectAiCandidate(candidate);

      expect(controller.selectedAiCandidate, equals(candidate));
      expect(controller.linkedThreadId, equals('rep-luna-missing'));
      expect(controller.linkedThreadPetName, equals('Luna'));
    });

    test('clearAiCandidate clears selection and thread context', () {
      final candidate = AiMatchCandidate(
        petId: 'pet-luna',
        reportId: 'rep-luna-missing',
        petName: 'Luna',
        species: 'Dog',
        photoUrl: 'https://example.com/luna.jpg',
        similarityScore: 0.95,
      );

      controller.selectAiCandidate(candidate);
      expect(controller.linkedThreadId, isNotNull);

      controller.clearAiCandidate();
      expect(controller.selectedAiCandidate, isNull);
      expect(controller.linkedThreadId, isNull);
      expect(controller.linkedThreadPetName, isNull);
    });

    test('runAiPreMatchScan populates candidates from service', () async {
      final List<AiMatchCandidate> candidates = [
        AiMatchCandidate(
          petId: 'pet-1',
          reportId: 'rep-1',
          petName: 'Luna',
          species: 'Dog',
          photoUrl: 'https://example.com/luna.jpg',
          similarityScore: 0.96,
        ),
        AiMatchCandidate(
          petId: 'pet-2',
          reportId: 'rep-2',
          petName: 'Bella',
          species: 'Dog',
          photoUrl: 'https://example.com/bella.jpg',
          similarityScore: 0.88,
        ),
      ];
      mockAiService.mockCandidates = candidates;

      controller.setImageData(Uint8List.fromList([1, 2, 3, 4]), 'test.jpg');
      await controller.runAiPreMatchScan();

      expect(controller.isScanningAi, isFalse);
      expect(controller.aiCandidates.length, equals(2));
      expect(controller.aiCandidates.first.petName, equals('Luna'));
    });

    test('clearPhoto clears image and resets AI candidates', () {
      controller.setImageData(Uint8List.fromList([1, 2, 3]), 'test.jpg');
      controller.selectAiCandidate(AiMatchCandidate(
        petId: 'p',
        reportId: 'r',
        petName: 'Pet',
        species: 'Dog',
        photoUrl: '',
        similarityScore: 0.9,
      ));

      controller.clearPhoto();

      expect(controller.selectedImageBytes, isNull);
      expect(controller.selectedImagePath, isNull);
      expect(controller.aiCandidates, isEmpty);
      expect(controller.selectedAiCandidate, isNull);
    });

    test('submitReport passes linkedReportId to repository', () async {
      final candidate = AiMatchCandidate(
        petId: 'pet-luna',
        reportId: 'rep-luna-missing',
        petName: 'Luna',
        species: 'Dog',
        photoUrl: '',
        similarityScore: 0.95,
      );

      controller.selectAiCandidate(candidate);
      controller.setImageData(Uint8List.fromList([1, 2, 3]), 'sample.jpg');

      final success = await controller.submitReport();

      expect(success, isTrue);
      expect(mockRepo.lastCreatedLinkedReportId, equals('rep-luna-missing'));
    });
  });
}
