#!/usr/bin/env bash

################################################################################
# AI Content Engine - Automated Setup Script
# Platform: Linux/macOS
# Requirements: Node.js 18+, PostgreSQL, Docker (optional)
################################################################################

set -euo pipefail
IFS=$'\n\t'

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="ai-content-engine"
BACKEND_DIR="backend"
FRONTEND_DIR="frontend"

################################################################################
# Helper Functions
################################################################################

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

check_command() {
    if ! command -v "$1" &> /dev/null; then
        print_error "$1 is not installed"
        return 1
    fi
    print_success "$1 is installed"
    return 0
}

################################################################################
# Check Prerequisites
################################################################################

check_prerequisites() {
    print_header "Checking Prerequisites"
    
    local all_ok=true
    
    if ! check_command "node"; then
        print_error "Please install Node.js 18+ from https://nodejs.org"
        all_ok=false
    else
        local node_version=$(node -v)
        print_info "Node.js version: $node_version"
    fi
    
    if ! check_command "npm"; then
        print_error "npm not found"
        all_ok=false
    else
        local npm_version=$(npm -v)
        print_info "npm version: $npm_version"
    fi
    
    if ! check_command "git"; then
        print_error "Please install Git from https://git-scm.com"
        all_ok=false
    fi
    
    if ! check_command "psql"; then
        print_warning "PostgreSQL not found - you'll need to install it manually or use Docker"
        print_info "Install from: https://www.postgresql.org/download"
    fi
    
    if ! command -v docker &> /dev/null; then
        print_warning "Docker not found - you can use Docker later for deployment"
    fi
    
    if [ "$all_ok" = false ]; then
        print_error "Missing required dependencies. Please install them and run this script again."
        exit 1
    fi
    
    echo
}

################################################################################
# Create Directory Structure
################################################################################

create_directories() {
    print_header "Creating Directory Structure"
    
    if [ -d "$BACKEND_DIR" ]; then
        print_warning "Backend directory already exists"
    else
        mkdir -p "$BACKEND_DIR"
        print_success "Created backend directory"
    fi
    
    if [ -d "$FRONTEND_DIR" ]; then
        print_warning "Frontend directory already exists"
    else
        mkdir -p "$FRONTEND_DIR"
        print_success "Created frontend directory"
    fi
    
    mkdir -p "$BACKEND_DIR/src"/{config,controllers,middleware,routes,services,utils,models}
    mkdir -p "$BACKEND_DIR/sql"
    print_success "Created subdirectories"
    
    echo
}

################################################################################
# Setup Backend
################################################################################

