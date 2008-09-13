module Rack
  class Request
    def request_method
      @env['REQUEST_METHOD'] = params['_method'].upcase if request_method_in_params?
      @env['REQUEST_METHOD']
    end

    private
    def request_method_in_params?
      @env["REQUEST_METHOD"] == "POST" && %w(PUT DELETE).include?(params['_method'].upcase)
    end
  end
end

class Router

  URI_CHAR = '[^/?:,&#\.]'.freeze unless defined?(URI_CHAR)
  PARAM = /(:(#{URI_CHAR}+))/.freeze unless defined?(PARAM)

  attr_accessor :routes

  def initialize
    @routes = []
  end

  # Matches a GET request
  def get(matcher, &handler)
    register(:get, matcher, &handler)
  end

  # Matches a POST (create) request
  def post(matcher, &handler)
    register(:post, matcher, &handler)
  end

  # Matches a PUT (update) request
  def put(matcher, &handler)
    register(:put, matcher, &handler)
  end

  def delete(matcher, &handler)
    register(:delete, matcher, &handler)
  end

  def register(request_method, matcher, &handler)
    @routes << [request_method.to_s.upcase, transform(matcher), handler]
  end

  def match(request)
    @routes.each do |request_method, matcher, handler|
      next unless request.request_method == request_method
      next unless matcher.call(request)
      break handler
    end
  end

  private

  def transform(matcher)
    case matcher
    when Proc then matcher
    when Regexp then lambda { |request| request.path_info =~ matcher }
    when String
      param_keys = []
      regex = matcher.gsub(PARAM) { param_keys << $2; "(#{URI_CHAR}+)" }
      regex = /#{regex}/
      lambda do |request|
        if request.path_info =~ regex
          request.params.update(Hash[param_keys.zip($~.captures)])
        end
      end
    end
  end

end