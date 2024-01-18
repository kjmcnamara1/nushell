# def "nu-complete poetry commands" [] {
#   poetry list
#   | str replace -r '[\s\S]*?Available commands:' '' 
#   | lines | str trim | compact -e | str join "\n" 
#   | from ssv -na 
#   | rename value description 
#   | where description != ''
# }
# export extern poetry [command:string@"nu-complete poetry commands"] 

def "nu-complete poetry packages" [context:string] {
  ^poetry search ($context | split words | last) | parse -r '(?P<value>\S+) \([\d.]+\)\s+(?P<description>.*)'
}

def "nu-complete poetry config keys" [context:string] {
  # ^poetry config --list | lines | str replace -r ' .*' '' | get -i ($context | split words | last)
  let keys = [
    cache-dir
    experimental.system-git-client
    installer.max-workers
    installer.modern-installation
    installer.no-binary
    installer.parallel
    virtualenvs.create
    virtualenvs.in-project
    virtualenvs.options.always-copy
    virtualenvs.options.no-pip
    virtualenvs.options.no-setuptools
    virtualenvs.options.system-site-packages
    virtualenvs.path
    virtualenvs.prefer-active-python
    virtualenvs.prompt
    warnings.export
  ]
  let result = $keys | where { |x| $x =~ ($context | split words | last) } 
  if ($result | is-empty) {$keys} else {$result}
}

def "nu-complete poetry config values" [context:string] {
  let defaults = ^poetry config --list | lines | parse -r `(?P<key>\S+) = (?P<value>["'].*["']|\w*)`

}

# Tool for dependency management and packaging in Python
export extern poetry [
  --help            (-h)        # Display help for the given command. When no command is given display help for the list command.
  --quiet           (-q)        # Do not output any message.
  --version         (-V)        # Display this application version.
  --ansi                        # Force ANSI output.
  --no-ansi                     # Disable ANSI output.
  --no-interaction  (-n)        # Do not ask any interactive question.
  --no-plugins                  # Disables plugins.
  --no-cache                    # Disables Poetry source caches.
  --directory       (-C):path=. # The working directory for the Poetry command (defaults to the current working directory).
  --verbose         (-v):int    # Increase the verbosity of messages: 1 for normal output, 2 for more verbose output and 3 for debug.
]

# Shows information about Poetry.
export extern "poetry about" [
  --help            (-h)        # Display help for the given command. When no command is given display help for the list command.
  --quiet           (-q)        # Do not output any message.
  --version         (-V)        # Display this application version.
  --ansi                        # Force ANSI output.
  --no-ansi                     # Disable ANSI output.
  --no-interaction  (-n)        # Do not ask any interactive question.
  --no-plugins                  # Disables plugins.
  --no-cache                    # Disables Poetry source caches.
  --directory       (-C):path=. # The working directory for the Poetry command (defaults to the current working directory).
  --verbose         (-v):int    # Increase the verbosity of messages: 1 for normal output, 2 for more verbose output and 3 for debug.
]

# Adds a new dependency to pyproject.toml.
export extern "poetry add" [
  ...name:string@"nu-complete poetry packages" # The packages to add.
  --group               (-G):string            # The group to add the dependency to. [default: "main"]
  --dev                 (-D)                   # Add as a development dependency. (Deprecated) Use --group=dev instead.
  --editable            (-e)                   # Add vcs/path dependencies as editable.
  --extras              (-E):string            # Extras to activate for the dependency. (multiple values allowed)
  --optional                                   # Add as an optional dependency.
  --python:string                              # Python version for which the dependency must be installed.
  --platform:string                            # Platforms for which the dependency must be installed.
  --source:string                              # Name of the source to use to install the package.
  --allow-prereleases                          # Accept prereleases.
  --dry-run                                    # Output the operations but do not execute anything (implicitly enables --verbose).
  --lock                                       # Do not perform operations (only update the lockfile).
  --help                (-h)                   # Display help for the given command. When no command is given display help for the list command.
  --quiet               (-q)                   # Do not output any message.
  --version             (-V)                   # Display this application version.
  --ansi                                       # Force ANSI output.
  --no-ansi                                    # Disable ANSI output.
  --no-interaction      (-n)                   # Do not ask any interactive question.
  --no-plugins                                 # Disables plugins.
  --no-cache                                   # Disables Poetry source caches.
  --directory           (-C):string            # The working directory for the Poetry command (defaults to the current working directory).
  --verbose             (-v):int               # Increase the verbosity of messages: 1 for normal output, 2 for more verbose output and 3 for debug.
]

