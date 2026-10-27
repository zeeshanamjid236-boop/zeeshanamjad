CHAMPIONS — PUBLISH SETUP (READ FIRST)

This package removes browser-only demo storage and uses Supabase for real accounts and shared data. It still needs your own free Supabase project credentials and one admin account before it can be live.

A) CREATE DATABASE
1. Sign in at https://supabase.com and create a project.
2. Open SQL Editor > New query.
3. Open schema.sql from this ZIP, copy all SQL, paste it, and click Run.
   If the last Realtime publication line says the table is already added, remove just that final line and run the rest; then enable Realtime for cc_messages and cc_poll_votes in Database > Replication.

B) CONNECT WEBSITE
1. Supabase Project Settings > API (or Connect) and copy the Project URL and public anon/publishable key.
2. Open index.html in a text editor.
3. Find:
   const SUPABASE_URL = "PASTE_YOUR_SUPABASE_PROJECT_URL_HERE";
   const SUPABASE_ANON_KEY = "PASTE_YOUR_SUPABASE_PUBLIC_ANON_KEY_HERE";
4. Replace the placeholder strings with your Project URL and public key. NEVER use a service_role or secret key in website code.
5. Save index.html.

C) CREATE YOUR ADMIN ACCOUNT
1. Publish the website and open it.
2. Use Create account with your own email and password. If email confirmation is enabled, confirm the email first and log in.
3. In Supabase SQL Editor run this query, replacing the email:
   insert into public.cc_admins(user_id)
   select id from auth.users where email = 'YOUR_EMAIL@example.com'
   on conflict (user_id) do nothing;
4. Log out and log in again. Admin menu will appear. Only admins can publish official polls and feedback; database policies enforce that permission.

D) PUBLISH ON GITHUB PAGES
1. Extract the ZIP on your computer.
2. In your GitHub repository, upload index.html and schema.sql to the ROOT (top level) of the repository. Commit changes.
3. Repository > Settings > Pages > Deploy from a branch > Branch main > Folder /(root) > Save.
4. Wait a few minutes and open the github.io link shown in Pages. Share that link with students.
5. Supabase > Authentication > URL Configuration: add your exact GitHub Pages URL to Site URL and Redirect URLs (for example https://YOUR-USERNAME.github.io/YOUR-REPO/).

FEATURES
- Email/password sign-up and login
- Shared polls; one vote per account per poll
- Admin-published daily feedback and one rating per account
- Fun/community posts and For Sale listings
- Groups with public/private membership rules and member-only group messages
- Realtime chat updates when Realtime is enabled

IMPORTANT PRIVACY / LIMITS
- Private group creators are automatically made members; other students cannot join private groups unless an admin/creator flow is added. Do not put sensitive personal information in posts.
- This is a community website, not the official WhatsApp app. It cannot send WhatsApp messages or provide WhatsApp end-to-end encryption.
- Test with two student accounts before inviting the full class. Check Supabase logs and policies. This starter package is not a formal security audit.
