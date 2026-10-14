# App-level secret encryption (AES-256-GCM)

For third-party secrets stored in SQLite (e.g. provider Admin API keys), encrypt
before write and decrypt only server-side. A DB/file leak then yields ciphertext,
not usable keys. The encryption key is `APP_ENCRYPTION_KEY` (32 bytes, base64),
held in `/etc/<app>/env` — never in the repo, never in the DB, never logged.

```ts
// app/lib/crypto.ts  — server-only
import "server-only"
import { createCipheriv, createDecipheriv, randomBytes } from "node:crypto"

const KEY = Buffer.from(process.env.APP_ENCRYPTION_KEY!, "base64") // 32 bytes
if (KEY.length !== 32) throw new Error("APP_ENCRYPTION_KEY must be 32 bytes (base64)")

// Store as: iv(12) . authTag(16) . ciphertext, base64. Self-describing, versionable.
export function encryptSecret(plaintext: string): string {
  const iv = randomBytes(12)
  const cipher = createCipheriv("aes-256-gcm", KEY, iv)
  const ct = Buffer.concat([cipher.update(plaintext, "utf8"), cipher.final()])
  return Buffer.concat([iv, cipher.getAuthTag(), ct]).toString("base64")
}

export function decryptSecret(blob: string): string {
  const buf = Buffer.from(blob, "base64")
  const iv = buf.subarray(0, 12)
  const tag = buf.subarray(12, 28)
  const ct = buf.subarray(28)
  const decipher = createDecipheriv("aes-256-gcm", KEY, iv)
  decipher.setAuthTag(tag)
  return Buffer.concat([decipher.update(ct), decipher.final()]).toString("utf8")
}
```

Rules:
- Generate the key once: `openssl rand -base64 32`. Losing it = losing all stored
  secrets; back it up out-of-band (password manager), not in the repo.
- Rotation: add a key-id prefix to the stored blob so you can decrypt-old /
  encrypt-new during a rotation window.
- Never return decrypted secrets to the client. Surface only a masked form
  (e.g. last 4 chars) for display.
