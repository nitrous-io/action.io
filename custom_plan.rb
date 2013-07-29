require 'zeus/rails'

# make ssl work with zeus server
class CustomPlan < Zeus::Rails
  def boot
    super
    require 'thin'
    Thin::Server.class_eval do
      def initialize_with_ssl(*args, &block)
        $stdout.sync = true
        $stderr.sync = true

        initialize_without_ssl(*args, &block)

        self.ssl = true
        self.ssl_options = {
          :private_key_file => File.expand_path("../dev/n2odev.com.key", __FILE__),
          :cert_chain_file  => File.expand_path("../dev/n2odev.com.crt", __FILE__),
          :verify_peer => nil
        }
      end

      alias_method :initialize_without_ssl, :initialize
      alias_method :initialize, :initialize_with_ssl
    end
  end
  # def my_custom_command
  #  # see https://github.com/burke/zeus/blob/master/docs/ruby/modifying.md
  # end
end

Zeus.plan = CustomPlan.new
