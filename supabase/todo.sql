CREATE TABLE todo_tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users NOT NULL,
    title TEXT NOT NULL,
    amount DECIMAL(15,2) NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('deposit', 'withdrawal')),
    category_id UUID REFERENCES categories(id),
    due_date TIMESTAMPTZ NOT NULL,
    recurrence TEXT NOT NULL DEFAULT 'none'
      CHECK (recurrence IN ('none', 'weekly', 'monthly')),
    is_completed BOOLEAN NOT NULL DEFAULT false,
    completed_at TIMESTAMPTZ,
    transaction_id UUID REFERENCES transactions(id),
    created_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE todo_tasks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own todos" ON todo_tasks
    FOR ALL USING (auth.uid() = user_id);