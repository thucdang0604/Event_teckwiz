# Hướng dẫn hệ thống duyệt tài khoản

## Tổng quan
Hệ thống đã được cập nhật để yêu cầu admin duyệt tài khoản trước khi người dùng có thể sử dụng ứng dụng.

## Các thay đổi chính

### 1. UserModel
- Thêm trường `approvalStatus` với các giá trị:
  - `pending`: Chờ duyệt (mặc định)
  - `approved`: Đã duyệt
  - `rejected`: Đã từ chối

### 2. Quy trình đăng ký
- Khi người dùng đăng ký tài khoản mới:
  - Tài khoản admin: Tự động được duyệt (`approved`)
  - Tài khoản khác: Đặt trạng thái `pending`
  - Hiển thị dialog thông báo cần chờ duyệt
  - Chuyển về màn hình đăng nhập

### 3. Quy trình đăng nhập
- Khi đăng nhập:
  - Kiểm tra `approvalStatus`
  - Nếu chưa được duyệt: Hiển thị dialog liên hệ admin
  - Nếu đã được duyệt: Cho phép đăng nhập bình thường

### 4. Màn hình admin duyệt tài khoản
- Đường dẫn: `/admin/user-approval`
- Chức năng:
  - Xem danh sách tài khoản chờ duyệt
  - Duyệt tài khoản
  - Từ chối tài khoản
  - Làm mới danh sách

## Cách sử dụng

### Cho người dùng thường
1. Đăng ký tài khoản mới
2. Nhận thông báo cần chờ duyệt
3. Liên hệ admin để được kích hoạt
4. Đăng nhập sau khi được duyệt

### Cho admin
1. Truy cập màn hình duyệt tài khoản
2. Xem thông tin người dùng chờ duyệt
3. Duyệt hoặc từ chối tài khoản
4. Người dùng sẽ nhận thông báo tương ứng

## Cấu trúc file đã thay đổi

### Models
- `lib/models/user_model.dart`: Thêm trường `approvalStatus`

### Services
- `lib/services/auth_service.dart`: 
  - Cập nhật logic đăng ký
  - Cập nhật logic đăng nhập
  - Thêm methods duyệt/từ chối tài khoản

### Screens
- `lib/screens/auth/login_screen.dart`: Thêm dialog thông báo liên hệ admin
- `lib/screens/auth/register_screen.dart`: Thêm dialog thông báo chờ duyệt
- `lib/screens/admin/user_approval_screen.dart`: Màn hình admin duyệt tài khoản

### Constants
- `lib/constants/app_constants.dart`: Thêm constants cho approval status

## Lưu ý quan trọng

1. **Tài khoản admin**: Tự động được duyệt khi đăng ký
2. **Tài khoản cũ**: Cần cập nhật `approvalStatus` trong database
3. **Email admin**: Có thể thay đổi trong dialog thông báo
4. **UI/UX**: Các dialog được thiết kế thân thiện với người dùng

## Cập nhật database

### Vấn đề Admin bị khóa
Nếu admin không thể đăng nhập sau khi cập nhật, có thể do:
1. Tài khoản admin cũ chưa có trường `approvalStatus` hoặc `isBlocked`
2. Logic kiểm tra approval áp dụng cho cả admin

### Giải pháp

#### Cách 1: Sử dụng Migration Screen (Khuyến nghị)
1. Truy cập màn hình Migration: `/admin/migration`
2. Nhấn "Chạy Migration" để cập nhật tài khoản admin cũ
3. Admin sẽ có thể đăng nhập bình thường

#### Cách 2: Cập nhật thủ công trong Firebase Console
```javascript
// Cập nhật tất cả admin thành approved và unblocked
db.users.updateMany(
  { role: "admin" },
  { 
    $set: { 
      approvalStatus: "approved",
      isBlocked: false,
      updatedAt: new Date()
    } 
  }
);

// Cập nhật tất cả tài khoản khác thành pending (nếu chưa có)
db.users.updateMany(
  { 
    role: { $ne: "admin" },
    approvalStatus: { $exists: false }
  },
  { 
    $set: { 
      approvalStatus: "pending",
      isBlocked: false,
      updatedAt: new Date()
    } 
  }
);
```

#### Cách 3: Sử dụng AuthService method
```dart
final authService = AuthService();
await authService.updateLegacyAdminUsers();
```

## Testing

1. Đăng ký tài khoản mới với role khác admin
2. Kiểm tra trạng thái `pending` trong database
3. Thử đăng nhập và xem dialog thông báo
4. Duyệt tài khoản từ admin panel
5. Đăng nhập lại và kiểm tra hoạt động bình thường
