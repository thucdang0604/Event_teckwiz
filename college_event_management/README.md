# Ứng Dụng Quản Lý Sự Kiện Trường Đại Học

Ứng dụng mobile Flutter để quản lý sự kiện trong trường đại học, sử dụng Firebase làm backend.

## Tính Năng Chính

### Cho Sinh Viên
- Xem danh sách sự kiện
- Tìm kiếm và lọc sự kiện theo danh mục
- Đăng ký tham gia sự kiện
- Xem chi tiết sự kiện
- Quản lý hồ sơ cá nhân

### Cho Người Tổ Chức
- Tạo sự kiện mới
- Quản lý sự kiện đã tạo
- Xem danh sách người đăng ký
- Duyệt/từ chối đăng ký
- Cập nhật thông tin sự kiện

### Cho Quản Trị Viên
- Quản lý tất cả sự kiện
- Quản lý người dùng
- Xem báo cáo thống kê

## Công Nghệ Sử Dụng

- **Frontend**: Flutter (Dart)
- **Backend**: Firebase
  - Authentication
  - Firestore Database
  - Storage
- **State Management**: Provider
- **Navigation**: GoRouter
- **UI**: Material Design 3

## Cài Đặt

### Yêu Cầu
- Flutter SDK (phiên bản 3.8.1 trở lên)
- Dart SDK
- Android Studio / VS Code
- Firebase project

### Các Bước Cài Đặt

1. **Clone repository**
   ```bash
   git clone <repository-url>
   cd college_event_management
   ```

2. **Cài đặt dependencies**
   ```bash
   flutter pub get
   ```

3. **Cấu hình Firebase**
   - Tạo project trên [Firebase Console](https://console.firebase.google.com/)
   - Bật Authentication (Email/Password)
   - Tạo Firestore Database
   - Tải file `google-services.json` (Android) và `GoogleService-Info.plist` (iOS)
   - Đặt vào thư mục `android/app/` và `ios/Runner/` tương ứng
   - Cập nhật file `firebase_options.dart` với thông tin project của bạn

4. **Chạy ứng dụng**
   ```bash
   flutter run
   ```

## Cấu Trúc Dự Án

```
lib/
├── constants/          # Các hằng số và cấu hình
├── models/            # Các model dữ liệu
├── providers/         # State management
├── screens/           # Các màn hình UI
│   ├── auth/         # Màn hình đăng nhập/đăng ký
│   ├── events/       # Màn hình sự kiện
│   ├── home/         # Màn hình chính
│   └── profile/      # Màn hình hồ sơ
├── services/          # Các service kết nối Firebase
├── widgets/           # Các widget tùy chỉnh
└── main.dart         # Entry point
```

## Cấu Trúc Database (Firestore)

### Collections

#### users
```json
{
  "id": "string",
  "email": "string",
  "fullName": "string",
  "phoneNumber": "string?",
  "studentId": "string?",
  "department": "string?",
  "role": "string", // admin, organizer, student
  "profileImageUrl": "string?",
  "createdAt": "timestamp",
  "updatedAt": "timestamp",
  "isActive": "boolean"
}
```

#### events
```json
{
  "id": "string",
  "title": "string",
  "description": "string",
  "category": "string",
  "location": "string",
  "startDate": "timestamp",
  "endDate": "timestamp",
  "registrationDeadline": "timestamp",
  "maxParticipants": "number",
  "currentParticipants": "number",
  "status": "string", // draft, published, cancelled, completed
  "organizerId": "string",
  "organizerName": "string",
  "imageUrls": "array",
  "requirements": "string?",
  "contactInfo": "string?",
  "isFree": "boolean",
  "price": "number?",
  "tags": "array",
  "createdAt": "timestamp",
  "updatedAt": "timestamp",
  "isActive": "boolean"
}
```

#### registrations
```json
{
  "id": "string",
  "eventId": "string",
  "userId": "string",
  "userEmail": "string",
  "userName": "string",
  "status": "string", // pending, approved, rejected, cancelled
  "registeredAt": "timestamp",
  "approvedAt": "timestamp?",
  "approvedBy": "string?",
  "rejectionReason": "string?",
  "additionalInfo": "object?",
  "qrCode": "string?",
  "attended": "boolean",
  "attendedAt": "timestamp?",
  "notes": "string?"
}
```

## Tính Năng Đang Phát Triển

- [ ] Đăng ký tham gia sự kiện
- [ ] QR Code check-in
- [ ] Thông báo push
- [ ] Upload hình ảnh sự kiện
- [ ] Báo cáo thống kê
- [ ] Chat trong sự kiện
- [ ] Đánh giá sự kiện

## Đóng Góp

1. Fork repository
2. Tạo feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Tạo Pull Request

## License

Distributed under the MIT License. See `LICENSE` for more information.

## Liên Hệ

- Email: your-email@example.com
- Project Link: [https://github.com/your-username/college-event-management](https://github.com/your-username/college-event-management)