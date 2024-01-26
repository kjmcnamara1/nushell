export-env {
    let c = $nu.default-config-dir | path join scripts prompt.toml | open
    
    def create-prompt [] {
        [
            $"(char newline)(left-prompt)"
            $"(char newline)(ansi default_dimmed)╰─(ansi reset)"
        ] | str join
    }
    
    def left-prompt [] {
        [
            $"(ansi default_dimmed)╭─(ansi reset)"
            (os-group $c.palette.white $c.palette.purple)
            (time-group $c.palette.black $c.palette.white)
            (user-group $c.palette.gray $c.palette.yellow)
            (directory-group $c.palette.white $c.palette.red)
            (python-group $c.palette.yellow $c.palette.blue)
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
    
    def time-group [fg bg] {
        [
            $"(ansi -e {fg:$bg})(ansi reset)"
            $"(ansi -e {fg:$fg bg:$bg})   (date now | format date %X) (ansi reset)"
            $"(ansi -e {fg:$bg})(ansi reset)"
        ] | str join
    }
    
    def user-group [fg bg] {
        let admin = is-admin
        let ssh = is-ssh
        # let bg = match [$admin $ssh] {
        #     [true false] => $c.palette.red
        #     [_ true] => $c.palette.teal
        #     _ => $bg
        # }
        # let fg = if $bg == $c.palette.red { $c.palette.white } | default $fg
        # if true {
        if ($admin or $ssh) {
            [
                $"(ansi -e {fg:$bg})"
                $"(ansi -e {fg:$fg bg:$bg}) "
                (if $admin {ansi $c.palette.red})
                (whoami)
                (ansi $fg)
                @(hostname)
                $" (ansi reset)(ansi -e {fg:$bg})(ansi reset)"
            ] | str join
        }
    }
    
    def hostname [] {
        let ssh = is-ssh
        [
            (sys | get host.hostname)
            (if $ssh {$'(ansi $c.palette.blue) 🌐'})
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
            (git-group $c.palette.black $c.palette.green)
        ] | str join
    }
    
    def path-group [] {
        # Home path subsitution
        let path = pwd | str replace $nu.home-path '~'
        # Directory symbol
        let symbol = if (is-git-path) { 
            $c.symbols.path.git
        } else {
            let base = $path | path split | last | str downcase
            $c.symbols.path | transpose key val | where {|x| $base =~ $x.key} | get -i val.0 | default $c.symbols.path.default
        }
        # Truncate path
        let truncated_path = truncate-path $path 3 $c.symbols.truncate
        # Read-only icon
        let readonly = if (is-readonly) { $" (ansi $c.palette.red)($c.symbols.read_only)" }

        $"($symbol) ($truncated_path)($readonly)"
    }
    
    def git-group [fg bg] {
        if (is-git-path) {
            let branch = ^git branch --show-current | str trim
            [
                $"(ansi -e {bg:$bg}) "
                $"(ansi $fg)($c.symbols.git.branch) ($branch) (ansi reset)"
                $"(ansi $bg)(ansi reset)"
            ] | str join
        }
    }

    def python-group [fg bg] {
        if ($env.VIRTUAL_ENV_PROMPT? != null) {
            [
                $"(ansi -e {fg:$bg}) "
                $"(ansi -e {fg:$fg bg:$bg})  ($env.VIRTUAL_ENV_PROMPT) "
                $"(ansi reset)(ansi -e {fg:$bg})(ansi reset) "
            ] | str join
        }
    }

    def continuation-prompt [] {
        $"(ansi $c.palette.gray)∙(ansi reset)"
    }
    
    def indicator-prompt [mode:string] {
        let characters = { insert:"  " normal:"  " }
        let character = $characters | get $mode
        let format = if ( $env.LAST_EXIT_CODE | into bool ) {
            ansi $c.palette.red
        } else {
            ansi $c.palette.green
        }
    
        $"(ansi reset)($format)($character)(ansi reset)"
    }
    
    def transient-prompt [] {
        # "  "
        $"(char newline)  "
        # $"  (indicator-prompt insert)"
    }

    def transient-right-prompt [] {
        let fg = $c.palette.white
        let bg = $c.palette.purple
        [
            (python-group $c.palette.yellow $c.palette.blue)
            (ansi $bg)
            
            $"(ansi -e {fg:$fg bg:$bg})(pwd | str replace $nu.home-path '~')(ansi reset)"
            (ansi $bg)
            
            (ansi reset)
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
        TRANSIENT_PROMPT_COMMAND: {|| transient-prompt}
        TRANSIENT_PROMPT_COMMAND_RIGHT: {|| transient-right-prompt}
        # TRANSIENT_PROMPT_INDICATOR_VI_INSERT: " ❯ "
    }
}
