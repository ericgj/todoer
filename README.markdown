# Todoer
## todo list sanity in bash and ruby

My key requirements, as a user sick of overly complex todo lists, were

- the syntax should be as close to simply writing a note to yourself as possible
- it has to be easy to add or remove something from a todo list wherever you are in the filesystem
- it should be easy to add or remove a task based on previous tasks added
- it should have an intuitive and unobtrusive markup format for specifying tags, persons involved the task, dates, and time estimates, directly in the task description
- it should _not_ encourage you to move around, recategorize, tag, or make pretty tasks or otherwise spend your time working on the list rather than on the things you have to do.
- it _should_ however be very easy to change the due date of a task or change its status (done, etc.) 

And on the technical side,

- it should not make changes to a file that you are also editing manually
- it should not rewrite the file each time a change is made, if possible

### Shell scripts for adding, removing, and changing tasks

The commands to add and remove tasks are one-liner bash scripts to echo the command line to ~/.todo, basically. `++` is add, `xx` is remove. (You can name them whatever you like, of course.)

So
    
    $ ++ personal, start the great american novel
    $ xx freelance myproject, refactor the frobosh modules

results in two records added to ~/.todo :

    + [Tue Sep 20 12:10:13 EDT 2011] personal, start the great american novel
    - [Tue Sep 20 12:10:50 EDT 2011] freelance myproject, refactor the frobosh modules

Anything before the first comma is treated as categories, anything after is the task itself.

So this gives you basically a log file. 

I decided I wanted to use bash autocompletion to much the same effect as select menu autocompletion -- as you type it narrows down the choices to previously-entered tasks. Also, the ruby parser matches on the start of the line, so you can just type as much of the line as you need to make it unique and it will handle the rest.

Also I wrote another little bash tool called `==` for append-editing:

    $ ++ personal, start the great american novel
    $ == -a 'novel$' 'tomorrow'

This gives you a '-' and '+' record:

    - [Tue Sep 20 14:15:38 EDT 2011] personal, start the great american novel
    + [Tue Sep 20 14:15:39 EDT 2011] personal, start the great american novel tomorrow

Of course for total flexibility (and nerdity) you could just use sed to edit the file in-place, too.

### Ruby for display

Then I wrote a little Ruby program to parse this and output in various ways.

So with these building blocks you could easily do something like 

- set a directory watcher on the .todo file and automatically redisplay a current todo list as it's edited (see example in `bin/todoer`)
- serve up the .todo file through a web app and provide a GUI for adding tasks
- stream it to loggly or PubSubHubbub it
- parse it into commands to send to your arduino-controlled personal robot over IRC

etc....

It's not rocket science and I've taken ideas from others, but it could be useful. I'm especially happy about the autocompletion, which is such a timesaver. Also it gave me a chance to struggle with bash which I've been wanting to do.

### Markup format

#### Persons: 

    ++ personal, call @mom about @bob proposed dates
    
#### Tags: 

    ++ school, draft =website assignment

As opposed to task _categories_, tags are for cross-cutting concerns.

_Note that I used `=` instead of the twitter `#` convention, mainly because # often has special meaning in other languages (YAML in particular, which I was originally using to display the todo lists)_

    
#### Time estimates: 

    ++ personal, give haircut to @riley ~45m
    
#### Dates: 

    ++ freelance project-x, mockups due 7-Oct-2011 start tue 
    
Note these don't have a special markup, they are just parsed out of the plain English. Relative days are assumed to refer to the _next date from when the task was created_. Date formats are anything that can be Date.parse'd.
