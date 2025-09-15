import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'unified_notification_service.dart';
import 'notification_service.dart';

class MultilangNotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UnifiedNotificationService _unifiedNotificationService =
      UnifiedNotificationService();

  static const String _translationsCollection = 'notification_translations';
  static const String _userLanguagesCollection = 'user_languages';

  // Supported languages
  static const List<String> supportedLanguages = [
    'vi', // Vietnamese
    'en', // English
    'zh', // Chinese
    'ja', // Japanese
    'ko', // Korean
    'th', // Thai
    'id', // Indonesian
    'ms', // Malay
  ];

  static const String defaultLanguage = 'vi';

  // Lưu translation
  Future<void> saveTranslation({
    required String key,
    required String language,
    required String translation,
    required String category,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _firestore
          .collection(_translationsCollection)
          .doc('${key}_$language')
          .set({
            'key': key,
            'language': language,
            'translation': translation,
            'category': category,
            'metadata': metadata ?? {},
            'createdAt': Timestamp.fromDate(DateTime.now()),
            'updatedAt': Timestamp.fromDate(DateTime.now()),
          });

      print('✅ Translation saved: $key ($language)');
    } catch (e) {
      print('❌ Error saving translation: $e');
      throw Exception('Failed to save translation: $e');
    }
  }

  // Lấy translation
  Future<String?> getTranslation({
    required String key,
    required String language,
  }) async {
    try {
      final doc = await _firestore
          .collection(_translationsCollection)
          .doc('${key}_$language')
          .get();

      if (doc.exists) {
        return doc.data()?['translation'] as String?;
      }
      return null;
    } catch (e) {
      print('❌ Error getting translation: $e');
      return null;
    }
  }

  // Lấy tất cả translations cho một key
  Future<Map<String, String>> getTranslationsForKey(String key) async {
    try {
      final snapshot = await _firestore
          .collection(_translationsCollection)
          .where('key', isEqualTo: key)
          .get();

      Map<String, String> translations = {};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final language = data['language'] as String;
        final translation = data['translation'] as String;
        translations[language] = translation;
      }

      return translations;
    } catch (e) {
      print('❌ Error getting translations for key: $e');
      return {};
    }
  }

  // Lấy user language preference
  Future<String> getUserLanguage(String userId) async {
    try {
      final doc = await _firestore
          .collection(_userLanguagesCollection)
          .doc(userId)
          .get();

      if (doc.exists) {
        return doc.data()?['language'] as String? ?? defaultLanguage;
      }

      // Tạo default language preference
      await _firestore.collection(_userLanguagesCollection).doc(userId).set({
        'userId': userId,
        'language': defaultLanguage,
        'createdAt': Timestamp.fromDate(DateTime.now()),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      return defaultLanguage;
    } catch (e) {
      print('❌ Error getting user language: $e');
      return defaultLanguage;
    }
  }

  // Cập nhật user language preference
  Future<void> updateUserLanguage(String userId, String language) async {
    try {
      if (!supportedLanguages.contains(language)) {
        throw Exception('Unsupported language: $language');
      }

      await _firestore.collection(_userLanguagesCollection).doc(userId).set({
        'userId': userId,
        'language': language,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      }, SetOptions(merge: true));

      print('✅ User language updated: $userId -> $language');
    } catch (e) {
      print('❌ Error updating user language: $e');
      throw Exception('Failed to update user language: $e');
    }
  }

  // Gửi notification đa ngôn ngữ
  Future<bool> sendMultilangNotification({
    required String userId,
    required String titleKey,
    required String bodyKey,
    required NotificationType type,
    Map<String, dynamic>? data,
    NotificationPriority priority = NotificationPriority.normal,
    String? language,
  }) async {
    try {
      // Lấy language của user
      final userLanguage = language ?? await getUserLanguage(userId);

      // Lấy translations
      final titleTranslation = await getTranslation(
        key: titleKey,
        language: userLanguage,
      );

      final bodyTranslation = await getTranslation(
        key: bodyKey,
        language: userLanguage,
      );

      // Fallback to default language if translation not found
      final title =
          titleTranslation ??
          await getTranslation(key: titleKey, language: defaultLanguage) ??
          titleKey;

      final body =
          bodyTranslation ??
          await getTranslation(key: bodyKey, language: defaultLanguage) ??
          bodyKey;

      // Gửi notification
      return await _unifiedNotificationService.sendUnifiedNotification(
        userId: userId,
        title: title,
        body: body,
        type: type,
        data: {
          ...?data,
          'language': userLanguage,
          'titleKey': titleKey,
          'bodyKey': bodyKey,
        },
        priority: priority,
      );
    } catch (e) {
      print('❌ Error sending multilang notification: $e');
      return false;
    }
  }

  // Gửi bulk notification đa ngôn ngữ
  Future<Map<String, int>> sendBulkMultilangNotification({
    required List<String> userIds,
    required String titleKey,
    required String bodyKey,
    required NotificationType type,
    Map<String, dynamic>? data,
    NotificationPriority priority = NotificationPriority.normal,
  }) async {
    int successCount = 0;
    int failCount = 0;

    for (final userId in userIds) {
      try {
        final success = await sendMultilangNotification(
          userId: userId,
          titleKey: titleKey,
          bodyKey: bodyKey,
          type: type,
          data: data,
          priority: priority,
        );

        if (success) {
          successCount++;
        } else {
          failCount++;
        }
      } catch (e) {
        print('❌ Error sending multilang notification to $userId: $e');
        failCount++;
      }
    }

    print(
      '📊 Bulk multilang notification results: $successCount success, $failCount failed',
    );
    return {'success': successCount, 'failed': failCount};
  }

  // Lấy tất cả translations cho một category
  Future<Map<String, Map<String, String>>> getTranslationsByCategory(
    String category,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(_translationsCollection)
          .where('category', isEqualTo: category)
          .get();

      Map<String, Map<String, String>> translations = {};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final key = data['key'] as String;
        final language = data['language'] as String;
        final translation = data['translation'] as String;

        translations.putIfAbsent(key, () => {})[language] = translation;
      }

      return translations;
    } catch (e) {
      print('❌ Error getting translations by category: $e');
      return {};
    }
  }

  // Lấy missing translations
  Future<Map<String, List<String>>> getMissingTranslations() async {
    try {
      Map<String, List<String>> missing = {};

      for (final language in supportedLanguages) {
        final snapshot = await _firestore
            .collection(_translationsCollection)
            .where('language', isEqualTo: language)
            .get();

        final existingKeys = snapshot.docs
            .map((doc) => doc.data()['key'] as String)
            .toSet();

        // Lấy tất cả keys từ default language
        final defaultSnapshot = await _firestore
            .collection(_translationsCollection)
            .where('language', isEqualTo: defaultLanguage)
            .get();

        final allKeys = defaultSnapshot.docs
            .map((doc) => doc.data()['key'] as String)
            .toSet();

        final missingKeys = allKeys.difference(existingKeys).toList();
        if (missingKeys.isNotEmpty) {
          missing[language] = missingKeys;
        }
      }

      return missing;
    } catch (e) {
      print('❌ Error getting missing translations: $e');
      return {};
    }
  }

  // Tạo default translations
  Future<void> createDefaultTranslations() async {
    try {
      final defaultTranslations = {
        'notification.event_created.title': {
          'vi': 'Sự kiện mới',
          'en': 'New Event',
          'zh': '新活动',
          'ja': '新しいイベント',
          'ko': '새 이벤트',
          'th': 'กิจกรรมใหม่',
          'id': 'Acara Baru',
          'ms': 'Acara Baru',
        },
        'notification.event_created.body': {
          'vi': 'Có sự kiện mới: {{eventTitle}}',
          'en': 'New event available: {{eventTitle}}',
          'zh': '新活动可用：{{eventTitle}}',
          'ja': '新しいイベントが利用可能：{{eventTitle}}',
          'ko': '새 이벤트 사용 가능：{{eventTitle}}',
          'th': 'กิจกรรมใหม่พร้อมใช้งาน：{{eventTitle}}',
          'id': 'Acara baru tersedia：{{eventTitle}}',
          'ms': 'Acara baru tersedia：{{eventTitle}}',
        },
        'notification.event_reminder.title': {
          'vi': 'Nhắc nhở sự kiện',
          'en': 'Event Reminder',
          'zh': '活动提醒',
          'ja': 'イベントリマインダー',
          'ko': '이벤트 알림',
          'th': 'การแจ้งเตือนกิจกรรม',
          'id': 'Pengingat Acara',
          'ms': 'Peringatan Acara',
        },
        'notification.event_reminder.body': {
          'vi': 'Sự kiện {{eventTitle}} sẽ diễn ra trong {{timeRemaining}}',
          'en': 'Event {{eventTitle}} will start in {{timeRemaining}}',
          'zh': '活动{{eventTitle}}将在{{timeRemaining}}后开始',
          'ja': 'イベント{{eventTitle}}は{{timeRemaining}}後に開始されます',
          'ko': '이벤트{{eventTitle}}이(가) {{timeRemaining}} 후에 시작됩니다',
          'th': 'กิจกรรม{{eventTitle}}จะเริ่มใน{{timeRemaining}}',
          'id': 'Acara {{eventTitle}} akan dimulai dalam {{timeRemaining}}',
          'ms': 'Acara {{eventTitle}} akan bermula dalam {{timeRemaining}}',
        },
        'notification.registration_confirmed.title': {
          'vi': 'Đăng ký được xác nhận',
          'en': 'Registration Confirmed',
          'zh': '注册已确认',
          'ja': '登録確認済み',
          'ko': '등록 확인됨',
          'th': 'การลงทะเบียนได้รับการยืนยัน',
          'id': 'Pendaftaran Dikonfirmasi',
          'ms': 'Pendaftaran Disahkan',
        },
        'notification.registration_confirmed.body': {
          'vi': 'Đăng ký tham gia sự kiện {{eventTitle}} đã được xác nhận',
          'en': 'Your registration for {{eventTitle}} has been confirmed',
          'zh': '您对{{eventTitle}}的注册已确认',
          'ja': '{{eventTitle}}への登録が確認されました',
          'ko': '{{eventTitle}}에 대한 등록이 확인되었습니다',
          'th': 'การลงทะเบียนสำหรับ{{eventTitle}}ได้รับการยืนยันแล้ว',
          'id': 'Pendaftaran Anda untuk {{eventTitle}} telah dikonfirmasi',
          'ms': 'Pendaftaran anda untuk {{eventTitle}} telah disahkan',
        },
      };

      for (final entry in defaultTranslations.entries) {
        final key = entry.key;
        final translations = entry.value;

        for (final langEntry in translations.entries) {
          final language = langEntry.key;
          final translation = langEntry.value;

          await saveTranslation(
            key: key,
            language: language,
            translation: translation,
            category: 'notification',
            metadata: {'isDefault': true, 'createdBy': 'system'},
          );
        }
      }

      print('✅ Default translations created');
    } catch (e) {
      print('❌ Error creating default translations: $e');
    }
  }

  // Lấy language statistics
  Future<Map<String, dynamic>> getLanguageStatistics() async {
    try {
      final snapshot = await _firestore
          .collection(_userLanguagesCollection)
          .get();

      Map<String, int> languageCounts = {};
      int totalUsers = snapshot.docs.length;

      for (final doc in snapshot.docs) {
        final language = doc.data()['language'] as String? ?? defaultLanguage;
        languageCounts[language] = (languageCounts[language] ?? 0) + 1;
      }

      Map<String, double> languagePercentages = {};
      languageCounts.forEach((language, count) {
        languagePercentages[language] = totalUsers > 0
            ? (count / totalUsers * 100)
            : 0.0;
      });

      return {
        'totalUsers': totalUsers,
        'languageCounts': languageCounts,
        'languagePercentages': languagePercentages,
        'supportedLanguages': supportedLanguages,
        'defaultLanguage': defaultLanguage,
      };
    } catch (e) {
      print('❌ Error getting language statistics: $e');
      return {};
    }
  }

  // Lấy translation coverage
  Future<Map<String, dynamic>> getTranslationCoverage() async {
    try {
      Map<String, Map<String, int>> coverage = {};

      for (final language in supportedLanguages) {
        final snapshot = await _firestore
            .collection(_translationsCollection)
            .where('language', isEqualTo: language)
            .get();

        Map<String, int> categoryCounts = {};

        for (final doc in snapshot.docs) {
          final category = doc.data()['category'] as String;
          categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
        }

        coverage[language] = categoryCounts;
      }

      return {'coverage': coverage, 'supportedLanguages': supportedLanguages};
    } catch (e) {
      print('❌ Error getting translation coverage: $e');
      return {};
    }
  }

  // Auto-translate (placeholder - would integrate with translation API)
  Future<String?> autoTranslate({
    required String text,
    required String fromLanguage,
    required String toLanguage,
  }) async {
    // This would integrate with a translation service like Google Translate API
    // For now, return null to indicate manual translation needed
    print(
      '🔄 Auto-translation not implemented yet: $text ($fromLanguage -> $toLanguage)',
    );
    return null;
  }

  // Validate translation completeness
  Future<Map<String, dynamic>> validateTranslations() async {
    try {
      final missingTranslations = await getMissingTranslations();
      final coverage = await getTranslationCoverage();

      int totalMissing = missingTranslations.values
          .map((list) => list.length)
          .reduce((a, b) => a + b);

      return {
        'missingTranslations': missingTranslations,
        'coverage': coverage,
        'totalMissing': totalMissing,
        'isComplete': totalMissing == 0,
      };
    } catch (e) {
      print('❌ Error validating translations: $e');
      return {};
    }
  }
}