# Builds a package, as a tarball and a wheel by default.
export extern "poetry build" [
  ...args
]

# Checks the validity of the pyproject.toml file.
export extern "poetry check" [
  ...args
]

# Manages configuration settings.
export extern "poetry config" [
  key?:string@"nu-complete poetry config keys"     # Setting key.
  value?:string@"nu-complete poetry config values" # Setting value.
  --list                                           # List configuration settings.
  --unset                                          # Unset configuration setting.
  --local                                          # Set/Get from the project's local configuration.
  --help                 (-h)                      # Display help for the given command. When no command is given display help for the list command.
  --quiet                (-q)                      # Do not output any message.
  --version              (-V)                      # Display this application version.
  --ansi                                           # Force ANSI output.
  --no-ansi                                        # Disable ANSI output.
  --no-interaction       (-n)                      # Do not ask any interactive question.
  --no-plugins                                     # Disables plugins.
  --no-cache                                       # Disables Poetry source caches.
  --directory            (-C):path                 # The working directory for the Poetry command (defaults to the current working directory).
  --verbose              (-v):int                  # Increase the verbosity of messages: 1 for normal output, 2 for more verbose output and 3 for debug.
]

# Exports the lock file to alternative formats.
export extern "poetry export" [
  ...args
]

# Displays help for a command.
export extern "poetry help" [
  command_name?:string=help      # The command name [default: "help"]
  --help             (-h)        # Display help for the given command. When no command is given display help for the list command.
  --quiet            (-q)        # Do not output any message.
  --version          (-V)        # Display this application version.
  --ansi                         # Force ANSI output.
  --no-ansi                      # Disable ANSI output.
  --no-interaction   (-n)        # Do not ask any interactive question.
  --no-plugins                   # Disables plugins.
  --no-cache                     # Disables Poetry source caches.
  --directory        (-C):path=. # The working directory for the Poetry command (defaults to the current working directory).
  --verbose          (-v):int    # Increase the verbosity of messages: 1 for normal output, 2 for more verbose output and 3 for debug.
]

# Creates a basic pyproject.toml file in the current directory.
export extern "poetry init" [
  --name:string                           # Name of the package.
  --description:string                    # Description of the package.
  --author:string                         # Author name of the package.
  --python:string                         # Compatible Python versions.
  --dependency:string                     # Package to require, with an optional version constraint, e.g. requests:^2.10.0 or requests=2.11.1. (multiple values allowed)
  --dev-dependency:string                 # Package to require for development, with an optional version constraint, e.g. requests:^2.10.0 or requests=2.11.1. (multiple values allowed)
  --license                   (-l):string # License of the package.
  --help                      (-h)        # Display help for the given command. When no command is given display help for the list command.
  --quiet                     (-q)        # Do not output any message.
  --version                   (-V)        # Display this application version.
  --ansi                                  # Force ANSI output.
  --no-ansi                               # Disable ANSI output.
  --no-interaction            (-n)        # Do not ask any interactive question.
  --no-plugins                            # Disables plugins.
  --no-cache                              # Disables Poetry source caches.
  --directory                 (-C):path   # The working directory for the Poetry command (defaults to the current working directory).
  --verbose                   (-v):int    # Increase the verbosity of messages: 1 for normal output, 2 for more verbose output and 3 for debug.
]

