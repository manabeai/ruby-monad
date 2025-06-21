require 'dry/monads'
class UserService
  include Dry::Monads[:result, :maybe]

  def find_user(id)
    User.find_by(id: id)
  end

  # idとemailが両方nilじゃなければdbに保存
  def save_user(user)
    
    user.bind do |u|
      puts "User found: id=#{u.id}, email=#{u.email}. Saved to database."
    end
  end
end

# Userのmock
require 'dry/monads'

class User
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

    if user.id.nil? || user.email.nil?
      Failure(user)
    else
      Success(user)
    end
  end
end

10.times do
  puts User.create_user(id: rand(1..10)).inspect
end

10.times do
  service = UserService.new
  result = service.create_user(rand(1..10))
  puts result = service.save_user(result)
end