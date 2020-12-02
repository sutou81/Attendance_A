class OfficesController < ApplicationController
  before_action :set_office, only: [:edit, :update, :destroy]
  before_action :admin_user

  def index
    @office = Office.new
    @offices = Office.all
    @status = {"出勤": "出勤", "退勤": "退勤"}
    # 拠点番号でダブらないな工夫
    for num in 1..999999 do
       o = Office.find_by(office_number: num)
      if !o
       @count = num
       break @count
      end
    end
  end

  def create 
    @office = Office.new(office_params)
    if @office.save 
      flash[:success] = "新規拠点:#{@office.office_name}を追加しました"
      redirect_to offices_url
    else
      flash[:danger] = @office.errors.full_messages.join("<br>")
      redirect_to offices_url 
    end
  end

  def destroy
    @office.delete
    flash[:danger] = "拠点:#{@office.office_name}のデータを削除しました"
    redirect_to offices_url
  end

  def edit
  end

  def update
    if @office.update_attributes(office_params)
      flash[:success] = "拠点:#{@office.office_name}の拠点情報を更新しました。"
      redirect_to offices_url
    else
      render :edit
    end
  end

  private
    def office_params
      params.require(:office).permit(:office_number, :office_name, :attendance_type)
    end

  # beforeフィルター(logged_in_user, correct_user→sessions_helper.rbにあり)
  
  # paramsハッシュからユーザーを取得します。
  def set_office
    @office = Office.find(params[:id])
  end
end
