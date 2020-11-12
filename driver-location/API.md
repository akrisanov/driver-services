# Internal Endpoint

## `GET /drivers/:id/locations?minutes=5`

### Response

```json
[
  {
    "latitude": 48.864193,
    "longitude": 2.350498,
    "updated_at": "2018-04-05T22:36:16Z"
  },
  {
    "latitude": 48.863921,
    "longitude":  2.349211,
    "updated_at": "2018-04-05T22:36:21Z"
  }
]
```

### Role

This endpoint is called by the Zombie Driver service.

### Behaviour

For a given driver, returns all the locations from the last 5 minutes (given minutes = 5).
