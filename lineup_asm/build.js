// Compila LineUp.asm con dasm e scrive LineUp.bin (cartuccia 4K Atari 2600)
const fs = require("fs");
const path = require("path");
const dasm = require("dasm").default;

const dir = __dirname;
const src = fs.readFileSync(path.join(dir, "LineUp.asm"), "utf8");
const res = dasm(src, {
  format: 3,
  quick: true,
  machine: "atari2600",
});

if (!res.data || res.data.length !== 4096) {
  console.error((res.output || []).join("\n"));
  process.exit(1);
}

fs.writeFileSync(path.join(dir, "LineUp.bin"), Buffer.from(res.data));
console.log("OK: LineUp.bin, 4096 byte");
