import 'package:flutter/material.dart';
import 'package:faulkner_footsteps/theme/app_theme.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_rating/flutter_rating.dart';

/// A collection of reusable widgets that follow the app's design guidelines.
/// This helps maintain consistency across the application.

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double? width;
  final double? height;
  final VoidCallback? onTap;

  const AppCard({
    Key? key,
    required this.child,
    this.padding = const EdgeInsets.all(16.0),
    this.width,
    this.height,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: AppTheme.cardDecoration,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12.0),
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}

class AppHeading extends StatelessWidget {
  final String text;
  final TextAlign textAlign;
  final bool onPrimary;

  const AppHeading({
    Key? key,
    required this.text,
    this.textAlign = TextAlign.left,
    this.onPrimary = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      style: onPrimary ? AppTheme.ultraHeadingOnPrimary : AppTheme.ultraHeading,
    );
  }
}

class AppSubheading extends StatelessWidget {
  final String text;
  final TextAlign textAlign;
  final bool onPrimary;

  const AppSubheading({
    Key? key,
    required this.text,
    this.textAlign = TextAlign.left,
    this.onPrimary = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      style: onPrimary
          ? AppTheme.ultraHeadingOnPrimary.copyWith(fontSize: 18.0)
          : AppTheme.ultraHeadingSmall,
    );
  }
}

class AppText extends StatelessWidget {
  final String text;
  final TextAlign textAlign;
  final bool onPrimary;
  final int? maxLines;
  final TextOverflow overflow;

  const AppText({
    Key? key,
    required this.text,
    this.textAlign = TextAlign.left,
    this.onPrimary = false,
    this.maxLines,
    this.overflow = TextOverflow.clip,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      style: onPrimary ? AppTheme.rakkasBodyOnPrimary : AppTheme.rakkasBody,
    );
  }
}

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isSecondary;
  final IconData? icon;
  final bool fullWidth;

  const AppButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.isSecondary = false,
    this.icon,
    this.fullWidth = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final buttonWidget = icon != null
        ? ElevatedButton.icon(
            onPressed: onPressed,
            icon: Icon(icon),
            label: Text(text,
                style: isSecondary
                    ? AppTheme.rakkasBody
                    : AppTheme.rakkasBodyOnPrimary),
            style: isSecondary
                ? AppTheme.secondaryButtonStyle
                : AppTheme.primaryButtonStyle,
          )
        : ElevatedButton(
            onPressed: onPressed,
            style: isSecondary
                ? AppTheme.secondaryButtonStyle
                : AppTheme.primaryButtonStyle,
            child: Text(text,
                style: isSecondary
                    ? AppTheme.rakkasBody
                    : AppTheme.rakkasBodyOnPrimary),
          );

    return fullWidth
        ? SizedBox(width: double.infinity, child: buttonWidget)
        : buttonWidget;
  }
}

class AppRatingBar extends StatelessWidget {
  final double rating;
  final ValueChanged<double>? onRatingChanged;
  final bool showRatingText;
  final double size;

  const AppRatingBar({
    Key? key,
    required this.rating,
    this.onRatingChanged,
    this.showRatingText = true,
    this.size = 40.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        StarRating(
          rating: rating,
          starCount: 5,
          onRatingChanged: onRatingChanged,
          color: Colors.amber,
          borderColor: Colors.amber,
          size: size,
        ),
        if (showRatingText) ...[
          const SizedBox(width: 8),
          AppText(
            text: "(${rating.toStringAsFixed(1)})",
          ),
        ],
      ],
    );
  }
}

class AppImageViewer extends StatelessWidget {
  final List<dynamic> images; // Can be Uint8List or String (URL)
  final double height;
  final VoidCallback? onTap;
  final bool isHorizontalList;
  final BoxFit fit;

