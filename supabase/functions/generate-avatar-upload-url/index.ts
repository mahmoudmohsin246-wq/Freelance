import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"
import { jwtVerify, createRemoteJWKSet } from "https://deno.land/x/jose@v4.14.4/index.ts"

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
    
    // التحقق من صحة توكن Firebase واستخراج الـ UID
    const { payload } = await jwtVerify(token, JWKS, {
      issuer: `https://securetoken.google.com/${FIREBASE_PROJECT_ID}`,
      audience: FIREBASE_PROJECT_ID,
    })

    const uid = payload.user_id || payload.sub
    if (!uid) throw new Error('Invalid Firebase UID')

    const filePath = `users/${uid}/avatar.jpg`

    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    const { data, error } = await supabaseAdmin.storage
      .from('avatars')
      .createSignedUploadUrl(filePath)

    if (error) throw error

    return new Response(
      JSON.stringify({ 
        signedUrl: data.signedUrl, 
        path: filePath, 
        baseUrl: Deno.env.get('SUPABASE_URL') 
      }),
      { headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' } }
    )
  } catch (err) {
    return new Response(
      JSON.stringify({ error: err.message }),
      { status: 400, headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' } }
    )
  }
})