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

# 主要なdry-rbライブラリ

最も使用頻度の高いライブラリたち

<div class="grid grid-cols-2 gap-4">

<div>

## Core Libraries
- **dry-configurable** - 設定管理
- **dry-container** - 依存性注入
- **dry-auto_inject** - 自動依存性注入
- **dry-initializer** - オブジェクト初期化

</div>

<div>

## Data Handling
- **dry-validation** - データバリデーション
- **dry-schema** - スキーマ定義
- **dry-types** - 型システム
- **dry-struct** - 不変構造体

</div>

</div>

<div class="mt-4">

## Functional Programming
- **dry-monads** - モナドパターン
- **dry-matcher** - パターンマッチング

</div>

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
