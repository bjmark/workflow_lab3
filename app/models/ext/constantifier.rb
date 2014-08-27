# rails models based on ActiveRecord's constant tables in DB
# should extend include this to automatically have
#   to_constant
# as model's class method
module Ext
  module Constantifier
    # [
    #    [1, "arrear"],
    #    [2, "advance"]
    # ]
    # used to populate Ext JS association combo dropdown
    #def to_constant_store
    #  self.all.inject([]) do |arr, rec|
    #    arr.push([rec.id, rec[:text_cn] || rec[:name] || rec[:chinese_name] ])
    #  end
    #end

    # {
    #    1 => :arrear,
    #    2 => :advance
    # }
    # used to map constant ID to symbol, which is used in Razor
    def const_mapping
      mapping = {}
      self.all.each do |rec|
        mapping[rec.id.to_s] = rec.code
      end
      mapping
    end

    def const_mapping_code_to_id
      mapping = {}
      self.all.each do |rec|
        mapping[rec.code] = rec.id
      end
      mapping
    end

    def const_mapping_id_to_name
      mapping = {}
      self.all.each do |rec|
        mapping[rec.id] = rec.name
      end
      mapping
    end

    def const_mapping_code_to_name
      mapping = {}
      self.all.each do |rec|
        mapping[rec.code] = rec.name
      end
      mapping
    end
  end
end
