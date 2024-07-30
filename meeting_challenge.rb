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
end