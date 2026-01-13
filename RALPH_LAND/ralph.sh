#!/bin/bash

# OpenCode Loop Runner
# Runs opencode in a loop using PROMPT.md until STATUS.md shows completed/blocked
# Usage: ./opencode-loop.sh [max_iterations]

set -e

# Configuration
MAX_ITERATIONS="${1:-100}"  # Default max iterations to prevent infinite loops
ITERATION=0
SESSION_ID=""
PROMPT_FILE="PROMPT.md"
STATUS_FILE="STATUS.md"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if PROMPT.md exists
if [ ! -f "$PROMPT_FILE" ]; then
    echo -e "${RED}Error: $PROMPT_FILE not found${NC}"
    echo "Please create a PROMPT.md file with your goal/instructions"
    exit 1
fi

# Initialize STATUS.md if it doesn't exist
if [ ! -f "$STATUS_FILE" ]; then
    cat > "$STATUS_FILE" << 'EOF'
# OpenCode Loop Status

Status: in_progress

---

## Instructions for OpenCode

When you have completed the goal, update this file by changing the status to:
```
Status: completed
```

You can also set it to:
```
Status: blocked
Reason: [explain what's blocking progress]
```

This will stop the loop.
EOF
    echo -e "${YELLOW}Created $STATUS_FILE${NC}"
fi

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}OpenCode Loop Runner${NC}"
echo -e "${BLUE}================================${NC}"
echo -e "Prompt file: ${GREEN}$PROMPT_FILE${NC}"
echo -e "Status file: ${GREEN}$STATUS_FILE${NC}"
echo -e "Max iterations: ${YELLOW}$MAX_ITERATIONS${NC}"
echo ""

# Function to check if goal is accomplished
check_goal_accomplished() {
    # Check if status file exists and contains "completed" or "blocked"
    if [ ! -f "$STATUS_FILE" ]; then
        echo -e "${RED}Error: $STATUS_FILE not found${NC}"
        return 1
    fi
    
    # Extract status from the file
    local status=$(grep -i "^Status:" "$STATUS_FILE" | head -1 | cut -d: -f2- | tr -d ' ' | tr '[:upper:]' '[:lower:]')
    
    if [ "$status" = "completed" ]; then
        echo -e "${GREEN}✓ Model marked status as: completed${NC}"
        return 0
    elif [ "$status" = "blocked" ]; then
        echo -e "${YELLOW}⚠ Model marked status as: blocked${NC}"
        local reason=$(grep -i "^Reason:" "$STATUS_FILE" | head -1 | cut -d: -f2-)
        if [ -n "$reason" ]; then
            echo -e "${YELLOW}Reason:$reason${NC}"
        fi
        return 0
    fi
    
    return 1  # Still in progress
}

# Function to run opencode iteration
run_iteration() {
    local iteration=$1
    
    echo -e "${BLUE}--- Iteration $iteration/$MAX_ITERATIONS ---${NC}"
    echo ""
    
    # Read the prompt from PROMPT.md
    local prompt=$(cat "$PROMPT_FILE")
    
    echo -e "${BLUE}Running opencode with prompt from $PROMPT_FILE${NC}"
    echo ""
    
    # Run opencode without capturing output, so it prints to terminal in real-time
    opencode run -m opencode/claude-opus-4-5 --variant high "$prompt"
    
    echo ""
    
    # Check if goal is accomplished by reading status file
    if check_goal_accomplished; then
        echo -e "${GREEN}✓ Goal accomplished after $iteration iterations!${NC}"
        return 0
    fi
    
    return 1
}

# Main loop
while [ $ITERATION -lt $MAX_ITERATIONS ]; do
    ITERATION=$((ITERATION + 1))
    
    if run_iteration $ITERATION; then
        echo -e "${GREEN}================================${NC}"
        echo -e "${GREEN}Success! Goal accomplished.${NC}"
        echo -e "${GREEN}================================${NC}"
        
        # Show final status
        echo ""
        echo -e "${BLUE}Final Status:${NC}"
        cat "$STATUS_FILE"
        
        exit 0
    fi
    
    # Check if this was the last iteration
    if [ $ITERATION -ge $MAX_ITERATIONS ]; then
        echo -e "${YELLOW}================================${NC}"
        echo -e "${YELLOW}Warning: Reached maximum iterations ($MAX_ITERATIONS)${NC}"
        echo -e "${YELLOW}Goal may not be fully accomplished.${NC}"
        echo -e "${YELLOW}================================${NC}"
        
        # Show current state
        echo ""
        echo -e "${BLUE}Current Status:${NC}"
        cat "$STATUS_FILE"
        
        exit 1
    fi
    
    # Brief pause between iterations
    echo -e "${BLUE}Waiting 2 seconds before next iteration...${NC}"
    echo ""
    sleep 2
done

echo -e "${RED}================================${NC}"
echo -e "${RED}Failed to accomplish goal within $MAX_ITERATIONS iterations${NC}"
echo -e "${RED}================================${NC}"
exit 1
