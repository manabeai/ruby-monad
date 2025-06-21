---
theme: seriph
background: https://source.unsplash.com/1920x1080/?ruby,programming
class: text-center
highlighter: shiki
lineNumbers: false
info: |
  ## dry-rb紹介
  
  関数型プログラミングの概念をRubyで実現するライブラリ群の紹介
drawings:
  persist: false
transition: slide-left
title: dry-rb入門
mdc: true
---

---

# 関数型まつり行ってきました

---

# dry-rb入門

関数型プログラミングをRubyで実現するツールキット

<div class="pt-12">
  <span @click="$slidev.nav.next" class="px-2 py-1 rounded cursor-pointer" hover="bg-white bg-opacity-10">
    Press Space for next page <carbon:arrow-right class="inline"/>
  </span>
</div>

<div class="abs-br m-6 flex gap-2">
  <button @click="$slidev.nav.openInEditor()" title="Open in Editor" class="text-xl slidev-icon-btn opacity-50 !border-none !hover:text-white">
    <carbon:edit />
  </button>
  <a href="https://github.com/dry-rb" target="_blank" alt="GitHub"
    class="text-xl slidev-icon-btn opacity-50 !border-none !hover:text-white">
    <carbon-logo-github />
  </a>
</div>

---

# dry-rbとは？

関数型プログラミングの概念をRubyで実現するライブラリ群

<v-clicks>

- **関数型プログラミング** - 副作用を避け、不変性を重視
- **モナド** - エラーハンドリングや値の変換を安全に
- **バリデーション** - 堅牢なデータ検証システム
- **設定管理** - 型安全な設定ファイル管理
- **依存性注入** - テスタブルで保守性の高いコード

</v-clicks>

<br>
<br>

dry-rbは単一のライブラリではなく、それぞれ独立した**ライブラリ群**

---

# つらいコード

```ruby
class User
  attr_reader :id, :email
  def initialize(id:, email:)
    @id = id
    @email = email
  end
  
  # @param id [Integer]
  # @return [User | nil] User
  def self.create(id:)
    # フィールドはnilかもしれない...
    user =
      if rand < 0.25
        new(id: "id#{id}", email: "example#{id}@example.com")
      elsif rand < 0.5
        new(id: "id#{id}", email: nil)
      ...

    # どっちもnilじゃなければインスタンスを返す
    if user.id.nil? || user.email.nil? ? nil : user
  end
  
  def save_to_db
    puts "保存しました: #{id}, #{email}"
  end
end
```

実行すると...

---
layout: center
---

# インスタンス化できなかった理由を呼び出し元で知りたい

---

# 方法1. エラーにする

```ruby
class MissingIdError < StandardError; end
class MissingEmailError < StandardError; end

class User
  def self.create(id:)
    user = # 省略

    raise MissingIdError, "User ID cannot be nil" if user.id.nil?
    raise MissingEmailError, "User email cannot be nil" if user.email.nil?
    user
  end
end
```

## 問題点
- **ビジネスロジックで発生しうる例外はErrorとして扱うべきではない**
- **どんどん複雑になる** - 例外が増えるとコードが読みにくくなる

---

# 2. 結果をタプル(風)で返す

```ruby
class User
  def self.create(id:)
    user = # 省略
    
    return [:error, :missing_id] if user.id.nil?
    return [:error, :missing_email] if user.email.nil?
    
    [:ok, user]
  end
end

# 使用例
status, result = User.create(id: 1)
case status
when :ok
  result.save_to_db
when :error
  puts "エラー: #{result}"
end
```

<v-click>

### 問題点
- **そもそもRubyにタプルはない**
- **`知るべきこと` が増える**
  - 配列のどちらが補足情報か
  - シンボルの値は何か
- **エラーの詳細情報が限定的** - シンボルだけで足りる？

</v-click>

---

# Dry-monadsを使って戻り値を`包む`
```ruby
class MUser
  include Dry::Monads[:result]
  extend Dry::Monads[:result]  
  attr_reader :id, :email

  def initialize(id:, email:)
    @id = id
    @email = email
  end

  def self.create(id:)
    r = rand
    user = # 省略

    user.id.nil? || user.email.nil? ? Failure(user) : Success(user)
  end
end
---

# 実行結果

```ruby
# 10回実行した結果
10.times do
  begin
    user = User.create(id: rand(1..10))
    puts "成功: id=#{user.id}, email=#{user.email}"
  rescue MissingIdError => e
    puts "エラー: #{e.message}"
  rescue MissingEmailError => e
    puts "エラー: #{e.message}"
  end
