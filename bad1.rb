require 'dry/monads'

# dry-monadの紹介用のコード
# まず、dry-monadを使用しないで外部API連携で失敗したときの処理が冗長になっているbad patternを出して
class ApiClient
  def fetch_data
    ans1 = call_api
    ans2 = call_api
    @data = [ans1, ans2]
  end

  def save_to_db
    fetch_data

    puts "APIから取得したデータ: #{@data.inspect} を保存しました"
  end

  private
  def call_api
    # 1/2の確率で文字列"value"を、それ以外はnilを返す
    return "value" if rand < 0.5
  end
end

10.times do 
  foo = ApiClient.new
  foo.fetch_data
  foo.save_to_db
end
