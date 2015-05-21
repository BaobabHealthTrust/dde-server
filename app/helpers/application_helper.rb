module ApplicationHelper

  def flash_messages
    msgs = flash.map do |type, message|
      content_tag :div, :class => ['message', type] do
        content_tag :p, message
      end
    end

    content_tag :div, msgs.join.html_safe, :class => 'flash'
  end

  def app_version
      `git describe`.gsub(/\n/, '')
  end
end
