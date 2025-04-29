require 'rails_helper'

RSpec.feature 'Contents balancing', type: :feature do
  fixtures :contents

  scenario 'visiting the contents balance by category page displays contents balanced by category' do
    visit '/contents/balance_by_category'
    expect(page).to have_content('Contents (Balanced by :category)')
    # Collect the categories from the second column of the table rows
    categories = page.all('table tbody tr').map { |row| row.all('td')[1]&.text }.compact

    expect(categories.count).to eq(Content.count)
    # There should be a mix of categories, not just a long run of one category
    expect(categories.uniq.sort).to eq(%w[blog news tutorial])
    # Check that the first 10 are not all the same (skewed fixture would be all news)
    expect(categories.first(10).uniq.size).to be > 1
  end
end 