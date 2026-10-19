// Compila sf8k.asm con dasm e scrive sf8k.bin (cartuccia da 8K, bankswitching F8).
// Uso:  npm install dasm   poi   python3 gen_data.py && node build.js
// (gen_data.py scrive data.inc e title.inc; il titolo e la logica della partita sono nel banco 0)
const fs = require('fs'), path = require('path');
const dasm = require(process.env.DASM || 'dasm').default;
const dir = __dirname;
const read = f => fs.readFileSync(path.join(dir, f), 'utf8');
const includes = {};
for (const f of ['data.inc', 'title.inc', 'bank0.asm', 'logic.asm']) includes[f] = read(f);
const res = dasm(read('sf8k.asm'), { format: 3, quick: true, machine: 'atari2600', includes });
if (!res.data || res.data.length !== 8192) {   // errore (o ROM oltre gli 8K): mostra i messaggi di dasm
  console.error((res.output || []).join('\n')); process.exit(1);
}
fs.writeFileSync(path.join(dir, 'sf8k.bin'), Buffer.from(res.data));
console.log('OK: sf8k.bin, 8192 byte');