end
```

<v-click>

```
成功: id=id7, email=example7@example.com
エラー: User email cannot be nil
エラー: User ID cannot be nil
エラー: User email cannot be nil
成功: id=id3, email=example3@example.com
エラー: User ID cannot be nil
エラー: User email cannot be nil
成功: id=id9, email=example9@example.com
エラー: User email cannot be nil
エラー: User ID cannot be nil
```

</v-click>

---

# 例外を使った場合の問題点

<v-clicks>

- **例外はフロー制御には不適切** - 正常なビジネスロジックの一部を例外で制御
- **パフォーマンスの問題** - 例外の生成・捕捉はコストが高い
- **コードの可読性** - try-catchのネストが深くなりがち
- **エラーの合成が困難** - 複数のエラーを扱いにくい
- **型安全性の欠如** - どの例外が発生するかコンパイル時に分からない

</v-clicks>

<v-click>

```ruby
# 複数のAPI呼び出しで例外が散らかる例
begin
  user = User.create(id: 1)
  profile = Profile.create(user_id: user.id)
  settings = Settings.create(user_id: user.id)
rescue MissingIdError => e
  # どの処理で失敗したか？
rescue MissingEmailError => e
  # profileやsettingsは作成された？
end
```

</v-click>

---

# この実装の問題点

<v-clicks>

- **エラーハンドリングの欠如** - APIがnilを返してもそのまま保存
- **データの整合性** - 不完全なデータ（nilを含む）が処理される
- **暗黙的な失敗** - エラーが発生しても正常終了したように見える
- **デバッグの困難性** - どこで失敗したか追跡しづらい
- **テストの複雑化** - 成功/失敗の両方のケースを考慮する必要

</v-clicks>

<br>

<v-click>

## よくある対処法の問題

```ruby
def fetch_data
  ans1 = call_api
  return nil unless ans1  # 早期リターンの連鎖
  
  ans2 = call_api
  return nil unless ans2
  
  @data = [ans1, ans2]
end
```

→ ネストが深くなり、エラーの詳細が失われる

</v-click>

---

# dry-monads - エラーハンドリング

Maybe、Result、Try モナドでエラーを安全に処理

```ruby {all|1-3|5-11|13-18|all}
require 'dry-monads'

class UserService
  include Dry::Monads[:result, :maybe]

  def find_user(id)
    user = User.find_by(id: id)
    return Failure(:user_not_found) unless user
    return Failure(:user_inactive) unless user.active?
    Success(user)
  end

  def get_user_email(id)
    find_user(id).bind do |user|
      Success(user.email)
    end
  end
end
```

<v-click>

```ruby
result = UserService.new.get_user_email(123)
result.success? # => true/false
result.value!   # => user email or raises exception
```

</v-click>

---

# dry-monads - yield記法

Do記法を使うとより直感的に書ける

```ruby {all|1-3|5-11|13-19|all}
require 'dry-monads'
require 'dry/monads/do'

class UserService
  include Dry::Monads[:result]
  include Dry::Monads::Do.for(:process_user)

  def find_user(id)
    user = User.find_by(id: id)
    return Failure(:user_not_found) unless user
    return Failure(:user_inactive) unless user.active?
    Success(user)
  end

  def process_user(id)
    user = yield find_user(id)           # 失敗したら自動的にFailureを返す
    profile = yield fetch_profile(user)   # こちらも同様
    settings = yield load_settings(user)  # 連続したyieldが可能
    
    Success({ user: user, profile: profile, settings: settings })
  end
end
```

<v-click>

### 通常の書き方との比較

```ruby
# yieldなし
find_user(id).bind do |user|
  fetch_profile(user).bind do |profile|
    load_settings(user).bind do |settings|
      Success({ user: user, profile: profile, settings: settings })
    end
  end
end
```

</v-click>

---

# dry-validation - データバリデーション

スキーマベースの堅牢なバリデーション

```ruby {all|1-2|4-12|14-20|all}
require 'dry-validation'

class UserContract < Dry::Validation::Contract
  params do
    required(:name).filled(:string)
    required(:email).filled(:string)
    required(:age).filled(:integer)
  end

  rule(:email) do
    unless /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i.match?(value)
      key.failure('must be a valid email')
    end
  end

  rule(:age) do
    key.failure('must be 18 or older') if value < 18
  end
