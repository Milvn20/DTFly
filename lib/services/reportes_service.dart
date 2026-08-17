import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter_application_1/models/asistencia_registro.dart';
import 'package:flutter_application_1/models/entrenamiento.dart';
import 'package:flutter_application_1/services/entrenamiento_service.dart';
import 'package:flutter_application_1/services/reportes_file_writer.dart';

/// Reportes exportables del entrenador (colección `reportes_entrenador`).
class ReportesService {
  ReportesService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _col = 'reportes_entrenador';

  static Future<void> generarResumen({
    required String entrenadorEmail,
    required String entrenadorId,
    required String titulo,
    required String contenido,
  }) async {
    await _db.collection(_col).add({
      'entrenadorEmail': entrenadorEmail,
      'entrenadorUsuarioId': entrenadorId,
      'titulo': titulo,
      'contenido': contenido,
      'creadoEn': FieldValue.serverTimestamp(),
    });
  }

  static Future<ReporteArchivo> generarExcelAsistencia({
    required String entrenadorEmail,
    required String entrenadorId,
    String? deporte,
  }) async {
    final entrenamientos =
        await EntrenamientoService.obtenerEntrenamientosParaReporte(entrenadorEmail);
    if (entrenamientos.isEmpty) {
      throw StateError('No hay entrenamientos activos o finalizados para exportar.');
    }

    final filas = <ReporteAsistenciaFila>[];
    for (final entrenamiento in entrenamientos) {
      await EntrenamientoService.registrarAusentesFaltantes(entrenamiento.id);
      final asistencias =
          await EntrenamientoService.obtenerAsistencias(entrenamiento.id);
      for (final asistencia in asistencias) {
        filas.add(
          ReporteAsistenciaFila(
            entrenamiento: entrenamiento,
            asistencia: asistencia,
          ),
        );
      }
    }

    if (filas.isEmpty) {
      throw StateError('No hay registros de asistencia para exportar.');
    }

    final contenido = _excelAsistencia(filas);
    final nombreArchivo =
        'reporte_asistencia_${_slugFecha(DateTime.now())}.xls';
    final ruta = await guardarArchivoReporte(nombreArchivo, contenido);

    await _db.collection(_col).add({
      'entrenadorEmail': entrenadorEmail,
      'entrenadorUsuarioId': entrenadorId,
      if (deporte != null && deporte.isNotEmpty) 'deporte': deporte,
      'titulo': 'Reporte asistencia completo',
      'contenido': contenido,
      'nombreArchivo': nombreArchivo,
      'rutaArchivo': ruta,
      'formato': 'xls_excel_xml',
      'totalEntrenamientos': entrenamientos.length,
      'creadoEn': FieldValue.serverTimestamp(),
    });

    return ReporteArchivo(
      nombreArchivo: nombreArchivo,
      rutaArchivo: ruta,
      entrenamientoTitulo: 'Reporte completo',
      total: filas.length,
      totalEntrenamientos: entrenamientos.length,
      presentes: filas.where((f) => _esPuntual(f.asistencia.estado)).length,
      atrasados: filas.where((f) => f.asistencia.estado == 'atrasado').length,
      ausentes: filas.where((f) => f.asistencia.estado == 'ausente').length,
    );
  }

