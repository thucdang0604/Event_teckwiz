import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_design.dart';
import '../../models/certificate_template_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/certificate_service.dart';
import '../../widgets/custom_loading_indicator.dart';
import '../../widgets/custom_error_widget.dart';

class CertificateTemplateScreen extends StatefulWidget {
  const CertificateTemplateScreen({super.key});

  @override
  State<CertificateTemplateScreen> createState() =>
      _CertificateTemplateScreenState();
}

class _CertificateTemplateScreenState extends State<CertificateTemplateScreen> {
  final CertificateService _certificateService = CertificateService();
  List<CertificateTemplateModel> _templates = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
    _ensureDefaultTemplate();
  }

  Future<void> _loadTemplates() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final templates = await _certificateService.getAllTemplates();

      setState(() {
        _templates = templates;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _ensureDefaultTemplate() async {
    try {
      await _certificateService.createDefaultTemplateIfNotExists();
    } catch (e) {
      print('Error ensuring default template: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Certificate Templates'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadTemplates,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
          IconButton(
            onPressed: _showCreateTemplateDialog,
            icon: const Icon(Icons.add),
            tooltip: 'Create Template',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CustomLoadingIndicator());
    }

    if (_error != null) {
      return Center(
        child: CustomErrorWidget(message: _error!, onRetry: _loadTemplates),
      );
    }

    if (_templates.isEmpty) {
      return _buildEmptyState();
    }

    return _buildTemplatesList();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.description_outlined,
            size: 100,
            color: AppColors.primary.withOpacity(0.3),
          ),
          const SizedBox(height: 24),
          Text(
            'No Templates Found',
            style: AppDesign.heading1.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          Text(
            'Create your first certificate template',
            style: AppDesign.bodyLarge.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showCreateTemplateDialog,
            icon: const Icon(Icons.add),
            label: const Text('Create Template'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplatesList() {
    return RefreshIndicator(
      onRefresh: _loadTemplates,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _templates.length,
        itemBuilder: (context, index) {
          final template = _templates[index];
          return _buildTemplateCard(template);
        },
      ),
    );
  }

  Widget _buildTemplateCard(CertificateTemplateModel template) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.description,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              template.name,
                              style: AppDesign.heading3.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (template.isDefault)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.success.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.success.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                'Default',
                                style: AppDesign.bodySmall.copyWith(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        template.description,
                        style: AppDesign.bodyLarge.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) => _handleTemplateAction(value, template),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        leading: Icon(Icons.edit),
                        title: Text('Edit'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    if (!template.isDefault)
                      const PopupMenuItem(
                        value: 'set_default',
                        child: ListTile(
                          leading: Icon(Icons.star),
                          title: Text('Set as Default'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    if (!template.isDefault)
                      const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete, color: Colors.red),
                          title: Text(
                            'Delete',
                            style: TextStyle(color: Colors.red),
                          ),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                  ],
                  child: Icon(Icons.more_vert, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.person, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Created by ${template.createdByName}',
                    style: AppDesign.bodyLarge.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Created on ${_formatDate(template.createdAt)}',
                    style: AppDesign.bodyLarge.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _handleTemplateAction(String action, CertificateTemplateModel template) {
    switch (action) {
      case 'edit':
        _showEditTemplateDialog(template);
        break;
      case 'set_default':
        _setAsDefaultTemplate(template);
        break;
      case 'delete':
        _showDeleteConfirmation(template);
        break;
    }
  }

  void _showCreateTemplateDialog() {
    showDialog(
      context: context,
      builder: (context) => CertificateTemplateDialog(onSave: _createTemplate),
    );
  }

  void _showEditTemplateDialog(CertificateTemplateModel template) {
    showDialog(
      context: context,
      builder: (context) => CertificateTemplateDialog(
        template: template,
        onSave: (updatedTemplate) =>
            _updateTemplate(template.id, updatedTemplate),
      ),
    );
  }

  Future<void> _createTemplate(CertificateTemplateModel template) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.currentUser;

      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      final newTemplate = template.copyWith(
        createdBy: currentUser.id,
        createdByName: currentUser.fullName,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _certificateService.createTemplate(newTemplate);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Template created successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        _loadTemplates();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating template: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _updateTemplate(
    String templateId,
    CertificateTemplateModel template,
  ) async {
    try {
      final updatedTemplate = template.copyWith(updatedAt: DateTime.now());

      await _certificateService.updateTemplate(templateId, updatedTemplate);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Template updated successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        _loadTemplates();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating template: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _setAsDefaultTemplate(CertificateTemplateModel template) async {
    try {
      // Set all templates to not default first
      for (final t in _templates) {
        if (t.isDefault) {
          await _certificateService.updateTemplate(
            t.id,
            t.copyWith(isDefault: false),
          );
        }
      }

      // Set selected template as default
      await _certificateService.updateTemplate(
        template.id,
        template.copyWith(isDefault: true),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Default template updated successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        _loadTemplates();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error setting default template: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showDeleteConfirmation(CertificateTemplateModel template) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Template'),
        content: Text('Are you sure you want to delete "${template.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteTemplate(template);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTemplate(CertificateTemplateModel template) async {
    try {
      await _certificateService.deleteTemplate(template.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Template deleted successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        _loadTemplates();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting template: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

class CertificateTemplateDialog extends StatefulWidget {
  final CertificateTemplateModel? template;
  final Function(CertificateTemplateModel) onSave;

  const CertificateTemplateDialog({
    super.key,
    this.template,
    required this.onSave,
  });

  @override
  State<CertificateTemplateDialog> createState() =>
      _CertificateTemplateDialogState();
}

class _CertificateTemplateDialogState extends State<CertificateTemplateDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _templateUrlController;
  late TextEditingController _backgroundColorController;
  late TextEditingController _textColorController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.template?.name ?? '');
    _descriptionController = TextEditingController(
      text: widget.template?.description ?? '',
    );
    _templateUrlController = TextEditingController(
      text: widget.template?.templateUrl ?? '',
    );
    _backgroundColorController = TextEditingController(
      text: widget.template?.backgroundColor ?? '#FFFFFF',
    );
    _textColorController = TextEditingController(
      text: widget.template?.textColor ?? '#000000',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _templateUrlController.dispose();
    _backgroundColorController.dispose();
    _textColorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.template != null;

    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              isEditing ? 'Edit Template' : 'Create Template',
              style: AppDesign.heading1,
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Template Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter template name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter description';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _templateUrlController,
                        decoration: const InputDecoration(
                          labelText: 'Template URL',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter template URL';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _backgroundColorController,
                              decoration: const InputDecoration(
                                labelText: 'Background Color',
                                border: OutlineInputBorder(),
                                prefixText: '#',
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _textColorController,
                              decoration: const InputDecoration(
                                labelText: 'Text Color',
                                border: OutlineInputBorder(),
                                prefixText: '#',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Advanced Settings',
                        style: AppDesign.heading3.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Font Settings',
                        style: AppDesign.bodyLarge.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue:
                                  widget.template?.titleFont ?? 'Arial',
                              decoration: const InputDecoration(
                                labelText: 'Title Font',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              initialValue:
                                  widget.template?.bodyFont ?? 'Arial',
                              decoration: const InputDecoration(
                                labelText: 'Body Font',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue:
                                  widget.template?.titleFontSize.toString() ??
                                  '24.0',
                              decoration: const InputDecoration(
                                labelText: 'Title Font Size',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              initialValue:
                                  widget.template?.bodyFontSize.toString() ??
                                  '16.0',
                              decoration: const InputDecoration(
                                labelText: 'Body Font Size',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveTemplate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                    ),
                    child: Text(isEditing ? 'Update' : 'Create'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _saveTemplate() {
    if (!_formKey.currentState!.validate()) return;

    final template = CertificateTemplateModel(
      id: widget.template?.id ?? '',
      name: _nameController.text,
      description: _descriptionController.text,
      templateUrl: _templateUrlController.text,
      backgroundColor: _backgroundColorController.text,
      textColor: _textColorController.text,
      titleFont: 'Arial',
      bodyFont: 'Arial',
      signatureFont: 'Arial',
      titleFontSize: double.tryParse('24.0') ?? 24.0,
      bodyFontSize: double.tryParse('16.0') ?? 16.0,
      signatureFontSize: 14.0,
      titlePosition: const {'x': 0.5, 'y': 0.2},
      recipientNamePosition: const {'x': 0.5, 'y': 0.4},
      eventTitlePosition: const {'x': 0.5, 'y': 0.5},
      issuedDatePosition: const {'x': 0.5, 'y': 0.6},
      signaturePosition: const {'x': 0.7, 'y': 0.8},
      certificateNumberPosition: const {'x': 0.1, 'y': 0.9},
      createdBy: widget.template?.createdBy ?? '',
      createdByName: widget.template?.createdByName ?? '',
      createdAt: widget.template?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      isActive: true,
      isDefault: widget.template?.isDefault ?? false,
    );

    widget.onSave(template);
    Navigator.of(context).pop();
  }
}
