describe ActiveGraph::Relationship::Property do
  let(:driver) { double('Driver') }

  before do
    @driver = double('Mock Driver')
    allow(clazz).to receive(:neo4j_driver).and_return(driver)
  end

  let(:clazz) do
    Class.new do
      def self.name
        'Clazz'
      end

      include ActiveGraph::Relationship::Property
      include ActiveGraph::Relationship::Types
    end
  end

  describe 'instance methods' do
    describe 'related nodes to/from' do
      it 'creates setters' do
        expect(clazz.new).to respond_to(:to_node=)
        expect(clazz.new).to respond_to(:from_node=)
      end

      it 'creates getters' do
        expect(clazz.new).to respond_to(:to_node)
        expect(clazz.new).to respond_to(:from_node)
      end

      it 'returns the @to and @from values' do
        r = clazz.new
        r.instance_variable_set(:@to_node, 'n1')
        r.instance_variable_set(:@from_node, 'n2')
        expect(r.to_node).to eq 'n1'
        expect(r.from_node).to eq 'n2'
      end
    end

    describe 'type' do
      it 'returns the relationship type set in class' do
        clazz.type 'myrel'
        expect(clazz.new.type).to eq 'myrel'
      end
    end

    describe 'to_class and from_class' do
      context 'when passed valid model classes' do
        it 'sets @from_class and @to_class' do
          expect(clazz.instance_variable_get(:@from_class)).to be_nil
          expect(clazz.instance_variable_get(:@to_class)).to be_nil
          clazz.from_class :Object
          clazz.to_class :Object
          expect(clazz.instance_variable_get(:@from_class)).to eq :Object
          expect(clazz.instance_variable_get(:@to_class)).to eq :Object
        end
      end
    end
  end

  describe 'class methods' do
    describe 'extract_relationship_attributes!' do
      it 'returns the from and to keys and values' do
        expect(clazz.extract_association_attributes!(to_node: 'test', from_node: 'test', name: 'chris')).to eq(to_node: 'test', from_node: 'test')
        expect(clazz.extract_association_attributes!(to_node: 'test', name: 'chris')).to eq(to_node: 'test')
        expect(clazz.extract_association_attributes!(from_node: 'test', name: 'chris')).to eq(from_node: 'test')
      end
    end

    describe 'type' do
      it 'sets @rel_type' do
        clazz.type 'myrel'
        expect(clazz.instance_variable_get(:@rel_type)).to eq 'myrel'
      end
    end

    describe '_type' do
      it 'returns the currently set rel type' do
        clazz.type 'myrel'
        expect(clazz._type).to eq 'myrel'
      end
    end
  end
end
