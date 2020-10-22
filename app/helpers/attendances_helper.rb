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

  # viewページでコントローラーに書くような事を避ける為のメッソド
  def apply_to_superior(attendance, id)
    o = attendance.where(user_id: id)
    u = User.find(id)
    return o, u
  end
  
  
  
  # 出勤時間と退社時間を受け取り、在社時間を計算して返します。
  def working_times(start, finish)
    format("%.2f", (((finish - start) / 60) / 60.0))
  end
end
