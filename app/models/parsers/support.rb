module Parsers
  class Support
    def self.download_via_post(url, data, name = nil, options = {})
      parsed = URI.parse(url)
      http = Net::HTTP.new(parsed.host, parsed.port)
      if url =~ %r{^https://}
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
      result = http.start do |http|
        post = Net::HTTP::Post.new(parsed.path)
        post.set_form_data(data)
        http.request(post)
      end
      result.error! unless result.is_a? Net::HTTPOK
      html = result.body
      save(name, html, options) if name
      html
    end

    def self.save(name, html, options = {})
      filename = get_path(name, options)
      FileUtils.mkdir_p(File.dirname(filename))
      f = File.open(filename, "wb")
      begin
        f.write html
      ensure
        f.close
      end
    end

    def self.get_path(path, options = {})
      defaults = {
        :bucketize => true
      }
      options = defaults.merge(options)

      if options[:bucketize]
        path_chunks = path.split('/')
        output = []
        path_chunks.each do |chunk|
          numbers = chunk.scan(/[0-9]{3,}/).collect do |part|
            part.to_i / 1000 * 1000
          end
          output += numbers if numbers.any?
          output << chunk
        end
        "#{Rails.root}/data/#{Rails.env}/#{output.join('/')}"
      else
        "#{Rails.root}/data/#{Rails.env}/#{path}"
      end
    end
  end
end
