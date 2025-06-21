class User
  attr_reader :id, :email

  def initialize(id:, email:)
    @id = id
    @email = email
  end

  def self.find_by(id:)
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
      user
    else
      nil
    end
  end
end

# 動作確認
10.times do
  status, user = User.find_by(id: rand(1..10))

  case status
  when :ok
    puts "成功: id=#{user.id}, email=#{user.email}"
  when :error
    puts "失敗: id=#{user.id.inspect}, email=#{user.email.inspect}"
  end
end