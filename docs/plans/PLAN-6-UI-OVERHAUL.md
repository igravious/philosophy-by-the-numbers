# Plan 6: UI Overhaul

**Goal:** Modernise the frontend from server-rendered ERB + jQuery + Bower to a
contemporary stack on Rails 8, dramatically improving the user experience.

**Back to:** [Master Plan](../../MASTER_PLAN.md)

**Prerequisite:** [Plan 5 (Query DSL)](PLAN-5-QUERY-DSL.md) complete.
The schema and query layer must be solid before building the presentation layer.
Rails 8.1 provides the modern foundation (Propshaft, Import Maps) that this plan
builds on.

## User's Rails 8 Preferences (~/.railsrc)

```
--skip-action-mailbox
--skip-active-storage
--skip-hotwire          # No Turbo, no Stimulus
--skip-bootsnap
--javascript=importmap  # Import Maps for JS (no build step)
--template=~/Code/rails/template.rb
```

These preferences drive the technology decisions below. Notably, **Hotwire is
deliberately excluded** — the approach is Alpine.js + Bootstrap 5 with Import Maps,
matching the proven stack used in `sceallog-bytes` (LaVie Skibbereen).

## Current State

### Frontend Stack
- **CSS Framework:** Picnic v5.0.1 (minimal, lightweight)
- **Icons:** Font Awesome 4.7.0
- **JS Libraries:** jQuery 2.2.0, Cocoon (nested forms)
- **Visualisation:** D3.js v3.5.13, Springy v2.7.1, Dracula v0.7.1, Venn.js v0.2.7
- **Date Picker:** Pickadate v3.5.6
- **Asset Pipeline:** Sprockets + Bower
- **Total Custom CSS:** 357 lines across 24 files
- **Total Custom JS:** 106 lines across 23 files

### View Templates
- **183 ERB templates** across 27+ directories
- Heavy use of tables for data display
- AJAX via jQuery for filtering
- Inline `<script>` blocks in visualisation pages
- Nested forms via Cocoon gem

### UI Pain Points (to address)
1. Table-heavy layout with minimal responsive design
2. No mobile support
3. Dated visual appearance
4. jQuery-dependent AJAX patterns
5. Inline scripts in templates
6. No consistent component system
7. Visualisation libraries are outdated (D3 v3 is from 2015)
8. No loading states or real-time feedback

## Technology Decisions

### Decision 1: CSS Framework

**Chosen:** Bootstrap 5.3 — already proven in sceallog-bytes, rich component library
(navbars, cards, tables, modals, badges, alerts), excellent responsive grid, and
works with Import Maps via `bin/importmap pin bootstrap`. Picnic is too limited
for the data-heavy views in this app.

### Decision 2: JavaScript Approach

**Chosen:** Alpine.js 3.x (per sceallog-bytes pattern). Alpine provides declarative
reactivity (`x-data`, `x-show`, `x-on`, `x-for`) directly in HTML templates,
replacing jQuery's imperative DOM manipulation with a fraction of the code. Combined
with `fetch()` for server communication, this replaces both jQuery and Cocoon.

No Hotwire (per `~/.railsrc` — `--skip-hotwire`). No build step (Import Maps only).

### Decision 3: Visualisation Library

**Recommended:** D3.js v7 for graphs/networks + Observable Plot for simpler charts.
Sigma.js for the philosopher relationship graphs (Springy/Dracula replacement).
All pinned via Import Maps.

### Decision 4: Asset Pipeline

**Chosen:** Propshaft + Import Maps (no npm, no node, no build step). This is the
sceallog-bytes stack and the Rails 8 default.

Import Maps will pin: `bootstrap`, `@popperjs/core`, `alpinejs`, `d3`, `sigma`.
Use `bin/fix-popper.sh` from the Rails template for the Popper.js naming fix.

### Reference Implementation

The sceallog-bytes project (`~/Code/hertzner-cx33/projects/sceallog-bytes/`) serves
as the reference for how this stack is wired up:
- `config/importmap.rb` — pin declarations
- `app/views/layouts/application.html.erb` — layout structure
- `app/javascript/application.js` — Alpine.js initialisation
- `bin/fix-popper.sh` — Popper.js workaround

## Phases

### Phase 1: Asset Pipeline Migration
Strip out Bower/Sprockets and move to the modern Rails 8 asset stack.

