# Script khắc phục Admin bị khóa

## Vấn đề
Admin không thể đăng nhập sau khi cập nhật logic approval vì tài khoản admin cũ chưa có trường `approvalStatus` và `isBlocked`.

## Giải pháp nhanh

### Cách 1: Chạy Migration trong App
1. Mở app và đăng nhập bằng tài khoản admin khác (nếu có)
2. Truy cập: `/admin/migration`
3. Nhấn "Chạy Migration"

### Cách 2: Cập nhật trực tiếp trong Firebase Console
1. Mở Firebase Console → Firestore Database
2. Vào collection `users`
3. Tìm tài khoản admin (role = "admin")
4. Cập nhật document với các trường sau:

```json
{
  "approvalStatus": "approved",
  "isBlocked": false,
  "updatedAt": "2024-01-01T00:00:00.000Z"
}
```

### Cách 3: Sử dụng Firebase CLI
```bash
# Cài đặt Firebase CLI nếu chưa có
npm install -g firebase-tools

# Đăng nhập Firebase
firebase login

# Chạy script cập nhật
firebase firestore:query users --where "role==admin" --format json | jq '.[] | .id' | xargs -I {} firebase firestore:update users/{} '{"approvalStatus": "approved", "isBlocked": false, "updatedAt": "2024-01-01T00:00:00.000Z"}'
```

### Cách 4: Sử dụng JavaScript trong Firebase Console
Mở Firebase Console → Firestore Database → Console và chạy:

```javascript
// Lấy tất cả admin
db.collection('users').where('role', '==', 'admin').get().then(snapshot => {
  const batch = db.batch();
  
  snapshot.forEach(doc => {
    const data = doc.data();
    if (!data.approvalStatus || !data.hasOwnProperty('isBlocked')) {
      batch.update(doc.ref, {
        approvalStatus: 'approved',
        isBlocked: false,
        updatedAt: new Date()
      });
    }
  });
  
  return batch.commit();
}).then(() => {
  console.log('Migration completed successfully!');
}).catch(error => {
  console.error('Migration failed:', error);
});
```

## Kiểm tra sau khi chạy
1. Thử đăng nhập lại với tài khoản admin
2. Kiểm tra trong Firestore xem các trường đã được cập nhật chưa
3. Nếu vẫn lỗi, kiểm tra console để xem lỗi cụ thể

## Lưu ý
- Chỉ cần chạy migration một lần duy nhất
- Backup database trước khi chạy migration (khuyến nghị)
- Sau khi migration, admin sẽ có thể đăng nhập bình thường
