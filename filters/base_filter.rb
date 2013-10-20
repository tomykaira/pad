class BaseFilter
  attr_accessor :filter_on, :callback_on

  def initialize(filter_on, callback_on)
    @filter_on, @callback_on = filter_on.freeze, callback_on.freeze
  end

  def filter(req)
    raise NotImplemented
  end

  def callback(req)
    raise NotImplemented
  end

  def decode_body(res)
    if res['Content-Encoding'] == 'gzip'
      Zlib::GzipReader.wrap(StringIO.new(res.body)) do |gz|
        JSON.parse(gz.read)
      end
    else
      JSON.parse(res.body)
    end
  end
end
