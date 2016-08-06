# ActiveRecord + Postgres + rspec_nested_transactions

[![Build Status](https://travis-ci.org/tiagoamaro/ar_with_rspec_nested_transactions.svg?branch=master)](https://travis-ci.org/tiagoamaro/ar_with_rspec_nested_transactions)

Based on [my rspec_nested_transactions pull request comment](https://github.com/rosenfeld/rspec_nested_transactions/pull/1#issuecomment-238022973), I've prepared this repository to explain the step by step of making ActiveRecord work with the `rspec_nested_transactions` gem.

## Approach

Instead of using RSpec transactional fixtures (which creates SAVEPOINTS but never use them) or database cleaner (which, well, execute too many commits/rollbacks around each RSpec example), Rodrigo Rosenfeld Rosas (https://github.com/rosenfeld) introduced an interesting idea on using nested transactions to isolate test records.

This repository is only testing against PostgreSQL, but according to the [current official Rails documentation](http://api.rubyonrails.org/v5.0.0/classes/ActiveRecord/Transactions/ClassMethods.html#module-ActiveRecord::Transactions::ClassMethods-label-Nested+transactions), it should work fine with MySQL and PostgreSQL. SQLite3 version >= '3.6.8'.

## Files

Notable files:

- `spec/support/setup/rspec_nested_transactions.rb`

## How?

- Based on http://api.rubyonrails.org/classes/ActiveRecord/Transactions/ClassMethods.html#module-ActiveRecord::Transactions::ClassMethods-label-Nested+transactions

As documented above, you can use the `ActiveRecord::Base.transaction(requires_new: true) {}` call to start a new savepoint. This will make the current database connection initialize a new transaction, calling it's [`TransactionManager`](https://github.com/rails/rails/blob/b326e82dc012d81e9698cb1f402502af1788c1e9/activerecord/lib/active_record/connection_adapters/abstract/transaction.rb#L145).

The `ActiveRecord::Base.transaction` class method allows to execute a database ROLLBACK on the current transaction by raising the `ActiveRecord::Rollback` exception within a transaction, making it easy creating a SAVEPOINT and rolling it back by doing the following:

```ruby
ActiveRecord::Base.transaction(requires_new: true) do
  execute_anything
  raise ActiveRecord::Rollback
end
```

To use it with the `rspec_nested_transactions` just insert the following snippet under any file that you would require on your test suite:

 ```ruby
 RSpec.configure do |c|
   (run[]; next) unless example_or_group.metadata[:db]

   c.nested_transaction do |example_or_group, run|
     ActiveRecord::Base.transaction(requires_new: true) do
       run[]
       raise ActiveRecord::Rollback
     end
   end
 end

 ```

## Expected Results

This is just a sample repository, but with this technique, a real project should be able to use native database features to keep test isolation and enhance large test suites performance at the same time! 

### Logs

#### With RSpec transactional fixtures

```
   (0.2ms)  BEGIN
   (0.2ms)  SAVEPOINT active_record_1
  SQL (0.8ms)  INSERT INTO "posts" ("title", "content", "created_at", "updated_at") VALUES ($1, $2, $3, $4) RETURNING "id"  [["title", "Title 1"], ["content", "Awesome"], ["created_at", 2016-08-06 23:35:43 UTC], ["updated_at", 2016-08-06 23:35:43 UTC]]
   (0.1ms)  RELEASE SAVEPOINT active_record_1
   (0.1ms)  SAVEPOINT active_record_1
  SQL (0.3ms)  INSERT INTO "posts" ("title", "content", "created_at", "updated_at") VALUES ($1, $2, $3, $4) RETURNING "id"  [["title", "Title 2"], ["content", "Awesome"], ["created_at", 2016-08-06 23:35:43 UTC], ["updated_at", 2016-08-06 23:35:43 UTC]]
   (0.1ms)  RELEASE SAVEPOINT active_record_1
   (0.1ms)  SAVEPOINT active_record_1
  SQL (0.3ms)  INSERT INTO "posts" ("title", "content", "created_at", "updated_at") VALUES ($1, $2, $3, $4) RETURNING "id"  [["title", "Title 3"], ["content", "Awesome"], ["created_at", 2016-08-06 23:35:43 UTC], ["updated_at", 2016-08-06 23:35:43 UTC]]
   (0.1ms)  RELEASE SAVEPOINT active_record_1
   (0.1ms)  ROLLBACK
```

#### With rspec_nested_transactions + transactional fixtures turned off

```
   (0.2ms)  BEGIN
   (0.1ms)  SAVEPOINT active_record_1
   (0.1ms)  SAVEPOINT active_record_2
  SQL (0.7ms)  INSERT INTO "posts" ("title", "content", "created_at", "updated_at") VALUES ($1, $2, $3, $4) RETURNING "id"  [["title", "Title 1"], ["content", "Awesome"], ["created_at", 2016-08-06 23:37:50 UTC], ["updated_at", 2016-08-06 23:37:50 UTC]]
  SQL (0.2ms)  INSERT INTO "posts" ("title", "content", "created_at", "updated_at") VALUES ($1, $2, $3, $4) RETURNING "id"  [["title", "Title 2"], ["content", "Awesome"], ["created_at", 2016-08-06 23:37:50 UTC], ["updated_at", 2016-08-06 23:37:50 UTC]]
  SQL (0.2ms)  INSERT INTO "posts" ("title", "content", "created_at", "updated_at") VALUES ($1, $2, $3, $4) RETURNING "id"  [["title", "Title 3"], ["content", "Awesome"], ["created_at", 2016-08-06 23:37:50 UTC], ["updated_at", 2016-08-06 23:37:50 UTC]]
   (0.1ms)  ROLLBACK TO SAVEPOINT active_record_2
   (0.1ms)  ROLLBACK TO SAVEPOINT active_record_1
```
