## Notes on edge

### Decentralization

The initial structure of todoer, as an app, assumed a centralized .todo file.  `Todoer.parse('~/.todo')`

But it is often the case where you are starting from an _existing_ todo list. Or you have a bunch of items to add to a list and you want to move them around a bit in your editor rather than deal with a stream editor. So it would be convenient, at the very least, to load these lists into todoer, and subsequently manage them from there.

But even better would be to load in these lists _non-persistently_ : i.e. parse them 'on top of' the centralized .todo, but don't write out records to .todo.  That way, you could simply keep editing your TODO file and it would be treated _as if it were_ records in the .todo log; it's a 'mixed-source' database.

I emphasize the principle that todoer should _never_ overwrite todo lists that are maintained outside of todoer. The aim is to present data from multiple todo lists, some of which todoer itself maintains, while others you edit yourself -- according to whatever your workflow is.


### Adapters and multiple lists

Typically, when you are in a project directory, you want to look at just the todo list for that project. But you still want the ability to look at todo lists across projects, wherever you are, so there should be a way of merging multiple .todo files in a single view.

I've introduced adapters to deal with differently structured todo list files. Right now (in edge) there are two -- the 'todo' stream format, and YAML. I could see others down the road, but for my own use I've found these two are enough.

### Draft CLI

The proposal is to store centralized information under `~/.todo` directory. 
This would include an (optional) centralized todo list, eg. `~/.todo/.todo` 
as well as a dictionary of projects => todo list files, eg. `~/.todo/projects.yaml`

    # View commands
    
    # global list, eg. ~/.todo/.todo 
    todoer list --global  
    
    # current project list, eg. ./.todo 
    todoer list --project  
    
    # default: global list merged with local project list
    todoer list
    
    # global list merged with all registered project lists
    todoer list --all
    
    # specific projects
    todoer list --project project1 --project project2    
    
    
    # Utility commands
    
    # add reference to todo list in current dir
    todoer project add project1 ./TODO   
    
    # remove project reference
    todoer project rm project1      
    
    # create local ./.todo file, reference project using name of folder as default
    todoer init .                       
    
    # or passing explicit project name
    todoer init . --project myproject


Some subtleties of the syntax need to be worked out, but all of the above is basically implemented in the edge branch.

### Testing

Unit and functional tests for what I consider the basic functionality of the CLI and adapters. They may not be 100% passing at the moment but are basically there - run under both Ruby 1.9.3 and 1.8.7. Tests still needed for the existing todoer core classes, and acceptance tests.  


## Notes on the Future

### The stream editing tools.

I want to reimplement them in ruby rather than bash -- including the autocompletion functions. For one thing, I want them to work on Windows (minus the autocompletion) as well as *nix. For another thing, it will be trickier to do autocompletion with decentralized todo files, and I'll have to think about that.

### Templating.

Implement something like
  
    todoer list --template calendar:week

Or direct paths

    todoer list --template ../todo/templates/urgent.erb
    
### Expand adapters to include web services as well as files.

For example write adapters for Google tasks, Tada list, Remember the Milk, Freckle... making it useful for more people.

### Task markup.

I want to modularize how markup is interpreted, so additional/different markup rules could be plugged in 

