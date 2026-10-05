# Third-party notices

## Sudoku Flutter OCR models

The optional on-device photo recognition feature uses two TensorFlow Lite model
files from [`einsitang/sudoku-flutter`](https://github.com/einsitang/sudoku-flutter).
The repository source is published under Apache License 2.0.

The embedded model metadata identifies the models as Ultralytics YOLOv8 models
under AGPL-3.0. They are included here only for this private, personal-use
application. Reassess or replace these models before distributing the app.

The model assets are bundled only for native targets. Web/PWA builds do not
include them and support photo reference entry rather than automatic OCR.

Files:

- `assets/models/sudoku_float16.tflite`
- `assets/models/digits_float16.tflite`
