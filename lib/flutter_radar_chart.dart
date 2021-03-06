library flutter_radar_chart;

import 'dart:ui';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'dart:math' show pi, cos, sin;

const defaultGraphColors = [
  Colors.green,
  Colors.blue,
  Colors.red,
  Colors.orange,
];

class RadarChart extends StatefulWidget {
  final List<double> ticks;
  final List<String> features;
  final List<List<double>> data;
  final bool reverseAxis;
  final TextStyle ticksTextStyle;
  final TextStyle featuresTextStyle;
  final Color outlineColor;
  final Color axisColor;
  final List<Color> graphColors;
	final bool animate;

  const RadarChart({
    Key key,
    @required this.ticks,
    @required this.features,
    @required this.data,
    this.reverseAxis = false,
    this.ticksTextStyle = const TextStyle(color: Colors.grey, fontSize: 12),
    this.featuresTextStyle = const TextStyle(color: Colors.black, fontSize: 16),
    this.outlineColor = Colors.black,
    this.axisColor = Colors.grey,
    this.graphColors = defaultGraphColors,
		this.animate = true,
  }) : super(key: key);

  factory RadarChart.light({
    @required List<double> ticks,
    @required List<String> features,
    @required List<List<double>> data,
    bool reverseAxis = false,
    List<Color> graphColors = defaultGraphColors,
		animate = true,
  }) {
    return RadarChart(
      ticks: ticks,
      features: features,
      data: data,
      reverseAxis: reverseAxis,
			graphColors: graphColors,
			animate: animate,
    );
  }

  factory RadarChart.dark({
    @required List<double> ticks,
    @required List<String> features,
    @required List<List<double>> data,
    bool reverseAxis = false,
    List<Color> graphColors = defaultGraphColors,
		bool animate = true,
  }) {
    return RadarChart(
      ticks: ticks,
      features: features,
      data: data,
      featuresTextStyle: const TextStyle(color: Colors.white, fontSize: 16),
      outlineColor: Colors.white,
      axisColor: Colors.grey,
      reverseAxis: reverseAxis,
			graphColors: graphColors,
			animate: animate,
    );
  }

  @override
  _RadarChartState createState() => _RadarChartState();
}

class _RadarChartState extends State<RadarChart>
    with SingleTickerProviderStateMixin {
  double fraction = 0.0;
  Animation<double> animation;
  AnimationController animationController;

  @override
  void initState() {
    super.initState();

		if (widget.animate) {
			animationController = AnimationController(
					duration: Duration(milliseconds: 1000), vsync: this);

			animation = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
				curve: Curves.fastOutSlowIn,
				parent: animationController,
			))
				..addListener(() {
					setState(() {
						fraction = animation.value;
					});
				});

			animationController.forward();
		}
		else
			fraction = 1.0;
  }

	@override
	void dispose() {
		if (widget.animate)
			animationController.dispose();
		super.dispose();
	}

  @override
  void didUpdateWidget(RadarChart oldWidget) {
    super.didUpdateWidget(oldWidget);

		if (widget.animate) {
			animationController.reset();
			animationController.forward();
		}
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(double.infinity, double.infinity),
      painter: RadarChartPainter(
				widget.ticks,
				widget.features,
				widget.data,
				widget.reverseAxis,
				widget.ticksTextStyle,
				widget.featuresTextStyle,
				widget.outlineColor,
				widget.axisColor,
				widget.graphColors,
				this.fraction
			),
    );
  }
}

class RadarChartPainter extends CustomPainter {
  final List<double> ticks;
  final List<String> features;
  final List<List<double>> data;
  final bool reverseAxis;
  final TextStyle ticksTextStyle;
  final TextStyle featuresTextStyle;
  final Color outlineColor;
  final Color axisColor;
  final List<Color> graphColors;
  final double fraction;

  RadarChartPainter(
      this.ticks,
      this.features,
      this.data,
      this.reverseAxis,
      this.ticksTextStyle,
      this.featuresTextStyle,
      this.outlineColor,
      this.axisColor,
      this.graphColors,
      this.fraction);

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2.0;
    final centerY = size.height / 2.0;
    final centerOffset = Offset(centerX, centerY);
    final radius = math.min(centerX, centerY) * 0.8;

