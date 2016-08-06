RSpec.configure do |c|
  c.nested_transaction do |example_or_group, run|
    (run[]; next) unless example_or_group.metadata[:db]

    begin
      ActiveRecord::Base.transaction(:requires_new => true) do
        run[]
        raise 'Rollback!'
      end
    rescue StandardError
      # NOOP
    end
  end
end
