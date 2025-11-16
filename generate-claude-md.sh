#!/bin/bash
# Generate CLAUDE.md from SKILL.md front matter
# This script extracts the name and description from each skill's front matter
# and creates a consolidated CLAUDE.md file for Claude Code to understand available skills

set -e

OUTPUT_FILE="CLAUDE.md"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Start the CLAUDE.md file
cat > "$OUTPUT_FILE" << 'EOF'
# Focus.AI Skills Reference

This repository contains skills for Focus.AI development. When a user asks about topics related to these skills, load the appropriate SKILL.md file to get detailed instructions and patterns.

## Available Skills

EOF

# Find all SKILL.md files and extract front matter
for skill_dir in */; do
    skill_file="${skill_dir}SKILL.md"

    if [[ -f "$skill_file" ]]; then
        # Extract front matter using awk
        front_matter=$(awk '
            BEGIN { in_front_matter = 0; found_start = 0 }
            /^---$/ {
                if (!found_start) {
                    found_start = 1
                    in_front_matter = 1
                    next
                } else {
                    exit
                }
            }
            in_front_matter { print }
        ' "$skill_file")

        # Extract name and description
        name=$(echo "$front_matter" | grep "^name:" | sed 's/^name: *//')
        description=$(echo "$front_matter" | grep "^description:" | sed 's/^description: *//')

        if [[ -n "$name" && -n "$description" ]]; then
            # Add to CLAUDE.md
            cat >> "$OUTPUT_FILE" << EOF
### ${name}
**Path**: \`${skill_file}\`

${description}

---

EOF
        fi
    fi
done

# Add usage instructions
cat >> "$OUTPUT_FILE" << 'EOF'
## How to Use

When a user request matches one of the skill descriptions above:

1. **Load the SKILL.md file** for that skill to get detailed implementation guidance
2. **Follow the patterns** described in the skill documentation
3. **Reference the REFERENCE.md** (if available) for complete specifications

### Trigger Examples

- "Create a Distill service for Twitter" → Load `distill-backend-service/SKILL.md`
- "Integrate my app with Focus authentication" → Load `focus-account-integration/SKILL.md`
- "Apply Focus.AI branding to this presentation" → Load `focus-ai-brand/SKILL.md`
- "Build a content aggregation microservice" → Load `distill-backend-service/SKILL.md`
- "Implement job credit management" → Load `focus-account-integration/SKILL.md`
- "Use Focus.AI color palette" → Load `focus-ai-brand/SKILL.md`
EOF

echo "Generated $OUTPUT_FILE with $(grep -c "^### " "$OUTPUT_FILE") skills"
