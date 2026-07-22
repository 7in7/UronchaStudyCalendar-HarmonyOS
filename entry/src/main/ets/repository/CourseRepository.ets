/**
 * 课程数据仓库
 * 提供 courses 表的增删改查
 */
import { relationalStore } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { Course } from '../models/Course';
import { ScheduleDatabase } from '../database/ScheduleDatabase';

const COURSE_COLUMNS: string[] = [
  'id', 'name', 'location', 'teacher', 'dayOfWeek', 'startSection',
  'endSection', 'weeks', 'description', 'semesterId', 'createdAt', 'updatedAt'
];

export class CourseRepository {
  /**
   * 查询所有课程
   */
  static async getAll(context: common.Context): Promise<Course[]> {
    try {
      const store = await ScheduleDatabase.getInstance(context);
      const predicates = new relationalStore.RdbPredicates('courses');
      const resultSet = await store.query(predicates, COURSE_COLUMNS);
      const courses: Course[] = [];
      while (resultSet.goToNextRow()) {
        courses.push(CourseRepository.mapRowToCourse(resultSet));
      }
      resultSet.close();
      return courses;
    } catch (e) {
      console.error('CourseRepository.getAll failed', e);
      return [];
    }
  }

  /**
   * 按学期查询课程
   */
  static async getBySemester(context: common.Context, semesterId: string): Promise<Course[]> {
    try {
      const store = await ScheduleDatabase.getInstance(context);
      const predicates = new relationalStore.RdbPredicates('courses');
      predicates.equalTo('semesterId', semesterId);
      const resultSet = await store.query(predicates, COURSE_COLUMNS);
      const courses: Course[] = [];
      while (resultSet.goToNextRow()) {
        courses.push(CourseRepository.mapRowToCourse(resultSet));
      }
      resultSet.close();
      return courses;
    } catch (e) {
      console.error('CourseRepository.getBySemester failed', e);
      return [];
    }
  }

  /**
   * 插入课程
   */
  static async insert(context: common.Context, course: Course): Promise<void> {
    try {
      const store = await ScheduleDatabase.getInstance(context);
      await store.insert('courses', CourseRepository.courseToValues(course));
    } catch (e) {
      console.error('CourseRepository.insert failed', e);
      throw new Error(String(e));
    }
  }

  /**
   * 更新课程
   */
  static async update(context: common.Context, course: Course): Promise<void> {
    try {
      const store = await ScheduleDatabase.getInstance(context);
      const predicates = new relationalStore.RdbPredicates('courses');
      predicates.equalTo('id', course.id);
      await store.update(CourseRepository.courseToValues(course), predicates);
    } catch (e) {
      console.error('CourseRepository.update failed', e);
      throw new Error(String(e));
    }
  }

  /**
   * 删除课程
   */
  static async delete(context: common.Context, id: string): Promise<void> {
    try {
      const store = await ScheduleDatabase.getInstance(context);
      const predicates = new relationalStore.RdbPredicates('courses');
      predicates.equalTo('id', id);
      await store.delete(predicates);
    } catch (e) {
      console.error('CourseRepository.delete failed', e);
      throw new Error(String(e));
    }
  }

  private static mapRowToCourse(rs: relationalStore.ResultSet): Course {
    try {
      return {
        id: rs.getString(rs.getColumnIndex('id')),
        name: rs.getString(rs.getColumnIndex('name')),
        location: rs.getString(rs.getColumnIndex('location')) ?? '',
        teacher: rs.getString(rs.getColumnIndex('teacher')) ?? '',
        dayOfWeek: rs.getLong(rs.getColumnIndex('dayOfWeek')),
        startSection: rs.getLong(rs.getColumnIndex('startSection')),
        endSection: rs.getLong(rs.getColumnIndex('endSection')),
        weeks: JSON.parse(rs.getString(rs.getColumnIndex('weeks')) || '[]') as number[],
        description: rs.getString(rs.getColumnIndex('description')) ?? '',
        semesterId: rs.getString(rs.getColumnIndex('semesterId')),
        createdAt: rs.getString(rs.getColumnIndex('createdAt')),
        updatedAt: rs.getString(rs.getColumnIndex('updatedAt'))
      };
    } catch (e) {
      throw new Error(String(e));
    }
  }

  private static courseToValues(course: Course): relationalStore.ValuesBucket {
    return {
      id: course.id,
      name: course.name,
      location: course.location,
      teacher: course.teacher,
      dayOfWeek: course.dayOfWeek,
      startSection: course.startSection,
      endSection: course.endSection,
      weeks: JSON.stringify(course.weeks),
      description: course.description ?? '',
      semesterId: course.semesterId,
      createdAt: course.createdAt,
      updatedAt: course.updatedAt
    };
  }
}
