#!/bin/bash
# Setup shell configuration for MetricFlow template wrappers
# Fixes "zsh: no matches found" errors when using {{ }} syntax

set -e

echo "🔧 MetricFlow Shell Configuration Setup"
echo ""

# Detect shell
SHELL_NAME=$(basename "$SHELL")
echo "Detected shell: $SHELL_NAME"
echo ""

# Configuration line to add
CONFIG_LINE="setopt BRACECCL  # Enable brace character class for MetricFlow"

case "$SHELL_NAME" in
  zsh)
    SHELL_CONFIG="$HOME/.zshrc"

    # Check if already configured
    if grep -q "BRACECCL" "$SHELL_CONFIG" 2>/dev/null; then
      echo "✅ Shell already configured for MetricFlow"
      echo "   Found in: $SHELL_CONFIG"
      exit 0
    fi

    # Backup existing config
    if [ -f "$SHELL_CONFIG" ]; then
      cp "$SHELL_CONFIG" "$SHELL_CONFIG.backup.$(date +%Y%m%d-%H%M%S)"
      echo "📦 Backed up existing config to: $SHELL_CONFIG.backup.*"
    fi

    # Add configuration
    echo "" >> "$SHELL_CONFIG"
    echo "# MetricFlow Configuration (added by setup_shell_config.sh)" >> "$SHELL_CONFIG"
    echo "$CONFIG_LINE" >> "$SHELL_CONFIG"

    echo "✅ Added BRACECCL option to $SHELL_CONFIG"
    echo ""
    echo "To apply changes, run:"
    echo "  source $SHELL_CONFIG"
    echo ""
    echo "Or restart your terminal."
    ;;

  bash)
    SHELL_CONFIG="$HOME/.bashrc"

    echo "⚠️  Bash detected"
    echo ""
    echo "Bash doesn't have the same brace expansion issue as zsh."
    echo "You should still quote MetricFlow commands:"
    echo ""
    echo '  mf query --metrics revenue --where "{{ Dimension(...) }}"'
    echo ""
    echo "No configuration changes needed."
    ;;

  *)
    echo "⚠️  Unknown shell: $SHELL_NAME"
    echo ""
    echo "For MetricFlow to work correctly, ensure template wrappers are quoted:"
    echo ""
    echo '  mf query --metrics revenue --where "{{ Dimension(...) }}"'
    echo ""
    ;;
esac

echo ""
echo "📚 Documentation: .claude/skills/kb-dbt-semantic-layer-developer/references/guide_local_development.md"
