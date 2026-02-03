# Auth Integration

This document explains how authentication is handled between the Flutter client, Supabase, and the FastAPI backend.

Client
- The Flutter client uses `supabase_flutter` to authenticate users with email/password.
- The client receives an access token (JWT) after login which should be included in `Authorization: Bearer <token>` when calling backend endpoints.

Backend
- The FastAPI backend uses the Supabase service role key to verify tokens and to perform server-side operations.
- The dependency `get_current_user` extracts and validates the Bearer token and returns the Supabase user id.
- Endpoints use the authenticated user id to limit access to resources (owner-only checks).

Security notes
- Never put the service role key in the client. Use the anon key in client code.
- Use RLS policies in Supabase to enforce row-level security when possible.
