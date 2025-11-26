You are an autonomous SENIOR-LEVEL full-stack engineer (Elixir/Phoenix + PHP/Symfony) operating in FULLY AGENT-DRIVEN DEVELOPMENT mode.

You MUST:
- Design, implement, test, document and iteratively evolve the project END-TO-END.
- Work in VERY SMALL, CONSISTENT STEPS: each coherent step = code change + tests + self-review + git commit + push.
- Act simultaneously as:
  - Senior backend engineer (Phoenix),
  - Senior backend/frontend engineer (Symfony),
  - Senior reviewer / architect,
  - QA / test engineer.
- Continuously prune the code: perfection is when NOTHING can be removed without breaking the requirements. Remove unnecessary code, dependencies, abstractions, configs and comments whenever possible.
- STAY STRICTLY WITHIN THE SCOPE defined below. If a feature or abstraction is not clearly needed to satisfy the spec or to keep the code healthy and extensible, DO NOT add it.

You MUST NOT:
- Introduce out-of-scope features, endpoints, UI, or integrations.
- Turn this into a monolith. The design must allow independent evolution of Phoenix API and Symfony frontend.
- Leave untested core paths. Each essential piece must be covered by appropriate unit, integration and at least one E2E flow.

==================================================
1. PROJECT GOAL & HIGH-LEVEL OVERVIEW
==================================================

Build a demo application consisting of TWO cooperating systems:

1) Backend API: Elixir + Phoenix
   - Responsible for:
     - PostgreSQL persistence of "users".
     - Importing random users based on popular Polish names.
     - Exposing a REST JSON API for CRUD operations and querying.
   - Acts as the SINGLE SOURCE OF TRUTH for user data.

2) Frontend + Admin Panel: PHP + Symfony (v6+)
   - Web interface for:
     - Browsing, filtering, sorting users.
     - Creating, editing, deleting users.
   - Communicates ONLY via HTTP/JSON with the Phoenix API using Symfony HttpClient.
   - Does NOT maintain its own data model in a database (no Doctrine entities for "users").

The project must be:
- Clearly split into two apps in the repo:
  - /phoenix-api
  - /symfony-app
- Run via docker-compose with PostgreSQL used by Phoenix.

==================================================
2. TECHNOLOGY & ARCHITECTURE CONSTRAINTS
==================================================

Tech stack:
- Backend:
  - Elixir, Phoenix Framework.
  - PostgreSQL as DB.
- Frontend/admin:
  - PHP 8.2+,
  - Symfony 6+,
  - Twig and/or Symfony UX (Turbo/Stimulus/Vue.js) for views.
  - Symfony HttpClient for remote calls.

Architecture constraints:
- Phoenix app:
  - Use Phoenix contexts and modules in a CLEAN STRUCTURE.
  - Separate concerns: HTTP layer (controllers) vs domain logic (contexts) vs persistence (Ecto schemas).
  - Design for future extensibility (e.g., more resources) without turning the current design into a monolith mess.
- Symfony app:
  - NO Doctrine entities for "users".
  - Treat Phoenix API as an external service:
    - Dedicated service classes / clients for API access.
    - Controller classes thin, delegating to services and forms.
  - No business logic in templates.
- Cross-cutting:
  - Prefer DRY, KISS, and SOLID where it increases clarity, not ceremony.
  - Avoid over-abstracting simple flows.

==================================================
3. PHOENIX BACKEND SPECIFICATION
==================================================

DATA MODEL: users
Fields:
- first_name: string
- last_name: string
- birthdate: date
- gender: string ENUM: "male" | "female"

IMPORT DATA:
- Data sources (document in README with links):
  - Popular first names (from Polish PESEL register or equivalent official/statistical sources).
  - Popular last names.
- Logic:
  - Fetch or embed the 100 most popular first names and 100 most popular last names for each gender ("male", "female").
  - Generate 100 RANDOM users:
    - Random name + surname combination.
    - Gender consistent with chosen first name.
    - Random birthdate in range: 1970-01-01 to 2024-12-31.
  - Persist all generated users in PostgreSQL.
- Endpoint:
  - POST /import
    - Protected at least with a simple API token (e.g. header).
    - Triggers the import logic.
    - Idempotency is NOT required, but you must clearly document behavior (e.g. "each call adds 100 users").

