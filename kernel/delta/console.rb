module Rubinius
  module Console
    class Server
      # The following constants are set internally:
      # RequestPath - the path to the console request file for this process
      # ResponsePath - the path to the console response file for this process

      attr_reader :inbox
      attr_reader :outbox
      attr_reader :thread

      def initialize
        @inbox = Channel.new
        @outbox = Channel.new

        @thread = Thread.new do
          source = @inbox.receive
          break unless source.size

          @outbox.send evaluate(source)
        end
      end

      def evaluate(source)
        begin
          eval(source, TOPLEVEL_BINDING, "(console)", 1).inspect
        rescue Object => e
          e.message + e.backtrace.join("\n")
        end
      end
    end
  end
end
