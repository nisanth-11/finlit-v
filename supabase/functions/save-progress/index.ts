import {
  corsHeaders,
  getAdminClient,
  jsonResponse,
  requireUser,
} from "../_shared/client.ts";
import { updateStreakAndCoins } from "../_shared/streak.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const user = await requireUser(req);
  if (!user) return jsonResponse({ error: "Not authenticated" }, 401);

  const { lesson_id, is_completed } = await req.json();
  if (!lesson_id) return jsonResponse({ error: "lesson_id is required" }, 400);

  const admin = getAdminClient();

  const { error } = await admin.from("progress").upsert({
    user_id: user.id,
    lesson_id,
    is_completed: Boolean(is_completed),
    completed_at: new Date().toISOString(),
  });

  if (error) return jsonResponse({ error: error.message }, 500);

  // Coins are only awarded through submit-quiz; saving progress never
  // grants a completion bonus on its own (matches the original backend).
  const bonusCoins = await updateStreakAndCoins(admin, user.id, 0);

  return jsonResponse({
    progress: { user_id: user.id, lesson_id, is_completed },
    bonus_coins_earned: bonusCoins,
  });
});
