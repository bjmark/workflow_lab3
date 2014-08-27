# -*- encoding: utf-8 -*-
# module for getting all kinds of numbers: total/receivable/settlement/fee-related
module Ext
  module CurrentNumbers
    extend ActiveSupport::Memoizable
    extend self

    def amort_total(category)
      amort_total = {
        :days => 0,
        :income => 0.0
      }

      if self.instance_of? FinancialTerm
        amorts = self.amortizations
      else
        amorts = self.financial_term.amortizations
      end

      amorts.each do |amort|
        next if amort.category != category.to_s
        amort_total.keys.each do |k|
          amort_total[k] += amort.send(k.to_s) if !amort.send(k.to_s).nil?
        end
      end

      amort_total.keys.each do |key|
        amort_total[key] = amort_total[key].round_to
      end

      amort_total
    end

    def amort_detail_total(category)
      total = 0.0

      association =
        case category.to_sym
        when :interest
          self.rental_details
        when :interim_interest
          self.ii_details
        when :other_fee
          self.other_fees
        when :management_fee
          self.management_fees
        when :handling_fee
          self.handling_fees
        when :commission
          # since we are expecting an array
          self.commission ? [self.commission] : []
        when :consulting_fee
          self.consulting_fees
        else
          raise "摊销明细种类名称不对: #{category}"
        end

      association.map(&:amort_details).flatten.each do |amort_detail|
        total += amort_detail.income
      end

      total.round_to
    end

    def settled_principal
      self.rental_receivable_settlements.map(&:principal).reduce(0.0, &:+).round_to
    end

    def settled_interests
      rental_settlements = self.rental_receivable_settlements
      get_settled_int_totals(rental_settlements)
    end

    def settled_amfs
      amf_receivables = self.receivables.where({
        :category => 'AssetManagementFee',
        :owner_type => 'Rental'
      })
      settlements = amf_receivables.map(&:settlements).compact.flatten

      get_settled_amf_totals(settlements)
    end

    def rental_total(association = 'rentals')
      total = {
        :days => 0,
        :principal => 0.0,
        :interest => 0.0,
        :rental_excl_vat => 0.0,
        :rental_vat => 0.0,
        :interest_excl_vat => 0.0,
        :interest_vat => 0.0,
        :principal_excl_vat => 0.0,
        :principal_vat => 0.0,
        :rental => 0.0
      }

      self.send(association).each do |rt|
        total.keys.each do |k|
          if !rt.send(k.to_s).nil?
            total[k] += rt.send(k.to_s)
          end
        end
      end

      total.keys.each do |key|
        total[key] = total[key].round_to
      end

      total
    end

    def ii_total
      total = {
        :days => 0,
        :interim_interest => 0.0,
        :ii_excl_vat => 0.0,
        :ii_vat => 0.0
      }

      iis_list = self.respond_to?(:iis_to_show) ? iis_to_show : self.financial_term.iis_to_show
      iis_list.each do |ii|
        total.keys.each do |k|
          total[k] += ii.send(k.to_s) if !ii.send(k.to_s).nil?
        end
      end

      total.keys.each do |key|
        total[key] = total[key].round_to
      end

      total
    end

    def ii_receivables
      self.interim_interests.map(&:receivable).compact.flatten
    end

    def ii_receivable_settlements
      self.ii_receivables.map(&:settlements).compact.flatten
    end

    def rental_receivables
      self.rentals.map(&:receivable).compact.flatten
    end

    def rental_receivable_settlements
      self.rental_receivables.map(&:settlements).compact.flatten
    end

    # type can only be:
    #   :principal
    #   :interest
    def receivable_total(type)
      rental_receivable_settlements.map(&type).compact.reduce(0.0, &:+).round_to
    end

    def receivable_ii_total
      ii_receivable_settlements.map(&:settled_amount).compact.reduce(0.0, &:+).round_to
    end

    def receivable_principal_total
      receivable_total(:principal)
    end

    def receivable_interest_totals
      get_settled_int_totals(rental_receivable_settlements)
    end

    def amf?
      self.instance_of? AssetManagementFee
    end

    # association: from the stand of point of FinancialTerm
    # - handling_fees, etc.
    def fee_total(association)
      return 0.0 if self.amf?
      self.send(association).map(&:amount).compact.reduce(0.0, &:+).round_to
    end

    def settled_fee(association)
      return 0.0 if self.amf?
      settled_amount(fee_receivables(association))
    end

    def unsettled_fee(association)
      return 0.0 if self.amf?
      fee_total(association) - settled_fee(association)
    end

    # - security_deposits
    def sd_total(sd_type)
      return 0.0 if self.amf?
      select_sd_type(sd_type).map(&:amount).compact.reduce(0.0, &:+).round_to
    end

    def settled_sd(sd_type)
      return 0.0 if self.amf?
      settled_amount(sd_receivables(sd_type))
    end

    def unsettled_sd(sd_type)
      return 0.0 if self.amf?
      (sd_total(sd_type) - settled_sd(sd_type)).round_to
    end

    #memoize :rental_total, :ii_total
    #memoize :rental_receivables, :rental_receivable_settlements, :receivable_total
    #memoize :ii_receivables, :ii_receivable_settlements
    #memoize :receivable_principal_total, :receivable_interest_total, :receivable_ii_total

    #memoize :fee_total, :settled_fee, :unsettled_fee
    #memoize :sd_total, :settled_sd, :unsettled_sd

    protected
    # with VAT fields if available
    def get_settled_amf_totals(settlements)
      amt = 0.00
      amt_excl_vat = 0.00
      amt_vat = 0.00

      settlements.each do |s|
        amt += s.settled_amount
        amt_excl_vat += s.amount_excl_vat.to_f
        amt_vat += s.amount_vat.to_f
      end

      [amt.round_to, amt_excl_vat.round_to, amt_vat.round_to]
    end

    # Rental interest VAT split in settlements is stored
    # differently from AMF and fees. Please see
    # settlement.rb's comments
    def get_settled_int_totals(settlements)
      amt = 0.00
      amt_excl_vat = 0.00
      amt_vat = 0.00

      settlements.each do |s|
        amt_excl_vat += s.interest.to_f
        amt_vat += s.interest_vat.to_f
        amt += (s.interest.to_f + s.interest_vat.to_f)
      end

      [amt.round_to, amt_excl_vat.round_to, amt_vat.round_to]
    end

    def settled_amount(receivables)
      receivables.map(&:settlements).flatten.map(&:settled_amount).reduce(0.0, &:+).round_to
    end

    def select_sd_type(sd_type)
      SecurityDeposit.select_type(self.security_deposits, sd_type)
    end

    def fee_receivables(fee_type)
      self.send(fee_type).map(&:fee_collection_schedules).flatten.map(&:receivable)
    end

    def sd_receivables(sd_type)
      select_sd_type(sd_type).map(&:fee_collection_schedules).flatten.map(&:receivable)
    end
  end
end
