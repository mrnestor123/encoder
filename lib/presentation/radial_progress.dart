import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as math;

class RadialProgress extends StatefulWidget {
  double goalCompleted = 0.7;
  String text;
  double value = 0.0;

  RadialProgress(
      {Key key,
      @required this.goalCompleted,
      @required this.text,
      this.value = 0.0})
      : super(key: key);

  @override
  _RadialProgressState createState() => _RadialProgressState();
}

class _RadialProgressState extends State<RadialProgress>
    with SingleTickerProviderStateMixin {
  AnimationController _radialProgressAnimationController;
  Animation<double> _progressAnimation;
  final Duration fadeInDuration = Duration(milliseconds: 500);
  final Duration fillDuration = Duration(seconds: 2);

  double progressDegrees = 0;
  var count = 0;

  @override
  void initState() {
    super.initState();
    _radialProgressAnimationController =
        AnimationController(vsync: this, duration: fillDuration);
    _progressAnimation = Tween(begin: 0.0, end: 360.0).animate(CurvedAnimation(
        parent: _radialProgressAnimationController, curve: Curves.easeIn))
      ..addListener(() {
        setState(() {
          progressDegrees = widget.goalCompleted * _progressAnimation.value;
        });
      });

    _radialProgressAnimationController.forward();
  }

  @override
  void dispose() {
    _radialProgressAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      child: Container(
        height: MediaQuery.of(context).size.width * 0.7,
        width: MediaQuery.of(context).size.width * 0.7,
        child: AnimatedOpacity(
          opacity: progressDegrees > 30 ? 1.0 : 0.0,
          duration: fadeInDuration,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                /*Text(
                  widget.text,
                  style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width * 0.05,
                      color: Colors.white,
                      letterSpacing: 1.5),
                ),
                SizedBox(
                  height: 4.0,
                ),
                Container(
                  height: 5.0,
                  width: 80.0,
                  decoration: BoxDecoration(
                      color: Colors.amber[800],
                      borderRadius: BorderRadius.all(Radius.circular(4.0))),
                ),*/
                Text(
                  '40 KG',
                  style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width * 0.05,
                      color: Colors.white,
                      letterSpacing: 1.5),
                ),
                Text(
                  '0.07',
                  style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width * 0.24,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold),
                ),
                Text( 
                 widget.text + ''' \nm/s
                 ''',
                 textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 14.0, color: Colors.blue, letterSpacing: 1.5),
                ),
              ],
            ),
          ),
        ),
      ),
      painter: RadialPainter(progressDegrees),
    );
  }
}

class RadialPainter extends CustomPainter {
  double progressInDegrees;

  RadialPainter(this.progressInDegrees);

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.black12
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0;

    Offset center = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(center, size.width / 2, paint);

    Paint progressPaint = Paint()
      ..shader = LinearGradient(
              colors: [Colors.grey[200], Colors.grey[500], Colors.grey])
          .createShader(Rect.fromCircle(center: center, radius: size.width / 2))
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0;

    canvas.drawArc(
        Rect.fromCircle(center: center, radius: size.width / 2),
        math.radians(-90),
        math.radians(progressInDegrees),
        false,
        progressPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
