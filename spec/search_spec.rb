require 'spec_helper.rb'

describe 'Searching', type: :integration do
  before do
    Gopher.application = './gopherpedia.rb'
  end

  it 'can search' do
    request '/'
    expect(response).to have_selector(
                          type: Gopher::Types::SEARCH,
                          text: 'Search Gopherpedia')

    follow 'Search Gopherpedia', search: 'Firehose'

    expect(response).to have_selector(
                          type: Gopher::Types::INFO,
                          text: '** RESULTS FOR Firehose **')
    expect(response).to have_selector(
                          type: Gopher::Types::TEXT,
                          text: 'Firehose of falsehood')
  end
end
