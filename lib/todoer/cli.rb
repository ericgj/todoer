Dir[File.expand_path('commands/*',File.dirname(__FILE__))].each do |f|
  require f
end

module Todoer

  module CLI
  
    module Commands
    end
    
    def self.command(cmd, opts)
      Commands.const_get(cmd.to_s.capitalize).new(environment(opts))
    rescue
      raise ArgumentError, "Command '#{cmd}' not defined"
    end
    
    def self.environment(opts)
      Environment.new(opts)
    end
    
  end
  
  # convert command-line options to environment.sources
  # and control read/writes to projects-list file
  class Environment

    DEFAULT_GLOBAL_TODO   = '~/.todo'
    DEFAULT_PROJECTS_LIST = '~/.todo/projects.yaml'
    
    class << self
      attr_reader :settings
      def settings; 
        @settings ||= {:global_todo   => self::DEFAULT_GLOBAL_TODO,
                       :projects_list => self::DEFAULT_PROJECTS_LIST
                      }
      end
    end
    
    def global_todo;   self.class.settings[:global_todo];   end
    def projects_list; self.class.settings[:projects_list]; end
    
    def sources
      return @sources if @sources
      @sources = 
        if @all
          all_projects
        elsif @project
          {@project.to_sym => project(@project)}
        else
          {}
        end
      @sources.merge!(:global => global_todo) if @global || @all
      @sources
    end
    
    def project_sources
      sources.reject {|(k,_)| k==:global}
    end
    
    def all_projects
      name = projects_list
      if File.exists?(name)
        parse_projects(name)
      else
        {}
      end
    end
    
    def project(proj)
      all_projects.fetch(proj.to_sym, proj)
    end
    
    def initialize(opts)
      init_settings
      @all, @global, @project = opts[:all], opts[:global], opts[:project]
    end
        
    # TODO: read in settings from ~/.todo/settings.yaml
    # which may change location of global todo, projects list files etc.
    def init_settings
    end
    
    def reset
      @sources = nil
    end
   
    
    def set(key, value)
      self.class.settings[key] = value
    end
    
    def add_source(key, path=nil)
      sources[key.to_sym] = path || key
    end
    
    # CUT ----------------
    def load
      Todoer.reset
      Todoer.load sources[:global] if sources[:global]
      project_sources.each do |(key, file)|
        Todoer.load(file)
      end
    end
    #---------------
    
    def save!
      save_settings!
      save_sources!
    end
    
    #TODO
    def save_settings!
    end
    
    def save_sources!
      dump_projects all_projects.merge(project_sources),
                    self.class.settings[:projects_list]
    end
    
    private
        
    def dump_projects(hash, file)
      File.open(file, 'w+') do |f|
        f.write YAML.dump(hash)
      end
    end
    
    def parse_projects(file)
      raw = YAML.load_file(file)
      validate raw
      raw.inject({}) {|memo, (k,v)| 
        memo[k.to_sym] = raw[k] 
        memo
      }
    end
    
    def validate(data)
      raise TypeError, "Expected Hash, was #{data.class}" unless Hash === data
      data.each do |(k,v)|
        raise TypeError, "Expected String or Symbol key, was #{k.class}: #{k}" \
          unless String === k || Symbol === k
        raise TypeError, "Expected String value, was #{v.class}: #{v}" \
          unless String === v
      end
    end
    
  end
  
end