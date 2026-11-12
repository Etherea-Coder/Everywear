import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../core/app_export.dart';
import '../services/storage_service.dart';

extension ImageTypeExtension on String {
  ImageType get imageType {
    switch (StorageService.classifyImageReference(this)) {
      case ImageReferenceRoute.storage:
        return ImageType.storage;
      case ImageReferenceRoute.network:
        return ImageType.network;
      case ImageReferenceRoute.localFile:
        return ImageType.file;
      case ImageReferenceRoute.asset:
        return endsWith('.svg') ? ImageType.svg : ImageType.png;
    }
  }
}

enum ImageType { svg, png, network, file, storage, unknown }

// ignore_for_file: must_be_immutable
class CustomImageWidget extends StatelessWidget {
  const CustomImageWidget({
    super.key,
    this.imageUrl,
    this.height,
    this.width,
    this.color,
    this.fit,
    this.alignment,
    this.onTap,
    this.radius,
    this.margin,
    this.border,
    this.placeHolder = 'assets/images/no-image.jpg',
    this.errorWidget,
    this.semanticLabel,
    this.storageUrlResolver,
  });

  ///[imageUrl] is required parameter for showing image
  final String? imageUrl;

  final double? height;

  final double? width;

  final BoxFit? fit;

  final String placeHolder;

  final Color? color;

  final Alignment? alignment;

  final VoidCallback? onTap;

  final BorderRadius? radius;

  final EdgeInsetsGeometry? margin;

  final BoxBorder? border;

  /// Optional widget to show when the image fails to load.
  /// If null, a default asset image is shown.
  final Widget? errorWidget;

  /// Semantic label for the image to improve accessibility
  final String? semanticLabel;

  /// Injectable for deterministic display tests; production uses StorageService.
  final Future<String?> Function(String reference)? storageUrlResolver;

  @override
  Widget build(BuildContext context) {
    return alignment != null
        ? Align(alignment: alignment!, child: _buildWidget())
        : _buildWidget();
  }

  Widget _buildWidget() {
    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: InkWell(onTap: onTap, child: _buildCircleImage()),
    );
  }

  ///build the image with border radius
  Widget _buildCircleImage() {
    if (radius != null) {
      return ClipRRect(
        borderRadius: radius ?? BorderRadius.zero,
        child: _buildImageWithBorder(),
      );
    } else {
      return _buildImageWithBorder();
    }
  }

  ///build the image with border and border radius style
  Widget _buildImageWithBorder() {
    if (border != null) {
      return Container(
        decoration: BoxDecoration(border: border, borderRadius: radius),
        child: _buildImageView(),
      );
    } else {
      return _buildImageView();
    }
  }

  Widget _buildImageView() {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      switch (imageUrl!.imageType) {
        case ImageType.svg:
          return SizedBox(
            height: height,
            width: width,
            child: SvgPicture.asset(
              imageUrl!,
              height: height,
              width: width,
              fit: fit ?? BoxFit.contain,
              colorFilter: color != null
                  ? ColorFilter.mode(
                      color ?? Colors.transparent,
                      BlendMode.srcIn,
                    )
                  : null,
              semanticsLabel: semanticLabel,
            ),
          );
        case ImageType.file:
          return Image.file(
            File(Uri.parse(imageUrl!).toFilePath()),
            height: height,
            width: width,
            fit: fit ?? BoxFit.cover,
            color: color,
            semanticLabel: semanticLabel,
          );
        case ImageType.network:
          final image = imageUrl!;
          return _networkImage(image);
        case ImageType.storage:
          return _StorageImageView(
            key: ValueKey('${StorageService.currentUserId}:$imageUrl'),
            reference: imageUrl!,
            height: height,
            width: width,
            fit: fit,
            color: color,
            placeholder: placeHolder,
            errorWidget: errorWidget,
            semanticLabel: semanticLabel,
            resolver: storageUrlResolver ?? StorageService().resolveImageUrl,
          );
        case ImageType.png:
        default:
          return Image.asset(
            imageUrl!,
            height: height,
            width: width,
            fit: fit ?? BoxFit.cover,
            color: color,
            semanticLabel: semanticLabel,
          );
      }
    }
    return const SizedBox.shrink();
  }

  Widget _networkImage(String url) => CachedNetworkImage(
    height: height,
    width: width,
    fit: fit,
    imageUrl: url,
    color: color,
    placeholder: (context, url) => SizedBox(
      height: 30,
      width: 30,
      child: LinearProgressIndicator(
        color: Colors.grey.shade200,
        backgroundColor: Colors.grey.shade100,
      ),
    ),
    errorWidget: (context, url, error) =>
        errorWidget ??
        Image.asset(
          placeHolder,
          height: height,
          width: width,
          fit: fit ?? BoxFit.cover,
          semanticLabel: semanticLabel,
        ),
  );
}

class _StorageImageView extends StatefulWidget {
  const _StorageImageView({
    super.key,
    required this.reference,
    required this.resolver,
    required this.placeholder,
    this.height,
    this.width,
    this.fit,
    this.color,
    this.errorWidget,
    this.semanticLabel,
  });

  final String reference;
  final Future<String?> Function(String reference) resolver;
  final String placeholder;
  final double? height;
  final double? width;
  final BoxFit? fit;
  final Color? color;
  final Widget? errorWidget;
  final String? semanticLabel;

  @override
  State<_StorageImageView> createState() => _StorageImageViewState();
}

class _StorageImageViewState extends State<_StorageImageView> {
  String? _resolvedUrl;
  bool _loading = true;
  bool _refreshScheduled = false;
  bool _refreshed = false;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    String? url;
    try {
      url = await widget.resolver(widget.reference);
    } catch (_) {
      url = null;
    }
    if (!mounted) return;
    setState(() {
      _resolvedUrl = url;
      _loading = false;
      _refreshScheduled = false;
    });
  }

  void _refreshExpiredUrl() {
    if (_refreshScheduled || _refreshed || !mounted) return;
    _refreshScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _refreshed = true;
      setState(() {
        _loading = true;
        _resolvedUrl = null;
      });
      _resolve();
    });
  }

  Widget _fallback() =>
      widget.errorWidget ??
      Image.asset(
        widget.placeholder,
        height: widget.height,
        width: widget.width,
        fit: widget.fit ?? BoxFit.cover,
        semanticLabel: widget.semanticLabel,
      );

  @override
  Widget build(BuildContext context) {
    final url = _resolvedUrl;
    if (_loading) {
      return SizedBox(
        height: widget.height,
        width: widget.width,
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    if (url == null) return _fallback();
    return CachedNetworkImage(
      imageUrl: url,
      cacheKey: StorageService.imageCacheKey(widget.reference),
      height: widget.height,
      width: widget.width,
      fit: widget.fit,
      color: widget.color,
      placeholder: (context, url) => SizedBox(
        height: widget.height ?? 30,
        width: widget.width ?? 30,
        child: const Center(child: CircularProgressIndicator()),
      ),
      errorWidget: (context, url, error) {
        _refreshExpiredUrl();
        return _fallback();
      },
    );
  }
}
