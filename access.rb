$LOAD_PATH.unshift("./ext")

require 'net/http'
require 'zlib'
require 'json'
require 'pp'
require 'date'
require 'pad_random'

def debug(hash, *keys)
  pp hash.select { |k, _| keys.include?(k) }
end

def random_sleep
  sleep(rand() % 10 + 5)
end

class Dungeon
  attr_reader :id, :floor, :hash, :requested_at, :started_at

  def initialize(id, floor, hash, requested_at)
    @id           = id
    @floor        = floor
    @hash         = hash
    @requested_at = requested_at
    @started_at   = nil
  end

  def start(time)
    if @started_at
      raise "This dungeon is already acknowledged."
    end
    @started_at = time
  end
end

class PadClient
  COMMON_HEADER = {"User-Agent"=>"GunghoPuzzleAndDungeon",
                   "Accept-Charset"=>"utf-8",
                   "Accept-Encoding"=>"gzip",
                   "Connection"=>"close"}

  def initialize
    @pid = nil
    @sid = nil
    @current_dungeon = nil
  end

  def keygen(request)
    "%08X" % PadRandom.generate_key(request)
  end

  def request(param_string)
    key = keygen(param_string).strip
    path = "/api.php?#{param_string}&key=#{key}"
    p path

    response = Net::HTTP.start("api-pad.gungho.jp") do |http|
      http.get(path, COMMON_HEADER)
    end

    body = Zlib::GzipReader.wrap(StringIO.new(response.body)) do |gz|
      JSON.parse(gz.read)
    end
  end

  def generate_tmd
    PadRandom.rnd_lc_get(0) & 0xffdf
  end

  # YYMMDDhhmmssmmm
  def datetime_to_pad(time)
    "%02d%02d%02d%02d%02d%02d%03d" % \
        [time.year % 100, time.month, time.day, time.hour, time.min, time.sec, (time.sec_fraction * 1000).to_i]
  end

  def pad_to_datetime(string)
    parts = (0..5).map do |i|
      string[i * 2..i * 2 + 1].to_i
    end
    DateTime.new(parts[0] + 2000, parts[1], parts[2], parts[3], parts[4], parts[5])
  end

  def login
    puts "login"
    response = request("action=login&t=0&v=4.41&u=8D603A32-3FA1-4754-A6D8-03A56D57D62C&dev=iPod4,1&osv=5.1")

    validate_response(response) do
      debug(response, 'id', 'sid')
      @pid = response["id"]
      @sid = response["sid"]
    end

    response
  end

  def get_player_data
    assert_login

    puts "get_player_data"
    response = request("action=get_player_data&pid=#{@pid}&sid=#{@sid}")

    validate_response(response) do
      debug(response, 'name', 'lv', 'exp')
    end

    response
  end

  def get_user_mail
    assert_login

    puts "get_user_mail"
    response = request("action=get_user_mails&pid=#{@pid}&sid=#{@sid}&ofs=0&cnt=256")

    validate_response(response) do
      pp response['mails'].map { |x| x["id"] }
    end

    response
  end

  def get_recommended_helpers
    assert_login

    puts "get_recommended_helpers"
    response = request("action=get_recommended_helpers&pid=#{@pid}&sid=#{@sid}")

    validate_response(response) do
      response['helpers'].each do |helper|
        puts "#{helper['pid']}: #{helper['name']}"
      end
    end

    response
  end

  def sneak_dungeon(dungeon, floor, helper_id)
    assert_login

    puts "sneak_dungeon"
    requested_at = DateTime.now
    time = datetime_to_pad(requested_at)
    response = request("action=sneak_dungeon&pid=#{@pid}&sid=#{@sid}&dung=#{dungeon}&floor=#{floor}&time=#{time}&helper=#{helper_id}")

    validate_response(response) do
      debug(response, 'hash', 'fp')
      @current_dungeon = Dungeon.new(dungeon, floor, response['hash'], requested_at)
    end

    response
  end

  def sneak_dungeon_ack
    assert_login
    assert_dungeon

    puts "sneak_dungeon_ack"
    time = datetime_to_pad(@current_dungeon.requested_at)
    response = request("action=sneak_dungeon_ack&pid=#{@pid}&sid=#{@sid}&hash=#{@current_dungeon.hash}&time=#{time}")

    validate_response(response) do
      debug(response, 'sta', 'sta_time')
      @current_dungeon.start(pad_to_datetime(response['sta_time']))
    end

    response
  end

  def clear_dungeon
    assert_login
    assert_dungeon

    puts "clear_dungeon"
    response = request("action=clear_dungeon&pid=#{@pid}&sid=#{@sid}&hash=#{@current_dungeon.hash}&tmd=#{generate_tmd}&dung=#{@current_dungeon.id}&floor=#{@current_dungeon.floor}")

    validate_response(response) do
      debug(response, 'lup', 'expgain', 'coingain', 'goldgain')
      @current_dungeon = nil
    end

    response
  end

  private
  def assert_login
    unless @pid && @sid
      raise "Not logged in"
    end
  end

  def assert_dungeon
    unless @current_dungeon
      raise "Not in dungeon"
    end
  end

  def validate_response(response)
    if response['res'] == 0
      yield
    else
      pp response
      raise "Validation failed"
    end
  end
end

client = PadClient.new

client.login
client.get_player_data
client.get_user_mail
random_sleep
helpers = client.get_recommended_helpers
random_sleep
# first dungeon
client.sneak_dungeon(10, 1, helpers['helpers'][0]['pid'])
random_sleep
client.sneak_dungeon_ack
client.clear_dungeon
