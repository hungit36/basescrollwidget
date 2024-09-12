import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum LoadingStyle {rotate, opacity, rotateAndopacity}

class BaseScrollView extends StatefulWidget {
  const BaseScrollView({
    super.key,
    required this.child,
    this.onRefresh,
    this.onScrollStart,
    this.onLoadMore,
    this.onScrollUpdate,
    required this.isLoading,
    this.indicatorColor = Colors.black54, 
    this.indicatorActiveColor = Colors.black54, 
    this.isEnableRefreshIndicator = true,
    this.imageLoading = '',
    this.loadingString,
    this.loadingStringStyle,
    this.style = LoadingStyle.rotate,
    this.angle = pi * 2,
  });

  final LoadingStyle style;

  final double angle;

  ///enable or disable the refresh indicator when pull to refresh
  final bool isEnableRefreshIndicator;

  ///The image (png) of loading replace default loading
  final String imageLoading;

  final String? loadingString;
  final TextStyle? loadingStringStyle;

  ///color the indicator
  final Color indicatorColor;

  final Color indicatorActiveColor;
  
  final bool isLoading;
  final Widget child;
  final VoidCallback? onScrollStart;
  final VoidCallback? onRefresh;
  final VoidCallback? onLoadMore;
  final void Function(ScrollDirection, double)? onScrollUpdate;

  @override
  State<BaseScrollView> createState() => _BaseScrollViewtate();
}

class _BaseScrollViewtate extends State<BaseScrollView> {
  bool _isUserScroll = false;
  double _oldOffset = 0;
  ScrollDirection _direction = ScrollDirection.idle;
  bool _isScrollToTop = false;

  _onUpdateScroll(ScrollMetrics metrics) {
    _direction = _oldOffset < metrics.pixels ? ScrollDirection.forward : ScrollDirection.reverse;
    widget.onScrollUpdate?.call(_direction, _oldOffset);
    _oldOffset = metrics.pixels;
    if (!widget.isEnableRefreshIndicator && metrics.pixels < -65) {
      _isScrollToTop = true;
    }
  }

