class Notifications < ActionMailer::Base
	include SendGrid
  default :from => User.find_by_name("admin").email
  sendgrid_category :use_subject_lines
  sendgrid_enable   :ganalytics, :opentrack
  sendgrid_unique_args :key1 => Time.now, :key2 => Time.now

  def notify(user,site_name,subject,body)
	 sendgrid_category "Welcome"
	 sendgrid_unique_args :key2 => Time.now, :key3 => Time.now
   @user = user
   @site_name = site_name
   @subject = subject
   @email_body = body
   mail(:to => @user.email, :subject => @subject)
  end
end
