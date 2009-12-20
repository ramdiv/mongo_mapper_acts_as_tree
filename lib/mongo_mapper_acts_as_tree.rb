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
          
          write_inheritable_attribute :acts_as_tree_options, options
          class_inheritable_reader :acts_as_tree_options
          
          include InstanceMethods
          include Fields
          extend Fields
          extend ClassMethods
          
          key parent_id_field,  String
          key path_field,       String,  :default => ""
          key depth_field,      Integer, :default => 0
          
          after_save      :move_children
          before_save     :will_save_tree
          # before_destroy  :destroy_descendants
        end
      end
      
      module ClassMethods
        def roots
          self.find(:all, :conditions => {parent_id_field => nil}, :order => tree_order)
        end
      end
      
      module InstanceMethods
        def ==(other)
          return true if other.equal?(self)
          return true if other.instance_of?(self.class) and other._id == self._id
          false
        end
      
        def parent=(var)
          var = self.find(var) if var.is_a? String
          
          if self.descendents.include? var
            @_cyclic = true
          else
            @_parent = var
            fix_position
            @_will_move = true
          end
        end
        
        def will_save_tree
          !@_cyclic
        end
        
        def fix_position
          if parent.nil?
            self[parent_id_field] = nil
            self[path_field] = ""
            self[depth_field] = 0
          else
            self[parent_id_field] = parent.id
            self[path_field] = parent[path_field] + ":" + parent.id.to_s
            self[depth_field] = parent[depth_field] + 1
          end
        end
        
        def parent
          @_parent or (self[parent_id_field] ? self.class.find(self[parent_id_field]) : nil)
        end
        
        def root?
          self[parent_id_field].nil?
        end
        
        def root
          self.class.find(self[path_field].split(":")[1]) or self
        end
        
        def ancestors
          return [] if root?
          self.class.find(self[path_field].split(":")[1..-1].collect{|i| Mongo::ObjectID.from_string(i)})
        end
        
        def self_and_ancestors
          ancestors << self
        end
        
        def siblings
          self.class.find(:all, :conditions => {:_id => {"$ne" => self._id}, parent_id_field => self[parent_id_field]}, :order => tree_order)
        end
        
        def self_and_siblings
          self.class.find(:all, :conditions => {parent_id_field => self[parent_id_field]}, :order => tree_order)
        end
        
        def children
          self.class.find(:all, :conditions => {parent_id_field => self._id.to_s}, :order => tree_order)
        end
        
        def descendents
          return [] if new_record?
          sorting_options = tree_order.split(",").map(&:strip).map(&:split).map{|item| [item[0], ((item[1].nil? or item[1].downcase == "asc") ? "asc" : "desc")]}.flatten
          self.class.collection.find({path_field => /#{self._id}/}, {:sort => sorting_options}).map{|i| self.class.new(i)} or []
        end
        
        def self_and_descendents
          [self] + self.descendents
        end
        
        def is_ancestor_of?(other)
          !(other[path_field] =~ /#{self._id}/).nil?
        end
        
        def is_or_is_ancestor_of?(other)
          (other == self) or is_ancestor_of?(other)
        end
        
        def is_descendant_of?(other)
          !(self[path_field] =~ /#{other._id}/).nil?
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
      end
    end
  end
end