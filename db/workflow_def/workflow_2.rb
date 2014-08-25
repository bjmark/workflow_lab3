#encoding:utf-8
Ruote.process_definition :name => "头寸报备", :revision => "2.0.0" do
	cursor  do
		# "业务部审核" 
		# "发起人(主办或协办)"
		business_manager :tag => 'step1',		
			:submit => {
			'下一步:业务部负责人审核' => nil,
			'取消流程' => {'command' => 'jump to finish','ok' => '2'},
			# "终审通过" => {'command' => 'jump to finish','ok' => '1'},
			# "终审否决" => {'command' => 'jump to finish','ok' => '0'}
		}

		#"本业务部负责人"
		business_dept_head :tag => 'step2',
			:submit => {
			'上一步:发起审签' => 'jump to step1',
			'下一步:项目审查' => nil}

		# "风险部审核" 
		# 项目审查岗，有权改是否占投放规模
		no_op :tag => 'step3'
		right_setter :add_right => {'update_account_for_position_scale' => 'risk_dept_examiner'}

		risk_dept_examiner :on_leave => {'del_right' => 'update_account_for_position_scale'},
			:submit => {
			"上一步:业务部负责人审核" => "jump to step2",
			"下一步:法务审核" => nil,
			"退回到发起审签" => 'rewind'
		}

		#法务岗审核,有权改是否占投放规模
		no_op :tag => 'step4'
		right_setter :add_right => {'update_account_for_position_scale' => 'risk_dept_legal_examiner'}

		risk_dept_legal_examiner :on_leave => {'del_right' => 'update_account_for_position_scale'}, 
			:submit => {
			"上一步:项目审核" => "jump to step3",
			"下一步:风险部负责人审核" => nil,
			"退回到发起审签" => 'rewind'
		}

		#"风险部负责人"
		risk_dept_head  :tag => "step5",
			:submit => {
			"上一步:法务审核" => "jump to step4",
			"下一步:资金管理岗审核" => nil}

		# "金融市场部" 
		#资金管理岗,有权修改头寸拟投放日期
		no_op :tag => 'step6'
		right_setter :add_right => {'update_payment_date' => 'capital_manager'}

		capital_manager :on_leave => {'del_right' => 'update_payment_date'},
			:submit => {
			"上一步:风险部负责人审核" => "jump to step5",
			"下一步:金融市场部负责人审核" => nil}

		#"金融市场部负责人,有权修改头寸拟投放日期"
		no_op :tag => 'step7'
		right_setter :add_right => {'update_payment_date' => 'capital_market_dept_head'}

		capital_market_dept_head :on_leave => {'del_right' => 'update_payment_date'},
			:submit => {
			"上一步:资金管理岗审核" => "jump to step6",
			"终审通过" => {'ok' => '1'},
			"终审否决" => {'ok' => '0'}}

		completer :tag => 'finish'
	end
end

