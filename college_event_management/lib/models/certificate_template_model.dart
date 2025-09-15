import 'package:cloud_firestore/cloud_firestore.dart';

class CertificateTemplateModel {
  final String id;
  final String name;
  final String description;
  final String templateUrl;
  final String backgroundColor;
  final String textColor;
  final String titleFont;
  final String bodyFont;
  final String signatureFont;
  final double titleFontSize;
  final double bodyFontSize;
  final double signatureFontSize;
  final Map<String, dynamic> titlePosition;
  final Map<String, dynamic> recipientNamePosition;
  final Map<String, dynamic> eventTitlePosition;
  final Map<String, dynamic> issuedDatePosition;
  final Map<String, dynamic> signaturePosition;
  final Map<String, dynamic> certificateNumberPosition;
  final String createdBy;
  final String createdByName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final bool isDefault;

  CertificateTemplateModel({
    required this.id,
    required this.name,
    required this.description,
    required this.templateUrl,
    this.backgroundColor = '#FFFFFF',
    this.textColor = '#000000',
    this.titleFont = 'Arial',
    this.bodyFont = 'Arial',
    this.signatureFont = 'Arial',
    this.titleFontSize = 24.0,
    this.bodyFontSize = 16.0,
    this.signatureFontSize = 14.0,
    this.titlePosition = const {'x': 0.5, 'y': 0.2},
    this.recipientNamePosition = const {'x': 0.5, 'y': 0.4},
    this.eventTitlePosition = const {'x': 0.5, 'y': 0.5},
    this.issuedDatePosition = const {'x': 0.5, 'y': 0.6},
    this.signaturePosition = const {'x': 0.7, 'y': 0.8},
    this.certificateNumberPosition = const {'x': 0.1, 'y': 0.9},
    required this.createdBy,
    required this.createdByName,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.isDefault = false,
  });

  factory CertificateTemplateModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return CertificateTemplateModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      templateUrl: data['templateUrl'] ?? '',
      backgroundColor: data['backgroundColor'] ?? '#FFFFFF',
      textColor: data['textColor'] ?? '#000000',
      titleFont: data['titleFont'] ?? 'Arial',
      bodyFont: data['bodyFont'] ?? 'Arial',
      signatureFont: data['signatureFont'] ?? 'Arial',
      titleFontSize: (data['titleFontSize'] ?? 24.0).toDouble(),
      bodyFontSize: (data['bodyFontSize'] ?? 16.0).toDouble(),
      signatureFontSize: (data['signatureFontSize'] ?? 14.0).toDouble(),
      titlePosition: Map<String, dynamic>.from(
        data['titlePosition'] ?? {'x': 0.5, 'y': 0.2},
      ),
      recipientNamePosition: Map<String, dynamic>.from(
        data['recipientNamePosition'] ?? {'x': 0.5, 'y': 0.4},
      ),
      eventTitlePosition: Map<String, dynamic>.from(
        data['eventTitlePosition'] ?? {'x': 0.5, 'y': 0.5},
      ),
      issuedDatePosition: Map<String, dynamic>.from(
        data['issuedDatePosition'] ?? {'x': 0.5, 'y': 0.6},
      ),
      signaturePosition: Map<String, dynamic>.from(
        data['signaturePosition'] ?? {'x': 0.7, 'y': 0.8},
      ),
      certificateNumberPosition: Map<String, dynamic>.from(
        data['certificateNumberPosition'] ?? {'x': 0.1, 'y': 0.9},
      ),
      createdBy: data['createdBy'] ?? '',
      createdByName: data['createdByName'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      isActive: data['isActive'] ?? true,
      isDefault: data['isDefault'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'templateUrl': templateUrl,
      'backgroundColor': backgroundColor,
      'textColor': textColor,
      'titleFont': titleFont,
      'bodyFont': bodyFont,
      'signatureFont': signatureFont,
      'titleFontSize': titleFontSize,
      'bodyFontSize': bodyFontSize,
      'signatureFontSize': signatureFontSize,
      'titlePosition': titlePosition,
      'recipientNamePosition': recipientNamePosition,
      'eventTitlePosition': eventTitlePosition,
      'issuedDatePosition': issuedDatePosition,
      'signaturePosition': signaturePosition,
      'certificateNumberPosition': certificateNumberPosition,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
      'isDefault': isDefault,
    };
  }

  CertificateTemplateModel copyWith({
    String? id,
    String? name,
    String? description,
    String? templateUrl,
    String? backgroundColor,
    String? textColor,
    String? titleFont,
    String? bodyFont,
    String? signatureFont,
    double? titleFontSize,
    double? bodyFontSize,
    double? signatureFontSize,
    Map<String, dynamic>? titlePosition,
    Map<String, dynamic>? recipientNamePosition,
    Map<String, dynamic>? eventTitlePosition,
    Map<String, dynamic>? issuedDatePosition,
    Map<String, dynamic>? signaturePosition,
    Map<String, dynamic>? certificateNumberPosition,
    String? createdBy,
    String? createdByName,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    bool? isDefault,
  }) {
    return CertificateTemplateModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      templateUrl: templateUrl ?? this.templateUrl,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textColor: textColor ?? this.textColor,
      titleFont: titleFont ?? this.titleFont,
      bodyFont: bodyFont ?? this.bodyFont,
      signatureFont: signatureFont ?? this.signatureFont,
      titleFontSize: titleFontSize ?? this.titleFontSize,
      bodyFontSize: bodyFontSize ?? this.bodyFontSize,
      signatureFontSize: signatureFontSize ?? this.signatureFontSize,
      titlePosition: titlePosition ?? this.titlePosition,
      recipientNamePosition:
          recipientNamePosition ?? this.recipientNamePosition,
      eventTitlePosition: eventTitlePosition ?? this.eventTitlePosition,
      issuedDatePosition: issuedDatePosition ?? this.issuedDatePosition,
      signaturePosition: signaturePosition ?? this.signaturePosition,
      certificateNumberPosition:
          certificateNumberPosition ?? this.certificateNumberPosition,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}
