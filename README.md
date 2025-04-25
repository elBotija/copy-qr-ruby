# README
## Database
Currently using a local SQLite

## Development
Views a written in [Haml](https://haml.info/). To know which file renders the
view, inspect the DOM to find the magic comments(`<!-- BEGIN path/to/view -->`)
with the path of the views.

### Build container image
```bash
docker-compose build
```
### Run container
```bash
docker-compose up app
```
Will run the Rails app and expose it in http://localhost:3000.
To access the app use the test user `usuario@ejemplo.com` with password `123456`

### Access Rails console
```bash
docker-compose exec app bundle exec bin/rails console
```

### Access database console
```bash
docker-compose exec app bundle exec bin/rails dbconsole
```

### Run tests
```bash
docker-compose exec app bundle exec rspec
```

### View container logs
```bash
docker-compose logs -f app
```

### Stop container
```bash
docker-compose down
```
