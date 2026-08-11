import {
  corsHeaders,
  getAdminClient,
  jsonResponse,
  requireUser,
} from "../_shared/client.ts";

// Called right after the client signs in anonymously. Creates the profile
// row on first run (keyed to the anonymous auth user id) or returns the
// existing one. Note: because this is tied to an anonymous auth session,
// re-entering the same phone number on a different device/reinstall does
// NOT recover the old account — it's a new anonymous identity. Real
// cross-device login would need Supabase's verified phone/OTP auth instead.
Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const user = await requireUser(req);
  if (!user) return jsonResponse({ error: "Not authenticated" }, 401);

  const { phone } = await req.json();
  if (!phone || typeof phone !== "string") {
    return jsonResponse({ error: "phone is required" }, 400);
  }

  const admin = getAdminClient();

  const { data: existing } = await admin
    .from("profiles")
    .select("*")
    .eq("id", user.id)
    .maybeSingle();

  if (existing) {
    return jsonResponse({ user_id: user.id, user: existing });
  }

  const { data: created, error } = await admin
    .from("profiles")
    .insert({ id: user.id, phone })
    .select()
    .single();

  if (error) {
    if (error.code === "23505") {
      return jsonResponse(
        { error: "This phone number is already registered on another device." },
        400,
      );
    }
    return jsonResponse({ error: error.message }, 500);
  }

  return jsonResponse({ user_id: user.id, user: created });
});
