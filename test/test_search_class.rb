require 'helper'

class TestSearchScope < Test::Unit::TestCase
  context "Simple, mixed type tree" do
    setup do
      shape = Shape.create(:name => "Root")
      Circle.create(:name => "Circle", :parent => shape)
      Square.create(:name => "Square", :parent => shape)
    end

    setup do
      # We are loading from the database here because this process proves the point. If we never did it this
      # way, there would be no reason to change the code.
      @shape, @circle, @square = Shape.first, Circle.first, Square.first
    end

    should "return circle and square as children of shape" do
      assert_equal [@circle, @square], @shape.children
    end

    should("return shape as parent of circle") { assert_equal @shape, @circle.parent }
    should("return shape as parent of square") { assert_equal @shape, @square.parent }

    should("return square as exclusive sibling of circle") { assert_equal [@square], @circle.siblings }
    should "return self and square as inclusive siblings of circle" do
      assert_equal [@circle, @square], @circle.self_and_siblings
    end

    should("return circle as exclusive sibling of square") { assert_equal [@circle], @square.siblings }
    should "return self and circle as inclusive siblings of square" do
      assert_equal [@circle, @square], @square.self_and_siblings
    end

    should "return circle and square as exclusive descendants of shape" do
      assert_equal [@circle, @square], @shape.descendants
    end
    should "return shape, circle and square as inclusive descendants of shape" do
      assert_equal [@shape, @circle, @square], @shape.self_and_descendants
    end

    should("return shape as exclusive ancestor of circle") { assert_equal [@shape], @circle.ancestors }
    should "return self and shape as inclusive ancestors of circle" do
      assert_equal [@shape, @circle], @circle.self_and_ancestors
    end

    should("return shape as exclusive ancestor of square") { assert_equal [@shape], @square.ancestors }
    should "return self and shape as inclusive ancestors of square" do
      assert_equal [@shape, @square], @square.self_and_ancestors
    end

    should("return shape as root of circle") { assert_equal @shape, @square.root }
    should("return shape as root of square") { assert_equal @shape, @circle.root }
  end

  context "A tree with mixed types on either side of a branch" do
    setup do
      shape = Shape.create(:name => "Root")
      circle = Circle.create(:name => "Circle", :parent => shape)
      Square.create(:name => "Square", :parent => circle)
    end

    setup do
      @shape, @circle, @square = Shape.first, Circle.first, Square.first
    end

    should("return circle as child of shape") { assert_equal [@circle], @shape.children }
    should("return square as child of circle") { assert_equal [@square], @circle.children }
    should("return circle as parent of square") { assert_equal @circle, @square.parent }
    should("return shape as parent of circle") { assert_equal @shape, @circle.parent }

    should "return circle and square as descendants of shape" do
      assert_equal [@circle, @square], @shape.descendants
    end

    should("return square as descendant of circle") { assert_equal [@square], @circle.descendants }

    should "return shape and circle as ancestors of square" do
      assert_equal [@shape, @circle], @square.ancestors
    end

    should("return shape as ancestor of circle") { assert_equal [@shape], @circle.ancestors }

    should "destroy descendants of shape" do
      @shape.destroy_descendants
      assert_nil Shape.find(@circle._id)
      assert_nil Shape.find(@square._id)
    end
  end

end # TestSearchScope