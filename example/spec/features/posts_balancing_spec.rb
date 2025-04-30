require 'rails_helper'

RSpec.feature 'Posts balancing', type: :feature do
  fixtures :posts

  scenario 'visiting the posts index displays posts balanced by media_type' do
    visit '/posts'
    expect(page).to have_content('Posts (Balanced by :media_type)')
    # Collect the media types from the second column of the table rows
    media_types = page.all('table tbody tr').map { |row| row.all('td')[1]&.text }.compact
    # There should be a mix of media types, not just a long run of one type
    expect(media_types.uniq.sort).to eq(%w[article image video])
    # Check that the first 10 are not all the same (skewed fixture would be all video)
    expect(media_types.first(10).uniq.size).to be > 1
  end
end
