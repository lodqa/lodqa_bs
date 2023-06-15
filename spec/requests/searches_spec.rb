# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Searches' do
  before do
    # Stub OpenAI API
    stub_request(:post, 'https://api.openai.com/v1/completions')
      .with(
        body: {
          'model' => 'text-davinci-001',
          'prompt' => 'Make the following sentences into one sentence: Which genes are associated with Endothelin receptor type C?',
          'temperature' => 0
        }.to_json

      )
      .to_return(status: 200,
                 body: { 'choices' =>
                           [{
                             'text' => 'Which genes are associated with Endothelin receptor type C?'
                           }] }.to_json,
                 headers: {})

    # Stub LODQA Targets API
    stub_request(:get, 'http://targets.lodqa.org/targets.json')
      .with(
        headers: {
          'Accept' => '*/*',
          'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'Host' => 'targets.lodqa.org',
          'User-Agent' => 'rest-client/2.1.0 (linux x86_64) ruby/3.2.2p53'
        }
      )
      .to_return(status: 200, body: '{}', headers: {})

    # Stub Enju API
    body = <<~RESPONSE
      0	ROOT	ROOT	ROOT	ROOT	ROOT	ROOT:4
      1	Which	which	WDT	WDT	det_arg1	ARG1:2
      2	genes	gene	NNS	NN	noun_arg0
      3	are	be	VBP	VB	aux_arg12	ARG1:2	ARG2:4
      4	associated	associate	VBN	VB	verb_arg12	ARG1:-1	ARG2:2
      5	with	with	IN	IN	prep_arg12	ARG1:4	ARG2:9
      6	Endothelin	endothelin	NN	NN	noun_arg1	ARG1:9
      7	receptor	receptor	NN	NN	noun_arg1	ARG1:9
      8	type	type	NN	NN	noun_arg1	ARG1:9
      9	C	c	NN	NN	noun_arg0
    RESPONSE
    stub_request(:get, 'http://enju-gtrec.dbcls.jp/?format=conll&sentence=Which%20genes%20are%20associated%20with%20Endothelin%20receptor%20type%20C?')
      .with(
        headers: {
          'Accept' => '*/*',
          'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'Host' => 'enju-gtrec.dbcls.jp',
          'User-Agent' => 'rest-client/2.1.0 (linux x86_64) ruby/3.2.2p53'
        }
      )
      .to_return(status: 200, body:, headers: {})
  end

  describe 'POST /searches' do
    it 'returns http success' do
      post '/searches', params: {
        query: 'Which genes are associated with Endothelin receptor type C?',
        callback_url: 'http://example.com/callback'
      }
      expect(response).to have_http_status(:ok)
    end

    it 'returns search_id' do
      post '/searches', params: {
        query: 'Which genes are associated with Endothelin receptor type C?',
        callback_url: 'http://example.com/callback'
      }

      json_response = JSON.parse(response.body)
      expect(json_response['search_id']).to be_present
    end

    it 'returns resource_url' do
      post '/searches', params: {
        query: 'Which genes are associated with Endothelin receptor type C?',
        callback_url: 'http://example.com/callback'
      }
      expect(response).to have_http_status(:ok)

      json_response = JSON.parse(response.body)
      expect(json_response['resouce_url']).to be_present
    end

    it 'returns subscribe_url' do
      post '/searches', params: {
        query: 'Which genes are associated with Endothelin receptor type C?',
        callback_url: 'http://example.com/callback'
      }
      expect(response).to have_http_status(:ok)

      json_response = JSON.parse(response.body)
      expect(json_response['subscribe_url']).to be_present
    end

    context 'when the same query has been searched in advance' do
      let(:search_id) do
        post '/searches', params: {
          query: 'Which genes are associated with Endothelin receptor type C?',
          callback_url: 'http://example.com/callback'
        }

        json_response = JSON.parse(response.body)
        json_response['search_id']
      end

      it 'returns the same search_id' do
        post '/searches', params: {
          query: 'Which genes are associated with Endothelin receptor type C?',
          callback_url: 'http://example.com/callback'
        }

        json_response = JSON.parse(response.body)
        expect(json_response['search_id']).to eq search_id
      end
    end

    context 'when the request contains user_id' do
      let(:params) do
        {
          query: 'Which genes are associated with Endothelin receptor type C?',
          callback_url: 'http://example.com/callback',
          user_id: 'test_user'
        }
      end

      it 'saves a dialog' do
        post('/searches', params:)
        expect(response).to have_http_status(:ok)

        dialog = Dialog.find_by user_id: 'test_user'
        expect(dialog).to be_present
      end

      it 'save a query to a dialog' do
        post('/searches', params:)
        expect(response).to have_http_status(:ok)

        dialog = Dialog.find_by user_id: 'test_user'
        expect(dialog.natural_language_expressions.first).to be_present
      end

      it 'save a contextualized query to a dialog' do
        post('/searches', params:)
        expect(response).to have_http_status(:ok)

        dialog = Dialog.find_by user_id: 'test_user'
        expect(dialog.contextualized_natural_language_expressions.first).to be_present
      end
    end

    context 'when the request contains pgp instead of query' do
      let(:params) do
        {
          pgp: '{
            "nodes": {
              "t1": {
                "head": 1,
                "text": "genes"
              },
              "t2": {
                "head": 8,
                "text": "Endothelin receptor type C"
              }
            },
            "edges": [{
                        "subject": "t1",
                        "object": "t2",
                        "text": "associated with"
                      }],
            "focus": "t1"
          }',
          mappings: '{
            "genes": "http://identifiers.org/ncbigene/1636"
          }',
          target: 'test_database',
          read_timeout: 10,
          sparql_limit: 100,
          answer_limit: 100,
          private: false,
          callback_url: 'http://example.com/callback'
        }
      end

      it 'acts as export mode' do
        post('/searches', params:)
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
