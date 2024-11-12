import 'package:flutter/cupertino.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:triboo/Widgets/NavButton.dart';

class NavBar extends StatefulWidget{

  final List<NavButton> arButtons;

  const NavBar({
    required this.arButtons,
    super.key,
  });


  @override
  State<NavBar> createState() => _NavBarState();
}

class _NavBarState extends State<NavBar> {
  @override
  Widget build(BuildContext context) {

    return Container(
      child: Row(children: [
        widget.arButtons[0],
        widget.arButtons[1],
        widget.arButtons[2],
        widget.arButtons[3],
        widget.arButtons[4],
      ],),
    );
  }
}