# encoding: utf-8

##
# This file is auto-generated. DO NOT EDIT!
#
require 'protobuf/message'

module Code
  module Justin
    module Tv
      module Release
        module Trace
          module Pbmsg

            ##
            # Message Classes
            #
            class Event < ::Protobuf::Message
              class Kind < ::Protobuf::Enum
                define :REQUEST_HEAD_RECEIVED, 20
                define :REQUEST_BODY_RECEIVED, 21
                define :RESPONSE_HEAD_PREPARED, 30
                define :RESPONSE_BODY_SENT, 31
                define :REQUEST_HEAD_PREPARED, 40
                define :REQUEST_BODY_SENT, 41
                define :RESPONSE_HEAD_RECEIVED, 50
                define :RESPONSE_BODY_RECEIVED, 51
              end

            end

            class Extra < ::Protobuf::Message; end
            class ExtraHTTP < ::Protobuf::Message
              class Method < ::Protobuf::Enum
                define :UNKNOWN, 0
                define :GET, 1
                define :HEAD, 2
                define :POST, 3
                define :PUT, 4
                define :DELETE, 5
                define :CONNECT, 6
                define :OPTIONS, 7
                define :TRACE, 8
                define :PATCH, 9
              end

            end

            class ExtraSQL < ::Protobuf::Message; end
            class ExtraMemcached < ::Protobuf::Message
              class MemcachedCommand < ::Protobuf::Enum
                define :UNKNOWN_COMMAND, 0
                define :SET, 1
                define :ADD, 2
                define :REPLACE, 3
                define :APPEND, 4
                define :PREPEND, 5
                define :CAS, 6
                define :GET, 7
                define :GETS, 8
                define :DELETE, 9
                define :INCR, 10
                define :DECR, 11
              end

            end

            class UnusedExtra < ::Protobuf::Message
              class KV < ::Protobuf::Message; end

            end

            class EventSet < ::Protobuf::Message; end


            ##
            # Message Fields
            #
            class Event
              optional ::Code::Justin::Tv::Release::Trace::Pbmsg::Event::Kind, :kind, 1
              optional :sfixed64, :time, 2
              optional :string, :hostname, 3
              optional :string, :svcname, 4
              optional :int32, :pid, 5
              repeated :fixed64, :transaction_id, 6, :packed => true
              repeated :uint32, :path, 7, :packed => true
              optional ::Code::Justin::Tv::Release::Trace::Pbmsg::Extra, :extra, 8
            end

            class Extra
              optional :string, :peer, 1
              optional ::Code::Justin::Tv::Release::Trace::Pbmsg::ExtraHTTP, :http, 2
              optional ::Code::Justin::Tv::Release::Trace::Pbmsg::ExtraSQL, :sql, 3
              optional ::Code::Justin::Tv::Release::Trace::Pbmsg::ExtraMemcached, :memcached, 4
            end

            class ExtraHTTP
              optional :sint32, :status_code, 1
              optional ::Code::Justin::Tv::Release::Trace::Pbmsg::ExtraHTTP::Method, :method, 2
              optional :string, :uri_path, 16
            end

            class ExtraSQL
              optional :string, :database_name, 1
              optional :string, :database_user, 2
              optional :string, :stripped_query, 16
            end

            class ExtraMemcached
              optional ::Code::Justin::Tv::Release::Trace::Pbmsg::ExtraMemcached::MemcachedCommand, :command, 1
              optional :uint32, :n_keys, 2
              optional :fixed32, :expiration, 3
            end

            class UnusedExtra
              class KV
                optional :string, :key, 1
                optional :string, :value, 2
              end

              optional :string, :text, 20
              optional :bool, :text_truncated, 1020
              optional :int64, :payload_size, 21
              optional :string, :http_uri, 41
              optional :bool, :http_uri_truncated, 1041
              repeated ::Code::Justin::Tv::Release::Trace::Pbmsg::UnusedExtra::KV, :http_header, 43
              optional :string, :http_referer, 44
              optional :bool, :http_referer_truncated, 1044
            end

            class EventSet
              repeated ::Code::Justin::Tv::Release::Trace::Pbmsg::Event, :event, 1
            end

          end

        end

      end

    end

  end

end

