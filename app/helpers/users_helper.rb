module UsersHelper
  
  # 勤怠基本情報を指定のフォーマットでかえします。
  def format_basic_info(time)
    format("%.2f", ((time.hour * 60) + time.min) / 60.0)
  end   
  
  # 承認した上長を検索
  def superior_search(superior_id)
    user = User.find(superior_id)
    user.name
  end
end