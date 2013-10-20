require 'pp'

class WeakMonsterFilter < BaseFilter
  def initialize()
    super([],
          ['sneak_dungeon'])
  end

  def callback(req, res)
    content = decode_body(res)
    count = 0
    content['waves'].each do |wave|
      wave['monsters'].each do |mon|
        mon['type'] = '0'
        mon['num']  = '50'
        mon['lv']   = '2'
      end
    end

    body = content.to_json
    if res['Content-Encoding'] == 'gzip'
      out = StringIO.new
      gz = Zlib::GzipWriter.new(out)
      gz.write(body)
      gz.close
      body = out.string
    end

    res.body = body
  end
end
