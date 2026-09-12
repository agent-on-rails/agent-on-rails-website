import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';

const APPCAST_PATH = fileURLToPath(new URL('../../public/downloads/appcast.xml', import.meta.url));

export type SetupRelease = {
  version: string;
  released: string;
  isoDate: string;
};

export function setupRelease(): SetupRelease {
  const xml = readFileSync(APPCAST_PATH, 'utf8');
  const item = xml.match(/<item>[\s\S]*?<\/item>/)?.[0] ?? '';
  const version = item.match(/<sparkle:version>([^<]+)<\/sparkle:version>/)?.[1]?.trim() ?? '';
  const pubDate = item.match(/<pubDate>([^<]+)<\/pubDate>/)?.[1]?.trim() ?? '';
  const parsed = new Date(pubDate);
  const valid = !Number.isNaN(parsed.getTime());
  const isoDate = valid ? parsed.toISOString().slice(0, 10) : '';
  const released = valid
    ? new Intl.DateTimeFormat('en-AU', {
        day: 'numeric',
        month: 'long',
        year: 'numeric',
        timeZone: 'Australia/Sydney',
      }).format(parsed)
    : '';
  return { version, released, isoDate };
}
