class UsersController < ApplicationController
  protect_from_forgery except: :import 
  require 'rounding'
  before_action :set_user, only: [:show, :edit, :update, :destroy, :edit_basic_info, :update_basic_info]
  before_action :logged_in_user, only: [:edit, :update, :destroy, :index, :edit_basic_info, :update_basic_info]
  before_action :correct_user, only: [:edit]
  before_action :show_access_limit, only: :show
  before_action :admin_user, only: [:index, :destroy, :edit_basic_info, :update_basic_info, :employees_at_work]
  before_action :set_one_month, only: :show
  
  def new
    @user = User.new
  end
  # 編集前 @user = User.paginate(page: params[:page]).search(params[:search])
  def index
    @user = User.paginate(page: params[:page]).search(params[:search])
  end
  
  # 1ヶ月分の勤怠データの中で、出勤時間が何も無い状態では無いものの数を代入
  # @attendancesはbefore_actionのset_one_month内で指定してあるから使える
  def show
    @one_month_approval = @user.attendances.find_by(worked_on: @last_day) # 1ヶ月の最後の日を特定
    @approval = @one_month_approval.onemonth_application_status
    @bunkatu = @approval.split(/\A(.{1,6})/,2)
    @bun = @bunkatu[1]
    @katu = @bunkatu[2]
    @worked_sum = @attendances.where.not(started_at: nil).count
    @attendance = Attendance.where(onemonth_instructor_confirmation: @user.id)
    @attendance = @attendance.where("onemonth_application_status LIKE ?", "%申請中%")
    @attendance.order(:user_id, :worked_on)
    @attendance1 = Attendance.where(oneday_instructor_confirmation: @user.id)
    @attendance1 = @attendance1.where("attendance_application_status LIKE ?", "%申請中%")
    @attendance1.order(:user_id, :worked_on)
    @attendance2 = Attendance.where(instructor_confirmation: @user.id)
    @attendance2 = @attendance2.where("overtime_application_status LIKE ?", "%申請中%")
    @attendance2.order(:user_id, :worked_on)
    @superior = User.where(superior: true)
    if params[:id].present?
      @specific = params[:attendance_id]
    end
    if params[:superior_id].present?
      @superior = params[:superior_id]
    end
    if params[:id].present?
      @users = User.find(params[:id])
    end
    case params[:number]
    when "1"
      @btn_name = "1ヶ月分の勤怠の承認"
      @attendance_i = @specific
      @number_i = 1
    when "2"
      @btn_name = "勤怠変更の承認"
      @attendance_i = @specific
      @number_i = 2
    when "3" 
      @btn_name = "残業申請の承認"
      @attendance_i = @specific
      @number_i = 3
    end
    if params[:date]
      month = params[:date].to_date
      @month = month.month
    end
    respond_to do |format|
      format.html
      format.csv do |csv|
        send_posts_csv(@attendances, @month)
      end
    end
  end

  def send_posts_csv(attendances,month)
    require 'csv'

    bom = "\uFEFF"
    CSV.generate(bom) do |csv|
      column_names = %w(日付 曜日 出社時間 退社時間 在社時間)
      csv << column_names
      attendances.each do |day|
        a = day.approved_started_at == nil ? nil : l(day.approved_started_at, format: :time)
        b = day.approved_finished_at == nil ? nil : l(day.approved_finished_at, format: :time)
        column_values = [
          l(day.worked_on, format: :short),
          $days_of_the_week[day.worked_on.wday],
          a,
          b
          
        ]
        csv << column_values
      end
    end
    send_data render_to_string, filename: "#{month}月の勤怠.csv", type: :csv
  end
  
  def create
    @user = User.new(user_params)
    if @user.save
      log_in(@user) # 保存成功後、ログインします。
      
      flash[:success] = "新規作成しました。"
      redirect_to user_url(@user) # ←はredirect_to user_url(@user)と同等→ @userの意味するところ：user.id
    else
      render :new
    end
  end
  
  def edit
  end
  
  # もし、更新エラーをユーザー一覧ページに表示したいなら 以下の文を挿入
  # flash[:danger] = @user.errors.full_messages.join("<br>") redirect_to users_path(@user)
  def update
    if @user.update_attributes(new_user_params)
      flash[:success] = "#{@user.name}の基本情報を更新しました"
      redirect_to users_url(@user)
    else
      render :edit
    end
  end
  
  def destroy
    @user.delete
    flash[:success] = "#{@user.name}のデータを削除しました"
    redirect_to users_url
  end
  
  def edit_basic_info
    @user = User.find(params[:id])
  end
  
  # @user.errors.full_messagesは配列のため、joinメソッドを使って要素ごとに「、」で区切るよう指定しています。これでひとまず更新失敗時に動作するはずです。
  def update_basic_info
      if @user.admin? && params[:user][:checkbox] == '0'
        if @user.update_attributes(basic_info_params) 
          @user = User.all
          @user.each do |user|
            user.update_attributes(basic_info_params)
          end
          flash[:success] = "全ユーザーの基本情報を更新しました。"
        else
          flash[:danger] = "全ユーザーの更新は失敗しました。<br>" + @user.errors.full_messages.join("<br>")
        end
      elsif !@user.admin? || params[:user][:checkbox] == '1'
        if @user.update_attributes(basic_info_params)
          flash[:success] = "#{@user.name}の基本情報を更新しました"
        else
        flash[:danger] = "#{@user.name}の更新は失敗しました。<br>"+ @user.errors.full_messages.join("<br>")

        end
      end
    redirect_to users_url
  end

  def import
    
   cnt, a = User.import(params[:file])
   cnt1 =cnt.count
    if cnt1 > 0
    flash[:warning] ="既に登録されているユーザー情報を更新したいのなら、こちらのページで直接行ってください。"
    flash[:danger] = "<br>#{cnt[0]}<br>""<br>#{cnt[1]}<br>""<br>#{cnt[2]}<br>""<br>#{cnt[3]}<br>""<br>#{cnt[4]}"
    end
   if a >= 1
    flash[:success] ="#{a}件追加・登録しました。"
   end
   
   
   redirect_to users_url
  end
  
  # 勤怠変更ログ
  def attendance_log
    @user = User.find(params[:id])
    @reset = DateTime.new(Time.current.year, Time.current.month, 1)
    if params[:date]
      date = params[:date].to_date # 日付形式にしてる
      @years = date.year
      @months = date.month
    else
      date = DateTime.new(params[:user][:year].to_i, params[:user][:month].to_i-1, 1) #ajaxで送られてきた物を日付に加工
      @years = date.year
      @months = date.month
    end
    @attendance = @user.attendances
    @attendance = @attendance.where.not(approved_finished_at: nil)
    if params[:date]
      search = params[:date].to_date
    else
      search = date.to_date
    end
    @search = @attendance.where(worked_on: search.beginning_of_month..search.end_of_month) # selectで選択された年月の承認ログを抽出
    @year = {" 年 ": 1, "2015": 2015, "2016": 2016, "2017": 2017, "2018": 2018, "2019": 2019, "2020": 2020, "2021": 2021, "2022": 2022, "2023": 2023, "2024": 2024, "2025": 2025 }
    @year_select = 1
    @month = {" 月 ": 1, "1": 2, "2": 3,"4": 5, "5": 6, "6": 7, "7": 8, "8": 9, "9": 10, "10": 11, "11": 12, "12": 13 }
    @month_select = 1
    @ajax = "できた"
    respond_to do |format|
      format.html
      format.js {@search=nil, @search1=@attendance.where(worked_on: search.beginning_of_month..search.end_of_month) }

      
    end
  end

  # 出社社員一覧
  def employees_at_work
    @attendance = Attendance.where.not(started_at: nil).where(finished_at: nil)
  end
  
  private
  
    def user_params
      params.require(:user).permit(:name, :email, :department, :password, :password_cofirmation)
    end

    def new_user_params
      params.require(:user).permit(:name, :email, :affiliation, :employee_number, :uid, :password, :basic_work_time, :designated_work_start_time, :designated_work_end_time)
    end
    
    def basic_info_params
      params.require(:user).permit(:department, :basic_time, :work_time)
    end
    
  # beforeフィルター(logged_in_user, correct_user→sessions_helper.rbにあり)
  
  # paramsハッシュからユーザーを取得します。
  def set_user
    @user = User.find(params[:id])
  end
end
