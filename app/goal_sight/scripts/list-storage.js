const u = process.env.SUPABASE_URL;
const s = process.env.SUPABASE_SERVICE_ROLE;
if (!u || !s) {
  console.error('Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE');
  process.exit(1);
}

async function list(bucket) {
  const res = await fetch(`${u}/storage/v1/object/list/${bucket}`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${s}`, apikey: s, 'Content-Type': 'application/json' },
    body: JSON.stringify({ prefix: '', limit: 100 })
  });
  const j = await res.json().catch(() => null);
  console.log('\nBUCKET', bucket, 'STATUS', res.status);
  console.log(JSON.stringify(j, null, 2));
}

(async () => {
  await list('team-logos');
  await list('player-images');
})();
