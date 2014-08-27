module ActiveRecord
  class Base
    # backporting of Rails 4's :none scope
    def self.none
      where(arel_table[:id].eq(nil).and(arel_table[:id].not_eq(nil)))
    end

    # for example, in FinancialTerm model:
    #   ft.set_association_by_code(:rate_adjustment_type, :next_term)
    def set_association_by_code(association, code)
      return set_association_by(association, :code, code)
    end

    def set_association_by_name(association, name)
      set_association_by(association, :name, name)
    end

    def update_association_by_code(association, code)
      return update_association_by(association, :code, code)
    end

    def update_association_by_code!(association, code)
      return update_association_by!(association, :code, code)
    end

    def update_association_by_name(association, name)
      return update_association_by(association, :name, name)
    end

    def update_association_by_name!(association, name)
      return update_association_by!(association, :name, name)
    end

    # calls AR's Class#update_all(attr_hash, { :id => <id> }), which
    # by passes AR validation and callbacks
    def sql_update_association_by_code(association, code)
      association_hash = gen_attr_hash_for_sql_update_association_by_code(association, code)
      self.class.update_all(association_hash, {:id => self.id })
    end

    def gen_attr_hash_for_sql_update_association_by_code(association, code)
      association_column = "#{association}_id".to_sym
      klass = association.to_s.pluralize.classify.constantize
      { association_column => klass.find_by_code(code).id }
    end

    def sql_update(attr_hash)
      self.class.update_all(attr_hash, { :id => self.id })
    end

    def status_eql?(status_column, status_value)
      sts = self.send(status_column)
      sts and sts.code == status_value.to_s
    end

    private
    def set_association_by(association, attr, val)
      association = association.to_s

      # classify expects a ActiveRecord table name,
      # which is a plural.
      klass = association.pluralize.classify.constantize
      self.send("#{association}=", klass.where(attr.to_s => val.to_s).first)
    end

    def gen_association_update_hash(association, attr, val)
      association = association.to_s
      klass = association.pluralize.classify.constantize

      { "#{association}" => klass.where(attr.to_s => val.to_s).first }
    end

    def update_association_by(association, attr, val)
      self.update_attributes(gen_association_update_hash(association, attr, val))
    end

    def update_association_by!(association, attr, val)
      self.update_attributes!(gen_association_update_hash(association, attr, val))
    end
  end
end
