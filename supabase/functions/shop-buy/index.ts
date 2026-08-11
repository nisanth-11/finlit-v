import {
  corsHeaders,
  getAdminClient,
  jsonResponse,
  requireUser,
} from "../_shared/client.ts";
import { SHOP_COUNT_FIELDS, SHOP_PRICES } from "../_shared/shop.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const user = await requireUser(req);
  if (!user) return jsonResponse({ error: "Not authenticated" }, 401);

  const { item } = await req.json();
  const price = SHOP_PRICES[item];
  if (price === undefined) return jsonResponse({ error: "Invalid item" }, 400);

  const admin = getAdminClient();
  const countField = SHOP_COUNT_FIELDS[item];

  const { data: profile, error } = await admin
    .from("profiles")
    .select(`coins, ${countField}`)
    .eq("id", user.id)
    .single();

  if (error || !profile) return jsonResponse({ error: "User not found" }, 404);

  const coins = profile.coins as number;
  if (coins < price) return jsonResponse({ error: "Not enough coins" }, 400);

  const remainingCoins = coins - price;
  const currentCount = (profile as Record<string, number>)[countField] ?? 0;

  await admin
    .from("profiles")
    .update({ coins: remainingCoins, [countField]: currentCount + 1 })
    .eq("id", user.id);

  return jsonResponse({
    message: "Purchased",
    item,
    remaining_coins: remainingCoins,
  });
});
