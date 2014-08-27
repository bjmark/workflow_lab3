class User < ActiveRecord::Base
  has_and_belongs_to_many :roles
  has_and_belongs_to_many :departments

  has_many :user_workflow_results
  has_many :workflow_results, :through => :user_workflow_results

  # returns the first business department the user belongs to
  # a user should _NOT_ belong to more than one business department
  def business_department
    self.departments.each do |d|
      return d if d.business_department?
    end
    nil
  end

  def self.by_login_or_object(user)
    user = User.find_by_login(user) if user.instance_of? String
    user.instance_of?(User) ? user : nil
  end

  def users_with_role_in_my_department(role)
    users = []
    return users if !role

    role.users.each do |u|
      if self == u or self.business_department != u.business_department
        next
      end

      users << u
    end

    users
  end
end
