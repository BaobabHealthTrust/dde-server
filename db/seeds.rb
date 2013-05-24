# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).

site = Site.create :name => 'My Local Site', :code => 'MLS', :annotations => 'MLS'
user = User.find_by_name('admin')
unless user.blank?
	user.email = 'dde@baobabhealth.org'
	user.notify = true
	user.save!
end
if Site.master?
  #NationalPatientIdentifier.generate!({:count => 19, :assigner_site_id => site.id})
  User.create :name => 'admin', :password => 'admin',:email => 'dde@baobabhealth.org', :notify => 1
  puts "The user for your site uses API key: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx42 and password: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx23"
else
	User.create :name => 'admin', :password => 'admin',:email => 'dde@baobabhealth.org', :notify => true
  puts "Your new user is: admin, password: admin"
end


