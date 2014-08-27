module ActiveModel
  class Errors
    def flattened_messages
      self.full_messages.join(" ")
    end
  end
end
