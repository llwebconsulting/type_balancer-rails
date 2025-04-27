class ContentsController < ApplicationController
  def balance_by_category
    @contents = Content.all.balance_by_type(type_field: :category)
    render :balance_by_category
  end

  def balance_by_content_type
    @contents = Content.all.balance_by_type(type_field: :content_type)
    render :balance_by_category
  end
end
