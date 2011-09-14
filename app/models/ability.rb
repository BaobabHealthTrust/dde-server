class Ability
  include CanCan::Ability

  def initialize(user)
    if user
      can :access, :anything

      if user.has_role? :clinic_admin
        can :show, Person
        can :edit, Person
        can :update, Person
      end

#       if user.has_role? :clinic_employee
#       end
# 
#       if user.has_role? :moh_employee
#       end

      if user.has_role? :doctor
        can :show, Person
        can :edit, Person
        can :update, Person
      end

      if Site.master?
        can :generate, NationalPatientIdentifier
        can :manage, Site
      end

      if Site.proxy?
        cannot :generate, NationalPatientIdentifier
        can :show_remote, Person do |person|
          person.npid_value
        end
      end
    else
      can :access, :login
    end
  end

end
