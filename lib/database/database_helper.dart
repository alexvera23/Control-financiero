import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

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
}