  static String _excelAsistencia(List<ReporteAsistenciaFila> filas) {
    final grupos = <String, List<ReporteAsistenciaFila>>{};
    for (final fila in filas) {
      grupos.putIfAbsent(fila.entrenamiento.id, () => []).add(fila);
    }
    final bloques = grupos.values.toList()
      ..sort(
        (a, b) => a.first.entrenamiento.inicioProgramado.compareTo(
          b.first.entrenamiento.inicioProgramado,
        ),
      );

    final puntuales = filas.where((f) => _esPuntual(f.asistencia.estado)).length;
    final atrasados = filas.where((f) => f.asistencia.estado == 'atrasado').length;
    final ausentes = filas.where((f) => f.asistencia.estado == 'ausente').length;
    final b = StringBuffer()
      ..writeln('<?xml version="1.0" encoding="UTF-8"?>')
      ..writeln('<?mso-application progid="Excel.Sheet"?>')
      ..writeln(
        '<Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet" '
        'xmlns:o="urn:schemas-microsoft-com:office:office" '
        'xmlns:x="urn:schemas-microsoft-com:office:excel" '
        'xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet">',
      )
      ..writeln(_excelStyles())
      ..writeln('<Worksheet ss:Name="Registro asistencia">')
      ..writeln('<Table>')
      ..writeln('<Column ss:Width="42"/>')
      ..writeln('<Column ss:Width="180"/>')
      ..writeln('<Column ss:Width="90"/>')
      ..writeln('<Column ss:Width="72"/>')
      ..writeln('<Column ss:Width="210"/>');

    for (final bloque in bloques) {
      final e = bloque.first.entrenamiento;
      final ordenadas = [...bloque]..sort((a, b) {
          final cmpEstado = _estadoPrioridad(a.asistencia.estado)
              .compareTo(_estadoPrioridad(b.asistencia.estado));
          if (cmpEstado != 0) return cmpEstado;
          return _apellidoKey(a.asistencia.nombre).compareTo(
            _apellidoKey(b.asistencia.nombre),
          );
        });

      b
        ..writeln(_row([
          _cell(
            'ENTRENAMIENTO ${e.titulo.toUpperCase()}',
            style: 'Title',
            mergeAcross: 4,
          ),
        ]))
        ..writeln(_row([
          _cell('Fecha: ${_fmtFecha(e.inicioProgramado)}', mergeAcross: 4),
        ]))
        ..writeln(_row([
          _cell(
            'Horario: ${_fmtHora(e.inicioProgramado)} - ${_fmtHora(e.finProgramado)}',
            mergeAcross: 4,
          ),
        ]))
        ..writeln(_row([
          _cell('Lugar: ${e.cancha}', mergeAcross: 4),
        ]))
        ..writeln(_row([
          _cell('N°', style: 'HeaderCenter'),
          _cell('Jugador', style: 'HeaderLeft'),
          _cell('Estado', style: 'HeaderCenter'),
          _cell('Hora ingreso', style: 'HeaderCenter'),
          _cell('Observación', style: 'HeaderLeft'),
        ]));

      for (var i = 0; i < ordenadas.length; i++) {
        final a = ordenadas[i].asistencia;
        b.writeln(_row([
          _cell('${i + 1}', style: 'CellCenter', type: 'Number'),
          _cell(a.nombre.isEmpty ? 'Sin nombre' : a.nombre),
          _cell(
            _etiquetaEstado(a.estado),
            style: _estadoStyle(a.estado),
          ),
          _cell(
            a.unidoEn == null ? '-' : _fmtHora(a.unidoEn!),
            style: 'CellCenter',
          ),
          _cell(_observacion(a.estado)),
        ]));
      }
      b.writeln(_row([_cell('', mergeAcross: 4)]));
    }

    b
      ..writeln(_row([
        _cell('Resumen general', style: 'SummaryHeader', mergeAcross: 1),
      ]))
      ..writeln(_row([
        _cell('Puntuales', style: 'SummaryLabel'),
        _cell('$puntuales', style: 'CellCenter', type: 'Number'),
      ]))
      ..writeln(_row([
        _cell('Atrasados', style: 'SummaryLabel'),
        _cell('$atrasados', style: 'CellCenter', type: 'Number'),
      ]))
      ..writeln(_row([
        _cell('Ausentes', style: 'SummaryLabel'),
        _cell('$ausentes', style: 'CellCenter', type: 'Number'),
      ]))
      ..writeln('</Table>')
      ..writeln(_worksheetOptions(freezeTopRow: true))
      ..writeln('</Worksheet>')
      ..writeln(_datosFiltrablesSheet(filas))
      ..writeln('</Workbook>');

    return b.toString();
  }