  const AppImageViewer({
    Key? key,
    required this.images,
    this.height = 200,
    this.onTap,
    this.isHorizontalList = true,
    this.fit = BoxFit.cover,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return Container(
        height: height,
        decoration: BoxDecoration(
          color: AppTheme.secondaryBackground,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Center(
          child: Icon(
            Icons.image_not_supported,
            size: 50,
            color: AppTheme.textSecondary.withOpacity(0.5),
          ),
        ),
      );
    }

    if (isHorizontalList) {
      return Container(
        height: height,
        decoration: BoxDecoration(
          color: AppTheme.secondaryBackground,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: images.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: GestureDetector(
                onTap: onTap,
                child: _buildImage(images[index], fit),
              ),
            );
          },
        ),
      );
    } else {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          height: height,
          width: double.infinity,
          child: _buildImage(images.first, fit),
        ),
      );
    }
  }

  Widget _buildImage(dynamic image, BoxFit fit) {
    if (image == null) {
      return Image.asset(
        'assets/images/faulkner_thumbnail.png',
        fit: fit,
      );
    } else if (image is String) {
      // URL string
      return Image.network(
        image,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(child: CircularProgressIndicator());
        },
        errorBuilder: (context, error, stackTrace) {
          return Image.asset(
            'assets/images/faulkner_thumbnail.png',
            fit: fit,
          );
        },
      );
    } else {
      // Uint8List (memory image)
      return Image.memory(
        image,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return Image.asset(
            'assets/images/faulkner_thumbnail.png',
            fit: fit,
          );
        },
      );
    }
  }
}

class AppSiteCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? distance;
  final dynamic image;
  final VoidCallback onTap;
  final double? rating;

  const AppSiteCard({
    Key? key,
    required this.title,
    this.subtitle,
    this.distance,
    this.image,
    required this.onTap,
    this.rating,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
      child: Container(
        decoration: AppTheme.cardDecoration,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Column(
            children: [
              // Thumbnail image
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(10),
                ),
                child: _buildImage(image),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: AppTheme.ultraHeadingSmall,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_circle_right_outlined,
                            color: AppTheme.textPrimary,
                          ),
                          onPressed: onTap,
                        ),
                      ],
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: AppTheme.rakkasBodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (distance != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          "$distance miles away",
                          style: AppTheme.ultraHeadingSmall.copyWith(
                            fontSize: 12,
                          ),
                        ),
                      ),
                    if (rating != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: AppRatingBar(
                          rating: rating!,
                          showRatingText: true,
                          size: 20,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage(dynamic image) {
    if (image == null) {
      return Image.asset(
        'assets/images/faulkner_thumbnail.png',
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    } else if (image is String) {
      return Image.network(
        image,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            height: 200,
            width: double.infinity,
            color: AppTheme.primaryColor,
            child: Center(
              child: CircularProgressIndicator(
                color: AppTheme.textOnPrimary,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Image.asset(
            'assets/images/faulkner_thumbnail.png',
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
          );
        },
      );
    } else {
      return Image.memory(
        image,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Image.asset(
            'assets/images/faulkner_thumbnail.png',
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
          );
        },
      );
    }
  }
}

class AppFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final ValueChanged<bool> onSelected;

  const AppFilterChip({
    Key? key,
    required this.label,
    required this.isSelected,
    required this.onSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
      child: FilterChip(
        backgroundColor: AppTheme.secondaryBackground,
        selectedColor: AppTheme.primaryColor,
        checkmarkColor: AppTheme.textOnPrimary,
        label: Text(
          label,
          style: isSelected
              ? AppTheme.ultraHeadingSmall.copyWith(
                  color: AppTheme.textOnPrimary,
                  fontSize: 14,
                )
              : AppTheme.ultraHeadingSmall.copyWith(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
        ),
        selected: isSelected,
        onSelected: onSelected,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}

class AppDistanceText extends StatelessWidget {
  final LatLng point1;
  final LatLng point2;
  final bool asMiles;

  const AppDistanceText({
    Key? key,
    required this.point1,
    required this.point2,
    this.asMiles = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final distance = Distance();
    final meters = distance.as(
      LengthUnit.Meter,
      point1,
      point2,
    );

    final String displayDistance;
    if (asMiles) {
      final miles = meters / 1609.344;
      displayDistance = "${miles.toStringAsFixed(2)} miles";
    } else {
      if (meters >= 1000) {
        final km = meters / 1000;
        displayDistance = "${km.toStringAsFixed(2)} km";
      } else {
        displayDistance = "${meters.toStringAsFixed(0)} meters";
      }
    }

    return Row(
      children: [
        Icon(
          Icons.location_on,
          color: AppTheme.primaryColor,
          size: 16,
        ),
        const SizedBox(width: 4),
        Text(
          displayDistance,
          style: AppTheme.ultraHeadingSmall.copyWith(
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
