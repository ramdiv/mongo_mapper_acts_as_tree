require 'helper'

class TestSearchMixedTree < Minitest::Test
  def setup
    DatabaseCleaner.start
    shape = Shape.create(name: "Root")
    circle = Circle.create(name: "Circle", parent: shape)
    Square.create(name: "Square", parent: circle)

    @shape, @circle, @square = Shape.first, Circle.first, Square.first
  end

  def teardown
    DatabaseCleaner.clean
  end

  def test_circle_is_child_of_shape
    assert_equal [@circle], @shape.children
  end

  def test_square_is_child_of_circle
    assert_equal [@square], @circle.children
  end

  def test_circle_is_parent_of_square
    assert_equal @circle, @square.parent
  end

  def test_shape_is_parent_of_circle
    assert_equal @shape, @circle.parent
  end

  def test_shape_decendants
    assert_equal [@circle, @square], @shape.descendants
  end

  def test_circle_decendants
    assert_equal [@square], @circle.descendants
  end

  def test_square_ancestors
    assert_equal [@shape, @circle], @square.ancestors
  end

  def test_circle_ansestors
    assert_equal [@shape], @circle.ancestors
  end

  def test_destroy_shape_decendants
    @shape.destroy_descendants
    assert_nil Shape.find(@circle._id)
    assert_nil Shape.find(@square._id)
  end
end
