// Compila spikefever2600.asm con dasm e scrive spikefever2600.bin (cartuccia da 16K, bank switching F6).
// Uso:  npm install dasm   poi   python3 gen_data.py && node build.js
const fs = require('fs'), path = require('path');
const dasm = require(process.env.DASM || 'dasm').default;
const dir = __dirname, rd = f => fs.readFileSync(path.join(dir, f), 'utf8');
const res = dasm(rd('spikefever2600.asm'), { format: 3, quick: !process.env.SYM, machine: 'atari2600',
  includes: { 'bank0.inc': rd('bank0.inc'), 'bank1.inc': rd('bank1.inc'), 'bank2.inc': rd('bank2.inc') } });
if (!res.data || res.data.length !== 16384) { console.error((res.output || []).join('\n')); process.exit(1); }
fs.writeFileSync(path.join(dir, 'spikefever2600.bin'), Buffer.from(res.data));
if (process.env.SYM) fs.writeFileSync(process.env.SYM, res.symbolsRaw || '');
console.log('OK: spikefever2600.bin, 16384 byte');
