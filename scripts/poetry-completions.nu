# def "nu-complete poetry commands" [] {
#   poetry list
#   | str replace -r '[\s\S]*?Available commands:' '' 
#   | lines | str trim | compact -e | str join "\n" 
#   | from ssv -na 
#   | rename value description 
#   | where description != ''
# }
# export extern poetry [command:string@"nu-complete poetry commands"] 

# Recursively search for pyproject.toml file in parent directories. Return file path or null.
def find_pyproject [] {
  mut last_dir = ''
  while ((pwd) != $last_dir) {
    $last_dir = (pwd)
    let result = ls -af | where name =~ pyproject.toml
    if ($result | is-empty | not $in) { return $result.name.0 }
    cd ..
  }
}

def "nu-complete poetry commands" [] {
  [
    [value                description];
    [`about`              `Shows information about Poetry.`]
    [`add`                `Adds a new dependency to pyproject.toml.`]
    [`build`              `Builds a package, as a tarball and a wheel by default.`]
    [`check`              `Validates the content of the pyproject.toml file and its consistency with the poetry.lock file.`]
    [`config`             `Manages configuration settings.`]
    [`export`             `Exports the lock file to alternative formats.`]
    [`help`               `Displays help for a command.`]
    [`init`               `Creates a basic pyproject.toml file in the current directory.`]
    [`install`            `Installs the project dependencies.`]
    [`list`               `Lists commands.`]
    [`lock`               `Locks the project dependencies.`]
    [`new`                `Creates a new Python project at <path>.`]
    [`publish`            `Publishes a package to a remote repository.`]
    [`remove`             `Removes a package from the project dependencies.`]
    [`run`                `Runs a command in the appropriate environment.`]
    [`search`             `Searches for packages on remote repositories.`]
    [`shell`              `Spawns a shell within the virtual environment.`]
    [`show`               `Shows information about packages.`]
    [`update`             `Update the dependencies as according to the pyproject.toml file.`]
    [`version`            `Shows the version of the project or bumps it when a valid bump rule is provided.`]
    [`cache clear`        `Clears a Poetry cache by name.`]
    [`cache list`         `List Poetry's caches.`]
    [`debug info`         `Shows debug information.`]
    [`debug resolve`      `Debugs dependency resolution.`]
    [`env info`           `Displays information about the current environment.`]
    [`env list`           `Lists all virtualenvs associated with the current project.`]
    [`env remove`         `Remove virtual environments associated with the project.`]
    [`env use`            `Activates or creates a new virtualenv for the current project.`]
    [`self add`           `Add additional packages to Poetry's runtime environment.`]
    [`self install`       `Install locked packages (incl. addons) required by this Poetry installation.`]
    [`self lock`          `Lock the Poetry installation's system requirements.`]
    [`self remove`        `Remove additional packages from Poetry's runtime environment.`]
    [`self show`          `Show packages from Poetry's runtime environment.`]
    [`self show plugins`  `Shows information about the currently installed plugins.`]
    [`self update`        `Updates Poetry to the latest version.`]
    [`source add`         `Add source configuration for project.`]
    [`source remove`      `Remove source configured for the project.`]
    [`source show`        `Show information about sources configured for the project.`]
  ]
}

def "nu-complete poetry add packages" [context:string] {
  if ($context =~ ' $') {
    return []
  } else {
    ^poetry search ($context | split words | last) | parse -r '(?P<value>\S+) \([\d.]+\)\s+(?P<description>.*)'
  }
}

def "nu-complete poetry config keys" [] {
  # ^poetry config --list | lines | str replace -r ' .*' '' | get -i ($context | split words | last)
  [
    [value                                      description];
    [`cache-dir`                                 `The path to the cache directory used by Poetry.`]
    [`experimental.system-git-client`            `Use system git client backend for git related tasks.`]
    [`installer.max-workers`                     `Set the maximum number of workers while using the parallel installer.`]
    [`installer.modern-installation`             `Use a more modern and faster method for package installation.`]
    [`installer.no-binary`                       `Configure package distribution format policy for all or specific packages.`]
    [`installer.parallel`                        `Use parallel execution when using the new (>=1.1.0) installer.`]
    [`virtualenvs.create`                        `Create a new virtual environment if one doesn’t already exist.`]
    [`virtualenvs.in-project`                    `Create the virtualenv inside the project’s root directory.`]
    [`virtualenvs.options.always-copy`           `The --always-copy parameter is passed to virtualenv on creation.`]
    [`virtualenvs.options.no-pip`                `The --no-pip parameter is passed to virtualenv on creation.`]
    [`virtualenvs.options.no-setuptools`         `The --no-setuptools parameter is passed to virtualenv on creation.`]
    [`virtualenvs.options.system-site-packages`  `Give the virtual environment access to the system site-packages directory.`]
    [`virtualenvs.path`                          `Directory where virtual environments will be created.`]
    [`virtualenvs.prefer-active-python`          `Use currently activated Python version to create a new virtual environment.`]
    [`virtualenvs.prompt`                        `Format string defining the prompt to be displayed when the virtual environment is activated.`]
    [`warnings.export`                            ``]
  ]
  # $keys
  # let result = $keys | where { |x| $x =~ ($context | split words | last) } 
  # if ($result | is-empty) {$keys} else {$result}
}

