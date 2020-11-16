module SessionsHelper
  # sessionとはログインを維持する機能→その機能する箱の中にuser.idを入れてログインを維持する
  def log_in(user)
    session[:user_id] = user.id
  end
  
  # 永続的セッションを(クッキーに保存)記憶します(Userモデルを参照)
  # ※cookiesの説明：永続セッションを作成するためには、cookiesというメソッドを使います
  # ※このメソッドはsessionと同様にハッシュ(ハッシュはオブジェクトがキーとバリューの二つ入っているのが特長)として扱えます
  # ※cookiesは1つのvalue（値）とexpires（有効期限）からできています
  # ※(1)20年で期限切れとなるcookiesの設定はよく使用→本来のコードの書き方(勤怠7.1.3)
  # ※(1)Railsでは専用となるpermanentという特殊なメソッドをつかて書いたのが4行目
  # signed:クッキーにそのままuser.idを入れてはダメ(session(自動で暗号化)とは違い)　保存前に安全に暗号化する為のもの
  # ユーザーIDと記憶トークンはペアで扱う必要があるのでこちらも永続化(4行目)
  def remember(user)
    user.remember
    cookies.permanent.signed[:user_id] = user.id
    cookies.permanent[:remember_token] = user.remember_token
  end
  
  def current_user?
    if session[:user_id] 
      @user = User.find(session[:user_id])
    end
  end
  
  # 永続的セッションを破棄します
  def forget(user)
    user.forget # Userモデル参照
    cookies.delete(:user_id)
    cookies.delete(:remember_token)
  end
  
  def log_out
    forget(current_user) #永続的セッションを終了(cookiesを消す)させる
    session.delete(:user_id)
    @current_user = nil
  end
  
  # 現在ログイン中のユーザーがいる場合オブジェクトを返します。
  # ◎最初のif文に対する疑問：if文がtrueの時いつも実行されるのは
  # ◎User.find_by(id: user_id)の方で@current_user(右辺の)はいらないのでは？→
  # ◎→なにもこのメソッドが実行されるのは1回だけじゃない→
  # ◎→1回目の実行の際はser.find_by(id: user_id)が実行されても、2回目以降に実行される時→
  # ◎→@cuurent_userの中身が存在している限り@current_user=@current_userが実行される
  # 今回のログイン仕様追加により、session[:user_id]が存在すれば一時的セッションから↓
  # ユーザーオブジェクトを取得し、それ以外の場合はcokkies[:user_id]から取得します。
  
  def current_user
    if (user_id = session[:user_id])
      @current_user ||= User.find_by(id: user_id) # @current_user = @current_user || User.find_by(id: session[:user_id])の省略形
    elsif (user_id = cookies.signed[:user_id])
      user = User.find_by(id: user_id)
      if user && user.authenticated?(cookies[:remember_token]) # userが存在し、引数、()の中が、データーベースの中のダイジェストと一致すれば以下の処理をする
         log_in(user)
        @current_user = user
      end
    end
  end
  
  # ログインしている状態とは、「一時的セッションにユーザーIDが存在する」ことであり、同時に先ほど定義したcurrent_userがnilではないことになりま
  # 現在ログイン中のユーザーがいればtrue、そうでなければfalseを返します。
  def logged_in?
    !current_user.nil?
  end
  
  def logged_in_user
    unless logged_in?
     store_location
     flash[:danger] = "ログインして下さい。"
     redirect_to login_url
    end
  end
  
  # アクセスしたユーザーが現在ログインしているユーザーか確認します。
  # current_userで現在ログインしているユーザーの情報を取得可
  # 上記とアクセスしたユーザー(@user)が同一人物か確認
  def correct_user
    @user = User.find(params[:id])
    unless @user == current_user
      flash[:danger] = "閲覧権限がありません。"
      redirect_to(root_url) 
    end
  end
  
  # 一般ユーザーがUrlを打ち込んで、他のユーザーの勤怠ページにアクセスするのを制限
  def show_access_limit
    @user = User.find(params[:id])
    if !current_user.admin? && !current_user.superior?
      unless @user == current_user
        flash[:danger] = "閲覧権限がありません。"
        redirect_to(root_url) 
      end
    end
  end
  
  def set_user
    @user = User.find(params[:id])
  end
  
  # 下記のメソッドでアクセスしｔURLを記憶した上で
  # 記憶しているURL(またはデフォルトURL) にリダイレクトします。
  # session.delete→一時的セッションを破棄→そうしないと次回ログイン時にも記憶されているURLに転送されてしまう
  def redirect_back_or(default_url)
    redirect_to(session[:fowarding_url] || default_url)
    session.delete(:fowarding_url)
  end
  # アクセスしようとしたURLを記憶します。
  def store_location
    session[:fowarding_url] = request.original_url if request.get?
  end
   
  # システム管理権限所有かどうか判定します。deleteメソッドで使用
  # (閲覧権限を規制するのにも使用→一般ユーザーがユーザー一覧の閲覧制限(urlを打ち込んで))
  # current_page?(users_path)→以下のように、current_page?メソッドを用いることによって、表示中のページのパスを判定できる
  def admin_user
    unless current_user.admin?
      if current_page?(users_path)
        flash[:danger] = "閲覧権限がありません。"
      end
      redirect_to root_url
    end
  end 
  
  def finished_at_is_invalid_without_a_finished_at
    
      if started_at.present? && finished_at.blank?
        errors.add(:finished_at, "が必要です")
      end
    
  end

  # 他のユーザーのshowページを上長が見た際の調整に必要→各お知らせを表示させない為のもの
  # 表示しているshowページが現在ログインしてるユーザー(上長のページ)と同じものか判断
  # showページ内で使用してる
  def correct_user_show
    @user = User.find(params[:id])
    @user == current_user
  end
end
