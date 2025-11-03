# ~/.config/zsh/dev-tools.zsh - Development tools and shortcuts

# Development environment functions and aliases

# Quick project initialization
init_project() {
    local project_type="${1:-generic}"
    local project_name="${2:-$(basename $(pwd))}"
    
    case $project_type in
        "node"|"js"|"javascript")
            npm init -y
            echo "node_modules/\n.env\n.DS_Store\ndist/\nbuild/" > .gitignore
            echo "# $project_name\n\nA Node.js project." > README.md
            ;;
        "python"|"py")
            echo "__pycache__/\n*.pyc\n*.pyo\n*.pyd\n.Python\nvenv/\nenv/\n.env\n.venv\n.DS_Store" > .gitignore
            echo "# $project_name\n\nA Python project." > README.md
            python3 -m venv venv
            echo "Virtual environment created. Run 'source venv/bin/activate' to activate."
            ;;
        "rust")
            cargo init --name "$project_name"
            ;;
        "go")
            go mod init "$project_name"
            echo "# $project_name\n\nA Go project." > README.md
            ;;
        *)
            echo "# $project_name\n\nA new project." > README.md
            echo ".DS_Store\n.env" > .gitignore
            ;;
    esac
    
    # Common initialization
    git init
    git add .
    git commit -m "Initial commit"
    
    echo "Project '$project_name' ($project_type) initialized!"
}

# Quick server shortcuts
serve_static() {
    local port="${1:-8000}"
    echo "Serving current directory at http://localhost:$port"
    python3 -m http.server "$port"
}

serve_php() {
    local port="${1:-8080}"
    echo "Serving PHP at http://localhost:$port"
    php -S "localhost:$port"
}

# Database shortcuts
db_backup() {
    local db_name="$1"
    local backup_name="${2:-${db_name}_backup_$(date +%Y%m%d_%H%M%S).sql}"
    
    if [[ -z "$db_name" ]]; then
        echo "Usage: db_backup <database_name> [backup_filename]"
        return 1
    fi
    
    mysqldump "$db_name" > "$backup_name"
    echo "Database '$db_name' backed up to '$backup_name'"
}

# Docker shortcuts
dcl() { docker container ls --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" }
dcu() { docker-compose up -d }
dcd() { docker-compose down }
dcr() { docker-compose restart }
dclogs() { docker-compose logs -f "${1:-}" }

# Git workflow shortcuts
gwip() {
    git add -A
    git commit -m "WIP: $(date)"
    echo "Work in progress committed"
}

gpull() {
    local current_branch=$(git branch --show-current)
    echo "Pulling latest changes for branch: $current_branch"
    git pull origin "$current_branch"
}

gpush() {
    local current_branch=$(git branch --show-current)
    echo "Pushing to branch: $current_branch"
    git push origin "$current_branch"
}

# Branch management
gnb() {
    if [[ -z "$1" ]]; then
        echo "Usage: gnb <branch-name>"
        return 1
    fi
    git checkout -b "$1"
    git push -u origin "$1"
}

gdel() {
    if [[ -z "$1" ]]; then
        echo "Usage: gdel <branch-name>"
        return 1
    fi
    git branch -d "$1"
    git push origin --delete "$1"
}

# Code quality shortcuts
lint_check() {
    echo "Running linting checks..."
    
    # ESLint for JavaScript/TypeScript
    if [[ -f ".eslintrc.js" || -f ".eslintrc.json" || -f "eslint.config.js" ]]; then
        echo "Running ESLint..."
        npx eslint .
    fi
    
    # Flake8 for Python
    if [[ -f "setup.py" || -f "requirements.txt" || -f "pyproject.toml" ]]; then
        echo "Running flake8..."
        flake8 .
    fi
    
    # cargo check for Rust
    if [[ -f "Cargo.toml" ]]; then
        echo "Running cargo check..."
        cargo check
        cargo clippy
    fi
    
    echo "Linting complete!"
}

# Test runners
test_run() {
    if [[ -f "package.json" ]]; then
        npm test
    elif [[ -f "pytest.ini" || -f "setup.cfg" ]] || command -v pytest &> /dev/null; then
        pytest
    elif [[ -f "Cargo.toml" ]]; then
        cargo test
    elif [[ -f "go.mod" ]]; then
        go test ./...
    else
        echo "No recognized test framework found"
    fi
}

# Environment management
env_setup() {
    if [[ -f ".env.example" ]]; then
        cp .env.example .env
        echo "Created .env from .env.example"
        echo "Please edit .env with your specific values"
    elif [[ ! -f ".env" ]]; then
        touch .env
        echo "Created empty .env file"
    else
        echo ".env file already exists"
    fi
}

# Port management
port_kill() {
    local port="$1"
    if [[ -z "$port" ]]; then
        echo "Usage: port_kill <port_number>"
        return 1
    fi
    
    local pid=$(lsof -ti:$port)
    if [[ -n "$pid" ]]; then
        kill -9 $pid
        echo "Killed process on port $port"
    else
        echo "No process found on port $port"
    fi
}

port_check() {
    local port="$1"
    if [[ -z "$port" ]]; then
        echo "Usage: port_check <port_number>"
        return 1
    fi
    
    lsof -i:$port
}

# Log tailing shortcuts
logs() {
    case "$1" in
        "nginx")
            tail -f /var/log/nginx/access.log
            ;;
        "apache")
            tail -f /var/log/apache2/access.log
            ;;
        "mysql")
            tail -f /var/log/mysql/error.log
            ;;
        *)
            echo "Usage: logs [nginx|apache|mysql]"
            ;;
    esac
}

