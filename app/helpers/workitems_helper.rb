# encoding: utf-8

module WorkitemsHelper
  def workitem_proceed_button(workitem)
    workitem_submit_button('提交', 'proceed', :proceed, "workitem_proceed")
  end

  def workitem_return_button(workitem)
    workitem_submit_button("退回给 #{workitem.real_name(workitem.top_participant)}", 'return',
                           :return, "workitem_return") 
  end

  def workitem_submit_button(label, value, icon_symbol, name)
    raw(
      "<button class='button workitem_submit' id='workitem_#{value}' type='submit' " <<
      "value='#{value}' name='workitem[submit]' alt='#{label}'/>#{label}</button>"
    )
  end

  def dispatch_to_select(users)
    raw("<select id='#dispatch_to_users'>#{user_select_options(users)}</select>")
  end

  def user_select_options(users)
    options = ''
    options << "<option value='0' data-value=''></option>"
    users.each do |u|
      options << "<option value='#{u.id}'>#{u.name}</option>"
    end

    options
  end

  def can_delegate_to_select(users)
    raw("<select id='#can_delegate_to_users'>#{user_select_options(users)}</select>")
  end

end
