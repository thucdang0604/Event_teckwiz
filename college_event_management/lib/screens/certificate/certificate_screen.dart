import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_design.dart';
import '../../models/certificate_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/certificate_service.dart';
import '../../widgets/custom_loading_indicator.dart';
import '../../widgets/custom_error_widget.dart';

class CertificateScreen extends StatefulWidget {
  const CertificateScreen({super.key});

  @override
  State<CertificateScreen> createState() => _CertificateScreenState();
}

class _CertificateScreenState extends State<CertificateScreen> {
  final CertificateService _certificateService = CertificateService();
  List<CertificateModel> _certificates = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCertificates();
  }

  Future<void> _loadCertificates() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.currentUser;

      if (currentUser == null) {
        setState(() {
          _error = 'User not logged in';
          _isLoading = false;
        });
        return;
      }

      final certificates = await _certificateService.getUserCertificates(
        currentUser.id,
      );

      setState(() {
        _certificates = certificates;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Certificates'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadCertificates,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
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
        child: CustomErrorWidget(message: _error!, onRetry: _loadCertificates),
      );
    }

    if (_certificates.isEmpty) {
      return _buildEmptyState();
    }

    return _buildCertificatesList();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.emoji_events_outlined,
            size: 100,
            color: AppColors.primary.withOpacity(0.3),
          ),
          const SizedBox(height: 24),
          Text(
            'No Certificates Yet',
            style: AppDesign.heading1.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          Text(
            'Complete events to earn certificates',
            style: AppDesign.bodyLarge.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadCertificates,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
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

  Widget _buildCertificatesList() {
    return RefreshIndicator(
      onRefresh: _loadCertificates,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _certificates.length,
        itemBuilder: (context, index) {
          final certificate = _certificates[index];
          return _buildCertificateCard(certificate);
        },
      ),
    );
  }

  Widget _buildCertificateCard(CertificateModel certificate) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _viewCertificate(certificate),
        borderRadius: BorderRadius.circular(12),
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
                      Icons.emoji_events,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          certificate.eventTitle,
                          style: AppDesign.heading3.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Certificate #${certificate.certificateNumber}',
                          style: AppDesign.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: AppColors.textSecondary,
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
                      certificate.userName,
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
                    Icons.business,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Issued by ${certificate.issuedByName}',
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
                      _formatDate(certificate.issuedAt),
                      style: AppDesign.bodyLarge.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.success.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 16,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Verified',
                      style: AppDesign.bodySmall.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _viewCertificate(CertificateModel certificate) {
    showDialog(
      context: context,
      builder: (context) => CertificateViewDialog(certificate: certificate),
    );
  }
}

class CertificateViewDialog extends StatelessWidget {
  final CertificateModel certificate;

  const CertificateViewDialog({super.key, required this.certificate});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.emoji_events, color: AppColors.white, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Certificate of Participation',
                      style: AppDesign.heading3.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: AppColors.white),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Certificate Preview (Mock)
                    Container(
                      width: double.infinity,
                      height: 300,
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border, width: 2),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.emoji_events,
                            size: 64,
                            color: AppColors.primary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Certificate of Participation',
                            style: AppDesign.heading1.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'This is to certify that',
                            style: AppDesign.bodyLarge,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            certificate.userName,
                            style: AppDesign.heading3.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'has successfully participated in',
                            style: AppDesign.bodyLarge,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            certificate.eventTitle,
                            style: AppDesign.heading3.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Certificate #${certificate.certificateNumber}',
                            style: AppDesign.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Certificate Details
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow(
                            'Certificate Number',
                            certificate.certificateNumber,
                          ),
                          const SizedBox(height: 8),
                          _buildDetailRow('Event', certificate.eventTitle),
                          const SizedBox(height: 8),
                          _buildDetailRow('Participant', certificate.userName),
                          const SizedBox(height: 8),
                          _buildDetailRow(
                            'Issued By',
                            certificate.issuedByName,
                          ),
                          const SizedBox(height: 8),
                          _buildDetailRow(
                            'Issue Date',
                            _formatDate(certificate.issuedAt),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _downloadCertificate(context),
                            icon: const Icon(Icons.download),
                            label: const Text('Download PDF'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: BorderSide(color: AppColors.primary),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _shareCertificate(context),
                            icon: const Icon(Icons.share),
                            label: const Text('Share'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: AppDesign.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(child: Text(value, style: AppDesign.bodyLarge)),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _downloadCertificate(BuildContext context) {
    // TODO: Implement PDF download
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('PDF download feature will be implemented soon'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _shareCertificate(BuildContext context) {
    // TODO: Implement certificate sharing
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share feature will be implemented soon'),
        backgroundColor: AppColors.primary,
      ),
    );
  }
}
