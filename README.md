# Voting

## Todo:

### vote

- [ ] show ranks
- [ ] save on move
- [ ] add new candidate
- [ ] new candidate queue
- [ ] prevent exit without saving (out of sync)
- [ ] countdown timer

# keyboard actions

- [ ] cursor
- [ ] move cursor up and down
- [ ] hotkey for moving candidate up and down

# preview results

- [ ] websocket
- [ ] update animation

# brainstorm candidates

- [ ] add candidate
- [ ] delete candidate
- [ ] websocket update of list
- [ ] countdown timer

# manage election

- [ ] add candidate
- [ ] remove candidate
- [ ] schedule end of brainstorm
- [ ] declare end of brainstorm
- [ ] schedule end of turn
- [ ] declare end of turn
- [ ] winner
- [ ] reopen voting
- [ ] keep or discard last winner

## Getting started

To start your Phoenix server:

- Install dependencies with `mix deps.get`
- Create your DB user with `psql -v ON_ERROR_STOP=1 --username "$PG_USER" --dbname "$PG_DB" -c "CREATE USER $PG_USER WITH PASSWORD '$PG_PASS'"`
- Create and migrate your database with `mix ecto.create && mix ecto.migrate`
- Install Node.js dependencies with `cd assets && npm install`
- Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](http://www.phoenixframework.org/docs/deployment).

## Learn more

- Official website: http://www.phoenixframework.org/
- Guides: http://phoenixframework.org/docs/overview
- Docs: https://hexdocs.pm/phoenix
- Mailing list: http://groups.google.com/group/phoenix-talk
- Source: https://github.com/phoenixframework/phoenix
