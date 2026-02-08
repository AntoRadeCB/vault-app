import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/image_cache_service.dart';

/// A widget that displays a card image with IndexedDB caching.
/// First checks local cache, then fetches from network if needed.
class CachedCardImage extends StatefulWidget {
  final String? imageUrl;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final Duration cacheTtl;
  final BorderRadius? borderRadius;

  const CachedCardImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.cacheTtl = const Duration(days: 7),
    this.borderRadius,
  });

  @override
  State<CachedCardImage> createState() => _CachedCardImageState();
}

class _CachedCardImageState extends State<CachedCardImage> {
  final ImageCacheService _cache = ImageCacheService();
  Uint8List? _imageBytes;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(CachedCardImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    final url = widget.imageUrl;
    if (url == null || url.isEmpty) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
      _imageBytes = null;
    });

    try {
      // Try cache first
      final cached = await _cache.get(url);
      if (cached != null) {
        if (mounted) {
          setState(() {
            _imageBytes = cached;
            _isLoading = false;
          });
        }
        return;
      }

      // Fetch from network
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        
        // Store in cache
        await _cache.put(url, bytes, ttl: widget.cacheTtl);
        
        if (mounted) {
          setState(() {
            _imageBytes = bytes;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _hasError = true;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget child;

    if (_isLoading) {
      child = widget.placeholder ?? 
        Container(
          color: Colors.grey.withValues(alpha: 0.2),
          child: const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
    } else if (_hasError || _imageBytes == null) {
      child = widget.errorWidget ?? 
        Container(
          color: Colors.grey.withValues(alpha: 0.2),
          child: const Icon(Icons.broken_image, color: Colors.grey),
        );
    } else {
      child = Image.memory(
        _imageBytes!,
        fit: widget.fit,
        errorBuilder: (_, __, ___) => widget.errorWidget ?? 
          Container(
            color: Colors.grey.withValues(alpha: 0.2),
            child: const Icon(Icons.broken_image, color: Colors.grey),
          ),
      );
    }

    if (widget.borderRadius != null) {
      return ClipRRect(
        borderRadius: widget.borderRadius!,
        child: child,
      );
    }

    return child;
  }
}

/// Preload images into cache (for batch operations)
class ImagePreloader {
  static final ImageCacheService _cache = ImageCacheService();

  /// Preload a list of image URLs into cache
  static Future<int> preload(List<String> urls, {
    Duration? ttl,
    void Function(int loaded, int total)? onProgress,
  }) async {
    int loaded = 0;
    
    for (final url in urls) {
      if (url.isEmpty) continue;
      
      try {
        // Check if already cached
        final cached = await _cache.get(url);
        if (cached == null) {
          // Fetch and cache
          final response = await http.get(Uri.parse(url));
          if (response.statusCode == 200) {
            await _cache.put(url, response.bodyBytes, ttl: ttl);
          }
        }
        loaded++;
        onProgress?.call(loaded, urls.length);
      } catch (e) {
        // Skip failed URLs
      }
    }
    
    return loaded;
  }
}
