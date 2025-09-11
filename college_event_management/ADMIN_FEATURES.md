# Chức năng Admin - Hệ thống Quản lý Sự kiện

## Tổng quan
Hệ thống admin được thiết kế để quản lý toàn bộ hoạt động của ứng dụng quản lý sự kiện, bao gồm duyệt sự kiện, quản lý người dùng, quản lý vị trí và thống kê.

## Các chức năng chính

### 1. Dashboard Admin
- **Truy cập**: Chỉ admin mới có thể truy cập
- **Chức năng**:
  - Xem thống kê tổng quan (số người dùng, sự kiện, đăng ký)
  - Truy cập nhanh đến các chức năng quản lý
  - Xem hoạt động gần đây

### 2. Quản lý Người dùng
- **Chức năng**:
  - Xem danh sách tất cả người dùng
  - Tìm kiếm người dùng theo tên, email, MSSV
  - Lọc người dùng theo vai trò (admin, organizer, student)
  - Kích hoạt/vô hiệu hóa tài khoản
  - Thay đổi vai trò người dùng (student ↔ organizer)

### 3. Duyệt Sự kiện
- **Chức năng**:
  - Xem danh sách sự kiện chờ duyệt
  - Duyệt sự kiện (chuyển trạng thái từ "pending" → "published")
  - Từ chối sự kiện (chuyển trạng thái từ "pending" → "rejected")
  - Xem chi tiết sự kiện trước khi duyệt
  - Nhập lý do từ chối khi cần thiết

### 4. Quản lý Vị trí
- **Chức năng**:
  - Thêm vị trí mới có thể tổ chức sự kiện
  - Chỉnh sửa thông tin vị trí
  - Kích hoạt/tạm dừng vị trí
  - Xóa vị trí
  - Quản lý tiện ích của từng vị trí
  - Thiết lập sức chứa tối đa

### 5. Lịch Sự kiện theo Vị trí
- **Chức năng**:
  - Chọn vị trí để xem lịch sự kiện
  - Hiển thị tất cả sự kiện tại vị trí đã chọn
  - Xem trạng thái sự kiện (đã duyệt, chờ duyệt, từ chối, hủy, hoàn thành)
  - Xem thông tin chi tiết sự kiện

### 6. Thống kê Sự kiện
- **Chức năng**:
  - Xem thống kê đăng ký và tham dự
  - Lọc theo vị trí và thời gian
  - Hiển thị tỷ lệ tham dự thực tế
  - So sánh số lượng đăng ký dự kiến vs thực tế
  - Cập nhật số lượng tham dự thực tế

## Cách sử dụng

### Truy cập Admin Dashboard
1. Đăng nhập với tài khoản admin
2. Trên màn hình chính, nhấn vào icon admin (⚙️) ở góc phải
3. Chọn chức năng cần sử dụng từ dashboard

### Duyệt Sự kiện
1. Vào "Duyệt sự kiện" từ dashboard
2. Xem danh sách sự kiện chờ duyệt
3. Nhấn "Duyệt" để chấp nhận hoặc "Từ chối" để từ chối
4. Nếu từ chối, nhập lý do từ chối

### Quản lý Vị trí
1. Vào "Quản lý vị trí" từ dashboard
2. Nhấn "+" để thêm vị trí mới
3. Điền đầy đủ thông tin vị trí
4. Thêm các tiện ích có sẵn
5. Lưu thông tin

### Xem Thống kê
1. Vào "Thống kê sự kiện" từ dashboard
2. Chọn vị trí và khoảng thời gian
3. Xem các chỉ số thống kê
4. Cập nhật số lượng tham dự thực tế nếu cần

## Lưu ý quan trọng

- Chỉ tài khoản có vai trò "admin" mới có thể truy cập các chức năng admin
- Sự kiện mới tạo sẽ có trạng thái "pending" và cần được admin duyệt
- Khi từ chối sự kiện, cần nhập lý do rõ ràng
- Thống kê sẽ được cập nhật tự động khi có dữ liệu mới
- Vị trí bị tạm dừng sẽ không thể được chọn khi tạo sự kiện mới

## Cấu trúc Dữ liệu

### Trạng thái Sự kiện
- `pending`: Chờ duyệt
- `published`: Đã duyệt và công khai
- `rejected`: Bị từ chối
- `cancelled`: Bị hủy
- `completed`: Đã hoàn thành

### Vai trò Người dùng
- `admin`: Quản trị viên (có quyền truy cập tất cả chức năng)
- `organizer`: Người tổ chức (có thể tạo sự kiện)
- `student`: Sinh viên (chỉ có thể đăng ký tham gia sự kiện)
