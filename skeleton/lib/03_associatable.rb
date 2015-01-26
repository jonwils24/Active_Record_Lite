require_relative '02_searchable'
require 'active_support/inflector'

# Phase IIIa
class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    @class_name.constantize
  end

  def table_name
    model_class.table_name
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    default_options = {
      foreign_key: ("#{name}_id").to_sym,
      class_name: ("#{name}").camelcase,
      primary_key: ("id").to_sym
    }
    
    default_options.keys.each do |key|
      self.send("#{key}=", options[key] || default_options[key])
    end
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    default_options = {
      foreign_key: ("#{self_class_name}_id").underscore.to_sym,
      class_name: ("#{name}").camelcase.singularize,
      primary_key: ("id").to_sym
    }
    
    default_options.keys.each do |key|
      self.send("#{key}=", options[key] || default_options[key])
    end
  end
end

module Associatable
  # Phase IIIb
  def belongs_to(name, options = {})
    assoc_options[name] = BelongsToOptions.new(name, options)
    
    define_method(name) do
      options = self.class.assoc_options[name]
      key_val = self.send(options.foreign_key)
      options
        .model_class
        .where(options.primary_key => key_val)
        .first
      
    end
  end

  def has_many(name, options = {})
    self.assoc_options[name] = HasManyOptions.new(name, self.name, options)

    define_method(name) do
      options = self.class.assoc_options[name]

      key_val = self.send(options.primary_key)
      options
        .model_class
        .where(options.foreign_key => key_val)
    end
  end

  def assoc_options
<<<<<<< HEAD:lib/active_record_lite/03_associatable.rb
    @assoc_options ||= {}
=======
    # Wait to implement this in Phase IVa. Modify `belongs_to`, too.
>>>>>>> c5160b6f944d6087ae431e1310f98297a5d35bab:skeleton/lib/03_associatable.rb
  end
end

class SQLObject
  extend Associatable
end
