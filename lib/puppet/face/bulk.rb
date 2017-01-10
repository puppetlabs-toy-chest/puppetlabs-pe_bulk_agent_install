require 'thread'
require 'facter'
require 'puppet/indirector/face'
require 'puppet/util/terminal'
require 'puppet/util/colors'

require 'chloride'

Puppet::Face.define(:bulk, '1.0.0') do
  extend Puppet::Util::Colors

  copyright "Puppet Labs", 2015
  license   "Puppet Enterprise Software License Agreement"

  summary "Handle Bulk Operations such as install/upgrade with Puppet Enterprise"
  description <<-'EOT'
    This subcommand is used to install or upgrade a large number of agent nodes at a time.
  EOT

  action(:install) do

    summary "Perform a bulk agent installation"
    arguments "<node> [<node> ...]"
    description <<-DESC
      This face performs a bulk agent install by triggering a simplified (curl|bash) install
      On the given node set.
      DESC

    option "--credentials=" do
      summary "A JSON file that contains the bulk agent configuration"

      default_to { 'bulk_install.json' }
    end

    option "--sudo" do
      summary "Use sudo to run commands on remote systems"
    end

    option "--threads=" do
      summary "the number of threads to use [defaults to processors times 2]"
      default_to { Facter.value('processors')['count'] * 2 }
    end

    option "--script=" do
      summary "The PE install script to use <install.bash> by default"
      default_to { 'install.bash' }
    end

    option "--nodes=" do
      summary "Path to a new line seperated file containing nodes or [-] for stdin"
      default_to { 'nodes.txt' }
    end

    when_invoked do |*args|

      options = args.pop

      raise "Configuration File missing: #{options[:credentials]}" unless File.exists?(options[:credentials])

      @config = Hash[JSON.parse( IO.read(options[:credentials])).map{ |k, v| [k.to_sym, v] }]
      Puppet.debug("Credentials File: #{@config}")

      if File.exists?(options[:nodes]) || options[:nodes] == '-'
        Puppet.debug($stdin)
        nodes = (options[:nodes] == '-' ? $stdin.each_line : File.foreach(options[:nodes])).map {|line| line.chomp!.split }.flatten
      else
        nodes = args
      end
      Puppet.debug("Nodes:#{nodes}")
      Puppet.debug("Options: #{options}")

      raise ArgumentError, "Please provide at least one node via arg or [--nodes NODES_FILE]" if nodes.empty?

      thread_count    = options[:threads].to_i
      completed_nodes = []
      failed_nodes    = []
      results         = []
      mutex           = Mutex.new

      thread_count.times.map {
        Thread.new(nodes,completed_nodes,options) do |nodes,completed_nodes,options|
          while target = mutex.synchronize { nodes.pop }
            Puppet.notice("Processing target: #{target}")
            begin
              node = Chloride::Host.new(target,@config)
              node.ssh_connect
              Puppet.debug("SSH status: #{node.ssh_status}")
              if [:error,:disconnected].include? node.ssh_status
                mutex.synchronize { failed_nodes  << Hash[target => node.ssh_connect.to_s] }
                next
              end
              # Allow user to pass in -s arguments as hash and reformat for
              # bash to parse them via the -s, such as the csr_attributes
              # custom_attributes:challengePassword=S3cr3tP@ssw0rd
              bash_arguments = @config[:arguments].map{|k,v| "#{v.map{|_k,_v| "%s:%s=%s" % [k,_k,_v]}.join(" ")}"}.unshift("-s").join(" ") unless @config[:arguments].nil?
              install = Chloride::Action::Execute.new(
                :host => node,
                :sudo => options[:sudo],
                :cmd  => "bash -c \"curl -k https://#{@config[:master]}:8140/packages/current/#{options[:script]} | bash #{bash_arguments}\"")
               install.go do |event|
                 event.data[:messages].each do |data|
                   Puppet::Util::Log.with_destination(:syslog) do
                     message = [
                       target,
                       data.message,
                     ].join(' ')
                     # We lose exit codes with curl | bash  so curl errors must
                     # be scraped out of the message in question. We could do
                     # the curl separately and then the install in later
                     # versions of this code to catch curl errors better
                     curl_errors = [
                       /Could not resolve host:.*; Name or service not known/,
                       /^.*curl.*(E|e)rror/
                     ]
                     re = Regexp.union(curl_errors)
                     severity = data.message.match(re) ? :err : data.severity
                     Puppet::Util::Log.newmessage(Puppet::Util::Log.new(:level => severity, :message => message))
                   end
                 end
               end
               if install.success?
                 mutex.synchronize { completed_nodes << Hash[target => install.results[target][:exit_status]] }
               else
                 mutex.synchronize { failed_nodes    << Hash[target => install.results[target][:exit_status]] }
                 Puppet.err "Node: #{target} failed"
               end
            rescue Exception => e
              Puppet.err("target:#{target} error:#{e.to_s}")
              mutex.synchronize { failed_nodes  << Hash[target => e.to_s] }
            end
          end
        end
      }.each(&:join)
      results << completed_nodes
      results << failed_nodes
      results.flatten
    end

    when_rendering(:console) do |output|
      padding = '  '
      headers = {
        'node_name'   => "\e[4mHostname\e[0m",
        'exit_status' => "\e[4mExit Status\e[0m",
      }
      output.unshift({headers.values.first => headers.values.last})

      min_widths = Hash[ *headers.map { |k,v| [k, v.length] }.flatten ]
      min_widths['node_name'] = min_widths['exit_status'] = 40

      min_width = min_widths.inject(0) { |sum,pair| sum += pair.last } + (padding.length * (headers.length - 1))

      terminal_width = [Puppet::Util::Terminal.width, min_width].max

      highlight = proc do |color,s|
        c = colorize(color, s)
        c
      end
      n = 0
      output.collect do |results|

        columns = results.inject(min_widths) do |node_name,exit_status|
          {
            'node_name'   => node_name.length,
            'exit_status' => exit_status.length,
          }
        end

        flex_width = terminal_width - columns['node_name'] - columns['exit_status'] - (padding.length * (headers.length - 1))

        format = %w{node_name exit_status}.map do |k|
          "%-#{ [ columns[k], min_widths[k] ].max }s"
        end.join(padding)
        results.map do |node_name,exit_status|
          n += 1
          if n.odd?
            highlight[ :hwhite,format % [ node_name, exit_status ] ]
          else
            highlight[ :white,format % [ node_name, exit_status ] ]
          end
        end.join
      end
    end
  end
end
