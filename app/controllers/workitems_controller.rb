# -*- encoding: utf-8 -*-
# Ruote::Worktiem
class WorkitemsController < ApplicationController
  #load_and_authorize_resource
  def index
    @workitems = Ruote::Workitem.for_user(current_user)
  end

  def show
    @workitem = RuoteKit.storage_participant[params[:id]]
  end

  def edit
    @workitem = RuoteKit.storage_participant[params[:id]]
    @submit_values = merge_submit(@workitem).keys
    @message = @workitem.fields['message']
    @message ||= []
    @final_right = @workitem.fields['final_right']
    @wi_action = @workitem.fields['params']['action']

    case @wi_action
    when 'workflow1_step5','workflow1_step6','workflow3_step4','workflow3_step5'
      @final_right = @workitem.fields['final_right']
      if @final_right == 'step_president' and ['workflow1_step6','workflow3_step5'].include?(@wi_action)
        @form = 'form'
      else
        @final_right ||= 'step_president'
        @form = 'form_workflow1_step6'
        @final_right_options = {
          'step_vp' => '分管副总裁',
          'step_president' => '总裁'
        }
      end
    else
      @form = 'form'
    end
  end

  def workflow1_set_final_right(workitem)
    final_right = params[:final_right]
    workitem.fields.delete(workitem.fields['final_right'])
    workitem.fields['final_right'] = final_right

    workitem.fields[final_right] = {
      "终审通过" => {'command' => 'jump to finish','ok' => '1'},
      "终审否决" => {'command' => 'jump to finish','ok' => '0'}
    }

    workitem.fields['message'] = []
    case final_right
    when 'step_vp'
      workitem.fields['message'] << '根据公司有关授权文件，本事项终审权人为:分管副总裁'
      workitem.fields['step_vp']["下一步:总裁"] = 'del'
    when 'step_president'
      workitem.fields['message'] << '根据公司有关授权文件，本事项终审权人为:总裁'
    end
=begin
    case final_right
    when 'step11'
      workitem.fields[final_right]["下一步:分管副总裁审批"] = 'del'
    end
=end
  end

  def workflow1_step5(workitem)
    workflow1_set_final_right(workitem)
  end

  def workflow1_step6(workitem)
    workflow1_set_final_right(workitem)
  end

  def workflow3_step4(workitem)
    workflow1_set_final_right(workitem)
  end

  def workflow3_step5(workitem)
    workflow1_set_final_right(workitem)
  end

  def update
    workitem = RuoteKit.storage_participant[params[:id]]

    # workitem _CANNOT_ be located, meaning it has been handled by somebody else
    # and it not long available in your queue
    if !workitem
      flash[:error] = "无法提交。该事项可能已处理，或已由同岗位/角色的其他用户处理提交。"
      redirect_to :action => :index
      return
    end

    if !workitem.belongs_to?(current_user)
      flash[:error] = "该事项不在当前用户队列，不能提交。ID: #{workitem.fei.sid}"
      redirect_to :action => :index
      return
    end

    op_name = params[:workitem][:submit]
    if op_name.include?('下一步') and (fun_name = workitem['params']['validate'])
      case fun_name
      when 'workflow1_validate'
        if !workitem.target.business_contract_exist?
          flash[:error] = "没有上传融资租赁合同,不能提交给下一步."
          redirect_to :action => :edit
          return
        end
      when 'workflow3_validate'
        if !workitem.target.bypass_validate('receivable_clear?') and
          !workitem.target.cash_position.receivable_clear?
          flash[:error] = "放款前应收的中间业务收入或保证金未全部核销"
          redirect_to :action => :edit
          return
        end
      end
    end

    # handle special condition,like workflow1_step5,workflow1_step6
    wi_action = params[:wi_action]
    send(wi_action,workitem) if wi_action

    exec_submit(workitem,op_name)

    #用于取消overview中某个字段的修改权限
    on_leave = workitem['params']['on_leave']
    unless on_leave.blank?
      on_leave.each do |fun,var|
        case fun
        when 'del_right'
          workitem.target.del_right(var)
        when 'update_business_contract_validate'
          unless workitem.target.update_business_contract_validate
            flash[:error] = "没有上传租赁合同！"
            redirect_to :action => :edit
            return
          end
        end
      end
    end

    begin
      RuoteKit.storage_participant.proceed(workitem)
    rescue
      flash[:error] = "该事项可能已处理，或已由同岗位/角色的其他用户处理提交。"
      redirect_to :action => :index
      return
    end

    ProcessJournal.create!([{
      :wfid => workitem.wfid,
      #:current_tree => RuoteKit.engine.process(workitem.wfid).current_tree,
      :user_id => current_user.id,
      :as_role_id => Role.find_by_code(workitem.participant_name).id,
      :comments => params[:workitem][:comments],
      :workflow_action => op_name,
      :owner_type => workitem.fields["target"]["type"].camelize,
      :owner_id => workitem.fields["target"]["id"],
      :ok => workitem.fields["ok"] }
    ])

    w = WorkflowResult.where(:wfid => workitem.wfid).first
    unless w.blank?
      w.process_at = Time.now
      w.final_user_id = current_user.id
      w.save!
    end

    UserWorkflowResult.check_and_create(w.id, current_user.id)

    redirect_to :action => :index
  end

  def merge_submit(workitem)
    my_tag = workitem.fields['params']['tag']
    hash = workitem.fields[my_tag]
    submit = workitem.fields['params']['submit']

    return submit if !hash

    submit = submit.merge(hash)
    submit.delete_if{|k,v| v == 'del'}

    return submit
  end

  def exec_submit(workitem,op_name)
    submit = merge_submit(workitem)

    raise 'invalid workflow operation' if !submit.has_key?(op_name)
    op = submit[op_name]

    case op
    when String
      workitem.command = op
    when Hash
      op.each do |k,v|
        if k == 'command'
          workitem.command = v
        else
          workitem.fields[k] = v
        end
      end
    end
    return workitem
  end

end
