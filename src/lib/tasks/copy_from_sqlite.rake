# rubocop:disable-next Metrics/BlockLength
namespace :db do
  desc 'Copy a legacy SQLite database into an empty PostgreSQL database'
  task copy_from_sqlite: :environment do
    previous_logger = ActiveRecord::Base.logger
    previous_migration_verbosity = ActiveRecord::Migration.verbose
    ActiveRecord::Base.logger = nil
    ActiveRecord::Migration.verbose = false

    sqlite_path = ENV.fetch('SQLITE_PATH', nil)
    unless sqlite_path && File.file?(sqlite_path)
      puts "SQLite database not found at #{sqlite_path || '(unset)'}; skipping copy."
      next
    end

    target_connection = ApplicationRecord.connection
    application_tables = target_connection.tables - %w[ar_internal_metadata schema_migrations]
    target_has_data = application_tables.any? do |table|
      target_connection.select_value("SELECT COUNT(*) FROM #{target_connection.quote_table_name(table)}").positive?
    end
    if target_has_data
      puts 'PostgreSQL already contains application data; skipping copy.'
      next
    end

    sqlite_record = CopyFromSqliteRecord
    sqlite_record.establish_connection(adapter: 'sqlite3', database: sqlite_path)
    source_connection = sqlite_record.connection

    # The target is empty, so loading the schema is safe. It also makes the
    # task work when the PostgreSQL image has just initialised its database.
    load Rails.root.join('db/schema.rb')
    tables = target_connection.tables - %w[ar_internal_metadata schema_migrations]

    ordered_tables = []
    visited_tables = {}
    visit = lambda do |table|
      next if visited_tables[table]

      visited_tables[table] = true
      target_connection.foreign_keys(table).each do |foreign_key|
        visit.call(foreign_key.to_table) if tables.include?(foreign_key.to_table)
      end
      ordered_tables << table
    end
    tables.sort.each { |table| visit.call(table) }

    target_connection.transaction do
      ordered_tables.each do |table|
        raise "SQLite database is missing expected table #{table}" unless source_connection.table_exists?(table)

        source_model = sqlite_record
        source_model.table_name = table
        source_model.reset_column_information
        target_model = CopyToPostgresqlRecord
        target_model.table_name = table
        target_model.reset_column_information
        column_names = source_model.column_names

        source_model.in_batches(of: 500) do |batch|
          rows = batch.map { |record| record.attributes.slice(*column_names) }
          target_model.insert_all!(rows, record_timestamps: false) if rows.any?
        end

        source_count = source_model.count
        target_count = target_model.count
        raise "Row count mismatch for #{table}: SQLite=#{source_count}, PostgreSQL=#{target_count}" unless source_count == target_count

        target_connection.reset_pk_sequence!(table)
        puts "Copied #{table}: #{target_count} rows"
      end
    end
  ensure
    ActiveRecord::Base.logger = previous_logger
    ActiveRecord::Migration.verbose = previous_migration_verbosity
    sqlite_record&.remove_connection
  end
end
