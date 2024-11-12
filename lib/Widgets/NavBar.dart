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

  NavButton _itemBuilder(BuildContext context, int i) {
    return widget.arButtons[i]; // Devuelve el NavButton desde la lista arButtons
  }

  @override
  Widget build(BuildContext context) {

    return Container(
      child: ListView.builder(itemBuilder: _itemBuilder , itemCount: widget.arButtons.length,)
    );
  }
}