  _onEndScroll(ScrollMetrics metrics) {
    if (_isUserScroll == false) return;
    _isUserScroll = false;
    widget.onScrollUpdate?.call(_direction, metrics.pixels);
    if (metrics.atEdge) {
      bool isTop = _direction == ScrollDirection.reverse;
      if (!isTop) {
        widget.onLoadMore?.call();
      } else if (_isScrollToTop && !widget.isEnableRefreshIndicator) {
        _isScrollToTop = false;
        widget.onRefresh?.call();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _MyLoadingView(
      loadingString: widget.loadingString,
      loadingStringStyle: widget.loadingStringStyle,
      imagePath: widget.imageLoading,
      angle: widget.angle,
      indicatorActiveColor: widget.indicatorActiveColor,
      isLoading: widget.isLoading,
      style: widget.style,
      indicatorColor: widget.indicatorColor,
      child: widget.isEnableRefreshIndicator ? RefreshIndicator(
        color: widget.indicatorColor,
        onRefresh: () async {
          widget.onRefresh?.call();
        },
        notificationPredicate: (notification) {
          if (notification is ScrollStartNotification) {
            widget.onScrollStart?.call();
          } else if (notification is ScrollUpdateNotification && notification.dragDetails != null) {
            _isUserScroll = true;
              _onUpdateScroll(notification.metrics);
          } else if (notification is ScrollEndNotification) {
            _onEndScroll(notification.metrics);
          }
          return true;
        },
        displacement: 50,
        child: widget.child,
      ) : NotificationListener(
        onNotification: (scrollNotification) {
          if (scrollNotification is ScrollStartNotification) {
            widget.onScrollStart?.call();
          } else if (scrollNotification is ScrollUpdateNotification && scrollNotification.dragDetails != null) {
            _isUserScroll = true;
            _onUpdateScroll(scrollNotification.metrics);
          } else if (scrollNotification is ScrollEndNotification) {
            _onEndScroll(scrollNotification.metrics);
          }
          return true;
        },
        child: widget.child,
      ),
    );
  }

}

class _MyLoadingView extends StatelessWidget {
  final Color indicatorColor;
  final bool isLoading;
  final String? loadingString;
  final Widget child;
  final String imagePath;
  final TextStyle? loadingStringStyle;
  final LoadingStyle style;
  final Color indicatorActiveColor;
  final double angle;

  const _MyLoadingView({
    super.key,
    this.imagePath = '',
    required this.isLoading,
    required this.child,
    this.indicatorColor = Colors.black54,
     this.loadingString,
    this.loadingStringStyle,
    this.style = LoadingStyle.rotate,
    this.indicatorActiveColor = Colors.black,
    this.angle = pi * 2,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) =>  ConstrainedBox(
        constraints: BoxConstraints(minWidth: constraints.maxWidth, minHeight: constraints.maxHeight),
        child: Stack(
          children: [
            child,
            if (isLoading)
              Positioned.fill(
                child: ColoredBox(
                  color: Colors.white.withOpacity(0.85),
                  child: Center(
                    child: style == LoadingStyle.rotateAndopacity ? _MyLoadingIconRotateAndFadeOpacity(
                      imagePath: imagePath, 
                      indicatorColor: indicatorColor, 
                      loadingString: loadingString ?? '',
                      loadingStringStyle: loadingStringStyle,
                      indicatorActiveColor: indicatorActiveColor, 
                      angle: angle,
                      ) : style == LoadingStyle.rotate ? _MyLoadingIcon(
                      imagePath: imagePath, 
                      indicatorColor: indicatorColor, 
                      loadingString: loadingString ?? '',
                      loadingStringStyle: loadingStringStyle,
                      indicatorActiveColor: indicatorActiveColor, 
                      angle: angle,
                      ) : _MyLoadingIconFadeOpacity(
                        imagePath: imagePath, 
                        indicatorColor: indicatorColor,
                         loadingString: loadingString ?? '',
                         loadingStringStyle: loadingStringStyle, 
                         indicatorActiveColor: indicatorActiveColor,
                         ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MyLoadingIcon extends StatefulWidget {
  const _MyLoadingIcon({
    this.imagePath = '',
    this.indicatorColor = Colors.black54, 
    this.loadingString = '', 
    this.loadingStringStyle, 
    this.indicatorActiveColor = Colors.black, 
    this.angle = pi * 2,
  });
  final String loadingString;
  final TextStyle? loadingStringStyle;
  final String imagePath;
  final Color indicatorColor;
  final Color indicatorActiveColor;
  final double angle;

  @override
  State<_MyLoadingIcon> createState() => _LoadingState();
}

class _LoadingState extends State<_MyLoadingIcon> with TickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    controller = AnimationController(vsync: this, duration: Duration(milliseconds: widget.angle == 2*pi ? 2000 : 1000))
    ..repeat();
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: controller,
            builder: (_, child) {
              return Transform.rotate(
                angle: controller.value * widget.angle,
                child: child,
              );
            },
            child:
              widget.imagePath.isNotEmpty ? (widget.imagePath.split('.').last.toLowerCase()=='svg' ? SvgPicture.asset(
                widget.imagePath,
                width: 24,
                height: 24,
              ) : Image.asset(
                widget.imagePath,
                width: 24,
                height: 24,
              )) : SizedBox(
                width: 24, 
                height: 24,
                  child: CircularProgressIndicator(
                    color: widget.indicatorColor,
                  ),
                
              ),
          ),
          if (widget.loadingString.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(widget.loadingString, style: widget.loadingStringStyle,),
          ],
        ],
      );
  }
}


class _MyLoadingIconRotateAndFadeOpacity extends StatefulWidget {
  const _MyLoadingIconRotateAndFadeOpacity({
    this.imagePath = '',
    this.indicatorColor = Colors.black54, 
    this.loadingString = '', 
    this.loadingStringStyle, 
    this.indicatorActiveColor = Colors.black,
    this.angle = pi * 2,
  });
  final String loadingString;
  final TextStyle? loadingStringStyle;
  final String imagePath;
  final Color indicatorColor;
  final Color indicatorActiveColor;
  final double angle;

  @override
  State<_MyLoadingIconRotateAndFadeOpacity> createState() => _WidgetRotateAndFadeOpacityState();
}

class _WidgetRotateAndFadeOpacityState extends State<_MyLoadingIconRotateAndFadeOpacity> with TickerProviderStateMixin {

  late AnimationController _animationController;
  late Animation _colorTween;
  
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    final time = widget.angle == 2*pi ? 2 : 1;

    _controller = AnimationController(vsync: this, duration: Duration(seconds: time))
    ..repeat(reverse: true);

    _animationController = AnimationController(
        vsync: this, duration: Duration(seconds: time))..repeat(reverse: true);
    _colorTween = ColorTween(begin: widget.indicatorColor, end: widget.indicatorActiveColor)
        .animate(_animationController);
  }

  @override
  void dispose() {
    _controller.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _colorTween,
            builder: (_, child) {
                    return Transform.rotate(
                      angle: _controller.value * widget.angle,
                      child: widget.imagePath.isNotEmpty ? (widget.imagePath.split('.').last.toLowerCase()=='svg' ? SvgPicture.asset(
                            widget.imagePath,
                            width: 24,
                            height: 24,
                            colorFilter: ColorFilter.mode(_colorTween.value, BlendMode.srcIn),
                          ) : Image.asset(
                            widget.imagePath,
                            width: 24,
                            height: 24,
                            color: _colorTween.value)) : SizedBox(
                        width: 24, 
                        height: 24,
                        child: CircularProgressIndicator(
                          color: _colorTween.value,
                        ),
                      ),
                    );
                  },
          ),
          if (widget.loadingString.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(widget.loadingString, style: widget.loadingStringStyle,),
          ],
        ],
      );
  }
}

class _MyLoadingIconFadeOpacity extends StatefulWidget {
  const _MyLoadingIconFadeOpacity({
    this.imagePath = '',
    this.indicatorColor = Colors.black54, 
    this.loadingString = '', 
    this.loadingStringStyle, 
    this.indicatorActiveColor = Colors.black,
  });
  final String loadingString;
  final TextStyle? loadingStringStyle;
  final String imagePath;
  final Color indicatorColor;
  final Color indicatorActiveColor;

  @override
  State<_MyLoadingIconFadeOpacity> createState() => _WidgetState();
}

class _WidgetState extends State<_MyLoadingIconFadeOpacity> with TickerProviderStateMixin {

  late AnimationController _animationController;
  late Animation _colorTween;

  @override
  void initState() {
    _animationController = AnimationController(
        vsync: this, duration: const Duration(seconds: 2));
    _colorTween = ColorTween(begin: widget.indicatorColor, end: widget.indicatorActiveColor)
        .animate(_animationController);
    changeColors();
    super.initState();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future changeColors() async {
    while (true) {
      await Future.delayed(const Duration(seconds: 2), () {
        if (_animationController.status == AnimationStatus.completed) {
          _animationController.reverse();
        } else {
          _animationController.forward();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _colorTween,
      builder: (context, child) =>
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          widget.imagePath.isNotEmpty ? (widget.imagePath.split('.').last.toLowerCase()=='svg' ? SvgPicture.asset(
                widget.imagePath,
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(_colorTween.value, BlendMode.srcIn),
              ) : Image.asset(
                widget.imagePath,
                width: 24,
                height: 24,
                color: _colorTween.value)) : SizedBox(
            width: 24, 
            height: 24,
            child: CircularProgressIndicator(
              color: _colorTween.value,
            ),
          ),
          if (widget.loadingString.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(widget.loadingString, style: widget.loadingStringStyle,),
          ],
        ],
      ),
    );
  }
}
