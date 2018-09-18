# frozen_string_literal: true

require 'rails_helper'

describe Channel do
  subject { Channel.new 'http://www.example.com/' }
  it('is able to initialize') { is_expected.not_to be_nil }

  context 'Url is available' do
    before { stub_request :post, 'www.example.com' }
    it('is able to transmit data') { subject.transmit 'xyz' }
  end

  context 'Url is not available' do
    before do
      Channel.unreachable_url.clear
      stub_request(:post, 'www.example.com').to_raise Errno::ECONNREFUSED
    end

    it 'raise errror and record unavailable url' do
      expect { subject.transmit 'xyz' }.to raise_error Errno::ECONNREFUSED
      expect(Channel.unreachable_url.member?('http://www.example.com/')).to be_truthy
    end
  end
end
