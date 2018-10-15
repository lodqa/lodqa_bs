# frozen_string_literal: true

require 'rails_helper'

describe Container do
  let(:data) { { message: 'messsage' } }
  let(:search) { Search.new }
  subject do
    # Test target that incluede the Container
    class Target
      include Container
    end
  end

  describe 'add_for' do
    it 'one search multiple callback URLs' do
      stub1 = stub_request(:post, 'foo.com').with body: data
      stub2 = stub_request(:post, 'bar.com').with body: data

      subject.add_for search, 'http://foo.com/'
      subject.add_for search, 'http://bar.com/'
      subject.publish_for search, data

      expect(stub1).to have_been_requested
      expect(stub2).to have_been_requested
    end
  end

  describe 'remove_all_for' do
    it 'one search Callback URLs, they will not be called after removed' do
      subject.add_for search, 'http://foo.com/'
      subject.add_for search, 'http://bar.com/'
      subject.remove_all_for search.search_id
      subject.publish_for search, data
    end
  end

  describe 'publish_for' do
    context 'one callback URL is unavailable' do
      before { stub_request(:post, 'foo.com').to_raise Errno::ECONNREFUSED }

      it 'logs error when URL is unavailable' do
        subject.add_for search, 'http://foo.com/'
        subject.publish_for search, data
      end
    end
  end
end
