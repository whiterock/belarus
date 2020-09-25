# belarus

Wir haben uns entschieden den Interpreter in Nim (https://github.com/nim-lang/Nim) zu schreiben, da @whiterock die Sprache für seine Hobbyprojekte verwendet und sie gut geeignet ist (außerdem machts halt irgendwie Spaß in Nim zu schreiben).

## how to compile

Zuerst den Nim compiler installieren: https://nim-lang.org/install.html

```bash
nim c ibelarus.nim
```

## how to run

```bash
./ibelarus
```

Daraufhin erscheint die REPL welche in register A gespeichert ist.

```none
Bienvenue!
Input:
```

Z.B.

```none
5 3 +
8.0
Input:
```

## registers

| Register  | Programm | Usage | Beispiel |
| ----------| -------- | ----- | -------- |
| A | REPL | Auszuführende Befehle eingeben und Enter drücken. Wenn das Programm ausgeführt wird kommt man immer sofort in die REPL. | `8 3 +` == 11.0 | 
| B | Fläche eines Dreiecks mit 3 (3D) Koordinaten | `x1 y1 z1 x2 y2 z2 x3 y3 z3 b@` | `1 1 5 4 1 5 4 5 5b@` == `6.0` |
| C | Fläche von n Dreiecken mir jeweils 3 (3D) Koordinaten | `x1 y1 z1 x2 y2 z2 x3 y3 z3`(n-times) + `n c@` | `1 1 5 4 1 5 4 5 5 1 1 5 4 1 5 4 5 5 2 c@` == 12.0 |
| D | Oberfläche eines Oktaeders auf zwei Arten (normale Formel vs. mittels C) | `d@` (interaktiv) | `d@` und dann Seitenlänge eingeben, e.g. 5 liefert 86.60 |
