require 'json'

class SaveDataFilter < BaseFilter
  def initialize
    super([],
          :any)
  end

  def callback(req, res)
    File.open("api_log/#{Time.now.to_i}_#{req.query['action']}", 'w') do |f|
      f.write(JSON.pretty_generate({ query: req.query, response: decode_body(res) }))
    end
  end
end
