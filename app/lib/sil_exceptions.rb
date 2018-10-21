# frozen_string_literal: true

module SilExceptions
  # Raised when trying to add/update an invalid Scale Question.
  # It occurrs when ScaleData document is different than 2.
  class InvalidQuantityToLocate < StandardError
    def initialize
        super(I18n.t('custom_errors.warehouse_location.invalid_quantity_to_locate'))
    end
  end

  class InvalidQuantityToAdd < StandardError
    def initialize
        super(I18n.t('custom_errors.inventory_item.invalid_quantity_to_add'))
    end
  end

  class ItemNotInLocation < StandardError
    def initialize
        super(I18n.t('custom_errors.inventory_item.invalid_quantity_to_add'))
    end
  end
  
  class InvalidQuantityToRelocate < StandardError
    def initialize
        super(I18n.t('custom_errors.warehouse_location.invalid_quantity_to_relocate'))
    end
  end
end
