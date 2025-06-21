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

# dry-monadsとは？



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
````md magic-move {lines: true}
```ruby {*}
class User
  attr_reader :id, :email

  def initialize(id:, email:)
    @id = id
    @email = email
  end
  
  def self.create(id:)
    user = # 省略
    user.id.nil? || user.email.nil? ? nil : user
  end
end
```

```ruby {2-3|13}
class User
  include Dry::Monads[:result]
  extend Dry::Monads[:result]  
  attr_reader :id, :email

  def initialize(id:, email:)
    @id = id
    @email = email
  end
  
  def self.create(id:)
    user = # 省略
    user.id.nil? || user.email.nil? ? nil : user
  end
end
```

```ruby {13|*}
class User
  include Dry::Monads[:result]
  extend Dry::Monads[:result]  
  attr_reader :id, :email

  def initialize(id:, email:)
    @id = id
    @email = email
  end

  def self.create(id:)
    user = # 省略
    user.id.nil? || user.email.nil? ? Failure(user) : Success(user)
  end
end
```

Non-code blocks are ignored.

```vue
<!-- step 4 -->
<script setup>
const author = {
  name: 'John Doe',
  books: [
    'Vue 2 - Advanced Guide',
    'Vue 3 - Basic Guide',
    'Vue 4 - The Mystery'
  ]
}
</script>
```
````

---

# 実行してみると...
```ruby
10.times do
  User.create(id: rand(1..10)).inspect
end
```

```
Failure(#<User:0x000073d6070dce50 @id=nil, @email=nil>)
Failure(#<User:0x000073d6070dc928 @id=nil, @email="example3@example.com">)
Failure(#<User:0x000073d6070dc838 @id=nil, @email="example5@example.com">)
Failure(#<User:0x000073d6070dc748 @id=nil, @email="example9@example.com">)
Failure(#<User:0x000073d6070dc658 @id=nil, @email="example3@example.com">)
Failure(#<User:0x000073d6070dc540 @id=nil, @email="example10@example.com">)
Failure(#<User:0x000073d6070dc428 @id="id4", @email=nil>)
Failure(#<User:0x000073d6070dc2e8 @id=nil, @email="example10@example.com">)
Failure(#<User:0x000073d6070dc1d0 @id="id8", @email=nil>)
Success(#<User:0x000073d6070dc0b8 @id="id4", @email="example4@example.com">)
```

- 有効なオブジェクトなら`Success`で、無効なオブジェクトなら`Failure`で返す
- タプルのように補足情報のためにシンボルを使う必要がない
---

# モナドの値を取り出す

<div class="grid grid-cols-2 gap-2">

<div class="mr-2">

<!-- ## `either` と `or` の説明 -->

<v-clicks>

### `bind`
- **Success**の場合にブロックを実行
- 成功時の処理を記述
- チェーンで`or`に繋げられる
- 新しいResultを返す必要がある

### `or`
- **Failure**の場合にブロックを実行
- 失敗時の処理を記述
- `bind`の後に使用

### 使い方
- 成功/失敗で処理を分岐
- メソッドチェーンで記述可能
- ブロック内で値にアクセス

</v-clicks>

</div>

<div>

## サンプルコード

```ruby
result = User.create(id: 1)

# bind/orパターン
result.bind do |user|
  # Successの場合
  user.save_to_db
  puts "保存しました: #{user.id}, #{user.email}"
  Success(user)
end.or do |user|
  # Failureの場合
  puts "作成失敗: #{user.inspect}"
  Failure(user)
end
```

<v-click>

### 別の書き方

```ruby
# fmapを使った短縮形
result.fmap(&:save_to_db)
      .or { |u| puts "失敗: #{u.inspect}" }

# case文を使う方法
case result
when Success
  result.value!.save_to_db
when Failure
  puts "失敗: #{result.failure.inspect}"
end
```

</v-click>

</div>

</div>

---

# もっと縮めて
```ruby
result = User.create(id: 1)
result.fmap(&:save_to_db).or -> puts "作ろうと思ったけど作れませんでした : #{user.inspect}" 
```

---

# `value_or` で仮ユーザーを作る

- `Success` -> 中身を返す
- `Failure` -> ブロックを実行して値を返す

```ruby
result = User.create(id: 1)
user = result.value_or do |user|
  TemporaryUser.new(email: "仮@example.com")
end
user.save_to_db
```

---

# 感想とか
- **副作用と向き合う協力なツール**
- **ActiveRecordとかでめっちゃ使いたくなる**
- **AI開発ととても相性が良さそう**