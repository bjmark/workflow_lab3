# encoding: utf-8
module Ext
  module Printer
    extend self

    TRANCHE_FIELDS = %w[
      disbursement_date
      amount
      disbursed?
      payee
    ]

    RENTAL_STRUCTURE_FIELDS = %w[
      term
      principal_amount
    ]

    RENTAL_FIELDS = %w[
      term
      days
      start_date
      end_date
      due_date
      opening_principal
      rental
      interest
      interest_excl_vat
      interest_vat
      principal
      closing_principal
      yearly_rate
      interest_diff_from_last_term
      int_diff_excl_vat_from_last_term
      int_diff_vat_from_last_term
    ]

    INTERIM_INTEREST_FIELDS = %w[
      term
      days
      start_date
      end_date
      due_date
      cumulative_disbursement
      interim_interest
      ii_excl_vat
      ii_vat
      rate
      ii_diff_from_last_term
      ii_diff_excl_vat_from_last_term
      ii_diff_vat_from_last_term
    ]

    AMORT_FIELDS = %w[
      days
      start_date
      end_date
      post_date
      income
      recognized
    ]

    AMORT_DETAIL_FIELDS = %w[
      days
      start_date
      end_date
      amort_date
      income
      recognized
    ]

    PROV_FIELDS = %w[
      days
      start_date
      end_date
      amort_date
      outstanding_principal
      outstanding_interest
      receivable_total
      remaining_receivable
      unrecognized_income
      provision_amount
      previous_total
      current_total
      special_provision_amount
      previous_special_total
      current_special_total
      provision_sum
    ]

    RECEIVABLE_FIELDS = %w[
      owner_type
      amount
      due_date
      settled_amount
      amount_excl_vat
      amount_vat
      interest_excl_vat
      interest_vat
    ]

    SETTLEMENT_FIELDS = %w[
      settled_date
      settled_amount
      principal
      interest
      amount_excl_vat
      amount_vat
      interest_vat
    ]

    module ClassMethods
      def print_header_line
        header_line = ""
        case self.to_s
        when "RentalStructure"
          fields = RENTAL_STRUCTURE_FIELDS
          lookup_prefix = "rental_structure"
        when "Tranche"
          fields = TRANCHE_FIELDS
          lookup_prefix = "tranche"
        when "Rental", "RentalDetail",
          "RentalHistory", "RentalDetailHistory"
          fields = RENTAL_FIELDS
          lookup_prefix = "rental"
        when "InterimInterest", "IiDetail",
          "InterimInterestHistory", "IiDetailHistory"
          fields = INTERIM_INTEREST_FIELDS
          lookup_prefix = "interim_interest"
        when "Amortization", "AmortizationHistory"
          fields = AMORT_FIELDS
          lookup_prefix = "amortization"
        when "AmortDetail", "AmortDetailHistory"
          fields = AMORT_DETAIL_FIELDS
          lookup_prefix = "amortization"
        when "Provision", "ProvisionHistory"
          fields = PROV_FIELDS
          lookup_prefix = "provision"
        when "Receivable"
          fields = RECEIVABLE_FIELDS
          lookup_prefix = "receivable"
        when "Settlement"
          fields = SETTLEMENT_FIELDS
          lookup_prefix = "settlement"
        else
          raise "#{self} print out NOT supported."
        end

        fields.each do |field|
          header_line <<
            I18n.t("formtastic.labels.#{lookup_prefix}.#{field}") << "\t"
        end
        puts header_line
      end

      # col: rentals/iis/amorts and *_details, provisions, etc
      def print_totals(col)
        return if col.empty?

        case col.first.class.to_s
        when "RentalStructure"
          lookup_prefix = "rental_structure"
          total_fields = %w[principal_amount]
        when "Tranche"
          lookup_prefix = "tranche"
          total_fields = %w[amount]
        when "Rental", "RentalDetail",
          "RentalHistory", "RentalDetailHistory"
          lookup_prefix = "rental"
          total_fields = %w[
            rental
            interest
            interest_excl_vat
            interest_vat
            principal
          ]
        when "InterimInterest", "IiDetail",
          "InterimInterestHistory", "IiDetailHistory"
          lookup_prefix = "interim_interest"
          total_fields = %w[
            interim_interest
            ii_excl_vat
            ii_vat
          ]
        when "Amortization", "AmortizationHistory"
          lookup_prefix = "amortization"
          total_fields = %w[income]
        when "AmortDetail", "AmortDetailHistory"
          lookup_prefix = "amortization"
          total_fields = %w[income]
        when "Provision", "ProvisionHistory"
          lookup_prefix = "provision"
          total_fields = %w[
            provision_amount
            special_provision_amount
            provision_sum
          ]
        when "Receivable"
          lookup_prefix = "receivable"
          total_fields = %w[
            amount
            settled_amount
            amount_excl_vat
            amount_vat
            interest_excl_vat
            interest_vat
          ]
        when "Settlement"
          lookup_prefix = "settlement"
          total_fields = %w[
            settled_amount
            principal
            interest
            interest_vat
            amount_excl_vat
            amount_vat
          ]
        else
          raise "#{self} print out NOT supported."
        end

        puts
        puts "合计"
        puts "===="
        total_fields.each do |field|
          total = col.map(&field.to_sym).compact.reduce(&:+)
          puts I18n.t("formtastic.labels.#{lookup_prefix}.#{field}") <<
            ": \t" << total.round_to_str
        end
      end

      def print_table(col)
        print_header_line
        col.each do |r|
          r.print_fields
        end
        print_totals(col)
        nil
      end
    end

    # extend host class with class methods when we're included
    def self.included(host_class)
      host_class.extend(ClassMethods)
    end

    def print_fields
      case self.class.to_s
      when "RentalStructure"
        fields = RENTAL_STRUCTURE_FIELDS
      when "Tranche"
        fields = TRANCHE_FIELDS
      when "Rental", "RentalDetail",
        "RentalHistory", "RentalDetailHistory"
        fields = RENTAL_FIELDS
      when "InterimInterest", "IiDetail",
        "InterimInterestHistory", "IiDetailHistory"
        fields = INTERIM_INTEREST_FIELDS
      when "Amortization", "AmortizationHistory"
        fields = AMORT_FIELDS
      when "AmortDetail", "AmortDetailHistory"
        fields = AMORT_DETAIL_FIELDS
      when "Provision", "ProvisionHistory"
        fields = PROV_FIELDS
      when "Receivable"
        fields = RECEIVABLE_FIELDS
      when "Settlement"
        fields = SETTLEMENT_FIELDS
      else
        raise "#{self} print out NOT supported."
      end
      rec = ""
      fields.each do |field|
        value = self.send(field)

        # for cases like: tranche.payee
        value = value.try(:name) if value.respond_to?(:name)

        rec << (value.instance_of?(BigDecimal) ?  value.round_to_str : "#{value}")
        rec << "\t"
      end
      puts rec
    end
  end
end
