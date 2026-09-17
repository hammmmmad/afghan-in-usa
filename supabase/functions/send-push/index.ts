// Deploy with: supabase functions deploy send-push
// Set FCM_SERVICE_ACCOUNT_JSON only as a Supabase Edge Function secret.
// The Flutter client never receives it.
import { createClient } from 'npm:@supabase/supabase-js@2';
import { GoogleAuth } from 'npm:google-auth-library@9';

const url = Deno.env.get('SUPABASE_URL')!;
const serviceRole = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
// Platform-injected SERVICE_ROLE may be the legacy JWT while the secrets
// panel exposes the new sb_secret key; trust either server-side form.
const legacyServiceRole = Deno.env.get('SEND_PUSH_LEGACY_KEY') ?? '';
const fcmServiceAccount = JSON.parse(Deno.env.get('FCM_SERVICE_ACCOUNT_JSON')!);
const admin = createClient(url, serviceRole, { auth: { persistSession: false } });

Deno.serve(async (request) => {
  const token = request.headers.get('authorization')?.replace('Bearer ', '');
  if (!token) return Response.json({ error: 'Unauthorized' }, { status: 401 });
  const input = await request.json();
  // Database triggers (pg_net) call this function with a service-role key.
  // Those calls originate server-side, so the admin lookup only applies to
  // user-facing callers (the admin web/app panel).
  if (token !== serviceRole && token !== legacyServiceRole) {
    const caller = await admin.auth.getUser(token);
    if (caller.error || !caller.data.user) {
      return Response.json({ error: 'Unauthorized' }, { status: 401 });
    }
    const { data: role } = await admin
      .from('admin_users').select('user_id').eq('user_id', caller.data.user.id).maybeSingle();
    if (!role) return Response.json({ error: 'Forbidden' }, { status: 403 });
  }

  const table = input.kind === 'special' ? 'special_notifications' : 'public_notifications';
  const { data: notice, error } = await admin.from(table).select('*').eq('id', input.notificationId).single();
  if (error || !notice) return Response.json({ error: 'Notification not found' }, { status: 404 });
  if (table === 'public_notifications' && notice.status !== 'published') {
    return Response.json({ error: 'Notification is not published' }, { status: 400 });
  }

  let tokens: string[] = [];
  if (table === 'special_notifications') {
    const { data: subscription } = await admin.from('case_subscriptions')
      .select('case_id').eq('user_id', notice.recipient_user_id)
      .eq('case_id', notice.case_id).eq('active', true).maybeSingle();
    if (subscription) {
      const { data: devices } = await admin.from('device_tokens')
        .select('fcm_token').eq('user_id', notice.recipient_user_id).eq('active', true);
      tokens = (devices ?? []).map((row) => row.fcm_token);
    }
  }

  const auth = new GoogleAuth({
    credentials: fcmServiceAccount,
    scopes: ['https://www.googleapis.com/auth/firebase.messaging'],
  });
  const accessToken = await auth.getAccessToken();
  const projectId = fcmServiceAccount.project_id;
  const messageBase = {
    notification: { title: notice.title_i18n.en || notice.title_i18n.fa, body: notice.body_i18n.en || notice.body_i18n.fa },
    data: { notificationId: notice.id, kind: input.kind === 'special' ? 'special' : 'public', caseId: notice.case_id ?? '' },
  };
  const targets = table === 'public_notifications'
    ? [{ topic: 'public-news' }]
    : tokens.map((fcm_token) => ({ token: fcm_token }));
  const responses = await Promise.all(targets.map(async (target) => {
    const result = await fetch(`https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`, {
      method: 'POST',
      headers: { authorization: `Bearer ${accessToken}`, 'content-type': 'application/json' },
      body: JSON.stringify({ message: { ...messageBase, ...target, android: { priority: 'high' } } }),
    });
    let detail = '';
    if (!result.ok) {
      try { detail = (await result.text()).slice(0, 300); } catch (_) {}
      // Self-healing: a token FCM reports as unregistered can never receive
      // anything again — deactivate it so future sends skip it.
      if (detail.includes('UNREGISTERED') || detail.includes('NotRegistered')) {
        const deadToken = (target as { token?: string }).token;
        if (deadToken) {
          await admin.from('device_tokens')
            .update({ active: false })
            .eq('fcm_token', deadToken);
        }
      }
    }
    return { ok: result.ok, status: result.status, detail, token: (target as { token?: string }).token?.slice(0, 12) };
  }));
  return Response.json({
    sent: responses.filter((item) => item.ok).length,
    total: responses.length,
    errors: responses.filter((item) => !item.ok).map((item) => item.detail),
  });
});
