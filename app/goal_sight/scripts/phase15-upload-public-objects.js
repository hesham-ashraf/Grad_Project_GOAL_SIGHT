const fs = require('fs');
const path = require('path');

const SUPABASE_URL = process.env.SUPABASE_URL;
const SERVICE_ROLE = process.env.SUPABASE_SERVICE_ROLE;

if (!SUPABASE_URL || !SERVICE_ROLE) {
  console.error('Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE');
  process.exit(1);
}

const items = [
  { bucket: 'team-logos', key: 'phase15/phase15-team-logo.txt', content: 'phase15 team logo placeholder' },
  { bucket: 'player-images', key: 'phase15/phase15-player-image.txt', content: 'phase15 player image placeholder' },
];

async function upload(item) {
  const url = `${SUPABASE_URL}/storage/v1/object/${item.bucket}/${item.key}`;
  const tmp = path.join(process.cwd(), `._phase15_${path.basename(item.key)}`);
  fs.writeFileSync(tmp, item.content, 'utf8');

  const formData = new FormData();
  formData.append('file', fs.createReadStream(tmp));

  const res = await fetch(url, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${SERVICE_ROLE}`,
      apikey: SERVICE_ROLE,
    },
    body: formData,
  });

  const text = await res.text();
  console.log(item.bucket, item.key, '->', res.status);
  if (!res.ok) console.error(text);
  fs.unlinkSync(tmp);
}

(async () => {
  for (const it of items) {
    try {
      await upload(it);
    } catch (err) {
      console.error('upload error', it, err && err.message);
    }
  }
})();
