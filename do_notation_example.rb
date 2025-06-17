require 'dry/monads'
require 'dry/monads/do'
require 'debug'

class UserService
  include Dry::Monads[:result, :maybe]
  include Dry::Monads::Do.for(:create_user)

  def create_user(params)
    debugger
    name = yield validate_name(params[:name])
    email = yield validate_email(params[:email])
    user = yield save_user(name, email)

    Success(user)
  end

  private

  def validate_name(name)
    if name.nil? || name.empty?
      Failure(:invalid_name)
    else
      Success(name.strip)
    end
  end

  def validate_email(email)
    if email.nil? || !email.match?(/\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i)
      Failure(:invalid_email)
    else
      Success(email.downcase)
    end
  end

  def save_user(name, email)
    # Simulate database save
    if email == "existing@example.com"
      Failure(:email_already_exists)
    else
      Success({ id: 1, name: name, email: email })
    end
  end
end

# Usage example
service = UserService.new

# Success case
result = service.create_user(name: "John Doe", email: "john@example.com")
puts "Success: #{result.value!.inspect}"

# Failure cases
result = service.create_user(name: "", email: "john@example.com")
puts "Failure (empty name): #{result.failure}"

result = service.create_user(name: "John", email: "invalid-email")
puts "Failure (invalid email): #{result.failure}"

result = service.create_user(name: "Jane", email: "existing@example.com")
puts "Failure (existing email): #{result.failure}"