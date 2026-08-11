import type { SupabaseClient } from "jsr:@supabase/supabase-js@2";

// Mirrors the original backend's _update_streak_and_coins: advances the
// daily streak, applies streak-freeze / double-coin power-ups, and credits
// coins. Returns the (possibly doubled) coins actually credited.
export async function updateStreakAndCoins(
  admin: SupabaseClient,
  userId: string,
  coinsEarned: number,
): Promise<number> {
  const { data: profile } = await admin
    .from("profiles")
    .select(
      "streak_count, coins, last_active_date, streak_freeze_count, double_coin_active_until",
    )
    .eq("id", userId)
    .single();

  if (!profile) return 0;

  let streak = profile.streak_count as number;
  const coins = profile.coins as number;
  const lastActive = profile.last_active_date as string | null;
  const streakFreezeCount = profile.streak_freeze_count as number;
  const doubleCoinActiveUntil = profile.double_coin_active_until as
    | string
    | null;

  const now = new Date();
  const todayStr = now.toISOString().slice(0, 10);

  const updates: Record<string, unknown> = {};

  if (doubleCoinActiveUntil && new Date(doubleCoinActiveUntil) > now) {
    coinsEarned *= 2;
  }

  if (lastActive === todayStr) {
    // Already active today — just add coins.
  } else if (lastActive) {
    const todayMidnight = new Date(`${todayStr}T00:00:00Z`).getTime();
    const lastMidnight = new Date(`${lastActive}T00:00:00Z`).getTime();
    const deltaDays = Math.round((todayMidnight - lastMidnight) / 86_400_000);

    if (deltaDays === 1) {
      streak += 1;
    } else if (streakFreezeCount > 0) {
      updates.streak_freeze_count = streakFreezeCount - 1;
    } else {
      streak = 1;
    }
  } else {
    streak = 1;
  }

  updates.streak_count = streak;
  updates.coins = coins + coinsEarned;
  updates.last_active_date = todayStr;

  await admin.from("profiles").update(updates).eq("id", userId);
  return coinsEarned;
}
