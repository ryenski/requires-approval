#  id                 :integer       not null
#  approvable_type    :string(255)   
#  approvable_id      :string(255)   
#  approval_status_id :string(255)   
#  updated_at         :datetime      
#  created_at         :datetime      
#  expires_at         :datetime
#  created_by         :integer       
#  updated_by         :integer       
#

class Approval < ActiveRecord::Base
  belongs_to :approvable, :polymorphic => true
  belongs_to :status, :class_name => "ApprovalStatus", :foreign_key => "approval_status_id"
end
