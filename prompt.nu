export def prompt_config [] {
    open ($nu.default-config-dir + '/prompt.toml')
}

export def repeat [char:string=' ' times:int=1] {
    1..$times | each { || $char } | str join
}

export def prompt_fill [char:string=' '] {
    let left_prompt_length = (left_prompt | ansi strip | split row "\n" | each { || str length -g } | math max)
    let right_prompt_length = (right_prompt | ansi strip | str length -g)
    let fill_length = (term size).columns - ($left_prompt_length + $right_prompt_length)
    
    repeat $char $fill_length
    # for c in 1..$fill_length { print $char}
    # $left_prompt_length
}

export def create_prompt [] {
    (
        $"(left_prompt)(prompt_fill ∙)(right_prompt)"
        + $"(char newline)(ansi default_dimmed)╰─(ansi reset)"
    )
}

export def left_prompt [] {
    let cfg = prompt_config
    let add_newline = if $cfg.add_newline { char newline } else { "" }
    let prompt = (
        $"(ansi default_dimmed)╭─(ansi reset)"
        + $"(sep round left)(os)(group_sep right)"
        + $"(username)(group_sep right)"
        + $"(directory) "
        )
    # let prompt = $"(ansi default_dimmed)╭─(ansi reset)(os)\n(ansi default_dimmed)╰─(ansi reset)"
    # let prompt = $cfg.format

    $add_newline + $prompt
}

export def right_prompt [] {
    $" (time)"
}
def continuation_prompt [] {
    $"(ansi grey)∙∙∙(ansi reset)"
}
def indicator_prompt [mode:string] {
    let characters = { insert:"  " normal:"  " }
    # match $mode {
    #     insert => { let character = "  " }
    #     normal => { let character = "  " }
    # }
    let character = $characters | get $mode
    let format = if ( $env.LAST_EXIT_CODE | into bool ) { ansi red_bold } else {  ansi green_bold }
    ( ansi reset ) + $format + $character + ( ansi reset )
}

export def sep [
    style:string 
    direction:string 
    fg:string=white
    --bg?:string
] {
    let symbol = match [$style $direction] {
        [round left] => ''
        [round right] => ""
        [angle left] => ''
        [angle right] => ''
        [slant left] => ''
        [slant right] => ''
    }
    # $"(ansi -e {fg:$fg (if ($bg != null) { $'bg:($bg)' })})($symbol)(ansi reset)"
    $symbol
}

export def group_sep [direction:string] {
    match $direction {
        right => ''
        left => ''
    }
}


export def os [] {
    let cfg = prompt_config
    let hostname = (sys).host.name | str downcase | split words | first
    let symbol = $cfg.os.symbols | get $hostname

    $"(ansi -e {fg:black bg:white})($symbol)(ansi reset)"
    # $"(ansi default)(ansi reset)(ansi -e {fg:black bg:white})($symbol)(ansi reset)(ansi default)(ansi reset)"
}


def username [] {
    let cfg = prompt_config
    let user = whoami
    let style = if (is-admin) { 
        $cfg.username.style_root 
    } else { 
        $cfg.username.style_user 
    }

    $"(ansi -e {fg:black bg:white}) ($user)@((sys).host.hostname) (ansi reset)"
}

export def is_readonly [path:path=.] {
    # let dir_user = ^stat -c %U $path
    
    if (sys | get host.long_os_version | split words | first) == Windows {
        ls -lD ($path | path expand) | first | get readonly
    } else {
        let dir_info = ls -lD ($path | path expand) | select user group mode readonly | first
        let user_match = $dir_info.user == (whoami)
        let permissions = $dir_info.mode | split chars
        
        $dir_info.readonly or ($user_match and $permissions.1 == -) or (not $user_match and $permissions.7 == -)
    }
}

# Truncate path
export def truncate_path [
    path:path=. 
    truncation_length:int=3 
    truncation_symbol:string='...'
] {
    $path |path expand | path split | 
    last $truncation_length | 
    prepend $truncation_symbol |
    path join
    # str join (char path_sep)
}

