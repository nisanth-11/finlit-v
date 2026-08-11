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

  const { lesson_id, answers, is_replay } = await req.json();
  if (!lesson_id || !Array.isArray(answers)) {
    return jsonResponse({ error: "lesson_id and answers are required" }, 400);
  }

  const admin = getAdminClient();

  const { data: questions, error: questionsError } = await admin
    .from("questions")
    .select("correct_option")
    .eq("lesson_id", lesson_id);

  if (questionsError) return jsonResponse({ error: questionsError.message }, 500);
  if (!questions || questions.length === 0) {
    return jsonResponse({ error: "Lesson not found" }, 404);
  }
  if (answers.length !== questions.length) {
    return jsonResponse({ error: "Answer count mismatch" }, 400);
  }

  let score = 0;
  for (let i = 0; i < questions.length; i++) {
    // Frontend sends 0-based indices; correct_option in the DB is 1-based.
    if (answers[i] === questions[i].correct_option - 1) score += 1;
  }

  const total = questions.length;
  const percentage = Math.floor((score / total) * 100);

  const { data: lesson } = await admin
    .from("lessons")
    .select("coins_reward")
    .eq("id", lesson_id)
    .maybeSingle();
  const coinsReward = lesson?.coins_reward ?? 10;

  let coinsEarned: number;
  if (is_replay) {
    // Golden replay: lesson was already completed with a perfect score,
    // so award a reduced reward (50% for perfect, 35% for one wrong).
    if (score === total) coinsEarned = Math.floor(coinsReward * 0.5);
    else if (score === total - 1) coinsEarned = Math.floor(coinsReward * 0.35);
    else coinsEarned = 0;
  } else {
    if (score === total) coinsEarned = coinsReward;
    else if (score === total - 1) coinsEarned = Math.floor(coinsReward * 0.7);
    else coinsEarned = 0;
  }

  const completedAt = new Date().toISOString();

  const { error: insertError } = await admin.from("quiz_results").insert({
    user_id: user.id,
    lesson_id,
    score: percentage,
    completed_at: completedAt,
  });
  if (insertError) return jsonResponse({ error: insertError.message }, 500);

  const actualCoins = await updateStreakAndCoins(admin, user.id, coinsEarned);

  return jsonResponse({
    result: { lesson_id, score: percentage, completed_at: completedAt },
    coins_earned: actualCoins,
  });
});
