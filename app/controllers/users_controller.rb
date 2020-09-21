class UsersController < ApplicationController
  protect_from_forgery except: :import 
  require 'rounding'
  before_action :set_user, only: [:show, :edit, :update, :destroy, :edit_basic_info, :update_basic_info]
  before_action :logged_in_user, only: [:edit, :update, :destroy, :index, :edit_basic_info, :update_basic_info]
  before_action :correct_user, only: [:edit, :update]
  before_action :show_access_limit, only: :show
  before_action :admin_user, only: [:index, :destroy, :edit_basic_info, :update_basic_info]
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
    @worked_sum = @attendances.where.not(started_at: nil).count
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
  
  def update
    if @user.update_attributes(user_params)
      flash[:success] = 'ユーザー情報を更新しました'
      redirect_to user_url(@user)
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
        flash[:danger] = "#{@user.name}の更新は失敗しました。<br>"

        end
      end
    redirect_to users_url
  end

  def import
    
   cnt, a = User.import(params[:file])
   if cnt != nil
    flash[:warning] ="既に登録されているユーザー情報を更新したいのなら、こちらのページで直接行ってください。"
   end
   if a >= 1
    flash[:success] ="#{a}件追加・登録しました。"
   end
   flash[:danger] = "<br>#{cnt[0]}<br>""<br>#{cnt[1]}<br>""<br>#{cnt[2]}<br>""<br>#{cnt[3]}<br>""<br>#{cnt[4]}"
   
   redirect_to users_url
  end
  
  
  private
  
    def user_params
      params.require(:user).permit(:name, :email, :department, :password, :password_cofirmation)
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
