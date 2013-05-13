# encoding: utf-8

module Cql
  module Protocol
    class OptionsRequest < RequestBody
      def initialize
        super(5)
      end

      def write(io)
        io
      end

      def to_s
        %(OPTIONS)
      end
    end
  end
end
