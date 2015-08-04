module ContentTypeHelper
  class ContentType
    def initialize(header_type)
      @type = header_type.gsub(/;.+/, '')
    end

    def html?
      @type == 'text/html'
    end

    def csv?
      @type == 'text/csv'
    end

    def xml?
      @type == 'application/xml'
    end
  end

  # content_type.should be_csv
  def content_type
    ContentType.new(response_headers["Content-Type"])
  end
end

RSpec.configure do |config|
  config.include ContentTypeHelper
end
