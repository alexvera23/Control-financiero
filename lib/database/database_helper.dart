import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/users.dart';
import '../models/categoria.dart';
import '../models/movimiento.dart';

class DatabaseHelper {
  // Patrón Singleton: asegura que solo exista una instancia de esta clase.
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  // Nombres de las tablas
  static const String tableUsuarios = 'usuarios';
  static const String tableCategorias = 'categorias';
  static const String tableMovimientos = 'movimientos';
  static const String tablePresupuestos = 'presupuestos';

  // Getter de la base de datos
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('control_financiero.db');
    return _database!;
  }

  // Inicialización de la BD
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    // Incrementa la versión si en el futuro necesitas alterar las tablas (onUpgrade)
    return await openDatabase(
      path,
      version: 1,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
    );
  }

  // Habilitar llaves foráneas en SQLite (Importante para las relaciones)
  Future _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  // Creación de las 4 tablas basadas en las especificaciones del PDF
  Future _onCreate(Database db, int version) async {
    // 1. Tabla Usuarios
    await db.execute('''
      CREATE TABLE $tableUsuarios (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL
      )
    ''');

    // 2. Tabla Categorías
    // Relación: Una categoría pertenece a un usuario.
    // ON DELETE CASCADE: Si se borra el usuario, se borran sus categorías.
    await db.execute('''
      CREATE TABLE $tableCategorias (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        color TEXT NOT NULL,
        icono TEXT NOT NULL,
        usuario_id INTEGER NOT NULL,
        FOREIGN KEY (usuario_id) REFERENCES $tableUsuarios (id) ON DELETE CASCADE
      )
    ''');

    // 3. Tabla Movimientos
    // Relación: Un movimiento pertenece a un usuario y a una categoría.
    await db.execute('''
      CREATE TABLE $tableMovimientos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tipo TEXT NOT NULL, -- 'Ingreso' o 'Gasto'
        cantidad REAL NOT NULL,
        descripcion TEXT NOT NULL,
        fecha TEXT NOT NULL, -- Formato ISO8601 (YYYY-MM-DD)
        metodo_pago TEXT NOT NULL, -- 'Efectivo', 'Tarjeta', 'Transferencia'
        categoria_id INTEGER NOT NULL,
        usuario_id INTEGER NOT NULL,
        FOREIGN KEY (categoria_id) REFERENCES $tableCategorias (id) ON DELETE CASCADE,
        FOREIGN KEY (usuario_id) REFERENCES $tableUsuarios (id) ON DELETE CASCADE
      )
    ''');

    // 4. Tabla Presupuestos
    // Relación: Un presupuesto es para una categoría específica en un mes/año, por un usuario.
    await db.execute('''
      CREATE TABLE $tablePresupuestos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        monto REAL NOT NULL,
        mes INTEGER NOT NULL,
        anio INTEGER NOT NULL,
        categoria_id INTEGER NOT NULL,
        usuario_id INTEGER NOT NULL,
        FOREIGN KEY (categoria_id) REFERENCES $tableCategorias (id) ON DELETE CASCADE,
        FOREIGN KEY (usuario_id) REFERENCES $tableUsuarios (id) ON DELETE CASCADE
      )
    ''');
  }

  // ------------------------------------------------------------------------
  // Métodos útiles genéricos para cerrar o limpiar la base de datos
  // ------------------------------------------------------------------------

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }

  // Método de emergencia por si necesitan reiniciar la BD durante el desarrollo
  Future<void> deleteDatabaseFile() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'control_financiero.db');
    await deleteDatabase(path);
  }

  // MÓDULO 1: MÉTODOS DE AUTENTICACIÓN (Usuario)

  /// Registra un nuevo usuario en la base de datos.
  /// Retorna el ID del nuevo usuario si fue exitoso.
  /// Lanza una excepción si el correo ya existe.
  Future<int> registrarUsuario(User usuario) async {
    final db = await instance.database;

    // 1. Verificar si el email ya existe
    final result = await db.query(
      tableUsuarios,
      where: 'email = ?',
      whereArgs: [usuario.email],
    );

    if (result.isNotEmpty) {
      throw Exception('El correo electrónico ya está registrado.');
    }

    // 2. Si no existe, insertar el nuevo usuario
    // SQLite generará automáticamente el ID
    return await db.insert(tableUsuarios, usuario.toMap());
  }

  /// Valida las credenciales para el inicio de sesión.
  /// Retorna el objeto User si las credenciales son correctas,
  /// o null si el correo o la contraseña son incorrectos.
  Future<User?> loginUsuario(String email, String password) async {
    final db = await instance.database;

    // Buscar un usuario que coincida con el email y el password
    final result = await db.query(
      tableUsuarios,
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );

    // Si encontramos una coincidencia, retornamos el objeto User
    if (result.isNotEmpty) {
      return User.fromMap(result.first);
    } else {
      // Credenciales inválidas
      return null;
    }
  }

  /// (Opcional pero útil) Obtener los datos de un usuario por su ID
  /// Sirve para cuando abres la app y ya hay una sesión guardada.
  Future<User?> getUsuarioById(int id) async {
    final db = await instance.database;
    final result = await db.query(
      tableUsuarios,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (result.isNotEmpty) {
      return User.fromMap(result.first);
    }
    return null;
  }

  // ─────────────────────────────────────────────────────────────
  //  MÓDULO 5 – CRUD CATEGORÍAS
  // ─────────────────────────────────────────────────────────────

  /// Crea una nueva categoría para el usuario dado.
  Future<int> insertarCategoria(Categoria categoria) async {
    final db = await instance.database;
    return await db.insert(tableCategorias, categoria.toMap());
  }

  /// Retorna todas las categorías del usuario.
  Future<List<Categoria>> getCategorias(int usuarioId) async {
    final db = await instance.database;
    final maps = await db.query(
      tableCategorias,
      where: 'usuario_id = ?',
      whereArgs: [usuarioId],
      orderBy: 'nombre ASC',
    );
    return maps.map((m) => Categoria.fromMap(m)).toList();
  }

  /// Actualiza los datos de una categoría existente.
  Future<int> actualizarCategoria(Categoria categoria) async {
    final db = await instance.database;
    return await db.update(
      tableCategorias,
      categoria.toMap(),
      where: 'id = ?',
      whereArgs: [categoria.id],
    );
  }

  /// Elimina una categoría. Por CASCADE, sus movimientos también se eliminan.
  Future<int> eliminarCategoria(int id) async {
    final db = await instance.database;
    return await db.delete(tableCategorias, where: 'id = ?', whereArgs: [id]);
  }

  // ─────────────────────────────────────────────────────────────
  //  MÓDULO 3 y 4 – CRUD MOVIMIENTOS
  // ─────────────────────────────────────────────────────────────

  /// Inserta un nuevo movimiento.
  Future<int> insertarMovimiento(Movimiento movimiento) async {
    final db = await instance.database;
    return await db.insert(tableMovimientos, movimiento.toMap());
  }

  /// Retorna los movimientos del usuario con JOIN para obtener
  /// nombre, color e icono de la categoría.
  /// Permite filtrar por tipo ('Ingreso'/'Gasto'), categoriaId y rango de fechas.
  Future<List<Movimiento>> getMovimientos(
    int usuarioId, {
    String? tipo,
    int? categoriaId,
    String? fechaDesde, // YYYY-MM-DD
    String? fechaHasta, // YYYY-MM-DD
  }) async {
    final db = await instance.database;

    // Construir WHERE dinámicamente
    final conditions = <String>['m.usuario_id = ?'];
    final args = <dynamic>[usuarioId];

    if (tipo != null) {
      conditions.add("m.tipo = ?");
      args.add(tipo);
    }
    if (categoriaId != null) {
      conditions.add("m.categoria_id = ?");
      args.add(categoriaId);
    }
    if (fechaDesde != null) {
      conditions.add("m.fecha >= ?");
      args.add(fechaDesde);
    }
    if (fechaHasta != null) {
      conditions.add("m.fecha <= ?");
      args.add(fechaHasta);
    }

    final whereClause = conditions.join(' AND ');

    // JOIN con categorías para traer nombre, color e icono
    final maps = await db.rawQuery('''
      SELECT 
        m.id, m.tipo, m.cantidad, m.descripcion,
        m.fecha, m.metodo_pago, m.categoria_id, m.usuario_id,
        c.nombre AS categoria_nombre, c.color, c.icono
      FROM $tableMovimientos m
      INNER JOIN $tableCategorias c ON m.categoria_id = c.id
      WHERE $whereClause
      ORDER BY m.fecha DESC, m.id DESC
    ''', args);

    return maps.map((m) => Movimiento.fromMap(m)).toList();
  }

  /// Actualiza un movimiento existente.
  Future<int> actualizarMovimiento(Movimiento movimiento) async {
    final db = await instance.database;
    return await db.update(
      tableMovimientos,
      movimiento.toMap(),
      where: 'id = ?',
      whereArgs: [movimiento.id],
    );
  }

  // Obtener suma total por tipo (Ingreso/Gasto) para el Dashboard
  Future<double> getTotalPorTipo(int usuarioId, String tipo) async {
    final db = await instance.database;
    final result = await db.rawQuery(
      'SELECT SUM(cantidad) as total FROM Movimientos WHERE usuario_id = ? AND tipo = ?',
      [usuarioId, tipo],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  // Obtener gastos agrupados por categoría para las Estadísticas
  Future<List<Map<String, dynamic>>> getGastosPorCategoria(
    int usuarioId,
  ) async {
    final db = await instance.database;
    return await db.rawQuery(
      '''
      SELECT c.nombre, c.color, SUM(m.cantidad) as total 
      FROM $tableMovimientos m
      INNER JOIN $tableCategorias c ON m.categoria_id = c.id
      WHERE m.usuario_id = ? AND m.tipo = 'Gasto'
      GROUP BY c.id
    ''',
      [usuarioId],
    );
  }

  // Función para el Módulo 2 (Dashboard) - Resumen del mes actual
  Future<Map<String, double>> getResumenMensual(int usuarioId) async {
    final db = await instance.database;

    // Obtenemos todos los movimientos del usuario
    final List<Map<String, dynamic>> res = await db.query(
      tableMovimientos,
      where: 'usuario_id = ?',
      whereArgs: [usuarioId],
    );

    double ingresos = 0.0;
    double gastos = 0.0;

    for (var row in res) {
      double cantidad = (row['cantidad'] as num).toDouble();
      if (row['tipo'] == 'Ingreso') {
        ingresos += cantidad;
      } else {
        gastos += cantidad;
      }
    }

    return {
      'ingresos': ingresos,
      'gastos': gastos,
      'balance': ingresos - gastos,
    };
  }

  /// Elimina un movimiento por su ID.
  Future<int> eliminarMovimiento(int id) async {
    final db = await instance.database;
    return await db.delete(tableMovimientos, where: 'id = ?', whereArgs: [id]);
  }

  // ─────────────────────────────────────────────────────────────
  //  MÓDULO 6 – CRUD PRESUPUESTOS
  // ─────────────────────────────────────────────────────────────

  /// Inserta un nuevo presupuesto.
  Future<int> insertarPresupuesto(Map<String, dynamic> presupuesto) async {
    final db = await instance.database;
    return await db.insert(tablePresupuestos, presupuesto);
  }

  /// Obtiene todos los presupuestos del usuario para un mes/año específico.
  Future<List<Map<String, dynamic>>> getPresupuestos(
    int usuarioId, {
    int? mes,
    int? anio,
  }) async {
    final db = await instance.database;
    final conditions = <String>['p.usuario_id = ?'];
    final args = <dynamic>[usuarioId];

    if (mes != null) {
      conditions.add('p.mes = ?');
      args.add(mes);
    }
    if (anio != null) {
      conditions.add('p.anio = ?');
      args.add(anio);
    }

    final whereClause = conditions.join(' AND ');

    return await db.rawQuery('''
      SELECT p.*, c.nombre AS categoria_nombre, c.color
      FROM $tablePresupuestos p
      INNER JOIN $tableCategorias c ON p.categoria_id = c.id
      WHERE $whereClause
      ORDER BY c.nombre ASC
    ''', args);
  }

  /// Obtiene gasto actual de una categoría en un mes específico.
  Future<double> getGastoActualCategoria(
    int usuarioId,
    int categoriaId,
    int mes,
    int anio,
  ) async {
    final db = await instance.database;
    final result = await db.rawQuery(
      '''
      SELECT SUM(m.cantidad) as total
      FROM $tableMovimientos m
      WHERE m.usuario_id = ? 
        AND m.categoria_id = ? 
        AND m.tipo = 'Gasto'
        AND strftime('%m', m.fecha) = ?
        AND strftime('%Y', m.fecha) = ?
    ''',
      [usuarioId, categoriaId, mes.toString().padLeft(2, '0'), anio.toString()],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  /// Actualiza un presupuesto existente.
  Future<int> actualizarPresupuesto(Map<String, dynamic> presupuesto) async {
    final db = await instance.database;
    final id = presupuesto['id'];
    return await db.update(
      tablePresupuestos,
      presupuesto,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Elimina un presupuesto por su ID.
  Future<int> eliminarPresupuesto(int id) async {
    final db = await instance.database;
    return await db.delete(tablePresupuestos, where: 'id = ?', whereArgs: [id]);
  }

  /// Obtiene ingresos vs gastos mensuales para gráfico de evolución.
  Future<List<Map<String, dynamic>>> getEvolucionMensual(
    int usuarioId, {
    int meses = 6,
  }) async {
    final db = await instance.database;
    final ahora = DateTime.now();
    final resultados = <Map<String, dynamic>>[];

    for (int i = meses - 1; i >= 0; i--) {
      final fecha = DateTime(ahora.year, ahora.month - i, 1);
      final mes = fecha.month.toString().padLeft(2, '0');
      final anio = fecha.year.toString();

      final result = await db.rawQuery(
        '''
        SELECT 
          SUM(CASE WHEN tipo = 'Ingreso' THEN cantidad ELSE 0 END) as ingresos,
          SUM(CASE WHEN tipo = 'Gasto' THEN cantidad ELSE 0 END) as gastos
        FROM $tableMovimientos
        WHERE usuario_id = ? 
          AND strftime('%m', fecha) = ?
          AND strftime('%Y', fecha) = ?
      ''',
        [usuarioId, mes, anio],
      );

      final row = result.first;
      resultados.add({
        'mes': fecha.month,
        'anio': fecha.year,
        'ingresos': (row['ingresos'] as num?)?.toDouble() ?? 0.0,
        'gastos': (row['gastos'] as num?)?.toDouble() ?? 0.0,
      });
    }

    return resultados;
  }
}