  static String _datosFiltrablesSheet(List<ReporteAsistenciaFila> filas) {
    final ordenadas = [...filas]..sort((a, b) {
        final fecha = a.entrenamiento.inicioProgramado.compareTo(
          b.entrenamiento.inicioProgramado,
        );
        if (fecha != 0) return fecha;
        return _apellidoKey(a.asistencia.nombre).compareTo(
          _apellidoKey(b.asistencia.nombre),
        );
      });
    final lastRow = ordenadas.length + 1;
    final b = StringBuffer()
      ..writeln('<Worksheet ss:Name="Datos filtrables">')
      ..writeln('<Table>')
      ..writeln('<Column ss:Width="90"/>')
      ..writeln('<Column ss:Width="65"/>')
      ..writeln('<Column ss:Width="160"/>')
      ..writeln('<Column ss:Width="160"/>')
      ..writeln('<Column ss:Width="210"/>')
      ..writeln('<Column ss:Width="95"/>')
      ..writeln('<Column ss:Width="78"/>')
      ..writeln('<Column ss:Width="210"/>')
      ..writeln(_row([
        _cell('Fecha', style: 'HeaderCenter'),
        _cell('Hora', style: 'HeaderCenter'),
        _cell('Entrenamiento', style: 'HeaderLeft'),
        _cell('Lugar', style: 'HeaderLeft'),
        _cell('Jugador', style: 'HeaderLeft'),
        _cell('Estado', style: 'HeaderCenter'),
        _cell('Ingreso', style: 'HeaderCenter'),
        _cell('Observación', style: 'HeaderLeft'),
      ]));

    for (final fila in ordenadas) {
      final e = fila.entrenamiento;
      final a = fila.asistencia;
      b.writeln(_row([
        _cell(_fmtFecha(e.inicioProgramado), style: 'CellCenter'),
        _cell(_fmtHora(e.inicioProgramado), style: 'CellCenter'),
        _cell(e.titulo),
        _cell(e.cancha),
        _cell(a.nombre.isEmpty ? 'Sin nombre' : a.nombre),
        _cell(_etiquetaEstado(a.estado), style: _estadoStyle(a.estado)),
        _cell(
          a.unidoEn == null ? '-' : _fmtHora(a.unidoEn!),
          style: 'CellCenter',
        ),
        _cell(_observacion(a.estado)),
      ]));
    }

    b
      ..writeln('</Table>')
      ..writeln(
        '<AutoFilter x:Range="R1C1:R${lastRow}C8" '
        'xmlns="urn:schemas-microsoft-com:office:excel"/>',
      )
      ..writeln(_worksheetOptions(freezeTopRow: true))
      ..writeln('</Worksheet>');
    return b.toString();
  }

  static String _excelStyles() {
    return '''
<Styles>
  <Style ss:ID="Default" ss:Name="Normal">
    <Alignment ss:Vertical="Center"/>
    <Font ss:FontName="Calibri" ss:Size="11"/>
  </Style>
  <Style ss:ID="Title">
    <Alignment ss:Horizontal="Center" ss:Vertical="Center"/>
    <Font ss:FontName="Calibri" ss:Size="16" ss:Bold="1" ss:Color="#FFFFFF"/>
    <Interior ss:Color="#1F4E78" ss:Pattern="Solid"/>
  </Style>
  <Style ss:ID="HeaderLeft">
    <Alignment ss:Horizontal="Left" ss:Vertical="Center"/>
    <Font ss:Bold="1" ss:Color="#FFFFFF"/>
    <Interior ss:Color="#244062" ss:Pattern="Solid"/>
    <Borders><Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/><Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/><Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/><Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/></Borders>
  </Style>
  <Style ss:ID="HeaderCenter">
    <Alignment ss:Horizontal="Center" ss:Vertical="Center"/>
    <Font ss:Bold="1" ss:Color="#FFFFFF"/>
    <Interior ss:Color="#244062" ss:Pattern="Solid"/>
    <Borders><Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/><Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/><Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/><Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/></Borders>
  </Style>
  <Style ss:ID="CellLeft">
    <Alignment ss:Horizontal="Left" ss:Vertical="Center"/>
    <Borders><Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/><Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/><Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/><Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/></Borders>
  </Style>
  <Style ss:ID="CellCenter">
    <Alignment ss:Horizontal="Center" ss:Vertical="Center"/>
    <Borders><Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/><Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/><Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/><Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/></Borders>
  </Style>
  <Style ss:ID="EstadoPuntual">
    <Alignment ss:Horizontal="Center" ss:Vertical="Center"/>
    <Font ss:Bold="1" ss:Color="#006100"/>
    <Interior ss:Color="#C6EFCE" ss:Pattern="Solid"/>
    <Borders><Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/><Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/><Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/><Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/></Borders>
  </Style>
  <Style ss:ID="EstadoAtrasado">
    <Alignment ss:Horizontal="Center" ss:Vertical="Center"/>
    <Font ss:Bold="1" ss:Color="#9C6500"/>
    <Interior ss:Color="#FFEB9C" ss:Pattern="Solid"/>
    <Borders><Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/><Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/><Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/><Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/></Borders>
  </Style>
  <Style ss:ID="EstadoAusente">
    <Alignment ss:Horizontal="Center" ss:Vertical="Center"/>
    <Font ss:Bold="1" ss:Color="#9C0006"/>
    <Interior ss:Color="#FFC7CE" ss:Pattern="Solid"/>
    <Borders><Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/><Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/><Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/><Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/></Borders>
  </Style>
  <Style ss:ID="SummaryHeader">
    <Alignment ss:Horizontal="Center" ss:Vertical="Center"/>
    <Font ss:Bold="1" ss:Color="#FFFFFF"/>
    <Interior ss:Color="#1F4E78" ss:Pattern="Solid"/>
  </Style>
  <Style ss:ID="SummaryLabel">
    <Alignment ss:Horizontal="Left" ss:Vertical="Center"/>
    <Font ss:Bold="1"/>
    <Borders><Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/><Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/><Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/><Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/></Borders>
  </Style>
</Styles>''';
  }

