class PersonNameCode < ActiveRecord::Base

  belongs_to :person, :foreign_key => :id

  def self.create_name_code(person)
    self.create(:person_id => person.id,
                :given_name_code => person.given_name.soundex,
                :family_name_code => person.family_name.soundex) 
  end

  def self.rebuild_person_name_codes
    PersonNameCode.delete_all
    people = Person.find(:all)
    people.each {|person|
      PersonNameCode.create(
        :person_id => person.id,
        :given_name_code => (person.given_name || '').soundex,
        :family_name_code => (person.family_name || '').soundex
      )
    }
  end
  
end
