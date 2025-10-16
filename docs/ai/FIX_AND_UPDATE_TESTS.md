# Plan to Fix Test Suite Issues

Below is a detailed, step-by-step plan for fixing the test suite issues we discovered. I'll tackle them one-by-one, prioritizing based on impact (e.g., route errors affect 100+ tests, so start there). For each issue, I'll explain:

- **What the problem is**: A clear description of the error and its symptoms.
- **Why it's happening**: The likely root cause based on Rails/testing knowledge.
- **How to fix it**: Specific steps, including code changes or commands.
- **Expected outcome**: What success looks like, and how it unblocks other tests.
- **Risks/Notes**: Any potential side effects or things to watch for.

This plan assumes we're working incrementally—run tests after each fix to validate progress. Since the project uses Rails 4.2 (EOL) and Ruby 2.6 (EOL), some fixes might reveal deeper compatibility issues, but we'll address them as they come.

## Step 1: Fix Route Loading Issues (High Priority - Affects 100+ Controller Tests)

**What the problem is**: Controller tests fail with `NoMethodError: undefined method 'texts' for #<ControllerTest>` (and similar for `fyles`, `works`, etc.). This means route helpers like `texts_path` aren't available in tests.

**Why it's happening**: In Rails, route helpers are generated from `config/routes.rb`. If routes aren't loading in the test environment, helpers won't be defined. This could be due to:
- Test environment not inheriting routes properly.
- A syntax error or missing file in routes.
- Rails 4.2 quirks with test setup (e.g., `ActionController::TestCase` not initializing routes).

**How to fix it**:
1. Check `config/routes.rb` for syntax errors: Run `bin/rails routes` in the terminal to see if routes load. If it fails, fix any syntax issues.
2. Ensure test environment loads routes: In `config/environments/test.rb`, add or verify `config.action_controller.include_all_helpers = true` (forces helper loading).
3. If routes are defined but not loading, check `test/test_helper.rb` for missing `require 'rails/test_help'` or route setup.
4. Run a single failing test: `bin/rake test TEST=test/controllers/texts_controller_test.rb` to isolate.

**Expected outcome**: Route helpers become available, fixing ~100 controller test errors. Tests should now complain about actual logic instead of missing methods.

**Risks/Notes**: If routes are complex (e.g., nested resources), this might reveal deeper routing issues. Rails 4.2 has known quirks with route reloading in tests.

## Step 2: Fix Fixture Loading Errors (Medium Priority - Affects Model Tests)

**What the problem is**: Tests fail with `TypeError: no implicit conversion of nil into String` during fixture setup (e.g., in `PhilosopherCanonicityTest`).

**Why it's happening**: Rails fixtures (YAML files in `test/fixtures/`) are loaded into the database. If a fixture has `nil` values where strings are expected (e.g., a name field set to `null` in YAML), ActiveRecord tries to convert `nil` to a string, causing the error. This is common in Rails 4.2 with strict type handling.

**How to fix it**:
1. Identify problematic fixtures: Look at `test/fixtures/philosophers.yml` (or similar) for `nil` values in string columns.
2. Replace `nil` with empty strings or valid defaults: E.g., change `name: null` to `name: ""`.
3. Check all fixture files: Run `grep -r "null\|nil" test/fixtures/` to find them.
4. Re-run affected tests: `bin/rake test TEST=test/models/philosopher_canonicity_test.rb`.

**Expected outcome**: Fixtures load without type errors, allowing model tests to run. This fixes ~20-30 errors related to data setup.

**Risks/Notes**: If fixtures have real `nil` data (e.g., optional fields), consider using `allow_nil: true` in model validations. Over-fixing might mask data integrity issues.

## Step 3: Load the SecurityConfig Module (Low-Medium Priority - Affects 1 Test)

**What the problem is**: `CredentialSecurityTest` fails with "SecurityConfig module should be defined".

**Why it's happening**: The `SecurityConfig` module (in `app/lib/security_config.rb`) isn't being loaded in the test environment. Rails autoloading might not be working, or the file isn't required.

**How to fix it**:
1. Check if the file exists: `ls app/lib/security_config.rb`.
2. Ensure it's autoloaded: In `config/application.rb`, verify `config.autoload_paths += %W(#{config.root}/lib)`.
3. Manually require it in tests: In `test/test_helper.rb`, add `require 'security_config'`.
4. Re-run the test: `bin/rake test TEST=test/controllers/security_vulnerabilities_test.rb`.

**Expected outcome**: The module loads, and the security test passes. This unblocks security-related assertions.

**Risks/Notes**: If the module has dependencies (e.g., on Rails components), loading issues might persist. Rails 4.2 autoloading can be finicky.

## Step 4: Address Model Association and Method Errors (Medium Priority - Scattered Issues)

**What the problem is**: Tests fail with `NoMethodError: undefined method '>=' for nil:NilClass` (e.g., in `CanonicityCalculationTest`), suggesting missing data or broken relationships.

**Why it's happening**: Model methods expect non-nil values (e.g., canonicity scores), but fixtures or test data provide `nil`. This could be due to incomplete fixtures or model logic assuming presence.

**How to fix it**:
1. Review the failing test: Look at `test/models/canonicity_calculation_test.rb` line 92—check what method is called and why it returns `nil`.
2. Fix model logic: In `app/models/philosopher.rb`, add nil checks (e.g., `score ||= 0` before comparisons).
3. Update fixtures: Ensure related data (e.g., `danker` scores) aren't `nil`.
4. Re-run: `bin/rake test TEST=test/models/canonicity_calculation_test.rb`.

**Expected outcome**: Model methods handle `nil` gracefully, fixing ~5-10 errors. Reveals if the canonicity algorithm itself is broken.

**Risks/Notes**: This might expose algorithmic bugs (e.g., division by zero). The canonicity logic is complex—refer to `docs/CANONICITY_ALGORITHM.md`.

## Step 5: Fix Rake Task Integration Errors (Low Priority - Affects Specific Tests)

**What the problem is**: Tests fail with `ArgumentError: wrong number of arguments` (e.g., in `FiltersControllerTest` calling `filters`).

**Why it's happening**: Rake tasks (in `lib/tasks/`) define methods that tests mock, but argument counts don't match. E.g., a task method expects 1 arg, but tests call it with 0.

**How to fix it**:
1. Check the rake task: Look at `lib/tasks/shadow.rake` line 1506 for the `filters` method—see its signature.
2. Update tests: In `test/controllers/filters_controller_test.rb`, adjust the mock call to match arguments.
3. Re-run: `bin/rake test TEST=test/controllers/filters_controller_test.rb`.

**Expected outcome**: Task mocks work, fixing ~10 errors. Ensures rake tasks integrate with controllers properly.

**Risks/Notes**: If tasks change, tests break—consider isolating task logic from controllers.

## Step 6: Validate and Re-Run Full Suite (Final Step)

**What to do**: After fixes, run `bin/rake test` again. Track progress (e.g., errors down from 149 to X).

**Why**: Ensures fixes don't introduce regressions. Rails 4.2 tests can be flaky due to threading issues (noted in `.ai-instructions.md`).

**Expected outcome**: Hopefully <50 errors. If major issues remain, investigate Rails upgrade or environment setup.

**Risks/Notes**: Full runs might take time. If stuck, focus on critical paths (e.g., core models).

This plan should reduce errors significantly. I'll start with Step 1—let me know if you want me to proceed or adjust the plan!