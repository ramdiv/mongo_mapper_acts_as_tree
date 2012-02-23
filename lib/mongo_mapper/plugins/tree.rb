# encoding: UTF-8
module MongoMapper
  module Plugins
    module Tree
      extend ActiveSupport::Concern

      module ClassMethods
        def roots
          self.where(parent_id_field => nil).sort(tree_order).all
        end
      end

      def tree_search_class
        self.class.tree_search_class
      end

      def will_save_tree
        if parent && self.descendants.include?(parent)
          errors.add(:base, :cyclic)
        end
      end

      def fix_position(opts = {})
        if parent.nil?
          self[parent_id_field] = nil
          self[path_field] = []
          self[depth_field] = 0
        elsif !!opts[:force] || self.changes.include?(parent_id_field)
          @_will_move = true
          self[path_field]  = parent[path_field] + [parent._id]
          self[depth_field] = parent[depth_field] + 1
        end
      end

      def fix_position!
        fix_position(:force => true)
        save
      end

      def root?
        self[parent_id_field].nil?
      end

      def root
        self[path_field].first.nil? ? self : tree_search_class.find(self[path_field].first)
      end

      def ancestors
        return [] if root?
        tree_search_class.find(self[path_field])
      end

      def self_and_ancestors
        ancestors << self
      end

      def siblings
        tree_search_class.where({
          :_id => { "$ne" => self._id },
          parent_id_field => self[parent_id_field]
        }).sort(tree_order).all
      end

      def self_and_siblings
        tree_search_class.where({
          parent_id_field => self[parent_id_field]
        }).sort(tree_order).all
      end

      def children
        tree_search_class.where(parent_id_field => self._id).sort(tree_order).all
      end

      def descendants
        return [] if new_record?
        tree_search_class.where(path_field => self._id).sort(tree_order).all
      end

      def self_and_descendants
        [self] + self.descendants
      end

      def is_ancestor_of?(other)
        other[path_field].include?(self._id)
      end

      def is_or_is_ancestor_of?(other)
        (other == self) or is_ancestor_of?(other)
      end

      def is_descendant_of?(other)
        self[path_field].include?(other._id)
      end

      def is_or_is_descendant_of?(other)
        (other == self) or is_descendant_of?(other)
      end

      def is_sibling_of?(other)
        (other != self) and (other[parent_id_field] == self[parent_id_field])
      end

      def is_or_is_sibling_of?(other)
        (other == self) or is_sibling_of?(other)
      end

      def move_children
        if @_will_move
          @_will_move = false
          self.children.each do |child|
            child.fix_position!
          end
          @_will_move = true
        end
      end

      def destroy_descendants
        tree_search_class.destroy(self.descendants.map(&:_id))
      end

      included do
        # Tree search class will be used as the base from which to
        # find tree objects. This is handy should you have a tree of objects that are of different types, but
        # might be related through single table inheritance.
        #
        #   self.tree_search_class = Shape
        #
        # In the above example, you could have a working tree ofShape, Circle and Square types (assuming
        # Circle and Square were subclasses of Shape). If you want to do the same thing and you don't provide
        # tree_search_class, nesting mixed types will not work.
        class_attribute :tree_search_class
        self.tree_search_class ||= self

        class_attribute :parent_id_field
        self.parent_id_field ||= "parent_id"

        class_attribute :path_field
        self.path_field ||= "path"

        class_attribute :depth_field
        self.depth_field ||= "depth"

        class_attribute :tree_order

        key parent_id_field, ObjectId
        key path_field, Array, :default => []
        key depth_field, Integer, :default => 0

        belongs_to :parent, :class => tree_search_class

        validate         :will_save_tree
        after_validation :fix_position
        after_save       :move_children
        before_destroy   :destroy_descendants
      end
    end
  end
end
