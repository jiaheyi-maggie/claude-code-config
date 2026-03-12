You are now in strict TDD (Test-Driven Development) mode. Every code change follows the Red-Green-Refactor cycle. No exceptions.

## Task
$ARGUMENTS

## The cycle — follow this EXACTLY

### Phase 1: RED — Write a failing test
1. Analyze the requirement and write a test that describes the expected behavior
2. The test must be specific: test behavior, not implementation
3. Run the test — it MUST fail. If it passes, the test is wrong (it's testing something that already exists or is vacuous)
4. Commit the failing test: `test: add failing test for [feature]`

**Rules during RED phase:**
- Do NOT modify production code
- Do NOT write multiple tests at once — one test at a time
- The test name should read like a specification: `test_user_cannot_checkout_with_empty_cart`

### Phase 2: GREEN — Make it pass with minimal code
1. Write the MINIMUM code necessary to make the failing test pass
2. "Minimum" means: no extra features, no optimization, no cleanup. Ugly is fine. Hardcoded values are fine if they pass the test.
3. Run all tests — the new test AND all previous tests must pass
4. Commit: `feat: implement [feature] (green)`

**Rules during GREEN phase:**
- Do NOT refactor
- Do NOT add code that isn't needed to pass the current test
- Do NOT modify tests

### Phase 3: REFACTOR — Clean up while green
1. Now improve the code: extract functions, rename variables, remove duplication, improve structure
2. Run all tests after each change — they must stay green
3. If any test breaks during refactoring, you went too far. Revert and take a smaller step
4. Commit: `refactor: [description]`

**Rules during REFACTOR phase:**
- Do NOT add new behavior (that requires a new RED test)
- Do NOT change what the code does, only how it's structured
- Do NOT modify tests (unless they test implementation details that changed during refactoring)

## Repeat

After refactoring, go back to RED with the next test. Continue until the feature is complete.

## Test quality checklist

For each test, verify:
- [ ] Tests behavior, not implementation (would survive a refactor of internals)
- [ ] Has a descriptive name that reads like a specification
- [ ] Tests one thing (single assertion focus, multiple asserts OK if testing one behavior)
- [ ] Covers the edge case, not just the happy path
- [ ] Is deterministic (no flaky timing, no external dependencies)
- [ ] Runs fast (< 1 second per test)

## What to test

Priority order:
1. **Core business logic** — the rules that make money
2. **Edge cases** — empty input, zero, null, max values, duplicates
3. **Error paths** — invalid input, network failures, permission denied
4. **Integration points** — API contracts, DB queries, external service calls
5. **User flows** — end-to-end critical paths

## Throughout the session

- Show the test output at each phase (RED: failure message, GREEN: passing, REFACTOR: still passing)
- Never write production code without a failing test first
- If you realize you need a helper/utility, write a test for it first
- If you find a bug while implementing, write a test that reproduces it BEFORE fixing it
