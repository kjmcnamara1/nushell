export-env { 
    def create_left_prompt [] {
        let c = $nu.default-config-dir | path join scripts prompt.toml | open
        let os = $c.symbols.os | get ((sys).host.name | str downcase | split words | first)
        let path = pwd | str replace $nu.home-path '~'
    
        $"($os)  ($path) "
    }
    
    def create_right_prompt [] {
        # $"(date now | format date %R)   (date now | format date %v)"
        ""
    }
    
    load-env {
        PROMPT_COMMAND_RIGHT: {|| create_right_prompt }
        PROMPT_COMMAND: {|| create_left_prompt }
        
        PROMPT_INDICATOR: {|| ": " }
        PROMPT_INDICATOR_VI_INSERT: {|| "  " }
        PROMPT_INDICATOR_VI_NORMAL: {|| "  " }
        PROMPT_MULTILINE_INDICATOR: {|| "∙∙∙" }

        TRANSIENT_PROMPT_COMMAND: {|| "" }
        TRANSIENT_PROMPT_INDICATOR: {|| ": " }
        TRANSIENT_PROMPT_INDICATOR_VI_INSERT: {|| "❯ " }
        TRANSIENT_PROMPT_INDICATOR_VI_NORMAL: {|| "❮ " }
        TRANSIENT_PROMPT_MULTILINE_INDICATOR: {|| "" }
        TRANSIENT_PROMPT_COMMAND_RIGHT: {|| "" }
    }
 }
