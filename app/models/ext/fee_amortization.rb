# -*- encoding: utf-8 -*-
module Ext
  module FeeAmortization
    extend self

    AMORT_FIELDS = %w[fee_amortization_type_id amortization_amount
      amortization_begin_date amortization_end_date]

    FEES = %w[other_fees management_fees handling_fees commission consulting_fees].freeze
    FEES_AND_DEPOSITS = [FEES, "security_deposits"].flatten.freeze

    # check if the category name is a valid fee/charge amortization category
    # as used in Amortization table.
    def valid_fee_amort_category?(cat)
      cats = Ext::FeeAmortization::FEES.map(&:classify).map(&:to_s)
      cats << "TranchePeggedItem"
      cats.include?(cat.to_s)
    end

    def print_amorts
      if self.collection_tranche_pegged?
        self.tranche_pegged_items.each do |tpi|
          Amortization.print_table(tpi.amortizations)
        end
      else
        Amortization.print_table(self.amortizations)
      end
    end

    def print_amort_details
      if self.collection_tranche_pegged?
        self.tranche_pegged_items.each do |tpi|
          AmortDetail.print_table(tpi.amort_details)
        end
      else
        AmortDetail.print_table(self.amort_details)
      end
    end

    # delete amort/amort_details for the fee.
    # _DO_NOT_ touch TPI level amorts/amort_details
    def delete_amorts
      self.amortizations.delete_all
    end

    def delete_amort_details
      self.amort_details.delete_all
    end

    # all amortizations and amort_details
    # that belongs to self and self.tpis
    def nuke_all_amorts
      delete_amorts
      delete_amort_details
      self.tranche_pegged_items.each do |tpi|
        tpi.delete_amorts
        tpi.delete_amort_details
      end
      self.reload
    end

    def calc_allowed?
      !self.financial_term.non_recourse_factoring? and
        !self.recognition_started?
    end

    def calc_and_save
      if !self.calc_allowed?
        msg = "#{self.class.to_s} ID: #{self.id} 不允许重算摊销。" +
          "可能已经开始确认摊销或已经进行了无追索保理。"
        Rails.logger.debug msg
        return
      end

      validate_amortization_settings # method defined in amort_setting.rb
      if self.errors.any?
        msg = "#{self.class.to_s} ID: #{self.id} 摊销设定非法。#{self.errors.full_messages}"
        Rails.logger.fatal msg
        raise msg
      end

      query_type = :fee_and_charge_amortization
      params = prepare_params

      json_data = nil
      if params.any?
        params_to_merge = { :fee => params }
        json_data =
          CalculationEngine.query(self.financial_term, query_type, params_to_merge)
      else
        json_data = {
          "scope"=> query_type
        }
      end

      # need it's own transaction handling since we have taken it out of AR's
      # #after_save callback.
      # ActiveRecord's #save/#after_save callback will handle the transcation for us.
      self.transaction do
        begin
          FinaTermCalcResultPopulator.perform(self, json_data)
        rescue Exception => e
          msg = "费用摊销计算出错: #{e.message}"
          self.errors.add(:base, msg)
          raise ActiveRecord::Rollback, msg
        end
      end
    end

    def query_calc_engine
      self.collection_tranche_pegged? ?
        get_tpi_amort_calc_result : get_fee_amort_calc_result
    end

    def delete_corresponding_amortizations
      category = self.class.to_s
      Amortization.delete_all({ :category => category, :fee_id => self.id,
                                :financial_term_id => self.financial_term.id })
    end

    # amortization summaries stored in Amortizatio table
    # NOTE: there is not defined relationship between fees and amortizaitons
    # This is different from amort_details, which have direct relationsbip with fees
    def amortizations
      Amortization.where({ :category => self.class.to_s, :fee_id => self.id,
                           :financial_term_id => self.financial_term.id })
    end

    def prepare_params(include_amort_details = true)
      if self.collection_tranche_pegged?
        prepare_tpi_amort_params(include_amort_details)
      else
        prepare_fee_amort_params(include_amort_details)
      end
    end

    private
    def prepare_fee_amort_params(include_amort_details)
      prepare_amort_params(self, include_amort_details)
    end

    def prepare_tpi_amort_params(include_amort_details = false)
      tpi_params = []
      self.tranche_pegged_items.each do |tpi|
        next if tpi.not_amortized?
        tpi_params <<  prepare_amort_params(tpi, include_amort_details)
      end
      tpi_params
    end

    # target can be:
    #   - fee (hangling_fee, etc.)
    #   - tranche_pegged_items for fee
    def prepare_amort_params(target, include_amort_details = false)
      amort_type = target.fee_amortization_type
      params = {}

      if !amort_type
        msg = "Error preparing amort params: fee_amortization_type not set: " <<
          " #{target.class.to_s} ID: #{target.id}"
        self.errors.add(:base, msg)
        return params
      end

      case amort_type.code.to_sym
      when :not_amortized
        return params
      when :interest_ratio
        # as long as the tranche is received (even partially, calc the amortization for
        # the full amount.

        vat_tax = false

        if target.instance_of? TranchePeggedItem
          vat_tax = target.tranche.financial_term.vat_tax?
        else
          vat_tax = target.financial_term.vat_tax?
        end

        amount_to_be_amortized = vat_tax? ? target.amount_excl_vat : target.amount

        if target.received_amount != 0.0
          params = {
            :type => target.class.to_s,
            :id => target.id,
            :amount => amount_to_be_amortized,
            :amortization_type => amort_type.code,
          }
        end
      when :straight_line_with_amount_and_duration_by_day,
          :straight_line_with_amount_and_duration_by_month
        # as long as the tranche is received (even partially, calc the amortization for
        # the full amortization_amount
        if target.received_amount != 0.00
          params = {
            :type => target.class.to_s,
            :id => target.id,
            :amount => target.amortization_amount,
            :amortization_type => amort_type.code,
            :amort_start_date => target.amortization_begin_date,
            :amort_end_date => target.amortization_end_date,
          }
        end
      else
        raise "系统不支持该中间业务收入摊销方式。"
      end

      if include_amort_details
        params[:old_amort_details] =
          FinaTermSerializer.serialize("amort_details", target)
        params[:recognition_end_date] = target.last_amort_recognition_date
      else
        params[:old_amort_details] = []
      end

      params
    end

    def amortized_income
      self.amortizations.where(:recognized => true).sum(:income)
    end
  end
end
