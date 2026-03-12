Transform the following idea into a comprehensive Product Requirements Document (PRD). This is the bridge between ideation and implementation — it must be specific enough that an engineer can build from it without ambiguity.

## Input
$ARGUMENTS

If no arguments provided, use the idea that was discussed in this conversation session.

## Before writing

1. Review the conversation for any prior ideation, constraints, or decisions made
2. If the idea hasn't been stress-tested yet, flag this: "This PRD is based on an unvalidated idea. Consider running /ideate first."

## PRD structure

Generate the following document and save it as `PRD.md` in the project root:

```markdown
# [Product Name] — Product Requirements Document
> Generated: [date] | Status: Draft

## 1. Executive Summary
One paragraph: what is this, who is it for, why does it matter, what's the business model.

## 2. Problem Statement
- The specific pain point (with evidence or reasoning)
- Current alternatives and why they're insufficient
- The cost of the status quo (time, money, frustration)

## 3. Target User
- Primary persona: name, role, context, daily workflow
- What triggers them to seek a solution (the "hair on fire" moment)
- How they currently solve this problem (workarounds, competitors)

## 4. Product Vision
- The "magic moment" — the single interaction that delivers core value
- North star metric: the one number that tells you if this is working
- What this looks like at 10K users vs 1M users

## 5. Core Features (MVP)
For each feature:
- **Feature name**: One-sentence description
- **User story**: As a [user], I want to [action], so that [outcome]
- **Acceptance criteria**: Specific, testable conditions (3-5 per feature)
- **Priority**: P0 (must-have) / P1 (should-have) / P2 (nice-to-have)

## 6. Explicitly Out of Scope (v1)
- Features intentionally deferred and why
- This prevents scope creep during implementation

## 7. Technical Considerations
- Recommended tech stack with rationale
- Key architectural decisions (monolith vs microservices, DB choice, auth strategy)
- Third-party services/APIs needed
- Performance requirements (latency targets, concurrent users)
- Data model sketch (key entities and relationships)

## 8. Success Criteria
- Launch criteria: what must be true before shipping
- Week 1 metrics: what you're measuring immediately
- Month 1 metrics: what signals product-market fit
- Kill criteria: what signals this isn't working (be honest)

## 9. Risks and Mitigations
| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|

## 10. Launch Plan
- Distribution channels for first 1,000 users
- Pricing (if applicable) with reasoning
- Launch sequence: soft launch → feedback → iterate → public launch

## 11. Future Roadmap (post-MVP)
- Phase 2 features (1-3 months post-launch)
- Phase 3 features (3-6 months)
- Long-term vision (1 year)
- Design schemas/interfaces NOW that support these future phases without migration
```

## After writing

- Review the PRD for internal consistency — do the success criteria match the features? Do the features solve the problem statement?
- Flag any sections where you had to make assumptions
- Ask the user to confirm or adjust before implementation begins
