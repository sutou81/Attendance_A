source 'https://rubygems.org'

gem 'rails', '~> 5.2.4', '>= 5.2.4.2'
gem 'rounding' # 時間を丸めるもの　今回は15分単位で
gem 'bcrypt' # パスワードをハッシュ化する物です
gem 'rails-i18n' # 日本語化するための物
gem 'bootstrap-sass' # bootstrap導入
gem 'will_paginate' # この行を追加してください。
gem 'bootstrap-will_paginate' # この行を追加してください。
gem 'faker'
gem 'puma', '~> 3.11'
gem 'sass-rails', '~> 5.0'
gem 'uglifier', '>= 1.3.0'
gem 'coffee-rails', '~> 4.2'
gem 'jquery-rails'
gem 'turbolinks', '~> 5'
gem 'jbuilder', '~> 2.5'
gem 'bootsnap', require: false

group :development, :test do
  gem 'sqlite3', '1.3.13'
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
end

group :development do
  gem 'web-console', '>= 3.3.0'
  gem 'listen', '>= 3.0.5', '< 3.2'
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end


# Windows環境ではtzinfo-dataというgemを含める必要があります
# Mac環境でもこのままでOKです
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]