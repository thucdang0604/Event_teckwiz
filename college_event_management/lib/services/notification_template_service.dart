import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'unified_notification_service.dart';
import 'notification_service.dart';

enum TemplateStatus { draft, active, inactive, archived }

enum TemplateType { email, push, sms, inApp }

class NotificationTemplate {
  final String id;
  final String name;
  final String description;
  final TemplateType type;
  final NotificationType notificationType;
  final String subject;
  final String title;
  final String body;
  final String htmlContent;
  final String textContent;
  final Map<String, dynamic> variables;
  final Map<String, dynamic> styling;
  final TemplateStatus status;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int version;
  final List<String> tags;
  final Map<String, dynamic> metadata;

  NotificationTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.notificationType,
    required this.subject,
    required this.title,
    required this.body,
    required this.htmlContent,
    required this.textContent,
    this.variables = const {},
    this.styling = const {},
    this.status = TemplateStatus.draft,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.version = 1,
    this.tags = const [],
    this.metadata = const {},
  });

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.name,
      'notificationType': notificationType.name,
      'subject': subject,
      'title': title,
      'body': body,
      'htmlContent': htmlContent,
      'textContent': textContent,
      'variables': variables,
      'styling': styling,
      'status': status.name,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'version': version,
      'tags': tags,
      'metadata': metadata,
    };
  }

  factory NotificationTemplate.fromFirestore(Map<String, dynamic> data) {
    return NotificationTemplate(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      type: TemplateType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => TemplateType.email,
      ),
      notificationType: NotificationType.values.firstWhere(
        (e) => e.name == data['notificationType'],
        orElse: () => NotificationType.systemAnnouncement,
      ),
      subject: data['subject'] ?? '',
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      htmlContent: data['htmlContent'] ?? '',
      textContent: data['textContent'] ?? '',
      variables: Map<String, dynamic>.from(data['variables'] ?? {}),
      styling: Map<String, dynamic>.from(data['styling'] ?? {}),
      status: TemplateStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => TemplateStatus.draft,
      ),
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      version: data['version'] ?? 1,
      tags: List<String>.from(data['tags'] ?? []),
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  NotificationTemplate copyWith({
    String? id,
    String? name,
    String? description,
    TemplateType? type,
    NotificationType? notificationType,
    String? subject,
    String? title,
    String? body,
    String? htmlContent,
    String? textContent,
    Map<String, dynamic>? variables,
    Map<String, dynamic>? styling,
    TemplateStatus? status,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? version,
    List<String>? tags,
    Map<String, dynamic>? metadata,
  }) {
    return NotificationTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      notificationType: notificationType ?? this.notificationType,
      subject: subject ?? this.subject,
      title: title ?? this.title,
      body: body ?? this.body,
      htmlContent: htmlContent ?? this.htmlContent,
      textContent: textContent ?? this.textContent,
      variables: variables ?? this.variables,
      styling: styling ?? this.styling,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
      tags: tags ?? this.tags,
      metadata: metadata ?? this.metadata,
    );
  }
}

