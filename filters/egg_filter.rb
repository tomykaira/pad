require 'pp'

class EggFilter < BaseFilter
  def initialize(monsters, count)
    super([],
          ['sneak_dungeon'])

    @monsters, @count = monsters.map(&:to_s), count.to_i
  end

  def callback(req, res)
    content = decode_body(res)
    pp content
    count = 0
    content['waves'].each do |wave|
      wave['monsters'].each do |mon|
        if @monsters.include?(mon['item'])
          count += 1
        end
      end
    end
    raise "not enough egg" if count < @count
  end
end
