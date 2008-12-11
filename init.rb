require 'requires_approval'
ActiveRecord::Base.send(:include, RequiresApproval)

require File.dirname(__FILE__) + '/lib/approval'
require File.dirname(__FILE__) + '/lib/approval_status'
