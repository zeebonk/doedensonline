class ConvertSqliteBooleansToIntegers < ActiveRecord::Migration[5.2]
  # The original SQLite conversion was applied before the PostgreSQL cutover.
  # All supported databases now use PostgreSQL, so retain only the migration
  # version for existing installations.
  def change; end
end