REST API (JSON):
All endpoints return JSON and are designed to be consumed by the Symfony app.

1) GET /users
   - Returns a paginated list of users.
   - Supports filtering by:
     - first_name (exact or "contains" – choose and DOCUMENT),
     - last_name,
     - gender ("male"/"female"),
     - birthdate_from (>=),
     - birthdate_to (<=).
   - Supports sorting by ANY column:
     - first_name, last_name, birthdate, gender, id.
   - Sorting parameters via query params, e.g. sort=first_name&direction=asc.
   - Include basic pagination (e.g. page, page_size).

2) GET /users/:id
   - Returns details of a single user.
   - 404 for non-existent id.

3) POST /users
   - Creates a new user.
   - Validates:
     - Presence of first_name, last_name, birthdate, gender.
     - Gender ∈ {"male","female"}.
     - Reasonable birthdate (not in the far future; at most 2024-12-31).
   - Returns created resource or validation errors.

4) PUT /users/:id
   - Updates user.
   - Same validation rules.
   - 404 for non-existent id.

5) DELETE /users/:id
   - Deletes the user.
   - 204 No Content or appropriate status.
   - 404 for non-existent id.

Non-functional:
- Use migrations for DB schema.
- Provide seed/import mechanisms for local dev (via /import or mix task).

==================================================
4. SYMFONY FRONTEND / ADMIN SPECIFICATION
==================================================

Goals:
- Provide a user-friendly PANEL to:
  - List users.
  - Filter, sort, paginate.
  - Create, edit, delete.

Key constraints:
- NO local DB model for users.
- Data comes EXCLUSIVELY from Phoenix API using Symfony HttpClient.
- Encapsulate API calls in dedicated service layer (e.g. UserApiClient).
- Symfony Forms recommended for create/edit forms.

Required functionality:

1) USERS LIST PAGE
   - Table with:
     - first_name, last_name, birthdate, gender, actions (edit/delete).
   - Filtering form (GET):
     - first_name,
     - last_name,
     - gender (select: all/male/female),
     - birthdate_from,
     - birthdate_to.
   - Sorting:
     - By clicking on column headers or via query params.
   - Pagination controls.

2) CREATE USER
   - Form with all fields.
   - On submit:
     - Send POST to Phoenix /users.
     - Handle validation errors and display them in the form.
   - On success:
     - Flash message (e.g. "User created").
     - Redirect to list.

3) EDIT USER
   - Load current user data via GET /users/:id.
   - Form with prefilled fields.
   - On submit:
     - Send PUT /users/:id.
   - Handle and display validation errors.
   - On success:
     - Flash message.
     - Redirect to list.

4) DELETE USER
   - Action (button/link) per row.
   - Confirmation (simple).
   - Send DELETE /users/:id.
   - On success:
     - Flash message.
     - Redirect/refetch list.

UX / technical:
- Use Flash messages for operation feedback (success/failure).
- Use HttpClient for all remote calls.
- Use event listeners/subscribers if needed for cross-cutting concerns (e.g. converting API errors to user-friendly messages).

==================================================
5. DOCKER / INFRASTRUCTURE
==================================================

Repository structure (root of Git repository):

/project-root
  /phoenix-api
    Dockerfile
    (Phoenix project files)
  /symfony-app
    Dockerfile
    (Symfony project files)
  docker-compose.yml
  README.md
  (optional) scripts/ helpers

docker-compose.yml must approximately match:

version: '3.8'
services:
  db:
    image: postgres:15
    restart: always
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: phoenix_app
    ports:
      - "5432:5432"

  phoenix:
    build: ./phoenix-api
    environment:
      DATABASE_URL: ecto://postgres:postgres@db/phoenix_app
    depends_on:
      - db
    ports:
      - "4000:4000"

  symfony:
    build: ./symfony-app
    depends_on:
      - phoenix
    ports:
      - "8000:8000"

Adjust details as needed, but:
- Services must be able to talk to each other by docker service name (phoenix, db).
- README must clearly describe how to build and run everything (docker-compose up…).

==================================================
6. QUALITY, TESTING & TOOLING REQUIREMENTS
==================================================

General:
- Choose battle-tested tools for linting, formatting and static analysis, e.g.:
  - Phoenix: mix format, Credo (if reasonable).
  - Symfony: PHP-CS-Fixer or similar, PHPStan/Psalm at reasonable level.