    // Painting the chart outline
    var outlinePaint = Paint()
      ..color = outlineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..isAntiAlias = true;

    var ticksPaint = Paint()
      ..color = axisColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..isAntiAlias = true;

    canvas.drawCircle(centerOffset, radius, outlinePaint);

    // Painting the circles and labels for the given ticks (could be auto-generated)
    // The first and last ticks are ignored given first tick is the center and
	  // last tick overlaps with the feature label
    var tickDistance = radius / (ticks.length - 1);
    var tickLabels = reverseAxis ? ticks.reversed.toList() : ticks;

    tickLabels.sublist(1, ticks.length - 1).asMap().forEach((index, tick) {
      var tickRadius = tickDistance * (index + 1);

      canvas.drawCircle(centerOffset, tickRadius, ticksPaint);

      TextPainter(
        text: TextSpan(text: tick.toString(), style: ticksTextStyle),
        textDirection: TextDirection.ltr,
      )
        ..layout(minWidth: 0, maxWidth: size.width)
        ..paint(canvas,
            Offset(centerX, centerY - tickRadius - ticksTextStyle.fontSize));
    });

    // Painting the axis for each given feature
    var angle = (2 * pi) / features.length;

    features.asMap().forEach((index, feature) {
      var xAngle = cos(angle * index - pi / 2);
      var yAngle = sin(angle * index - pi / 2);

      var featureOffset =
          Offset(centerX + radius * xAngle, centerY + radius * yAngle);

      canvas.drawLine(centerOffset, featureOffset, ticksPaint);

      var featureLabelFontHeight = featuresTextStyle.fontSize;
      var featureLabelFontWidth = featuresTextStyle.fontSize - 4;
      var labelYOffset = yAngle < 0 ? -featureLabelFontHeight : 0;
      var labelXOffset =
          xAngle < 0 ? -featureLabelFontWidth * feature.length : 0;

      TextPainter(
        text: TextSpan(text: feature, style: featuresTextStyle),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )
        ..layout(minWidth: 0, maxWidth: size.width)
        ..paint(
            canvas,
            Offset(featureOffset.dx + labelXOffset,
                featureOffset.dy + labelYOffset));
    });

    // Painting each graph
    data.asMap().forEach((index, graph) {

			if (graph.length < 1)
			 	return;

      var graphPaint = Paint()
        ..color = graphColors[index % graphColors.length].withOpacity(0.3)
        ..style = PaintingStyle.fill;

      var graphOutlinePaint = Paint()
        ..color = graphColors[index % graphColors.length]
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..isAntiAlias = true;

      var path = Path();
			bool moved = false;

      graph.asMap().forEach((index, value) {
				if (value == null)
					return;

				value = _validPointValue(value);
        var xAngle = cos(angle * index - pi / 2);
        var yAngle = sin(angle * index - pi / 2);
        var pixel = _distanceAlongRadius(value, radius) * fraction;
				var x;
				var y;

        if (reverseAxis) {
					x = centerX + (radius * fraction - pixel) * xAngle;
					y = centerY + (radius * fraction - pixel) * yAngle;
        } else {
					x = centerX + pixel * xAngle;
					y = centerY + pixel * yAngle;
        }

				if (moved != true) {
					moved = true;
					path.moveTo(x, y);
				}
				else
					path.lineTo(x, y);
			});

      path.close();
      canvas.drawPath(path, graphPaint);
      canvas.drawPath(path, graphOutlinePaint);
    });
  }

  @override
  bool shouldRepaint(RadarChartPainter oldDelegate) {
    return oldDelegate.fraction != fraction;
  }

	double _validPointValue(value) {
		// constrain value to between first tick and last tick
		// thus, no spiking nor going in wrong direction
		return math.min(math.max(value, ticks.first), ticks.last);
	}

	double _distanceAlongRadius(value, radius) {
		return ((value - ticks.first) / (ticks.last - ticks.first)) * radius;
	}
}
