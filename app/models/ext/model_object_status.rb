# handles model object status related concerns
# for example, project's status
# NOTE: this is separate from Workflow's target's
# workflow status, which is handled in WorkflowTarget module
#
# Usage:
# In model:
#   class Project
#     include ::ModelObjectStatus
#     ...
#    end
#
module ModelObjectStatus
  extend ActiveSupport::Concern

  module ClassMethods
  end

  # matching_status: a single string/symbol
  # or array of strings/symbols (to be OR'd)
  def status_is?(status_name, *matching_status)
    st = self.send(status_name)
    if !st or !st.code
      return false
    end

    [matching_status].flatten.map(&:to_sym).include?(st.code.to_sym)
  end
end