export def directory [] {
    let cfg = (prompt_config).directory
    let home_symbol = $cfg.home_symbol? | default ~
    let truncation_length = $cfg.truncation_length? | default 3
    let truncation_symbol = $cfg.truncation_symbol? | default '...'
    let truncate_to_repo = $cfg.truncate_to_repo? | default true
    let ro_symbol = $cfg.read_only? | default ' '
    
    let path = if (is_git_path) and $truncate_to_repo {
        let git_path = $"(get_git_path | path dirname)/" 
        $" (pwd | str replace $git_path '')"
    } else {
        pwd | str replace $nu.home-path $home_symbol
    }
    

    let path = $cfg.substitutions |
        transpose key val |
        reduce -f $path { |it, acc| 
            $acc | str replace $it.key $it.val 
    }
    
    let path_length = $path | path split | length
    let path = if ($path_length > $truncation_length) {
        if (is_git_path) {
            $path | path split | first | 
            append (truncate_path $path ($truncation_length - 1) $truncation_symbol) |
            path join
        } else {
            truncate_path $path $truncation_length $truncation_symbol
        }
    } else { $path }

    let readonly = if (is_readonly) { $"(ansi red)($ro_symbol)" } | default ''

    let section_cap = if (is_git_path) {git_info} else {sep round right}
    # $path
    $"(ansi -e {fg:black bg:white}) ($path) ($readonly)(ansi reset)($section_cap)"
}

def is_git_path [path:path = .] {
    # '.git' in (ls -a $path | get name)
    (^git rev-parse --is-inside-work-tree err> /dev/null) != ''
}

def get_git_path [path:path = .] {
    if (is_git_path $path) {
        ^git rev-parse --git-dir err> /dev/null | path expand | path dirname
    }
}

export def get_git_status [idx:string tree:string] {
    match [idx tree] {
        [? ?] => untracked
        [! !] => ignored
        [' ' ' '] => unmodified
        [R ' '] => renamed
        [R ' '] => stashed
        [' ' M] => modified
        [M ' '] => staged
        [' ' D] => deleted
        [R ' '] => typechanged
        [R ' '] => ahead
        [R ' '] => behind
        _ => unknown
    }
}
        
def git_info [] {
    let cfg = (prompt_config)
    
    let symbol = $cfg.git_branch.symbol? | default '󰘬'
    let ahead_symbol = $cfg.git_status.ahead? | default '⇡'
    let behind_symbol = $cfg.git_status.behind? | default '⇣'
    let staged_symbol = $cfg.git_status.staged? | default '+'
    let modified_symbol = $cfg.git_status.modified? | default '!'
    let untracked_symbol = $cfg.git_status.untracked? | default '?'
    let ignored_symbol = $cfg.git_status.ignored? | default ''

    let branch = ^git branch --show-current | str trim
    let git_stats = ^git status -s | from ssv -nam 1 | select column1 column2 | rename idx tree
    let git_ahead_behind = $"(^git rev-list --left-right --count $'HEAD...origin/($branch)')" | split chars # | parse -r '(?<ahead>\d+)\s+(?<behind>\d+)' | first
    
    let ahead_count = $git_ahead_behind | first | into int
    let behind_count = $git_ahead_behind | last | into int
    let staged_count = $git_stats | group-by idx | get M? | length
    let modified_count = $git_stats | group-by tree | get M? | length
    let untracked_count = $git_stats | group-by tree | get '?'? | length
    let ignored_count = $git_stats | group-by tree | get '!'? | length

    let ahead = if ($ahead_count > 0) {$"($ahead_symbol)($ahead_count)"}
    let behind = if ($behind_count > 0) {$"($behind_symbol)($behind_count)"}
    let staged = if ($staged_count > 0) {$"($staged_symbol)($staged_count)"}
    let modified = if ($modified_count > 0) {$"($modified_symbol)($modified_count)"}
    let untracked = if ($untracked_count > 0) {$"($untracked_symbol)($untracked_count)"}
    let ignored = if ($ignored_count > 0) {$"($ignored_symbol)($ignored_count)"}
    
    let all_counts = [$ahead_count $behind_count $staged_count $modified_count $untracked_count $ignored_count] | math sum
    let all_flags = [$ahead $behind $staged $modified $untracked $ignored] | where { |x| $x != null } | str join ' ' | str trim

    let bg = if ($all_counts > 0) {'yellow'} else {'green'}

    $"(ansi -e {bg:$bg})(sep angle right) (ansi black)([$symbol $branch $all_flags] | str join ' ' | str trim) (ansi reset)(ansi $bg)(sep round right)(ansi reset)"
    # $git_ahead_behind
}

export def time [] {
    $"(sep round left)(ansi default_reverse) (date now | format date %X)  (ansi reset)(sep round right)"
}

export-env { load-env {
    PROMPT_COMMAND: {|| create_prompt}
    PROMPT_COMMAND_RIGHT: '' # {|| create_right_prompt}
    PROMPT_INDICATOR_VI_INSERT: {|| indicator_prompt insert}
    PROMPT_INDICATOR_VI_NORMAL: {|| indicator_prompt normal}
    PROMPT_MULTILINE_INDICATOR: {|| continuation_prompt}
    # config: ($env.config? | default {} | merge {
    #     render_right_prompt_on_last_line: true
    # })
}}