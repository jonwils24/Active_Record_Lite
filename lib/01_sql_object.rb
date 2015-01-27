require_relative 'db_connection'
require 'active_support/inflector'

class SQLObject
  def self.columns #returns an array of the column names, class method
    return @columns if @columns
    cols = DBConnection.execute2(<<-SQL)
    SELECT
      *
    FROM
      #{self.table_name}
    SQL
    cols = cols.first
    cols.map! { |col| col.to_sym }
    @columns = cols
  end

  def self.finalize! #creates getter and setter methods for each col name
    self.columns.each do |name|
      define_method(name) do #class scope
        self.attributes[name] #instance scope
      end

      define_method("#{name}=") do |value| #class scope
        self.attributes[name] = value #instance scope
      end
    end
  end

  def self.table_name=(table_name)#creates setter for table_name
    @table_name = table_name #class scope, class instance variable
  end

  def self.table_name
    @table_name || self.name.underscore.pluralize #class instance variable/scope
  end

  def self.all #
    select_all = DBConnection.execute(<<-SQL)
    SELECT
      #{table_name}.*
    FROM
      #{table_name}
    SQL
    parse_all(select_all)
  end

  def self.parse_all(results)
    results.map { |result| self.new(result)}
  end

  def self.find(id)
    select_one = DBConnection.execute(<<-SQL, id)
    SELECT
      #{table_name}.*
    FROM
      #{table_name}
    WHERE
      id = (?)
    SQL
    parse_all(select_one).first
  end

  def attributes
    @attributes ||= {}
  end

  def insert #instance
    col_names = self.class.columns.map(&:to_s).join(", ")
    n = self.class.columns.count
    question_marks = (["?"] * n).join(", ")
    
    DBConnection.execute(<<-SQL, *attribute_values)
    INSERT INTO
      #{self.class.table_name} (#{col_names})
    VALUES
      (#{question_marks})
    SQL
    self.id = DBConnection.last_insert_row_id
  end

  def initialize(params = {})
    params.each do |name, value|
      if self.class.columns.include?(name.to_sym)
        self.send("#{name.to_sym}=", value)
      else
        raise "unknown attribute '#{name}'" 
      end
    end
  end

  def save
    if self.id.nil?
      self.insert
    else
      self.update
    end
  end

  def update
    col_names = self.class.columns.map(&:to_s)
    attr_name = col_names.map { |col| "#{col} = ?"}.join(", ")
    
    DBConnection.execute(<<-SQL, *attribute_values, id)
    UPDATE
      #{self.class.table_name}
    SET
      #{attr_name}
    WHERE
      id = ?
    SQL
  end

  def attribute_values
    self.class.columns.map {|column| self.send(column) }
  end
end
