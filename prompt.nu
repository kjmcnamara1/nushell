let prompt_config = (open ($nu.default-config-dir + '/prompt.toml'))

def username [] {
    let user = whoami
    let style = if ($user == 'root') { 
        $prompt_config.username.style_root 
    } else { 
        $prompt_config.username.style_user 
    }
}