setup_backend() {
    print_header "Setting Up Backend"
    
    cd "$BACKEND_DIR"
    
    # Create package.json
    cat > package.json << 'EOF'
{
  "name": "ai-content-engine-backend",
  "version": "1.0.0",
  "description": "Backend API for AI Content Engine with Claude AI integration",
  "main": "src/app.js",
  "type": "module",
  "scripts": {
    "start": "node src/app.js",
    "dev": "nodemon src/app.js",
    "test": "echo \"Error: no test specified\" && exit 1"
  },
  "keywords": ["ai", "content", "social-media", "claude"],
  "author": "",
  "license": "MIT",
  "dependencies": {
    "express": "^4.18.2",
    "cors": "^2.8.5",
    "dotenv": "^16.3.1",
    "anthropic": "^0.14.0",
    "pg": "^8.11.3",
    "jsonwebtoken": "^9.1.2",
    "bcryptjs": "^2.4.3",
    "helmet": "^7.1.0",
    "express-rate-limit": "^7.1.5",
    "express-validator": "^7.0.0",
    "morgan": "^1.10.0",
    "uuid": "^9.0.1"
  },
  "devDependencies": {
    "nodemon": "^3.0.2"
  },
  "engines": {
    "node": ">=18.0.0"
  }
}
EOF
    print_success "Created package.json"
    
    # Create .env.example
    cat > .env.example << 'EOF'
# Server Configuration
PORT=5000
NODE_ENV=development

# Database Configuration
DB_HOST=localhost
DB_PORT=5432
DB_NAME=ai_content_engine
DB_USER=postgres
DB_PASSWORD=your_password

# Claude AI API
ANTHROPIC_API_KEY=your_anthropic_api_key_here

# JWT Configuration
JWT_SECRET=your_jwt_secret_key_change_this_in_production
JWT_EXPIRE=7d

# Frontend URL
FRONTEND_URL=http://localhost:3000

# Rate Limiting
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100
EOF
    print_success "Created .env.example"
    
    # Create .gitignore
    cat > .gitignore << 'EOF'
node_modules/
npm-debug.log*
.env
.env.local
.vscode/
.idea/
*.swp
.DS_Store
logs/
dist/
EOF
    print_success "Created .gitignore"
    
    # Create src/app.js
    cat > src/app.js << 'EOF'
import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import dotenv from 'dotenv';
import { fileURLToPath } from 'url';
import { dirname } from 'path';

dotenv.config();

const app = express();
const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

app.use(helmet());
app.use(cors({
  origin: process.env.FRONTEND_URL || 'http://localhost:3000',
  credentials: true
}));

app.use(express.json({ limit: '10mb' }));
app.use(morgan('combined'));

app.get('/api/health', (req, res) => {
  res.status(200).json({
    status: 'success',
    message: 'Server is running',
    timestamp: new Date().toISOString()
  });
});

app.use((req, res) => {
  res.status(404).json({
    status: 'error',
    message: 'Route not found'
  });
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(`🚀 Server running on http://localhost:${PORT}`);
  console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
});

export default app;
EOF
    print_success "Created src/app.js"
    
    # Create Dockerfile
    cat > Dockerfile << 'EOF'
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm install --production

COPY . .

EXPOSE 5000

CMD ["npm", "start"]
EOF
    print_success "Created Dockerfile"
    
    # Create docker-compose.yml
    cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  postgres:
    image: postgres:15-alpine
    container_name: ai_content_engine_db
    environment:
      POSTGRES_DB: ai_content_engine
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./sql/init.sql:/docker-entrypoint-initdb.d/init.sql

  api:
    build: .
    container_name: ai_content_engine_api
    environment:
      NODE_ENV: development
      PORT: 5000
      DB_HOST: postgres
      DB_PORT: 5432
      DB_NAME: ai_content_engine
      DB_USER: postgres
      DB_PASSWORD: postgres
    ports:
      - "5000:5000"
    depends_on:
      - postgres
    volumes:
      - .:/app
      - /app/node_modules

volumes:
  postgres_data:
EOF
    print_success "Created docker-compose.yml"
    
    # Create sql/init.sql
    cat > sql/init.sql << 'EOF'
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY,
  email VARCHAR(255) UNIQUE NOT NULL,
  password VARCHAR(255) NOT NULL,
  name VARCHAR(255) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS content_history (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  platform VARCHAR(50) NOT NULL,
  content_type VARCHAR(100) NOT NULL,
  tone VARCHAR(100) NOT NULL,
  topic TEXT NOT NULL,
  target_audience TEXT,
  generated_content JSONB NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_content_history_user_id ON content_history(user_id);
CREATE INDEX idx_content_history_created_at ON content_history(created_at DESC);
EOF
    print_success "Created sql/init.sql"
    
    # Install dependencies
    print_info "Installing npm dependencies..."
    npm install
    print_success "Dependencies installed"
    
    # Create .env.local
    if [ ! -f .env.local ]; then
        cp .env.example .env.local
        print_success "Created .env.local"
        print_warning "⚠️  Please edit .env.local and add your ANTHROPIC_API_KEY"
    fi
    
    cd ..
    echo
}

################################################################################
# Setup Frontend
################################################################################

setup_frontend() {
    print_header "Setting Up Frontend"
    
    cd "$FRONTEND_DIR"
    
    # Copy React component
    if [ ! -f "ai-content-engine.jsx" ]; then
        cp ../ai-content-engine.jsx.txt ai-content-engine.jsx
        print_success "Copied React component"
    else
        print_warning "React component already exists"
    fi
    
    cd ..
    echo
}

################################################################################
# Setup Git
################################################################################

setup_git() {
    print_header "Setting Up Git"
    
    if [ ! -d ".git" ]; then
        git init
        print_success "Initialized Git repository"
        
        # Create .gitignore in root
        cat > .gitignore << 'EOF'
node_modules/
.env
.env.local
.DS_Store
*.log
dist/
.next/
out/
EOF
        print_success "Created root .gitignore"
        
        # Create initial commit
        git add .
        git commit -m "Initial commit: AI Content Engine setup"
        print_success "Created initial Git commit"
    else
        print_warning "Git repository already exists"
    fi
    
    echo
}

################################################################################
# Display Setup Summary
################################################################################

show_summary() {
    print_header "Setup Complete! 🎉"
    
    cat << EOF

${GREEN}Next Steps:${NC}

1. ${YELLOW}Configure Environment Variables:${NC}
   cd $BACKEND_DIR
   nano .env.local
   
   Add your:
   - ANTHROPIC_API_KEY (from https://console.anthropic.com)
   - DB credentials
   - JWT_SECRET

2. ${YELLOW}Setup Database (Choose One):${NC}

   ${BLUE}Option A - Using Docker:${NC}
   cd $BACKEND_DIR
   docker-compose up -d
   
   ${BLUE}Option B - Manual PostgreSQL:${NC}
   createdb ai_content_engine
   psql -U postgres -d ai_content_engine -f sql/init.sql

3. ${YELLOW}Start Backend:${NC}
   cd $BACKEND_DIR
   npm run dev

4. ${YELLOW}API will be available at:${NC}
   http://localhost:5000/api/health

5. ${YELLOW}Frontend Integration:${NC}
   Update React component with API URL

${BLUE}Project Structure:${NC}
${PROJECT_NAME}/
├── backend/
│   ├── src/
│   ├── sql/
│   ├── .env.local
│   ├── package.json
│   ├── docker-compose.yml
│   └── Dockerfile
├── frontend/
│   └── ai-content-engine.jsx
└── .git/

${BLUE}Useful Commands:${NC}
- npm run dev          → Start development server
- npm start            → Start production server
- docker-compose up    → Start with Docker
- docker-compose logs  → View logs

${YELLOW}Important:${NC}
- Change JWT_SECRET in .env.local for production
- Update FRONTEND_URL if not localhost:3000
- Keep .env.local out of version control

Need help? Check backend/README.md for documentation.

EOF
}

################################################################################
# Main Execution
################################################################################

main() {
    print_header "🚀 AI Content Engine - Setup Script"
    
    check_prerequisites
    create_directories
    setup_backend
    setup_frontend
    setup_git
    show_summary
}

main "$@"