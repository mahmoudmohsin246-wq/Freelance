import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"
import { jwtVerify, createRemoteJWKSet } from "https://deno.land/x/jose@v4.14.4/index.ts"

// Verifies a Firebase ID token (same approach already used by
// generate-avatar-upload-url) and, once verified, upserts one or more
// academy names into the public `academy_names` table using the Supabase
// service role — the client never gets write access itself.
//
// Body: { "names": ["Academy A", "Academy B", ...] }
// Used two ways:
//   1) Right after a manager registers: names = [that one academyName].
//   2) One-time backfill: names = every existing academyName.

const JWKS = createRemoteJWKSet(
  new URL("https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com")
)

const FIREBASE_PROJECT_ID = "sports-academy-app-cb958"

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', {
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'authorization, content-type'
      }
    })
  }

  try {
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) throw new Error('Missing Authorization header')

    const token = authHeader.replace('Bearer ', '')

    // Verify the Firebase ID token is genuine — this just proves the
    // caller is a real signed-in user of the app, so anonymous scripts
    // can't spam fake academy names into the public list.
    await jwtVerify(token, JWKS, {
      issuer: `https://securetoken.google.com/${FIREBASE_PROJECT_ID}`,
      audience: FIREBASE_PROJECT_ID,
    })

    const { names } = await req.json()
    if (!Array.isArray(names) || names.length === 0) {
      throw new Error('Body must include a non-empty "names" array')
    }

    const rows = Array.from(
      new Set(
        names
          .map((n: unknown) => (typeof n === 'string' ? n.trim() : ''))
          .filter((n: string) => n.length > 0)
      )
    ).map((name) => ({ name }))

    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    const { error } = await supabaseAdmin
      .from('academy_names')
      .upsert(rows, { onConflict: 'name', ignoreDuplicates: true })

    if (error) throw error

    return new Response(
      JSON.stringify({ synced: rows.length }),
      { headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' } }
    )
  } catch (err) {
    return new Response(
      JSON.stringify({ error: err.message }),
      { status: 400, headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' } }
    )
  }
})
