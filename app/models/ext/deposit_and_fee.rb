# encoding: utf-8
module Ext
  module DepositAndFee
    # shorter name
    def tpis
      self.tranche_pegged_items
    end

    def valid_collection_types
      h = {}
      if self.financial_term.contract_status.code == 'started'
        # 一次直接收取
        lump_sum_col_type = FeeCollectionType.find_by_code('lump_sum_from_customer')

        # use name, which is chinese as hash ke: formtastic/HTML needs it
        h[lump_sum_col_type.name] = lump_sum_col_type.id
      else
        # this is a hack just to get 一次性委托扣款 to be the default (first collection)
        FeeCollectionType.order(:name).each { |type| h[type.name] = type.id }
      end
      h
    end

    def first_disbursement_date
      self.financial_term.first_disbursement_date.to_s
    end

    def last_term_due_date
      self.financial_term.last_rental.due_date
    end

    def collection_tranche_pegged?
      # 按放款百分比分次直接收取 or 按放款百分比分次委托扣款
      %w(received_from_customer_on_each_disbursement
        deduct_from_each_disbursement).include?(self.fee_collection_type.code)
    end

    # 收款方式为委托扣款
    def collection_commissioned_debit?
      # 按放款百分比分次委托扣款 # or 一次性委托扣款
      %w(lump_sum_deduct_from_first_disbursement
        deduct_from_each_disbursement).include?(self.fee_collection_type.code)
    end

    # if the fee/deposit is collected only once, whether it's tranche_pegged (
    # when there is only one tranche) or not
    def one_collection?
      self.financial_term.tranches.size == 1 ?  true : false
    end

    def total
      collection_tranche_pegged? ?
        self.tranche_pegged_items.map(&:amount).compact.reduce(&:+).round_to :
        self.amount
    end

    def total_excl_vat
      collection_tranche_pegged? ?
        self.tranche_pegged_items.map(&:amount_excl_vat).reduce(&:+).round_to :
        self.amount_excl_vat
    end

    def total_vat
      collection_tranche_pegged? ?
        self.tranche_pegged_items.map(&:amount_vat).reduce(&:+).round_to :
        self.amount_vat
    end

    def total_as_pct_of_fa
      (100.00 * total / self.financial_term.financed_amount).round_to(4)
    end

    def build_tranche_pegged_items
      if self.new_record? and self.tranche_pegged_items.empty?
        self.financial_term.tranches.each do |tranche|
          tpi = self.tranche_pegged_items.build
          tpi.owner = self
          tpi.tranche = tranche
        end
      else
        # the user might still want to modify the handling fee
        # such that it become tranche pegged
        if !self.collection_tranche_pegged? and
          self.financial_term.tranche_defined? and
          self.tranche_pegged_items.empty?
          self.financial_term.tranches.each do |tranche|
            tpi = self.tranche_pegged_items.build
            tpi.owner = self
            tpi.tranche = tranche
          end
        end
      end
    end

    #   - business-rules (including sensible defaults)
    #   - custom (more complex) validation
    def apply_business_rules
      if self.financial_term.tranches.empty? and self.collection_tranche_pegged?
        errors.add(:base, "未定义放款计划, 不能按放款百分比收取")
        return
      end

      if self.collection_tranche_pegged?
        set_amount_and_pct_from_tpis
        self.fee_calculation_type_id = nil
        self.due_date = nil
      else
        # remove any defined tranch_pegged_items in this case
        self.tranche_pegged_items.destroy_all

        if self.fee?
          if self.financial_term.vat_tax?
            self.vat_rate = 17.00 if !self.vat_rate

            self.amount_excl_vat, self.amount_vat =
              Ext::VatCalculator.calc(self.amount, self.vat_rate)
          else
            self.vat_rate = self.amount_excl_vat = self.amount_vat = 0.00
          end
        end
      end

      if !self.amount
        errors.add(:amount, '不能为空')
        return
      end

      if self.amount < 0.00 or self.amount > self.financial_term.financed_amount
        errors.add(:base, "金额需大于0但不超过融资额")
        return
      end

      if !self.percentage_of_financed_amount
        errors.add(:percentage_of_financed_amount, '不能为空')
        return
      end

      if self.percentage_of_financed_amount < 0.01 or
        self.percentage_of_financed_amount > 99.99
        errors.add(:percentage_of_financed_amount, "需在[0.01, 99.99]之间")
        return
      end

      validate_due_date
    end

    def fee_collection_schedule_changed
      FeeCollectionSchedule.create_for_fee(self)
    end

    # receivable settlement started, but there may still be remaining
    # receivables to be settled
    def received?
      self.settled_total > 0.0
    end

    # received_amount should always equal the amount
    # so it can be used to calculate the amortization
    def received_amount
      self.collection_tranche_pegged? ?
        self.tranche_pegged_items.map(&:received_amount).copmact.reduce(&:+) :
        self.settled_total
    end

    def settled_total
      recvs = self.fee_collection_schedules.map(&:receivable)

      recvs.any? ? recvs.map(&:settled_amount).compact.reduce(&:+) : 0
    end

    # recalc based on tranche's disbursement amount change.
    # if financed_amount changes, need to re-calc as well.
    def update_on_financed_amount_change(old_financed_amount)
      case self.fee_collection_type.code.to_sym
      when :lump_sum_from_customer, :lump_sum_deduct_from_first_disbursement
        new_amount = (old_financed_amount * self.percentage_of_financed_amount / 100.00).round_to
        self.amount = new_amount if new_amount != self.amount
        self.save if self.changed?
      when :received_from_customer_on_each_disbursement, :deduct_from_each_disbursement
        # ain't doing nothin'
        # will be handled in #update_due_date_on_disbursement method
      else
        raise "费用收取方式非法: #{self.fee_collection_type.code}"
      end
    end

    def update_on_disbursement(tranche)
      update_due_date_and_amount_on_disbursement(tranche)

      # the following function is defined in deposit_and_fee.rb
      update_amort_settings_on_disbursement(tranche) if self.fee?
    end

    def update_due_date_and_amount_on_disbursement(tranche)
      case self.fee_collection_type.code.to_sym
      when :lump_sum_from_customer
        # ain't doing nothin'
      when :lump_sum_deduct_from_first_disbursement
        if tranche.tranche_first? and self.due_date != tranche.disbursement_date
          self.due_date = tranche.disbursement_date
          self.save if self.changed?
          FeeCollectionSchedule.update_due_date(self, tranche.disbursement_date)
        end
      when :received_from_customer_on_each_disbursement
        self.tranche_pegged_items.each do |tpi|
          if tpi.tranche == tranche
            new_amount = (tranche.amount * tpi.percentage / 100.00).round_to
            tpi.amount = new_amount if new_amount != tpi.amount
            tpi.save if tpi.changed?
          end
        end
      when :deduct_from_each_disbursement
        self.tranche_pegged_items.each do |tpi|
          # find the corresponding TPI
          if tpi.tranche == tranche
            new_amount = (tranche.amount * tpi.percentage / 100.00).round_to
            tpi.amount = new_amount if new_amount != tpi.amount

            if tpi.due_date != tranche.disbursement_date
              tpi.due_date = tranche.disbursement_date
              FeeCollectionSchedule.update_due_date(
                self, tranche.disbursement_date, tranche.payable_id)
            end
            tpi.save if tpi.changed?
          end
        end
      else
        raise "费用收取方式非法: #{self.fee_collection_type.code}"
      end
    end

    # update due_date (for both fee/SD) and
    # amort_begin_date (for fee with straight-line amortization)
    # when the first disbursement is made
    # This is for use in CashPosition  ONLY.
    # TODO: needs refactoring
    def update_due_dates(disbursement_date)
      return if !self.collection_commissioned_debit?

      if self.fee?
        attrs = { :due_date => disbursement_date }

        self.class.update_all(attrs, { :id => self.id })
      else
        self.class.update_all({ :due_date => disbursement_date }, { :payable_id => self.id })
      end
      self.reload
      FeeCollectionSchedule.update_due_date(self, disbursement_date)
    end

    # the host model (in which this module is included) should either be a SecurityDeposit or
    # a fee.  Amortization related attributes are relevant only for fees.
    def fee?
      self.instance_of?(SecurityDeposit) ? false : true
    end

    def security_deposit?
      !self.fee?
    end

    def receivable_status
     self.fee_collection_schedules.first.receivable.receivable_status
    end

    def id_for_fee_or_sd
      # security_deposit inherits from Payable, it has not :ID field
      self.security_deposit? ? self.payable_id : self.id
    end

    private
    # when fees are tranche pagged, calculate :amount and :pct_of_fa
    # based on tranche_pegged_items
    def set_amount_and_pct_from_tpis
      self.amount = total
      self.percentage_of_financed_amount = total_as_pct_of_fa

      if self.financial_term.vat_tax? and self.fee?
        self.amount_excl_vat = total_excl_vat
        self.amount_vat = total_vat
      end

      # there is _NO_ amortization_amount attribute for security_deposit
      if self.fee? and !self.amortization_amount
        self.amortization_amount =
          self.financial_term.vat_tax? ? self.amount_excl_vat : self.amount
      end
    end

    def validate_due_date
      if self.collection_tranche_pegged?
        if self.due_date
          errors.add(:due_date, "不能单独定义")
          errors.add(:base, "当收款方式跟放款挂钩时，收取日不能单独定义")
        end
      else
        errors.add(:due_date, "不能为空") if !self.due_date
      end
    end
  end
end