# Development aliases
alias npmls='npm list --depth=0'
alias npmg='npm list -g --depth=0'
alias pipr='pip install -r requirements.txt'
alias pipf='pip freeze > requirements.txt'
alias vact='source venv/bin/activate'
alias vdeact='deactivate'
alias gd='git diff --name-only'
alias gdc='git diff --cached'
alias gl='git log --oneline -10'
alias gla='git log --oneline --all --graph -10'
alias dps='docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"'

# Aider - AI pair programming with local Ollama
aider() {
    # Check if Ollama is running
    if ! curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
        echo "⚠️  Ollama is not running. Start it with: ollama serve"
        return 1
    fi

    # Run aider with config file from dotfiles
    command aider --config ~/.dotfiles/config/aider/aider.conf.yml "$@"
}

# Quick aider for current project
aider-project() {
    echo "🚀 Starting Aider for $(basename $(pwd))"
    aider .
}

# Aider with specific model
aider-model() {
    local model="${1:-ollama/codellama:34b}"
    echo "🤖 Starting Aider with model: $model"
    command aider --model "$model" --config ~/.dotfiles/config/aider/aider.conf.yml
}

# List available Ollama models
ollama-list() {
    if ! curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
        echo "⚠️  Ollama is not running"
        return 1
    fi

    echo "Available Ollama models:"
    curl -s http://localhost:11434/api/tags | \
        python3 -c "import sys, json; [print(f'  • {m[\"name\"]}') for m in json.load(sys.stdin).get('models', [])]"
}

# Start Ollama service
ollama-start() {
    if command -v ollama &> /dev/null; then
        echo "🚀 Starting Ollama..."
        ollama serve &

        # Wait for Ollama to be ready
        local max_attempts=30
        local attempt=0

        while [ $attempt -lt $max_attempts ]; do
            if curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
                echo "✅ Ollama is ready on http://localhost:11434"
                ollama-list
                return 0
            fi
            sleep 1
            attempt=$((attempt + 1))
        done

        echo "❌ Ollama failed to start"
        return 1
    else
        echo "❌ Ollama is not installed"
        return 1
    fi
}

# Pull a specific model
ollama-pull() {
    local model="${1:-codellama:34b}"
    echo "📥 Pulling model: $model"
    ollama pull "$model"
}

# Aliases for quick access
alias aid="aider"
alias aid-proj="aider-project"
alias ollama-run="ollama serve"
