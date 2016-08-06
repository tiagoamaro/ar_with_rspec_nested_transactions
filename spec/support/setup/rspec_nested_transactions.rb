RSpec.configure do |c|
  c.nested_transaction do |example_or_group, run|
    (run[]; next) unless example_or_group.metadata[:nested_transaction]

    # Source: http://api.rubyonrails.org/classes/ActiveRecord/Transactions/ClassMethods.html#module-ActiveRecord::Transactions::ClassMethods-label-Nested+transactions
    # Source: https://github.com/rails/rails/blob/b326e82dc012d81e9698cb1f402502af1788c1e9/activerecord/lib/active_record/connection_adapters/abstract/database_statements.rb#L226-L235
    # "However, if +:requires_new+ is set, the block will be wrapped in a database savepoint acting as a sub-transaction."
    # => https://github.com/rails/rails/blob/b326e82dc012d81e9698cb1f402502af1788c1e9/activerecord/lib/active_record/connection_adapters/abstract/database_statements.rb#L174

    # Much of this happens in ActiveRecord::ConnectionAdapters::TransactionManager, which is accessible through ActiveRecord::Base.connection.transaction_manager

    begin
      ActiveRecord::Base.transaction(requires_new: true) do
        run[]
        raise StandardError, 'Rollback SAVEPOINT'
      end
    rescue StandardError
      # NOOP
    end
  end
end
