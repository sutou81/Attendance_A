Rails.application.routes.draw do

  root 'static_pages#top'
  get  '/signup', to: 'users#new'
  
  # ログイン機能
  get   '/login', to: 'sessions#new'
  post  '/login', to: 'sessions#create'
  delete '/logout', to: 'sessions#destroy'

  # member:urlにuserを識別するためのid(userモデルのidカラム)が追加される
  # 上と比べてcollection:はurlにidは追加されない 
  # 但し、memberもcollectionも、今回の様に同じusersの下(同じループの中)にコード書いたなら→urlにusersが入ってくる
  resources :users do
    member do
      get 'edit_basic_info'
      patch 'update_basic_info'
      get 'attendances/edit_overwork_request' # 残業申請に関する追加
      patch 'attendances/update_overwork_request' # 残業申請に関する追加
      get 'attendances/edit_one_month' # この行が追加対象です。
      patch 'attendances/update_one_month' # この行が追加対象です。
    end
    collection { post :import } 
    resources :attendances do
      member do 
        get 'edit_overwork_request'
        patch 'update_overwork_request'
        get 'edit_superior_approve'
        patch 'update_superior_approve'
      end
    end
  end
end