end
```

<v-click>

```ruby
contract = UserContract.new
result = contract.call(name: "John", email: "john@example.com", age: 25)
result.success? # => true
result.errors   # => {}
```

</v-click>

---

# dry-types - 型システム

Rubyに型安全性を導入

```ruby {all|1-2|4-9|11-16|18-23|all}
require 'dry-types'

module Types
  include Dry::Types()
  
  Email = String.constrained(format: /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i)
  Age = Integer.constrained(gteq: 0, lteq: 150)
  Status = String.enum('active', 'inactive', 'pending')
end

class User < Dry::Struct
  attribute :name, Types::String
  attribute :email, Types::Email
  attribute :age, Types::Age
  attribute :status, Types::Status
end
```

```ruby {all}
user = User.new(
  name: "John",
  email: "john@example.com", 
  age: 25,
  status: "active"
)
```

---

# dry-container - 依存性注入

DIコンテナによる疎結合な設計

```ruby {all|1-2|4-8|10-17|19-24|all}
require 'dry-container'
require 'dry-auto_inject'

class Container
  extend Dry::Container::Mixin

  register 'user_repository', UserRepository.new
  register 'email_service', EmailService.new
end

AutoInject = Dry::AutoInject(Container)

class UserService
  include AutoInject['user_repository', 'email_service']

  def notify_user(user_id)
    user = user_repository.find(user_id)
    email_service.send_notification(user.email)
  end
end
```

<v-click>

```ruby
service = UserService.new
service.notify_user(123) # 依存性が自動注入される
```

</v-click>

---

# 実践例：ユーザー登録システム

dry-rbライブラリを組み合わせた実装例

```ruby {all|1-4|6-14|16-26|28-35|all}
class UserRegistration
  include Dry::Monads[:result]
  include AutoInject['user_repository', 'email_service']

  def call(params)
    validated = validate_params(params)
    return validated if validated.failure?

    user_data = validated.value!
    user = create_user(user_data)
    return user if user.failure?

    send_welcome_email(user.value!)
    user
  end

  private

  def validate_params(params)
    result = UserContract.new.call(params)
    return Failure(result.errors) unless result.success?
    Success(result.values)
  end

  def create_user(data)
    user = User.new(data)
    repository_result = user_repository.create(user)
    repository_result.success? ? Success(user) : Failure(:creation_failed)
  end

  def send_welcome_email(user)
    email_service.send_welcome(user.email)
    Success(:email_sent)
  rescue => e
    Failure(:email_failed)
  end
end
```

---

# dry-rbの利点

なぜdry-rbを使うのか？

<v-clicks>

- **エラーハンドリング** - モナドによる安全なエラー処理
- **型安全性** - ランタイムエラーの削減
- **テスタビリティ** - DIによる依存関係の制御
- **保守性** - 関数型プログラミングによる予測可能性
- **堅牢性** - バリデーションによるデータ整合性保証

</v-clicks>

<br>

<v-click>

## 従来のRubyコードと比較

```ruby
# 従来の書き方
def process_user(params)
  raise ArgumentError, "Name is required" unless params[:name]
  user = User.create(params)
  EmailService.new.send_welcome(user.email) if user.persisted?
  user
rescue => e
  Rails.logger.error("User processing failed: #{e.message}")
  nil
end
```

</v-click>

---

# 学習リソース

dry-rbを学ぶための情報源

<div class="grid grid-cols-1 gap-4">

## 公式サイト
- **dry-rb.org** - 公式ドキュメント
- **GitHub** - github.com/dry-rb

## 学習順序の推奨
1. **dry-monads** - 関数型の基礎概念
2. **dry-types** - 型システムの理解  
3. **dry-validation** - データ検証
4. **dry-container** - 依存性注入
5. その他のライブラリ

## コミュニティ
- **Gitter Chat** - リアルタイムサポート
- **Stack Overflow** - 問題解決
- **Discourse** - 議論フォーラム

</div>

---
layout: center
class: text-center
---

# ありがとうございました

dry-rbで関数型プログラミングを始めましょう！

[公式サイト](https://dry-rb.org) · [GitHub](https://github.com/dry-rb) · [ドキュメント](https://dry-rb.org/gems/)
