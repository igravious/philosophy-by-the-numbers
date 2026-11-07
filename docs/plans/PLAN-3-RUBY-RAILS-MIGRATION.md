# Plan 3: Ruby and Rails Migration

**Goal:** Upgrade Ruby 2.6.10 and Rails 4.2.11.3 to Ruby 3.4.x and Rails 8.1.x
through one coordinated sequence of independently tested upgrades.

**Back to:** [Master Plan](../../MASTER_PLAN.md)

**Prerequisites:** Complete the migration safety net in
[Plan 1 (Test Coverage)](PLAN-1-TEST-COVERAGE.md), and use the workflow inventory
and tests from [Plan 2 (Task Classification)](PLAN-2-TASK-CLASSIFICATION.md) to
verify command-line behaviour throughout the migration.

## Current Baseline

| Component | Starting version |
|-----------|------------------|
| Ruby | 2.6.10, managed with rbenv |
| Rails | 4.2.11.3 |
| Bundler | 1.17.3, locally patched |
| composite_primary_keys | 8.1.8 |
| sqlite3 | 1.3.13 |
| Assets | Sprockets, Bower, jQuery and Cocoon |

Existing compatibility workarounds:
- `config/initializers/ruby_2_6_monitor_fix.rb`
- `test/support/thread_error_workarounds.rb`

## Upgrade Strategy

Keep Ruby and Rails changes in the same plan, but change one component at a time
where possible. Do not finish all Ruby upgrades while leaving Rails at 4.2.
Select the latest suitable patch release within each intermediate series and
resolve the complete gem bundle before committing to that checkpoint.

