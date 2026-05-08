import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/users.dart';
import '../models/categoria.dart';
import '../models/movimiento.dart';
import '../models/presupuesto.dart';

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
    return await db.delete(
      tableCategorias,
      where: 'id = ?',
      whereArgs: [id],
    );
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

  /// Elimina un movimiento por su ID.
  Future<int> eliminarMovimiento(int id) async {
    final db = await instance.database;
    return await db.delete(
      tableMovimientos,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}