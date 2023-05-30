# frozen_string_literal: true

require 'rails_helper'

describe Channel do
  subject { described_class.new 'http://www.example.com/' }

  it('is able to initialize') { is_expected.not_to be_nil }

  context 'when Url is available' do
    before { stub_request :post, 'www.example.com' }

    it('is able to transmit data') { subject.transmit 'xyz' }
  end

  context 'when Url is not available' do
    before do
      described_class.unreachable_url.clear
      stub_request(:post, 'www.example.com').to_raise Errno::ECONNREFUSED
    end

    it 'raise error and record unavailable url' do
      expect { subject.transmit 'xyz' }.to raise_error Errno::ECONNREFUSED
      expect(described_class.unreachable_url).to be_member('http://www.example.com/')
    end
  end
end
