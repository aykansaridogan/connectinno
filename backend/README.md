FastAPI backend with Supabase

Instructions:

1) Copy `.env.example` to `.env` and fill the Supabase values (use service role for server operations):

```bash
cp .env.example .env
# edit .env
```

2) Create and activate a virtualenv, install deps:

```bash
python -m venv .venv
. .venv/Scripts/activate    # windows
pip install -r requirements.txt
```

3) Run the server:

```bash
uvicorn app.main:app --host 0.0.0.0 --port 3333 --reload
```

Notes:
- This server uses the Supabase service role key; keep it secret and do not expose in clients.
- Auth uses Supabase Auth via the service client. For production, implement proper session handling and token exchange.
- Adjust endpoints to match your Supabase schema (users/notes tables) as needed.