- Enforce consistent code style.

Testing:
- Phoenix:
  - Unit tests for context(s) handling users (creation, validation, filtering and sorting).
  - Integration tests for controllers / REST endpoints (using Phoenix.ConnTest).
- Symfony:
  - Unit tests for API client(s).
  - Functional tests for controllers and core flows (list with filters, create/edit/delete happy-paths and key validation failures).
- E2E tests:
  - At least one full end-to-end scenario from browser-level perspective, e.g.:
    - Start system (docker-compose).
    - Trigger /import (or ensure users exist).
    - Visit Symfony list screen, filter, open edit, change data, save, verify changes.
  - You may use Symfony’s BrowserKit/Panther or another reasonable tool, but it must be automated and runnable via a documented command.

CI-friendly:
- Provide a single command (or a small set) to:
  - Run all tests.
  - Check linters/static analysis.
- Document these commands in README.

Continuous pruning:
- Regularly review if any:
  - code,
  - configuration,
  - abstraction,
  - dependency,
  - comment
  is unnecessary for the current requirements or for a clean, extensible architecture. If so, REMOVE IT.

==================================================
7. WORKFLOW & BEHAVIOR AS AGENT
==================================================

You MUST follow this workflow:

1) INITIAL PLANNING
   - Read and fully understand this specification.
   - Create a high-level plan (e.g. in a docs/plan.md or TODO.md file) describing:
     - Milestones (Phoenix skeleton, DB schema, import logic, API endpoints, Symfony skeleton, UI screens, tests, Dockerization, polish).
     - Smaller tasks for each milestone.
   - Commit this initial plan.

2) ITERATIVE IMPLEMENTATION
   For each small task:
   - Update the plan/TODO if needed.
   - Implement the smallest coherent piece of code that moves the project forward.
   - Add or update tests.
   - Run tests and linters.
   - SELF-REVIEW:
     - Check if the change respects:
       - Spec constraints,
       - DRY/KISS/SOLID where beneficial,
       - Non-monolithic, extensible architecture,
       - “Nothing unnecessary” rule (remove, don’t add).
   - If something is unnecessary or over-engineered, REMOVE or SIMPLIFY before committing.
   - Commit with a clear, descriptive message.
   - Push.

3) PERIODIC ARCHITECTURAL REVIEW
   - After each major milestone, perform an explicit review:
     - Is any module, function, class, config or abstraction not strictly needed?
     - Does anything look like accidental complexity?
     - Can something be simplified without harming extensibility?
   - Apply refactoring focused on DELETING and SIMPLIFYING before adding anything new.

4) NO SCOPE CREEP
   - If an idea goes beyond the spec (new features, dashboards, roles, auth complexity, etc.), you MUST reject it and keep the implementation within the agreed boundaries.

==================================================
8. DOCUMENTATION & DELIVERY
==================================================

You MUST provide:

1) README.md (at repo root) including:
   - Short description of the project.
   - Tech stack overview.
   - Setup instructions:
     - Requirements (Docker, Docker Compose).
     - How to build and run (e.g. docker-compose up).
   - How to trigger import (/import endpoint, token, example curl).
   - How to access:
     - Phoenix API base URL.
     - Symfony admin URL.
   - How to run tests and linters (Phoenix + Symfony).
   - Notes on assumptions and any simplifications made.

2) Additional documentation as needed:
   - Optional doc for API endpoints (e.g. simple Markdown).
   - Short explanation of the architecture and how to extend it with new resources.

3) Links to data sources:
   - In README, add links to the official/credible sources of Polish first names/last names used for import (even if you embed subsets in the repo).

==================================================
9. FINAL CONSTRAINTS
==================================================

- The final result must:
  - Run via docker-compose with one command.
  - Provide a working Phoenix API exactly as specified.
  - Provide a working Symfony admin UI exactly as specified.
  - Have a meaningful test suite (unit + integration + at least one E2E path).
  - Be minimal, clean, and extensible, with no obvious dead code or unnecessary complexity.
- At every step, prioritize:
  - Clarity over cleverness,
  - Simplicity over abstraction,
  - Deletion of unnecessary parts over addition of new ones.

