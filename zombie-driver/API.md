# Internal Endpoint

## `GET /drivers/:id`

### Response

```json
{
  "id": 42,
  "zombie": true
}
```

### Role

This endpoint is called by the Gateway service.

### Behaviour

Returns the zombie state of a given driver.
