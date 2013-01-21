# encoding: ascii-8bit

require 'spec_helper'


module Cql
  describe RequestFrame do
    context 'with OPTIONS requests' do
      it 'encodes an OPTIONS request' do
        bytes = RequestFrame.new(OptionsRequest.new).write('')
        bytes.should == "\x01\x00\x00\x05\x00\x00\x00\x00"
      end
    end

    context 'with STARTUP requests' do
      it 'encodes the request' do
        bytes = RequestFrame.new(StartupRequest.new('3.0.0', 'snappy')).write('')
        bytes.should == "\x01\x00\x00\x01\x00\x00\x00\x2b\x00\x02\x00\x0bCQL_VERSION\x00\x053.0.0\x00\x0bCOMPRESSION\x00\x06snappy"
      end

      it 'defaults to CQL 3.0.0 and no compression' do
        bytes = RequestFrame.new(StartupRequest.new).write('')
        bytes.should == "\x01\x00\x00\x01\x00\x00\x00\x16\x00\x01\x00\x0bCQL_VERSION\x00\x053.0.0"
      end
    end

    context 'with REGISTER requests' do
      it 'encodes the request' do
        bytes = RequestFrame.new(RegisterRequest.new('TOPOLOGY_CHANGE', 'STATUS_CHANGE')).write('')
        bytes.should == "\x01\x00\x00\x0b\x00\x00\x00\x22\x00\x02\x00\x0fTOPOLOGY_CHANGE\x00\x0dSTATUS_CHANGE"
      end
    end

    context 'with QUERY requests' do
      it 'encodes the request' do
        bytes = RequestFrame.new(QueryRequest.new('USE system', :all)).write('')
        bytes.should == "\x01\x00\x00\x07\x00\x00\x00\x10\x00\x00\x00\x0aUSE system\x00\x05"
      end
    end

    context 'with PREPARE requests' do
      it 'encodes the request' do
        bytes = RequestFrame.new(PrepareRequest.new('UPDATE users SET email = ? WHERE user_name = ?')).write('')
        bytes.should == "\x01\x00\x00\x09\x00\x00\x00\x32\x00\x00\x00\x2eUPDATE users SET email = ? WHERE user_name = ?"
      end
    end

    context 'with EXECUTE requests' do
      let :id do
        "\xCAH\x7F\x1Ez\x82\xD2<N\x8A\xF35Qq\xA5/"
      end

      let :column_metadata do
        [['ks', 'tbl', 'col1', :varchar], ['ks', 'tbl', 'col2', :int], ['ks', 'tbl', 'col3', :varchar]]
      end

      it 'encodes the request' do
        bytes = RequestFrame.new(ExecuteRequest.new(id, column_metadata, ['hello', 42, 'foo'], :each_quorum)).write('')
        bytes.should == "\x01\x00\x00\x0a\x00\x00\x00\x2e\x00\x10\xCAH\x7F\x1Ez\x82\xD2<N\x8A\xF35Qq\xA5/\x00\x03\x00\x00\x00\x05hello\x00\x00\x00\x04\x00\x00\x00\x2a\x00\x00\x00\x03foo\x00\x07"
      end

      specs = [
        [:ascii, 'test', "test"],
        [:bigint, 1012312312414123, "\x00\x03\x98\xB1S\xC8\x7F\xAB"],
        [:blob, "\xab\xcd", "\xab\xcd"],
        [:boolean, false, "\x00"],
        [:boolean, true, "\x01"],
        [:decimal, BigDecimal.new('1042342234234.123423435647768234'), "\x00\x00\x00\x12\r'\xFDI\xAD\x80f\x11g\xDCfV\xAA"],
        [:double, 10000.123123123, "@\xC3\x88\x0F\xC2\x7F\x9DU"],
        [:float, 12.13, "AB\x14{"],
        [:inet, IPAddr.new('8.8.8.8'), "\x08\x08\x08\x08"],
        [:inet, IPAddr.new('::1'), "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01"],
        [:int, 12348098, "\x00\xBCj\xC2"],
        [:text, 'FOOBAR', 'FOOBAR'],
        [:timestamp, Time.at(1358013521.123), "\x00\x00\x01</\xE9\xDC\xE3"],
        [:timeuuid, Uuid.new('a4a70900-24e1-11df-8924-001ff3591711'), "\xA4\xA7\t\x00$\xE1\x11\xDF\x89$\x00\x1F\xF3Y\x17\x11"],
        [:uuid, Uuid.new('cfd66ccc-d857-4e90-b1e5-df98a3d40cd6'), "\xCF\xD6l\xCC\xD8WN\x90\xB1\xE5\xDF\x98\xA3\xD4\f\xD6"],
        [:varchar, 'hello', 'hello'],
        [:varint, 1231312312331283012830129382342342412123, "\x03\x9EV \x15\f\x03\x9DK\x18\xCDI\\$?\a["],
        [:varint, -234234234234, "\xC9v\x8D:\x86"]
      ]
      specs.each do |type, value, expected_bytes|
        it "encodes #{type} values" do
          metadata = [['ks', 'tbl', 'id_column', type]]
          bytes = RequestFrame.new(ExecuteRequest.new(id, metadata, [value], :one)).write('')
          bytes.slice!(0, 8 + 2 + 16 + 2)
          length = bytes.slice!(0, 4).unpack('N').first
          result_bytes = bytes[0, length]
          result_bytes.should == expected_bytes
        end
      end

      it 'raises an error when the metadata and values don\'t have the same size' do
        expect { ExecuteRequest.new(id, column_metadata, ['hello', 42], :each_quorum) }.to raise_error(ArgumentError)
      end

      it 'raises an error for unsupported column types' do
        column_metadata[2][3] = :imaginary
        expect { RequestFrame.new(ExecuteRequest.new(id, column_metadata, ['hello', 42, 'foo'], :each_quorum)).write('') }.to raise_error(UnsupportedColumnTypeError)
      end
    end

    context 'with a stream ID' do
      it 'encodes the stream ID in the header' do
        bytes = RequestFrame.new(QueryRequest.new('USE system', :all), 42).write('')
        bytes[2].should == "\x2a"
      end

      it 'defaults to zero' do
        bytes = RequestFrame.new(QueryRequest.new('USE system', :all)).write('')
        bytes[2].should == "\x00"
      end

      it 'raises an exception if the stream ID is outside of 0..127' do
        expect { RequestFrame.new(QueryRequest.new('USE system', :all), -1) }.to raise_error(InvalidStreamIdError)
        expect { RequestFrame.new(QueryRequest.new('USE system', :all), 128) }.to raise_error(InvalidStreamIdError)
        expect { RequestFrame.new(QueryRequest.new('USE system', :all), 99999999) }.to raise_error(InvalidStreamIdError)
      end
    end

    describe 'StartupRequest#to_s' do
      it 'returns a pretty string' do
        request = StartupRequest.new
        request.to_s.should == 'STARTUP {"CQL_VERSION"=>"3.0.0"}'
      end
    end

    describe 'OptionsRequest#to_s' do
      it 'returns a pretty string' do
        request = OptionsRequest.new
        request.to_s.should == 'OPTIONS'
      end
    end

    describe 'RegisterRequest#to_s' do
      it 'returns a pretty string' do
        request = RegisterRequest.new('TOPOLOGY_CHANGE', 'STATUS_CHANGE')
        request.to_s.should == 'REGISTER ["TOPOLOGY_CHANGE", "STATUS_CHANGE"]'
      end
    end

    describe 'QueryRequest#to_s' do
      it 'returns a pretty string' do
        request = QueryRequest.new('SELECT * FROM system.peers', :local_quorum)
        request.to_s.should == 'QUERY "SELECT * FROM system.peers" LOCAL_QUORUM'
      end
    end

    describe 'QueryRequest#to_s' do
      it 'returns a pretty string' do
        request = PrepareRequest.new('UPDATE users SET email = ? WHERE user_name = ?')
        request.to_s.should == 'PREPARE "UPDATE users SET email = ? WHERE user_name = ?"'
      end
    end

    describe 'ExecuteRequest#to_s' do
      it 'returns a pretty string' do
        request = ExecuteRequest.new("\xCAH\x7F\x1Ez\x82\xD2<N\x8A\xF35Qq\xA5/", [['ks', 'tbl', 'col1', :varchar], ['ks', 'tbl', 'col2', :int], ['ks', 'tbl', 'col3', :varchar]], ['hello', 42, 'foo'], :each_quorum)
        request.to_s.should == 'EXECUTE ca487f1e7a82d23c4e8af3355171a52f ["hello", 42, "foo"] EACH_QUORUM'
      end
    end
  end
end