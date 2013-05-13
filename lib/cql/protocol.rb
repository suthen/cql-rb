# encoding: utf-8

module Cql
  ProtocolError = Class.new(CqlError)

  # @private
  module Protocol
    DecodingError = Class.new(ProtocolError)
    EncodingError = Class.new(ProtocolError)
    InvalidStreamIdError = Class.new(ProtocolError)
    InvalidValueError = Class.new(ProtocolError)
    UnsupportedOperationError = Class.new(ProtocolError)
    UnsupportedFrameTypeError = Class.new(ProtocolError)
    UnsupportedResultKindError = Class.new(ProtocolError)
    UnsupportedColumnTypeError = Class.new(ProtocolError)
    UnsupportedEventTypeError = Class.new(ProtocolError)

    CONSISTENCIES = [:any, :one, :two, :three, :quorum, :all, :local_quorum, :each_quorum].freeze

    module Formats
      CHAR_FORMAT = 'c'.freeze
      DOUBLE_FORMAT = 'G'.freeze
      FLOAT_FORMAT = 'g'.freeze
      INT_FORMAT = 'N'.freeze
      SHORT_FORMAT = 'n'.freeze

      BYTES_FORMAT = 'C*'.freeze
      TWO_INTS_FORMAT = 'NN'.freeze
      HEADER_FORMAT = 'c4'.freeze
    end

    module Constants
      TRUE_BYTE = "\x01".freeze
      FALSE_BYTE = "\x00".freeze
    end
  end
end

require 'cql/protocol/encoding'
require 'cql/protocol/decoding'
require 'cql/protocol/type_converter'
require 'cql/protocol/response_body'
require 'cql/protocol/responses/error_response'
require 'cql/protocol/responses/detailed_error_response'
require 'cql/protocol/responses/ready_response'
require 'cql/protocol/responses/authenticate_response'
require 'cql/protocol/responses/supported_response'
require 'cql/protocol/responses/result_response'
require 'cql/protocol/responses/void_result_response'
require 'cql/protocol/responses/rows_result_response'
require 'cql/protocol/responses/set_keyspace_result_response'
require 'cql/protocol/responses/prepared_result_response'
require 'cql/protocol/responses/schema_change_result_response'
require 'cql/protocol/responses/event_response'
require 'cql/protocol/responses/schema_change_event_result_response'
require 'cql/protocol/responses/status_change_event_result_response'
require 'cql/protocol/responses/topology_change_event_result_response'
require 'cql/protocol/request_body'
require 'cql/protocol/requests/startup_request'
require 'cql/protocol/requests/credentials_request'
require 'cql/protocol/requests/options_request'
require 'cql/protocol/requests/register_request'
require 'cql/protocol/requests/query_request'
require 'cql/protocol/requests/prepare_request'
require 'cql/protocol/requests/execute_request'
require 'cql/protocol/response_frame'
require 'cql/protocol/request_frame'
