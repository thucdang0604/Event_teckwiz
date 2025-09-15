import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../utils/navigation_helper.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../providers/event_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/admin_provider.dart';
import '../../models/event_model.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import '../../services/image_service.dart';
import '../../services/event_service.dart';

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
  final _maxSupportStaffController = TextEditingController();

  String _selectedCategory = AppConstants.eventCategories.first;
  final String _selectedStatus = 'pending';
  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  DateTime _endDate = DateTime.now().add(const Duration(days: 2));
  DateTime _registrationDeadline = DateTime.now().add(
    const Duration(hours: 12),
  );
  String? _registrationDeadlineError;
  bool _isFree = true;

  // Media upload
  final ImagePicker _imagePicker = ImagePicker();
  final ImageService _imageService = ImageService();
  final List<File> _selectedImages = [];
  final List<File> _selectedVideos = [];
  String? _selectedLocationId;
  final EventService _eventService = EventService();
  final Set<int> _bookedHours = {};
  // removed auto-duration usage; keeping default 1 hour logic inline
  final Set<int> _bookedHoursEnd = {};
  bool _selectingStart = true;
  // Removed co-organizer variables as they're now managed through invitation system
  @override
  void initState() {
    super.initState();
    // Load locations for dropdown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final adminProvider = Provider.of<AdminProvider>(context, listen: false);
      adminProvider.loadLocations();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _maxParticipantsController.dispose();
    _requirementsController.dispose();
    _contactInfoController.dispose();
    _priceController.dispose();
    _maxSupportStaffController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage();
      setState(() {
        _selectedImages.addAll(images.map((image) => File(image.path)));
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting images: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _pickVideo() async {
    try {
      final XFile? video = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
      );
      if (video != null) {
        setState(() {
          _selectedVideos.add(File(video.path));
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting video: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _removeVideo(int index) {
    setState(() {
      _selectedVideos.removeAt(index);
    });
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
      final DateTime selectedDateTime = DateTime(
        picked.year,
        picked.month,
        picked.day,
        initialDate.hour,
        initialDate.minute,
      );
      onDateSelected(selectedDateTime);
      if (onDateSelected == _onStartDateSelected) {
        _loadBookedHoursForStartDate(selectedDateTime);
      } else if (onDateSelected == _onEndDateSelected) {
        _loadBookedHoursForEndDate(selectedDateTime);
      }
    }
  }

  void _onStartDateSelected(DateTime dt) {
    setState(() {
      _startDate = dt;
      if (!_endDate.isAfter(_startDate)) {
        _endDate = _startDate.add(const Duration(hours: 1));
      }
    });
  }

  void _onEndDateSelected(DateTime dt) {
    setState(() {
      _endDate = dt.isAfter(_startDate)
          ? dt
          : _startDate.add(const Duration(hours: 1));
    });
  }

  Future<void> _loadBookedHoursForStartDate(DateTime date) async {
    _bookedHours.clear();
    if (_selectedLocationId == null) {
      setState(() {});
      return;
    }
    try {
      final events = await _eventService.getEvents();
      final sameDayEvents = events.where((e) {
        final sameLocation = e.location == _locationController.text;
        // Check if event overlaps with the given date
        final dayStart = DateTime(date.year, date.month, date.day, 0, 0);
        final dayEnd = DateTime(date.year, date.month, date.day, 23, 59, 59);
        final eventOverlaps =
            e.startDate.isBefore(dayEnd) && e.endDate.isAfter(dayStart);
        return sameLocation && eventOverlaps;
      }).toList();

      for (int h = 0; h < 24; h++) {
        final slotStart = DateTime(date.year, date.month, date.day, h, 0);
        final slotEnd = slotStart.add(const Duration(hours: 1));
        final overlaps = sameDayEvents.any((ev) {
          final evStart = ev.startDate;
          final evEnd = ev.endDate;
          return slotStart.isBefore(evEnd) && slotEnd.isAfter(evStart);
        });
        if (overlaps) {
          _bookedHours.add(h);
        }
      }
      setState(() {});
      print(
        'Loaded ${_bookedHours.length} booked hours for start date ${date.toString()}: ${_bookedHours.toList()}',
      );
    } catch (e) {
      print('Error loading booked hours for start date: $e');
      setState(() {});
    }
  }

  Future<void> _loadBookedHoursForEndDate(DateTime date) async {
    _bookedHoursEnd.clear();
    if (_selectedLocationId == null) {
      setState(() {});
      return;
    }
    try {
      final events = await _eventService.getEvents();
      final sameDayEvents = events.where((e) {
        final sameLocation = e.location == _locationController.text;
        // Check if event overlaps with the given date
        final dayStart = DateTime(date.year, date.month, date.day, 0, 0);
        final dayEnd = DateTime(date.year, date.month, date.day, 23, 59, 59);
        final eventOverlaps =
            e.startDate.isBefore(dayEnd) && e.endDate.isAfter(dayStart);
        return sameLocation && eventOverlaps;
      }).toList();

      for (int h = 0; h < 24; h++) {
        final slotStart = DateTime(date.year, date.month, date.day, h, 0);
        final slotEnd = slotStart.add(const Duration(hours: 1));
        final overlaps = sameDayEvents.any((ev) {
          final evStart = ev.startDate;
          final evEnd = ev.endDate;
          return slotStart.isBefore(evEnd) && slotEnd.isAfter(evStart);
        });
        if (overlaps) {
          _bookedHoursEnd.add(h);
        }
      }
      setState(() {});
      print(
        'Loaded ${_bookedHoursEnd.length} booked hours for end date ${date.toString()}: ${_bookedHoursEnd.toList()}',
      );
    } catch (e) {
      print('Error loading booked hours for end date: $e');
      setState(() {});
    }
  }

  Future<bool> _isRangeAvailable(DateTime start, DateTime end) async {
    try {
      final events = await _eventService.getEvents();
      final sameLocationEvents = events.where(
        (e) => e.location == _locationController.text,
      );

      // Lấy danh sách các ngày trong khoảng thời gian
      final days = <DateTime>[];
      DateTime currentDay = DateTime(start.year, start.month, start.day);
      final endDay = DateTime(end.year, end.month, end.day);

      while (!currentDay.isAfter(endDay)) {
        days.add(currentDay);
        currentDay = currentDay.add(const Duration(days: 1));
      }

      // Kiểm tra xung đột cho từng ngày
      for (final day in days) {
        final dayStart =
            day.isAtSameMomentAs(DateTime(start.year, start.month, start.day))
            ? start
            : DateTime(day.year, day.month, day.day, 0, 0);
        final dayEnd =
            day.isAtSameMomentAs(DateTime(end.year, end.month, end.day))
            ? end
            : DateTime(day.year, day.month, day.day, 23, 59);

        for (final ev in sameLocationEvents) {
          final evStart = ev.startDate;
          final evEnd = ev.endDate;

          // Kiểm tra xung đột trong ngày này
          if (dayStart.isBefore(evEnd) && dayEnd.isAfter(evStart)) {
            // Kiểm tra xem có cùng ngày không
            final evDay = DateTime(evStart.year, evStart.month, evStart.day);
            if (evDay.isAtSameMomentAs(day)) {
              return false;
            }
          }
        }
      }

      return true;
    } catch (_) {
      return true;
    }
  }

  void _ensureContinuousTime() {
    if (_startDate.isAfter(_endDate)) {
      _endDate = _startDate.add(const Duration(hours: 1));
    }
  }

  void _createEvent() async {
    // Check registration deadline validation
    if (_registrationDeadline.isAfter(_startDate) ||
        _registrationDeadline.isAtSameMomentAs(_startDate)) {
      setState(() {
        _registrationDeadlineError =
            'Registration deadline must be before event start time';
      });
      return;
    }

    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final eventProvider = Provider.of<EventProvider>(context, listen: false);

      if (authProvider.currentUser == null) return;

      try {
        // Upload images and videos
        List<String> imageUrls = [];
        List<String> videoUrls = [];

        // Upload images
        for (File image in _selectedImages) {
          String imageUrl = await _imageService.uploadImage(image);
          imageUrls.add(imageUrl);
        }

        // Upload videos
        for (File video in _selectedVideos) {
          String videoUrl = await _imageService.uploadVideo(video);
          videoUrls.add(videoUrl);
        }

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
          coOrganizers: [], // Không thêm co-organizers trực tiếp
          maxSupportStaff: int.tryParse(_maxSupportStaffController.text) ?? 0,
          requirements: _requirementsController.text.trim().isNotEmpty
              ? _requirementsController.text.trim()
              : null,
          contactInfo: _contactInfoController.text.trim().isNotEmpty
              ? _contactInfoController.text.trim()
              : null,
          isFree: _isFree,
          price: _isFree ? null : double.tryParse(_priceController.text),
          imageUrls: imageUrls,
          videoUrls: videoUrls,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        bool success = await eventProvider.createEvent(event);

        if (success && mounted) {
          // Gửi lời mời co-organizer sau khi tạo event thành công
          // Co-organizer invitations are now sent through the invitation system after event creation

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Event created successfully! You can now invite co-organizers from the event details.',
              ),
              backgroundColor: AppColors.success,
            ),
          );
          context.go('/home');
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                eventProvider.errorMessage ?? 'Failed to create event',
              ),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error uploading media: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, AdminProvider>(
      builder: (context, authProvider, adminProvider, _) {
        // Check event creation permissions
        if (authProvider.currentUser?.role != 'organizer' &&
            authProvider.currentUser?.role != 'admin') {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Create New Event'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => safePop(context),
              ),
            ),
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.block, size: 64, color: AppColors.error),
                  SizedBox(height: 16),
                  Text(
                    'You don\'t have permission to create events',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Only staff members can create events',
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
            title: const Text('Create New Event'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => safePop(context),
            ),
            actions: [
              TextButton(
                onPressed: _createEvent,
                child: const Text(
                  'Save',
                  style: TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              return Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 32,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Basic Information
                        const Text(
                          'Basic Information',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),

                        const SizedBox(height: 16),

                        CustomTextField(
                          controller: _titleController,
                          label: 'Event Title *',
                          hint: 'Enter event title',
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter event title';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        CustomTextField(
                          controller: _descriptionController,
                          label: 'Description *',
                          hint: 'Enter detailed event description',
                          maxLines: 4,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter event description';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // Category
                        const Text(
                          'Category *',
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
                              items: AppConstants.eventCategories.map((
                                category,
                              ) {
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

                        const Text(
                          'Location *',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _selectedLocationId,
                          items: adminProvider.locations
                              .map(
                                (loc) => DropdownMenuItem<String>(
                                  value: loc.id,
                                  child: Text(loc.name),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedLocationId = val;
                              if (val != null) {
                                final loc = adminProvider.locations.firstWhere(
                                  (l) => l.id == val,
                                );
                                _locationController.text = loc.name;
                              }
                            });
                            _loadBookedHoursForStartDate(_startDate);
                            _loadBookedHoursForEndDate(_endDate);
                          },
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return 'Please select a location';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 24),

                        // Date and Time
                        const Text(
                          'Date & Time',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Event Time (combined selector)
                        InkWell(
                          onTap: _openDateTimeSheet,
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
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Event Time',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      Text(
                                        '${DateFormat(AppConstants.dateTimeFormat).format(_startDate.toLocal())} - ${DateFormat(AppConstants.dateTimeFormat).format(_endDate.toLocal())}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: AppColors.textSecondary,
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Registration Deadline
                        if (_registrationDeadlineError != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.error),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.warning,
                                  color: AppColors.error,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _registrationDeadlineError!,
                                    style: const TextStyle(
                                      color: AppColors.error,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        InkWell(
                          onTap: () => _selectDate(_registrationDeadline, (
                            date,
                          ) {
                            setState(() {
                              _registrationDeadline = date;
                              _registrationDeadlineError = null;
                              if (_registrationDeadline.isAfter(_startDate) ||
                                  _registrationDeadline.isAtSameMomentAs(
                                    _startDate,
                                  )) {
                                _registrationDeadlineError =
                                    'Registration deadline must be before event start time';
                              }
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
                                      'Registration Deadline',
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
                          'Participants & Pricing',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),

                        const SizedBox(height: 16),

                        CustomTextField(
                          controller: _maxParticipantsController,
                          label: 'Maximum Participants *',
                          hint: 'Enter maximum number of participants',
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter maximum participants';
                            }
                            if (int.tryParse(value) == null ||
                                int.parse(value) <= 0) {
                              return 'Number must be positive';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // Free/Paid toggle
                        Row(
                          children: [
                            const Text(
                              'Free Event',
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
                            label: 'Ticket Price (USD)',
                            hint: 'Enter ticket price',
                            keyboardType: TextInputType.number,
                            prefixIcon: Icons.attach_money,
                            validator: (value) {
                              if (!_isFree &&
                                  (value == null || value.isEmpty)) {
                                return 'Please enter ticket price';
                              }
                              if (!_isFree &&
                                  (double.tryParse(value!) == null ||
                                      double.parse(value) < 0)) {
                                return 'Price must be positive';
                              }
                              return null;
                            },
                          ),
                        ],

                        const SizedBox(height: 24),

                        // Co-Organizers & Support Staff
                        const Text(
                          'Co-Organizers & Support Staff',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Note: Co-Organizers are now managed through the invitation system
                        // after event creation, not during creation
                        const SizedBox(height: 16),

                        // Max Support Staff
                        CustomTextField(
                          controller: _maxSupportStaffController,
                          label: 'Maximum Support Staff',
                          hint:
                              'Enter maximum support staff count (0 if not needed)',
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              final num = int.tryParse(value);
                              if (num == null || num < 0) {
                                return 'Must be a non-negative integer';
                              }
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 24),

                        // Additional Information
                        const Text(
                          'Additional Information',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),

                        const SizedBox(height: 16),

                        CustomTextField(
                          controller: _requirementsController,
                          label: 'Participation Requirements',
                          hint: 'Enter participation requirements (optional)',
                          maxLines: 3,
                        ),

                        const SizedBox(height: 16),

                        CustomTextField(
                          controller: _contactInfoController,
                          label: 'Contact Information',
                          hint: 'Enter contact information (optional)',
                          maxLines: 2,
                        ),

                        const SizedBox(height: 24),

                        // Media Upload Section
                        const Text(
                          'Images & Videos',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Image Upload
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Event Images',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    TextButton.icon(
                                      onPressed: _pickImages,
                                      icon: const Icon(
                                        Icons.add_photo_alternate,
                                      ),
                                      label: const Text('Select Images'),
                                    ),
                                  ],
                                ),
                                if (_selectedImages.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    height: 100,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: _selectedImages.length,
                                      itemBuilder: (context, index) {
                                        return Container(
                                          margin: const EdgeInsets.only(
                                            right: 8,
                                          ),
                                          child: Stack(
                                            children: [
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                child: Image.file(
                                                  _selectedImages[index],
                                                  width: 100,
                                                  height: 100,
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                              Positioned(
                                                top: 4,
                                                right: 4,
                                                child: GestureDetector(
                                                  onTap: () =>
                                                      _removeImage(index),
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.all(4),
                                                    decoration:
                                                        const BoxDecoration(
                                                          color:
                                                              AppColors.error,
                                                          shape:
                                                              BoxShape.circle,
                                                        ),
                                                    child: const Icon(
                                                      Icons.close,
                                                      color: AppColors.white,
                                                      size: 16,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ] else
                                  Container(
                                    height: 100,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: AppColors.grey,
                                        style: BorderStyle.solid,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.image,
                                            size: 32,
                                            color: AppColors.grey,
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            'No images selected',
                                            style: TextStyle(
                                              color: AppColors.grey,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Video Upload
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Event Videos',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    TextButton.icon(
                                      onPressed: _pickVideo,
                                      icon: const Icon(Icons.videocam),
                                      label: const Text('Select Video'),
                                    ),
                                  ],
                                ),
                                if (_selectedVideos.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: _selectedVideos.length,
                                    itemBuilder: (context, index) {
                                      return Container(
                                        margin: const EdgeInsets.only(
                                          bottom: 8,
                                        ),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: AppColors.greyLight,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.play_circle_outline,
                                              color: AppColors.primary,
                                              size: 24,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                _selectedVideos[index].path
                                                    .split('/')
                                                    .last,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: AppColors.textPrimary,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            IconButton(
                                              onPressed: () =>
                                                  _removeVideo(index),
                                              icon: const Icon(
                                                Icons.close,
                                                color: AppColors.error,
                                                size: 20,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ] else
                                  Container(
                                    height: 60,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: AppColors.grey,
                                        style: BorderStyle.solid,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.videocam_outlined,
                                            size: 24,
                                            color: AppColors.grey,
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            'No video selected',
                                            style: TextStyle(
                                              color: AppColors.grey,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Create Button
                        Consumer<EventProvider>(
                          builder: (context, eventProvider, _) {
                            return CustomButton(
                              text: 'Create Event',
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
          ),
        );
      },
    );
  }

  void _openDateTimeSheet() async {
    if (_selectedLocationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a location first'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          minChildSize: 0.6,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return StatefulBuilder(
              builder: (context, sbSetState) {
                return SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          const Text(
                            'Select Event Time',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Date selector
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.grey),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Event Schedule:',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () async {
                                      final DateTime? picked =
                                          await showDatePicker(
                                            context: context,
                                            initialDate: _startDate,
                                            firstDate: DateTime.now(),
                                            lastDate: DateTime.now().add(
                                              const Duration(days: 365),
                                            ),
                                          );
                                      if (picked != null) {
                                        setState(() {
                                          _startDate = DateTime(
                                            picked.year,
                                            picked.month,
                                            picked.day,
                                            _startDate.hour,
                                            0,
                                          );
                                          _ensureContinuousTime();
                                        });
                                        await _loadBookedHoursForStartDate(
                                          _startDate,
                                        );
                                        sbSetState(() {});
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(
                                          0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              const Text(
                                                'Start Date',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              const Icon(
                                                Icons.edit,
                                                size: 14,
                                                color: AppColors.primary,
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            DateFormat(
                                              'dd/MM/yyyy',
                                            ).format(_startDate),
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () async {
                                      final DateTime? picked =
                                          await showDatePicker(
                                            context: context,
                                            initialDate: _endDate,
                                            firstDate: _startDate,
                                            lastDate: DateTime.now().add(
                                              const Duration(days: 365),
                                            ),
                                          );
                                      if (picked != null) {
                                        setState(() {
                                          _endDate = DateTime(
                                            picked.year,
                                            picked.month,
                                            picked.day,
                                            _endDate.hour,
                                            0,
                                          );
                                          _ensureContinuousTime();
                                        });
                                        await _loadBookedHoursForEndDate(
                                          _endDate,
                                        );
                                        sbSetState(() {});
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppColors.success.withOpacity(
                                          0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: AppColors.success,
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              const Text(
                                                'End Date',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              const Icon(
                                                Icons.edit,
                                                size: 14,
                                                color: AppColors.success,
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            DateFormat(
                                              'dd/MM/yyyy',
                                            ).format(_endDate),
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.success,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Step indicator
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: _selectingStart
                                        ? AppColors.primary
                                        : Colors.grey,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '1',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _selectingStart
                                        ? 'Step 1: Select Start Time'
                                        : 'Step 1: Start Time Selected',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: _selectingStart
                                          ? AppColors.primary
                                          : Colors.grey,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: !_selectingStart
                                        ? AppColors.success
                                        : Colors.grey,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '2',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    !_selectingStart
                                        ? 'Step 2: Select End Time'
                                        : 'Step 2: Select End Time',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: !_selectingStart
                                          ? AppColors.success
                                          : Colors.grey,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Time selection buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                setState(() => _selectingStart = true);
                                _loadBookedHoursForStartDate(_startDate);
                                sbSetState(() {});
                              },
                              icon: Icon(
                                Icons.play_arrow,
                                color: _selectingStart
                                    ? Colors.white
                                    : AppColors.primary,
                              ),
                              label: Text(
                                'Select Start Time',
                                style: TextStyle(
                                  color: _selectingStart
                                      ? Colors.white
                                      : AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _selectingStart
                                    ? AppColors.primary
                                    : Colors.white,
                                foregroundColor: _selectingStart
                                    ? Colors.white
                                    : AppColors.primary,
                                side: BorderSide(
                                  color: AppColors.primary,
                                  width: 2,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                elevation: _selectingStart ? 4 : 2,
                                shadowColor: _selectingStart
                                    ? AppColors.primary.withOpacity(0.3)
                                    : Colors.grey.withOpacity(0.2),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                setState(() => _selectingStart = false);
                                _loadBookedHoursForEndDate(_endDate);
                                sbSetState(() {});
                              },
                              icon: Icon(
                                Icons.stop,
                                color: !_selectingStart
                                    ? Colors.white
                                    : AppColors.success,
                              ),
                              label: Text(
                                'Select End Time',
                                style: TextStyle(
                                  color: !_selectingStart
                                      ? Colors.white
                                      : AppColors.success,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: !_selectingStart
                                    ? AppColors.success
                                    : Colors.white,
                                foregroundColor: !_selectingStart
                                    ? Colors.white
                                    : AppColors.success,
                                side: BorderSide(
                                  color: AppColors.success,
                                  width: 2,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                elevation: !_selectingStart ? 4 : 2,
                                shadowColor: !_selectingStart
                                    ? AppColors.success.withOpacity(0.3)
                                    : Colors.grey.withOpacity(0.2),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Current selection display
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _selectingStart
                              ? AppColors.primary.withOpacity(0.1)
                              : AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _selectingStart
                                ? AppColors.primary
                                : AppColors.success,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _selectingStart
                                      ? Icons.play_arrow
                                      : Icons.stop,
                                  color: _selectingStart
                                      ? AppColors.primary
                                      : AppColors.success,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _selectingStart
                                      ? 'Selecting Start Time'
                                      : 'Selecting End Time',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: _selectingStart
                                        ? AppColors.primary
                                        : AppColors.success,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _selectingStart
                                  ? 'Current: ${_startDate.hour.toString().padLeft(2, '0')}:00'
                                  : 'Current: ${_endDate.hour.toString().padLeft(2, '0')}:00',
                              style: TextStyle(
                                fontSize: 14,
                                color: _selectingStart
                                    ? AppColors.primary
                                    : AppColors.success,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Information about continuous time
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 16,
                              color: Colors.orange[600],
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Events can span multiple consecutive days, as long as there are no time conflicts',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Time grid
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                              childAspectRatio: 2.5,
                            ),
                        itemCount: 24,
                        itemBuilder: (context, index) {
                          final hour = index;
                          final isBooked = _selectingStart
                              ? _bookedHours.contains(hour)
                              : _bookedHoursEnd.contains(hour);
                          final isSelected = _selectingStart
                              ? _startDate.hour == hour
                              : _endDate.hour == hour;

                          Color bgColor;
                          Color textColor;
                          Color borderColor;

                          if (isBooked) {
                            bgColor = Colors.red[50]!;
                            textColor = Colors.red[600]!;
                            borderColor = Colors.red[200]!;
                          } else if (isSelected) {
                            bgColor = _selectingStart
                                ? AppColors.primary
                                : AppColors.success;
                            textColor = Colors.white;
                            borderColor = _selectingStart
                                ? AppColors.primary
                                : AppColors.success;
                          } else {
                            bgColor = Colors.white;
                            textColor = AppColors.textPrimary;
                            borderColor = Colors.grey[300]!;
                          }

                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                            child: GestureDetector(
                              onTap: isBooked
                                  ? () {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Time $hour:00 is already booked',
                                          ),
                                          backgroundColor: AppColors.error,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  : () async {
                                      if (_selectingStart) {
                                        final newStart = DateTime(
                                          _startDate.year,
                                          _startDate.month,
                                          _startDate.day,
                                          hour,
                                          0,
                                        );

                                        setState(() {
                                          _startDate = newStart;
                                          _ensureContinuousTime();
                                        });
                                        await _loadBookedHoursForStartDate(
                                          _startDate,
                                        );
                                      } else {
                                        final newEnd = DateTime(
                                          _endDate.year,
                                          _endDate.month,
                                          _endDate.day,
                                          hour,
                                          0,
                                        );

                                        if (newEnd.isAfter(_startDate)) {
                                          final ok = await _isRangeAvailable(
                                            _startDate,
                                            newEnd,
                                          );
                                          if (!ok) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'This time slot is already booked',
                                                ),
                                                backgroundColor:
                                                    AppColors.error,
                                              ),
                                            );
                                            return;
                                          }

                                          setState(() {
                                            _endDate = newEnd;
                                            _ensureContinuousTime();
                                          });
                                          await _loadBookedHoursForEndDate(
                                            _endDate,
                                          );
                                        } else {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'End time must be after start time',
                                              ),
                                              backgroundColor: AppColors.error,
                                            ),
                                          );
                                        }
                                      }
                                      sbSetState(() {});
                                    },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: bgColor,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: borderColor,
                                    width: 2,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: borderColor.withOpacity(0.4),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                            spreadRadius: 1,
                                          ),
                                        ]
                                      : [
                                          BoxShadow(
                                            color: Colors.grey.withOpacity(0.1),
                                            blurRadius: 2,
                                            offset: const Offset(0, 1),
                                          ),
                                        ],
                                ),
                                child: Center(
                                  child: Text(
                                    '${hour.toString().padLeft(2, '0')}:00',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 20),

                      // Summary
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(Icons.schedule, color: Colors.blue[600]),
                                const SizedBox(width: 8),
                                const Text(
                                  'Selected Time:',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        const Text(
                                          'Start',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        Text(
                                          '${_startDate.hour.toString().padLeft(2, '0')}:00',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: AppColors.success,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        const Text(
                                          'End',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        Text(
                                          '${_endDate.hour.toString().padLeft(2, '0')}:00',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.success,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Confirm button
                      SizedBox(
                        width: double.infinity,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          child: ElevatedButton.icon(
                            onPressed:
                                (_startDate.hour != 0 && _endDate.hour != 0)
                                ? () => Navigator.of(context).pop()
                                : null,
                            icon: Icon(
                              (_startDate.hour != 0 && _endDate.hour != 0)
                                  ? Icons.check_circle
                                  : Icons.warning,
                            ),
                            label: Text(
                              (_startDate.hour != 0 && _endDate.hour != 0)
                                  ? 'Confirm Time'
                                  : 'Please select complete time',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  (_startDate.hour != 0 && _endDate.hour != 0)
                                  ? AppColors.primary
                                  : Colors.grey[400],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 16,
                              ),
                              elevation:
                                  (_startDate.hour != 0 && _endDate.hour != 0)
                                  ? 6
                                  : 2,
                              shadowColor:
                                  (_startDate.hour != 0 && _endDate.hour != 0)
                                  ? AppColors.primary.withOpacity(0.4)
                                  : Colors.grey.withOpacity(0.2),
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // Removed old separate time slot builders; combined into bottom sheet
}
