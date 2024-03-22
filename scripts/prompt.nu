# let c = $nu.default-config-dir | path join scripts prompt.toml | open

def create-prompt [--transient] {
    let fill = if $transient { '─' } else { '∙' }
    let left = if $transient { left-prompt --transient } else { left-prompt }
    let right = if $transient { right-prompt --transient } else { right-prompt }
    let len_left = $left | ansi strip | str length -g | $in + (is-ssh | into int)
    let fill_right = $right | fill -a r -c $fill -w ((term size).columns - $len_left)

    [
        "\n" 
        $left 
        (ansi $env.PROMPT_CONFIG.palette.gray)
        $fill_right
    ] | str join
}

def left-prompt [--transient] {
    if $transient { 
        return ''
    }
    [
        (ansi $env.PROMPT_CONFIG.palette.gray) ╭─ (ansi reset)
        (os-group $env.PROMPT_CONFIG.palette.white $env.PROMPT_CONFIG.palette.gray)
        (user-group $env.PROMPT_CONFIG.palette.gray $env.PROMPT_CONFIG.palette.yellow)
        (directory-group $env.PROMPT_CONFIG.palette.white $env.PROMPT_CONFIG.palette.red)
        ' '
    ] | str join
}

def right-prompt [--transient] {
    let virtual_env = if "VIRTUAL_ENV_PROMPT" in $env { $"\(($env.VIRTUAL_ENV_PROMPT)\) "}
    if not $transient {
        return $" (python-group $env.PROMPT_CONFIG.palette.yellow $env.PROMPT_CONFIG.palette.blue)(time-group)"
    }
    [
        ' '
        (ansi $env.PROMPT_CONFIG.palette.blue)
        $virtual_env
        (ansi $env.PROMPT_CONFIG.palette.purple)
        (pwd | str replace $nu.home-path '~')
        (ansi reset)
    ] | str join
}

def os-group [fg bg] {
    let hostname = (sys).host.name | str downcase | split words | first
    let os = $env.PROMPT_CONFIG.symbols.os | get $hostname
    [
        (ansi -e {fg:$bg })  (ansi reset)
        (ansi -e {fg:$fg bg:$bg})
        ' ' ($os) ' '
        (ansi reset)
        (ansi -e {fg:$bg })  (ansi reset)
    ] | str join
}

def user-group [fg bg] {
    let admin = is-admin
    let ssh = is-ssh
    if ($admin or $ssh) {
        [
            (ansi -e {fg:$bg}) 
            (ansi -e {fg:$fg bg:$bg}) ' '
            (if $admin {ansi $env.PROMPT_CONFIG.palette.red})
            (whoami)
            (ansi $fg)
            @ (hostname)
            ' ' (ansi reset) (ansi -e {fg:$bg})  (ansi reset)
        ] | str join
    }
}

def hostname [] {
    [
        (sys | get host.hostname)
        (if (is-ssh) {$'(ansi $env.PROMPT_CONFIG.palette.blue) 🌐'})
    ] | str join
}

def directory-group [fg bg] {
    [
        (ansi -e {fg:$bg}) 
        (ansi -e {fg:$fg bg:$bg})
        ' ' (path-group) ' '
        (ansi reset)
        (ansi $bg)
        (git-group $env.PROMPT_CONFIG.palette.black)
    ] | str join
}

def path-group [] {
    let path = pwd | str replace $nu.home-path '~'
    # Directory symbol
    let symbol = if (is-git-path) { 
        $env.PROMPT_CONFIG.symbols.path.git
    } else {
        let base = $path | path split | last | str downcase
        $env.PROMPT_CONFIG.symbols.path | transpose key val | where {|x| $base =~ $x.key} | get -i val.0 | default $env.PROMPT_CONFIG.symbols.path.default
    }
    let truncated_path = truncate-path $path 3 $env.PROMPT_CONFIG.symbols.truncate
    let readonly = if (is-readonly) { $" (ansi $env.PROMPT_CONFIG.palette.black)($env.PROMPT_CONFIG.symbols.read_only)" }

    $"($symbol) ($truncated_path)($readonly)"
}

