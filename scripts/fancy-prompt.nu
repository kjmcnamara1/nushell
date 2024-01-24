# export-env {
    let c = $nu.default-config-dir | path join scripts prompt.toml | open
    
    def create-prompt [] {
        [
            (char newline)
            $"(left-prompt)(prompt-fill)(right-prompt)(char newline)"
            $"(ansi default_dimmed)╰─(ansi reset)"
        ] | str join
    }
    
    def left-prompt [] {
        [
            $"(ansi default_dimmed)╭─(ansi reset)"
            $"(os-group $c.palette.white $c.palette.gray)"
            $"(user-group $c.palette.gray $c.palette.light)"
            $"(directory-group $c.palette.white $c.palette.purple)"
        ] | str join
    }
    
    def prompt-fill [] {
        let left_prompt_length = (left-prompt | ansi strip | split row "\n" | each { || str length -g } | math max)
        let right_prompt_length = (right-prompt | ansi strip | str length -g)
        let fill_length = (
            (term size).columns - 
            ($left_prompt_length + $right_prompt_length) - 
            (if (is-ssh) {3} else {2}) - 
            (if $nu.os-info.name == 'windows' {2} else {0})
        )
        
        $"(ansi $c.palette.gray) ('' | fill -c ∙ -w $fill_length) (ansi reset)"
    }
    
    def right-prompt [] {
        [
            (python-group $c.palette.yellow $c.palette.blue)
            (time-group $c.palette.black $c.palette.white)
        ] | str join
    }
    
    def os-group [fg bg] {
        let hostname = (sys).host.name | str downcase | split words | first
        let os = $c.symbols.os | get $hostname
        [
            $"(ansi -e {fg:$bg })(ansi reset)"
            $"(ansi -e {fg:$fg bg:$bg}) ($os) (ansi reset)"
            $"(ansi -e {fg:$bg })(ansi reset)"
        ] | str join
    }
    
    def user-group [fg bg] {
        let admin = is-admin
        let ssh = is-ssh
        let bg = match [$admin $ssh] {
            [true false] => $c.palette.red
            [_ true] => $c.palette.teal
            _ => $bg
        }
        let fg = if $bg == $c.palette.red { $c.palette.white } | default $fg
        # if true {
        if ($admin or $ssh) {
            [
                $"(ansi -e {fg:$bg})"
                $"(ansi -e {fg:$fg bg:$bg}) "
                (if ($admin and $ssh) {ansi red})
                (whoami)
                (ansi $fg)
                @(hostname)
                $" (ansi reset)(ansi -e {fg:$bg})(ansi reset)"
            ] | str join
        }
    }
    
    def hostname [] {
        [
            # (ansi green_dimmed)
            (sys | get host.hostname)
            (if (is-ssh) {$'(ansi blue_dimmed) 🌐'})
        ] | str join
    }
    
    def directory-group [fg bg] {
        let is_gp = is-git-path
        [
            $"(ansi -e {fg:$bg})"
            $"(ansi -e {fg:$fg bg:$bg}) "
            $"(path-group) (ansi reset)"
            (ansi $bg)
            (if not $is_gp {''})
            (git-group $c.palette.black)
            # (if $is_gp {git-info $c.palette.black $bg})
            # (git-info $c.palette.black $bg)
        ] | str join
    }
    
    def path-group [] {
        # Git path or regular path
        let is_gp = is-git-path
        # let path = if $is_gp {
        #     let git_path = $"(get-git-path | path dirname)(char path_sep)" 
        #     $"($c.symbols.git.symbol) (pwd | str replace $git_path '')"
        # } else {
        #     pwd | str replace $nu.home-path $c.symbols.home
        # }
        # # Directory substitutions
        # let path = $c.symbols.directories |
        #     transpose key val |
        #     reduce -f $path { |it, acc| 
        #         $acc | str replace $it.key $it.val 
        # }
        # # Truncate path
        # let path_length = $path | path split | length
        # let path = if ($path_length > 3) {
        #     if $is_gp {
        #         $path | path split | first | 
        #         append (truncate-path $path (3 - 1) $c.symbols.truncate) |
        #         path join
        #     } else {
        #         truncate-path $path 3 $c.symbols.truncate
        #     }
        # } else { $path }
        # # Read-only icon
        # let readonly = if (is-readonly) { $" (ansi $c.palette.red)($c.symbols.read_only)" }
    
        # $"($path)($readonly)"

        let path = pwd | str replace $nu.home-path '~'

        let symbol = if $is_gp { 
            $c.symbols.path.git
        } else {
            let base = $path | path split | last | str downcase
            $c.symbols.path | transpose key val | where {|x| $base =~ $x.key} | get -i val.0 | default $c.symbols.path.default
        }

        let truncated_path = truncate-path $path 3 $c.symbols.truncate

        let readonly = if (is-readonly) { $" (ansi $c.palette.red)($c.symbols.read_only)" }

        $"($symbol) ($truncated_path)($readonly)"
    }
    
    def git-group [fg] {
        if (is-git-path) {
                let stats = git-stats
                let flags = $stats | reject branch | 
                    items { |key, val| if ($val.val > 0) {$"($val.symbol)($val.val)"} } | 
                    compact | str join ' '
                let up_to_date = ($flags | str length -g) > 0
                let bg = if $up_to_date { $c.palette.yellow } else { $c.palette.green }
            [
                $"(ansi -e {bg:$bg}) "
                $"(ansi $fg)"
                ([$stats.branch.symbol $stats.branch.val $flags] | str join ' ')
                $" (ansi reset)(ansi $bg)(ansi reset)"
            ] | str join
        }
    }
    
    def git-stats [] {
        let branch = ^git branch --show-current | str trim
        let stash = do { ^git stash show -u } | complete | get stdout | lines | length | if $in > 0 { $in - 1 } else { 0 }
        let changes = ^git status -s | lines | parse -r '^(.)(.) (.+?)(?: -> (.*))?$' | rename idx tree name new_name
        let compare = do {^git rev-list --left-right --count $'HEAD...origin/($branch)'} | complete | get stdout | str trim | split chars
        {
            branch: {
                symbol: $c.symbols.git.branch 
                val:$branch 
                }
            ahead: {
                symbol: $c.symbols.git.ahead 
                val: (if ($compare | is-empty) {0} else {$compare | first | into int})
                }
            behind: {
                symbol: $c.symbols.git.behind 
                val: (if ($compare | is-empty) {0} else {$compare | last | into int})
                }
            stashed: {
                symbol: $c.symbols.git.stashed 
                val: ($stash)
                }
            staged: {
                symbol: $c.symbols.git.staged 
                val: ($changes | group-by idx | get M? | length)
                }
            modified: {
                symbol: $c.symbols.git.modified 
                val: ($changes | group-by tree | get M? | length)
                }
            renamed: {
                symbol: $c.symbols.git.renamed 
                val: ($changes | group-by idx | get R? | length)
                }
            deleted: {
                symbol: $c.symbols.git.deleted 
                val: ($changes | default [] | each { |x| $x.idx? == 'D' or $x.tree? == 'D' } | into int | if ($in | is-empty) {0} else {math sum})
                }
            untracked: {
                symbol: $c.symbols.git.untracked 
                val: ($changes | group-by tree | get '?'? | length)
                }
            ignored: {
                symbol: $c.symbols.git.ignored 
                val: ($changes | group-by tree | get '!'? | length)
                }
        }
    }
            
    
    def python-group [fg bg] {
        if ($env.VIRTUAL_ENV_PROMPT? != null) {
            [
                $"(ansi -e {fg:$bg})"
                $"(ansi -e {fg:$fg bg:$bg})  ($env.VIRTUAL_ENV_PROMPT) "
                $"(ansi reset)(ansi -e {fg:$bg})(ansi reset) "
            ] | str join
        }
    }
    
    def cmd-duration-module [fg bg neighbor_bg=white] {
        let min_time = 2000ms
        let duration = ($env.CMD_DURATION_MS | into int) // 1000 | into duration -u sec
        if ($duration > $min_time) {
            [
                $"(ansi -e {fg:$bg})(ansi reset)"
                $"(ansi -e {fg:$fg bg:$bg}) ($duration)  "
                # $"(ansi -e {fg:$neighbor_bg})(ansi reset)"
            ] | str join
        } 
    }
    
    def time-group [fg bg] {
        let cdm = cmd-duration-module $c.palette.black $c.palette.orange 
        [
            $"($cdm)(ansi -e {fg:$bg})"
            (if $cdm == null {''} else {''})
            # (if $cdm != null {$"($cdm)(ansi -e {fg:$bg})"} else {$"(ansi -e {fg:$bg})"})
            # ($cdm | default $"(ansi -e {fg:$bg})")
            $"(ansi -e {fg:$fg bg:$bg}) (date now | format date %X)  (ansi reset)"
            $"(ansi -e {fg:$bg})"
        ] | str join
    }
    
    # def repeat [char:string=' ' times:int=1] {
    #     1..$times | each { || $char } | str join
    # }
    
    def continuation-prompt [] {
        $"(ansi $c.palette.gray)∙∙∙(ansi reset)"
    }
    
    def indicator-prompt [mode:string] {
        let characters = { insert:"  " normal:"  " }
        let character = $characters | get $mode
        let format = if ( $env.LAST_EXIT_CODE | into bool ) {
            ansi $c.palette.red
        } else {
            ansi $c.palette.green
        }
    
        return $"(ansi reset)($format)($character)(ansi reset)"
    }
    
    def transient-prompt [] {
        let fg = $c.palette.white
        let bg = $c.palette.blue
        let ug = user-group $c.palette.gray $c.palette.white | str replace '' ''
        [
            $"(char newline)  "
            ($ug)
            (ansi $bg)
            (if ($ug | is-empty) {''} else {''})
            (ansi -e {fg:$fg bg:$bg})
            $" (pwd | str replace $nu.home-path $c.symbols.home) "
            $"(ansi reset)(ansi $bg)(ansi reset)"
        ] | str join
    }

    def transient-right-prompt [] {
        let fg = $c.palette.black
        let bg = $c.palette.lake
        let duration = $env.CMD_DURATION_MS + 'ms' | into duration 
        [
        #     # (char newline)
            (python-group $c.palette.yellow $c.palette.blue)
        #     $"(ansi $bg)"
        #     (ansi -e {fg:$fg bg:$bg})
        #     $" ($duration)  "
        #     $"(ansi reset)(ansi $bg)(ansi reset)"
            (time-group $c.palette.black $c.palette.white)
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
            ls -lD ($path | path expand) | first | get readonly
        } else {
            let dir_info = ls -lD ($path | path expand) | select user group mode readonly | first
            let user_match = $dir_info.user == (whoami)
            let permissions = $dir_info.mode | split chars
            
            $dir_info.readonly or ($user_match and $permissions.1 == -) or (not $user_match and $permissions.7 == -)
        }
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
            # let git_root = $path | path expand | str replace $git_parent '' | path split
            # if ($git_root | length) > $truncation_length {
            #     return (
            #         $git_root | first
            #         | append $truncation_symbol
            #         | append ($git_root | last ($truncation_length - 1))
            #         | path join
            #     )
            # }
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
        do { ^git rev-parse --is-inside-work-tree } | complete | get stdout | is-empty | not $in
    }
    
    export def get-git-path [path:path=.] {
        if (is-git-path $path) {
            cd $path
            do { ^git rev-parse --git-dir } | complete | get stdout | path expand | path dirname | path split | path join
        }
    }

    load-env {
        VIRTUAL_ENV_DISABLE_PROMPT: true
        PROMPT_COMMAND: {|| create-prompt}
        PROMPT_COMMAND_RIGHT: '' # {|| create_right_prompt}
        PROMPT_INDICATOR_VI_INSERT: {|| indicator-prompt insert}
        PROMPT_INDICATOR_VI_NORMAL: {|| indicator-prompt normal}
        PROMPT_MULTILINE_INDICATOR: (continuation-prompt)
        # TRANSIENT_PROMPT_COMMAND: {|| transient-prompt}
        # TRANSIENT_PROMPT_COMMAND_RIGHT: {|| transient-right-prompt}
        # TRANSIENT_PROMPT_INDICATOR_VI_INSERT: " ❯ "
    }
# }
