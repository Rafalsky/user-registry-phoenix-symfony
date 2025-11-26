# Walkthrough

I have implemented the Phoenix API + Symfony Admin application as requested.

## Architecture

-   **Phoenix API**: Handles user data persistence (PostgreSQL), import logic, and exposes a JSON REST API.
    -   Uses `Accounts` context and `User` schema.
    -   Implements `DataImport` for generating random Polish users.
    -   Exposes endpoints for CRUD, filtering, sorting, and pagination.
-   **Symfony App**: Admin interface for managing users.
    -   Uses `UserApiClient` to communicate with Phoenix.
    -   Uses `UserController` and `UserType` form for UI logic.
    -   Uses Twig templates with Bootstrap for styling.
-   **Infrastructure**: Docker Compose orchestrates `db`, `phoenix`, and `symfony` services.

## How to Run

1.  **Start the stack**:
    ```bash
    make up
    # or
    docker-compose up --build -d
    ```

2.  **Access the applications**:
    -   **Symfony Admin**: [http://localhost:8000/users](http://localhost:8000/users)
    -   **Phoenix API**: [http://localhost:4000/api/users](http://localhost:4000/api/users)

3.  **Import Users**:
    You can trigger the import via the API:
    ```bash
    make import-users
    # or
    curl -X POST http://localhost:4000/api/import -H "x-api-token: secret-token"
    ```

## Testing

I have included a `Makefile` to run tests easily inside Docker containers.

-   **Run all tests**:
    ```bash
    make test-all
    ```

-   **Run Phoenix tests** (Unit + Integration):
    ```bash
    make test-phoenix
    ```

-   **Run Symfony tests** (Functional):
    ```bash
    make test-symfony
    ```

## Verification Results

-   **Phoenix Tests**: Verified `Accounts` context logic (CRUD, validations, import) and `UserController` API endpoints.
-   **Symfony Tests**: Verified `UserController` UI logic using `WebTestCase` and mocked API client.
-   **Builds**: Verified `docker build` for both services.

## Pruning

-   Removed unused aliases and code.
-   Ensured no unnecessary dependencies (e.g. no Doctrine entities in Symfony, no HTML/Webpack in Phoenix).
-   Kept controllers and services thin.
