require 'spec_helper.rb'

describe 'Direct pages', type: :integration do
  before do
    Gopher.application = './gopherpedia.rb'
  end

  it 'works' do
    request '/Bouba/kiki_effect'
    expect(response).to have_content('Bouba/kiki_effect')
  end
end
