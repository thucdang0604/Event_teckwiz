import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../../models/student_model.dart';
import '../../services/student_service.dart';
import '../../constants/app_colors.dart';

class StudentManagementScreen extends StatefulWidget {
  const StudentManagementScreen({super.key});

  @override
  State<StudentManagementScreen> createState() =>
      _StudentManagementScreenState();
}

class _StudentManagementScreenState extends State<StudentManagementScreen> {
  final StudentService _studentService = StudentService();
  final TextEditingController _searchController = TextEditingController();

  List<StudentModel> _students = [];
  List<StudentModel> _filteredStudents = [];
  bool _isLoading = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final students = await _studentService.getAllStudents();
      setState(() {
        _students = students;
        _filteredStudents = students;
      });
    } catch (e) {
      _showErrorSnackBar('Lỗi tải danh sách sinh viên: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterStudents(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredStudents = _students;
      } else {
        _filteredStudents = _students.where((student) {
          return student.fullName.toLowerCase().contains(query.toLowerCase()) ||
              student.studentId.toLowerCase().contains(query.toLowerCase()) ||
              student.email.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  Future<void> _importSampleData() async {
    try {
      final String jsonString = await rootBundle.loadString(
        'assets/sample_students.json',
      );
      final List<dynamic> jsonData = json.decode(jsonString);

      final List<StudentModel> students = jsonData.map((json) {
        return StudentModel.fromJson(json);
      }).toList();

      await _studentService.addMultipleStudents(students);
      _showSuccessSnackBar('Import thành công ${students.length} sinh viên');
      _loadStudents();
    } catch (e) {
      _showErrorSnackBar('Lỗi import dữ liệu: $e');
    }
  }

  Future<void> _deleteStudent(StudentModel student) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text(
          'Bạn có chắc chắn muốn xóa sinh viên ${student.fullName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _studentService.deleteStudent(student.id);
        _showSuccessSnackBar('Xóa sinh viên thành công');
        _loadStudents();
      } catch (e) {
        _showErrorSnackBar('Lỗi xóa sinh viên: $e');
      }
    }
  }

  Future<void> _toggleStudentStatus(StudentModel student) async {
    try {
      final updatedStudent = student.copyWith(
        isActive: !student.isActive,
        updatedAt: DateTime.now(),
      );
      await _studentService.updateStudent(updatedStudent);
      _showSuccessSnackBar(
        '${student.isActive ? 'Vô hiệu hóa' : 'Kích hoạt'} sinh viên thành công',
      );
      _loadStudents();
    } catch (e) {
      _showErrorSnackBar('Lỗi cập nhật trạng thái: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.success),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý sinh viên'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadStudents),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndActions(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildStudentsList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _importSampleData,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.upload_file, color: Colors.white),
      ),
    );
  }

  Widget _buildSearchAndActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Tìm kiếm theo tên, mã số SV, email...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _filterStudents('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: _filterStudents,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _importSampleData,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Import dữ liệu mẫu'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _loadStudents,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Làm mới'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStudentsList() {
    if (_filteredStudents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty
                  ? 'Chưa có sinh viên nào'
                  : 'Không tìm thấy sinh viên phù hợp',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredStudents.length,
      itemBuilder: (context, index) {
        final student = _filteredStudents[index];
        return _buildStudentCard(student);
      },
    );
  }

  Widget _buildStudentCard(StudentModel student) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: student.isActive
                      ? AppColors.primary
                      : Colors.grey,
                  child: Text(
                    student.fullName.isNotEmpty
                        ? student.fullName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.fullName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        student.studentId,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: student.isActive
                        ? AppColors.success.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    student.isActive ? 'Hoạt động' : 'Tạm khóa',
                    style: TextStyle(
                      fontSize: 12,
                      color: student.isActive
                          ? AppColors.success
                          : Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.email, student.email),
            _buildInfoRow(Icons.phone, student.phoneNumber),
            if (student.department != null)
              _buildInfoRow(Icons.school, student.department!),
            if (student.classCode != null)
              _buildInfoRow(Icons.class_, student.classCode!),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _toggleStudentStatus(student),
                  icon: Icon(
                    student.isActive ? Icons.block : Icons.check_circle,
                    size: 16,
                  ),
                  label: Text(
                    student.isActive ? 'Khóa' : 'Mở khóa',
                    style: TextStyle(
                      color: student.isActive ? Colors.red : AppColors.success,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _deleteStudent(student),
                  icon: const Icon(Icons.delete, size: 16),
                  label: const Text('Xóa', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }
}
