# dbt Semantic Layer Developer Skill

## Overview

This skill provides comprehensive assistance with dbt Semantic Layer development, extracted from official dbt documentation using [Skill Seekers](https://github.com/yusufkaraaslan/Skill_Seekers/).

## What's Included

### 📄 SKILL.md (8.7 KB)
The main skill file with:
- Quick reference patterns for semantic models and metrics
- All metric types (simple, ratio, cumulative, derived, conversion)
- MetricFlow time spine setup
- Python SDK examples
- Common troubleshooting scenarios

### 📂 references/ (9.6 MB total)
Comprehensive documentation organized by category:

- **metrics.md** (109 KB) - Metric definitions, Python SDK, query examples
- **api_reference.md** (114 KB) - API documentation, integrations, JDBC/GraphQL
- **examples.md** (155 KB) - Real-world examples and patterns
- **other.md** (1.4 MB) - Additional dbt documentation
- **llms.md** (192 KB) - Quick reference llms.txt
- **llms-full.md** (7.9 MB) - Complete dbt documentation in llms.txt format

### 📦 Supporting Directories

- **assets/** - For templates and boilerplate code
- **scripts/** - Helper scripts for automation

## How It Was Generated

1. **Source**: Official dbt documentation at docs.getdbt.com
2. **Tool**: Skill Seekers web scraper
3. **Method**: Extracted llms.txt content (204 pages)
4. **Coverage**: Semantic Layer, MetricFlow, all metric types, integrations

## Key Topics Covered

### Core Concepts
- Semantic models (entities, dimensions, measures)
- MetricFlow architecture
- Time spine configuration
- Join logic and grain

### Metric Types
- Simple metrics (direct aggregations)
- Ratio metrics (division)
- Cumulative metrics (running totals)
- Derived metrics (expressions)
- Conversion metrics (funnels)

### Integrations
- BI tools (Tableau, Power BI, Looker, Hex, Mode)
- APIs (GraphQL, REST, JDBC)
- Python SDK (sync and async)
- Notebooks (Jupyter, Hex, Deepnote)

### Best Practices
- Semantic model normalization
- Primary entity design
- Consistent grain
- Saved queries
- Lazy loading optimization

## Usage in Claude

This skill will be automatically available in Claude when working in this project directory. Claude will reference it when you:

- Ask about semantic models or MetricFlow
- Need help defining metrics
- Want integration examples
- Debug semantic layer issues
- Learn best practices

## Updating the Skill

To refresh with latest dbt documentation:

```bash
cd ~/git-repos/Skill_Seekers
source venv/bin/activate
python3 cli/doc_scraper.py --config configs/skill_seeker_config_dbt_semantic.json

# Copy updated files
cp -r output/dbt-semantic-layer/* \
  ~/git-repos/dbt_projects/dbt-enterprise/.claude/skills/dbt-semantic-layer-developer/
```

## Configuration

The skill was generated using this config:
`~/git-repos/dbt_projects/dbt-enterprise/skill_seeker_config_dbt_semantic.json`

Key settings:
- Base URL: https://docs.getdbt.com
- Focus: Semantic Layer, MetricFlow, metrics
- Max pages: 100
- Rate limit: 1 second between requests

## File Sizes

| File | Size | Description |
|------|------|-------------|
| SKILL.md | 8.7 KB | Main skill file |
| llms-full.md | 7.9 MB | Complete documentation |
| other.md | 1.4 MB | Additional docs |
| examples.md | 155 KB | Practical examples |
| llms.md | 192 KB | Quick reference |
| api_reference.md | 114 KB | API docs |
| metrics.md | 109 KB | Metric definitions |

**Total**: ~9.6 MB of comprehensive documentation

## Next Steps

1. ✅ Skill is ready to use with Claude
2. Test it by asking Claude about semantic layer topics
3. Update periodically as dbt documentation evolves
4. Add custom examples to assets/ directory
5. Add helper scripts to scripts/ directory

---

**Generated**: 2025-11-04
**Tool**: Skill Seekers v2.0.0
**Source**: dbt Labs official documentation
