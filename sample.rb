require 'dry-monads'
include Dry::Monads[:result]

# カスタムエラークラス
class MissingIdError < StandardError; end
class MissingEmailError < StandardError; end

# === 1. つらいコード（nilを返すパターン） ===
class TraditionalUser
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
      elsif rand < 0.75
        new(id: nil, email: "example#{id}@example.com")
      else
        new(id: nil, email: nil)
      end

    # どっちもnilじゃなければインスタンスを返す
    user.id.nil? || user.email.nil? ? nil : user
  end
  
  def save_to_db
    puts "保存しました: #{id}, #{email}"
  end
end

# === 2. エラーにするパターン（例外を投げる） ===
class ExceptionUser
  attr_reader :id, :email
  
  def initialize(id:, email:)
    @id = id
    @email = email
  end
  
  def self.create(id:)
    user =
      if rand < 0.25
        new(id: "id#{id}", email: "example#{id}@example.com")
      elsif rand < 0.5
        new(id: "id#{id}", email: nil)
      elsif rand < 0.75
        new(id: nil, email: "example#{id}@example.com")
      else
        new(id: nil, email: nil)
      end

    raise MissingIdError, "User ID cannot be nil" if user.id.nil?
    raise MissingEmailError, "User email cannot be nil" if user.email.nil?
    
    user
  end
  
  def save_to_db
    puts "保存しました: #{id}, #{email}"
  end
end

# === 3. タプル風で返すパターン ===
class TupleUser
  attr_reader :id, :email
  
  def initialize(id:, email:)
    @id = id
    @email = email
  end
  
  def self.create(id:)
    user =
      if rand < 0.25
        new(id: "id#{id}", email: "example#{id}@example.com")
      elsif rand < 0.5
        new(id: "id#{id}", email: nil)
      elsif rand < 0.75
        new(id: nil, email: "example#{id}@example.com")
      else
        new(id: nil, email: nil)
      end
    
    return [:error, :missing_id] if user.id.nil?
    return [:error, :missing_email] if user.email.nil?
    
    [:ok, user]
  end
  
  def save_to_db
    puts "保存しました: #{id}, #{email}"
  end
end

# === 4. Dry-monadsを使ったパターン ===
class User
  include Dry::Monads[:result]
  extend Dry::Monads[:result]
  attr_reader :id, :email

  def initialize(id:, email:)
    @id = id
    @email = email
  end

  def self.create(id:)
    user =
      if rand < 0.25
        new(id: "id#{id}", email: "example#{id}@example.com")
      elsif rand < 0.5
        new(id: "id#{id}", email: nil)
      elsif rand < 0.75
        new(id: nil, email: "example#{id}@example.com")
      else
        new(id: nil, email: nil)
      end

    user.id.nil? || user.email.nil? ? Failure(user) : Success(user)
  end
  
  def save_to_db
    puts "保存しました: #{id}, #{email}"
  end
end

# モック: TemporaryUser
class TemporaryUser
  attr_reader :email
  
  def initialize(email:)
    @email = email
  end
  
  def save_to_db
    puts "仮ユーザーとして保存しました: #{email}"
  end
end

# === デモ実行 ===

puts "=== 1. つらいコード（nilを返すパターン） ==="
5.times do
  user = TraditionalUser.create(id: rand(1..10))
  if user.nil?
    puts "ユーザーの作成に失敗しました"
  else
    user.save_to_db
  end
end

puts "\n=== 2. エラーにするパターン（例外を投げる） ==="
5.times do
  begin
    user = ExceptionUser.create(id: rand(1..10))
    puts "成功: id=#{user.id}, email=#{user.email}"
  rescue MissingIdError => e
    puts "エラー: #{e.message}"
  rescue MissingEmailError => e
    puts "エラー: #{e.message}"
  end
end

puts "\n=== 3. タプル風で返すパターン ==="
5.times do
  status, result = TupleUser.create(id: rand(1..10))
  case status
  when :ok
    result.save_to_db
  when :error
    puts "エラー: #{result}"
  end
end

puts "\n=== 4. Dry-monadsを使ったパターン ==="
puts "--- 実行結果の確認 ---"
10.times do
  result = User.create(id: rand(1..10))
  puts result.inspect
end

puts "\n--- bind/orパターン ---"
3.times do
  result = User.create(id: rand(1..10))
  
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
end

puts "\n--- fmapを使った短縮形 ---"
3.times do
  result = User.create(id: rand(1..10))
  result.fmap(&:save_to_db)
        .or { |u| puts "失敗: #{u.inspect}" }
end

puts "\n--- case文を使う方法 ---"
3.times do
  result = User.create(id: rand(1..10))
  case result
  when Success
    result.value!.save_to_db
  when Failure
    puts "失敗: #{result.failure.inspect}"
  end
end

puts "\n--- value_orで仮ユーザーを作る ---"
3.times do
  result = User.create(id: rand(1..10))
  user = result.value_or do |user|
    TemporaryUser.new(email: "仮@example.com")
  end
  user.save_to_db
end