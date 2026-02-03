from fastapi import FastAPI, HTTPException, Depends, Header
from pydantic import BaseModel, EmailStr, Field
from typing import Optional, List
import os

from .supabase_client import supabase


from .ai_utils import summarize_text

app = FastAPI(title='Connectinno API')

class SignupModel(BaseModel):
    email: EmailStr
    password: str
    full_name: Optional[str] = None

class LoginModel(BaseModel):
    email: EmailStr
    password: str

class NoteIn(BaseModel):
    # client may send user_id but server will ignore it and use authenticated user
    user_id: Optional[str] = None
    title: str = Field(..., min_length=1, max_length=200)
    content: Optional[str] = Field('', max_length=2000)
    pinned: Optional[bool] = False

class NoteUpdate(BaseModel):
    title: Optional[str] = Field(None, min_length=1, max_length=200)
    content: Optional[str] = Field(None, max_length=2000)
    pinned: Optional[bool]


def _get_user_from_supabase_token(token: str):
    """Try several supabase-py auth methods to get user info from access token."""
    try:
        # new versions
        res = supabase.auth.get_user(token)
        if getattr(res, 'error', None):
            # try api.get_user
            raise Exception('get_user error')
        data = getattr(res, 'data', None)
        if isinstance(data, dict) and data.get('user'):
            return data['user']
        if getattr(res, 'user', None):
            return res.user
    except Exception:
        try:
            res2 = supabase.auth.api.get_user(token)
            if getattr(res2, 'error', None):
                raise Exception('api.get_user error')
            return getattr(res2, 'user', None) or getattr(res2, 'data', None)
        except Exception:
            return None


async def get_current_user(authorization: Optional[str] = Header(None)):
    """Dependency: extract Bearer token from Authorization header and return Supabase user id."""
    if not authorization:
        raise HTTPException(status_code=401, detail='Authorization header is required')
    if not authorization.startswith('Bearer '):
        raise HTTPException(status_code=401, detail='Authorization header must be a Bearer token')
    token = authorization.split(' ', 1)[1].strip()
    user = _get_user_from_supabase_token(token)
    if not user:
        raise HTTPException(status_code=401, detail='Invalid or expired token')
    uid = None
    if isinstance(user, dict):
        uid = user.get('id') or (user.get('user') or {}).get('id')
    else:
        uid = getattr(user, 'id', None)
    if not uid:
        raise HTTPException(status_code=401, detail='Unable to determine user id')
    return uid

@app.post('/auth/signup')
async def signup(data: SignupModel):
    # Use Supabase Auth to sign up
    res = supabase.auth.sign_up({"email": data.email, "password": data.password})
    if getattr(res, 'error', None):
        # provide Supabase error details if available
        raise HTTPException(status_code=400, detail=getattr(res.error, 'message', str(res.error)))
    # Optionally store profile in public.users table using service role
    try:
        profile = supabase.table('users').insert({
            'id': res.user.id if getattr(res, 'user', None) else None,
            'email': data.email,
            'full_name': data.full_name,
        }).execute()
    except Exception:
        profile = None
    return {"auth": res, "profile": getattr(profile, 'data', None)}

@app.post('/auth/login')
async def login(data: LoginModel):
    # Note: sign_in may differ by supabase-py version
    res = supabase.auth.sign_in_with_password({"email": data.email, "password": data.password})
    if getattr(res, 'error', None):
        raise HTTPException(status_code=401, detail=getattr(res.error, 'message', str(res.error)))
    return {"session": getattr(res, 'data', res)}

@app.get('/notes', response_model=List[dict])
async def list_notes(q: Optional[str] = None, filter: str = 'both', user_id: str = Depends(get_current_user)):
    # list only notes for the authenticated user
    query = supabase.table('notes').select('*').eq('user_id', user_id)
    res = query.execute()
    if getattr(res, 'error', None):
        raise HTTPException(status_code=500, detail=str(res.error))
    notes = getattr(res, 'data', res) or []
    # server-side optional filter (simple contains)
    if q:
        ql = q.lower()
        def match(n):
            t = (n.get('title') or '').lower()
            c = (n.get('content') or '').lower()
            if filter == 'title':
                return ql in t
            if filter == 'content':
                return ql in c
            return ql in t or ql in c
        notes = [n for n in notes if match(n)]
    # order pinned first then by updated_at desc
    notes.sort(key=lambda n: (0 if n.get('pinned') else 1, n.get('updated_at') or n.get('created_at')), )
    return notes

