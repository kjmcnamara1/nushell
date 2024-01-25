# List directory in a grid sorted by type
export def l [path:glob = .] {
    core-ls -s $path | sort-by type name -i | grid -cs '   '
}

# List directory in a grid including hidden files and sorted by type
export def la [path:glob = .] {
    core-ls -sa $path | sort-by type name -i | grid -cs '   '
}

# Long list directory including hidden files with actual folder sizes sorted by type
export def ll [path:glob = .] {
    core-ls -lsa $path | sort-by type name -i #| table -t light
}

# Git status in table format
export def gits [] {
    # TODO: Need to rewrite command 'lsg' for ls with all git stats
    ^git status -s | lines | parse -r '^(.)(.) (.+?)(?: -> (.*))?$' | rename idx tree name new_name
}
