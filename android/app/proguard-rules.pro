# ONNX Runtime keeps native entry points that may look unused to shrinkers.
# Keeping them here is harmless for debug and helps if release shrinking is enabled later.
-keep class ai.onnxruntime.** { *; }
-dontwarn ai.onnxruntime.**
