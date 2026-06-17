-- ============================================================
-- 037 — Notifications: admin receives club-scoped notifications
-- ============================================================
-- Emits a notification to the club's admin whenever:
--   • A manager's upload job transitions to 'completed' or 'failed'.
-- (Additional triggers for risk thresholds and manager onboarding
--  can be added here later without touching Flutter code.)
-- ============================================================

-- 1. Notification type enum (extend as new trigger types are added)
DO $$ BEGIN
  CREATE TYPE public.notification_type AS ENUM (
    'upload_complete',
    'upload_failed',
    'high_risk_player',
    'manager_added'
  );
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

-- 2. Notifications table
CREATE TABLE IF NOT EXISTS public.notifications (
  id            uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  recipient_id  uuid        NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  club_id       uuid        REFERENCES public.teams (id) ON DELETE CASCADE,
  type          public.notification_type NOT NULL,
  title         text        NOT NULL,
  body          text        NOT NULL,
  related_id    text,           -- flexible FK (upload_job id, player id, …)
  is_read       boolean     NOT NULL DEFAULT false,
  created_at    timestamptz NOT NULL DEFAULT now()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_notifications_recipient
  ON public.notifications (recipient_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_notifications_unread
  ON public.notifications (recipient_id, is_read)
  WHERE NOT is_read;

-- 3. RLS
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "notifications_own_select" ON public.notifications;
CREATE POLICY "notifications_own_select" ON public.notifications
  FOR SELECT USING (recipient_id = auth.uid());

DROP POLICY IF EXISTS "notifications_own_update" ON public.notifications;
CREATE POLICY "notifications_own_update" ON public.notifications
  FOR UPDATE USING (recipient_id = auth.uid());

-- Triggers (SECURITY DEFINER functions) can insert on behalf of any user
DROP POLICY IF EXISTS "notifications_insert_trigger" ON public.notifications;
CREATE POLICY "notifications_insert_trigger" ON public.notifications
  FOR INSERT WITH CHECK (true);

-- 4. Trigger function: notify admin on upload-job status change
CREATE OR REPLACE FUNCTION public.notify_admin_on_upload_status()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_club_id   uuid;
  v_admin_id  uuid;
  v_type      public.notification_type;
  v_title     text;
  v_body      text;
BEGIN
  -- Guard: only act on status transitions to terminal states
  IF NEW.status = OLD.status THEN
    RETURN NEW;
  END IF;
  IF NEW.status NOT IN ('completed', 'failed') THEN
    RETURN NEW;
  END IF;

  -- Resolve the uploader's club
  SELECT p.club_id INTO v_club_id
  FROM public.profiles p
  WHERE p.id = NEW.manager_id;

  IF v_club_id IS NULL THEN
    RETURN NEW;
  END IF;

  -- Resolve the club's admin
  SELECT p.id INTO v_admin_id
  FROM public.profiles p
  WHERE p.role = 'admin' AND p.club_id = v_club_id
  LIMIT 1;

  IF v_admin_id IS NULL THEN
    RETURN NEW;
  END IF;

  -- Build notification payload
  IF NEW.status = 'completed' THEN
    v_type  := 'upload_complete';
    v_title := 'Analysis complete';
    v_body  := format(
      '%s vs %s analysis is ready to review.',
      COALESCE(NEW.home_team, 'Home'),
      COALESCE(NEW.away_team, 'Away')
    );
  ELSE
    v_type  := 'upload_failed';
    v_title := 'Upload failed';
    v_body  := format(
      '%s vs %s upload failed.%s',
      COALESCE(NEW.home_team, 'Home'),
      COALESCE(NEW.away_team, 'Away'),
      CASE WHEN NEW.error_message IS NOT NULL
           THEN ' ' || NEW.error_message
           ELSE ''
      END
    );
  END IF;

  INSERT INTO public.notifications
    (recipient_id, club_id, type, title, body, related_id)
  VALUES
    (v_admin_id, v_club_id, v_type, v_title, v_body, NEW.id::text);

  RETURN NEW;
END;
$$;

-- Attach trigger to upload_jobs
DROP TRIGGER IF EXISTS trg_notify_admin_upload_status ON public.upload_jobs;
CREATE TRIGGER trg_notify_admin_upload_status
  AFTER UPDATE OF status ON public.upload_jobs
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_admin_on_upload_status();

-- 5. Enable realtime (admin subscribes to their notification stream)
ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;
