class User < ActiveRecord::Base

  belongs_to :site

  def has_role?(role_name)
    true
  end

  def password_matches?(password)
    true
  end
end
