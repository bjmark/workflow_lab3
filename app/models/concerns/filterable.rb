# Call scopes directly from your URL params:
#
# In controller:
#   @products = Product.filter_by_scope(params.slice(:status, :location, :starts_with))
#
# In model:
#   class Product < ActiveRecord::Base
#     ... after all association defs
#
#     include Filterable
#     ...
#   end
#
module Filterable
  extend ActiveSupport::Concern

  module ClassMethods
    # the idea is to move the #search method defined in individual
    # model class into this concern
    # NOTE: fields are matched using SQL LIKE and OR
    #
    # :search by is a class macro just like ActiveRecord's :has_many
    # Usage: add the following in the AR model def
    #
    # class Proejct < ActiveRecord::Base
    #   ... after all association defs
    #   include Filterable
    #   search_by :name, :number
    # ...
    # end
    #
    # for example (from Quote model)
    # In model:
    #   ... after all association defs
    #   include Filterable
    #   search_by :name, :associations => [:users]
    #
    #
    # which should translate to:
    # def self.search(search)
    #   if search.nil?
    #     scoped
    #   else
    #     joins('LEFT JOIN users ON users.id = quotes.user_id').
    #       where('quotes.name like ? or users.name like ?',
    #         "%#{URI.decode(search)}%", "%#{URI.decode(search)}%")
    #   end
    # end
    #
    def search_by(*argv)
      # define a class method
      define_singleton_method('search') do |search|
        # puts "in #{self.name} - ARGV: #{argv}"
        return scoped if search.blank?

        match_fields = argv
        associations_used_in_search = []
        if argv.last.instance_of? Hash
          # NOTE: CANNOT use #pop here. Need to preserve the *argv
          associations_used_in_search = argv.last[:associations]
          match_fields = argv.slice(0..-2)
        end
        match_fields = [:name] if match_fields.empty?

        condition = match_fields.map { |f| "#{self.table_name}.#{f} LIKE ?" }.join(' OR ')
        term = ["%#{URI.decode(search)}%"] * match_fields.size
        final_arel = where(condition, *term)

        associations_used_in_search.each do |association|
          corresponding_association = self.reflect_on_all_associations.
            find { |a| a.name == association.to_sym}

          if !corresponding_association
            raise "Invalid search_by arguments: association #{association} not found"
          end

          pk = self.primary_key
          # NOTE: need to use the :primary_key_name to get the :foreign_key
          fk = corresponding_association.primary_key_name

          join_table_class = corresponding_association.options[:class_name]

          join_table = join_table_class ? join_table_class.constantize.table_name :
            corresponding_association.name.to_s.classify.constantize.table_name

          on_condition = "#{self.table_name}.#{fk} = #{join_table}.#{pk}"
            # puts "SQL: " << self.joins("LEFT JOIN #{join_table} ON #{on_condition}").
            #   merge(join_table.classify.constantize.search(search)).to_sql
            final_arel |= self.joins("LEFT JOIN #{join_table} ON #{on_condition}").
              merge(join_table.classify.constantize.search(search))
        end

        final_arel
      end
    end

    # Call the class methods with the same name as the keys in <tt>filtering_params</tt>
    # with their associated values. Most useful for calling named scopes from
    # URL params. Make sure you don't pass stuff directly from the web without
    # whitelisting only the params you care about first!
    # conditions in params are AND'ed to reach the final result
    def filter_by_scopes(filtering_params)
      results = self.none  # AdtiveRecord::Base monkey patched in ext/base.rb
      filtering_params.each do |key, value|
        results = results.public_send(key, value) if value.present?
      end

      results
    end

    # conditions in params are AND'ed to reach the final result
    def filter_by_fields(filter = {})
      results = self.none
      filter.each do |key, value|
        results = results.where("#{key} like ?", "%#{value}%") if value.present?
      end

      results
    end
  end
end
