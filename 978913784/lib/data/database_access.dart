import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../entity/page.dart';

class DatabaseAccess {
  static final DatabaseAccess _databaseAccess = DatabaseAccess._internal();

  static Database _db;

  factory DatabaseAccess() {
    return _databaseAccess;
  }

  DatabaseAccess._internal();

  static void initialize() async {
    _db = await openDatabase(
      join(await getDatabasesPath(), 'database.db'),
      onCreate: (db, version) {
        db.execute(
          'CREATE TABLE pages('
          'id INTEGER PRIMARY KEY AUTOINCREMENT,'
          ' title TEXT, iconIndex INTEGER,'
          ' isPinned INTEGER,'
          ' creationTime INTEGER'
          ');',
        );
        db.execute(
          'CREATE TABLE events('
          'id INTEGER PRIMARY KEY AUTOINCREMENT,'
          ' pageId INTEGER,'
          ' iconIndex INTEGER,'
          ' isFavourite INTEGER,'
          ' description TEXT,'
          ' creationTime INTEGER,'
          ' imagePath TEXT'
          ');',
        );
      },
      version: 1,
    );
  }

  Future<List<JournalPage>> fetchPages() async {
    final pagesMap = await _db.query('pages');

    var pages = List<JournalPage>.generate(pagesMap.length, (i) {
      return JournalPage.fromDb(
        pagesMap[i]['id'],
        pagesMap[i]['title'],
        pagesMap[i]['iconIndex'],
        pagesMap[i]['isPinned'] == 0 ? false : true,
        DateTime.fromMillisecondsSinceEpoch(pagesMap[i]['creationTime'] * 1000),
      );
    });

    for (var i = 0; i < pagesMap.length; i++) {
      await _fetchLastEvent(pages[i]);
    }

    return pages;
  }

  void _fetchLastEvent(JournalPage page) async {
    final eventMap = await _db.rawQuery(
      'SELECT * FROM events WHERE creationTime = ( SELECT MAX ( creationTime )'
      ' FROM ( SELECT * FROM events WHERE pageId = ? ) )',
      [page.id],
    );

    if (eventMap.isNotEmpty) {
      page.lastEvent = Event.fromDb(
        eventMap.first['id'],
        eventMap.first['pageId'],
        eventMap.first['iconIndex'],
        eventMap.first['isFavourite'] == 0 ? false : true,
        eventMap.first['description'],
        DateTime.fromMillisecondsSinceEpoch(
            eventMap.first['creationTime'] * 1000),
        eventMap.first['imagePath'],
      );
    } else {
      page.lastEvent = null;
    }
  }

  Future<List<Event>> fetchEvents(int pageId) async {
    final eventsMap =
        await _db.rawQuery('SELECT * FROM events WHERE pageId = ?', [pageId]);
    final events = List.generate(eventsMap.length, (i) {
      return Event.fromDb(
        eventsMap[i]['id'],
        eventsMap[i]['pageId'],
        eventsMap[i]['iconIndex'],
        eventsMap[i]['isFavourite'] == 0 ? false : true,
        eventsMap[i]['description'],
        DateTime.fromMillisecondsSinceEpoch(
            eventsMap[i]['creationTime'] * 1000),
        eventsMap[i]['imagePath'],
      );
    });
    events.sort((a, b) => a.creationTime.compareTo(b.creationTime));
    return events;
  }

  Future<void> insertPage(JournalPage page) async {
    await _db.insert(
      'pages',
      page.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updatePage(JournalPage page) async {
    await _db.update(
      'pages',
      page.toMap(),
      where: 'id = ?',
      whereArgs: [page.id],
    );
  }

  Future<void> deletePage(JournalPage page) async {
    await _db.delete(
      'pages',
      where: 'id = ?',
      whereArgs: [page.id],
    );
  }

  Future<int> insertEvent(Event event) async {
    return _db.insert(
      'events',
      event.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateEvent(Event event) async {
    await _db.update(
      'events',
      event.toMap(),
      where: 'id = ?',
      whereArgs: [event.id],
    );
  }

  Future<void> deleteEvent(Event event) async {
    await _db.delete(
      'events',
      where: 'id = ?',
      whereArgs: [event.id],
    );
  }
}
