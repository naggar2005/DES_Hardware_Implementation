# Hardware Implementation of DES (Data Encryption Standard)

An iterative hardware implementation of the Data Encryption Standard (DES / FIPS 46-3) written in SystemVerilog, supporting both Encryption and Decryption modes.

---

## 📁 Project Directory Structure

```text
E:\DES_Hardware_Implementation\
├── docs/                      # Architectural specs and schematics
│   └── diagram.drawio         # Draw.io block diagram & timing structure
├── rtl/                       # Synthesizable RTL source files ONLY
│   ├── des_pkg.sv             # Lookup tables (IP, FP, PC-1, PC-2, E, P, S-Boxes)
│   ├── controller.sv          # 5-state FSM controller (IDLE, LOAD, ROUND, FINAL, DONE)
│   ├── data_path.sv           # Datapath handling IP, round registers, and FP swap
│   ├── key_schedule.sv        # Parallel 16-round subkey generator (768 bits)
│   ├── f_round.sv             # Feistel round function logic
│   └── des_top.sv             # Top-level module interconnecting controller & datapath
├── tb/                        # Testbenches & verification infrastructure
│   ├── tb_controller.sv       # FSM controller unit testbench
│   ├── tb_data_path.sv        # Datapath unit testbench
│   ├── tb_des_key_schedule.sv # Key schedule NIST subkey verification
│   ├── tb_f_round.sv          # Single Feistel round unit testbench
│   ├── tb_des_top.sv          # Top-level testbench with File I/O verification
│   └── vectors/               # Test vector files
│       ├── plaintext.txt      # 64-bit plaintext blocks (hex per line)
│       ├── key.txt            # 64-bit keys (hex per line)
│       └── expected_output.txt# NIST expected ciphertexts (hex per line)
├── sim/                       # Simulation scripts & Questa workspace
│   ├── run_tb_top.do          # QuestaSim script for tb_des_top with waveforms
│   ├── run_all.do             # Batch regression script running all 5 testbenches
│   └── questa/                # QuestaSim project directory & work library
└── README.md                  # Project documentation & usage guide
```

---

## ⚡ Specifications & Architecture

- **Standard**: NIST FIPS 46-3 (DES 64-bit block, 56-bit effective key).
- **Architecture**: 16-round iterative Feistel architecture.
- **Latency**: 19 clock cycles per 64-bit block:
  - `1 cycle`  : `LOAD` (Initial Permutation `IP` and input register sampling)
  - `16 cycles`: `ROUND` (1 cycle per Feistel round with round key multiplexing)
  - `1 cycle`  : `FINAL` (32-bit left/right swap and Final Permutation `FP`)
  - `1 cycle`  : `DONE` (Result valid on `data_out`)
- **Modes**:
  - `mode = 0`: Encryption ($K_0 \rightarrow K_{15}$)
  - `mode = 1`: Decryption ($K_{15} \rightarrow K_0$)

---

## 🚀 Running Simulations

### Option 1: Top-Level Testbench with Waveforms (`tb_des_top`)
1. Open QuestaSim / ModelSim.
2. In the transcript console:
   ```tcl
   cd E:/DES_Hardware_Implementation/sim
   do run_tb_top.do
   ```
3. The testbench automatically:
   - Reads `tb/vectors/plaintext.txt` and `tb/vectors/key.txt`.
   - Executes hardware encryption and writes results to `sim/output.txt`.
   - Verifies against `tb/vectors/expected_output.txt`.
   - Feeds ciphertexts back with `mode = 1` (decryption) and verifies full reversibility against original plaintexts, writing recovered plaintexts to `sim/decrypted_output.txt`.

### Option 2: Run All Testbenches (Regression)
In the Questa transcript console:
```tcl
cd E:/DES_Hardware_Implementation/sim
do run_all.do
```
This automatically compiles and executes all 5 testbenches:
1. `tb_f_round`
2. `tb_des_key_schedule`
3. `tb_controller`
4. `tb_data_path`
5. `tb_des_top`
