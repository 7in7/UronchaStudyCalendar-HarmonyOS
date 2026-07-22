/**
 * 学期数据仓库
 * 提供 semesters 表的增删改查
 */
import { relationalStore } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { util } from '@kit.ArkTS';
import { Semester } from '../models/Semester';
import { ScheduleDatabase } from '../database/ScheduleDatabase';

const SEMESTER_COLUMNS: string[] = [
  'id', 'name', 'startDate', 'totalWeeks', 'weekStartDay', 'isCurrent', 'createdAt', 'updatedAt'
];

export class SemesterRepository {
  /**
   * 确保至少存在一个当前学期；若不存在则创建默认学期
   */
  static async ensureCurrent(context: common.Context): Promise<Semester> {
    const existing = await SemesterRepository.getCurrent(context);
    if (existing) {
      return existing;
    }

    const now = new Date();
    const isoDate = now.toISOString();
    const datePart = isoDate.split('T')[0];
    const semester: Semester = {
      id: SemesterRepository.generateUuid(),
      name: '默认学期',
      startDate: datePart,
      totalWeeks: 20,
      weekStartDay: 1,
      isCurrent: true,
      createdAt: isoDate,
      updatedAt: isoDate
    };
    await SemesterRepository.insert(context, semester);
    return semester;
  }

  /**
   * 获取当前学期
   */
  static async getCurrent(context: common.Context): Promise<Semester | undefined> {
    try {
      const store = await ScheduleDatabase.getInstance(context);
      const predicates = new relationalStore.RdbPredicates('semesters');
      predicates.equalTo('isCurrent', 1);
      const resultSet = await store.query(predicates, SEMESTER_COLUMNS);
      if (resultSet.goToNextRow()) {
        const semester = SemesterRepository.mapRowToSemester(resultSet);
        resultSet.close();
        return semester;
      }
      resultSet.close();
      return undefined;
    } catch (e) {
      console.error('SemesterRepository.getCurrent failed', e);
      return undefined;
    }
  }

  /**
   * 查询所有学期
   */
  static async getAll(context: common.Context): Promise<Semester[]> {
    try {
      const store = await ScheduleDatabase.getInstance(context);
      const predicates = new relationalStore.RdbPredicates('semesters');
      const resultSet = await store.query(predicates, SEMESTER_COLUMNS);
      const semesters: Semester[] = [];
      while (resultSet.goToNextRow()) {
        semesters.push(SemesterRepository.mapRowToSemester(resultSet));
      }
      resultSet.close();
      return semesters;
    } catch (e) {
      console.error('SemesterRepository.getAll failed', e);
      return [];
    }
  }

  /**
   * 插入学期
   */
  static async insert(context: common.Context, semester: Semester): Promise<void> {
    try {
      const store = await ScheduleDatabase.getInstance(context);
      await store.insert('semesters', SemesterRepository.semesterToValues(semester));
    } catch (e) {
      console.error('SemesterRepository.insert failed', e);
      throw new Error(String(e));
    }
  }

  /**
   * 更新学期
   */
  static async update(context: common.Context, semester: Semester): Promise<void> {
    try {
      const store = await ScheduleDatabase.getInstance(context);
      const predicates = new relationalStore.RdbPredicates('semesters');
      predicates.equalTo('id', semester.id);
      await store.update(SemesterRepository.semesterToValues(semester), predicates);
    } catch (e) {
      console.error('SemesterRepository.update failed', e);
      throw new Error(String(e));
    }
  }

  /**
   * 删除学期
   */
  static async delete(context: common.Context, id: string): Promise<void> {
    try {
      const store = await ScheduleDatabase.getInstance(context);
      const predicates = new relationalStore.RdbPredicates('semesters');
      predicates.equalTo('id', id);
      await store.delete(predicates);
    } catch (e) {
      console.error('SemesterRepository.delete failed', e);
      throw new Error(String(e));
    }
  }

  private static mapRowToSemester(rs: relationalStore.ResultSet): Semester {
    try {
      return {
        id: rs.getString(rs.getColumnIndex('id')),
        name: rs.getString(rs.getColumnIndex('name')),
        startDate: rs.getString(rs.getColumnIndex('startDate')),
        totalWeeks: rs.getLong(rs.getColumnIndex('totalWeeks')),
        weekStartDay: rs.getLong(rs.getColumnIndex('weekStartDay')),
        isCurrent: rs.getLong(rs.getColumnIndex('isCurrent')) === 1,
        createdAt: rs.getString(rs.getColumnIndex('createdAt')),
        updatedAt: rs.getString(rs.getColumnIndex('updatedAt'))
      };
    } catch (e) {
      throw new Error(String(e));
    }
  }

  private static semesterToValues(semester: Semester): relationalStore.ValuesBucket {
    return {
      id: semester.id,
      name: semester.name,
      startDate: semester.startDate,
      totalWeeks: semester.totalWeeks,
      weekStartDay: semester.weekStartDay,
      isCurrent: semester.isCurrent ? 1 : 0,
      createdAt: semester.createdAt,
      updatedAt: semester.updatedAt
    };
  }

  private static generateUuid(): string {
    return util.generateRandomUUID();
  }
}
