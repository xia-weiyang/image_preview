# image_preview

Multi-image preview in your gallery.

![describe](./describe.gif)

## Setup

Add to pubspec.yaml

```
dependencies:
  image_preview: ^0.0.1
```
Import it

```dart
import 'package:image_preview/image_preview.dart';
```

## Usage

```dart
openImagesPage(
                context,
                imgUrls: _imageUrls,  // Images list
                index: i,  // First opened image
                );
```

Look at the sample app for more.

### Thanks
- [https://github.com/renefloor/flutter_cached_network_image](https://github.com/renefloor/flutter_cached_network_image)
- [https://github.com/renancaraujo/photo_view](https://github.com/renancaraujo/photo_view)

