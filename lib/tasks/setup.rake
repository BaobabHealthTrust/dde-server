task :setup do
  User.create :name => 'admin', :password => 'admin'
  Site.create :name => 'Test Site', :code => 'TS'
  
end

