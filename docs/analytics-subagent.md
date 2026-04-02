# Analytics Subagent

A Claude Code subagent specialized for data analytics workflows. Follows the planning-with-files methodology with analytics-specific templates for tracking data sources, hypotheses, query results, and statistical findings.

## What it does

The analytics subagent adapts the 3-file planning pattern for data work:

- **task_plan.md** tracks 4 analytics phases instead of the default 5 software phases
- **findings.md** includes Data Sources, Hypothesis Log, Query Results, Statistical Findings, and Technical Decisions sections
- **progress.md** uses a Query Log instead of Test Results

The subagent enforces statistical rigor: hypothesis discipline, assumption validation, effect size reporting, and transformation documentation.

## Installation

Copy the agent definition from the skill directory into your project:

```bash
mkdir -p .claude/agents
cp ~/.claude/skills/planning-with-files/agents/analytics.md .claude/agents/
```

If you cloned the repo directly:

```bash
mkdir -p .claude/agents
cp skills/planning-with-files/agents/analytics.md .claude/agents/
```

The subagent requires the planning-with-files skill to be installed (it inherits the skill via the `skills` field in its frontmatter).

## Usage

Once the file is in `.claude/agents/analytics.md`, Claude Code discovers it automatically. You can invoke it by asking for analytics work:

```
Analyze user churn from our PostgreSQL database
```

Or invoke it directly:

```
/agent analytics
```

The subagent will:
1. Initialize analytics planning files (using `--template analytics`)
2. Ask for your analytical objective if not provided
3. Work through the 4 phases: Data Discovery, Exploratory Analysis, Hypothesis Testing, Synthesis
4. Persist all findings to disk so nothing is lost on context reset

## The 4 phases

**Phase 1: Data Discovery** - Connect to sources, document schemas, assess data quality. No analysis until data is understood.

**Phase 2: Exploratory Analysis** - Summary statistics, distributions, correlations, outlier detection. Document patterns in findings.md.

**Phase 3: Hypothesis Testing** - Formalize hypotheses, select tests, run them, record results with p-values and effect sizes.

**Phase 4: Synthesis & Reporting** - Summarize findings with evidence, create final visualizations, document conclusions and limitations.

## How it integrates with planning-with-files

The subagent loads the planning-with-files skill via `skills: planning-with-files` in its frontmatter. This means:

- All PreToolUse/PostToolUse/Stop hooks from SKILL.md apply
- The `task_plan.md` is re-read before tool calls (attention manipulation)
- Completion verification runs before stopping
- Session recovery works across context resets

The difference is in the system prompt: the subagent knows about statistical methods, hypothesis tracking, data quality assessment, and analytics-specific anti-patterns.

## Templates used

The subagent uses the analytics templates added in v2.29.0:

- `templates/analytics_task_plan.md` - 4-phase analytics workflow
- `templates/analytics_findings.md` - Data Sources, Hypothesis Log, Query Results, Statistical Findings
- `templates/progress.md` - Session logging with Query Log

## Recovering context

Same as the main skill. If context fills up, start a new session and say:

```
Read task_plan.md, findings.md, and progress.md to restore context. Continue from Phase [X].
```

The files are your memory. The subagent picks up where it left off.
