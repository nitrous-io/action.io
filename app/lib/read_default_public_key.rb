module ReadDefaultPublicKey
  DEFAULT_USER = "action"

  # Read id_rsa.pub from a box
  #
  # box - instance of `Box`
  def self.run(box)
    key = nil
    private_key = box.key_pairs.first.private_key
    begin
      Net::SSH.start box.host, DEFAULT_USER, port: box.port, key_data: private_key, paranoid: false do |ssh|
        ssh.exec "cat /home/action/.ssh/id_rsa.pub" do |ch, stream, data|
          key = data.strip if stream == :stdout
        end
      end
    rescue Errno::ECONNREFUSED
      return nil # logging of nil to take place in caller
    end
    key
  end
end
