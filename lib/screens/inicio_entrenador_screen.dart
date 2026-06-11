import 'package:flutter/material.dart';

class InicioEntrenadorScreen extends StatelessWidget {
  const InicioEntrenadorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD9D9D9), // Manteniendo tu estilo gris
      appBar: AppBar(
        title: const Text("Panel del Entrenador"),
        backgroundColor: Colors.red,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text(
              "Bienvenido, Entrenador",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            
            // Opciones del Entrenador
            _buildBotonOpcion(Icons.group, "Gestionar Jugadores"),
            _buildBotonOpcion(Icons.calendar_today, "Programar Entrenamientos"),
            _buildBotonOpcion(Icons.bar_chart, "Estadísticas del Equipo"),
          ],
        ),
      ),
    );
  }

  Widget _buildBotonOpcion(IconData icono, String texto) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 15),
      child: ListTile(
        leading: Icon(icono, color: Colors.red),
        title: Text(texto, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          // Aquí programarás la acción de cada botón
        },
      ),
    );
  }
}