class NotificationTemplateService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UnifiedNotificationService _unifiedNotificationService =
      UnifiedNotificationService();

  static const String _templatesCollection = 'notification_templates';
  static const String _templateVersionsCollection = 'template_versions';

  // Tạo template mới
  Future<String> createTemplate(NotificationTemplate template) async {
    try {
      await _firestore
          .collection(_templatesCollection)
          .doc(template.id)
          .set(template.toFirestore());

      print('✅ Template created: ${template.name}');
      return template.id;
    } catch (e) {
      print('❌ Error creating template: $e');
      throw Exception('Failed to create template: $e');
    }
  }

  // Cập nhật template
  Future<void> updateTemplate(NotificationTemplate template) async {
    try {
      final updatedTemplate = template.copyWith(
        updatedAt: DateTime.now(),
        version: template.version + 1,
      );

      // Lưu version cũ
      await _saveTemplateVersion(template);

      // Cập nhật template mới
      await _firestore
          .collection(_templatesCollection)
          .doc(template.id)
          .update(updatedTemplate.toFirestore());

      print('✅ Template updated: ${template.name}');
    } catch (e) {
      print('❌ Error updating template: $e');
      throw Exception('Failed to update template: $e');
    }
  }

  // Lưu version của template
  Future<void> _saveTemplateVersion(NotificationTemplate template) async {
    try {
      await _firestore.collection(_templateVersionsCollection).add({
        'templateId': template.id,
        'version': template.version,
        'template': template.toFirestore(),
        'savedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      print('❌ Error saving template version: $e');
    }
  }

  // Lấy template theo ID
  Future<NotificationTemplate?> getTemplate(String templateId) async {
    try {
      final doc = await _firestore
          .collection(_templatesCollection)
          .doc(templateId)
          .get();

      if (doc.exists) {
        return NotificationTemplate.fromFirestore(doc.data()!);
      }
      return null;
    } catch (e) {
      print('❌ Error getting template: $e');
      return null;
    }
  }

  // Lấy danh sách templates
  Future<List<NotificationTemplate>> getTemplates({
    TemplateType? type,
    NotificationType? notificationType,
    TemplateStatus? status,
    String? searchQuery,
    List<String>? tags,
    int limit = 50,
  }) async {
    try {
      Query query = _firestore
          .collection(_templatesCollection)
          .orderBy('updatedAt', descending: true)
          .limit(limit);

      if (type != null) {
        query = query.where('type', isEqualTo: type.name);
      }

      if (notificationType != null) {
        query = query.where(
          'notificationType',
          isEqualTo: notificationType.name,
        );
      }

      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }

      final snapshot = await query.get();

      List<NotificationTemplate> templates = snapshot.docs
          .map(
            (doc) => NotificationTemplate.fromFirestore(
              doc.data() as Map<String, dynamic>,
            ),
          )
          .toList();

      // Filter by search query
      if (searchQuery != null && searchQuery.isNotEmpty) {
        templates = templates.where((template) {
          return template.name.toLowerCase().contains(
                searchQuery.toLowerCase(),
              ) ||
              template.description.toLowerCase().contains(
                searchQuery.toLowerCase(),
              ) ||
              template.tags.any(
                (tag) => tag.toLowerCase().contains(searchQuery.toLowerCase()),
              );
        }).toList();
      }

      // Filter by tags
      if (tags != null && tags.isNotEmpty) {
        templates = templates.where((template) {
          return tags.any((tag) => template.tags.contains(tag));
        }).toList();
      }

      return templates;
    } catch (e) {
      print('❌ Error getting templates: $e');
      return [];
    }
  }

  // Xóa template
  Future<void> deleteTemplate(String templateId) async {
    try {
      await _firestore.collection(_templatesCollection).doc(templateId).update({
        'status': TemplateStatus.archived.name,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      print('✅ Template archived: $templateId');
    } catch (e) {
      print('❌ Error deleting template: $e');
      throw Exception('Failed to delete template: $e');
    }
  }

  // Kích hoạt template
  Future<void> activateTemplate(String templateId) async {
    try {
      await _firestore.collection(_templatesCollection).doc(templateId).update({
        'status': TemplateStatus.active.name,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      print('✅ Template activated: $templateId');
    } catch (e) {
      print('❌ Error activating template: $e');
      throw Exception('Failed to activate template: $e');
    }
  }

  // Vô hiệu hóa template
  Future<void> deactivateTemplate(String templateId) async {
    try {
      await _firestore.collection(_templatesCollection).doc(templateId).update({
        'status': TemplateStatus.inactive.name,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      print('✅ Template deactivated: $templateId');
    } catch (e) {
      print('❌ Error deactivating template: $e');
      throw Exception('Failed to deactivate template: $e');
    }
  }

  // Render template với variables
  Future<Map<String, String>> renderTemplate(
    String templateId,
    Map<String, dynamic> variables,
  ) async {
    try {
      final template = await getTemplate(templateId);
      if (template == null) {
        throw Exception('Template not found: $templateId');
      }

      String renderedSubject = _interpolateString(template.subject, variables);
      String renderedTitle = _interpolateString(template.title, variables);
      String renderedBody = _interpolateString(template.body, variables);
      String renderedHtml = _interpolateString(template.htmlContent, variables);
      String renderedText = _interpolateString(template.textContent, variables);

      return {
        'subject': renderedSubject,
        'title': renderedTitle,
        'body': renderedBody,
        'htmlContent': renderedHtml,
        'textContent': renderedText,
      };
    } catch (e) {
      print('❌ Error rendering template: $e');
      throw Exception('Failed to render template: $e');
    }
  }

  // Interpolate string với variables
  String _interpolateString(String template, Map<String, dynamic> variables) {
    String result = template;

    variables.forEach((key, value) {
      result = result.replaceAll('{{$key}}', value.toString());
    });

    return result;
  }

  // Gửi notification sử dụng template
  Future<bool> sendNotificationWithTemplate({
    required String templateId,
    required String userId,
    required Map<String, dynamic> variables,
    NotificationPriority priority = NotificationPriority.normal,
  }) async {
    try {
      final template = await getTemplate(templateId);
      if (template == null) {
        throw Exception('Template not found: $templateId');
      }

      if (template.status != TemplateStatus.active) {
        throw Exception('Template is not active: ${template.status}');
      }

      final rendered = await renderTemplate(templateId, variables);

      return await _unifiedNotificationService.sendUnifiedNotification(
        userId: userId,
        title: rendered['title']!,
        body: rendered['body']!,
        type: template.notificationType,
        data: {
          'templateId': templateId,
          'templateName': template.name,
          'subject': rendered['subject'],
          'htmlContent': rendered['htmlContent'],
          'textContent': rendered['textContent'],
          ...variables,
        },
        priority: priority,
      );
    } catch (e) {
      print('❌ Error sending notification with template: $e');
      return false;
    }
  }

  // Gửi bulk notification sử dụng template
  Future<Map<String, int>> sendBulkNotificationWithTemplate({
    required String templateId,
    required List<String> userIds,
    required Map<String, dynamic> baseVariables,
    required String variableKey, // Key để lấy user-specific variables
    NotificationPriority priority = NotificationPriority.normal,
  }) async {
    int successCount = 0;
    int failCount = 0;

    for (final userId in userIds) {
      try {
        // Lấy user-specific variables
        final userVariables = await _getUserSpecificVariables(
          userId,
          variableKey,
        );
        final allVariables = {...baseVariables, ...userVariables};

        final success = await sendNotificationWithTemplate(
          templateId: templateId,
          userId: userId,
          variables: allVariables,
          priority: priority,
        );

        if (success) {
          successCount++;
        } else {
          failCount++;
        }
      } catch (e) {
        print('❌ Error sending template notification to $userId: $e');
        failCount++;
      }
    }

    print(
      '📊 Bulk template notification results: $successCount success, $failCount failed',
    );
    return {'success': successCount, 'failed': failCount};
  }

  // Lấy user-specific variables
  Future<Map<String, dynamic>> _getUserSpecificVariables(
    String userId,
    String variableKey,
  ) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();

      if (doc.exists) {
        final userData = doc.data()!;
        return Map<String, dynamic>.from(userData[variableKey] ?? {});
      }
      return {};
    } catch (e) {
      print('❌ Error getting user-specific variables: $e');
      return {};
    }
  }

  // Lấy template versions
  Future<List<Map<String, dynamic>>> getTemplateVersions(
    String templateId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(_templateVersionsCollection)
          .where('templateId', isEqualTo: templateId)
          .orderBy('version', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'version': data['version'],
          'template': data['template'],
          'savedAt': data['savedAt'],
        };
      }).toList();
    } catch (e) {
      print('❌ Error getting template versions: $e');
      return [];
    }
  }

  // Restore template version
  Future<void> restoreTemplateVersion(String templateId, int version) async {
    try {
      final snapshot = await _firestore
          .collection(_templateVersionsCollection)
          .where('templateId', isEqualTo: templateId)
          .where('version', isEqualTo: version)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final versionData = snapshot.docs.first.data();
        final templateData = versionData['template'] as Map<String, dynamic>;

        // Cập nhật template với version data
        await _firestore
            .collection(_templatesCollection)
            .doc(templateId)
            .update({
              ...templateData,
              'updatedAt': Timestamp.fromDate(DateTime.now()),
            });

        print('✅ Template restored to version $version');
      }
    } catch (e) {
      print('❌ Error restoring template version: $e');
      throw Exception('Failed to restore template version: $e');
    }
  }

  // Lấy template statistics
  Future<Map<String, dynamic>> getTemplateStatistics(String templateId) async {
    try {
      // Lấy số lần sử dụng template
      final usageSnapshot = await _firestore
          .collection('notification_logs')
          .where('data.templateId', isEqualTo: templateId)
          .get();

      final totalUsage = usageSnapshot.docs.length;
      final successfulUsage = usageSnapshot.docs
          .where((doc) => doc.data()['success'] == true)
          .length;

      return {
        'templateId': templateId,
        'totalUsage': totalUsage,
        'successfulUsage': successfulUsage,
        'successRate': totalUsage > 0
            ? (successfulUsage / totalUsage * 100).toStringAsFixed(2)
            : '0.00',
        'lastUsed': usageSnapshot.docs.isNotEmpty
            ? usageSnapshot.docs.first.data()['timestamp']
            : null,
      };
    } catch (e) {
      print('❌ Error getting template statistics: $e');
      return {};
    }
  }

  // Clone template
  Future<String> cloneTemplate(String templateId, String newName) async {
    try {
      final originalTemplate = await getTemplate(templateId);
      if (originalTemplate == null) {
        throw Exception('Template not found: $templateId');
      }

      final clonedTemplate = originalTemplate.copyWith(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: newName,
        status: TemplateStatus.draft,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        version: 1,
      );

      return await createTemplate(clonedTemplate);
    } catch (e) {
      print('❌ Error cloning template: $e');
      throw Exception('Failed to clone template: $e');
    }
  }
}
