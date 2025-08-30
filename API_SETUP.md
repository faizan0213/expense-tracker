# FastAPI Endpoint Setup

## Configuration

Update the FastAPI server URL in `lib/config/api_config.dart`:

```dart
class ApiConfig {
  // Change this to your FastAPI server URL
  static const String baseUrl = 'http://your-server-url:port';
  
  // Upload endpoint
  static const String uploadEndpoint = '/upload-image';
}
```

## Network Configuration

### For Android Emulator:
```dart
static const String baseUrl = 'http://10.0.2.2:8000';
```

### For iOS Simulator:
```dart
static const String baseUrl = 'http://localhost:8000';
```

### For Physical Device:
```dart
static const String baseUrl = 'http://192.168.1.100:8000'; // Your computer's IP
```

## Expected API Response

The FastAPI endpoint should return JSON with file URL:

```json
{
  "file_url": "http://your-server/uploads/filename.jpg",
  "success": true
}
```

Or:

```json
{
  "url": "http://your-server/uploads/filename.jpg"
}
```

Or:

```json
{
  "image_url": "http://your-server/uploads/filename.jpg"
}
```

## Supported File Types

- Images: JPG, JPEG, PNG, GIF, BMP
- Documents: PDF, CSV, TXT
- Any other file type

## Usage

1. User selects file (camera, gallery, or file picker)
2. File is stored locally until expense is saved
3. When saving expense, file is uploaded to FastAPI endpoint
4. Server returns file URL
5. URL is stored in expense record

That's it! Simple and clean. 🚀