require 'securerandom'

class Node
  attr_accessor :id, :log

  def initialize(id)
    @uid = SecureRandom.uuid
    @id=id
    @log = []
    @neighbors = []
    @partitioned = {}
  end

  def add_neighbor(node)
    @neighbors << node
  end
  
  def message(message, node_destination)
    neighbors = node_destination ? @neighbors.find{|neighbor| node_destination.include? neighbor.id} : @neighbors
    neighbors = [neighbors].compact unless neighbors.is_a?(Array)
    neighbors.each do |neighbor| 
      neighbor.receive_message(self, message)
    end
  end
  
  def receive_message(sender, message)
    # todo: Write log
    puts "New message from #{sender.id}: #{message}"
    process_message(message)
  end

  def process_message(message)
    # todo: Write log
  end

end

### TEST

node1 = Node.new(1)
node2 = Node.new(2)
node3 = Node.new(3)
node1.add_neighbor(node2)
node1.add_neighbor(node3)
node2.add_neighbor(node1)
node2.add_neighbor(node3)
node3.add_neighbor(node1)
node3.add_neighbor(node2)
node1.message("test", nil)
