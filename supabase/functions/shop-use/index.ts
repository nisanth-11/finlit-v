import {
  corsHeaders,
  getAdminClient,
  jsonResponse,
  requireUser,
} from "../_shared/client.ts";
import { SHOP_COUNT_FIELDS } from "../_shared/shop.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const user = await requireUser(req);
  if (!user) return jsonResponse({ error: "Not authenticated" }, 401);

  const { item } = await req.json();
  const countField = SHOP_COUNT_FIELDS[item];
  if (!countField) return jsonResponse({ error: "Invalid item" }, 400);

  const admin = getAdminClient();
  const { data: profile, error } = await admin
    .from("profiles")
    .select(countField)
    .eq("id", user.id)
    .single();

  if (error || !profile) return jsonResponse({ error: "User not found" }, 404);

  const count = (profile as Record<string, number>)[countField] ?? 0;
  if (count <= 0) return jsonResponse({ error: "None available" }, 400);

  await admin
    .from("profiles")
    .update({ [countField]: count - 1 })
    .eq("id", user.id);

  return jsonResponse({ message: "Used", item, remaining: count - 1 });
});
