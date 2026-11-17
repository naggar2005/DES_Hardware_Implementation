# Hardware Implementation of DES (Data Encryption Standard)

An iterative hardware realization of the **Data Encryption Standard (DES / FIPS 46-3)** cipher built in **SystemVerilog**, featuring dual-mode support for symmetric encryption and decryption.

---

## 📌 Project Overview

This repository contains a modular, synthesizable register-transfer-level (RTL) implementation of the classic 16-round Data Encryption Standard. It incorporates:
- **Iterative Datapath**: Utilizes a single combinational Feistel round instance iterated across 16 clock cycles to balance throughput and FPGA resource utilization.
- **Full Parallel Key Schedule**: Evaluates all 16 round subkeys (48 bits each) combinationally from a 64-bit input key via Permuted Choice 1 (PC-1), round-specific bit rotations, and Permuted Choice 2 (PC-2).
- **Dual-Mode Controller**: Supports both Encryption (`mode = 0`) and Decryption (`mode = 1`) by reversing the subkey multiplexer ordering ($K_0 \rightarrow K_{15}$ vs. $K_{15} \rightarrow K_0$).
- **File I/O Top Verification**: Automated top-level testbench (`tb_des_top`) capable of reading plaintext and key files, logging hardware ciphertexts, validating against expected vectors, and performing complete decryption reversibility checks.

---

## 📁 Repository Organization

```text
DES_Hardware_Implementation/
├── docs/                      # Schematics and architecture drawings
│   └── diagram.drawio         # Draw.io block diagram & timing structure
├── rtl/                       # Synthesizable RTL modules
│   ├── des_pkg.sv             # Permutations (IP, FP, PC1, PC2, E, P) and S-Boxes
│   ├── controller.sv          # 5-state control FSM (IDLE, LOAD, ROUND, FINAL, DONE)
│   ├── data_path.sv           # Feistel round register, IP, FP swap, and key mux
│   ├── key_schedule.sv        # Parallel 16-round subkey generator (768 bits)
│   ├── f_round.sv             # Combinational Feistel round computation
│   └── des_top.sv             # Top-level module interconnecting datapath & controller
├── tb/                        # Testbenches & verification suite
│   ├── tb_controller.sv       # FSM controller unit testbench
│   ├── tb_data_path.sv        # Datapath unit testbench
│   ├── tb_des_key_schedule.sv # Key schedule NIST subkey verification
│   ├── tb_f_round.sv          # Feistel function unit testbench
│   ├── tb_des_top.sv          # Top-level testbench with File I/O verification
│   └── vectors/               # Hexadecimal test vector files
│       ├── plaintext.txt      # 64-bit plaintext blocks (one per line)
│       ├── key.txt            # 64-bit keys (one per line)
│       └── expected_output.txt# NIST expected ciphertexts (one per line)
├── sim/                       # Simulation workspace & scripts
│   ├── run_tb_top.do          # QuestaSim script for tb_des_top with waveforms
│   ├── run_all.do             # Batch regression script running all 5 testbenches
│   └── questa/                # QuestaSim project configuration
├── LICENSE                    # Open-source license terms
└── README.md                  # Project documentation
```

---

## 🔌 Top-Level Interface (`des_top`)

| Port Name | Direction | Width | Type | Description |
| :--- | :---: | :---: | :---: | :--- |
| `clk` | Input | 1 | logic | Master system clock |
| `arstn` | Input | 1 | logic | Asynchronous active-low reset |
| `start` | Input | 1 | logic | Single-cycle start strobe initiating cipher processing |
| `mode` | Input | 1 | logic | Operation mode: `0` = Encrypt, `1` = Decrypt |
| `key` | Input | 64 | logic | 64-bit cryptographic key (56 key bits + 8 parity bits) |
| `data_in` | Input | 64 | logic | 64-bit input data block (Plaintext or Ciphertext) |
| `data_out` | Output | 64 | logic | 64-bit resulting data block |
| `busy` | Output | 1 | logic | Status indicator: asserted during active processing |
| `done` | Output | 1 | logic | Status indicator: asserted for 1 cycle when `data_out` is valid |

---

## ⏱️ Timing & Controller FSM

The controller cycles through 5 distinct states:
1. **`IDLE`**: Awaiting the `start` pulse. `busy = 0`, `done = 0`.
2. **`LOAD`** *(1 cycle)*: Asserts `load` signal. Datapath samples `data_in`, applies the Initial Permutation ($\text{IP}$), and latches the `key` and `mode`.
3. **`ROUND`** *(16 cycles)*: Asserts `round_en`. An internal 4-bit round counter increments from `0` to `15`, computing one Feistel round per clock cycle.
4. **`FINAL`** *(1 cycle)*: Asserts `finalize`. Applies the 32-bit left/right half swap and Final Permutation ($\text{FP}$), loading the result into `data_out`.
5. **`DONE`** *(1 cycle)*: Asserts `done = 1` while `busy = 0`. Returns to `IDLE` on the following clock cycle.

**Total Processing Latency**: Exactly **19 clock cycles** per 64-bit data block.

---

## 🧪 Simulation & Verification

The project includes unit testbenches for all submodules as well as an automated file-driven top-level verification suite.

### Running Top Verification in QuestaSim:
1. Open QuestaSim or ModelSim.
2. In the transcript terminal, navigate to the simulation directory and execute:
   ```tcl
   cd E:/DES_Hardware_Implementation/sim
   do run_tb_top.do
   ```
3. The testbench automatically:
   - Reads `tb/vectors/plaintext.txt` and `tb/vectors/key.txt`.
   - Executes hardware encryption and logs output to `sim/output.txt`.
   - Compares the results against NIST reference answers in `tb/vectors/expected_output.txt`.
   - Automatically switches to Decryption mode (`mode = 1`), decrypts the generated ciphertexts, logs results to `sim/decrypted_output.txt`, and validates 100% reversibility back to the original plaintexts.

### Running the Full Regression Suite:
```tcl
cd E:/DES_Hardware_Implementation/sim
do run_all.do
```
Executes all 5 testbenches in sequence (`tb_f_round`, `tb_des_key_schedule`, `tb_controller`, `tb_data_path`, and `tb_des_top`) and logs PASS/FAIL statistics to the console.

---

## 📄 License

This project is licensed under the terms described in the [LICENSE](LICENSE) file.
