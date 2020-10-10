class AttendancesController < ApplicationController
  before_action :set_user, only: [:edit_one_month, :update_one_month]
  before_action :logged_in_user, only: [:update, :edit_one_month]
  before_action :admin_or_correct_user, only: [:update, :edit_one_month, :update_one_month]
  before_action :set_one_month, only: :edit_one_month
  
  def update 
    # 更新対象のuserを特定(@user)し、更新対象の勤怠データを特定(@attendance)する
    @user = User.find(params[:user_id])
    @attendance = Attendance.find(params[:id])
    # 出勤時間が未登録であることを判定します。
    if @attendance.started_at.nil?
      if @attendance.update_attributes(started_at: Time.current.change(sec: 0))
        flash[:info] = "おはようございます！"
      else
        flash[:danger] = "勤怠登録に失敗しました。やり直してください。"
      end
    elsif @attendance.finished_at.nil?
      if @attendance.update_attributes(finished_at: Time.current.change(sec: 0))
        flash[:info] = "お疲れ様でした。"
      else
        flash[:danger] = "勤怠登録に失敗しました。やり直してください。"
      end
    end
    redirect_to user_url(@user)
  end
  
  def edit_one_month
    @superior = User.where(superior: true)
  end
  
  # 繰り返し処理の中では、まずはじめにidを使って更新対象となるオブジェクトを変数に代入します。
  # その後、update_attributesメソッドの引数にitemを指定し、オブジェクトの情報を更新します
  # update_attributes!:「!」が付いている意味→通常更新失敗時はfalseが返る→
  # ↑ →「！」を付けるとfalseでなく例外処理を返します
  # *勤怠11章参照:attendance_params～初めのend→ここにトランザクション(データベースの操作を保証したい処理)を適用します
  # *flash～初めのredirect_to→全ての繰返し更新処理が問題なく完了した時はこの部分の処理を実行
  # *rescue以下→例外が発生した時は、この部分の処理を実行
  def update_one_month
    count = 0
    ActiveRecord::Base.transaction do # トランザクションを開始します。
      attendances_params.each do |id, item|
        @attendance = Attendance.find(id)
        if params[:user][:attendances][id][:oneday_instructor_confirmation].present?
          @superior1 = User.find(params[:user][:attendances][id][:oneday_instructor_confirmation])
          @attendance.started_at = params[:user][:attendances][id][:started_at]
          @attendance.finished_at = params[:user][:attendances][id][:finished_at]
          @attendance.oneday_instructor_confirmation = params[:user][:attendances][id][:oneday_instructor_confirmation]
          # 変更がないものを更新とみなさない為に下記のunless文
          unless @attendance.started_at_in_database == @attendance.started_at && @attendance.finished_at_in_database == @attendance.finished_at && @attendance.oneday_instructor_confirmation_in_database == @attendance.oneday_instructor_confirmation
            
            @attendance.oneday_instructor_confirmation = params[:user][:attendances][id][:oneday_instructor_confirmation]
            # update_one_monthの場所だけにバリデーションを効かせたい為にコンテキストを使用
            if @attendance.oneday_instructor_confirmation.present? #@attendance.valid?(:update_one_month)
              @attendance.attendance_application_status = "#{@superior1.name}へ勤怠編集申請中"
              
              count += 1 if @attendance.update_attributes!(item)
            end
          end
        end
        # if item[:started_at].present? && item[:finished_at].blank?
        #   flash[:danger] = "終了時間が入力されてません。"
        #   redirect_to attendances_edit_one_month_user_url(date: params[:date]) and return
        # end
        # if @attendance.changed?
        #   debugger
        #   count += 1
        # end
        # if  @attendance != params[:user][:attendances][id]
        #   params[:user][:attendances][id][:attendance_application_status] = "#{@superior1.name}へ勤怠編集申請中"
        #   @attendance.attendance_application_status = "#{@superior1.name}へ勤怠編集申請中"
        #   debugger
        # end
        
        # if @attendance.valid?(:update_one_month)
        #   @attendance.update_attributes!(item)
        # end       
      end
    end
    if count > 0
      flash[:success] = "勤怠変更を合計#{count}件申請しました。"
    else
      flash[:success] = "勤怠の変更はありません"
    end
    redirect_to user_url(date: params[:date])
  rescue ActiveRecord::RecordInvalid # トランザクション���よるエラーの分岐です。
    flash[:danger] = "無効な入力データがあった為、更新をキャンセルしました。"
    redirect_to attendances_edit_one_month_user_url(date: params[:date]) and return
  end

   # 残業申請のモーダル
   def edit_overwork_request
    @attendance = Attendance.find(params[:id])
    @user = User.find(@attendance.user_id)
    @superior = User.where(superior: true)
    
  end

  # 残業申請モーダル更新
   def update_overwork_request
    ActiveRecord::Base.transaction do # トランザクションを開始します。
      @attendance = Attendance.find(params[:id])
      @user =User.find(params[:user_id])
      if params[:user][:attendances][:instructor_confirmation].present?
        @superior = User.find(params[:user][:attendances][:instructor_confirmation])
        @attendance.overtime_application_status = "#{@superior.name}へ残業申請中"
        @attendance.instructor_confirmation = params[:user][:attendances][:instructor_confirmation]
      end
      if @attendance.valid?(:update_overwork_request) && @attendance.valid?(:update_overwork_request1)
        @attendance.update_attributes!(overwork_params)
        m = Time.current
        @attendance.sceduled_end_time = Time.new(Time.current.year, Time.current.month, Time.current.day, params[:user][:attendances]["sceduled_end_time(4i)"], params[:user][:attendances]["sceduled_end_time(5i)"])
        params[:user][:attendances][:sceduled_end_time] = Time.new(Time.current.year, Time.current.month, Time.current.day, params[:user][:attendances]["sceduled_end_time(4i)"], params[:user][:attendances]["sceduled_end_time(5i)"])
        @attendance.save!
      else
        @attendance.attributes = {instructor_confirmation: nil, sceduled_end_time: nil}
        @attendance.save!(context: :update_overwork_request)
      end 
    end
    flash[:success] = "残業を申請しました"
    redirect_to user_url(@user)
  rescue ActiveRecord::RecordInvalid # トランザクション���よるエラーの分岐です。
    flash[:danger] = "未入力な項目があった為、申請をキャンセルしました。"
    redirect_to user_url(@user) and return
  end
  
  
  private
    # 1ヶ月分の勤怠情報を扱います。勤怠11章テキスト説明あり
    def attendances_params
      params.require(:user).permit(attendances: [:started_at, :finished_at, :note, :oneday_instructor_confirmation, :attendance_application_status])[:attendances]
    end

    # 残業情報を扱う
    def overwork_params
      params.require(:user).permit(attendances: [:sceduled_end_time, :next_day, :business_content, :instructor_confirmation, :overtime_application_status])[:attendances]
    end
  
  # beforeフィルター
  # 管理権限者、または現在ログインしているユーザーを許可します。
  def admin_or_correct_user
    @user = User.find(params[:user_id]) if @user.blank?
    unless @user == current_user || current_user.admin?
      flash[:danger] = "編集権限がありません"
      redirect_to(root_url)
    end
  end
end
