require 'spec_helper.rb'

describe 'Landing page', type: :integration do
  before do
    Gopher.application = './gopherpedia.rb'
  end

  it 'works' do
    request '/'
    expect(response).to have_selector(
                          type: Gopher::Types::INFO,
                          text: /Welcome to \*\*Gopherpedia\*\*/)
  end
end
