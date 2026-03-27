# Common Patterns

## Skeleton Projects

When implementing new functionality, start from a proven foundation:

1. Search for battle-tested skeleton projects or starter templates that match your stack
2. Evaluate candidates against your requirements:
   - Security posture and known vulnerabilities
   - Extensibility and how well it accommodates future needs
   - Relevance to your specific use case
   - Quality of the implementation and test coverage
3. Clone or fork the best match as your foundation
4. Iterate within the proven structure rather than starting from scratch

Prefer adopting a proven scaffold over hand-rolling boilerplate.

## Repository Pattern

Encapsulate all data access behind a consistent interface:

- Define a standard set of operations: `findAll`, `findById`, `create`, `update`, `delete`
- Concrete implementations handle the storage details (database, REST API, file system, etc.)
- Business logic depends on the abstract interface, not the storage mechanism
- Enables easy swapping of data sources and simplifies testing with mock implementations

```
// Pseudocode
interface UserRepository {
  findAll(): User[]
  findById(id): User | null
  create(data): User
  update(id, data): User
  delete(id): void
}

class PostgresUserRepository implements UserRepository { ... }
class InMemoryUserRepository implements UserRepository { ... }  // for tests
```

## API Response Format

Use a consistent envelope for all API responses:

```json
{
  "success": true,
  "data": { ... },
  "error": null,
  "meta": {
    "total": 100,
    "page": 1,
    "limit": 20
  }
}
```

- `success` — boolean indicating whether the request succeeded
- `data` — the payload; `null` on error
- `error` — human-readable error message; `null` on success
- `meta` — pagination or other metadata; omit when not applicable

Apply this envelope consistently across all endpoints so clients can handle responses uniformly.
