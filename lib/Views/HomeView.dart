import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class HomeView extends StatefulWidget {
  @override
  State<HomeView> createState() {
    return _HomeView();
  }
}

class _HomeView extends State<HomeView> {
  int clickContador = 0;
  bool visible = true;

  void clickBtnContador() {
    setState(() {
      clickContador++;
      visible = !visible;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[900],
      appBar: AppBar(
        title: Text(
          "Premios CELO",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blueGrey[800],
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                "Hola Mundo",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Soy Pedro",
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                visible ? "Que te den" : "ADIOS",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  color: Colors.lightGreenAccent,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "CONTADOR DE CLICKS",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 30,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "$clickContador",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 30,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text("btn1"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.lightBlueAccent, // Cambia aquí
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    icon: const FaIcon(FontAwesomeIcons.anchor),
                    color: Colors.lightBlueAccent,
                    onPressed: () {
                      clickBtnContador();
                      print("VALOR DEL CONTADOR: $clickContador");
                    },
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text("btn2"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.lightBlueAccent, // Cambia aquí
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: Colors.lightBlueAccent,
        child: const FaIcon(FontAwesomeIcons.apple),
      ),
    );
  }
}























/*
// Antiguo o para gente con muchos principios
Widget pintadoComoJava(){
  Text saludo=Text("HOLA MUNDO");
  Text saludo2=Text("SOY SANTI");
  Text saludo3=Text("WELCOME TO HELL HDP");
  TextButton Btn1=TextButton(onPressed: (){}, child: Text("btn1"));
  TextButton Btn2=TextButton(onPressed: (){}, child: Text("btn2"));

  // Primero declara la fila porque es como JAVA, y es medio Tonto

  Row fila = Row(children: [Btn1, Btn2],mainAxisAlignment: MainAxisAlignment.center);

  Column columna=Column(children: [saludo,saludo2,saludo3,fila]);

  return columna;
}
*/