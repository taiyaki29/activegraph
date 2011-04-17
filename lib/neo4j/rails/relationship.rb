module Neo4j
  module Rails
    class Relationship
      include Neo4j::RelationshipMixin

      attr_reader :type

      index :_classname

      # Initialize a Node with a set of properties (or empty if nothing is passed)
      def initialize(*args)
        @type = args[0]
        self.start_node = args[1]
        self.end_node = args[2]
        attributes = args[3]
        reset_attributes
        self.attributes = attributes if attributes.is_a?(Hash)
      end

      def other_node(node) # TODO - compare neo_id instead ?
        if persisted?
          _java_rel.getOtherNode(node._java_node)
        else
          @start_node == (node._java_node || node) ? @end_node : @start_node
        end
      end


      alias_method :get_other_node, :other_node # so it looks like the java version
      
      def to_s
        "id: #{self.object_id}  start_node: #{start_node} end_node: #{end_node} type:#{@type}"
      end
      
      def id
        _java_rel.nil? || neo_id.nil? ? nil : neo_id.to_s
      end

      def hash
        persisted? ? _java_entity.neo_id.hash : super
      end

      def start_node
        @start_node ||= _java_rel && _java_rel.start_node
      end

      def start_node=(node)
        old = @start_node
        @start_node = node
        # TODO should raise exception if not persisted and changed
        if old != @start_node
          old && old.rm_outgoing_rel(type, self)
          @start_node.class != Neo4j::Node && @start_node.add_outgoing_rel(type, self)
        end
      end

      def end_node
        @end_node ||= _java_rel && _java_rel.start_node
      end

      def end_node=(node)
        old = @end_node
        @end_node = node
        # TODO should raise exception if not persisted and changed
        if old != @end_node
          old && old.rm_incoming_rel(type, self)
          @end_node.class != Neo4j::Node && @end_node.add_incoming_rel(type, self)
        end
      end

      def del
        _java_rel.del
      end

      def reset_attributes
        @properties = {}
      end

      # --------------------------------------
      # Public Class Methods
      # --------------------------------------
      class << self
        # NodeMixin overwrites the #new class method but it saves it as orig_new
        # Here, we just get it back to normal
        alias :new :orig_new

        def entity_load(id)
          Neo4j::Relationship.load(id)
        end


        def rule(*)
        end

        def _all
          _indexer.find(:_classname => self)
        end
        
        def load(*ids) # TODO Copied from finders.rb
          result = ids.map { |id| entity_load(id) }
          if ids.length == 1
            result.first
          else
            result
          end
        end

      end

    end


    Relationship.class_eval do
      extend ActiveModel::Translation
      include RelPersistence # handles how to save, create and update the model
      include Attributes # handles how to save and retrieve attributes
      include Mapping::Property # allows some additional options on the #property class method
      include Serialization # enable to_xml and to_json
      include Timestamps # handle created_at, updated_at timestamp properties
      include Validations # enable validations
      include Callbacks # enable callbacks
      include Finders # ActiveRecord style find
    end

  end
end