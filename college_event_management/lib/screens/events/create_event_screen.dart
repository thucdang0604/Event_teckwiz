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
        final sameDay =
            e.startDate.year == date.year &&
                e.startDate.month == date.month &&
                e.startDate.day == date.day ||
            e.endDate.year == date.year &&
                e.endDate.month == date.month &&
                e.endDate.day == date.day;
        return sameLocation && sameDay;
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
      // keep end-grid in sync with start day
      _bookedHoursEnd
        ..clear()
        ..addAll(_bookedHours);
      setState(() {});
    } catch (_) {
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
        final sameDay =
            e.startDate.year == date.year &&
                e.startDate.month == date.month &&
                e.startDate.day == date.day ||
            e.endDate.year == date.year &&
                e.endDate.month == date.month &&
                e.endDate.day == date.day;
        return sameLocation && sameDay;
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
    } catch (_) {
      setState(() {});
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Event created successfully! Your event is pending approval.',
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
                                        '${DateFormat(AppConstants.dateTimeFormat).format(_startDate)} - ${DateFormat(AppConstants.dateTimeFormat).format(_endDate)}',
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
                            label: 'Ticket Price (VND)',
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
          initialChildSize: 0.9,
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
                      Row(
                        children: const [
                          Text(
                            'Select Event Time',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Start Date (inline, no popup)
                      Container(
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
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Start Date',
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
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.chevron_left),
                              onPressed: () {
                                setState(() {
                                  final d = _startDate.subtract(
                                    const Duration(days: 1),
                                  );
                                  _startDate = DateTime(
                                    d.year,
                                    d.month,
                                    d.day,
                                    _startDate.hour,
                                    0,
                                  );
                                  if (!_endDate.isAfter(_startDate)) {
                                    _endDate = _startDate.add(
                                      const Duration(hours: 1),
                                    );
                                  }
                                });
                                _loadBookedHoursForStartDate(_startDate);
                                sbSetState(() {});
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.chevron_right),
                              onPressed: () {
                                setState(() {
                                  final d = _startDate.add(
                                    const Duration(days: 1),
                                  );
                                  _startDate = DateTime(
                                    d.year,
                                    d.month,
                                    d.day,
                                    _startDate.hour,
                                    0,
                                  );
                                  if (!_endDate.isAfter(_startDate)) {
                                    _endDate = _startDate.add(
                                      const Duration(hours: 1),
                                    );
                                  }
                                });
                                _loadBookedHoursForStartDate(_startDate);
                                sbSetState(() {});
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Display selected times
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Thời gian đã chọn:',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Giờ bắt đầu:',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${_startDate.hour.toString().padLeft(2, '0')}:00',
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
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: AppColors.success,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Giờ kết thúc:',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${_endDate.hour.toString().padLeft(2, '0')}:00',
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
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Switch which bound to edit
                      Row(
                        children: [
                          ChoiceChip(
                            label: const Text('Chọn giờ bắt đầu'),
                            selected: _selectingStart,
                            onSelected: (v) =>
                                setState(() => _selectingStart = true),
                            selectedColor: AppColors.primary.withOpacity(0.2),
                            labelStyle: TextStyle(
                              color: _selectingStart
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                              fontWeight: _selectingStart
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('Chọn giờ kết thúc'),
                            selected: !_selectingStart,
                            onSelected: (v) =>
                                setState(() => _selectingStart = false),
                            selectedColor: AppColors.success.withOpacity(0.2),
                            labelStyle: TextStyle(
                              color: !_selectingStart
                                  ? AppColors.success
                                  : AppColors.textSecondary,
                              fontWeight: !_selectingStart
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // One grid to pick start or end depending on toggle
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                              childAspectRatio: 2.6,
                            ),
                        itemCount: 24,
                        itemBuilder: (context, index) {
                          final hour = index;
                          final isBooked = _bookedHours.contains(hour);
                          final isSelectedStart = _startDate.hour == hour;
                          final isSelectedEnd =
                              _endDate.hour == hour &&
                              _endDate.day == _startDate.day;
                          final bg = isBooked
                              ? const Color(0xFFFFE5E5)
                              : const Color(0xFFE8F8F0);
                          final border = (isSelectedStart || isSelectedEnd)
                              ? const Color(0xFF10b981)
                              : Colors.transparent;
                          return GestureDetector(
                            onTap: isBooked
                                ? null
                                : () {
                                    setState(() {
                                      if (_selectingStart) {
                                        final newStart = DateTime(
                                          _startDate.year,
                                          _startDate.month,
                                          _startDate.day,
                                          hour,
                                          0,
                                        );
                                        _startDate = newStart;
                                        if (!_endDate.isAfter(_startDate)) {
                                          _endDate = _startDate.add(
                                            const Duration(hours: 1),
                                          );
                                        }
                                        // after picking start, auto switch to End selection
                                        _selectingStart = false;
                                        // Check registration deadline when start time changes
                                        if (_registrationDeadline.isAfter(
                                              _startDate,
                                            ) ||
                                            _registrationDeadline
                                                .isAtSameMomentAs(_startDate)) {
                                          _registrationDeadlineError =
                                              'Registration deadline must be before event start time';
                                        } else {
                                          _registrationDeadlineError = null;
                                        }
                                        // Update UI to show selected times
                                        sbSetState(() {});
                                      } else {
                                        final newEnd = DateTime(
                                          _startDate.year,
                                          _startDate.month,
                                          _startDate.day,
                                          hour,
                                          0,
                                        );
                                        if (!newEnd.isAfter(_startDate)) {
                                          _endDate = _startDate.add(
                                            const Duration(hours: 1),
                                          );
                                        } else {
                                          _endDate = newEnd;
                                        }
                                      }
                                    });
                                    sbSetState(() {});
                                  },
                            child: Container(
                              decoration: BoxDecoration(
                                color: bg,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: border, width: 2),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${hour.toString().padLeft(2, '0')}:00',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isBooked
                                      ? const Color(0xFFDC2626)
                                      : const Color(0xFF10b981),
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.white,
                              ),
                              child: const Text('Confirm'),
                            ),
                          ),
                        ],
                      ),
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
