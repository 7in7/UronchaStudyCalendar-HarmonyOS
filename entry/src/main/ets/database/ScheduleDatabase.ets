/**
 * 课程表本地数据库
 * 基于 relationalStore（SQLite）实现
 */
import { relationalStore } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';

const DB_NAME = 'schedule.db';

export class ScheduleDatabase {
  private static store?: relationalStore.RdbStore;

  /**
   * 获取数据库实例（单例，首次调用会建表）
   */
  static async getInstance(context: common.Context): Promise<relationalStore.RdbStore> {
    if (ScheduleDatabase.store) {
      return ScheduleDatabase.store;
    }
    try {
      const config: relationalStore.StoreConfig = {
        name: DB_NAME,
        securityLevel: relationalStore.SecurityLevel.S1
      };
      ScheduleDatabase.store = await relationalStore.getRdbStore(context, config);
      await ScheduleDatabase.initTables();
      return ScheduleDatabase.store;
    } catch (e) {
      console.error('ScheduleDatabase.getInstance failed', e);
      throw new Error(String(e));
    }
  }

  /**
   * 初始化数据表
   */
  private static async initTables(): Promise<void> {
    if (!ScheduleDatabase.store) {
      return;
    }

    try {
      await ScheduleDatabase.store.executeSql(`
        CREATE TABLE IF NOT EXISTS semesters (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          startDate TEXT NOT NULL,
          totalWeeks INTEGER NOT NULL,
          weekStartDay INTEGER NOT NULL DEFAULT 1,
          isCurrent INTEGER NOT NULL DEFAULT 1,
          createdAt TEXT NOT NULL,
          updatedAt TEXT NOT NULL
        )
      `);

      await ScheduleDatabase.store.executeSql(`
        CREATE TABLE IF NOT EXISTS time_slots (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          sectionNumber INTEGER NOT NULL UNIQUE,
          startTime TEXT NOT NULL,
          endTime TEXT NOT NULL,
          name TEXT
        )
      `);

      await ScheduleDatabase.store.executeSql(`
        CREATE TABLE IF NOT EXISTS courses (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          location TEXT,
          teacher TEXT,
          dayOfWeek INTEGER NOT NULL,
          startSection INTEGER NOT NULL,
          endSection INTEGER NOT NULL,
          weeks TEXT NOT NULL,
          description TEXT,
          semesterId TEXT NOT NULL,
          createdAt TEXT NOT NULL,
          updatedAt TEXT NOT NULL
        )
      `);

      await ScheduleDatabase.store.executeSql(`
        CREATE TABLE IF NOT EXISTS events (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          detail TEXT,
          actionType TEXT NOT NULL DEFAULT 'none',
          actionTarget TEXT,
          actionParameters TEXT,
          actionDescription TEXT,
          createdAt TEXT NOT NULL,
          updatedAt TEXT NOT NULL
        )
      `);

      await ScheduleDatabase.store.executeSql(`
        CREATE TABLE IF NOT EXISTS timeline_nodes (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          eventId TEXT NOT NULL,
          nodeId INTEGER NOT NULL,
          type TEXT NOT NULL,
          date TEXT NOT NULL,
          nodeName TEXT NOT NULL,
          icon TEXT,
          FOREIGN KEY (eventId) REFERENCES events(id) ON DELETE CASCADE
        )
      `);
    } catch (e) {
      console.error('ScheduleDatabase.initTables failed', e);
      throw new Error(String(e));
    }
  }
}
