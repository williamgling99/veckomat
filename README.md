# Veckomat — shared meal planner

A responsive Swedish meal-planning app built with React, Vite and Supabase. Includes email/password auth, household invite codes, recipe CRUD, weekly breakfast/lunch/dinner planning, a shared shopping checklist and Supabase Realtime subscriptions.

## 1. Configure Supabase

1. In Supabase, open **SQL Editor** and run `supabase/schema.sql`.
2. In **Project Settings → API**, copy the Project URL and the **publishable key** (or legacy `anon` key). Never use the `service_role` / secret key in browser code.
3. Copy `.env.example` to `.env` and set:

```env
VITE_SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co
VITE_SUPABASE_ANON_KEY=YOUR_PUBLIC_PUBLISHABLE_OR_ANON_KEY
```

4. In **Authentication → URL Configuration**, add your deployed site URL to Site URL / Redirect URLs. For local development, include `http://localhost:5173/**`.
5. In Authentication settings, decide whether to require email confirmation. If enabled, users need to confirm their email before logging in.

## 2. Run locally

Requires Node.js 20+.

```bash
npm install
npm run dev
```

Open the local URL Vite prints, usually `http://localhost:5173`.

## 3. Use together

1. Create an account and create a household.
2. Share the household invite code from the sidebar with your partner.
3. Your partner creates their own account and selects **Gå med** to enter the code.
4. Both can manage recipes, plans and the shopping list. Supabase Realtime broadcasts changes to connected clients.

## 4. Deploy

Deploy the project to Vercel or Netlify as a Vite app. Build command: `npm run build`; output directory: `dist`. Add the two `VITE_SUPABASE_*` environment variables in the hosting dashboard, then redeploy. Add the final site URL to Supabase Auth URL Configuration.

## Notes

- The browser app uses only the public publishable/anon key; Row Level Security policies protect records by household membership.
- The join flow uses the `join_household_by_code` RPC so invite-code lookups do not require exposing household rows to non-members.
- Ingredient quantities are stored as one line per ingredient. Shopping list entries are manually added; recipe-to-shopping-list aggregation can be added next.

## Färgtema

Sol/måne-knappen i headern växlar mellan ljust och mörkt läge. Den finns även på inloggnings- och installationssidorna. Valet sparas lokalt i webbläsaren med nyckeln `darkMode` och påverkar inte hushållets data eller din partners tema. Före första egna valet följer appen systemets färgtema, även när systemtemat ändras. Temat appliceras innan sidan ritas för att undvika en ljus blinkning. Om lokal lagring blockeras fungerar knappen fortfarande under besöket.

Mörkt läge omfattar veckoplanen, recept, inköpslistan, formulär, modaler, fritext och aktiva släppzoner. Tangentbordsfokus visas i båda teman.
