# Hướng dẫn sử dụng giao diện Admin mới

## Tổng quan
Hệ thống admin đã được cập nhật với giao diện mới, thay thế các nút action riêng lẻ bằng dropdown để chọn trạng thái.

## Các màn hình mới

### 1. User Management Screen (`/admin/user-management`)
**Màn hình quản lý tài khoản tổng quan**

#### Tính năng:
- **Tìm kiếm**: Tìm theo tên, email, MSSV
- **Lọc theo trạng thái**: 
  - Tất cả
  - Chờ duyệt
  - Đã duyệt
  - Đã từ chối
  - Bị khóa
  - Không hoạt động
- **Danh sách tài khoản**: Hiển thị thông tin cơ bản và trạng thái
- **Xem chi tiết**: Tap vào tài khoản để xem chi tiết

#### Giao diện:
- Card layout với avatar, tên, email, vai trò
- Status chips hiển thị trạng thái hiện tại
- Mũi tên chỉ hướng để vào chi tiết

### 2. User Detail Screen (`/admin/user-detail`)
**Màn hình chi tiết tài khoản với dropdown thay đổi trạng thái**

#### Các phần chính:

##### A. Thông tin cơ bản
- Avatar, tên, email, vai trò
- Số điện thoại, MSSV (nếu có)
- Ngày tạo tài khoản

##### B. Trạng thái hiện tại
- **Trạng thái duyệt**: Chờ duyệt/Đã duyệt/Đã từ chối
- **Trạng thái hoạt động**: Hoạt động/Không hoạt động
- **Trạng thái khóa**: Bị khóa/Không bị khóa
- **Trạng thái đăng nhập**: Có thể/Không thể đăng nhập

##### C. Thay đổi trạng thái
- **3 Dropdown** để chọn trạng thái mới:
  1. **Trạng thái duyệt**: Chờ duyệt → Đã duyệt → Đã từ chối
  2. **Trạng thái hoạt động**: Hoạt động ↔ Không hoạt động
  3. **Trạng thái khóa**: Không bị khóa ↔ Bị khóa

#### Cách sử dụng:
1. Chọn trạng thái mới từ dropdown
2. Nhấn "Cập nhật trạng thái"
3. Hệ thống sẽ cập nhật và thông báo kết quả
4. Tự động quay lại danh sách và refresh

### 3. User Approval Screen (Cập nhật)
**Màn hình duyệt tài khoản chờ duyệt**

#### Thay đổi:
- Thay nút "Từ chối" bằng nút "Chi tiết"
- Giữ nút "Duyệt" để duyệt nhanh
- Nút "Chi tiết" chuyển đến User Detail Screen

## So sánh giao diện cũ vs mới

### ❌ Giao diện cũ:
```
[Toggle Active Status] [Toggle Block Status] 
[Approve User] [Reject User] [Change Role]
```

### ✅ Giao diện mới:
```
Trạng thái hiện tại:
- Approval Status: Pending
- Active Status: Active  
- Block Status: Not Blocked
- Login Status: Cannot Login

Thay đổi trạng thái:
[Dropdown: Chờ duyệt ▼] 
[Dropdown: Hoạt động ▼]
[Dropdown: Không bị khóa ▼]

[Cập nhật trạng thái]
```

## Lợi ích của giao diện mới

### 1. **Trực quan hơn**
- Hiển thị rõ ràng trạng thái hiện tại
- Màu sắc phân biệt trạng thái
- Icon minh họa dễ hiểu

### 2. **Dễ sử dụng hơn**
- Một màn hình thay vì nhiều nút
- Dropdown thay vì toggle buttons
- Thông tin đầy đủ trong một view

### 3. **An toàn hơn**
- Xem trước thay đổi trước khi cập nhật
- Xác nhận rõ ràng trạng thái mới
- Giảm nhầm lẫn khi thao tác

### 4. **Linh hoạt hơn**
- Thay đổi nhiều trạng thái cùng lúc
- Tìm kiếm và lọc dễ dàng
- Quản lý tất cả tài khoản trong một nơi

## Cách truy cập

### Từ Admin Dashboard:
1. **Quản lý tài khoản** → User Management Screen
2. **Duyệt tài khoản** → User Approval Screen (chỉ tài khoản chờ duyệt)

### Từ User Management:
- Tap vào bất kỳ tài khoản nào → User Detail Screen

## Lưu ý quan trọng

1. **Trạng thái đăng nhập** được tính tự động dựa trên:
   - `isActive = true`
   - `isBlocked = false` 
   - `approvalStatus = "approved"`

2. **Admin luôn có thể đăng nhập** bất kể trạng thái approval

3. **Thay đổi trạng thái** sẽ cập nhật ngay lập tức trong database

4. **Refresh tự động** sau khi cập nhật thành công

## Troubleshooting

### Nếu không thấy thay đổi:
1. Kiểm tra kết nối internet
2. Refresh trang
3. Kiểm tra console để xem lỗi

### Nếu admin bị khóa:
1. Sử dụng Migration Screen
2. Hoặc cập nhật trực tiếp trong Firebase Console
3. Xem `ADMIN_FIX_SCRIPT.md` để biết chi tiết
