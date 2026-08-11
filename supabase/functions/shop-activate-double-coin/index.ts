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

  const admin = getAdminClient();
  const { data: profile, error } = await admin
    .from("profiles")
    .select("double_coin_count")
    .eq("id", user.id)
    .single();

  if (error || !profile) return jsonResponse({ error: "User not found" }, 404);
  if ((profile.double_coin_count as number) <= 0) {
    return jsonResponse({ error: "No double coin available" }, 400);
  }

  const activeUntil = new Date(Date.now() + 7 * 86_400_000).toISOString();

  await admin
    .from("profiles")
    .update({
      double_coin_active_until: activeUntil,
      double_coin_count: (profile.double_coin_count as number) - 1,
    })
    .eq("id", user.id);

  return jsonResponse({ active_until: activeUntil });
});
