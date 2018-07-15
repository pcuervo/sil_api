# frozen_string_literal: true

module SilExceptions
  # Error raised when trying to add/update an invalid Scale Question.
  # It occurrs when ScaleData document is different than 2.
  class InvalidQuantityToLocate < StandardError
    def initialize
        super(I18n.t('custom_errors.warehouse_location.invalid_quantity_to_locate'))
    end
  end
end
