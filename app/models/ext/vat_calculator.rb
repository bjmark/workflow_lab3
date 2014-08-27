# -*- encoding: utf-8 -*-
module Ext
  module VatCalculator
    extend self

    # given total, split into excl_vat and vat
    def calc(amount, vat_rate = 17.00)
      amount_excl_vat =
        (amount / (1.00 + vat_rate/100.00)).round_to
      amount_vat = (amount - amount_excl_vat).round_to

      [amount_excl_vat, amount_vat]
    end

    # given excl_vat, get total and vat part
    def reverse_calc(amount_excl_vat, vat_rate = 17.00)
      total = (amount_excl_vat * (1.00 + vat_rate / 100.00)).round_to
      amount_vat = (total - amount_excl_vat).round_to

      [total, amount_vat]
    end
  end
end