- [ ] Remove Bower: delete `bower.json`, `.bowerrc`, `vendor/assets/bower_components/`
- [ ] Install Propshaft: `bundle add propshaft`, remove `sprockets-rails`
- [ ] Set up Import Maps: `bin/rails importmap:install`
- [ ] Pin core dependencies:
  - `bin/importmap pin bootstrap` (Bootstrap 5.3)
  - `bin/importmap pin @popperjs/core` (then run `bin/fix-popper.sh`)
  - `bin/importmap pin alpinejs` (Alpine.js 3.x)
  - `bin/importmap pin d3` (or vendor locally for visualisations)
- [ ] Remove `resolve:paths` rake task (no longer needed)
- [ ] Update `application.html.erb` layout for new asset helpers
- [ ] Create `app/javascript/application.js` with Alpine.js init (copy pattern from sceallog-bytes)
- [ ] Verify all pages load without JS/CSS errors
- [ ] Commit: "Migrate to Propshaft + Import Maps + Bootstrap 5 + Alpine.js"

### Phase 2: Layout & Navigation Redesign
Replace the basic layout with a modern, responsive shell.

- [ ] Design new application layout with Bootstrap 5 components:
  - `navbar` with responsive collapse (hamburger on mobile)
  - Breadcrumb trail (`breadcrumb` component)
  - Search bar in navbar
  - Sidebar navigation (optional, using `offcanvas` on mobile)
- [ ] Use Bootstrap 5 component classes throughout:
  - Buttons (`btn btn-primary`, `btn-outline-danger`, etc.)
  - Cards (`card`, `card-body`, `card-header`)
  - Form controls (`form-control`, `form-select`, `form-check`)
  - Tables (`table`, `table-striped`, `table-hover`, sortable headers)
  - Badges (`badge bg-primary`, etc.)
  - Alerts (`alert alert-success`, etc.)
  - Modals (`modal` — replace browser `confirm()`)
- [ ] Implement dark mode support (Bootstrap 5.3 `data-bs-theme="dark"`)
- [ ] Replace Font Awesome 4 with Bootstrap Icons or Font Awesome 6
- [ ] Commit: "Redesign application layout with Bootstrap 5"

### Phase 3: jQuery Removal (Alpine.js + fetch)
Replace jQuery with Alpine.js for DOM reactivity and `fetch()` for server calls.

- [ ] Replace jQuery AJAX patterns with Alpine.js `x-data` + `fetch()`:
  - `$.ajax()` / `$.get()` / `$.post()` -> `fetch()` inside Alpine methods
  - `$(el).show()`/`.hide()` -> `x-show="condition"`
  - `$(el).on('click', ...)` -> `x-on:click="handler"`
  - `$.each()` -> `x-for="item in items"`
  - `$(document).ready()` -> `x-init="..."`
- [ ] Convert filter forms to Alpine.js components with `fetch()`:
  - Philosopher index filtering (`x-data` component with filter state)
  - Text index filtering
  - Work index filtering
- [ ] Convert table sorting to Alpine.js (click header -> `x-on:click` -> re-sort)
- [ ] Replace Cocoon nested forms with Alpine.js add/remove:
  - Author/writing nested forms (`x-for` over dynamic array)
  - Tag/labeling nested forms
- [ ] Remove jQuery dependency entirely
- [ ] Remove `jquery-rails` gem
- [ ] Remove `cocoon` gem
- [ ] Commit: "Replace jQuery + Cocoon with Alpine.js + fetch"

### Phase 4: Data Display Modernisation
Redesign the core data views.

- [ ] **Philosopher Index:** Card-based grid layout with:
  - Thumbnail/avatar placeholder
  - Key metrics (canonicity score, birth-death years)
  - Quick-filter chips
  - Pagination via Alpine.js + fetch()
- [ ] **Philosopher Show:** Clean profile page with:
  - Bootstrap tabs (Bio, Works, Metrics, Names, References)
  - Inline editing via Alpine.js `x-show`/`x-on` + fetch()
  - Linked data/Wikidata widget
- [ ] **Text Index:** Searchable Bootstrap table with:
  - Full-text search via Alpine.js + fetch()
  - Column sorting via `x-on:click`
  - Expandable row details
- [ ] **Work Index:** Similar card/table hybrid
- [ ] **Dictionary/Unit views:** Clean table layouts
- [ ] Replace Pickadate with native HTML5 date inputs (Bootstrap styling)
- [ ] Commit: "Modernise data display views"

