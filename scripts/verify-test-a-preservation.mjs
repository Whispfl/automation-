import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { readFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const manifest = JSON.parse(await readFile(path.join(root, 'docs/PHASE4-TEST-A-PRESERVATION.json'), 'utf8'));
for(const check of manifest.checks){
 let text = await readFile(path.join(root,check.file));
 if(check.method){
  text=text.toString('utf8');
  const start=text.indexOf('function GameKnowledge:'+check.method+'(');
  assert(start>=0,'Missing frozen physical method: '+check.method);
  const end=text.indexOf('\nfunction ',start+1);
  text=text.slice(start,end<0 ? text.length : end);
 }
 assert.equal(createHash('sha256').update(text).digest('hex'),check.sha256,'Owner-approved travel changed: '+check.file+(check.method ? ':'+check.method : ''));
}
console.log('[OC] Test A preservation PASS: '+manifest.checks.length+' frozen file/method hashes match '+manifest.baseline);
