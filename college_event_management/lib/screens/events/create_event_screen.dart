import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/event_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/event_model.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _maxParticipantsController = TextEditingController();
  final _requirementsController = TextEditingController();
  final _contactInfoController = TextEditingController();
  final _priceController = TextEditingController();

  String _selectedCategory = AppConstants.eventCategories.first;
  String _selectedStatus = AppConstants.eventDraft;
  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  DateTime _endDate = DateTime.now().add(const Duration(days: 2));
  DateTime _registrationDeadline = DateTime.now().add(
    const Duration(hours: 12),
  );
  bool _isFree = true;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _maxParticipantsController.dispose();
    _requirementsController.dispose();
    _contactInfoController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(
    DateTime initialDate,
    Function(DateTime) onDateSelected,
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate),
      );

      if (time != null) {
        final DateTime selectedDateTime = DateTime(
          picked.year,
          picked.month,
          picked.day,
          time.hour,
          time.minute,
        );
        onDateSelected(selectedDateTime);
      }
    }
  }

  void _createEvent() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final eventProvider = Provider.of<EventProvider>(context, listen: false);

      if (authProvider.currentUser == null) return;

      final event = EventModel(
        id: '', // Will be generated
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        location: _locationController.text.trim(),
        startDate: _startDate,
        endDate: _endDate,
        registrationDeadline: _registrationDeadline,
        maxParticipants: int.parse(_maxParticipantsController.text),
        status: _selectedStatus,
        organizerId: authProvider.currentUser!.id,
        organizerName: authProvider.currentUser!.fullName,
        requirements: _requirementsController.text.trim().isNotEmpty
            ? _requirementsController.text.trim()
            : null,
        contactInfo: _contactInfoController.text.trim().isNotEmpty
            ? _contactInfoController.text.trim()
            : null,
        isFree: _isFree,
        price: _isFree ? null : double.tryParse(_priceController.text),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      bool success = await eventProvider.createEvent(event);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tạo sự kiện thành công!'),
            backgroundColor: AppColors.success,
          ),
        );
        context.go('/home');
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(eventProvider.errorMessage ?? 'Tạo sự kiện thất bại'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        // Kiểm tra quyền tạo sự kiện
        if (authProvider.currentUser?.role != 'organizer' &&
            authProvider.currentUser?.role != 'admin') {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Tạo sự kiện mới'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              ),
            ),
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.block, size: 64, color: AppColors.error),
                  SizedBox(height: 16),
                  Text(
                    'Bạn không có quyền tạo sự kiện',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Chỉ có staff mới có thể tạo sự kiện',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Tạo sự kiện mới'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
            actions: [
              TextButton(
                onPressed: _createEvent,
                child: const Text(
                  'Lưu',
                  style: TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          body: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Basic Information
                  const Text(
                    'Thông tin cơ bản',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 16),

                  CustomTextField(
                    controller: _titleController,
                    label: 'Tên sự kiện *',
                    hint: 'Nhập tên sự kiện',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập tên sự kiện';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  CustomTextField(
                    controller: _descriptionController,
                    label: 'Mô tả *',
                    hint: 'Mô tả chi tiết về sự kiện',
                    maxLines: 4,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập mô tả sự kiện';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Category
                  const Text(
                    'Danh mục *',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.grey),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCategory,
                        isExpanded: true,
                        items: AppConstants.eventCategories.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCategory = value!;
                          });
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  CustomTextField(
                    controller: _locationController,
                    label: 'Địa điểm *',
                    hint: 'Nhập địa điểm tổ chức',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập địa điểm';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  // Date and Time
                  const Text(
                    'Thời gian',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Start Date
                  InkWell(
                    onTap: () => _selectDate(_startDate, (date) {
                      setState(() {
                        _startDate = date;
                      });
                    }),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.grey),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Ngày bắt đầu',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                DateFormat(
                                  AppConstants.dateTimeFormat,
                                ).format(_startDate),
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // End Date
                  InkWell(
                    onTap: () => _selectDate(_endDate, (date) {
                      setState(() {
                        _endDate = date;
                      });
                    }),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.grey),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Ngày kết thúc',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                DateFormat(
                                  AppConstants.dateTimeFormat,
                                ).format(_endDate),
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Registration Deadline
                  InkWell(
                    onTap: () => _selectDate(_registrationDeadline, (date) {
                      setState(() {
                        _registrationDeadline = date;
                      });
                    }),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.grey),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Hạn đăng ký',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                DateFormat(
                                  AppConstants.dateTimeFormat,
                                ).format(_registrationDeadline),
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Participants and Pricing
                  const Text(
                    'Tham gia và giá',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 16),

                  CustomTextField(
                    controller: _maxParticipantsController,
                    label: 'Số lượng tham gia tối đa *',
                    hint: 'Nhập số lượng',
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập số lượng tham gia';
                      }
                      if (int.tryParse(value) == null ||
                          int.parse(value) <= 0) {
                        return 'Số lượng phải là số dương';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Free/Paid toggle
                  Row(
                    children: [
                      const Text(
                        'Sự kiện miễn phí',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      Switch(
                        value: _isFree,
                        onChanged: (value) {
                          setState(() {
                            _isFree = value;
                          });
                        },
                        activeColor: AppColors.primary,
                      ),
                    ],
                  ),

                  if (!_isFree) ...[
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _priceController,
                      label: 'Giá vé (VNĐ)',
                      hint: 'Nhập giá vé',
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.attach_money,
                      validator: (value) {
                        if (!_isFree && (value == null || value.isEmpty)) {
                          return 'Vui lòng nhập giá vé';
                        }
                        if (!_isFree &&
                            (double.tryParse(value!) == null ||
                                double.parse(value) < 0)) {
                          return 'Giá vé phải là số dương';
                        }
                        return null;
                      },
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Additional Information
                  const Text(
                    'Thông tin bổ sung',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 16),

                  CustomTextField(
                    controller: _requirementsController,
                    label: 'Yêu cầu tham gia',
                    hint: 'Nhập các yêu cầu (không bắt buộc)',
                    maxLines: 3,
                  ),

                  const SizedBox(height: 16),

                  CustomTextField(
                    controller: _contactInfoController,
                    label: 'Thông tin liên hệ',
                    hint: 'Nhập thông tin liên hệ (không bắt buộc)',
                    maxLines: 2,
                  ),

                  const SizedBox(height: 32),

                  // Create Button
                  Consumer<EventProvider>(
                    builder: (context, eventProvider, _) {
                      return CustomButton(
                        text: 'Tạo sự kiện',
                        onPressed: eventProvider.isLoading
                            ? null
                            : _createEvent,
                        isLoading: eventProvider.isLoading,
                      );
                    },
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