### Phase 5: Visualisation Rebuild
Replace outdated visualisation libraries with modern equivalents.

- [ ] **Philosopher Relationship Graph** (replaces Springy/Dracula):
  - Use Sigma.js or D3.js v7 force-directed graph
  - Interactive: click to explore philosopher connections
  - Zoom, pan, search within graph
  - Colour-code by era, tradition, or canonicity
- [ ] **Venn Diagrams** (replaces Venn.js):
  - Upgrade to D3.js v7 with modern Venn layout
  - Or use Observable Plot for set visualisation
- [ ] **Metrics Dashboard** (new):
  - Canonicity distribution chart
  - Timeline of philosopher births/deaths
  - Reference work coverage heatmap
  - Corpus growth over time
- [ ] **Word Cloud / Text Analysis** (replaces pages/pome):
  - Modern word cloud library (d3-cloud or observable)
  - Interactive: click term to search corpus
- [ ] Wrap all visualisations in ES modules pinned via Import Maps
- [ ] Commit: "Rebuild visualisations with D3 v7 and Sigma.js"

### Phase 6: Forms & Interactions
Modernise all form interactions.

- [ ] Styled form components with Bootstrap 5:
  - `form-control`, `form-select`, `form-check`
  - Input groups, floating labels
  - File uploads (`form-control` type="file")
- [ ] Form validation with Alpine.js:
  - Client-side validation feedback (`x-show` error messages)
  - Real-time field validation via `x-on:input`
  - Bootstrap validation classes (`is-valid`, `is-invalid`)
- [ ] Autocomplete for philosopher/work name fields (Alpine.js + fetch())
- [ ] Bulk operations with Alpine.js (select-all checkbox, `x-for` selected items)
- [ ] Confirmation dialogues via Bootstrap modals (replace browser `confirm()`)
- [ ] Commit: "Modernise forms and interactions"

### Phase 7: Performance & Polish
Final optimisation pass.

- [ ] Add loading skeletons/spinners for fetch() partial loads
- [ ] Implement infinite scroll or progressive loading for large lists
- [ ] Add keyboard shortcuts (vanilla JS module) for power users
- [ ] Optimise images and assets
- [ ] Add Open Graph / meta tags for sharing
- [ ] Accessibility audit (ARIA labels, focus management, colour contrast)
- [ ] Cross-browser testing (Chrome, Firefox, Safari, Edge)
- [ ] Mobile testing
- [ ] Commit: "Performance optimisation and polish"

## Migration Strategy for 183 Templates

Rather than rewriting all 183 templates at once, migrate incrementally:

1. **Create new layout** (Phase 2) that works with both old and new templates
2. **Migrate high-traffic pages first:** philosophers/index, philosophers/show,
   texts/index, pages/index
3. **Batch-migrate simple CRUD views:** forms, show pages, edit pages
4. **Migrate visualisation pages last** (Phase 5)
5. **Delete old CSS/JS files** as each view is migrated

## Files to Delete After Migration
- `vendor/assets/bower_components/` (entire directory)
- `bower.json`, `.bowerrc`
- All controller-specific `.js` files (replaced by ES modules via Import Maps)
- All controller-specific `.css` files (replaced by Bootstrap classes)
- `app/assets/stylesheets/scaffolds.css` / `scaffolds.scss`
- `app/assets/stylesheets/application.css` (replaced by Bootstrap entry point)
- `lib/tasks/resolve.rake` (Bower path resolution)

## Success Criteria
- No jQuery dependency
- No Bower dependency
- Responsive design working on mobile/tablet/desktop
- All visualisations functional with modern libraries
- Lighthouse score >= 90 for performance, accessibility, best practices
- All existing functionality preserved
- Page load times improved (target: < 2s for index pages)

## Estimated Effort
- Phase 1 (Asset Pipeline): 2-3 sessions
- Phase 2 (Layout): 2-3 sessions
- Phase 3 (Alpine.js): 3-4 sessions
- Phase 4 (Data Display): 4-6 sessions (183 templates)
- Phase 5 (Visualisations): 3-4 sessions
- Phase 6 (Forms): 2-3 sessions
- Phase 7 (Polish): 2-3 sessions
- **Total: ~18-26 sessions**
