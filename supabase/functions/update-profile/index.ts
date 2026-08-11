import {
  corsHeaders,
  getAdminClient,
  jsonResponse,
  requireUser,
} from "../_shared/client.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const user = await requireUser(req);
  if (!user) return jsonResponse({ error: "Not authenticated" }, 401);

  const { name, language } = await req.json();

  const admin = getAdminClient();
  const { error } = await admin
    .from("profiles")
    .update({ name, language })
    .eq("id", user.id);

  if (error) return jsonResponse({ error: error.message }, 500);
  return jsonResponse({ message: "Profile updated" });
});
