require 'helper'
require 'set'

class TestMongomapperActsAsTree < Test::Unit::TestCase
  context "Tree" do
    setup do
      @root_1     = Category.create(:name => "Root 1")
      @child_1    = Category.create(:name => "Child 1", :parent => @root_1)
      @child_2    = Category.create(:name => "Child 2", :parent => @root_1)
      @child_2_1  = Category.create(:name => "Child 2.1", :parent => @child_2)
      @child_3    = Category.create(:name => "Child 3", :parent => @root_1)
      @root_2     = Category.create(:name => "Root 2")
    end
    
   	should "create node from id " do
			assert Category.create(:name => "Child 2.2", :parent => @root_1.id.to_s).parent == @root_1
		end 

    should "have roots" do
      assert eql_arrays?(Category.roots, [@root_1, @root_2])
    end
      
    context "node" do
      should "have a root" do
        assert_equal @root_1.root, @root_1
        assert_not_equal @root_1.root, @root_2.root
        assert_equal @root_1, @child_2_1.root
      end
      
      should "have ancestors" do
        assert_equal @root_1.ancestors, []
        assert_equal @child_2_1.ancestors, [@root_1, @child_2]
        assert_equal @root_1.self_and_ancestors, [@root_1]
        assert_equal @child_2_1.self_and_ancestors, [@root_1, @child_2, @child_2_1]
      end
      
      should "have siblings" do
        assert eql_arrays?(@root_1.siblings, [@root_2])
        assert eql_arrays?(@child_2.siblings, [@child_1, @child_3])
        assert eql_arrays?(@child_2_1.siblings, [])
        assert eql_arrays?(@root_1.self_and_siblings, [@root_1, @root_2])
        assert eql_arrays?(@child_2.self_and_siblings, [@child_1, @child_2, @child_3])
        assert eql_arrays?(@child_2_1.self_and_siblings, [@child_2_1])
      end
      
      should "set depth" do
        assert_equal 0, @root_1.depth
        assert_equal 1, @child_1.depth
        assert_equal 2, @child_2_1.depth
      end
      
      should "have children" do
        assert @child_2_1.children.empty?
        assert eql_arrays?(@root_1.children, [@child_1, @child_2, @child_3])
      end
      
      should "have descendants" do
        assert eql_arrays?(@root_1.descendants, [@child_1, @child_2, @child_3, @child_2_1])
        assert eql_arrays?(@child_2.descendants, [@child_2_1])
        assert @child_2_1.descendants.empty?
        assert eql_arrays?(@root_1.self_and_descendants, [@root_1, @child_1, @child_2, @child_3, @child_2_1])
        assert eql_arrays?(@child_2.self_and_descendants, [@child_2, @child_2_1])
        assert eql_arrays?(@child_2_1.self_and_descendants, [@child_2_1])
      end
      
      should "be able to tell if ancestor" do
        assert @root_1.is_ancestor_of?(@child_1)
        assert !@root_2.is_ancestor_of?(@child_2_1)
        assert !@child_2.is_ancestor_of?(@child_2)
        
        assert @root_1.is_or_is_ancestor_of?(@child_1)
        assert !@root_2.is_or_is_ancestor_of?(@child_2_1)
        assert @child_2.is_or_is_ancestor_of?(@child_2)
      end
      
      should "be able to tell if descendant" do
        assert !@root_1.is_descendant_of?(@child_1)
        assert @child_1.is_descendant_of?(@root_1)
        assert !@child_2.is_descendant_of?(@child_2)
        
        assert !@root_1.is_or_is_descendant_of?(@child_1)
        assert @child_1.is_or_is_descendant_of?(@root_1)
        assert @child_2.is_or_is_descendant_of?(@child_2)
      end
      
      should "be able to tell if sibling" do
        assert !@root_1.is_sibling_of?(@child_1)
        assert !@child_1.is_sibling_of?(@child_1)
        assert !@child_2.is_sibling_of?(@child_2)
        
        assert !@root_1.is_or_is_sibling_of?(@child_1)
        assert @child_1.is_or_is_sibling_of?(@child_2)
        assert @child_2.is_or_is_sibling_of?(@child_2)
      end
      
      context "when moving" do
        should "recalculate path and depth" do
          @child_3.parent = @child_2
          @child_3.save
          
          assert @child_2.is_or_is_ancestor_of?(@child_3)
          assert @child_3.is_or_is_descendant_of?(@child_2)
          assert @child_2.children.include?(@child_3)
          assert @child_2.descendants.include?(@child_3)
          assert @child_2_1.is_or_is_sibling_of?(@child_3)
          assert_equal 2, @child_3.depth
        end
        
        should "move children on save" do
          @child_2.parent = @root_2
          
          assert !@root_2.is_or_is_ancestor_of?(@child_2_1)
          assert !@child_2_1.is_or_is_descendant_of?(@root_2)
          assert !@root_2.descendants.include?(@child_2_1)
          
          @child_2.save
          @child_2_1.reload
    
          assert @root_2.is_or_is_ancestor_of?(@child_2_1)
          assert @child_2_1.is_or_is_descendant_of?(@root_2)
          assert @root_2.descendants.include?(@child_2_1)
        end
        
        should "check against cyclic graph" do
          @root_1.parent = @child_2_1
          assert !@root_1.save
        end
      end
      
      should "destroy descendants when destroyed" do
        @child_2.destroy
        assert_nil Category.find(@child_2_1._id)
      end
    end
    
    context "root node" do
      should "not have a parent" do
        assert_nil @root_1.parent
      end
    end
    
    context "child_node" do
      should "have a parent" do
        assert_equal @child_2, @child_2_1.parent
      end
    end
  end
end
