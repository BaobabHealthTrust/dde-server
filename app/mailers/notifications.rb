class Notifications < ActionMailer::Base
	include SendGrid
  default :from => User.find_by_name("admin").email
  sendgrid_category :use_subject_lines
  sendgrid_enable   :ganalytics, :opentrack
  sendgrid_unique_args :key1 => Time.now, :key2 => Time.now

  def notify(user,site_name,subject,body)
	 sendgrid_category "Notification"
	 sendgrid_unique_args :key2 => Time.now, :key3 => Time.now
   sendgrid_recipients users_to_notify
   @site_name = site_name
   @subject = subject
   @email_body = body
   mail(:to => User.find_by_name("admin").email, :subject => @subject)
  end

  def users_to_notify
    users = User.where(:disabled => 0, :notify => 1).collect do |user|
      user.email
    end
    return users
  end
end
