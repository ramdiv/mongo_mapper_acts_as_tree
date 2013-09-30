require 'helper'

class TestSearchTree < Minitest::Test
  def setup
    DatabaseCleaner.start
    shape = Shape.create(name: "Root")
    Circle.create(name: "Circle", parent: shape)
    Square.create(name: "Square", parent: shape)

    # We are loading from the database here because this process proves the point. If we never did it this
    # way, there would be no reason to change the code.
    @shape, @circle, @square = Shape.first, Circle.first, Square.first
  end

  def teardown
    DatabaseCleaner.clean
  end

  def text_children
    assert_equal [@circle, @square], @shape.children
  end

  def test_shape_parenhood
    assert_equal @shape, @circle.parent
    assert_equal @shape, @square.parent
  end

  def text_siblings
    assert_equal [@square], @circle.siblings
    assert_equal [@circle, @square], @circle.self_and_siblings

    assert_equal [@circle], @square.siblings
    assert_equal [@circle, @square], @square.self_and_siblings
  end

  def test_deendants
    assert_equal [@circle, @square], @shape.descendants
    assert_equal [@shape, @circle, @square], @shape.self_and_descendants
  end

  def test_ancestors
    assert_equal [@shape], @circle.ancestors
    assert_equal [@shape, @circle], @circle.self_and_ancestors
    assert_equal [@shape], @square.ancestors
    assert_equal [@shape, @square], @square.self_and_ancestors
  end

  def test_roots
    assert_equal @shape, @square.root
    assert_equal @shape, @circle.root
  end
end
