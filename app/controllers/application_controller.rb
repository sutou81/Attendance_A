class ApplicationController < ActionController::Base
  require 'rounding'
  protect_from_forgery with: :exception
  # paramsハッシュからユーザーを取得します。
  def set_user
    @user = User.find(params[:id])
  end
  include SessionsHelper
  include ActionView::Helpers::UrlHelper
  # %w{日 月 火 水 木 金 土}はRubyのリテラル表記と呼ばれるものです。
  # ["日", "月", "火", "水", "木", "金", "土"]の配列と同じように使えます。
  # $変数名 →グローバル変数 グローバル変数は極端に言うとプログラムのどこからでも呼び出すことのできる変数で
  $days_of_the_week = %w{日 月 火 水 木 金 土}
  
  def set_one_month 
    @first_day = params[:date].nil? ?
    Date.current.beginning_of_month : params[:date].to_date
    @last_day = @first_day.end_of_month
    @one_month = [*@first_day..@last_day] 
    @count = [*1..@one_month.count]
    # ↓1ヶ月分のユーザーに紐付く勤怠データを検索し取得する それを＠attendancesに入れてる
    @attendances = @user.attendances.where(worked_on: @first_day..@last_day).order(:worked_on)
    
    # 1ヶ月の日数と勤怠データ（@userの）の数が一致しなかったら以下(Activ～)を実行する
    unless @one_month.count == @attendances.count
      # トランザクションの説明：勤怠10章10.3参照
      # トランザクション→まとめてデータを保存や更新するときに、全部成功したことを保証するための機能
      # *Active～2つ目の処理にエラーが出た際ロールバックし(繰り返しが行われる前のデータベースの状態に戻る)
      # *rescueの中身(flashメッセージとredirect)が実行される
      ActiveRecord::Base.transaction do
        # 1ヶ月分worked_onに日付が入ったAttendanceモデルのデータが生成されている
        @one_month.each do |day|
          @user.attendances.create!(worked_on: day)
        end
      end
    end
    
    # rescue→例外(上記のActive～)がでたときに実行される救援措置
  rescue ActiveRecord::RecordInvalid
    flash[:danger] = "ページ情報の取得に失敗しました、再アクセスしてください。"
    redirect_to root_url
   
  end

   
end