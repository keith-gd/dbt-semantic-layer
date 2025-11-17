# dbt Semantic Layer Developer Skill

> **Transform your analytics with centralized metric definitions.** This Claude AI skill provides expert guidance on building production-ready semantic layers using dbt's MetricFlow—enabling consistent metrics across all your data tools.

## Overview

Stop rebuilding the same metrics in Tableau, Looker, and Python notebooks. This skill teaches Claude how to help you:

- ✅ **Define metrics once, use everywhere** - Single source of truth for revenue, churn, LTV, and more
- ✅ **Build semantic models** - Map your data warehouse tables to business entities
- ✅ **Query with MetricFlow** - CLI, Python SDK, or direct BI integrations
- ✅ **Follow best practices** - Production patterns from dbt Labs' official documentation

Built from curated official dbt documentation, this skill gives Claude deep expertise in:

- All 5 metric types (simple, ratio, cumulative, derived, conversion)
- Semantic model architecture (entities, dimensions, measures)
- MetricFlow validation and debugging (3-layer framework)
- Time spine configuration and granularity
- BI tool integrations (Tableau, Power BI, Looker, Hex, Mode)
- Python SDK for notebooks and custom workflows
- Verification checklists and best practices

## What's Included

### 📄 SKILL.md (10.5 KB, 511 lines)
The main skill file with:
- **Role definition** - Semantic Layer architect persona with hallucination guardrails
- **Verification checklist** - 5-step validation for metric creation
- **3-layer debugging framework** - Structured CoT for validation errors (Parse → Semantic → Data Platform)
- **Quick reference patterns** - Semantic models and all metric types
- **Test scenarios** - 4 validation scenarios for skill effectiveness
- MetricFlow time spine setup and Python SDK examples

### 📂 references/ (~280 KB, 8,821 lines - curated content)
Focused documentation for Semantic Layer development:

**Core References**:
- **metrics.md** (44 KB, 1,014 lines) - Metric definitions, Python SDK, query examples (curated)
- **api_reference.md** (114 KB, 2,466 lines) - API documentation, integrations, JDBC/GraphQL
- **cli_commands_complete.md** (19 KB, 830 lines) - MetricFlow CLI complete reference

**Practical Guides** (8 focused guides):
- **guide_bi_tool_integrations.md** - BI tool connection patterns (Tableau, Power BI, etc.)
- **guide_local_development.md** - Local MetricFlow development setup
- **guide_query_syntax.md** - MetricFlow query patterns and syntax
- **guide_validation_workflow.md** - 3-layer validation approach
- **guide_naming_conventions.md** - Metric and dimension naming standards
- **guide_alternative_implementations.md** - Non-dbt semantic layer patterns
- **guide_enterprise_patterns.md** - Enterprise adoption strategies
- **guide_iterative_migration.md** - Step-by-step migration from legacy metrics

### 📦 Supporting Directories

- **assets/** - For templates and boilerplate code
- **scripts/** - Helper scripts for automation

## Sources & Documentation

### Primary Source
**[dbt Labs Documentation](https://docs.getdbt.com)** (Apache 2.0 license)
- Semantic Layer and MetricFlow official guides
- Metric definitions and types
- MetricFlow CLI and Python SDK
- API reference (GraphQL, REST, JDBC)
- BI tool integration guides
- Production best practices

### Additional References
- **[dbt Blog](https://www.getdbt.com/blog)** - Enterprise implementation patterns
- **[Grid Dynamics](https://www.griddynamics.com)** - Production deployment case studies
- **[MotherDuck Blog](https://motherduck.com/blog)** - Alternative semantic layer implementations

### Development History

**v1.0.0** (2025-11-04) - Initial generation
1. Extracted content from dbt docs using Skill Seekers
2. Curated 9.6 MB down to ~280 KB of Semantic Layer-focused content
3. Organized into topic-based reference files

**v1.0.1** (2025-11-17) - Production hardening
1. Added role definition and hallucination guardrails
2. Implemented 5-step metric verification checklist
3. Created 3-layer debugging framework (Parse → Semantic → Data Platform)
4. Added 4 test scenarios for validation
5. Wrapped examples in XML tags for machine parsing
6. Curated metrics.md (62% reduction, 2,710 → 1,014 lines)

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

## File Sizes

### Active Files (Focused on Semantic Layer)
| File | Size | Lines | Description |
|------|------|-------|-------------|
| SKILL.md | 10.5 KB | 511 | Main skill file with verification checklists |
| metrics.md | 44 KB | 1,014 | Metric definitions (curated, 62% reduction) |
| api_reference.md | 114 KB | 2,466 | API documentation |
| cli_commands_complete.md | 19 KB | 830 | MetricFlow CLI reference |
| 8 guide_*.md files | ~90 KB | ~4,000 | Practical implementation guides |

**Total**: ~280 KB / 8,821 lines (100% Semantic Layer focused)

## Quick Start

1. ✅ **Ready to use** - Skill automatically loads in this project directory
2. **Test it** - Ask Claude: "Help me create a ratio metric for average order value"
3. **Explore** - Try debugging scenarios with the 3-layer validation framework
4. **Extend** - Add project-specific examples to `assets/` or helper scripts to `scripts/`

---

## Acknowledgments

**Primary Content Source**
Built from [dbt Labs documentation](https://docs.getdbt.com) (Apache 2.0 license). All core MetricFlow and Semantic Layer concepts are attributed to dbt Labs.

**Extraction Tool**
Initial generation using [Skill Seekers](https://github.com/yusufkaraaslan/Skill_Seekers/) v2.0.0 by Yusuf Karaaslan.

**Version History**
- v1.0.0 (2025-11-04) - Initial generation
- v1.0.1 (2025-11-17) - Production hardening with verification frameworks
