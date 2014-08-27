# encoding: utf-8
module FinaTermPrinter
  extend ActiveSupport::Concern

  module ClassMethods
  end

  module InstanceMethods
    def print_rental_structures
      RentalStructure.print_table(self.rental_structures)
    end

    def print_tranches
      Tranche.print_table(self.tranches)
    end

    def print_amorts(category)
      Amortization.print_table(self.amortizations.where(:category => category))
    end

    def print_amort_details(category)
      case category.to_sym
      when :Rental
        ads = self.rental_details.map(&:amort_details).flatten
      when :InterimInterest
        ads = self.ii_details.map(&:amort_details).flatten
      else
        puts "Amort details for category #{category} not available"
        return
      end

      AmortDetail.print_table(ads)
    end

    def print_provs(category)
      Provision.print_table(self.provisions.where(:category => category))
    end

    def print_iis
      InterimInterest.print_table(self.interim_interests)
    end

    def print_ii_details
      IiDetail.print_table(self.ii_details)
    end

    def print_rentals
      Rental.print_table(self.rentals)
    end

    def print_rental_details
      RentalDetail.print_table(self.rental_details)
    end

    def print_rental_details_and_amort_details(category)
      case category.to_sym
      when :Rental
        ads = self.rental_details.map(&:amort_details).flatten
        rs = self.rentals
      when :InterimInterest
        ads = self.ii_details.map(&:amort_details).flatten
        rs = self.interim_interests
      else
        puts "Amort details for category #{category} not available"
        return
      end

      header = []
      %w[
        rental.term
        rental.due_date
        rental.rental
        rental.interest
        rental.principal
        rental.closing_principal
        rental.yearly_rate
        rental.days
        rental.start_date
        rental.end_date
        amortization.post_date
        amortization.income
      ].each do |field|
        header << I18n.t("formtastic.labels.#{field}")
      end
      puts header.join(",")

      data_rd = nil
      data_ad = nil
      rs.each do |rd|
        ads.each do |ad|
          if data_ad and rd.due_date
            if rd.due_date.to_date > ad.end_date.to_date and !data_rd
              puts ",,,,,,," +
                "#{data_ad.days.to_s}," <<
                "#{data_ad.start_date.to_s}," <<
                "#{data_ad.end_date.to_s}," <<
                "#{data_ad.amort_date.to_s}," <<
                "#{data_ad.income.to_s}"
            elsif data_rd and
              rd.due_date.to_date > ad.end_date.to_date and
              data_rd.due_date.to_date < ad.end_date.to_date and
              rd.due_date.to_date > data_ad.end_date.to_date and
              data_rd.due_date.to_date < data_ad.end_date.to_date
              puts ",,,,,,,"+
                "#{data_ad.days.to_s}," <<
                "#{data_ad.start_date.to_s}," <<
                "#{data_ad.end_date.to_s}," <<
                "#{data_ad.amort_date.to_s}," <<
                "#{data_ad.income.to_s}"
            elsif rd.due_date.to_date < ad.end_date.to_date and data_rd
              puts "#{rd.term.to_s}," <<
                "#{rd.due_date.to_s}," <<
                "#{rd.rental.to_s}," <<
                "#{category.to_sym == :Rental ? rd.interest : 0}," <<
                "#{rd.principal.to_s}," <<
                "#{category.to_sym == :Rental ? rd.closing_principal : 0}," <<
                "#{category.to_sym == :Rental ? rd.yearly_rate : 0}," <<
                "#{data_ad.days.to_s}," <<
                "#{data_ad.start_date.to_s}," <<
                "#{data_ad.end_date.to_s}," <<
                "#{data_ad.amort_date.to_s}," <<
                "#{data_ad.income.to_s}"
              break
            end
          end
          data_ad = ad
        end
        data_rd = rd
      end

      puts "#{data_rd.term.to_s}," <<
        "#{data_rd.due_date.to_s}," <<
        "#{data_rd.rental.to_s}," <<
        "#{category.to_sym == :Rental ? data_rd.interest : 0}," <<
        "#{data_rd.principal.to_s}," <<
        "#{category.to_sym == :Rental ? data_rd.closing_principal : 0}," <<
        "#{category.to_sym == :Rental ? data_rd.yearly_rate : 0}," <<
        "#{data_ad.days.to_s}," <<
        "#{data_ad.start_date.to_s}," <<
        "#{data_ad.end_date.to_s}," <<
        "#{data_ad.amort_date.to_s}," <<
        "#{data_ad.income.to_s}"
    end

    def print_receivables
      Receivable.print_table(self.receivables)
    end

    def print_settlements
      Settlement.print_table(self.receivables.map(&:settlements).flatten)
    end

    # print info regarding financial_events
    def print_fina_events
      return if self.financial_events.empty?

      puts "ID\t日期\t\t类型"
      self.financial_events.order(:event_date).each do |fe|
        pretty_json = JSON.pretty_generate(JSON.parse(fe.change_in_json))
        puts "#{fe.id}\t#{fe.event_date}\t#{fe.financial_event_type.name}"
        puts "明细: \n#{pretty_json}"
        puts
      end

      nil
    end

    # print only the significant financial params to be used in CalcEngine directly
    def print_params
      white_list = [
        :finance_terms_in_months,
        :financed_amount,
        :ii_yearly_rate,
        :interest_calculation_type_id,
        :payment_type_id,
        :interest_only_terms,
        :number_of_advanced_months,
        :rate_adjustment_type_id,
        :rate_type_id,
        :rental_calculation_type_id,
        :rental_due_day_id,
        :rental_frequency_id,
        :rv_amount,
        :rv_type_id,
        :start_date,
        :terms_in_months,
        :turnover_tax_type_id,
        :yearly_rate
      ]

      attrs =
        self.attributes.delete_if { |k, v| v.nil? or !white_list.include?(k.to_sym) }
      params_hash = {}

      attrs.each do |k, v|
        if k == "start_date"
          params_hash[k.to_sym] = v.to_s
          next
        end

        match = k.match(/(.+)_id$/)
        if match
          klass = match[1].classify.constantize
          params_hash[match[1].to_sym] = klass.find(v).code.to_sym
        else
          params_hash[k.to_sym] = v
        end
      end

      params_hash[:rental_due_day] = params_hash[:rental_due_day].to_s.to_i

      ap params_hash
      nil
    end
  end
end
