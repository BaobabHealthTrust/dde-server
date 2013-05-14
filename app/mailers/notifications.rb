class Notifications < ActionMailer::Base
  default :from => "dde.admin@baobabhealth.org"
  def notify(user,site_name,subject,body)
   @user = user
   @site_name = site_name
   @subject = subject.title_case
   @body = body
   mail(:to => @user.email, :subject => @subject)
  end
end
