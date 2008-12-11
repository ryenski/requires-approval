require File.join(File.dirname(__FILE__), 'test_helper')

class RequiresApprovalTest < Test::Unit::TestCase
  fixtures :abstract_articles, :approvals, :approval_statuses
  
  def test_should_publish
    a = AbstractArticle.create(:title => "Mark Me as published")
    assert a.published!
  end
  
  def test_should_find_published
    articles = AbstractArticle.find_published(:all)
    assert_equal 3, AbstractArticle.find_published(:all).size
    articles.each {|a| assert a.published? }
  end
  
  
  def test_should_save_as_draft
    assert_difference Approval, :count do
      a = AbstractArticle.create(:title => "Please Mark Me as Draft")
      assert a.valid?
      assert a.draft!
    end
  end
  
  def assert_published(obj)
    assert obj.published?
    deny obj.draft?
    deny obj.spam?
    deny obj.pending?
    deny obj.declined?
  end
  
  def test_should_find_abstract_article_by_permalink
    first = AbstractArticle.find_by_permalink("first")
    assert_equal abstract_articles(:first), first
    assert_published first
    
    second = AbstractArticle.find_published_by_permalink("second")
    assert_equal abstract_articles(:second), second
    assert_published second
  end
  
  def test_should_find_abstract_article_by_id
    a = AbstractArticle.find(1, :conditions => "approval_status_id = 1")
    assert_equal a, abstract_articles(:first)
    assert_published a
    
    a2 = AbstractArticle.find_published(1)
    assert_equal a2, abstract_articles(:first)
    assert_published a2
  end
  
  def test_should_track_multiple_approvals
    article = AbstractArticle.create(:title => "test3")
    assert_equal 0, article.approvals.size
    
    article.draft!
    assert article.draft?
    assert_equal "draft", article.status
    assert_equal 1, article.approvals.find(:all).size
    
    article.pending!
    
    assert article.reload.pending?
    assert_equal "pending", article.status
    assert_equal 2, article.approvals.count
    
    article.published!
    assert article.reload.published?
    assert_equal "published", article.status
    assert_equal 3, article.approvals.count
  end
  
  def test_raise_for_unapproved
    assert_raise(ActiveRecord::RecordNotFound){AbstractArticle.find_published(5)}
  end
  
  def test_raise_for_published
    assert_raise(ActiveRecord::RecordNotFound){AbstractArticle.find_declined(1)}
  end
  
  def test_find
    AbstractArticle.find(1).published!
    AbstractArticle.find(2).published!
    assert_equal 3, AbstractArticle.find_published(:all).size
  end

  def test_find_with_limit
    AbstractArticle.create(:title => "test3")
    AbstractArticle.find(1).published!
    AbstractArticle.find(2).published!
    AbstractArticle.find(3).published!
    articles = AbstractArticle.find_published(:all, :limit => 2, :order => "created_at ASC")
    assert_equal 2, articles.size
  end
  
  def test_find_with_args
    articles = AbstractArticle.find_published(:all, :limit => 2)
    assert_equal 2, articles.size
  end

  
  def test_should_count_published
    assert_equal 3, AbstractArticle.count_published(:all)
  end
  
  def test_should_count_drafts
    assert_equal 1, AbstractArticle.count_draft(:all)
  end
  
  def test_should_count_pending    
    assert_equal 1, AbstractArticle.count_pending(:all)
  end
  
  def test_should_find_pending
    assert_equal abstract_articles(:pending_article), AbstractArticle.find_pending(:all).first
  end
  
  def test_approval_status_id
    article = abstract_articles(:first)
    assert article.published?
    assert_equal "published", article.approval.status.name
  end
  
  def test_set_approval_status_id
    article = AbstractArticle.create(:title => "Test Cached")
    article.published!
    assert article.published?
    assert_equal "published", article.approval.status.name
  end
  
end
