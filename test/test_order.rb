require 'helper'
require 'set'

class TestMongomapperActsAsTree < Test::Unit::TestCase
  context "Ordered tree" do
    setup do
      @root_1     = OrderedCategory.create(:name => "Root 1", :value => 2)
      @child_1    = OrderedCategory.create(:name => "Child 1", :parent => @root_1, :value => 1)
      @child_2    = OrderedCategory.create(:name => "Child 2", :parent => @root_1, :value => 9)
      @child_2_1  = OrderedCategory.create(:name => "Child 2.1", :parent => @child_2, :value => 2)
      @child_3    = OrderedCategory.create(:name => "Child 3", :parent => @root_1, :value => 5)
      @root_2     = OrderedCategory.create(:name => "Root 2", :value => 1)
    end
    
    should "be in order" do
      assert_equal OrderedCategory.roots, [@root_2, @root_1]
      
      assert_equal @root_1.children, [@child_1, @child_3, @child_2]
  
      assert_equal @root_1.descendants, [@child_1, @child_2_1, @child_3, @child_2]
      assert_equal @root_1.self_and_descendants, [@root_1, @child_1, @child_2_1, @child_3, @child_2]
      
      assert_equal @child_2.siblings, [@child_1, @child_3]
      assert_equal @child_2.self_and_siblings, [@child_1, @child_3, @child_2]
      assert_equal @root_1.self_and_siblings, [@root_2, @root_1]
    end
  end
end
