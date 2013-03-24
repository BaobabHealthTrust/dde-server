# == Schema Information
#
# Table name: person_name_codes
#
#  id               :integer          not null, primary key
#  person_id        :integer          not null
#  given_name_code  :string(255)      not null
#  family_name_code :string(255)      not null
#  created_at       :datetime
#  updated_at       :datetime
#

class PersonNameCode < ActiveRecord::Base

  belongs_to :person, :foreign_key => :id

  def self.create_name_code(person)
    found = self.find_by_person_id(person.id)
    return if person.given_name.blank?
    return if person.family_name.blank?
    return unless person.given_name.match(/[0-9]/).blank?
    return unless person.family_name.match(/[0-9]/).blank?
    
    if found.blank?
      self.create(:person_id => person.id,
                :given_name_code => person.given_name.soundex,
                :family_name_code => person.family_name.soundex)
    else
      found.given_name_code = person.given_name.soundex
      found.family_name_code = person.family_name.soundex
      found.save
    end           
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
