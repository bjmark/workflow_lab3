# encoding: utf-8
# module for fee/charge related amortization settings
# TODO: may need to re-write this whole dame thing in State Machine
module Ext
  module AmortSetting
    extend self

    AMORT_FIELDS = %w[fee_amortization_type_id amortization_amount
      amortization_begin_date amortization_end_date]

    def self.amortization_straight_line?(amort_type)
      [:straight_line_with_amount_and_duration_by_month,
       :straight_line_with_amount_and_duration_by_day].include?(amort_type.code.to_sym)
    end

    def amortized?
      !not_amortized?
    end

    def not_amortized?
      self.fee_amortization_type ?
        self.fee_amortization_type.code.to_sym == :not_amortized :
        false
    end

    # will _ONLY_ be called for fee, not the TPI object
    def amortization_settings_editable?
      raise "Can ONLY be called on fee, not tpi" if self.instance_of?(TranchePeggedItem)

      if self.collection_tranche_pegged?
        self.tranche_pegged_items.each do |tpi|
          if !Amortization.fee_recognition_started?(tpi.class.to_s, nil, tpi.id)
            return true
          end
        end
        return false
      else
        !self.recognition_started?
      end
    end

    def nullify_amort_fields
      self.fee_amortization_type = nil
      nullify_amort_amount_and_dates
    end

    def straight_line_amortization?
      self.fee_amortization_type and
        AmortSetting.amortization_straight_line?(self.fee_amortization_type)
    end

    def post_start_collection?
      self.due_date > self.fina_term.start_date
    end

    # called as :after_create callback in Fee/TPI
    def set_default_amort_settings
      set_default_amort_type
      reset_amort_defaults_based_on_amort_type
    end

    def set_default_amort_type
      if self.instance_of? TranchePeggedItem
        self.set_association_by_code(:fee_amortization_type,
                                     :straight_line_with_amount_and_duration_by_month)
      else
        if self.due_date
          self.post_start_collection? ?
            self.set_association_by_code(:fee_amortization_type,
                                         :straight_line_with_amount_and_duration_by_month) :
            self.set_association_by_code(:fee_amortization_type, :interest_ratio)
        else
          # newly created Fee: no due_date has been set yet.
          self.set_association_by_code(:fee_amortization_type, :interest_ratio)
        end
      end
    end

    # modify amortization-related settings upon receipt
    def calc_amorts_if_post_start_receipt(settlement_date)
      if self.straight_line_amortization? and settlement_date > lease_start_date
        # for straight line amortization, the amort_end_date counts.
        # To be consistent with interest ratio amortization, which does not
        # count lease_end_date, we need to subtract ONE DAY.
        set_amort_attributes(self, settlement_date, lease_end_date - 1,
                             default_amortization_amount)
        self.save if self.changed?

        # need to calculate amortization if lease already stareted,
        # and we settled a fee
        if self.instance_of? TranchePeggedItem
          self.owner.calc_and_save
        else
          self.calc_and_save
        end
      end
    end

    def update_amort_settings_on_disbursement(tranche)
      if self.instance_of? TranchePeggedItem
        raise "Invalid caller type (TranchePeggedItem)"
      end

      case fee_collection_type.code.to_sym
      when :lump_sum_from_customer
        self.set_default_amort_type

        if self.fee_amortization_type.code.to_sym == :interest_ratio or
          self.fee_amortization_type.code.to_sym == :not_amortized
          nullify_amort_amount_and_dates
        end

        if self.straight_line_amortization?
          if self.due_date > self.fina_term.start_date # 租后收取的中间业务收入
            set_amort_attributes(self, self.due_date, lease_end_date - 1,
                                 default_amortization_amount)
          else
            set_amort_attributes(self, self.fina_term.start_date,
                                 lease_end_date - 1, default_amortization_amount)
          end
        end

        self.save if self.changed?
      when :lump_sum_deduct_from_first_disbursement
        self.set_default_amort_type

        if self.fee_amortization_type.code.to_sym == :interest_ratio or
          self.fee_amortization_type.code.to_sym == :not_amortized
          nullify_amort_amount_and_dates
        end

        if self.straight_line_amortization? and tranche.tranche_first?
            set_amort_attributes(self, tranche.disbursement_date,
                                 lease_end_date - 1, default_amortization_amount)
        end

        self.save if self.changed?
      when :received_from_customer_on_each_disbursement
        self.tranche_pegged_items.each do |tpi|
          next if tpi.tranche.disbursement_date != tranche.disbursement_date

          tpi.set_default_amort_type

          if tpi.straight_line_amortization?
            if tranche.post_start?
              set_amort_attributes(tpi, tranche.disbursement_date, lease_end_date - 1,
                                   tpi.default_amortization_amount)
            else
              set_amort_attributes(tpi, lease_start_date, lease_end_date - 1,
                                   tpi.default_amortization_amount)
            end
          else
            tpi.set_default_amortization_amount
          end

          tpi.save if tpi.changed?
        end
      when :deduct_from_each_disbursement
        self.tranche_pegged_items.each do |tpi|
          next if tpi.tranche.disbursement_date != tranche.disbursement_date

          tpi.set_default_amort_type

          if tpi.straight_line_amortization?
            if tranche.post_start?
              set_amort_attributes(tpi, tranche.disbursement_date, lease_end_date - 1,
                                   tpi.default_amortization_amount)
            else
              set_amort_attributes(tpi, lease_start_date, lease_end_date - 1,
                                   tpi.default_amortization_amount)
            end
          else
            tpi.set_default_amortization_amount
          end

          tpi.save if tpi.changed?
        end
      else
        self.errors.add(:fee_collection_type, "费用收取方式非法")
      end
    end

    # Note: amortication related fields are not visible when the business people defines
    # the fees. We need to setup sensible defaults under the hood. These defaults will be
    # modified if necessary during contract approval phase.
    def reset_amort_defaults_based_on_amort_type
      case fee_amortization_type.code.to_sym
      when :not_amortized, :interest_ratio
        nullify_amort_amount_and_dates
      when :straight_line_with_amount_and_duration_by_day,
        :straight_line_with_amount_and_duration_by_month

        set_default_amortization_amount

        if self.instance_of? TranchePeggedItem
          if self.tranche.post_start?
            if self.due_date > lease_start_date
              self.amortization_begin_date = self.due_date
            else
              self.amortization_begin_date = lease_start_date
            end
          else
            self.amortization_begin_date = lease_start_date
          end
        else
          if self.due_date and self.post_start_collection?
            self.amortization_begin_date = self.due_date
          else
            self.amortization_begin_date = lease_start_date
          end
        end

        self.amortization_end_date = lease_end_date - 1
      else
        self.errors.add(:fee_amortization_type, "费用摊销类型非法")
      end
    end

    def get_amortization_date_errors(date)
      errors = []
      if ['straight_line_with_amount_and_duration_by_month',
          'straight_line_with_amount_and_duration_by_day'].include?(
            self.fee_amortization_type.code) and
        self.amortization_begin_date < date.to_date
        errors << '摊销起始日将会在合同起租日之前。'
      end

      errors
    end

    def amortization_attributes_update_allowed?
      !self.recognition_started?
    end

    # this is for best_in_place editing. The update starts from
    #:fee_amortization_type.  if :fee_amortization_type changes,
    # all other amort_fields are reset to its corresponding (reasonable)
    # defaults.
    # _NOTE_: best_in_place always changes ONE FIELD AT A TIME.
    def update_amortization_attribute(params)
      return if !amortization_attributes_update_allowed?

      # sanitize first
      params.keys.map { |k| params.delete(k) if !AMORT_FIELDS.include?(k) }

      # ONE at a time
      raise "一次只能修改一个摊销设置参数" if params.size != 1

      if params["fee_amortization_type_id"]
        new_amort_type_id = params["fee_amortization_type_id"]
        new_amort_type = FeeAmortizationType.find(new_amort_type_id)

        if !new_amort_type
          self.errors.add(:fee_amortization_type, "费用摊销类型非法")
          return false
        end

        if new_amort_type != self.fee_amortization_type
          if self.post_start_collection? and
            new_amort_type.code.to_sym == :interest_ratio

            # NOTE: no-op - amort_type change to :interest_ration in this
            # case NOT ALLOWED.
          else
            self.fee_amortization_type = new_amort_type
            reset_amort_defaults_based_on_amort_type
            return self.save
          end
        end
      else
        # since we are only changine ONE amortization attribute here
        return update_amortization_attribute_with_type_given(params)
      end
    end

    # amort_attrib: hash that has ONLY ONE amort-setting key
    def update_amortization_attribute_with_type_given(amort_attrib)
      case self.fee_amortization_type.code.to_sym
      when :not_amortized, :interest_ratio
        nullify_amort_amount_and_dates
        return self.save
      when :straight_line_with_amount_and_duration_by_day,
        :straight_line_with_amount_and_duration_by_month

        k = amort_attrib.keys.first
        v = amort_attrib[k]
        self.send("#{k}=", v)

        # let the validation do all the default settings/corrections
        validate_amort_amount
        validate_amort_dates

        self.save
      else
        errors.add(:fee_amortization_type, "系统不支持该中间业务收入摊销方式")
        return false
      end
    end

    def lease_start_date
      self.fina_term.start_date
    end

    def lease_end_date
      self.fina_term.end_date
    end

    def first_disbursement_date
      self.fina_term.first_disbursement_date
    end

    # NOTE: this is tricky: when a TPI is created as part of fee creation,
    # through "accepts_nested_attributes_for", tpi.owner will be null.
    # We need to go through tpi.tranche to get to the financial_term.
    def fina_term
      self.instance_of?(TranchePeggedItem) ? self.tranche.financial_term : self.financial_term
    end

    # amortization can be defined in either fee/charge or tpi
    # this method validate a single set of amortization settings
    def validate_amortization()
      return if !fee?

      raise "fee_amortization_type not set" if !self.fee_amortization_type

      case self.fee_amortization_type.code.to_sym
      when :not_amortized, :interest_ratio
        nullify_amort_amount_and_dates
      when :straight_line_with_amount_and_duration_by_day,
        :straight_line_with_amount_and_duration_by_month
        validate_amort_amount
        validate_amort_dates
      else
        errors.add(:fee_amortization_type, "系统不支持该中间业务收入摊销方式")
      end
    end

    def validate_amortization_settings
      return if !fee?

      if collection_tranche_pegged?
        self.tranche_pegged_items.each do |tpi|
          tpi.validate_amortization
          self.errors.add(:base, tpi.errors.full_messages) if tpi.errors.any?
        end
      else
        validate_amortization
      end
    end

    def default_amortization_amount
      self.vat_tax? ? self.amount_excl_vat : self.amount
    end

    def vat_tax?
      self.instance_of?(TranchePeggedItem) ?
        self.tranche.financial_term.vat_tax? : self.financial_term.vat_tax?
    end

    def update_amorti_settings_for_early_termination(termination_date)
      if self.instance_of?(TranchePeggedItem) or !self.fee?
        raise "can only be called on fee, not TPI or security_deposit"
      end

      if self.collection_tranche_pegged?
        self.tranche_pegged_items.each do |tpi|
          if tpi.straight_line_amortization? and
            tpi.amortization_end_date > termination_date

            tpi.amortization_end_date = termination_date
            tpi.save!
          end
        end
      else
        if self.straight_line_amortization? and
          self.amortization_end_date > termination_date

          self.amortization_end_date = termination_date
          self.save!
        end
      end
    end

    # 最后的过账日: 例如，已经完成8月底月结，则应为8-31日
    # put this mothod here since it needs to be included in both fees and tpis.
    def last_amort_recognition_date
      self.instance_of?(TranchePeggedItem) ?
        Amortization.fee_last_recognition_date(self.class.to_s, nil, self.id) :
        Amortization.fee_last_recognition_date(self.class.to_s, self.id, nil)
    end

    # 中间业务收入摊销确认已开始
    def recognition_started?
      self.instance_of?(TranchePeggedItem) ?
        Amortization.fee_recognition_started?(self.class.to_s, nil, self.id) :
        Amortization.fee_recognition_started?(self.class.to_s, self.id, nil)
    end

    def set_default_amortization_amount
      return if !self.fee?

      self.amortization_amount = default_amortization_amount
    end

    private
    def nullify_amort_amount_and_dates
      self.amortization_amount = self.amortization_begin_date =
        self.amortization_end_date = nil
    end

    def set_amort_attributes(fee_or_tpi, start_date, end_date, amount)
      fee_or_tpi.amortization_begin_date = start_date
      fee_or_tpi.amortization_end_date = end_date
      fee_or_tpi.amortization_amount = amount
    end

    def validate_amort_amount
      if !self.amortization_amount or self.amortization_amount < 0.0 or
        self.amortization_amount > self.amount
        self.set_default_amortization_amount
      end
    end

    def validate_amort_dates
      if !self.straight_line_amortization?
        raise "amort_date validation only applicable to :straight_line_amortization"
      end

      if !self.fina_term.started? and self.amortization_begin_date < Date.today
        errors.add(:amortization_begin_date, "未起租条款，摊销起始日 " +
                   "#{self.amortization_begin_date} 需大于或等于系统当前日期")
      end

      msg = "指定期限摊销时，摊销期间" +
        " #{self.amortization_begin_date} ~ #{self.amortization_end_date} "
      if self.instance_of?(TranchePeggedItem)
        if self.post_start_collection? and self.amortization_begin_date < self.due_date
          check_amort_begin_and_end_date_against(self.due_date, lease_end_date - 1,
                                                 msg + "必须在放款日(含)和租赁截止日(含)之间")
        else
          check_amort_begin_and_end_date_against(lease_start_date, lease_end_date - 1,
                                                 msg + "必须在租赁起始日(含)和租赁截止日(含)之间")
        end
      else
        check_amort_begin_and_end_date_against(lease_start_date, lease_end_date - 1,
                                               msg + "必须在租赁起始日(含)和租赁截止日(含)之间")
      end
    end

    def check_amort_begin_and_end_date_against(start_date, end_date, msg)
      if !self.amortization_begin_date or self.amortization_begin_date < start_date
        errors.add(:amortization_begin_date, msg)
        self.amortization_begin_date = start_date
        return
      end

      if !self.amortization_end_date or self.amortization_end_date > end_date
        errors.add(:amortization_end_date, msg)
        self.amortization_end_date = end_date
        return
      end
    end
  end
end
