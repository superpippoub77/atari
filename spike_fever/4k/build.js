// Compila sf4k.asm con dasm e scrive sf4k.bin (cartuccia da 4K).
// Uso:  npm install dasm   poi   python3 gen_data.py > data.inc && node build.js
const fs = require('fs'), path = require('path');
const dasm = require(process.env.DASM || 'dasm').default;
const dir = __dirname;
const src = fs.readFileSync(path.join(dir, 'sf4k.asm'), 'utf8');
const res = dasm(src, { format: 3, quick: true, machine: 'atari2600', includes: { 'data.inc': fs.readFileSync(path.join(dir, 'data.inc'), 'utf8') } });
if (!res.data || res.data.length !== 4096) {   // errore (o ROM oltre i 4K): mostra i messaggi di dasm
  console.error((res.output || []).join('\n')); process.exit(1);
}
fs.writeFileSync(path.join(dir, 'sf4k.bin'), Buffer.from(res.data));
console.log('OK: sf4k.bin, 4096 byte');