# Installs the project dependencies.
export extern "poetry install" [
  --without:string                    # The dependency groups to ignore. (multiple values allowed)
  --with:string                       # The optional dependency groups to include. (multiple values allowed)
  --only:string                       # The only dependency groups to include. (multiple values allowed)
  --no-dev                            # Do not install the development dependencies. (Deprecated)
  --sync                              # Synchronize the environment with the locked packages and the specified groups.
  --no-root                           # Do not install the root package (the current project).
  --no-directory                      # Do not install any directory path dependencies; useful to install dependencies without source code, e.g. for caching of Docker layers)
  --dry-run                           # Output the operations but do not execute anything (implicitly enables --verbose).
  --remove-untracked                  # Removes packages not present in the lock file. (Deprecated)
  --extras               (-E):string  # Extra sets of dependencies to install. (multiple values allowed)
  --all-extras                        # Install all extra dependencies.
  --only-root                         # Exclude all dependencies.
  --compile                           # Compile Python source files to bytecode. (This option has no effect if modern-installation is disabled because the old installer always compiles.)
  --help                 (-h)         # Display help for the given command. When no command is given display help for the list command.
  --quiet                (-q)         # Do not output any message.
  --version              (-V)         # Display this application version.
  --ansi                              # Force ANSI output.
  --no-ansi                           # Disable ANSI output.
  --no-interaction       (-n)         # Do not ask any interactive question.
  --no-plugins                        # Disables plugins.
  --no-cache                          # Disables Poetry source caches.
  --directory            (-C):path    # The working directory for the Poetry command (defaults to the current working directory).
  --verbose              (-v):int     # Increase the verbosity of messages: 1 for normal output, 2 for more verbose output and 3 for debug.
]

# Lists commands.
export extern "poetry list" [
  --help                 (-h)         # Display help for the given command. When no command is given display help for the list command.
  --quiet                (-q)         # Do not output any message.
  --version              (-V)         # Display this application version.
  --ansi                              # Force ANSI output.
  --no-ansi                           # Disable ANSI output.
  --no-interaction       (-n)         # Do not ask any interactive question.
  --no-plugins                        # Disables plugins.
  --no-cache                          # Disables Poetry source caches.
  --directory            (-C):path    # The working directory for the Poetry command (defaults to the current working directory).
  --verbose              (-v):int     # Increase the verbosity of messages: 1 for normal output, 2 for more verbose output and 3 for debug.
]

# Locks the project dependencies.
export extern "poetry lock" [
  ...args
]

# Creates a new Python project at <path>.
export extern "poetry new" [
  path:path                           # The path to create the project at.
  --name:string                       # Set the resulting package name.
  --src                               # Use the src layout for the project.
  --readme                            # Specify the readme file format. One of md (default) or rst
  --help                 (-h)           # Display help for the given command. When no command is given display help for the list command.
  --quiet                (-q)           # Do not output any message.
  --version              (-V)           # Display this application version.
  --ansi                                # Force ANSI output.
  --no-ansi                             # Disable ANSI output.
  --no-interaction       (-n)           # Do not ask any interactive question.
  --no-plugins                          # Disables plugins.
  --no-cache                            # Disables Poetry source caches.
  --directory            (-C):path=.    # The working directory for the Poetry command (defaults to the current working directory).
  --verbose              (-v):int     # Increase the verbosity of messages: 1 for normal output, 2 for more verbose output and 3 for debug.
]

# Publishes a package to a remote repository.
export extern "poetry publish" [
  ...args
]

# Removes a package from the project dependencies.
export extern "poetry remove" [
  ...packages:string                   # The packages to remove.
  --group              (-G):string     # The group to remove the dependency from.
  --dev                (-D)            # Remove a package from the development dependencies. (Deprecated) Use --group=dev instead.
  --dry-run                            # Output the operations but do not execute anything (implicitly enables --verbose).
  --lock                               # Do not perform operations (only update the lockfile).
  --help            (-h)        # Display help for the given command. When no command is given display help for the list command.
  --quiet           (-q)        # Do not output any message.
  --version         (-V)        # Display this application version.
  --ansi                        # Force ANSI output.
  --no-ansi                     # Disable ANSI output.
  --no-interaction  (-n)        # Do not ask any interactive question.
  --no-plugins                  # Disables plugins.
  --no-cache                    # Disables Poetry source caches.
  --directory       (-C):path=. # The working directory for the Poetry command (defaults to the current working directory).
  --verbose         (-v):int    # Increase the verbosity of messages: 1 for normal output, 2 for more verbose output and 3 for debug.

]

# Runs a command in the appropriate environment.
export extern "poetry run" [
  ...args
]

# Searches for packages on remote repositories.
export extern "poetry search" [
  ...args
]

# Spawns a shell within the virtual environment.
export def 'poetry shell' [] {
    let env_path = ^poetry env info | parse -r 'Virtualenv[\s\S]*?Executable:\s*(.*)' | get capture0.0 
    let activate_script = $env_path | path split | drop | path join activate.nu
    nu -e $'overlay use ($activate_script)'
}