def git-group [fg] {
    if not (is-git-path) { return  }
    
    let stats = git-stats
    let flags = $stats | reject branch | 
        items { |key, val| if ($val.val > 0) {$"($val.symbol)($val.val)"} } | 
        compact | str join ' '
    let up_to_date = ($flags | str length -g) > 0
    let bg = if $up_to_date { $env.PROMPT_CONFIG.palette.yellow } else { $env.PROMPT_CONFIG.palette.green }

    [
        (ansi -e {bg:$bg}) ' '
        (ansi $fg)
        ([$stats.branch.symbol $stats.branch.val $flags] | str join ' ')
        ' ' (ansi reset) (ansi $bg)  (ansi reset)
    ] | str join
}

def git-stats []: nothing -> record {
    let branch = ^git branch --show-current | str trim
    let stash = do { ^git stash show -u } | complete | get stdout | lines | length | if $in > 0 { $in - 1 } else { 0 }
    let changes = ^git status -s | lines | parse -r '^(.)(.) (.+?)(?: -> (.*))?$' | rename idx tree name new_name
    let compare = do {^git rev-list --left-right --count $'HEAD...origin/($branch)'} | complete | get stdout | str trim | split chars
    {
        branch: {
            symbol: $env.PROMPT_CONFIG.symbols.git.branch 
            val: $branch 
            }
        ahead: {
            symbol: $env.PROMPT_CONFIG.symbols.git.ahead 
            val: (if ($compare | is-empty) {0} else {$compare | first | into int})
            }
        behind: {
            symbol: $env.PROMPT_CONFIG.symbols.git.behind 
            val: (if ($compare | is-empty) {0} else {$compare | last | into int})
            }
        stashed: {
            symbol: $env.PROMPT_CONFIG.symbols.git.stashed 
            val: ($stash)
            }
        staged: {
            symbol: $env.PROMPT_CONFIG.symbols.git.staged 
            val: ($changes | group-by idx | get M? | length)
            }
        modified: {
            symbol: $env.PROMPT_CONFIG.symbols.git.modified 
            val: ($changes | group-by tree | get M? | length)
            }
        renamed: {
            symbol: $env.PROMPT_CONFIG.symbols.git.renamed 
            val: ($changes | group-by idx | get R? | length)
            }
        deleted: {
            symbol: $env.PROMPT_CONFIG.symbols.git.deleted 
            val: ($changes | default [] | each { |x| $x.idx? == 'D' or $x.tree? == 'D' } | into int | if ($in | is-empty) {0} else {math sum})
            }
        untracked: {
            symbol: $env.PROMPT_CONFIG.symbols.git.untracked 
            val: ($changes | group-by tree | get '?'? | length)
            }
        ignored: {
            symbol: $env.PROMPT_CONFIG.symbols.git.ignored 
            val: ($changes | group-by tree | get '!'? | length)
            }
    }
}

def python-group [fg bg] {
    if ($env.VIRTUAL_ENV_PROMPT? != null) {
        [
            (ansi -e {fg:$bg}) 
            (ansi -e {fg:$fg bg:$bg}) '  ' ($env.VIRTUAL_ENV_PROMPT) ' '
            (ansi reset) (ansi -e {fg:$bg})  (ansi reset) ' '
        ] | str join
    }
}

def cmd-duration-module [fg bg neighbor_bg=white] {
    let min_time = 2000ms
    let duration = ($env.CMD_DURATION_MS | into int) // 1000 | into duration -u sec
    if ($duration > $min_time) {
        [
            (ansi -e {fg:$bg})  (ansi reset)
            (ansi -e {fg:$fg bg:$bg}) ' ' ($duration) '  '
        ] | str join
    } 
}

def time-group [] {
    let fg_time = $env.PROMPT_CONFIG.palette.black
    let bg_time = $env.PROMPT_CONFIG.palette.white
    let fg_date = $env.PROMPT_CONFIG.palette.white
    let bg_date = $env.PROMPT_CONFIG.palette.purple
    let cdm = cmd-duration-module $env.PROMPT_CONFIG.palette.black $env.PROMPT_CONFIG.palette.orange 
    [
        $cdm
        ( ansi -e {fg:$bg_time} )
        ( if $cdm == null {''} else {''} )
        ( ansi -e {fg:$fg_time bg:$bg_time} )
        ' ' (date now | format date %X) '  '
        ( ansi -e {fg:$bg_time bg:$bg_date} )
        
        ' ' (date now | format date %v) '  '
        (ansi reset)
        (ansi -e {fg:$bg_date}) 
        (ansi reset)
    ] | str join
}

