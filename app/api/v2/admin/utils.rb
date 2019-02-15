# frozen_string_literal: true

module API
  module V2
    module Admin
      # helper module
      module Utils
        def search(field, value)
          case field
          when 'email'
            User.where("users.#{field} LIKE ?", "#{value}%")
          when 'first_name', 'last_name'
            User.joins(:profile).where("profiles.#{field} LIKE ?", "#{value}%")
          else
            User.all
          end.order('email ASC')
        end
      end
    end
  end
end
