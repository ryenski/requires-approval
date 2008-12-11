#  id      :integer       not null
#  name    :string(255)
#  publish :boolean
#

class ApprovalStatus < ActiveRecord::Base
  has_many :approvals
  validates_uniqueness_of :name
  
  def self.options_for_select
    ApprovalStatus.find(:all).map{|a| a.name}.unshift("")
  end
end
