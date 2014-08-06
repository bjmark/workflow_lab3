class User < ActiveRecord::Base
  has_and_belongs_to_many :roles
  has_and_belongs_to_many :departments

  # returns the first business department the user belongs to
  # a user should _NOT_ belong to more than one business department
  def business_department
    self.departments.each do |d|
      return d if d.business_department?
    end
    nil
  end
end
