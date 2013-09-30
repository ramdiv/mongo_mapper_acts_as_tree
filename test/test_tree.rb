require 'helper'
class TestTree < Minitest::Test
  def setup
    DatabaseCleaner.start
    @root_1     = Category.create(name: "Root 1")
    @child_1    = Category.create(name: "Child 1", parent: @root_1)
    @child_2    = Category.create(name: "Child 2", parent: @root_1)
    @child_2_1  = Category.create(name: "Child 2.1", parent: @child_2)
    @child_3    = Category.create(name: "Child 3", parent: @root_1)
    @root_2     = Category.create(name: "Root 2")
  end

  def teardown
    DatabaseCleaner.clean
  end

  def test_create_node_from_id
    assert Category.create(name: "Child 2.2", parent_id: @root_1.id).parent == @root_1
  end

  def test_category_roots
    assert eql_arrays?(Category.roots, [@root_1, @root_2])
  end

  def test_roots
    assert_equal @root_1.root, @root_1
    refute_equal @root_1.root, @root_2.root
    assert_equal @root_1, @child_2_1.root
  end

  def test_ancestors
    assert_equal @root_1.ancestors, []
    assert_equal @child_2_1.ancestors, [@root_1, @child_2]
    assert_equal @root_1.self_and_ancestors, [@root_1]
    assert_equal @child_2_1.self_and_ancestors, [@root_1, @child_2, @child_2_1]
  end

  def test_siblings
    assert eql_arrays?(@root_1.siblings, [@root_2])
    assert eql_arrays?(@child_2.siblings, [@child_1, @child_3])
    assert eql_arrays?(@child_2_1.siblings, [])
    assert eql_arrays?(@root_1.self_and_siblings, [@root_1, @root_2])
    assert eql_arrays?(@child_2.self_and_siblings, [@child_1, @child_2, @child_3])
    assert eql_arrays?(@child_2_1.self_and_siblings, [@child_2_1])
  end

  def test_depths
    assert_equal 0, @root_1.depth
    assert_equal 1, @child_1.depth
    assert_equal 2, @child_2_1.depth
  end

  def test_children
    assert @child_2_1.children.empty?
    assert eql_arrays?(@root_1.children, [@child_1, @child_2, @child_3])
  end

  def test_decendants
    assert eql_arrays?(@root_1.descendants, [@child_1, @child_2, @child_3, @child_2_1])
    assert eql_arrays?(@child_2.descendants, [@child_2_1])
    assert @child_2_1.descendants.empty?
    assert eql_arrays?(@root_1.self_and_descendants, [@root_1, @child_1, @child_2, @child_3, @child_2_1])
    assert eql_arrays?(@child_2.self_and_descendants, [@child_2, @child_2_1])
    assert eql_arrays?(@child_2_1.self_and_descendants, [@child_2_1])
  end

  def test_knows_if_ancestor
    assert @root_1.is_ancestor_of?(@child_1)
    assert ! @root_2.is_ancestor_of?(@child_2_1)
    assert ! @child_2.is_ancestor_of?(@child_2)

    assert @root_1.is_or_is_ancestor_of?(@child_1)
    assert ! @root_2.is_or_is_ancestor_of?(@child_2_1)
    assert @child_2.is_or_is_ancestor_of?(@child_2)
  end

  def test_knows_if_decendant
    assert ! @root_1.is_descendant_of?(@child_1)
    assert @child_1.is_descendant_of?(@root_1)
    assert ! @child_2.is_descendant_of?(@child_2)

    assert ! @root_1.is_or_is_descendant_of?(@child_1)
    assert @child_1.is_or_is_descendant_of?(@root_1)
    assert @child_2.is_or_is_descendant_of?(@child_2)
  end

  def test_knows_if_sibling
    assert ! @root_1.is_sibling_of?(@child_1)
    assert ! @child_1.is_sibling_of?(@child_1)
    assert ! @child_2.is_sibling_of?(@child_2)

    assert ! @root_1.is_or_is_sibling_of?(@child_1)
    assert @child_1.is_or_is_sibling_of?(@child_2)
    assert @child_2.is_or_is_sibling_of?(@child_2)
  end

  def test_recalculates_path_and_depth_when_moved
    @child_3.parent = @child_2
    @child_3.save

    assert @child_2.is_or_is_ancestor_of?(@child_3)
    assert @child_3.is_or_is_descendant_of?(@child_2)
    assert @child_2.children.include?(@child_3)
    assert @child_2.descendants.include?(@child_3)
    assert @child_2_1.is_or_is_sibling_of?(@child_3)
    assert_equal 2, @child_3.depth
  end

  def test_moved_children_when_moved
    @child_2.parent = @root_2

    assert ! @root_2.is_or_is_ancestor_of?(@child_2_1)
    assert ! @child_2_1.is_or_is_descendant_of?(@root_2)
    assert ! @root_2.descendants.include?(@child_2_1)

    @child_2.save
    @child_2_1.reload

    assert @root_2.is_or_is_ancestor_of?(@child_2_1)
    assert @child_2_1.is_or_is_descendant_of?(@root_2)
    assert @root_2.descendants.include?(@child_2_1)
  end

  def test_checks_against_cyclic_graph
    @root_1.parent = @child_2_1
    assert ! @root_1.valid?
    assert_equal I18n.t(:'mongo_mapper.errors.messages.cyclic'), @root_1.errors[:base].first
  end

  def test_can_become_root
    @child_2.parent = nil
    @child_2.save
    @child_2.reload
    assert_nil @child_2.parent
    @child_2_1.reload
    assert (@child_2_1.path == [@child_2.id])
  end

  def test_destroys_decendants
    assert @child_2.destroy
    assert_nil Category.find(@child_2_1._id)
  end

  def test_roots_cannot_have_parents
    assert_nil @root_1.parent
  end

  def test_children_have_a_parent
    assert_equal @child_2, @child_2_1.parent
  end
end
