class User < ActiveRecord::Base

  def has_role?(role_name)
    true
  end

  def password_matches?(password)
    true
  end
end