@app.post('/notes')
async def create_note(note: NoteIn, user_id: str = Depends(get_current_user)):
    # server ignores any supplied user_id and uses authenticated user
    if not note.title or not note.title.strip():
        raise HTTPException(status_code=400, detail='Title is required and cannot be empty')
    try:
        res = supabase.table('notes').insert({
            'user_id': user_id,
            'title': note.title.strip(),
            'content': (note.content or '').strip(),
            'pinned': bool(note.pinned),
        }).execute()
        if getattr(res, 'error', None):
            raise Exception(getattr(res.error, 'message', str(res.error)))
        return getattr(res, 'data', res)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f'Failed to create note: {e}')

@app.put('/notes/{note_id}')
async def update_note(note_id: str, data: NoteUpdate, user_id: str = Depends(get_current_user)):
    # ensure note belongs to user
    look = supabase.table('notes').select('*').eq('id', note_id).execute()
    if getattr(look, 'error', None):
        raise HTTPException(status_code=500, detail=str(look.error))
    rows = getattr(look, 'data', look) or []
    if not rows:
        raise HTTPException(status_code=404, detail='Note not found')
    if rows[0].get('user_id') != user_id:
        raise HTTPException(status_code=403, detail='Not allowed')
    payload = {k: v for k, v in data.dict().items() if v is not None}
    if not payload:
        raise HTTPException(status_code=400, detail='No fields to update')
    # validate title if provided
    if 'title' in payload and (not isinstance(payload['title'], str) or not payload['title'].strip()):
        raise HTTPException(status_code=400, detail='Title cannot be empty')
    res = supabase.table('notes').update(payload).eq('id', note_id).execute()
    if getattr(res, 'error', None):
        raise HTTPException(status_code=500, detail=getattr(res.error, 'message', str(res.error)))
    return getattr(res, 'data', res)

@app.delete('/notes/{note_id}')
async def delete_note(note_id: str, user_id: str = Depends(get_current_user)):
    # ensure note belongs to user
    look = supabase.table('notes').select('*').eq('id', note_id).execute()
    if getattr(look, 'error', None):
        raise HTTPException(status_code=500, detail=str(look.error))
    rows = getattr(look, 'data', look) or []
    if not rows:
        raise HTTPException(status_code=404, detail='Note not found')
    if rows[0].get('user_id') != user_id:
        raise HTTPException(status_code=403, detail='Not allowed')
    res = supabase.table('notes').delete().eq('id', note_id).execute()
    if getattr(res, 'error', None):
        raise HTTPException(status_code=500, detail=getattr(res.error, 'message', str(res.error)))
    return {"deleted": True}


@app.post('/notes/{note_id}/summary')
async def summarize_note(note_id: str, max_sentences: int = 3, user_id: str = Depends(get_current_user)):
    """Return a short extractive summary for the authenticated user's note.

    This endpoint enforces ownership and uses a small deterministic summarizer
    (`backend/app/ai_utils.py`) as a placeholder for an LLM-backed summarizer.
    """
    # load note and verify owner
    look = supabase.table('notes').select('*').eq('id', note_id).execute()
    if getattr(look, 'error', None):
        raise HTTPException(status_code=500, detail=getattr(look.error, 'message', str(look.error)))
    rows = getattr(look, 'data', look) or []
    if not rows:
        raise HTTPException(status_code=404, detail='Note not found')
    if rows[0].get('user_id') != user_id:
        raise HTTPException(status_code=403, detail='Not allowed')
    content = (rows[0].get('content') or '')
    if not content.strip():
        raise HTTPException(status_code=400, detail='Note has no content to summarize')
    try:
        max_s = max(1, min(10, int(max_sentences)))
    except Exception:
        max_s = 3
    summary = summarize_text(content, max_sentences=max_s)
    return {"note_id": note_id, "summary": summary, "method": "naive-extractive"}

# simple health
@app.get('/')
async def root():
    return {"status": "ok"}
