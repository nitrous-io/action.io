require 'spec_helper'

describe Boxer do
  let!(:boxer) do
    Boxer.new(username: 'action',
              hostname: 'fragrant-wind-69',
              region: 'us-west-1',
              public_keys: ['some public key 1', 'some public key 2'],
              ec2_host: 'foreman.ap-southeast-1.action.io',
              ec2_key: 'some private key',
              box_id: 1,
              box_key: 'secrud_box_key',
              user_ids: [1, 42, 24, 69])
  end

  it "should set the right instance vars" do
    boxer.hostname.should    == 'fragrant-wind-69'
    boxer.region.should      == 'us-west-1'
    boxer.public_keys.should == ['some public key 1', 'some public key 2']
    boxer.ec2_host.should    == 'foreman.ap-southeast-1.action.io'
    boxer.ec2_key.should     == 'some private key'
    boxer.box_id.should      == 1
    boxer.box_key.should     == 'secrud_box_key'
    boxer.user_ids.should    == [1, 42, 24, 69]
  end

  describe "#provision_box" do
    context "with an unsupported container type" do
      it "should raise an exception if you try to provision a box" do
        expect {
          boxer.provision_box('java')
        }.to raise_error(Boxer::InvalidContainerTypeError)
      end
    end

    context "with a valid container type" do
      let!(:ssh_connection) { mock("SSH Connection") }

      before do
        Net::SSH.stub!(:start) { ssh_connection }
        Net::SSH.should_receive(:start).and_yield(ssh_connection)
      end

      context "when no more IPs are available on the box" do
        it "should return a nil port/IP/volume_id" do
          ssh_connection.should_receive(:exec!).ordered
                        .with("echo -e 'MULTI\\nBRPOPLPUSH available_ips used_ips 1\\n" +
                             "BRPOPLPUSH available_ports used_ports 1\\n" +
                             "BRPOPLPUSH available_block_devices used_block_devices 1\\n" +
                             "EXEC' | redis-cli -p 65000 -x")
                        .and_return("OK\nQUEUED\nQUEUED\nQUEUED")

          boxer.provision_box('rails').should == {
            host: "foreman.ap-southeast-1.action.io",
            ssh_port: nil,
            volume_id: nil,
            block_device_id: nil
          }
        end
      end

      context "when an IP is available but one port is not available" do
        it "should return a nil port/IP" do
          ssh_connection.should_receive(:exec!).ordered
                        .with("echo -e 'MULTI\\nBRPOPLPUSH available_ips used_ips 1\\n" +
                              "BRPOPLPUSH available_ports used_ports 1\\n" +
                              "BRPOPLPUSH available_block_devices used_block_devices 1\\n" +
                              "EXEC' | redis-cli -p 65000 -x")
                        .and_return("OK\nQUEUED\nQUEUED\nQUEUED\n254")

          boxer.provision_box('rails').should == {
            host: "foreman.ap-southeast-1.action.io",
            ssh_port: nil,
            volume_id: nil,
            block_device_id: nil
          }
        end
      end

      context "when an IP and port are available but a block device ID is not available" do
        it "should return a nil port/IP" do
          ssh_connection.should_receive(:exec!).ordered
                        .with("echo -e 'MULTI\\nBRPOPLPUSH available_ips used_ips 1\\n" +
                              "BRPOPLPUSH available_ports used_ports 1\\n" +
                              "BRPOPLPUSH available_block_devices used_block_devices 1\\n" +
                              "EXEC' | redis-cli -p 65000 -x")
                        .and_return("OK\nQUEUED\nQUEUED\nQUEUED\n254\n10000")

          boxer.provision_box('rails').should == {
            host: "foreman.ap-southeast-1.action.io",
            ssh_port: nil,
            volume_id: nil,
            block_device_id: nil
          }
        end
      end

      context "when an IP and a port are available" do
        it "should run all the required steps to setup the box and return the ip and port" do
          ssh_connection.should_receive(:exec!).ordered
                        .with("echo -e 'MULTI\\nBRPOPLPUSH available_ips used_ips 1\\n" +
                              "BRPOPLPUSH available_ports used_ports 1\\n" +
                              "BRPOPLPUSH available_block_devices used_block_devices 1\\n" +
                              "EXEC' | redis-cli -p 65000 -x")
                        .and_return("OK\nQUEUED\nQUEUED\nQUEUED\n253\n10000\nz15")

          ssh_connection.should_receive(:exec!).ordered
                        .with("source ~/.eucarc; euca-create-volume -z $EC2_ZONE --snapshot snap-f8c07d9e")
                        .and_return("VOLUME vol-bc6a1ada  2 snap-f8c07d9e us-west-1a  creating  2012-07-11T06:45:49.000Z")

          ssh_connection.should_receive(:exec!).ordered
                        .with("source ~/.eucarc; while euca-describe-volumes vol-bc6a1ada | grep -v \"available\" ; do echo ''; done")

          ssh_connection.should_receive(:exec!).ordered
                        .with("source ~/.eucarc; euca-attach-volume vol-bc6a1ada -i $EC2_INSTANCE -d sdz15")

          ssh_connection.should_receive(:exec!).ordered
                        .with("source ~/.eucarc; while euca-describe-volumes vol-bc6a1ada | tail -n 1 | grep -v \"attached\" ; do echo ''; done")

          ssh_connection.should_receive(:exec!).ordered
                        .with("sudo mkdir -p /var/lib/lxc/fragrant-wind-69")

          ssh_connection.should_receive(:exec!).ordered
                        .with("sudo mount -t xfs /dev/xvdz15 /var/lib/lxc/fragrant-wind-69")

          ssh_connection.should_receive(:exec!).ordered
                        .with("sudo sed -i \"s/rails-container-template/fragrant-wind-69/g\" /var/lib/lxc/fragrant-wind-69/config")

          ssh_connection.should_receive(:exec!).ordered
                        .with("sudo sh -c 'echo \"fragrant-wind-69\" > /var/lib/lxc/fragrant-wind-69/rootfs/etc/hostname'")

          # This sets up the network for the container
          ssh_connection.should_receive(:exec!).ordered
                        .with("sudo sh -c \"echo \\\"auto lo\niface lo inet loopback\n\nauto eth0\niface eth0 inet static\n  address 192.168.254.253\n  netmask 255.255.255.0\n  gateway 192.168.254.1\\\" > /var/lib/lxc/fragrant-wind-69/rootfs/etc/network/interfaces\"")
          # This sets up the container to boot up by itself when the host is rebooted
          ssh_connection.should_receive(:exec!).ordered
                        .with("sudo ln -s /var/lib/lxc/fragrant-wind-69/config /etc/lxc/auto/fragrant-wind-69.conf")
          # This setups the correct terminal emulation for the container, otherwise less/man etc. will throw warnings and errors
          ssh_connection.should_receive(:exec!).ordered
                        .with("sudo sh -c \"echo \\\"\nexport TERM=xterm-256color\\\" >> /var/lib/lxc/fragrant-wind-69/rootfs/etc/profile\"")
          # This command sets up the networking on the host to route all
          # connections coming through to the selected port on the host to the container
          ssh_connection.should_receive(:exec!).ordered
                        .with("sudo iptables -t nat -A PREROUTING -p tcp --dport 10000 -j DNAT --to 192.168.254.253:22")
          ssh_connection.should_receive(:exec!).ordered
                        .with(("sudo sh -c \"echo \\\"some public key 1\\\" >> /var/lib/lxc/fragrant-wind-69/rootfs/etc/ssh/univ_public_keys\""))
          ssh_connection.should_receive(:exec!).ordered
                        .with(("sudo sh -c \"echo \\\"some public key 2\\\" >> /var/lib/lxc/fragrant-wind-69/rootfs/etc/ssh/univ_public_keys\""))

          ssh_connection.should_receive(:exec!).ordered
                        .with("sudo mkdir -p /var/lib/lxc/fragrant-wind-69/rootfs/etc/actionio")
          # Add box_key to /etc/actionio/box_key
          ssh_connection.should_receive(:exec!).ordered
                        .with("sudo sh -c 'echo \"secrud_box_key\" > /var/lib/lxc/fragrant-wind-69/rootfs/etc/actionio/box_key'")
          # Add user_ids to /etc/actionio/users
          ssh_connection.should_receive(:exec!).ordered
                        .with("sudo sh -c 'echo \"1\\n42\\n24\\n69\" > /var/lib/lxc/fragrant-wind-69/rootfs/etc/actionio/users'")
          # Add box_id to /etc/actionio/box_id
          ssh_connection.should_receive(:exec!).ordered
                        .with("sudo sh -c 'echo \"1\" > /var/lib/lxc/fragrant-wind-69/rootfs/etc/actionio/box_id'")
          # Add box_id to /etc/actionio/box_id
          ssh_connection.should_receive(:exec!).ordered
                        .with("sudo sh -c 'echo \"action\" > /var/lib/lxc/fragrant-wind-69/rootfs/etc/actionio/box_owner'")
          # Add haproxy rules
          ssh_connection.should_receive(:exec!).ordered
                        .with("echo -e \"sed -i '/#pragma mark ACTION_ACL_MARKER/ a\\\\\\\\\\tacl is_fragrant_wind_69 hdr_beg(Host) -i fragrant-wind-69.\\\\\\n\\tuse_backend fragrant-wind-69 if is_fragrant_wind_69' /etc/haproxy/haproxy.cfg\" | sudo bash")
          ssh_connection.should_receive(:exec!).ordered
                        .with("echo -e \"sed -i '/#pragma mark ACTION_BACKEND_MARKER/ a\\\\\\backend fragrant-wind-69\\\\\\n\\tserver box-server 192.168.254.253 weight 1 maxconn 1024' /etc/haproxy/haproxy.cfg\" | sudo bash")
          # Restart HAProxy
          ssh_connection.should_receive(:exec!).ordered
                        .with("sudo /etc/init.d/haproxy reload")

          boxer.provision_box('rails').should == {
            host: "foreman.ap-southeast-1.action.io",
            ssh_port: '10000',
            volume_id: 'vol-bc6a1ada',
            block_device_id: 'z15'
          }
        end
      end
    end
  end

  describe "#status" do
    let!(:ssh_connection) { mock("SSH Connection") }

    before do
      Net::SSH.stub!(:start) { ssh_connection }
      Net::SSH.should_receive(:start).and_yield(ssh_connection)
    end

    context "when the box does not exist" do
      it "should return :terminated" do
        ssh_connection.should_receive(:exec!).ordered
                      .with("sudo ls /var/lib/lxc/fragrant-wind-69")
                      .and_return("ls: cannot access /var/lib/lxc/fragrant-wind-69: No such file or directory")

        boxer.status.should == :terminated
      end
    end

    context "when the box exists" do
      context "when the box is running" do
        it "should return :ready" do
          ssh_connection.should_receive(:exec!).ordered
                        .with("sudo ls /var/lib/lxc/fragrant-wind-69")
                        .and_return("config\tfstab\trootfs")

          ssh_connection.should_receive(:exec!).ordered
                        .with("sudo lxc-info -n fragrant-wind-69")
                        .and_return("state:\tRUNNING\npid:\t789")

          boxer.status.should == :ready
        end
      end

      context "when the box is not running" do
        it "should return :ready" do
          ssh_connection.should_receive(:exec!).ordered
                        .with("sudo ls /var/lib/lxc/fragrant-wind-69")
                        .and_return("config\tfstab\trootfs")

          ssh_connection.should_receive(:exec!).ordered
                        .with("sudo lxc-info -n fragrant-wind-69")
                        .and_return("state:\tSTOPPED\nlxc-info:\t'raging-tiger-1' is not running\npid:\t\t-1")

          boxer.status.should == :shut_down
        end
      end

      context "when the box is frozen" do
        it "should return :frozen" do
          ssh_connection.should_receive(:exec!).ordered
                        .with("sudo ls /var/lib/lxc/fragrant-wind-69")
                        .and_return("config\tfstab\trootfs")

          ssh_connection.should_receive(:exec!).ordered
                        .with("sudo lxc-info -n fragrant-wind-69")
                        .and_return("state:\tFROZEN\nlxc-info:\t'raging-tiger-1' is not running\npid:\t\t-1")

          boxer.status.should == :frozen
        end
      end
    end
  end

  describe "#terminate_box" do
    let!(:ssh_connection) { mock("SSH Connection") }

    before do
      Net::SSH.stub!(:start) { ssh_connection }
      Net::SSH.should_receive(:start).and_yield(ssh_connection)
    end

    context "when the box does not exist" do
      it "should return false" do
        ssh_connection.should_receive(:exec!).ordered
                      .with("sudo ls /var/lib/lxc/fragrant-wind-69")
                      .and_return("ls: cannot access /var/lib/lxc/fragrant-wind-69: No such file or directory")


        boxer.terminate_box.should == false
      end
    end

    context "when the box does exist" do
      it "should return true" do
        ssh_connection.should_receive(:exec!).ordered
                      .with("sudo ls /var/lib/lxc/fragrant-wind-69")
                      .and_return("config\tfstab\trootfs")

        ssh_connection.should_receive(:exec!).ordered
                      .with("sudo grep 'address 192\.168\.254\.' /var/lib/lxc/fragrant-wind-69/rootfs/etc/network/interfaces")
                      .and_return("address 192.168.254.217")

        ssh_connection.should_receive(:exec!).ordered
                      .with("sudo iptables -L PREROUTING -t nat --line-numbers | grep 192.168.254.217")
                      .and_return("3\tDNAT\t\ttcp\t--\tanywhere\t\t\tanywhere\t\t\ttcp dpt:10248 to:192.168.254.217:22\n")

        ssh_connection.should_receive(:exec!).ordered
                      .with("sudo lxc-stop -n fragrant-wind-69")

        ssh_connection.should_receive(:exec!).ordered
                      .with("sudo lxc-destroy -n fragrant-wind-69")

        ssh_connection.should_receive(:exec!).ordered
                      .with("sudo iptables -L PREROUTING -t nat --line-numbers | grep dpt:10248")
                      .and_return("3\tDNAT\t\ttcp\t--\tanywhere\t\t\tanywhere\t\t\ttcp dpt:10248 to:192.168.254.217:22\n")

        ssh_connection.should_receive(:exec!).ordered
                      .with("sudo iptables -D PREROUTING 3 -t nat")

        ssh_connection.should_receive(:exec!).ordered
                      .with("echo -e 'MULTI\\nLREM used_ports 0 10248\\nRPUSH available_ports 10248\\nLREM used_ips 0 217\\nRPUSH available_ips 217\\nEXEC' | redis-cli -p 65000 -x")

        ssh_connection.should_receive(:exec!).ordered
                      .with("sudo sed -i \"/fragrant-wind-69\\|192\.168\.254\.217/d\" /etc/haproxy/haproxy.cfg")

        ssh_connection.should_receive(:exec!).ordered
                      .with("sudo /etc/init.d/haproxy reload")

        boxer.terminate_box.should == true
      end
    end
  end

  describe "#shut_down_box" do
    let!(:ssh_connection) { mock("SSH Connection") }

    before do
      Net::SSH.stub!(:start) { ssh_connection }
      Net::SSH.should_receive(:start).and_yield(ssh_connection)
    end

    context "when the box does not exist" do
      it "should return false" do
        ssh_connection.should_receive(:exec!).ordered
                      .with("sudo ls /var/lib/lxc/fragrant-wind-69")
                      .and_return("ls: cannot access /var/lib/lxc/fragrant-wind-69: No such file or directory")

        boxer.shut_down_box.should == false
      end
    end

    context "when the box does exist" do
      it "should return true" do
        ssh_connection.should_receive(:exec!).ordered
                      .with("sudo ls /var/lib/lxc/fragrant-wind-69")
                      .and_return("config\tfstab\trootfs")

        ssh_connection.should_receive(:exec!).ordered
                      .with("sudo lxc-stop -n fragrant-wind-69")

        boxer.shut_down_box.should == true
      end
    end
  end

  describe "#start_box" do
    let!(:ssh_connection) { mock("SSH Connection") }

    before do
      Net::SSH.stub!(:start) { ssh_connection }
      Net::SSH.should_receive(:start).and_yield(ssh_connection)
    end

    context "when the box does not exist" do
      it "should return false" do
        ssh_connection.should_receive(:exec!).ordered
                      .with("sudo ls /var/lib/lxc/fragrant-wind-69")
                      .and_return("ls: cannot access /var/lib/lxc/fragrant-wind-69: No such file or directory")


        boxer.start_box.should == false
      end
    end


    context "when the box does exist" do
      it "should return true" do
        ssh_connection.should_receive(:exec!).ordered
                      .with("sudo ls /var/lib/lxc/fragrant-wind-69")
                      .and_return("config\tfstab\trootfs")

        ssh_connection.should_receive(:exec!).ordered
                      .with("sudo lxc-start -n fragrant-wind-69 -d")
        ssh_connection.should_receive(:exec!).ordered
                      .with("sudo lxc-wait -n fragrant-wind-69")

        boxer.start_box.should == true
      end
    end
  end

  describe "#freeze_box" do
    let!(:ssh_connection) { mock("SSH Connection") }

    before do
      Net::SSH.stub!(:start) { ssh_connection }
      Net::SSH.should_receive(:start).and_yield(ssh_connection)
    end

    context "when the box does not exist" do
      it "should return false" do
        ssh_connection.should_receive(:exec!).ordered
                      .with("sudo ls /var/lib/lxc/fragrant-wind-69")
                      .and_return("ls: cannot access /var/lib/lxc/fragrant-wind-69: No such file or directory")

        boxer.freeze_box.should == false
      end
    end


    context "when the box does exist" do
      it "should return true" do
        ssh_connection.should_receive(:exec!).ordered
                      .with("sudo ls /var/lib/lxc/fragrant-wind-69")
                      .and_return("config\tfstab\trootfs")

        ssh_connection.should_receive(:exec!).ordered
                      .with("sudo lxc-freeze -n fragrant-wind-69")

        boxer.freeze_box.should == true
      end
    end
  end

  describe "#unfreeze_box" do
    let!(:ssh_connection) { mock("SSH Connection") }

    before do
      Net::SSH.stub!(:start) { ssh_connection }
      Net::SSH.should_receive(:start).and_yield(ssh_connection)
    end

    context "when the box does not exist" do
      it "should return false" do
        ssh_connection.should_receive(:exec!).ordered
                      .with("sudo ls /var/lib/lxc/fragrant-wind-69")
                      .and_return("ls: cannot access /var/lib/lxc/fragrant-wind-69: No such file or directory")

        boxer.unfreeze_box.should == false
      end
    end

    context "when the box does exist" do
      it "should return true" do
        ssh_connection.should_receive(:exec!).ordered
                      .with("sudo ls /var/lib/lxc/fragrant-wind-69")
                      .and_return("config\tfstab\trootfs")

        ssh_connection.should_receive(:exec!).ordered
                      .with("sudo lxc-unfreeze -n fragrant-wind-69")

        boxer.unfreeze_box.should == true
      end
    end
  end

  describe "#add_key" do
    let!(:ssh_connection) { mock("SSH Connection") }

    before do
      Net::SSH.stub!(:start) { ssh_connection }
      Net::SSH.should_receive(:start).and_yield(ssh_connection)
    end

    context "when the box does not exist" do
      it "should return false" do
        ssh_connection.should_receive(:exec!).ordered
                      .with("sudo ls /var/lib/lxc/fragrant-wind-69")
                      .and_return("ls: cannot access /var/lib/lxc/fragrant-wind-69: No such file or directory")

        boxer.add_key('public_key').should == false
      end
    end

    context "when the box does exist" do
      it "should return true" do
        ssh_connection.should_receive(:exec!).ordered
                      .with("sudo ls /var/lib/lxc/fragrant-wind-69")
                      .and_return("config\tfstab\trootfs")

        ssh_connection.should_receive(:exec!).ordered
                      .with("sudo sh -c 'echo \"public_key\" >> /var/lib/lxc/fragrant-wind-69/rootfs/etc/ssh/univ_public_keys'")

        ssh_connection.should_receive(:exec!).ordered
                      .with("sudo chroot /var/lib/lxc/fragrant-wind-69/rootfs chown -R action:action /etc/ssh/univ_public_keys")

        boxer.add_key('public_key').should == true
      end
    end
  end

  describe "#delete_key" do
    let!(:ssh_connection) { mock("SSH Connection") }

    before do
      Net::SSH.stub!(:start) { ssh_connection }
      Net::SSH.should_receive(:start).and_yield(ssh_connection)
    end

    context "when the box does not exist" do
      it "should return false" do
        ssh_connection.should_receive(:exec!).ordered
                      .with("sudo ls /var/lib/lxc/fragrant-wind-69")
                      .and_return("ls: cannot access /var/lib/lxc/fragrant-wind-69: No such file or directory")

        boxer.delete_key('public_key').should == false
      end
    end

    context "when the box does exist" do
      context "when the authorized_keys file does not exist" do
        it "should return true" do
          ssh_connection.should_receive(:exec!).ordered
                        .with("sudo ls /var/lib/lxc/fragrant-wind-69")
                        .and_return("config\tfstab\trootfs")

          ssh_connection.should_receive(:exec!).ordered
                        .with("sudo ls /var/lib/lxc/fragrant-wind-69/rootfs/etc/ssh/univ_public_keys")
                        .and_return("ls: cannot access /var/lib/lxc/fragrant-wind-69/rootfs/etc/ssh/univ_public_keys: No such file or directory")

          boxer.delete_key('public_key').should == false
        end
      end

      context "when the authorized_keys file does exist" do
        it "should return true" do
          ssh_connection.should_receive(:exec!).ordered
                        .with("sudo ls /var/lib/lxc/fragrant-wind-69")
                        .and_return("config\tfstab\trootfs")

          ssh_connection.should_receive(:exec!).ordered
                        .with("sudo ls /var/lib/lxc/fragrant-wind-69/rootfs/etc/ssh/univ_public_keys")
                        .and_return("-rw------- 1 action action 404 2012-04-20 09:49 /var/lib/lxc/fragrant-wind-69/rootfs/etc/ssh/univ_public_keys")

          ssh_connection.should_receive(:exec!).ordered
                        .with("sudo sh -c 'sed -i \"s/public_key\\/==//g\" /var/lib/lxc/fragrant-wind-69/rootfs/etc/ssh/univ_public_keys'")

          ssh_connection.should_receive(:exec!).ordered
                        .with("sudo chroot /var/lib/lxc/fragrant-wind-69/rootfs chown -R action:action /etc/ssh/univ_public_keys")

          boxer.delete_key('public_key/==').should == true
        end
      end
    end
  end

end
