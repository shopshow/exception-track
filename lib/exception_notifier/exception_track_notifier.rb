# 异常通知
module ExceptionNotifier
  class ExceptionTrackNotifier
    def initialize(_options)
    end

    def call(exception, _options = {})
      data = _options[:data]
      data ||= _options[:env]["exception_notifier.exception_data"] rescue nil
      messages = []
      @title = exception.message

      messages << exception.inspect
      messages << "\n"
      messages << "--------------------------------------------------"
      messages << headers_for_env(_options)
      messages << "--------------------------------------------------"

      unless exception.backtrace.blank?
        messages << "\n"
        messages << exception.backtrace
      end

      if data
        messages << "\nData: --------------------------------------------------"
        messages << data.inspect
      end

      if ExceptionTrack.config.enabled_env?(Rails.env)
        Rails.logger.silence do
          ExceptionTrack::Log.create(title: @title, body: messages.join("\n"))
        end
      end
    end

    # Log Request headers from Rack env
    def headers_for_env(options)
      headers = []
      headers << "Timestamp:          #{Time.current}"

      if env = options[:env]
        request = ActionDispatch::Request.new(env)
        headers << "URL:                #{request.original_url}"
        headers << "HTTP Method:        #{request.method}"
        headers << "IP Address:         #{request.remote_ip}"
        headers << "User-Agent:         #{request.user_agent}"
        headers << "Parameters:         #{request.filtered_parameters}"
      end

      headers << "Server:             #{Socket.gethostname}"
      headers << "Rails root:         #{Rails.root}"
      headers << "Process:            #{$$}"

      headers.join("\n")
    end
  end
end