Rails recommends advancing one minor release at a time and reviewing framework
defaults incrementally. Its minimum Ruby version is a lower bound, not proof
that every newer Ruby works with an older Rails release or this application's
dependencies. Follow the [Rails upgrade guide](https://guides.rubyonrails.org/upgrading_ruby_on_rails.html)
at each step.

The following is the proposed route to validate against the bundle and test suite:

| Stage | Ruby | Rails checkpoints | Main purpose |
|-------|------|-------------------|--------------|
| Baseline | 2.6.10 | 4.2.11.3 | Record passing tests and existing behaviour |
| 1 | 2.6.10 | 5.0 -> 5.1 -> 5.2 | Upgrade Rails while holding the current Ruby steady |
| 2 | 2.6.10 | 6.0 -> 6.1 | Prepare framework and dependencies for Ruby 3 |
| 3 | 2.7 -> 3.0 | Hold at 6.1 | Resolve keyword-argument changes in two Ruby checkpoints |
| 4 | Hold at 3.0 | 7.0 | Complete Zeitwerk migration |
| 5 | 3.1 | Hold at 7.0, then 7.1 -> 7.2 | Handle YAML changes and native composite keys |
| 6 | 3.2 -> 3.3 -> 3.4 | Hold at 7.2 | Upgrade Ruby and native dependencies incrementally |
| 7 | Hold at 3.4 | 8.0 -> 8.1 | Reach the target framework |

Each arrow represents a separate checkpoint. If a dependency blocks one, adjust
the pairing explicitly and record the reason; do not make untested version jumps.
Ruby 4.0 remains an optional follow-on assessment after this plan's target works,
not a prerequisite for completing the migration.

## Preparation

- [ ] Reconcile Plan 1 progress and Plan 2 implementation with their checklists.
- [ ] Record the current test and coverage baseline using `bin/rake test` and
      `COVERAGE=1 bin/rake test`.
- [ ] Audit dependencies with `bin/bundle exec ruby scripts/check_gems.rb`.
- [ ] Enable Ruby and Rails deprecation reporting and fix warnings supported by
      the current stack before upgrading.
- [ ] Record `.ruby-version`, `Gemfile.lock`, and native library requirements.
- [ ] Back up the database and use a disposable copy for migration checks.
- [ ] Identify representative web pages, corpus queries, canonicity calculations,
      and CLI workflows to exercise after each checkpoint.

## Checks at Every Checkpoint

- [ ] Update `.ruby-version` for Ruby changes and the relevant Gemfile constraints
      for Rails or gem changes; keep the resulting lockfile.
- [ ] Select a Bundler release compatible with that Ruby. Remove reliance on the
      local Bundler 1.17 patches when moving to Bundler 2.
- [ ] Install the bundle using the project's `bin/bundle` executable.
- [ ] For Rails upgrades, run `bin/rails app:update` and review generated changes;
      adopt new framework defaults individually.
- [ ] Run `bin/rake test`; resolve failures and relevant deprecation warnings.
- [ ] Exercise the representative pages and workflows, with external services
      mocked in automated tests.
- [ ] Verify assets still load and native-extension gems still work.
- [ ] Commit the passing checkpoint before the next version change.

## Stage 1: Rails 4.2 -> 5.0 -> 5.1 -> 5.2

Keep Ruby 2.6.10 initially. Use the matching composite-primary-key gem at each
Rails checkpoint: 9.x for 5.0, 10.x for 5.1, and 11.x for 5.2.

- [ ] Replace `before_filter` with `before_action` where used.
- [ ] Replace old static-file configuration with `config.public_file_server.enabled`.
- [ ] Add `ApplicationRecord`; update models directly inheriting from
      `ActiveRecord::Base`, preserving STI subclass inheritance.
- [ ] Set `config.active_record.belongs_to_required_by_default = false` initially
      to preserve existing association behaviour.
- [ ] Review callback halting and controller-test changes at the Rails 5 boundary.
- [ ] Audit dynamic finder usage; change unsupported calls without assuming all
      `find_by_*` methods have been removed.
- [ ] Resolve sqlite3 adapter requirements for each Rails patch release rather
      than applying a single gem version to every stage.
- [ ] At Rails 5.2, migrate secret configuration to credentials while preserving
      the existing `secret_key_base` and excluding the encryption key from git.
- [ ] Keep optional framework features out of the migration unless required.

## Stage 2: Rails 5.2 -> 6.0 -> 6.1

Keep Ruby steady while upgrading Rails. Use CPK 12.x for Rails 6.0 and 13.x for 6.1.

- [ ] Replace `update_attributes` with `update` throughout application code.
- [ ] Update `web-console` and other framework-coupled gems as required.
- [ ] Begin Zeitwerk migration; classic autoloading may be retained temporarily
      while resolving naming and loading issues.
- [ ] Pay particular attention to `Philosopher` and `Work`, which are defined in
      `shadow.rb`, and the `P::Smart` STI hierarchy.
- [ ] Review connection-handling defaults and changes to model errors.
- [ ] Keep Sprockets and the existing frontend working; do not introduce Webpacker
      as a temporary dependency.

## Stage 3: Ruby 2.6 -> 2.7 -> 3.0 on Rails 6.1

- [ ] Install Ruby 2.7 with rbenv and choose a compatible Bundler 2 release.
- [ ] Enable and resolve keyword-argument warnings, including delegation and
      calls into gems; verify on 2.7 before moving to 3.0.
- [ ] Install Ruby 3.0 and resolve remaining keyword-argument failures.
- [ ] Rebuild and exercise sqlite3, RMagick, ffi-hunspell and rdf-raptor.
- [ ] Review Watir and selenium-webdriver together if browser compatibility
      requires an update.
- [ ] Remove the Ruby 2.6 Monitor patch and controller-test workarounds only after
      real controller tests pass without them; remove their loading hooks too.
- [ ] Verify tests still exercise real responses after workaround removal.

## Stage 4: Rails 6.1 -> 7.0 on Ruby 3.0

- [ ] Upgrade to CPK 14.x alongside Rails 7.0.
- [ ] Complete Zeitwerk migration; verify eager loading and STI discovery.
- [ ] Keep `sprockets-rails` explicitly available for the existing assets.
- [ ] Review errors, callbacks, helper behaviour and framework defaults against
      the upgrade guide and regression tests.
- [ ] Preserve the current frontend; Turbo, Stimulus and asset replacement are
      not required to complete this stage.

## Stage 5: Ruby 3.1, then Rails 7.1 -> 7.2

Upgrade Ruby first with Rails held at 7.0, then take each Rails checkpoint.

- [ ] Audit YAML loading under Psych 4, including workflow definitions, fixtures
      and saved configuration; choose permitted types and aliases deliberately.
- [ ] Review any `require 'debug'` conflicts and dependencies extracted from Ruby's
      standard library.
- [ ] At Rails 7.1, migrate composite-key behaviour to native Rails support before
      proceeding beyond the CPK gem's supported ActiveRecord series.
- [ ] Audit `Expression`, `P::Smart` subclasses and `ViafCacheItem`: key definitions,
      associations, `find` calls and fixtures must retain their behaviour.
- [ ] Remove `composite_primary_keys` once equivalent behaviour is verified.
- [ ] Advance through Rails 7.1 and 7.2 with separate tests and defaults review.

The subsequent [schema plan](PLAN-4-SCHEMA-OVERHAUL.md) verifies the native-key
transition and handles broader data-model cleanup; it must not be a prerequisite
for booting the upgraded framework.

## Stage 6: Ruby 3.2 -> 3.3 -> 3.4 on Rails 7.2

- [ ] Take each Ruby minor release separately, updating rbenv configuration,
      Bundler and the lockfile as necessary.
- [ ] Check the release notes for each selected version rather than assuming
      parser, standard-library or string behaviour from another release.
- [ ] Exercise encoding, regular expressions, JSON/YAML serialisation and native
      extensions at each checkpoint.
- [ ] Resolve parser or string-mutation warnings encountered on the target Ruby.
- [ ] Declare extracted library gems explicitly where the application needs them.

## Stage 7: Rails 7.2 -> 8.0 -> 8.1 on Ruby 3.4

- [ ] Resolve the sqlite3 2.x dependency and verify database operations against a
      copy of the existing database.
- [ ] Review generated configuration and new defaults at both Rails checkpoints.
- [ ] Preserve the working asset pipeline; the full Propshaft/Import Maps and
      Bootstrap/Alpine migration belongs to [Plan 6](PLAN-6-UI-OVERHAUL.md).
- [ ] Do not add authentication, deployment or queue/cache infrastructure solely
      because generators offer it.
- [ ] Verify web pages, CLI workflows, canonicity and corpus operations together.

## Dependency Coordination

### Composite Primary Keys

Use the gem's [published ActiveRecord compatibility mapping](https://github.com/composite-primary-keys/composite_primary_keys#versions):

| Rails / ActiveRecord | CPK gem |
|----------------------|---------|
| 4.2 | 8.x |
| 5.0 | 9.x |
| 5.1 | 10.x |
| 5.2 | 11.x |
| 6.0 | 12.x |
| 6.1 | 13.x |
| 7.0 | 14.x |

For Rails 7.1 onward, use the native-key transition in Stage 5, following the
[Rails composite primary key guide](https://guides.rubyonrails.org/active_record_composite_primary_keys.html).

### Other Dependencies

| Dependency | What to verify |
|------------|----------------|
| Bundler | Ruby compatibility, binstubs and removal of local patches |
| sqlite3 | Rails adapter constraints, native compilation and boolean queries |
| RMagick | ImageMagick compatibility and actual image operations |
| ffi-hunspell, rdf-raptor | Native libraries, loading and representative calls |
| Watir, selenium-webdriver, headless | Browser compatibility as a group |
| api_cache, rzotero | Actual usage and compatibility before replacing or removing |
| web-console, kaminari, jbuilder | Framework compatibility and rendered responses |
| Sass, jquery-rails, Cocoon | Existing asset compilation and forms |

Keep the asset migration separate from runtime compatibility work. Retain Bower
assets while existing templates need them; their replacements and `resolve:paths`
removal belong to Plan 6. Preserve the user's no-Hotwire/no-Bootsnap preferences.

## Success Criteria

- Ruby 3.4.x and Rails 8.1.x run with a reproducible bundle.
- The test suite passes, including the Plan 1 regression coverage and Plan 2 CLI
  workflow tests.
- Zeitwerk loads the application and STI models correctly.
- Native composite keys preserve existing lookup and association behaviour.
- Ruby 2.6-specific workarounds and Bundler patches are no longer required.
- Credentials, database data, current canonicity values and corpus files survive
  the upgrade without unintended changes.
- Existing pages, forms and visualisations work; frontend redesign remains Plan 6.
- Remaining dependency warnings or limitations are explicitly documented.

## Estimated Effort

The original Ruby and Rails estimates combined were **20-30 sessions**. Retain that
as a provisional planning range, to be revised after the dependency audit and first
working upgrade. Checkpoints are validated by passing behaviour, not session count.
