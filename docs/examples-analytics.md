# Analytics Subagent: Example Workflow

This walkthrough shows how the analytics subagent handles a user churn analysis from start to finish.

## The ask

> "Determine which user segments have the highest churn risk using the last 90 days of activity data."

## Phase 1: Data Discovery

The subagent connects to data sources and documents what it finds.

**findings.md after Phase 1:**

```markdown
## Data Sources
| Source | Location | Size | Key Fields | Quality Notes |
|--------|----------|------|------------|---------------|
| user_events | PostgreSQL prod replica | 2.3M rows | user_id, event_type, ts | 0.2% null user_id |
| subscriptions | PostgreSQL prod replica | 145K rows | user_id, plan, start_date, churn_date | Complete, no nulls |
| revenue | Finance CSV export | 45K rows | account_id, mrr, churn_date | 3 duplicate account_ids removed |
```

**task_plan.md update:**

```markdown
### Phase 1: Data Discovery
- [x] Identify and connect to data sources
- [x] Document schemas and field descriptions in findings.md
- [x] Assess data quality (nulls, duplicates, outliers, date ranges)
- [x] Estimate dataset size and query performance
- **Status:** complete
```

## Phase 2: Exploratory Analysis

The subagent computes summaries and documents patterns.

**findings.md after Phase 2:**

```markdown
## Query Results

### Activity distribution by user segment
Query: SELECT activity_bucket, COUNT(*), AVG(churned::int) FROM user_segments GROUP BY 1
Result: Low activity (0-2 logins/month): 62% churn. Medium (3-10): 28%. High (11+): 8%.
Interpretation: Strong inverse relationship between login frequency and churn.

### Revenue distribution
Query: SELECT percentile_cont(0.5) WITHIN GROUP (ORDER BY mrr) FROM subscriptions WHERE churn_date IS NOT NULL
Result: Median MRR of churned users: $29. Non-churned: $89.
Interpretation: Churned users skew toward lower-tier plans.
```

**Visual findings captured:**

```markdown
## Visual/Browser Findings
- Histogram of login frequency: bimodal distribution with peaks at 1 login/month and 15 logins/month. Very few users in the 5-8 range.
- Churn rate scatter plot: churn drops sharply after 5 logins/month, then flattens. The inflection point is around 5 logins.
```

## Phase 3: Hypothesis Testing

The subagent formalizes hypotheses and runs tests.

**task_plan.md hypotheses:**

```markdown
## Hypotheses
1. Users with fewer than 3 logins in the last 30 days have a churn rate above 50% (H1)
2. Feature X adoption (used at least once) correlates with retention, r > 0.3 (H2)
3. Users on the $29/month plan churn at higher rates than $89/month users (H3)
```

**findings.md after Phase 3:**

```markdown
## Hypothesis Log
| Hypothesis | Test Method | Result | Confidence |
|------------|-------------|--------|------------|
| H1: Churn > 50% for low-activity users | Chi-squared test | Confirmed (p=0.003, observed 62%) | High |
| H2: Feature X correlates with retention | Pearson correlation | Rejected (r=0.08, p=0.42) | High |
| H3: $29 plan churns more than $89 plan | Two-proportion z-test | Confirmed (p<0.001, 41% vs 12%) | High |

## Statistical Findings
| Test | p-value | Effect Size | Conclusion |
|------|---------|-------------|------------|
| Chi-squared (churn ~ activity level) | p=0.003 | Cramer's V=0.31 | Activity segments differ significantly in churn |
| Pearson (feature_x ~ retention) | p=0.42 | r=0.08 | No meaningful correlation |
| Two-proportion z (churn ~ plan tier) | p<0.001 | Cohen's h=0.67 | Large effect: plan tier strongly associated with churn |
```

## Phase 4: Synthesis

**task_plan.md final state:**

```markdown
### Phase 4: Synthesis & Reporting
- [x] Summarize key findings with supporting evidence
- [x] Create final visualizations
- [x] Document conclusions and recommendations
- [x] Note limitations and areas for further investigation
- **Status:** complete
```

**Summary produced:**

The two strongest churn predictors are login frequency (users below 5 logins/month churn at 3x the rate of active users) and plan tier ($29 plan churns at 41% vs 12% for $89 plan). Feature X adoption showed no significant correlation with retention (r=0.08).

Limitations: analysis covers 90 days only, and the 0.2% null user_ids in user_events were excluded rather than imputed. Seasonal effects were not tested.

## What this looks like without the subagent

Without persistent planning files, the same analysis typically loses state after context resets. Query results disappear. Hypotheses get re-tested or forgotten. Statistical findings are scattered across the conversation instead of organized in one place. The subagent keeps everything on disk so nothing is lost.
