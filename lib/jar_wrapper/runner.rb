
  class Runner
    def run_jar name, jar_file, java_opts, args
      @jar_file = jar_file
       
      #  forking = ARGV.include?("--fork") and ARGV.first != "install"
      #  no_runner = ARGV.include?("--no-sub-jruby")
      #  jruby = Config::CONFIG["RUBY_INSTALL_NAME"] == "jruby"
      #  osx = !(RUBY_PLATFORM =~/(windows|linux)/)
      #  begin
      #    if forking and not jruby
      #      # jRuby doesn't support fork() because of the runtime stuff...
      #      forking = false
      #      puts 'Forking failed, attempting to start anyway...' if (pid = fork) == -1
      #      exit unless pid.nil? # kill the parent process
      #      
      #      if pid.nil?
      #        # reopen the standard pipes to nothingness
      #        # STDIN.reopen Redcar.null_device
      #        # STDOUT.reopen Redcar.null_device, 'a'
      #        STDERR.reopen STDOUT
      #      end
      #    elsif forking and SPOON_AVAILABLE and ::Spoon.supported?
      #      # so we need to try something different...
      #      
      #      forking = false
      #      construct_command do |command|
      #        command.push('--silent')
      #        ::Spoon.spawnp(*command)
      #      end
      #      exit 0
      #    elsif forking
      #      raise NotImplementedError, "Something weird has happened. Please contact us."
      #    end
      #  rescue NotImplementedError
      #    puts $!.class.name + ": " + $!.message
      #    puts "Forking isn't supported on this system. Sorry."
      #    puts "Starting normally..."
      #  end
      #  
      #  return if no_runner
      #  return if jruby and not osx
      
      construct_command(true, name, java_opts, args) do |command|
        exec(command.join(" "))
      end

    end

    def run_cp name, class_path, main_class, java_opts, args
      @main_class = main_class
      @class_path = class_path
      
      construct_command(false, name, java_opts, args) do |command|
        exec(command.join(" "))
      end

    end    
    # Trade in this Ruby instance for a JRuby instance, loading in a 
    # starter script and passing it some arguments.
    # If --jruby is passed, use the installed version of jruby, instead of 
    # our vendored jarred one (useful for gems).
    def construct_command(exec_mode, name, java_opts=[], args="")
      bin = File.expand_path(File.join(File.dirname(__FILE__), %w{.. .. bin #{name}}))
      #ENV['RUBYOPT'] = nil # disable other native args

      # Windows XP updates

  #       if RUBY_PLATFORM =~ /window/
  # bin = "\"#{bin}\""
  # jruby_complete = "\"#{jruby_complete}\""
  #       end      

      # unfortuanately, ruby doesn't support [a, *b, c]
      command = ["java"]
      command.push(*java_args)

      command.push(*java_opts) if java_opts.length > 0

      if exec_mode
        command.push("-jar", @jar_file)
      else
        command.push("-cp", @class_path)
        command.push(@main_class)
      end

      #command.push("-Djruby.memory.max=500m", "-Djruby.stack.max=1024k", "-cp", jruby_complete, "org.jruby.Main")

      command.push "--debug" if debug_mode?
      # command.push(bin)
      # command.push(*cleaned_args)
      # command.push("--no-sub-jruby", "--ignore-stdin")
      command.push(*args)
      
      puts command.join(' ')
      yield command
    end
    
    # def cleaned_args
    #   # We should never pass --fork to a subprocess
    #   result = ARGV.find_all {|arg| arg != '--fork'}.map do |arg|
    #     if arg =~ /--(.+)=(.+)/
    #       "--" + $1 + "=\"" + $2 + "\""
    #     else
    #       arg
    #     end
    #   end
    #   result.delete("install")
    #   result
    # end
    
    def debug_mode?
      ARGV.include?("--debug")
    end
    
    def java_args
      str = []
      if Config::CONFIG["host_os"] =~ /darwin/
        str.push "-XstartOnFirstThread"
      end
      
      # if ARGV.include?("--load-timings")
      #   str.push "-Djruby.debug.loadService.timing=true"
      # end
      
      jvm_options_probe = JvmOptionsProbe.new
      
      str.push "-d32" if jvm_options_probe.can_use_d32?
      str.push "-client" if jvm_options_probe.can_use_client?
      
      str
    end
  end

