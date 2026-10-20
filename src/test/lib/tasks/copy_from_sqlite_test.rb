require 'test_helper'
require 'fileutils'
require 'sqlite3'

Rake::Task.define_task(:environment) unless Rake::Task.task_defined?(:environment)
load Rails.root.join('lib/tasks/copy_from_sqlite.rake') unless Rake::Task.task_defined?('db:copy_from_sqlite')

class CopyFromSqliteTest < ActiveSupport::TestCase
  self.use_transactional_tests = false
  self.fixture_table_names = []
  self.fixture_sets = {}

  setup do
    @sqlite_path = Rails.root.join('tmp/copy-from-sqlite-test.sqlite3')
    FileUtils.rm_f(@sqlite_path)
    clear_postgresql_database
  end

  teardown do
    FileUtils.rm_f(@sqlite_path)
    clear_postgresql_database
  end

  test 'copies explicit ids, booleans, and timestamps' do
    create_sqlite_database
    run_copy_task

    user = User.find(42)
    assert user.notify_news
    assert_not user.isadmin
    assert_equal Time.utc(2020, 1, 2, 3, 4, 5), user.created_at
    assert_equal 43, User.create!(
      first_name: 'Test', last_name: 'User', email: 'test@example.com', password: 'secret'
    ).id
  end

  test 'does nothing when the SQLite database is absent' do
    run_copy_task

    assert_equal 0, User.count
  end

  test 'does not overwrite a PostgreSQL database that already has data' do
    create_sqlite_database
    User.insert_all!([{ id: 1, first_name: 'Existing' }])

    run_copy_task

    assert_equal [1], User.order(:id).pluck(:id)
  end

  private

  def clear_postgresql_database
    connection = ApplicationRecord.connection
    tables = connection.tables - %w[ar_internal_metadata schema_migrations]
    connection.disable_referential_integrity do
      tables.each { |table| connection.execute("DELETE FROM #{connection.quote_table_name(table)}") }
    end
  end

  def create_sqlite_database
    database = SQLite3::Database.new(@sqlite_path)
    database.execute_batch(<<~SQL.squish)
      CREATE TABLE users (
        id INTEGER PRIMARY KEY,
        first_name varchar,
        last_name varchar,
        email varchar,
        password varchar,
        notify_news boolean,
        created_at datetime,
        updated_at datetime,
        isadmin boolean,
        notify_photo_album boolean
      );
      CREATE TABLE news_items (id INTEGER PRIMARY KEY);
      CREATE TABLE news_comments (id INTEGER PRIMARY KEY);
      CREATE TABLE photo_albums (id INTEGER PRIMARY KEY);
      CREATE TABLE photo_album_comments (id INTEGER PRIMARY KEY);
      CREATE TABLE photo_album_pictures (id INTEGER PRIMARY KEY);
    SQL
    database.execute(
      'INSERT INTO users VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [42, 'Source', 'User', 'source@example.com', 'not-a-real-password', 1,
       '2020-01-02 03:04:05', '2020-01-02 03:04:05', 0, 1]
    )
  ensure
    database&.close
  end

  def run_copy_task
    original_path = ENV.fetch('SQLITE_PATH', nil)
    ENV['SQLITE_PATH'] = @sqlite_path.to_s
    task = Rake::Task['db:copy_from_sqlite']
    task.reenable
    task.invoke
  ensure
    ENV['SQLITE_PATH'] = original_path
  end
end
