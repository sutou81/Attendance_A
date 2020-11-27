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
      if @attendance.update_attributes(started_at: Time.current.change(sec: 0)) && @attendance.update_attributes(approved_started_at: Time.current.change(sec: 0))
        flash[:info] = "おはようございます！"
      else


        flash[:danger] = "勤怠登録に失敗しました。やり直してください。"
      end
    elsif @attendance.finished_at.nil?
      if @attendance.update_attributes(finished_at: Time.current.change(sec: 0)) && @attendance.update_attributes(approved_finished_at: Time.current.change(sec: 0))
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
          if params[:user][:attendances][id][:onday_check_box] == "1"
            @attendance.finished_at = @attendance.finished_at+ 1.day
          end
          @attendance.oneday_instructor_confirmation = params[:user][:attendances][id][:oneday_instructor_confirmation]
          # 変更がないものを更新とみなさない為に下記のunless文
          unless @attendance.started_at_in_database == @attendance.started_at && @attendance.finished_at_in_database == @attendance.finished_at && @attendance.oneday_instructor_confirmation_in_database == @attendance.oneday_instructor_confirmation
            @attendance.oneday_instructor_confirmation = params[:user][:attendances][id][:oneday_instructor_confirmation]
            # update_one_monthの場所だけにバリデーションを効かせたい為にコンテキストを使用
            if @attendance.oneday_instructor_confirmation.present? #@attendance.valid?(:update_one_month)
              @attendance.attendance_application_status = "#{@superior1.name}へ勤怠編集申請中"
              if params[:user][:attendances][id][:onday_check_box] == "1"
                @attendance.attributes = {finished_at: @attendance.finished_at, onday_check_box: "1", note: params[:user][:attendances][id][:note]}
                count += 1 if @attendance.save!(context: :onday_check_box)
              else
                count += 1 if @attendance.update_attributes!(item)
              end
            end
          end
        else
          # oneday_instructor_confirmationとstarted_atとfinished_atの3つがそろわないと更新できなくする
          unless params[:user][:attendances][id][:finished_at].blank? && params[:user][:attendances][id][:started_at].blank?
            @attendance.attributes = {oneday_instructor_confirmation: nil}
            @attendance.save!(context: :update_one_month)
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
      flash[:success] = "勤怠申請の変更はありません"
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
      id = params[:id]
      if params[:user][:attendances][id][:instructor_confirmation].present?
        @superior = User.find(params[:user][:attendances][id][:instructor_confirmation])
        @attendance.overtime_application_status = "#{@superior.name}へ残業申請中"
        params[:user][:attendances][id][:overtime_application_status] = "#{@superior.name}へ残業申請中"
        @attendance.instructor_confirmation = params[:user][:attendances][id][:instructor_confirmation]
      end
      unless params[:user][:attendances][id]["sceduled_end_time(4i)"].blank? || params[:user][:attendances][id]["sceduled_end_time(5i)"].blank?
        @attendance.sceduled_end_time = Time.new(Time.current.year, Time.current.month, Time.current.day, params[:user][:attendances][id]["sceduled_end_time(4i)"], params[:user][:attendances][id]["sceduled_end_time(5i)"])
        params[:user][:attendances][id][:sceduled_end_time] = Time.new(Time.current.year, Time.current.month, Time.current.day, params[:user][:attendances][id]["sceduled_end_time(4i)"], params[:user][:attendances][id]["sceduled_end_time(5i)"])
      end
      if @attendance.valid?(:update_overwork_request) && @attendance.valid?(:update_overwork_request1)
        overwork_params.each do |id, item|
          @attendance1 = Attendance.find(id)
          @attendance1.update_attributes!(item)
        end
        
        @attendance.sceduled_end_time = Time.new(Time.current.year, Time.current.month, Time.current.day, params[:user][:attendances][id]["sceduled_end_time(4i)"], params[:user][:attendances][id]["sceduled_end_time(5i)"])
        #params[:user][:attendances][:sceduled_end_time] = Time.new(Time.current.year, Time.current.month, Time.current.day, params[:user][:attendances]["sceduled_end_time(4i)"], params[:user][:attendances]["sceduled_end_time(5i)"])
        #  @attendance.business_content = params[:user][:attendances][id][:business_content]
        #  @attendance.next_day = params[:user][:attendances][id][:next_day]
        #@attendance.save!
      else
        @attendance.attributes = {instructor_confirmation: nil, sceduled_end_time: nil}
        @attendance.save!(context: :update_overwork_request)
      end 
    end
    flash[:success] = "残業を申請しました"
    redirect_to user_url(@user,date:@attendance.worked_on.beginning_of_month)
  rescue ActiveRecord::RecordInvalid # トランザクション���よるエラーの分岐です。
    flash[:danger] = "未入力な項目があった為、申請をキャンセルしました。"
    redirect_to user_url(@user,date:@attendance.worked_on.beginning_of_month) and return
  end

  
  # 申請確認ボタンからの遷移モーダル
  def edit_superior_approve
    @user = User.find(params[:user_id])
    case params[:number]
    when "1"
      @attendance = Attendance.where(onemonth_instructor_confirmation: @user.id).order(:user_id, :worked_on)
      @cou1 =0
      @status = {"なし": 1, "申請中":2, "承認":3, "否認":4}
      attendance = Attendance.where(onemonth_instructor_confirmation: @user.id)
      @superior = params[:user_id]
      if attendance.blank? && @attendance.blank?
        @users = User.find(params[:user_id]) # 勤怠を編集した人のUserモデルのデータが入ってる
        @attendance3 = Attendance.find(params[:a_id]) 
        @superior = params[:superior_id]
        @number = params[:number]
      else
        # 申請者のuser_idを配列にしてる
        attendance.order(:user_id, :worked_on)
        count = attendance.count
        while count > 0
          d = attendance[attendance.count-count].user_id
          if count == attendance.count
            @ary = []

          end

          if attendance[attendance.count-count].user_id != attendance[attendance.count-(count+1)].user_id
            @ary.push(d)
          elsif d.present?
            @ary.push(d)
            @ary.uniq!
          end
          count -= 1
        end
      end

    when "2"
      
      @attendance1 = Attendance.where(oneday_instructor_confirmation: @user.id).order(:user_id, :worked_on)
      @i = 0
      @cou =0
      @nt = 0
      @status = {"なし": 1, "申請中":2, "承認":3, "否認":4}
      attendance = Attendance.where(oneday_instructor_confirmation: @user.id)
      @superior = params[:user_id]
      if attendance.blank? && @attendance1.blank?
        # *@attendance4勤怠編集申請したものの中から、確認ボタンをおしたattendanceを特定し1件、取り出す
        # 上の@attendance1は特定の上長宛てに勤怠編集申請して来たものを全て抽出
        @users = User.find(params[:user_id]) # 勤怠を編集した人のUserモデルのデータが入ってる
        @attendance4 = Attendance.find(params[:a_id])  # 勤怠編集申請したものの1件を特定する
        @superior = params[:superior_id]
        @number = params[:number]
      else
        attendance.order(:user_id, :worked_on)
        count = attendance.count
        while count > 0
          d = attendance[attendance.count-count].user_id
          if count == attendance.count
            @ary = []
          end
          if attendance[attendance.count-count].user_id != attendance[attendance.count-(count+1)].user_id
            @ary.push(d)
          elsif d.present?
            @ary.push(d)
            @ary.uniq!
          end
          count -= 1
        end
      end
      
      
    when "3"
      @attendance2 = Attendance.where(instructor_confirmation: @user.id).order(:user_id, :worked_on)
      @cou1 =0
      @status = {"なし": 1, "申請中":2, "承認":3, "否認":4}
      attendance = Attendance.where(instructor_confirmation: @user.id)
      @superior = params[:user_id]
      if attendance.blank? && @attendance2.blank?
        @users = User.find(params[:user_id]) # 勤怠を編集した人のUserモデルのデータが入ってる
        @attendance5 = Attendance.find(params[:a_id]) 
        @superior = params[:superior_id]
        @number = params[:number]
      else
        # 申請者のuser_idを配列にしてる
        attendance.order(:user_id, :worked_on)
        count = attendance.count
        while count > 0
          d = attendance[attendance.count-count].user_id
          if count == attendance.count
            @ary = []

          end

          if attendance[attendance.count-count].user_id != attendance[attendance.count-(count+1)].user_id
            @ary.push(d)
          elsif d.present?
            @ary.push(d)
            @ary.uniq!
          end
          count -= 1
        end
      end
    end
  end

  # 確認ボタン1件のみの更新・各申請を申請中から変更した場合ここで更新する
  def update_superior_approve
    @superior = params[:superior_id]
    if params[:attendance][:status] != "2" && params[:attendance][:change] == "1"
      debugger
      case params[:number]
      when "1"
        debugger
        attendance = Attendance.find(params[:attendance_id])
        a = params[:attendance][:status].to_i
        @superior = attendance.onemonth_instructor_confirmation
        debugger
        if a == 1
          attendance.onemonth_application_status = "所属長承認： 未申請"
          attendance.onemonth_instructor_confirmation =nil
          debugger
          attendance.save
          flash[:success] = "1ヶ月分の勤怠を'なし'にしました"
          debugger
          redirect_to user_path(@superior)
        elsif a == 3
          debugger
          @user = User.find(@superior)
          attendance.onemonth_application_status = "所属長承認： #{@user.name}より1ヶ月分の勤怠承認済み"
          attendance.onemonth_instructor_confirmation =nil
          attendance.save
          flash[:success] = "1ヶ月分の勤怠を'承認'しました"
          redirect_to user_path(@superior)
        elsif a == 4
          @user = User.find(@superior)
          attendance.overtime_application_status = "所属長承認： #{@user.name}より1ヶ月分の勤怠申請否認"
          attendance.onemonth_instructor_confirmation =nil
          attendance.save
          flash[:success] = "1ヶ月分の勤怠を'否認'しました"
          redirect_to user_path(@superior)
        end
      when "2"
        debugger
        attendance = Attendance.find(params[:attendance_id])
        a = params[:attendance][:status].to_i
        if a == 1
            attendance.started_at = nil
            attendance.finished_at = nil
            attendance.onday_check_box = nil
            attendance.attendance_application_status = nil
            attendance.oneday_instructor_confirmation = nil
            attendance.note = nil
            attendance.save
            flash[:success] = "勤怠編集を'なし'にしました"
            redirect_to user_path(@superior)
        elsif a == 3
          debugger
          attendance.approved_started_at = attendance.started_at
          attendance.approved_finished_at = attendance.finished_at
          if (attendance.first_approved_started_at && attendance.first_approved_finished_at) == nil
            debugger
            if attendance.approved_started_at_in_database != nil && attendance.approved_finished_at_in_database != nil
              attendance.first_approved_started_at = attendance.approved_started_at_in_database
              attendance.first_approved_finished_at = attendance.approved_finished_at_in_database
            end
          end
          attendance.approved_update_time = Time.current
          debugger
          attendance.approved_note = attendance.note
          attendance.attendance_application_status = "勤怠編集承認済み"
          attendance.save
          flash[:success] = "勤怠編集を'承認'しました"
          redirect_to user_path(@superior)
        elsif a == 4
          attendance.attendance_application_status = "勤怠編集否認"
          attendance.save
          flash[:success] = "勤怠編集を'否認'しました"
          redirect_to user_path(@superior)
        end
      when "3"
        attendance = Attendance.find(params[:attendance_id])
        a = params[:attendance][:status].to_i
        @superior = attendance.instructor_confirmation
        debugger
        if a == 1
          attendance.sceduled_end_time = nil
          attendance.next_day = nil
          attendance.business_content = nil
          attendance.instructor_confirmation = nil
          attendance.overtime_application_status = nil
          debugger
          attendance.save
          flash[:success] = "残業申請を'なし'にしました"
          debugger
          redirect_to user_path(@superior)
        elsif a == 3
          attendance.approved_sceduled_end_time = attendance.sceduled_end_time
          attendance.approved_business_content = attendance.business_content
          attendance.overtime_application_status = "残業申請承認済み"
          attendance.save
          flash[:success] = "残業申請を'承認'しました"
          redirect_to user_path(@superior)
        elsif a == 4
          attendance.overtime_application_status = "残業申請否認"
          attendance.save
          flash[:success] = "残業申請を'否認'しました"
          redirect_to user_path(@superior)
        end
      end
    elsif params[:attendance][:change] == "0"
      flash[:danger] = "変更欄にチェックを入れてください。"
      redirect_to user_path(@superior)
    elsif params[:attendance][:status] == "2" && params[:attendance][:change] == "1"
      flash[:danger] = "指示確認㊞を'申請中'以外を選択してください"
      redirect_to user_path(@superior)
    end
  end

  def new_edit_superior_approve
    @user = User.find(params[:id])
    case params[:number]
    when "1"
      @attendance = Attendance.where(onemonth_instructor_confirmation: @user.id).order(:user_id, :worked_on)
      @attendance = @attendance.where("onemonth_application_status LIKE ?", "%申請中%")
      @cou1 =0
      @status = {"なし": 1, "申請中":2, "承認":3, "否認":4}
      attendance = Attendance.where(onemonth_instructor_confirmation: @user.id)
      attendance = attendance.where("onemonth_application_status LIKE ?", "%申請中%")
      @superior = params[:id]
      if attendance.blank? && @attendance.blank?
        @users = User.find(params[:user_id]) # 1ヶ月勤怠申請した人のUserモデルのデータが入ってる
        @attendance5 = Attendance.find(params[:a_id]) 
        @superior = params[:superior_id]
      else
        # 申請者のuser_idを配列にしてる
        attendance.order(:user_id, :worked_on)
        count = attendance.count
        while count > 0
          d = attendance[attendance.count-count].user_id
          if count == attendance.count
            @ary = []

          end

          if attendance[attendance.count-count].user_id != attendance[attendance.count-(count+1)].user_id
            @ary.push(d)
            @ary.uniq!
          elsif d.present?
            @ary.push(d)
            @ary.uniq!
          end
          count -= 1
        end
      end
    when "2"
      @attendance1 = Attendance.where(oneday_instructor_confirmation: @user.id).order(:user_id, :worked_on)
      @attendance1 = @attendance1.where("attendance_application_status LIKE ?", "%申請中%")
      @i = 1
      @cou =0
      @nt = 0
      @status = {"なし": 1, "申請中":2, "承認":3, "否認":4}
      attendance = Attendance.where(oneday_instructor_confirmation: @user.id)
      attendance = attendance.where("attendance_application_status LIKE ?", "%申請中%")
      @superior = params[:id]
      if attendance.blank? && @attendance1.blank?
        # *@attendance4勤怠編集申請したものの中から、確認ボタンをおしたattendanceを特定し1件、取り出す
        # 上の@attendance1は特定の上長宛てに勤怠編集申請して来たものを全て抽出
        @users = User.find(params[:user_id]) # 勤怠を編集した人のUserモデルのデータが入ってる
        @attendance4 = Attendance.find(params[:a_id])  # 勤怠編集申請したものの1件を特定する
        @superior = params[:superior_id]
      else
        attendance.order(:user_id, :worked_on)
        count = attendance.count
        while count > 0
          d = attendance[attendance.count-count].user_id
          if count == attendance.count
            @ary = []
          end
          if attendance[attendance.count-count].user_id != attendance[attendance.count-(count+1)].user_id
            @ary.push(d)
          elsif d.present?
            @ary.push(d)
            @ary.uniq!
          end
          count -= 1
        end
      end
      
      
    when "3"
      @attendance2 = Attendance.where(instructor_confirmation: @user.id).order(:user_id, :worked_on)
      @attendance2 = @attendance2.where("overtime_application_status LIKE ?", "%申請中%")
      @cou1 =0
      @status = {"なし": 1, "申請中":2, "承認":3, "否認":4}
      attendance = Attendance.where(instructor_confirmation: @user.id)
      attendance = attendance.where("overtime_application_status LIKE ?", "%申請中%")
      debugger
      @superior = params[:id]
      if attendance.blank? && @attendance2.blank?
        @users = User.find(params[:user_id]) # 勤怠を編集した人のUserモデルのデータが入ってる
        @attendance5 = Attendance.find(params[:a_id]) 
        @superior = params[:superior_id]
      else
        # 申請者のuser_idを配列にしてる
        attendance.order(:user_id, :worked_on)
        count = attendance.count
        while count > 0
          d = attendance[attendance.count-count].user_id
          if count == attendance.count
            @ary = []

          end

          if attendance[attendance.count-count].user_id != attendance[attendance.count-(count+1)].user_id
            @ary.push(d)
            @ary.uniq!
          elsif d.present?
            @ary.push(d)
            @ary.uniq!
          end
          count -= 1
        end
      end
    end
  end

  # 上長からの指示を受けて複数の勤怠編集申請や残業申請の更新
  def new_update_superior_approve
    @user = User.find(params[:id])
    ary = []
    i = 0
    k = 0
    n = 0
    m = 0
    l = 0
    params[:user][:attendances].each do |id, item|
      ary.push([id.to_i,item[:status].to_i, item[:changes].to_i])
    end
    ary.count
    ary.each do |a|
      if a[2] == 0
        i = i + 1
      end
      if a[1] == 2
        k = k + 1
      end
    end
    if ary.count == i
      flash[:danger] = "変更対象のレコードにチェックを入れてください。"
      redirect_to user_path(@user)
    elsif ary.count == k
      flash[:danger] = "変更対象の指示者確認㊞を'申請中'以外を選択してください。"
      redirect_to user_path(@user)
    else
      # ↓ 指示確認印が'申請中'または変更チェックボタンがないものを取り除く
      ary.delete_if{ |a|
        a[1] == 2 || a[2] == 0
      }
      case params[:number]
      when "1" # 1か月の勤怠申請関連
        ary.each do |a|
          attendance = Attendance.find(a[0]) # ここで申請してきた勤怠を特定する
          if a[1] == 1
            attendance.onemonth_application_status = "所属長承認： 未申請"
            attendance.onemonth_instructor_confirmation =nil
            attendance.save
            l += 1
          elsif a[1] == 3
            attendance.onemonth_application_status = "所属長承認： #{@user.name}より1ヶ月分の勤怠承認済み"
            attendance.onemonth_instructor_confirmation =nil
            attendance.save
            m += 1
          elsif a[1] == 4
            attendance.onemonth_application_status = "所属長承認： #{@user.name}より1ヶ月分の勤怠申請否認"
            attendance.onemonth_instructor_confirmation =nil
            attendance.save
            n += 1
          end
        end
        flash[:success] = "残業申請を 承認: #{m}件、否認: #{n}件、なし: #{l}件 しました。"
        redirect_to user_path(@user)

      when "2" # 勤怠編集申請関連
        # ↓ 指示確認印が'申請中'または変更チェックボタンがないものを取り除く
        ary.delete_if{ |a|
          a[1] == 2 || a[2] == 0
        }
        # 申請の更新の分岐
        ary.each do |a|
          attendance = Attendance.find(a[0]) # ここで申請してきたユーザーを特定する。
          if a[1] == 1
            attendance.started_at = nil
            attendance.finished_at = nil
            attendance.onday_check_box = nil
            attendance.attendance_application_status = nil
            attendance.oneday_instructor_confirmation = nil
            attendance.note = nil
            attendance.save
            l += 1
          elsif a[1] == 3
            attendance.approved_started_at = attendance.started_at
            attendance.approved_finished_at = attendance.finished_at
            if (attendance.first_approved_started_at && attendance.first_approved_finished_at) == nil
              if attendance.approved_started_at_in_database != nil && attendance.approved_finished_at_in_database != nil
                attendance.first_approved_started_at = attendance.approved_started_at_in_database
                attendance.first_approved_finished_at = attendance.approved_finished_at_in_database
              end
            end
            attendance.approved_update_time = Time.current
            attendance.approved_note = attendance.note
            attendance.attendance_application_status = "勤怠編集承認済み"
            attendance.save
            m += 1

          elsif a[1] == 4
            attendance.attendance_application_status = "勤怠編集否認"
            attendance.save
            n += 1
 
          end
        end
        flash[:success] = "勤怠編集申請を 承認: #{m}件、否認: #{n}件、なし: #{l}件 しました。"
        redirect_to user_path(@user)

      when "3" # 残業申請関連
        debugger
        ary.each do |a|
          attendance = Attendance.find(a[0]) # ここで申請してきたユーザーを特定する
          if a[1] == 1
            attendance.sceduled_end_time = nil
            attendance.next_day = nil
            attendance.business_content = nil
            attendance.instructor_confirmation = nil
            attendance.overtime_application_status = nil
            attendance.save
            l += 1
          elsif a[1] == 3
            attendance.approved_sceduled_end_time = attendance.sceduled_end_time
            attendance.approved_business_content = attendance.business_content
            attendance.overtime_application_status = "残業申請承認済み"
            attendance.save
            m += 1
          elsif a[1] == 4
            attendance.overtime_application_status = "残業申請否認"
            attendance.save
            n += 1
          end
        end
        flash[:success] = "残業申請を 承認: #{m}件、否認: #{n}件、なし: #{l}件 しました。"
        redirect_to user_path(@user)
      end

    end

  end

  # 勤怠変更ログ
  def attendance_log
    @year = {"年": 1, "2015": 2, "2016": 3, "2017": 4, "2018": 5, "2019": 6, "2020": 7, "2021": 8, "2022": 9, "2023": 10, "2024": 11, "2025": 12, }
    @year_select = 1
    @month = {"月": 1, "1": 2, "2": 3,"4": 5, "5": 6, "6": 7, "7": 8, "8": 9, "9": 10, "10": 11, "11": 12, "12": 13 }
    @month_select = 1

  end

  # 1ヶ月申請をする
  def update_month_approval
    @user = User.find(params[:user_id])
    @attendance = Attendance.find(params[:id])
    if params[:attendance][:onemonth_instructor_confirmation].present?
      @user = User.find(params[:user_id])
      @superior = User.find(params[:attendance][:onemonth_instructor_confirmation])
      @attendance = Attendance.find(params[:id])
      @attendance.onemonth_application_status = "所属長承認： #{@superior.name}に申請中"
      status = "所属長承認： #{@superior.name}に申請中"
      month_superior_params[:onemonth_application_status] = "所属長承認： #{@superior.name}に申請中"
      if @attendance.update_attributes(month_superior_params)
        flash[:success] = "#{@superior.name}に1ヶ月分の勤怠を申請しました"
        redirect_to user_url(@user,date:@attendance.worked_on.beginning_of_month)
      else
        flash[:success] = "1ヶ月分の勤怠申請に失敗しました"
        redirect_to user_url(@user, date:@attendance.worked_on.beginning_of_month)
      end
    else
      flash[:danger] = "申請先の上長を選択してください"
      redirect_to user_url(@user, date:@attendance.worked_on.beginning_of_month)
    end
  end
  private
    # 1ヶ月分の勤怠情報を扱います。勤怠11章テキスト説明あり
    def attendances_params
      params.require(:user).permit(attendances: [:started_at, :finished_at, :note, :oneday_instructor_confirmation, :attendance_application_status, :onday_check_box, :id])[:attendances]
    end

    # 残業情報を扱う
    def overwork_params
      params.require(:user).permit(attendances: [:sceduled_end_time, :next_day, :business_content, :instructor_confirmation, :overtime_application_status])[:attendances]
    end

    # 上長へ1ヶ月の勤怠承認申請
    def month_superior_params
      params.require(:attendance).permit(:onemonth_instructor_confirmation).merge(onemonth_application_status: @attendance.onemonth_application_status)
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