  static String _worksheetOptions({required bool freezeTopRow}) {
    if (!freezeTopRow) return '';
    return '''
<WorksheetOptions xmlns="urn:schemas-microsoft-com:office:excel">
  <FreezePanes/>
  <FrozenNoSplit/>
  <SplitHorizontal>1</SplitHorizontal>
  <TopRowBottomPane>1</TopRowBottomPane>
  <ActivePane>2</ActivePane>
</WorksheetOptions>''';
  }

  static String _row(List<String> cells) => '<Row>${cells.join()}</Row>';

  static String _cell(
    String value, {
    String style = 'CellLeft',
    String type = 'String',
    int? mergeAcross,
  }) {
    final merge = mergeAcross == null ? '' : ' ss:MergeAcross="$mergeAcross"';
    return '<Cell ss:StyleID="$style"$merge>'
        '<Data ss:Type="$type">${_xml(value)}</Data>'
        '</Cell>';
  }

  static String _xml(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }



  static String _fmtFecha(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/'
        '${d.year}';
  }

  static String _fmtHora(DateTime d) {
    return '${d.hour.toString().padLeft(2, '0')}:'
        '${d.minute.toString().padLeft(2, '0')}';
  }

  static String _slugFecha(DateTime d) {
    return '${d.year}${d.month.toString().padLeft(2, '0')}'
        '${d.day.toString().padLeft(2, '0')}_'
        '${d.hour.toString().padLeft(2, '0')}'
        '${d.minute.toString().padLeft(2, '0')}';
  }

  static bool _esPuntual(String estado) => estado == 'presente' || estado == 'puntual';

  static String _estadoStyle(String estado) {
    if (estado == 'atrasado') return 'EstadoAtrasado';
    if (estado == 'ausente') return 'EstadoAusente';
    return 'EstadoPuntual';
  }

  static int _estadoPrioridad(String estado) {
    if (_esPuntual(estado)) return 0;
    if (estado == 'atrasado') return 1;
    return 2;
  }

  static String _observacion(String estado) {
    if (estado == 'atrasado') return 'Ingreso fuera de horario';
    if (estado == 'ausente') return 'Sin registro de ingreso';
    return 'Ingreso puntual';
  }

  static String _apellidoKey(String nombre) {
    final parts = nombre.trim().toLowerCase().split(RegExp(r'\s+'));
    if (parts.length <= 1) return nombre.trim().toLowerCase();
    return '${parts.last} ${parts.take(parts.length - 1).join(' ')}';
  }

  static String _etiquetaEstado(String estado) {
    switch (estado) {
      case 'atrasado':
        return 'Atrasado';
      case 'ausente':
        return 'Ausente';
      case 'presente':
      default:
        return 'Puntual';
    }
  }

  /// Sin `orderBy` para no exigir otro índice compuesto; se ordena en cliente.
  static Stream<QuerySnapshot<Map<String, dynamic>>> streamReportes(
    String entrenadorEmail,
  ) {
    return _db
        .collection(_col)
        .where('entrenadorEmail', isEqualTo: entrenadorEmail)
        .snapshots();
  }
}

class ReporteArchivo {
  const ReporteArchivo({
    required this.nombreArchivo,
    required this.rutaArchivo,
    required this.entrenamientoTitulo,
    required this.total,
    required this.totalEntrenamientos,
    required this.presentes,
    required this.atrasados,
    required this.ausentes,
  });

  final String nombreArchivo;
  final String? rutaArchivo;
  final String entrenamientoTitulo;
  final int total;
  final int totalEntrenamientos;
  final int presentes;
  final int atrasados;
  final int ausentes;
}

class ReporteAsistenciaFila {
  const ReporteAsistenciaFila({
    required this.entrenamiento,
    required this.asistencia,
  });

  final Entrenamiento entrenamiento;
  final AsistenciaRegistro asistencia;
}
