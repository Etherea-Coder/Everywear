import 'dart:io' show File;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../core/app_export.dart';

extension ImageTypeExtension on String {
  ImageType get imageType {
    if (startsWith('http://') || startsWith('https://')) {
      return ImageType.network;
    } else if (endsWith('.svg')) {
      return ImageType.svg;
    } else if (startsWith('file://')) {
      return ImageType.file;
    } else {
      return ImageType.png;
    }
  }
}

enum ImageType { svg, png, network, file, unknown }

class CustomImageWidget extends StatelessWidget {
  final String? imageUrl;
  final double? height;
  final double? width;
  final Color? color;
  final BoxFit? fit;
  final String placeHolder;
  final Alignment? alignment;
  final VoidCallback? onTap;
  final BorderRadius? radius;
  final EdgeInsetsGeometry? margin;
  final BoxBorder? border;
  final Widget? errorWidget;
  final String? semanticLabel;

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
  });

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

  _buildCircleImage() {
    if (radius != null) {
      return ClipRRect(
        borderRadius: radius ?? BorderRadius.zero,
        child: _buildImageWithBorder(),
      );
    } else {
      return _buildImageWithBorder();
    }
  }

  _buildImageWithBorder() {
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
    if (imageUrl != null) {
      switch (imageUrl!.imageType) {
        case ImageType.svg:
          return Container(
            height: height,
            width: width,
            child: SvgPicture.asset(
              imageUrl!,
              height: height,
              width: width,
              fit: fit ?? BoxFit.contain,
              colorFilter: color != null
                  ? ColorFilter.mode(color!, BlendMode.srcIn)
                  : null,
              semanticsLabel: semanticLabel,
            ),
          );
        case ImageType.file:
          if (kIsWeb) {
            return Image.asset(
              placeHolder,
              height: height,
              width: width,
              fit: fit ?? BoxFit.cover,
              semanticLabel: semanticLabel,
            );
          }
          final filePath = Uri.tryParse(imageUrl!)?.toFilePath() ?? imageUrl!;
          return Image.file(
            File(filePath),
            height: height,
            width: width,
            fit: fit ?? BoxFit.cover,
            color: color,
            semanticLabel: semanticLabel,
            errorBuilder: (_, __, ___) => Image.asset(
              placeHolder,
              height: height,
              width: width,
              fit: fit ?? BoxFit.cover,
              semanticLabel: semanticLabel,
            ),
          );
        case ImageType.network:
          return CachedNetworkImage(
            height: height,
            width: width,
            fit: fit,
            imageUrl: imageUrl!,
            color: color,
            placeholder: (context, url) => Container(
              height: height ?? 30,
              width: width ?? 30,
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
        case ImageType.png:
        case ImageType.unknown:
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
    return Image.asset(
      placeHolder,
      height: height,
      width: width,
      fit: fit ?? BoxFit.cover,
      semanticLabel: semanticLabel,
    );
  }
}
