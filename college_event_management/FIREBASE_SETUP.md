# Hướng Dẫn Cài Đặt Firebase

## Bước 1: Tạo Project Firebase

1. Truy cập [Firebase Console](https://console.firebase.google.com/)
2. Nhấn "Create a project" hoặc "Tạo dự án"
3. Nhập tên project: `college-event-management`
4. Bật Google Analytics (tùy chọn)
5. Chọn region: `asia-southeast1` (Singapore)
6. Nhấn "Create project"

## Bước 2: Cấu Hình Authentication

1. Trong Firebase Console, chọn project vừa tạo
2. Vào **Authentication** > **Sign-in method**
3. Bật **Email/Password**
4. Bật **Anonymous** (cho demo)

## Bước 3: Cấu Hình Firestore Database

1. Vào **Firestore Database**
2. Nhấn "Create database"
3. Chọn "Start in test mode" (cho development)
4. Chọn location: `asia-southeast1`
5. Nhấn "Done"

## Bước 4: Cấu Hình Android App

1. Vào **Project settings** (biểu tượng bánh răng)
2. Chọn tab **General**
3. Trong phần "Your apps", nhấn **Add app** > **Android**
4. Nhập package name: `com.college.eventmanagement`
5. Nhập app nickname: `College Event Management`
6. Nhấn "Register app"
7. Tải file `google-services.json`
8. Đặt file vào thư mục `android/app/`

## Bước 5: Cấu Hình iOS App (Nếu cần)

1. Trong **Project settings**, nhấn **Add app** > **iOS**
2. Nhập bundle ID: `com.college.eventmanagement`
3. Nhập app nickname: `College Event Management`
4. Nhấn "Register app"
5. Tải file `GoogleService-Info.plist`
6. Đặt file vào thư mục `ios/Runner/`

## Bước 6: Cập Nhật Firebase Options

1. Cài đặt Firebase CLI:
   ```bash
   npm install -g firebase-tools
   ```

2. Đăng nhập Firebase:
   ```bash
   firebase login
   ```

3. Cài đặt FlutterFire CLI:
   ```bash
   dart pub global activate flutterfire_cli
   ```

4. Cấu hình FlutterFire:
   ```bash
   flutterfire configure
   ```

5. Chọn project Firebase và platforms (Android, iOS, Web)

## Bước 7: Cấu Hình Firestore Rules

Vào **Firestore Database** > **Rules** và cập nhật:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Events collection
    match /events/{eventId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
        (resource.data.organizerId == request.auth.uid || 
         get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin');
    }
    
    // Registrations collection
    match /registrations/{registrationId} {
      allow read, write: if request.auth != null && 
        (resource.data.userId == request.auth.uid || 
         get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['admin', 'organizer']);
    }

    // Support registrations collection
    match /support_registrations/{supportRegistrationId} {
      allow read: if request.auth != null && (
        // Organizer or co-organizer of the event can read
        get(/databases/$(database)/documents/events/$(request.resource.data.eventId)).data.organizerId == request.auth.uid ||
        request.auth.token != null &&
        request.auth.uid in get(/databases/$(database)/documents/events/$(request.resource.data.eventId)).data.coOrganizers ||
        // Admin can read
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin'
      );
      
      allow write: if request.auth != null && (
        // Only organizer/co-organizer/admin can approve/reject
        get(/databases/$(database)/documents/events/$(request.resource.data.eventId)).data.organizerId == request.auth.uid ||
        request.auth.uid in get(/databases/$(database)/documents/events/$(request.resource.data.eventId)).data.coOrganizers ||
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin'
      );
    }
  }
}
```

## Bước 8: Cấu Hình Storage (Tùy chọn)

1. Vào **Storage**
2. Nhấn "Get started"
3. Chọn "Start in test mode"
4. Chọn location: `asia-southeast1`

## Bước 9: Kiểm Tra Cấu Hình

1. Chạy ứng dụng:
   ```bash
   flutter run
   ```

2. Kiểm tra console để đảm bảo không có lỗi Firebase

## Lưu Ý Quan Trọng

- **Không commit** file `google-services.json` và `GoogleService-Info.plist` vào Git
- Thêm các file này vào `.gitignore`
- Sử dụng Firebase Emulator Suite cho development
- Cấu hình Firebase Security Rules phù hợp cho production

## Troubleshooting

### Lỗi "No Firebase App '[DEFAULT]' has been created"
- Đảm bảo đã gọi `Firebase.initializeApp()` trong `main()`
- Kiểm tra file `firebase_options.dart` đã được tạo đúng

### Lỗi "Missing google-services.json"
- Đảm bảo file `google-services.json` đã được đặt trong `android/app/`
- Kiểm tra package name trong file JSON khớp với `android/app/build.gradle`

### Lỗi Authentication
- Kiểm tra Authentication đã được bật trong Firebase Console
- Đảm bảo Sign-in methods đã được cấu hình đúng
