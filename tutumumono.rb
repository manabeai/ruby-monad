require 'dry/monads'

class User
   attr_reader :id, :email
  def initialize(id:, email:)
    @id = id
    @email = email
  end

  def self.create(id:)
    r = rand
    user =
      if r < 0.25
        new(id: "id#{id}", email: "example#{id}@example.com")
      elsif r < 0.5
        new(id: "id#{id}", email: nil)
      elsif r < 0.75
        new(id: nil, email: "example#{id}@example.com")
      else
        new(id: nil, email: nil)
      end

    if user.id.nil? || user.email.nil?
      nil
    else
      user
    end
  end

  def save_to_db
    if id.nil? || email.nil?
      puts "保存に失敗しました: id=#{id.inspect}, email=#{email.inspect}"
    else
      puts "保存に成功しました: id=#{id}, email=#{email}"
    end
  end
end

# 10.times do
#   user = User.create(id: rand(1..10)) # 失敗したらnilが返る
#   user.save_to_db 
#   puts user.inspect
# end

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
    user =
      if r < 0.25
        new(id: "id#{id}", email: "example#{id}@example.com")
      elsif r < 0.5
        new(id: "id#{id}", email: nil)
      elsif r < 0.75
        new(id: nil, email: "example#{id}@example.com")
      else
        new(id: nil, email: nil)
      end

    user.id.nil? || user.email.nil? ? Failure(user) : Success(user)
  end
end

10.times do
  user = MUser.create(id: rand(1..10))
  puts user.inspect
end