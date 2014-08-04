# encoding:utf-8
Ruote.process_definition :name => "放款审批", :revision => "2.1.0" do
  cursor  do
    business_manager :tag => 'step1', 
      :submit => {'下一步:业务部负责人' => nil,
      '取消流程' => {'command' => 'jump to finish','ok' => '2'}
    }

    # 本业务部负责人
    business_dept_head :tag => 'step2',
      :submit => {
      '上一步:发起审签' => 'jump to step1',
      '下一步:风险部放款审查岗' => nil}

    # 风险管理部放款审查岗
    risk_dept_disbursement_examiner :tag => 'step3',
      :submit => {
      "上一步:业务部负责人" => "jump to step2",
      "下一步:风险部放款复核岗" => nil,
      '退到发起审签' => 'rewind'
    }

    # 风险管理部放款复核岗
    risk_dept_disbursement_reviewer :tag => 'step4',
      :submit => {
      "上一步:风险部放款审查岗" => "jump to step3",
      "下一步:风险部负责人" => nil,
      '退到发起审签' => 'rewind'},
      :action => 'workflow3_step4'

    # 风险部负责人
    risk_dept_head :tag => 'step5',
      :submit => {
      "上一步:风险部放款复核岗" => "jump to step4",
      "下一步:资金管理岗" => nil,
      '退到发起审签' => 'rewind'},
      :action => 'workflow3_step5'

    # 金融市场部
    # 资金管理岗
    capital_manager :tag => 'step6',
      :submit => {
      "上一步:风险部负责人" => "jump to step5",
      "下一步:金融市场部负责人" => nil}

    # 金融市场部负责人
    capital_market_dept_head :tag => 'step7',
      :submit => {
      "上一步:资金管理岗" => "jump to step6",
      "下一步:会计审核岗" => nil,
      '退到发起审签' => 'rewind'
    }

    # 计财部审核
    # 会计审核岗审核
    accounting_dept_accounting_post :tag => 'step8',
      :validate => 'workflow3_validate',
      :submit => {
      "上一步:金融市场部负责人" => "jump to step7",
      "下一步:计财部负责人" => nil,
      '退到发起审签' => 'rewind'
    }

    #计财部负责人审核
    accounting_dept_head :tag => 'step9',
      :submit => {
      "上一步:会计审核岗" => "jump to step8",
      "下一步:分管副总裁" => nil}

    #分管副总裁
    vp :tag => 'step_vp',
      :submit => {
      "上一步:计财部负责人" => "jump to step9",
      "下一步:总裁" => nil,
      '退到风险部负责人' => 'jump to step5'
    }

    #总裁
    president :tag => 'step_president',
      :submit => {
      "上一步:分管副总裁" => "jump to step_vp",
      "终审通过" => {'command' => 'jump to finish','ok' => '1'},
      "终审否决" => {'command' => 'jump to finish','ok' => '0'},
      '退到风险部负责人' => 'jump to step5'
    }

    completer :tag => 'finish'
  end
end

