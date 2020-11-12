# Public Endpoints

## `PATCH /drivers/:id/locations`

### Payload

```json
{
  "latitude": 48.864193,
  "longitude": 2.350498
}
```

### Role

During a typical day, thousands of drivers send their coordinates every 5 seconds to this endpoint.

### Behaviour

Coordinates received on this endpoint are converted to [NSQ](https://github.com/nsqio/nsq) messages
listened by the `Driver Location` service.

## `GET /drivers/:id`

### Response

```json
{
  "id": 42,
  "zombie": true
}
```

### Role

Users request this endpoint to know if a driver is a zombie.
A driver is a zombie if he has driven less than 500 meters in the last 5 minutes.

### Behaviour

This endpoint forwards the HTTP request to the `Zombie Driver` service.
