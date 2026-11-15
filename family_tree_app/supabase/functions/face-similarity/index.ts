// Supabase Edge Function: face similarity between family members.
//
// Request (POST, signed-in user's JWT in Authorization header):
//   { "source": "<base64 jpeg>", "targets": [{ "id": "...", "image": "<base64>" }] }
// Response:
//   { "results": [{ "id": "...", "similarity": 0-100 }] }  or  { "error": "no_face" }
//
// Uses AWS Rekognition CompareFaces. Images are processed in memory and never
// stored. Required secrets (supabase secrets set ...):
//   AWS_REGION, AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY
//
// Note: Rekognition is tuned for identity matching, so scores between
// different (even related) people are naturally low; use them to rank
// resemblance, not as a probability. Any other provider can be swapped in by
// replacing compare() below.

import {
  CompareFacesCommand,
  DetectFacesCommand,
  RekognitionClient,
} from "npm:@aws-sdk/client-rekognition@3.637.0";
import { createClient } from "npm:@supabase/supabase-js@2.45.4";

const MAX_TARGETS = 60;
const MAX_IMAGE_BYTES = 5 * 1024 * 1024;

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...cors, "Content-Type": "application/json" },
  });

const rekognition = new RekognitionClient({
  region: Deno.env.get("AWS_REGION") ?? "eu-central-1",
});

function decode(b64: string): Uint8Array {
  const bin = atob(b64);
  const bytes = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) bytes[i] = bin.charCodeAt(i);
  if (bytes.length > MAX_IMAGE_BYTES) throw new Error("image_too_large");
  return bytes;
}

/** Highest similarity (0–100) between the source face and faces in target. */
async function compare(source: Uint8Array, target: Uint8Array): Promise<number | null> {
  const res = await rekognition.send(
    new CompareFacesCommand({
      SourceImage: { Bytes: source },
      TargetImage: { Bytes: target },
      SimilarityThreshold: 0,
    }),
  );
  const scores = (res.FaceMatches ?? []).map((m) => m.Similarity ?? 0);
  return scores.length ? Math.max(...scores) : null;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return json({ error: "method_not_allowed" }, 405);

  // Only signed-in users of this project may use the (paid) API.
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: req.headers.get("Authorization") ?? "" } } },
  );
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return json({ error: "unauthorized" }, 401);

  let body: { source?: string; targets?: { id: string; image: string }[] };
  try {
    body = await req.json();
  } catch {
    return json({ error: "bad_request" }, 400);
  }
  if (!body.source || !Array.isArray(body.targets)) {
    return json({ error: "bad_request" }, 400);
  }
  const targets = body.targets.slice(0, MAX_TARGETS);

  let source: Uint8Array;
  try {
    source = decode(body.source);
  } catch (e) {
    return json({ error: (e as Error).message }, 400);
  }

  // Make sure the source photo actually contains a face.
  const detected = await rekognition.send(
    new DetectFacesCommand({ Image: { Bytes: source } }),
  );
  if (!detected.FaceDetails?.length) return json({ error: "no_face" });

  const results: { id: string; similarity: number }[] = [];
  for (const t of targets) {
    try {
      const s = await compare(source, decode(t.image));
      if (s !== null) results.push({ id: t.id, similarity: Math.round(s * 10) / 10 });
    } catch {
      // The target has no detectable face (or is invalid): skip it.
    }
  }
  results.sort((a, b) => b.similarity - a.similarity);
  return json({ results });
});
