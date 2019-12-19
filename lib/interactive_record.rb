require_relative "../config/environment.rb"
require 'active_support/inflector'

class InteractiveRecord
  def initialize(options={})
    options.each do |property, value|
      self.send("#{property}=", value)
    end
  end

  def self.table_name
    self.to_s.downcase.pluralize
  end

  def self.column_names
    DB[:conn].results_as_hash = true

    sql = <<-SQL
      PRAGMA table_info('#{table_name}')
    SQL

    column_names = []
    DB[:conn].execute(sql).map do |column|
      column_names << column["name"]
  end

    column_names.compact
  end

  def table_name_for_insert
    self.class.table_name
  end

  def col_names_for_insert
    self.class.column_names.delete_if {|col| col == "id"}.join(", ")
  end

  def values_for_insert
    values = []
    self.class.column_names.each do |col_name|
      values << "'#{send(col_name)}'" unless send(col_name).nil?
    end
    values.join(", ")
  end

  def save
    sql = <<-SQL
      INSERT INTO #{self.table_name_for_insert} (#{self.col_names_for_insert})
      VALUES (#{values_for_insert});
    SQL
    DB[:conn].execute(sql)
    @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
  end

  def self.find_by_name(name)
    sql = <<-SQL
      SELECT * FROM #{table_name} WHERE name = ?;
    SQL
    DB[:conn].execute(sql,name)
  end

  def self.find_by(options)
    properties = []
    values = []
    options.each do |property, value|
      properties << "#{property} = ?"
      if value.is_a?(Integer)
        values << value
      else
        values << "#{value}"
      end
  end

    properties = properties.join(" and ")
    values = values.join(",")

    sql = <<-SQL
      SELECT * FROM #{table_name} WHERE #{properties}
    SQL
    DB[:conn].execute(sql,values)
  end
end