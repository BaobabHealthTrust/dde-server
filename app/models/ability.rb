class Ability
  include CanCan::Ability

  def initialize(user)
    if user
      can :access, :anyhing

#       if user.has_role? :clinic_admin
#       end
# 
#       if user.has_role? :clinic_employee
#       end
# 
#       if user.has_role? :moh_employee
#       end
# 
#       if user.has_role? :doctor
#         can :update, Person
#       end
    else
      can :access, :login
    end
  end

end