def "nu-complete poetry config values" [context:string] {
  let token = $context | split row ' ' | drop | last
  let values = {
    experimental.system-git-client: [ 'true' 'false' ]
    installer.max-workers: [...1..16]
    installer.modern-installation: [ 'true' 'false' ]
    installer.no-binary: [ 'true' 'false' 'package1,package2']
    installer.parallel: [ 'true' 'false' ]
    virtualenvs.create: [ 'true' 'false' ]
    virtualenvs.in-project: [ 'true' 'false' ]
    virtualenvs.options.always-copy: [ 'true' 'false' ]
    virtualenvs.options.no-pip: [ 'true' 'false' ]
    virtualenvs.options.no-setuptools: [ 'true' 'false' ]
    virtualenvs.options.system-site-packages: [ 'true' 'false' ]
    virtualenvs.prefer-active-python: [ 'true' 'false' ]
    warnings.export: [ 'true' 'false' ]
  }
  $values | get -i $token
}

def "nu-complete poetry build formats" [] { [sdist wheel] }

def "nu-complete poetry groups" [] {
  open (find_pyproject) | get tool.poetry.group | columns
}

def "nu-complete poetry export formats" [] { [constraints.txt requirements.txt] }

# Tool for dependency management and packaging in Python
# export extern poetry [
#   --help            (-h)              # Display help for the given command. When no command is given display help for the list command.
#   --quiet           (-q)              # Do not output any message.
#   --version         (-V)              # Display this application version.
#   --ansi                              # Force ANSI output.
#   --no-ansi                           # Disable ANSI output.
#   --no-interaction  (-n)              # Do not ask any interactive question.
#   --no-plugins                        # Disables plugins.
#   --no-cache                          # Disables Poetry source caches.
#   --directory       (-C)  :path = .   # The working directory for the Poetry command (defaults to the current working directory).
#   --verbose         (-v)  :int        # Increase the verbosity of messages: 1 for normal output, 2 for more verbose output and 3 for debug.
# ]

# Shows information about Poetry.
export extern "poetry about" [
  --help            (-h)              # Display help for the given command. When no command is given display help for the list command.
  --quiet           (-q)              # Do not output any message.
  --version         (-V)              # Display this application version.
  --ansi                              # Force ANSI output.
  --no-ansi                           # Disable ANSI output.
  --no-interaction  (-n)              # Do not ask any interactive question.
  --no-plugins                        # Disables plugins.
  --no-cache                          # Disables Poetry source caches.
  --directory       (-C)  :path = .   # The working directory for the Poetry command (defaults to the current working directory).
  --verbose         (-v)  :int        # Increase the verbosity of messages: 1 for normal output, 2 for more verbose output and 3 for debug.
]

# Adds a new dependency to pyproject.toml.
export extern "poetry add" [
  ...name                     :string@"nu-complete poetry add packages"           # The packages to add.
  --group               (-G)  :string@"nu-complete poetry groups"        = main   # The group to add the dependency to. [default: "main"]
  --dev                 (-D)                                                      # Add as a development dependency. (Deprecated) Use --group=dev instead.
  --editable            (-e)                                                      # Add vcs/path dependencies as editable.
  --extras              (-E)  :string@"nu-complete poetry add packages"           # Extras to activate for the dependency. (multiple values allowed)
  --optional                                                                      # Add as an optional dependency.
  --python                    :string                                             # Python version for which the dependency must be installed.
  --platform                  :string                                             # Platforms for which the dependency must be installed.
  --source                    :string                                             # Name of the source to use to install the package.
  --allow-prereleases                                                             # Accept prereleases.
  --dry-run                                                                       # Output the operations but do not execute anything (implicitly enables --verbose).
  --lock                                                                          # Do not perform operations (only update the lockfile).
]

# Builds a package, as a tarball and a wheel by default.
export extern "poetry build" [
  --format          (-f)  :string@"nu-complete poetry build formats"  # Limit the format to either sdist or wheel.
]

# Validates the content of the pyproject.toml file and its consistency with the poetry.lock file.
export extern "poetry check" [
  --lock                                                              # Checks that poetry.lock exists for the current version of pyproject.toml.
]

