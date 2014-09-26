module ApplicationHelper
  def my_workitems
    res = []
    ([current_user] + current_user.principals).each do |u|
      res += Ruote::Workitem.for_user(u)
    end
    res
  end
end
