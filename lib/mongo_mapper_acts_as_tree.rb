require "mongo_mapper"

module MongoMapper
  module Acts
    module Tree
      def self.included(model)
        model.class_eval do
          extend InitializerMethods
        end
      end

      module InitializerMethods
        def acts_as_tree(options = {})
          options = {
            :parent_id_field => "parent_id",
            :path_field      => "path",
            :depth_field     => "depth"
          }.merge(options)

          class_attribute :acts_as_tree_options, :instance_writer => false
          self.acts_as_tree_options = options

          include InstanceMethods
          include Fields
          extend Fields
          extend ClassMethods

          key parent_id_field,  ObjectId
          key path_field,       Array,  :default => [], :index => true
          key depth_field,      Integer, :default => 0

          after_save      :move_children
          validate        :will_save_tree
          before_destroy  :destroy_descendants
        end
      end

      module ClassMethods
        def roots
          self.all(parent_id_field => nil, :order => tree_order)
        end
      end

      module InstanceMethods
        def ==(other)
          return true if other.equal?(self)
          return true if other.instance_of?(self.class) and other._id == self._id
          false
        end

        def parent=(var)
          self[parent_id_field] = nil if var.nil?
          var = search_class.find(var) if var.is_a? String

          if self.descendants.include? var
            @_cyclic = true
          else
            @_parent = var
            fix_position
            @_will_move = true
          end
        end

        def will_save_tree
          if @_cyclic
            errors.add(:base, "Can't be children of a descendant")
          end
        end

        def fix_position
          if parent.nil?
            self[parent_id_field] = nil
            self[path_field] = []
            self[depth_field] = 0
          else
            self[parent_id_field] = parent._id
            self[path_field] = parent[path_field] + [parent._id]
            self[depth_field] = parent[depth_field] + 1
          end
        end

        def parent
          @_parent or (self[parent_id_field].nil? ? nil : search_class.find(self[parent_id_field]))
        end

        def root?
          self[parent_id_field].nil?
        end

        def root
          self[path_field].first.nil? ? self : search_class.find(self[path_field].first)
        end

        def ancestors
          return [] if root?
          search_class.find(self[path_field])
        end

        def self_and_ancestors
          ancestors << self
        end

        def siblings
          search_class.all(:_id => {"$ne" => self._id}, parent_id_field => self[parent_id_field], :order => tree_order)
        end

        def self_and_siblings
          search_class.all(parent_id_field => self[parent_id_field], :order => tree_order)
        end

        def children
          search_class.all(parent_id_field => self._id, :order => tree_order)
        end

        def descendants
          return [] if new_record?
          search_class.all(path_field => self._id, :order => tree_order)
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
            for child in self.children
              child.fix_position
              child.save
            end
            @_will_move = true
          end
        end

        def destroy_descendants
          search_class.destroy(self.descendants.map(&:_id))
        end
      end

      module Fields
        def parent_id_field
          acts_as_tree_options[:parent_id_field]
        end

        def path_field
          acts_as_tree_options[:path_field]
        end

        def depth_field
          acts_as_tree_options[:depth_field]
        end

        def tree_order
          acts_as_tree_options[:order] or ""
        end

        # When added as an option to acts_as_tree, search class will be used as the base from which to
        # find tree objects. This is handy should you have a tree of objects that are of different types, but
        # might be related through single table inheritance.
        #
        #     acts_as_tree :search_class => Shape
        #
        # In the above example, you could have a working tree ofShape, Circle and Square types (assuming
        # Circle and Square were subclasses of Shape). If you want to do the same thing and you don't provide
        # search_class, nesting mixed types will not work.
        #
        # The default is +self.class+
        def search_class
          acts_as_tree_options[:search_class] or self.class
        end
      end
    end
  end
end
