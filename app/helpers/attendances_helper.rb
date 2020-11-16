module AttendancesHelper
  
  def attendance_state(attendance)
    # 受け取ったAttendanceオブジェクトが当日と一致するか評価します。
    if Date.current == attendance.worked_on
      return '出勤' if attendance.started_at.nil?
      return '退勤' if attendance.started_at.present? && attendance.finished_at.nil?
    end
    # どれにも当てはまらなかった場合はfalseを返します。
    false
  end
  #  Date.current == attendance.worked_on より前日の日にstarted_atのみ(出勤登録のみ投下)でfinished_atの投下せず翌日になってしまった時にそれを消去する
  def attendance_state_before_day(attendance)
    if Date.current > attendance.worked_on
      if attendance.started_at.present? && attendance.finished_at.nil?
        attendance..started_at = nil
        attendance.save
      end
    end
    # どれにも当てはまらなかった場合はfalseを返します。
    false
  end

  # viewページでコントローラーに書くような事を避ける為のメッソド
  # 上長に申請してきた物の中から➀各個人ごとにピックアップし、➁申請してきた人を特定しその人の情報を取り出す
  def apply_to_superior(attendance, id) # ➀
    o = attendance.where(user_id: id) # ➁
    u = User.find(id)
    return o, u
  end

  # 上長の指示確認㊞の状況により表示内容を場合分けする判断基準(残業時間ver)
  def approval_include_overwork(overtime_application_status)
    overtime_application_status.include?("申請") || overtime_application_status.include?("否認") ||  overtime_application_status.blank?
  end

  # 上長の指示確認㊞の状況により表示内容を場合分けする判断基準(勤怠編集ver(時間関係以外))
  def approval_include_oneday(attendance_application_status)
    attendance_application_status.include?("承認")
  end

  # 上長の指示確認㊞の状況により表示内容を場合分けする判断基準(勤怠編集ver(時間関係))
  def approval_include_oneday_time(approved_started_at, approved_finished_at, started_at, finished_at, attendance_application_status)
    if approved_started_at.present? && approved_finished_at.present?
      new_started_at = approved_started_at
      new_finished_at = approved_finished_at
    #elsif (started_at.present? || finished_at.present?) &&  attendance_application_status == nil
    elsif approved_started_at.present? || approved_finished_at.present? 
      new_started_at = approved_started_at
      new_finished_at = approved_finished_at
    else
      new_started_at = nil
      new_finished_at = nil
      
    end
    return new_started_at, new_finished_at
  end

  
  
  
  # 出勤時間と退社時間を受け取り、在社時間を計算して返します。
  def working_times(start, finish)
    format("%.2f", (((finish - start) / 60) / 60.0))
  end

  # 残業時間の計算
  def overtime_hours(designated_work_end_time, sceduled_end_time, next_day)
    d = designated_work_end_time
    s = sceduled_end_time
    # 下記のchangeでdesignated_work_end_timeがmigrateを行った日(sceduled_end_timeより前の日でも)
    # ちゃんと計算できるよう年月日を調整してる
    d.change(year: s.year)
    d.change(month: s.month)
    d.change(day: s.day)
    n =d.change(year: s.year, month: s.month, day: s.day)
    if next_day == "1"
      format("%.2f", (((s - (n - 1.day)) / 60) / 60.0))
    else
      format("%.2f", (((s - n) / 60) / 60.0))
    end
  end

  def overtime_hours_real(sceduled_end_time, approved_finished_at, next_day)
    a = approved_finished_at
    s = sceduled_end_time
    a.change(year: s.year)
    a.change(month: s.month)
    a.change(day: s.day)
    if next_day == "1"
      format("%.2f", (((s - (a - 1.day)) / 60) / 60.0))
    else
      format("%.2f", (((s - a) / 60) / 60.0))
    end
  end
end
