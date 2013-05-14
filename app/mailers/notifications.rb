class Notifications < ActionMailer::Base
  default :from => "dde.admin@baobabhealth.org"
  def notify(user,site,subject,body)
   @user = user
   @site = site
   @subject = subject.title_case
   @body = body
   mail(:to => @user.email, :subject => @subject)
  end
end
