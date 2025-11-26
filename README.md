# Phoenix API + Symfony Admin Demo

A demo application consisting of two cooperating systems:
1.  **Phoenix API**: Backend with PostgreSQL, handling user data and imports.
2.  **Symfony App**: Frontend Admin Panel, communicating with the API via HTTP.

## Tech Stack

-   **Backend**: Elixir, Phoenix Framework, PostgreSQL.
-   **Frontend**: PHP 8.2+, Symfony 6+, Twig, Bootstrap/Tailwind (TBD).
-   **Infrastructure**: Docker, Docker Compose.

## Setup & Running

### Requirements
-   Docker
-   Docker Compose

### Quick Start

1.  Clone the repository.
2.  Build and run the stack:
    ```bash
    docker compose build
    docker compose up
    ```
3.  Access the applications:
    -   **Phoenix API**: `http://localhost:4000`
    -   **Symfony Admin**: `http://localhost:8000/users`

## Testing

Run all tests with a single command:
```bash
make test-all
```

Or run individually:
```bash
make test-phoenix
make test-symfony
```

## Features

-   **Import Users**: POST `/import` (Phoenix) generates random users.
-   **User Management**: Browse, Filter, Sort, Create, Edit, Delete users via Symfony Admin.

## Documentation

-   [Task List](task.md)
-   [Implementation Plan](implementation_plan.md)