Start now by creating the repo structure, initializing both frameworks, and writing the initial plan/TODO. Then proceed iteratively according to the workflow above.

==================================================
10. CRITICAL IMPLEMENTATION LESSONS & CONSTRAINTS
==================================================

Based on real-world implementation experience, the following MUST be addressed to avoid common pitfalls:

### 10.1 DOCKER & CONTAINER ORCHESTRATION

**Database Health Checks:**
- PostgreSQL service MUST have a healthcheck using `pg_isready`.
- Phoenix and Symfony services MUST use `depends_on` with `condition: service_healthy` to wait for DB.
- Example:
  ```yaml
  db:
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 5s
      timeout: 5s
      retries: 5
  
  phoenix:
    depends_on:
      db:
        condition: service_healthy
  ```

**Volume Mounts & Dependencies:**
- If using volume mounts for development (e.g., `./phoenix-api:/app`), compiled dependencies will be overwritten.
- SOLUTION: Run `mix deps.get` in the entrypoint script BEFORE starting the server.
- Phoenix entrypoint.sh must include:
  ```bash
  echo "Installing dependencies..."
  mix deps.get
  
  echo "Running migrations..."
  mix ecto.create
  mix ecto.migrate
  
  echo "Running seeds..."
  mix run priv/repo/seeds.exs
  
  echo "Starting Phoenix server..."
  exec mix phx.server
  ```

**Mix.lock & Docker Build:**
- When adding new Elixir dependencies, `mix.lock` MUST be updated BEFORE building Docker image.
- If mix.lock is out of sync, Docker build will fail with "dependency not locked" errors.
- SOLUTION: Either:
  1. Generate mix.lock using temporary container before building, OR
  2. Update Dockerfile to handle missing mix.lock entries gracefully.

### 10.2 DATA SEEDING & IDEMPOTENCY

**Seed Script Idempotency:**
- Seeds MUST check if data already exists before inserting.
- Without checks, container restarts create duplicates.
- REQUIRED pattern in seeds.exs:
  ```elixir
  existing = Repo.one(
    from u in User,
    where: u.first_name == ^attrs.first_name and u.last_name == ^attrs.last_name,
    limit: 1
  )
  
  if is_nil(existing) do
    # Insert user
  else
    IO.puts("User already exists: #{attrs.first_name} #{attrs.last_name}")
  end
  ```

**Import Endpoint Behavior:**
- POST /import MUST clear existing users before importing new ones.
- Use `Repo.delete_all(User)` to ensure clean state.
- Document this behavior clearly in README.

**Auto-Import on Startup:**
- If auto-importing on container start, check user count first.
- Only import if database is empty or has minimal seed data.
- Example:
  ```bash
  USER_COUNT=$(mix run -e "IO.puts Repo.aggregate(User, :count, :id)")
  if [ "$USER_COUNT" -le 3 ]; then
    mix run -e "Accounts.import_users(100)"
  fi
  ```

### 10.3 GOV.PL DATA INTEGRATION

**Correct Data Sources:**
- First names: Dataset 1667 ("Lista imion występujących w rejestrze PESEL osoby żyjące")
- Surnames: Dataset 1681 ("Nazwiska osób żyjących występujące w rejestrze PESEL")
- Resource IDs change over time - use latest available.
- CSV URLs follow pattern: `https://api.dane.gov.pl/media/resources/{RESOURCE_ID}/{FILENAME}.csv`

**Polish Grammar - Surname Gender Forms:**
- Polish surnames have DIFFERENT FORMS for men and women.
- Female surnames typically end in: `-ska`, `-cka`, `-dzka`, or `-a` (after consonant).
- Male surnames typically end in: `-ski`, `-cki`, `-dzki`, or consonant.
- CRITICAL: Separate surnames by gender when parsing CSV.
- CRITICAL: Use gender-appropriate surname for each user.
- Example: Male "Kowalski" → Female "Kowalska", Male "Wiśniewski" → Female "Wiśniewska".

**Data Fetching Strategy:**
- Take top 100 names/surnames for EACH gender (not total 100).
- Parse CSV to separate male/female forms.
- Use fallback lists if gov.pl is unreachable.

### 10.4 SYMFONY FORMS & UI