# Manages configuration settings.
export extern "poetry config" [
  key?                     :string@"nu-complete poetry config keys"   # Setting key.
  ...value                 :string@"nu-complete poetry config values"    # Setting value.
  --list                                                              # List configuration settings.
  --unset                                                             # Unset configuration setting.
  --local                                                             # Set/Get from the project's local configuration.
] {
  let flags = {'--list':$list '--unset':$unset '--local':$local} 
    | transpose key val | where val | get -i key # | str join ' '
  let args = [...$flags $key ...$value] | compact -e | str join ' '
  nu -c $'^poetry config ($args)'
}

# Exports the lock file to alternative formats.
export extern "poetry export" [
  --format              (-f)  :string@"nu-complete poetry export formats" = requirements.txt  # Format to export to. Currently, only constraints.txt and requirements.txt are supported. [default: "requirements.txt"]
  --output              (-o)  :path                                                           # The name of the output file.
  --without-hashes                                                                            # Exclude hashes from the exported file.
  --without-urls                                                                              # Exclude source repository urls from the exported file.
  --dev                                                                                       # Include development dependencies. (Deprecated)
  --without                   :string                                                         # The dependency groups to ignore. (multiple values allowed)
  --with                      :string                                                         # The optional dependency groups to include. (multiple values allowed)
  --only                      :string                                                         # The only dependency groups to include. (multiple values allowed)
  --extras              (-E)  :string                                                         # Extra sets of dependencies to include. (multiple values allowed)
  --all-extras                                                                                # Include all sets of extra dependencies.
  --with-credentials                                                                          # Include credentials for extra indices.
]

# Displays help for a command.
export extern "poetry help" [
  command_name?               :string@"nu-complete poetry commands" = help              # The command name [default: "help"]
]

# Creates a basic pyproject.toml file in the current directory.
export extern "poetry init" [
  --name                        :string   # Name of the package.
  --description                 :string   # Description of the package.
  --author                      :string   # Author name of the package.
  --python                      :string   # Compatible Python versions.
  --dependency                  :string   # Package to require, with an optional version constraint, e.g. requests:^2.10.0 or requests=2.11.1. (multiple values allowed)
  --dev-dependency              :string   # Package to require for development, with an optional version constraint, e.g. requests:^2.10.0 or requests=2.11.1. (multiple values allowed)
  --license               (-l)  :string   # License of the package.
]

# Installs the project dependencies.
export extern "poetry install" [
  --without                   :string     # The dependency groups to ignore. (multiple values allowed)
  --with                      :string     # The optional dependency groups to include. (multiple values allowed)
  --only                      :string     # The only dependency groups to include. (multiple values allowed)
  --no-dev                                # Do not install the development dependencies. (Deprecated)
  --sync                                  # Synchronize the environment with the locked packages and the specified groups.
  --no-root                               # Do not install the root package (the current project).
  --no-directory                          # Do not install any directory path dependencies; useful to install dependencies without source code, e.g. for caching of Docker layers)
  --dry-run                               # Output the operations but do not execute anything (implicitly enables --verbose).
  --remove-untracked                      # Removes packages not present in the lock file. (Deprecated)
  --extras               (-E) :string     # Extra sets of dependencies to install. (multiple values allowed)
  --all-extras                            # Install all extra dependencies.
  --only-root                             # Exclude all dependencies.
  --compile                               # Compile Python source files to bytecode. (This option has no effect if modern-installation is disabled because the old installer always compiles.)
]

# Lists commands.
export extern "poetry list" [
]

# Locks the project dependencies.
export extern "poetry lock" [
  --no-update            # Do not update locked versions, only refresh lock file.
  --check                # Check that the poetry.lock file corresponds to the current version of pyproject.toml. (Deprecated) Use poetry check --lock instead.
]

# Creates a new Python project at <path>.
export extern "poetry new" [
  path                          :directory  # The path to create the project at.
  --name                        :string     # Set the resulting package name.
  --src                                     # Use the src layout for the project.
  --readme                                  # Specify the readme file format. One of md (default) or rst
]

# Publishes a package to a remote repository.
export extern "poetry publish" [
  --repository               (-r) :string     # The repository to publish the package to.
  --username                 (-u) :string     # The username to access the repository.
  --password                 (-p) :string     # The password to access the repository.
  --cert                          :string     # Certificate authority to access the repository.
  --client-cert                   :string     # Client certificate to access the repository.
  --build                                     # Build the package before publishing.
  --dry-run                                   # Perform all actions except upload the package.
  --skip-existing                             # Ignore errors from files already existing in the repository.
]

# Removes a package from the project dependencies.
export extern "poetry remove" [
  ...packages:string                   # The packages to remove.
  --group              (-G):string     # The group to remove the dependency from.
  --dev                (-D)            # Remove a package from the development dependencies. (Deprecated) Use --group=dev instead.
  --dry-run                            # Output the operations but do not execute anything (implicitly enables --verbose).
  --lock                               # Do not perform operations (only update the lockfile).
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