def continuation-prompt [char:string=∙ --transient] {
    let length = indicator-prompt insert --transient=$transient
        | ansi strip | split row (char newline) | last | str length -g

    [
        (ansi $env.PROMPT_CONFIG.palette.gray)
        ('' | fill -c $char -w $length)
        (ansi reset)
    ] | str join
}

def complete-indicator-prompt [] {
    [insert normal completion help history]
}

export def indicator-prompt [
    mode:string@'complete-indicator-prompt' =   insert 
    --transient
    ] {
    if $transient { return $"(ansi $env.PROMPT_CONFIG.palette.lake) ❯ (ansi reset)" }

    let characters = { 
        insert:"  " 
        normal:"  " 
        completion:"   " 
        help:" 󰋖  " 
        history:"   "
    }
    let character = $characters | get $mode
    let format = if ( $env.LAST_EXIT_CODE | into bool ) {
        ansi $env.PROMPT_CONFIG.palette.red
    } else {
        ansi $env.PROMPT_CONFIG.palette.green
    }

    [
        (ansi $env.PROMPT_CONFIG.palette.gray)
        │ "\n"           
        ╰─ (ansi reset) $format $character (ansi reset)
    ] | str join
}

def is-ssh [] {
        [
            $env.SSH_TTY? 
            $env.SSH_CONNECTION? 
            $env.SSH_CLIENT?
        ] | any {|| $in != null}
}

def is-readonly [path:path=.] {
    if $nu.os-info.name == 'windows' {
        return ( ls -lD ($path | path expand) | first | get readonly )
    }

    let dir_info = ls -lD ($path | path expand) | select user group mode readonly | first
    let user_match = $dir_info.user == (whoami)
    let permissions = $dir_info.mode | split chars
    
    (
        $dir_info.readonly
        or ($user_match and $permissions.1 == -)
        or (not $user_match and $permissions.7 == -)
    )
}

export def truncate-path [
    path:path=. 
    truncation_length:int=3 
    truncation_symbol:string='...'
] {
    if ($path | path split | length) <= $truncation_length { return $path }

    if (is-git-path $path) {
        let git_parent = $"(get-git-path | path dirname)(char path_sep)" 
        return ($path | path expand | str replace $git_parent '')
    }

    $path
    | path expand
    | path split 
    | last $truncation_length 
    | prepend $truncation_symbol 
    | path join
}

export def is-git-path [path:path=.] {
    cd $path
    do { ^git rev-parse --is-inside-work-tree }
    | complete | get stdout | is-empty | not $in
}

export def get-git-path [path:path=.] {
    if (is-git-path $path) {
        cd $path
        do { ^git rev-parse --git-dir }
        | complete | get stdout | path expand
        | path dirname | path split | path join
    }
}

export-env {
    load-env {
        PROMPT_CONFIG: ( $nu.default-config-dir | path join scripts prompt.toml | open )
        
        VIRTUAL_ENV_DISABLE_PROMPT: true
        
        PROMPT_COMMAND: { || create-prompt }
        # PROMPT_COMMAND_RIGHT: { || right-prompt }
        PROMPT_COMMAND_RIGHT: ''

        PROMPT_INDICATOR: { || indicator-prompt insert }
        PROMPT_INDICATOR_VI_INSERT: { || indicator-prompt insert }
        PROMPT_INDICATOR_VI_NORMAL: { || indicator-prompt normal }
        PROMPT_MULTILINE_INDICATOR: { || continuation-prompt }
        
        TRANSIENT_PROMPT_COMMAND: { || create-prompt --transient }
        # TRANSIENT_PROMPT_COMMAND_RIGHT: { || right-prompt --transient }
        TRANSIENT_PROMPT_COMMAND_RIGHT: ''

        TRANSIENT_PROMPT_INDICATOR: { || indicator-prompt insert --transient }
        TRANSIENT_PROMPT_INDICATOR_VI_INSERT: { || indicator-prompt insert --transient }
        TRANSIENT_PROMPT_INDICATOR_VI_NORMAL: { || indicator-prompt normal --transient }
        TRANSIENT_PROMPT_MULTILINE_INDICATOR: { || continuation-prompt ' ' --transient }
        
        # config: ($env.config? | default {} | merge {
        #     render_right_prompt_on_last_line: false
        # })
    }
}
