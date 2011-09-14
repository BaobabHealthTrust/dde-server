module ApplicationHelper

  def notice
    unless flash[:notice].blank?
      content_tag :p, flash[:notice], :class => 'notice'
    end
  end
end
