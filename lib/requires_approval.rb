#  Copyright (c) 2006 Ryan Heneise
#    
#  Permission is hereby granted, free of charge, to any person obtaining
#  a copy of this software and associated documentation files (the
#  "Software"), to deal in the Software without restriction, including
#  without limitation the rights to use, copy, modify, merge, publish,
#  distribute, sublicense, and/or sell copies of the Software, and to
#  permit persons to whom the Software is furnished to do so, subject to
#  the following conditions:
#  
#  The above copyright notice and this permission notice shall be
#  included in all copies or substantial portions of the Software.
#  
#  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
#  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
#  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
#  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
#  LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
#  OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
#  WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

module RequiresApproval #:nodoc:
  # RequiresApproval enables an approval system for ActiveRecord object. 
  # Records can be marked as "published", "declined", "embargoed", "pending", or any other ApprovalStatus that you wish to create.
  #
  #   class Article < ActiveRecord::Base
  #      requires_approval
  #   end
  #
  #   To publish a record, simply call its #publish! method. For example: 
  #   * @article.published!
  #   * @article.draft!
  #   * @article.decline!
  #   * @article.spam!
  #
  #   To ask an object if it is published, call its #published? method. For example: 
  #   * @article.published?
  #   * @article.draft?
  #   * @article.decline?
  #   * @article.spam?
  #   
  #   To select a list of published objects, call Article#find_published
  #   
  #   To select a particular object if it is published, call Article#find_published(id)
  #
  #   You'll need a field called "approval_id", which stores the value of the most recent approval_id. 
  #   This simplifies the entire process and lets us use has_one :approval, instead of parsing through
  #   a list of former approvals. 
  #
  #   RequiresApproval remembers all former actions taken on a record. So if you mark an item as "pending"
  #   and then subsequently change the status to "published", there is a record of both actions taken, 
  #   when, and by which person. 
  #   
  
  class ActiveRecord::RecordNotPublished < ActiveRecord::ActiveRecordError #:nodoc:
  end
  
  def self.included(base)
    base.extend(ClassMethods)
  end
  
  module ClassMethods
    def requires_approval(options = {})
      write_inheritable_attribute(:requires_approval_options, {
        :approvable_type => ActiveRecord::Base.send(:class_name_of_active_record_descendant, self).to_s
      })
      
      class_inheritable_reader :requires_approval_options
      
      # Cache the approval_status_id in the object's record. 
      # This improves query performance and makes it possible to filter AR finds 
      # using conditionals like :conditions => "approval_status_id = 1"
      # You must add a row to the object's table: 
      #   add_column :contents, :approval_status_id, :integer
      has_one :approval_status
      
      # Set up a quick association so that we can get the most recent 
      # approval record without having to return the whole set into memory. 
      # For example, @content.approval returns the latest approval record. 
      has_one :approval, :as => :approvable, :order => "created_at DESC, id DESC"
      
      # Set up the full association with all approvals belonging to an object. 
      has_many :approvals, :as => :approvable, :dependent => :destroy, :order => "created_at DESC, id DESC"
      
      
      include RequiresApproval::InstanceMethods
      extend RequiresApproval::SingletonMethods
    end
  end
  
  module SingletonMethods
    # Set up method_missing so that we can use some convenience methods
    # 
    # Example: 
    # * Object.count_published_approvals
    # * Object.find_published_approvals    
    # * Object.find_published_by_permalink 
    def method_missing(method,*args)
      #breakpoint "method_missing"
      if match = /^count_(published|draft|declined|spam|pending|edited)$/.match(method.to_s)
        count_with_approval_status(match[1], *args)
        
      elsif match = /^find_(published|draft|declined|spam|pending|edited)$/.match(method.to_s)
        find_with_approval_status(match[1], *args)
        
      # Example: Object.find_published_by_permalink("permalink")
      elsif match = /^find_(published|draft|declined|spam|pending|edited)_by_([_a-zA-Z]\w*)$/.match(method.to_s)
        find_with_approval_status(match[1], :first, :conditions => "#{match[2]} = '#{args.first}'")
      else
        super
      end
    end
    
    # Find using Object.approval_id
    def find_with_approval_status(status="published", *args)
      find(*set_conditions(status,*args))
    end
    
    # Count using Object.approval_id
    def count_with_approval_status(status="published", *args)
      count(*set_conditions(status,*args))
    end
    
    # Set up the conditional statement to select from Object.approval_id
    def set_conditions(status="published", *args)
      approval_status = ApprovalStatus.find_by_name(status)
      conditions = approval_status.nil? ? "approval_status_id IS NULL" : "approval_status_id = #{approval_status.id}"
      
      if args.last.is_a?(Hash)
        args.last[:conditions] = args.last[:conditions] ? "#{args.last[:conditions]} AND #{conditions}" : conditions
      else
        args << {:conditions => conditions}
      end
      return args
    end
    
  end
  
  module InstanceMethods
    
    def method_missing(method,*args)
      if match = /^(published|draft|declined|spam|pending|hidden|edited)\?$/.match(method.to_s)
        return true if self.approval and self.approval.status.name == match[1]
        return false
      elsif match = /^(published|draft|declined|spam|pending|hidden|edited)\!$/.match(method.to_s)
        set_approval!(match[1])
      else
        super
      end
    end
    
    def status
      self.approval ? self.approval.status.name : nil
    end
    
    protected
    
    def set_approval!(approval_status="published")
      approval_status = ApprovalStatus.find_by_name(approval_status)
      self.approvals << Approval.create(:approval_status_id => approval_status.id)
      self.update_attributes(:approval_status_id => approval_status.id)
      self.reload
    end
    
  end
end