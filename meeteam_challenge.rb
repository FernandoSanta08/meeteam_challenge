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
    @state = 0
    @accept_proposal = false
  end

  def add_neighbor(node)
    @neighbors << node
  end
  
  def message(message, node_destination)
    neighbors = node_destination ? @neighbors.select{|neighbor| node_destination.include? neighbor.id} : @neighbors
    neighbors.each do |neighbor| 
      next if @partitioned.include?(neighbor) || neighbor.failure
      neighbor.receive_message(self, message)
      create_log("message sent from #{self.id} to #{neighbor.id}: #{message}")
    end
  end
  
  def receive_message(sender, message)
    process_message(sender, message)
  end

  def process_message(sender, message)
    if message.is_a?(Hash) && message[:type] == 'propose_state'
      vote = vote_on_state(message[:new_state])
      sender.receive_vote(self.id, vote, message[:new_state])
      create_log("Vote state: #{message}")
    elsif message.is_a?(Hash) && message[:type] == 'update_state'
      update_state(message[:new_state])
      create_log("Update State to: #{message}")
    else
      create_log("Addressed Message: #{message}")
    end
  end

  def create_log(event)
    @log << "[#{Time.now}] Node #{@id}: #{event}"
  end

  def add_partitioned(node)
    @partitioned += node
  end

  def node_failure
    @failure = true
    create_log("Failure in Node #{id}")
  end

  def propose_state(new_state)
    create_log("Proposing new state: #{new_state}")
    @votes = {}
    @neighbors.each do |neighbor|
      next if @partitioned.include?(neighbor) || neighbor.failure
      neighbor.receive_message(self, {type: 'propose_state', new_state: new_state})
    end
    @votes[self.id] = vote_on_state(new_state)
    check_consensus(new_state)
  end

  def vote_on_state(new_state)
    new_state > @state
  end

  def receive_vote(sender_id, vote, proposed_state)
    @votes[sender_id] = vote
    check_consensus(proposed_state)
  end

  def check_consensus(proposed_state)
    active_nodes = @neighbors.reject { |n| @partitioned.include?(n) || n.failure }.map(&:id) + [self.id]
    if @votes.keys.sort == active_nodes.sort
      if @votes.values.all?
        update_state(proposed_state)
        @neighbors.each do |neighbor|
          next if @partitioned.include?(neighbor) || neighbor.failure
          neighbor.receive_message(self, {type: 'update_state', new_state: proposed_state})
        end
      else
        create_log("Consensus not reached for state: #{proposed_state}")
      end
      @votes.clear
    end
  end

  def update_state(new_state)
    @state = new_state
    create_log("Updated state to: #{@state}")
  end
  
  def retrieve_log
    @log.join("\n")
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
node1.propose_state(150)
node2.propose_state(20)
node3.add_partitioned([node1])
node2.propose_state(200)
puts node1.retrieve_log
puts node2.retrieve_log
puts node3.retrieve_log
