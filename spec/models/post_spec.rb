require 'rails_helper'

RSpec.describe Post, type: :model, nested_transaction: true do
  let!(:posts) { create_list(:post, 3, content: 'Awesome') }

  context 'creates 3 posts' do
    it { expect(posts.count).to eq(3) }
  end

  context 'creates posts with "Awesome" content' do
    it { expect(posts.map(&:content).uniq).to eq(['Awesome']) }
  end
end
