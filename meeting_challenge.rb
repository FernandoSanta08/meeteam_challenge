require 'securerandom'

class Node
  attr_reader :id, :log, :failure

  def initialize(id)
    @uid = SecureRandom.uuid
    @id=id
    @log = []
    @neighbors = []
    @partitioned = []
    @failure = false
  end

  def add_neighbor(node)
    @neighbors << node
  end
  
  def message(message, node_destination)
    neighbors = node_destination ? @neighbors.find{|neighbor| node_destination.include? neighbor.id} : @neighbors
    neighbors = [neighbors].compact unless neighbors.is_a?(Array)
    neighbors.each do |neighbor| 
      next if @partitioned.include? (neighbor) || neighbor.failure
      neighbor.receive_message(self, message)
      create_log("message sent from #{self.id} to #{neighbor.id}: #{message}")
    end
  end
  
  def receive_message(sender, message)
    puts "New message from #{sender.id}: #{message}"
    process_message(message)
  end

  def process_message(message)
    create_log("Addressed Message: #{message}")
  end

  def create_log(event)
    @log << { timestamp: Time.now, event: event }
    puts "[#{Time.now}] Node #{@id}: #{event}"
  end

  def add_partitioned(node)
    @partitioned += node
  end

  def node_failure
    @failure = true
    create_log("Failure in Node #{id}")
  end


end



### TEST

node1 = Node.new(1)
node2 = Node.new(2)
node3 = Node.new(3)
node4 = Node.new(4)
node1.add_neighbor(node2)
node1.add_neighbor(node3)
node2.add_neighbor(node1)
node2.add_neighbor(node3)
node3.add_neighbor(node1)
node3.add_neighbor(node2)
node4.add_neighbor(node1)
node1.add_neighbor(node3)
node4.node_failure
node1.add_partitioned([node3])

node1.message("A", nil)
