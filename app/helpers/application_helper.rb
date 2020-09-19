module ApplicationHelper
  
  # ページごとにタイトルを返す
  def full_title(page_name = "")
    basic_title = "AttendanceApp"
    if page_name.empty?
      basic_title
    else
      page_name + ' | ' + basic_title # 文字列を連結して返す
    end
  end
end
