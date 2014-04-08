require 'json'
require 'securerandom'
require '../stream/stream_base'

module ThinConnector
  module Stream

    class MockStream < ThinConnector::Stream::Base

      SECONDS_REST_BETWEEN_PAYLOADS = 1
      DEFAULT_MAX_TIMEOUT_IN_SECONDS = 60*5

      @logger

      # Passes json strings to &block
      def start(&block)
        begin

          while stream_is_open?
            yield json_data.to_json
            sleep SECONDS_REST_BETWEEN_PAYLOADS if SECONDS_REST_BETWEEN_PAYLOADS
          end

        rescue => e
          @logger.info "Rescuing from error #{e}:#{e.message}"
          retry_count ||= 0
          retry_count += 1

          if should_try_reconnect retry_count
            sleep seconds_between_reconnect(retry_count)
            @logger.info "Retrying to connect stream for #{retry_count} time"
            retry
          else
            @logger.error "Not retrying to connect stream, probably timed out"
          end
        end
      end

      def stop
        @stop_stream = true
      end

      private

      def stream_running?

      end

      def reconnect

      end

      def random_string; SecureRandom.hex 32; end

      def json_data
        {
            timestamp: Time.now.utc.to_f,
            payload: random_string
        }
      end

      # Unassigned @stop_stream assumed to mean stream should be open
      def stream_is_open?
        @stop_stream.nil? || !@stop_stream
      end

      def seconds_between_reconnect(attempt_number)
        (attempt_number**2) * 10
      end

      def max_timeout
        ThinConnector::Environment.instance.stream_timeout || DEFAULT_MAX_TIMEOUT_IN_SECONDS
      end

      def should_try_reconnect?(attempt_number)
        raise 'Cannot retry negative times' if attempt_number < 0
        seconds_between_reconnect(attempt_number) < max_timeout
      end

    end

  end
end