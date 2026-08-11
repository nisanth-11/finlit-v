-- PLACEHOLDER SEED DATA
-- =====================
-- This is NOT your real lesson content. The original app's actual lessons
-- and questions only ever existed in your live Firestore database — they
-- were never checked into the gamifiedappforfinancialknowledge-main repo,
-- so there's nothing here to port from. The only real question data
-- findable anywhere in the repo is the 4 questions below, pulled from
-- backend/seed_questions.py (a maintenance script that assumed lesson_1
-- and lesson_2 already existed).
--
-- This file exists so the schema/app pipeline can be exercised end-to-end.
-- Replace it with your real lesson content before this goes anywhere near
-- real users — see the chat for how to export it from Firestore.

insert into public.lessons (id, title, description, content, module_number, section_name, coins_reward, order_index)
values
  ('11111111-1111-1111-1111-111111111111', 'Budgeting Basics', 'Learn to track income and expenses.', null, 1, 'Foundations', 10, 0),
  ('22222222-2222-2222-2222-222222222222', 'Saving Habits', 'Why and how to build savings.', null, 1, 'Foundations', 10, 1);

insert into public.questions (lesson_id, question, option_1, option_2, option_3, option_4, correct_option)
values
  ('11111111-1111-1111-1111-111111111111',
   'Which of these is a fixed expense in a monthly budget?',
   'Rent', 'Eating out occasionally', 'An impulse purchase', 'A festival gift', 1),
  ('11111111-1111-1111-1111-111111111111',
   'What should you do if your expenses are higher than your income?',
   'Ignore it and keep spending', 'Cut unnecessary expenses or increase income', 'Take a loan for daily expenses', 'Stop checking your budget', 2),
  ('22222222-2222-2222-2222-222222222222',
   'What is an emergency fund?',
   'Money saved for unexpected expenses', 'Money spent on entertainment', 'A type of loan', 'Money given to friends', 1),
  ('22222222-2222-2222-2222-222222222222',
   'Which habit helps you save money faster?',
   'Spending first, saving whatever is left', 'Saving a fixed amount first, then spending the rest', 'Borrowing money to save', 'Saving only once a year', 2);