# Shows information about packages.
export extern "poetry show" [
  package?:string                   # The package to inspect
  --without:string                  # The dependency groups to ignore. (multiple values allowed)
  --with:string                     # The optional dependency groups to include. (multiple values allowed)
  --only:string                     # The only dependency groups to include. (multiple values allowed)
  --no-dev                          # Do not list the development dependencies. (Deprecated)
  --tree            (-t)            # List the dependencies as a tree.
  --why                             # When showing the full list, or a --tree for a single package, also display why it's included.
  --latest          (-l)            # Show the latest version.
  --outdated        (-o)            # Show the latest version but only for packages that are outdated.
  --all             (-a)            # Show all packages (even those not compatible with current system).
  --top-level       (-T)            # Show only top-level dependencies.
  --help            (-h)            # Display help for the given command. When no command is given display help for the list command.
  --quiet           (-q)            # Do not output any message.
  --version         (-V)            # Display this application version.
  --ansi                            # Force ANSI output.
  --no-ansi                         # Disable ANSI output.
  --no-interaction  (-n)            # Do not ask any interactive question.
  --no-plugins                      # Disables plugins.
  --no-cache                        # Disables Poetry source caches.
  --directory       (-C):path=.     # The working directory for the Poetry command (defaults to the current working directory).
  --verbose         (-v):int        # Increase the verbosity of messages: 1 for normal output, 2 for more verbose output and 3 for debug.
]

# Update the dependencies as according to the pyproject.toml file.
export extern "poetry update" [
  ...packages:string                # The packages to update
  --without:string                  # The dependency groups to ignore. (multiple values allowed)
  --with:string                     # The optional dependency groups to include. (multiple values allowed)
  --only:string                     # The only dependency groups to include. (multiple values allowed)
  --no-dev                          # Do not update the development dependencies. (Deprecated)
  --dry-run                         # Output the operations but do not execute anything (implicitly enables --verbose).
  --lock                            # Do not perform operations (only update the lockfile).
  --help            (-h)            # Display help for the given command. When no command is given display help for the list command.
  --quiet           (-q)            # Do not output any message.
  --version         (-V)            # Display this application version.
  --ansi                            # Force ANSI output.
  --no-ansi                         # Disable ANSI output.
  --no-interaction  (-n)            # Do not ask any interactive question.
  --no-plugins                      # Disables plugins.
  --no-cache                        # Disables Poetry source caches.
  --directory       (-C):path=.     # The working directory for the Poetry command (defaults to the current working directory).
  --verbose         (-v):int        # Increase the verbosity of messages: 1 for normal output, 2 for more verbose output and 3 for debug.
]

# Shows the version of the project or bumps it when a valid bump rule is provided.
export extern "poetry version" [
  ...args
]

# Clears Poetry's cache.
export extern "poetry cache clear" [
    ...args
]

# List Poetry's caches.
export extern "poetry cache list" [
    ...args
]

# Shows debug information.
export extern "poetry debug info" [
    ...args
]

# Debugs dependency resolution.
export extern "poetry debug resolve" [
    ...args
]

# Displays information about the current environment.
export extern "poetry env info" [
    ...args
]

# Lists all virtualenvs associated with the current project.
export extern "poetry env list" [
    ...args
]

# Remove virtual environments associated with the project.
export extern "poetry env remove" [
    ...args
]

# Activates or creates a new virtualenv for the current project.
export extern "poetry env use" [
    ...args
]

# Add additional packages to Poetry's runtime environment.
export extern "poetry self add" [
    ...args
]

# Install locked packages (incl. addons) required by this Poetry installation.
export extern "poetry self install" [
    ...args
]

# Lock the Poetry installation's system requirements.
export extern "poetry self lock" [
    ...args
]

# Remove additional packages from Poetry's runtime environment.
export extern "poetry self remove" [
    ...args
]

# Show packages from Poetry's runtime environment.
export extern "poetry self show" [
    ...args
]

# Shows information about the currently installed plugins.
export extern "poetry self show plugins" [
    ...args
]

# Updates Poetry to the latest version.
export extern "poetry self update" [
    ...args
]

# Add source configuration for project.
export extern "poetry source add" [
    ...args
]

# Remove source configured for the project.
export extern "poetry source remove" [
    ...args
]

# Show information about sources configured for the project.
export extern "poetry source show" [
    ...args
]
