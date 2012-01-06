require 'fileutils'

module Todoer
  
  # convert command-line options to environment.sources
  # and control read/writes to projects-list file
  class Environment

    DEFAULT_GLOBAL_TODO   = '~/.todo/.todo'
    DEFAULT_LOCAL_TODO   = './.todo'
    DEFAULT_PROJECTS_LIST = '~/.todo/projects.yaml'
    
    class << self
      attr_reader :settings
      def settings
        @settings ||= {:global_todo   => self::DEFAULT_GLOBAL_TODO,
                       :projects_list => self::DEFAULT_PROJECTS_LIST,
                       :local_todo    => self::DEFAULT_LOCAL_TODO
                      }
      end
      
      def blank
        new 
      end
      
    end
    
    attr_reader :options
    
    def global_todo
      File.expand_path(self.class.settings[:global_todo], Dir.pwd)
    end
    def local_todo
      File.expand_path(self.class.settings[:local_todo], Dir.pwd)
    end
    def projects_list
      File.expand_path(self.class.settings[:projects_list], Dir.pwd)
    end
    
    def sources
      return @sources if @sources
      
      @sources = \
        [ @all      ? all_projects             : {} ,
          @projects ? named_projects           : {} ,
          @current  ? {:current => local_todo} : {} ,
          @global   ? {:global => global_todo} : {}
        ].inject({}) { |memo, hash|
          memo.merge(hash)
        }
    end
    
    def project_sources
      sources.reject {|(k,_)| k==:global || k==:current}
    end
    
    def all_projects
      parse_projects || {}
    end
    
    def named_projects
      @projects.inject({}) {|memo, p|
        memo[p.to_sym] = project(p); memo
      }
    end
    
    def project(proj)
      all_projects.fetch(proj.to_sym, File.expand_path(proj, Dir.pwd))
    end
    
    def initialize(opts={})
      init_settings
      default_options = !(opts[:projects_given] || 
                           opts[:global_given] ||
                           opts[:all_given] ||
                           opts[:current_given]
                         )
      if default_options
        @all,  @global, @current, @projects = \
        false, true,    true,     []
      else
        @all,       @global,       @current,       @projects = \
        opts[:all], opts[:global], opts[:current], opts[:project] || []
      end
      @options = {:all => @all,
                  :global => @global,
                  :current => @current,
                  :projects => @projects
                 }
    end
        
    # TODO: read in settings from ~/.todo/settings.yaml
    # which may change location of global todo, projects list files etc.
    def init_settings
    end
    
    def init_projects_list
      unless File.exists?(self.projects_list)
        FileUtils.mkdir_p File.dirname(self.projects_list)
        File.open(projects_list,'w', 0644) do |f| 
          f.write YAML.dump({}) 
        end
      end
    end
    
    def reset
      @sources = nil
    end
   
    
    def set(key, value)
      self.class.settings[key] = value
    end
    
    def add_source(key, path=nil)
      sources[key.to_sym] = File.expand_path(path || key.to_s, Dir.pwd)
    end
    
    def rm_source(key)
      removed_sources << key.to_sym
    end
    
    def save!
      save_settings!
      save_sources!
    end
    
    #TODO
    def save_settings!
    end
    
    def save_sources!
      dump_projects all_projects.merge(project_sources).reject {|(k,v)|
                      removed_sources.include?(k)
                    }
    end
    
    private
        
    def removed_sources; @removed_sources ||= []; end
    
    def dump_projects(hash)
      init_projects_list
      File.open(self.projects_list, 'w') do |f|
        f.write YAML.dump(hash)
      end
    end
    
    def parse_projects
      init_projects_list
      raw = YAML.load_file(self.projects_list)
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