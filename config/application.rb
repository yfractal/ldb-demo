require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

class LDBMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    @stop = false
    @traces = {}

    @buffer = StackFrames::Buffer.new(50)
    @thread = Thread.current

    @buffer.set_trace_id_and_generation(rand(10000))

    Thread.new do
      inteval = 0.0005

      puts "probe every #{inteval * 1009} ms."

      while !@stop
        frames_count = @buffer.caputre_frames(@thread)
        frame = []
        trace_id = @buffer[0].f_trace_id
        @traces[trace_id] ||= []

        frames_count.times do |i|
          buffer = @buffer[i]
          frame << [i, buffer.f_method_name, buffer.f_generation]
        end

        @traces[trace_id] << frame

        sleep inteval
      end

      file = "traces-#{rand(10000)}"

      File.open(file, 'w') { |file| file.write(@traces.to_json) }
    end

    rv = @app.call(env)

    @stop = true

    rv
  end
end

module LdbDemo
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w(assets tasks))

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
    config.api_only = true
    config.middleware.insert_before 0, LDBMiddleware
  end
end

