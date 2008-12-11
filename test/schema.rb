ActiveRecord::Schema.define(:version => 0) do
  
  create_table :abstract_articles, :force => true do |t|
    t.column :title, :string
    t.column :permalink, :string
    t.column :created_at, :datetime
    t.column :approval_status_id, :integer
  end
  
  create_table :approvals, :force => true do |t|
    t.column :approvable_type, :string
    t.column :approvable_id, :integer
    t.column :approval_status_id, :integer
    t.column :updated_at, :datetime
    t.column :created_at, :datetime
    t.column :expires_at, :datetime, :default => nil
  end

  create_table :approval_statuses, :force => true do |t|
    t.column :name, :string
    t.column :visible, :boolean
  end

end