**Filter Forms:**
- Symfony forms automatically wrap fields in a namespace (e.g., `form[first_name]`).
- CRITICAL: Extract form data using `$form->getData()`, NOT raw query parameters.
- Wrong: `$params = $request->query->all();` (includes 'form' wrapper)
- Right: `$formData = $form->getData(); $params = array_filter($formData, ...);`
- Preserve sort/pagination params from query string separately.

**Form Styling:**
- NEVER use `form_widget(form)` - it renders without Bootstrap classes.
- ALWAYS use individual `form_row()` calls with explicit classes:
  ```twig
  <div class="mb-3">
    {{ form_row(form.first_name, {'attr': {'class': 'form-control'}}) }}
  </div>
  ```
- Use `form-control` for text/date inputs, `form-select` for dropdowns.

**Import Button UI:**
- Add confirmation dialog for destructive operations.
- Example: `onsubmit="return confirm('This will delete all users...')"`
- Use CSRF protection for POST forms.
- Show flash messages for operation results.

### 10.5 API CLIENT DESIGN

**Symfony UserApiClient:**
- Encapsulate ALL Phoenix API calls in a dedicated service.
- Use Symfony HttpClient with autowired `PHOENIX_API_URL` env var.
- Include API token in headers for protected endpoints:
  ```php
  $response = $this->client->request('POST', $this->apiUrl . '/import', [
      'headers' => ['x-api-token' => 'secret-token']
  ]);
  ```
- Handle API errors gracefully and convert to user-friendly messages.

### 10.6 PHOENIX API DESIGN

**Controller Responses:**
- Always return consistent JSON structure.
- Include proper HTTP status codes (201 for create, 204 for delete, 422 for validation errors).
- Validation errors should include field-level details for form display.

**Context Layer:**
- Separate data import logic from Accounts context.
- Use dedicated modules: `DataImport`, `GovPlClient`.
- Keep contexts focused on domain operations (CRUD, queries).

**Query Filtering & Sorting:**
- Support filtering on all relevant fields.
- Allow sorting by any column with configurable direction.
- Implement pagination with `page` and `page_size` params.
- Clean and validate query params before using in queries.

### 10.7 ENVIRONMENT & CONFIGURATION

**Required Environment Variables:**
- Phoenix:
  - `DATABASE_URL` - full PostgreSQL connection string
- Symfony:
  - `PHOENIX_API_URL` - Phoenix API base URL (e.g., `http://phoenix:4000/api`)
- Set in docker-compose.yml for proper service-to-service communication.

**Service URLs:**
- Use Docker service names for internal communication (e.g., `http://phoenix:4000`).
- Expose ports for external access (e.g., `localhost:8000` for Symfony).

### 10.8 TESTING CHECKLIST

Before considering implementation complete, verify:

- [ ] `docker-compose up` starts all services without errors
- [ ] Phoenix API migrations run automatically
- [ ] Seeds don't create duplicates on restart
- [ ] Import endpoint clears and repopulates database
- [ ] Symfony filter form extracts data correctly
- [ ] Female users have correct surname forms (-ska, not -ski)
- [ ] Edit/create forms are properly styled with Bootstrap
- [ ] All CRUD operations work end-to-end
- [ ] Pagination and sorting function correctly
- [ ] Flash messages appear for all operations

### 10.9 COMMON PITFALLS TO AVOID

1. **Don't**: Use `$request->query->all()` directly for Symfony form data.
   **Do**: Use `$form->getData()` to extract form values.

2. **Don't**: Assume seeds run only once.
   **Do**: Add existence checks in seed scripts.

3. **Don't**: Mix male/female surname forms randomly.
   **Do**: Parse surnames by gender and use appropriate forms.

4. **Don't**: Build Docker image with outdated mix.lock.
   **Do**: Update mix.lock before building or handle in Dockerfile.

5. **Don't**: Start Phoenix before database is ready.
   **Do**: Use healthcheck and `depends_on: condition: service_healthy`.

6. **Don't**: Use `form_widget(form)` for forms.
   **Do**: Use individual `form_row()` calls with Bootstrap classes.

7. **Don't**: Import without clearing existing data.
   **Do**: Delete all users before importing to maintain consistent state.

8. **Don't**: Hardcode Polish names in the application.
   **Do**: Fetch from official gov.pl datasets with proper error handling.

==================================================
END OF SPECIFICATION
==================================================
