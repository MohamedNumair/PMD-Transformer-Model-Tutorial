# Transformer Vector Group & Permutation Analysis

This document analyzes the mathematical permutations of 3-phase transformer connections and maps them to standard IEC Vector Groups.

## 1. Problem Space Definition

We are analyzing a 2-winding 3-phase transformer.
*   **Connection Types ($C$):** Each winding can be connected in Delta ($\Delta$) or Wye ($Y$).
    *   Set $C = \{D, Y\}$
*   **Terminal Connections ($P$):** The mapping of the logical phases (A, B, C) to the physical terminals (1, 2, 3).
    *   Set $P = S_3$ (The symmetric group of degree 3, i.e., all permutations of $\{1, 2, 3\}$).

### Total Permutation Space
If we assume we can arbitrarily permute the order of connections on both the Primary and Secondary sides:

$$ N_{total} = N_{Conns} \times N_{Perm\_Pri} \times N_{Perm\_Sec} $$

*   $N_{Conns} = 2 \times 2 = 4$ pairs ($Dd, Dy, Yd, Yy$)
*   $N_{Perm\_Pri} = 3! = 6$
*   $N_{Perm\_Sec} = 3! = 6$

$$ N_{total} = 4 \times 6 \times 6 = 144 \text{ possible wiring permutations} $$
However, in OpenDSS an additional parameter `leadlag` is provided which also swaps connections for {Delta/Wye} connections, which effectively doubles the possible configurations to 288, as in Appendix A.
## 2. Mathematical Representation of Permutations

Let the source voltage vector be $\mathbf{V}_{abc} = [1\angle0^\circ, 1\angle-120^\circ, 1\angle120^\circ]^T$.

A permutation $\sigma \in S_3$ can be represented by a permutation matrix $\mathbf{P}$.
For a connection specification $[n_1, n_2, n_3]$ (e.g., `1.2.3` or `3.1.2`):

1.  **Identity (abc / 123):** No shift.
    $$ \mathbf{P}_{123} = \begin{bmatrix} 1 & 0 & 0 \\ 0 & 1 & 0 \\ 0 & 0 & 1 \end{bmatrix} $$
2.  **Cyclic Shift (+120° / cab / 312):**
    $$ \mathbf{P}_{312} = \begin{bmatrix} 0 & 0 & 1 \\ 1 & 0 & 0 \\ 0 & 1 & 0 \end{bmatrix} $$
3.  **Cyclic Shift (-120° / bca / 231):**
    $$ \mathbf{P}_{231} = \begin{bmatrix} 0 & 1 & 0 \\ 0 & 0 & 1 \\ 1 & 0 & 0 \end{bmatrix} $$
4.  **Swap (acb / 132) - Negative Sequence:**
    $$ \mathbf{P}_{132} = \begin{bmatrix} 1 & 0 & 0 \\ 0 & 0 & 1 \\ 0 & 1 & 0 \end{bmatrix} $$

**Note:** Permutations 4, 5, and 6 correspond to swapping two phases. In a transformer context, this reverses the phase sequence (creating negative sequence voltage) and is generally considered a "faulty" wiring for a Vector Group unless the primary is also swapped. For Vector Group analysis, we usually focus on the **Cyclic Shifts** and **Polartity Reversals** (which D/Y connections naturally induce).

## 3. Analytical Derivation of Phase Shifts

The "Clock Number" $k$ represents a phase shift of $k \times -30^\circ$.

### Step 1: Intrinsic Shifts (Connection Type)
*   **Yy or Dd:** $0^\circ$ shift (Clock 0)
*   **Dy or Yd:** $\pm 30^\circ$ shift (Clock 1 or 11).
    *   Standard Dy1 lags by $30^\circ$.
    *   Standard Dy11 leads by $30^\circ$.

### Step 2: Permutation Shifts (Rotation)
Cyclically shifting the terminal definitions rotates the phasor diagram by $120^\circ$ (4 hours on the clock).

Let $k_{base}$ be the base clock of the connection (e.g., Dy1 = 1).
Let $r_p$ be the rotation index of the primary (0, 1, 2 for 0, -120, +120).
Let $r_s$ be the rotation index of the secondary.

$$ \text{Total Shift} = \text{Base Shift} + 120^\circ(r_p - r_s) $$

In clock notation ($\text{hours}$):
$$ Clock = (Clock_{base} + 4(r_s - r_p)) \pmod{12} $$

*   **Example:** Take a **Dy1** transformer (Base Clock = 1).
    *   Connect Primary normally (1.2.3, $r_p=0$).
    *   Connect Secondary shifted (2.3.1, $r_s=1$, effectively rotating sequence $-120^\circ$).
    *   New Clock = $1 + 4(1 - 0) = 5$.
    *   Result: **Dy5**.

## 4. Mapping Permutations to Vector Groups

Assuming standard positive sequence (no phase swapping like 1-3-2), here are the reachable vector groups by simply rolling the connections `[1.2.3]`, `[2.3.1]`, `[3.1.2]`.

### Case A: Delta-Delta (Dd) or Wye-Wye (Yy)
*Base Clock: 0*

| Primary Conn | Secondary Conn | Shift Calculation | Resulting Vector Group |
| :--- | :--- | :--- | :--- |
| 1.2.3 | 1.2.3 | $0 + 4(0-0) = 0$ | **Dd0 / Yy0** |
| 1.2.3 | 2.3.1 | $0 + 4(1-0) = 4$ | **Dd4 / Yy4** |
| 1.2.3 | 3.1.2 | $0 + 4(2-0) = 8$ | **Dd8 / Yy8** |
| 2.3.1 | 1.2.3 | $0 + 4(0-1) = -4 \equiv 8$ | **Dd8 / Yy8** |

### Case B: Delta-Wye (Dy) or Wye-Delta (Yd)
*Base Clock: 1 (Standard ANSI/IEC Dy1)*

| Primary Conn | Secondary Conn | Shift Calculation | Resulting Vector Group |
| :--- | :--- | :--- | :--- |
| 1.2.3 | 1.2.3 | $1 + 4(0-0) = 1$ | **Dy1 / Yd1** |
| 1.2.3 | 2.3.1 | $1 + 4(1-0) = 5$ | **Dy5 / Yd5** |
| 1.2.3 | 3.1.2 | $1 + 4(2-0) = 9$ | **Dy9 / Yd9** |

*Base Clock: 11 (Alternative standard Dy11)*

| Primary Conn | Secondary Conn | Shift Calculation | Resulting Vector Group |
| :--- | :--- | :--- | :--- |
| 1.2.3 | 1.2.3 | $11 + 4(0-0) = 11$ | **Dy11 / Yd11** |
| 1.2.3 | 2.3.1 | $11 + 4(1-0) = 15 \equiv 3$ | **Dy3 / Yd3** |
| 1.2.3 | 3.1.2 | $11 + 4(2-0) = 19 \equiv 7$ | **Dy7 / Yd7** |

## 5. Summary of Reachable Groups

By changing the connection permutation (cyclic rotation) of the terminals 1, 2, 3:

1.  **Group 0 (0, 4, 8):** Obtained from **Dd / Yy** types.
2.  **Group 1 (1, 5, 9):** Obtained from **Dy / Yd** types (lagging connection).
3.  **Group 11 (11, 3, 7):** Obtained from **Dy / Yd** types (leading connection).
4.  **Group 6 (6, 10, 2):** Obtained by reversing polarity of coils (Swapping ends of windings, e.g., connecting a' to Neutral instead of n').

*Note: In OpenDSS/PowerModelsDistribution, defining `Buses=[... 3.1.2]` performs these cyclic shifts.*




## Appendix A --- All Possible Transformer Vector Group Permutations
Analyzing configuration with variable Conns [Delta/Wye] and Lead/Lag

Mapping Permutations to Vector Groups (Clock Numbers)
LL   | Conns     | Pri      | Sec      | Shift deg     | Clock | Note
-----|-----------|----------|----------|---------------|-------|---------------
Lead | Delta-Wye | 1.2.3    | 1.2.3    | 330.0 deg     | 11    | 
Lead | Delta-Wye | 1.2.3    | 1.3.2    |  30.5 deg     |  1    | (Swap)
Lead | Delta-Wye | 1.2.3    | 2.1.3    | 150.6 deg     |  5    | (Swap)
Lead | Delta-Wye | 1.2.3    | 2.3.1    | 210.0 deg     |  7    |
Lead | Delta-Wye | 1.2.3    | 3.1.2    |  90.0 deg     |  3    |
Lead | Delta-Wye | 1.2.3    | 3.2.1    | 270.8 deg     |  9    | (Swap)
Lead | Delta-Wye | 1.3.2    | 1.2.3    |  90.8 deg     |  3    | (Swap)
Lead | Delta-Wye | 1.3.2    | 1.3.2    |  30.0 deg     |  1    | (Swap)
Lead | Delta-Wye | 1.3.2    | 2.1.3    | 270.0 deg     |  9    | (Swap)
Lead | Delta-Wye | 1.3.2    | 2.3.1    | 210.5 deg     |  7    | (Swap)
Lead | Delta-Wye | 1.3.2    | 3.1.2    | 330.6 deg     | 11    | (Swap)
Lead | Delta-Wye | 1.3.2    | 3.2.1    | 150.0 deg     |  5    | (Swap)
Lead | Delta-Wye | 2.1.3    | 1.2.3    | 210.5 deg     |  7    | (Swap)
Lead | Delta-Wye | 2.1.3    | 1.3.2    | 150.0 deg     |  5    | (Swap)
Lead | Delta-Wye | 2.1.3    | 2.1.3    |  30.0 deg     |  1    | (Swap)
Lead | Delta-Wye | 2.1.3    | 2.3.1    | 330.6 deg     | 11    | (Swap)
Lead | Delta-Wye | 2.1.3    | 3.1.2    |  90.8 deg     |  3    | (Swap)
Lead | Delta-Wye | 2.1.3    | 3.2.1    | 270.0 deg     |  9    | (Swap)
Lead | Delta-Wye | 2.3.1    | 1.2.3    |  90.0 deg     |  3    |
Lead | Delta-Wye | 2.3.1    | 1.3.2    | 150.6 deg     |  5    | (Swap)
Lead | Delta-Wye | 2.3.1    | 2.1.3    | 270.8 deg     |  9    | (Swap)
Lead | Delta-Wye | 2.3.1    | 2.3.1    | 330.0 deg     | 11    |
Lead | Delta-Wye | 2.3.1    | 3.1.2    | 210.0 deg     |  7    |
Lead | Delta-Wye | 2.3.1    | 3.2.1    |  30.5 deg     |  1    | (Swap)
Lead | Delta-Wye | 3.1.2    | 1.2.3    | 210.0 deg     |  7    |
Lead | Delta-Wye | 3.1.2    | 1.3.2    | 270.8 deg     |  9    | (Swap)
Lead | Delta-Wye | 3.1.2    | 2.1.3    |  30.5 deg     |  1    | (Swap)
Lead | Delta-Wye | 3.1.2    | 2.3.1    |  90.0 deg     |  3    |
Lead | Delta-Wye | 3.1.2    | 3.1.2    | 330.0 deg     | 11    |
Lead | Delta-Wye | 3.1.2    | 3.2.1    | 150.6 deg     |  5    | (Swap)
Lead | Delta-Wye | 3.2.1    | 1.2.3    | 330.6 deg     | 11    | (Swap)
Lead | Delta-Wye | 3.2.1    | 1.3.2    | 270.0 deg     |  9    | (Swap)
Lead | Delta-Wye | 3.2.1    | 2.1.3    | 150.0 deg     |  5    | (Swap)
Lead | Delta-Wye | 3.2.1    | 2.3.1    |  90.8 deg     |  3    | (Swap)
Lead | Delta-Wye | 3.2.1    | 3.1.2    | 210.5 deg     |  7    | (Swap)
Lead | Delta-Wye | 3.2.1    | 3.2.1    |  30.0 deg     |  1    | (Swap)
Lead | Wye-Wye   | 1.2.3    | 1.2.3    |   0.2 deg     |  0    |
Lead | Wye-Wye   | 1.2.3    | 1.3.2    |  61.1 deg     |  2    | (Swap)
Lead | Wye-Wye   | 1.2.3    | 2.1.3    | 180.7 deg     |  6    | (Swap)
Lead | Wye-Wye   | 1.2.3    | 2.3.1    | 240.2 deg     |  8    |
Lead | Wye-Wye   | 1.2.3    | 3.1.2    | 120.3 deg     |  4    |
Lead | Wye-Wye   | 1.2.3    | 3.2.1    | 300.9 deg     | 10    | (Swap)
Lead | Wye-Wye   | 1.3.2    | 1.2.3    |  61.1 deg     |  2    | (Swap)
Lead | Wye-Wye   | 1.3.2    | 1.3.2    |   0.2 deg     |  0    | (Swap)
Lead | Wye-Wye   | 1.3.2    | 2.1.3    | 240.2 deg     |  8    | (Swap)
Lead | Wye-Wye   | 1.3.2    | 2.3.1    | 180.7 deg     |  6    | (Swap)
Lead | Wye-Wye   | 1.3.2    | 3.1.2    | 300.9 deg     | 10    | (Swap)
Lead | Wye-Wye   | 1.3.2    | 3.2.1    | 120.3 deg     |  4    | (Swap)
Lead | Wye-Wye   | 2.1.3    | 1.2.3    | 180.7 deg     |  6    | (Swap)
Lead | Wye-Wye   | 2.1.3    | 1.3.2    | 120.3 deg     |  4    | (Swap)
Lead | Wye-Wye   | 2.1.3    | 2.1.3    |   0.2 deg     |  0    | (Swap)
Lead | Wye-Wye   | 2.1.3    | 2.3.1    | 300.9 deg     | 10    | (Swap)
Lead | Wye-Wye   | 2.1.3    | 3.1.2    |  61.1 deg     |  2    | (Swap)
Lead | Wye-Wye   | 2.1.3    | 3.2.1    | 240.2 deg     |  8    | (Swap)
Lead | Wye-Wye   | 2.3.1    | 1.2.3    | 120.3 deg     |  4    |
Lead | Wye-Wye   | 2.3.1    | 1.3.2    | 180.7 deg     |  6    | (Swap)
Lead | Wye-Wye   | 2.3.1    | 2.1.3    | 300.9 deg     | 10    | (Swap)
Lead | Wye-Wye   | 2.3.1    | 2.3.1    |   0.2 deg     |  0    |
Lead | Wye-Wye   | 2.3.1    | 3.1.2    | 240.2 deg     |  8    |
Lead | Wye-Wye   | 2.3.1    | 3.2.1    |  61.1 deg     |  2    | (Swap)
Lead | Wye-Wye   | 3.1.2    | 1.2.3    | 240.2 deg     |  8    |
Lead | Wye-Wye   | 3.1.2    | 1.3.2    | 300.9 deg     | 10    | (Swap)
Lead | Wye-Wye   | 3.1.2    | 2.1.3    |  61.1 deg     |  2    | (Swap)
Lead | Wye-Wye   | 3.1.2    | 2.3.1    | 120.3 deg     |  4    |
Lead | Wye-Wye   | 3.1.2    | 3.1.2    |   0.2 deg     |  0    |
Lead | Wye-Wye   | 3.1.2    | 3.2.1    | 180.7 deg     |  6    | (Swap)
Lead | Wye-Wye   | 3.2.1    | 1.2.3    | 300.9 deg     | 10    | (Swap)
Lead | Wye-Wye   | 3.2.1    | 1.3.2    | 240.2 deg     |  8    | (Swap)
Lead | Wye-Wye   | 3.2.1    | 2.1.3    | 120.3 deg     |  4    | (Swap)
Lead | Wye-Wye   | 3.2.1    | 2.3.1    |  61.1 deg     |  2    | (Swap)
Lead | Wye-Wye   | 3.2.1    | 3.1.2    | 180.7 deg     |  6    | (Swap)
Lead | Wye-Wye   | 3.2.1    | 3.2.1    |   0.2 deg     |  0    | (Swap)
Lead | Wye-Delta | 1.2.3    | 1.2.3    |  15.0 deg     |  0    |
Lead | Wye-Delta | 1.2.3    | 1.3.2    |  74.9 deg     |  2    | (Swap)
Lead | Wye-Delta | 1.2.3    | 2.1.3    | 195.0 deg     |  6    | (Swap)
Lead | Wye-Delta | 1.2.3    | 2.3.1    | 254.9 deg     |  8    |
Lead | Wye-Delta | 1.2.3    | 3.1.2    | 135.0 deg     |  4    |
Lead | Wye-Delta | 1.2.3    | 3.2.1    | 315.0 deg     | 10    | (Swap)
Lead | Wye-Delta | 1.3.2    | 1.2.3    | 135.0 deg     |  4    | (Swap)
Lead | Wye-Delta | 1.3.2    | 1.3.2    |  74.9 deg     |  2    | (Swap)
Lead | Wye-Delta | 1.3.2    | 2.1.3    | 315.0 deg     | 10    | (Swap)
Lead | Wye-Delta | 1.3.2    | 2.3.1    | 254.9 deg     |  8    | (Swap)
Lead | Wye-Delta | 1.3.2    | 3.1.2    |  15.0 deg     |  0    | (Swap)
Lead | Wye-Delta | 1.3.2    | 3.2.1    | 195.0 deg     |  6    | (Swap)
Lead | Wye-Delta | 2.1.3    | 1.2.3    | 254.9 deg     |  8    | (Swap)
Lead | Wye-Delta | 2.1.3    | 1.3.2    | 195.0 deg     |  6    | (Swap)
Lead | Wye-Delta | 2.1.3    | 2.1.3    |  74.9 deg     |  2    | (Swap)
Lead | Wye-Delta | 2.1.3    | 2.3.1    |  15.0 deg     |  0    | (Swap)
Lead | Wye-Delta | 2.1.3    | 3.1.2    | 135.0 deg     |  4    | (Swap)
Lead | Wye-Delta | 2.1.3    | 3.2.1    | 315.0 deg     | 10    | (Swap)
Lead | Wye-Delta | 2.3.1    | 1.2.3    | 135.0 deg     |  4    |
Lead | Wye-Delta | 2.3.1    | 1.3.2    | 195.0 deg     |  6    | (Swap)
Lead | Wye-Delta | 2.3.1    | 2.1.3    | 315.0 deg     | 10    | (Swap)
Lead | Wye-Delta | 2.3.1    | 2.3.1    |  15.0 deg     |  0    |
Lead | Wye-Delta | 2.3.1    | 3.1.2    | 254.9 deg     |  8    |
Lead | Wye-Delta | 2.3.1    | 3.2.1    |  74.9 deg     |  2    | (Swap)
Lead | Wye-Delta | 3.1.2    | 1.2.3    | 254.9 deg     |  8    |
Lead | Wye-Delta | 3.1.2    | 1.3.2    | 315.0 deg     | 10    | (Swap)
Lead | Wye-Delta | 3.1.2    | 2.1.3    |  74.9 deg     |  2    | (Swap)
Lead | Wye-Delta | 3.1.2    | 2.3.1    | 135.0 deg     |  4    |
Lead | Wye-Delta | 3.1.2    | 3.1.2    |  15.0 deg     |  0    |
Lead | Wye-Delta | 3.1.2    | 3.2.1    | 195.0 deg     |  6    | (Swap)
Lead | Wye-Delta | 3.2.1    | 1.2.3    |  15.0 deg     |  0    | (Swap)
Lead | Wye-Delta | 3.2.1    | 1.3.2    | 315.0 deg     | 10    | (Swap)
Lead | Wye-Delta | 3.2.1    | 2.1.3    | 195.0 deg     |  6    | (Swap)
Lead | Wye-Delta | 3.2.1    | 2.3.1    | 135.0 deg     |  4    | (Swap)
Lead | Wye-Delta | 3.2.1    | 3.1.2    | 254.9 deg     |  8    | (Swap)
Lead | Wye-Delta | 3.2.1    | 3.2.1    |  74.9 deg     |  2    | (Swap)
Lead | Delta-Delta | 1.2.3    | 1.2.3    |  44.9 deg     |  1    |
Lead | Delta-Delta | 1.2.3    | 1.3.2    | 105.0 deg     |  3    | (Swap)
Lead | Delta-Delta | 1.2.3    | 2.1.3    | 224.9 deg     |  7    | (Swap)
Lead | Delta-Delta | 1.2.3    | 2.3.1    | 285.0 deg     |  9    |
Lead | Delta-Delta | 1.2.3    | 3.1.2    | 165.0 deg     |  5    |
Lead | Delta-Delta | 1.2.3    | 3.2.1    | 345.0 deg     | 11    | (Swap)
Lead | Delta-Delta | 1.3.2    | 1.2.3    | 105.0 deg     |  3    | (Swap)
Lead | Delta-Delta | 1.3.2    | 1.3.2    |  44.9 deg     |  1    | (Swap)
Lead | Delta-Delta | 1.3.2    | 2.1.3    | 285.0 deg     |  9    | (Swap)
Lead | Delta-Delta | 1.3.2    | 2.3.1    | 224.9 deg     |  7    | (Swap)
Lead | Delta-Delta | 1.3.2    | 3.1.2    | 345.0 deg     | 11    | (Swap)
Lead | Delta-Delta | 1.3.2    | 3.2.1    | 165.0 deg     |  5    | (Swap)
Lead | Delta-Delta | 2.1.3    | 1.2.3    | 224.9 deg     |  7    | (Swap)
Lead | Delta-Delta | 2.1.3    | 1.3.2    | 165.0 deg     |  5    | (Swap)
Lead | Delta-Delta | 2.1.3    | 2.1.3    |  44.9 deg     |  1    | (Swap)
Lead | Delta-Delta | 2.1.3    | 2.3.1    | 345.0 deg     | 11    | (Swap)
Lead | Delta-Delta | 2.1.3    | 3.1.2    | 105.0 deg     |  3    | (Swap)
Lead | Delta-Delta | 2.1.3    | 3.2.1    | 285.0 deg     |  9    | (Swap)
Lead | Delta-Delta | 2.3.1    | 1.2.3    | 165.0 deg     |  5    |
Lead | Delta-Delta | 2.3.1    | 1.3.2    | 224.9 deg     |  7    | (Swap)
Lead | Delta-Delta | 2.3.1    | 2.1.3    | 345.0 deg     | 11    | (Swap)
Lead | Delta-Delta | 2.3.1    | 2.3.1    |  44.9 deg     |  1    |
Lead | Delta-Delta | 2.3.1    | 3.1.2    | 285.0 deg     |  9    |
Lead | Delta-Delta | 2.3.1    | 3.2.1    | 105.0 deg     |  3    | (Swap)
Lead | Delta-Delta | 3.1.2    | 1.2.3    | 285.0 deg     |  9    |
Lead | Delta-Delta | 3.1.2    | 1.3.2    | 345.0 deg     | 11    | (Swap)
Lead | Delta-Delta | 3.1.2    | 2.1.3    | 105.0 deg     |  3    | (Swap)
Lead | Delta-Delta | 3.1.2    | 2.3.1    | 165.0 deg     |  5    |
Lead | Delta-Delta | 3.1.2    | 3.1.2    |  44.9 deg     |  1    |
Lead | Delta-Delta | 3.1.2    | 3.2.1    | 224.9 deg     |  7    | (Swap)
Lead | Delta-Delta | 3.2.1    | 1.2.3    | 345.0 deg     | 11    | (Swap)
Lead | Delta-Delta | 3.2.1    | 1.3.2    | 285.0 deg     |  9    | (Swap)
Lead | Delta-Delta | 3.2.1    | 2.1.3    | 165.0 deg     |  5    | (Swap)
Lead | Delta-Delta | 3.2.1    | 2.3.1    | 105.0 deg     |  3    | (Swap)
Lead | Delta-Delta | 3.2.1    | 3.1.2    | 224.9 deg     |  7    | (Swap)
Lead | Delta-Delta | 3.2.1    | 3.2.1    |  44.9 deg     |  1    | (Swap)
Lag  | Delta-Wye | 1.2.3    | 1.2.3    |  30.0 deg     |  1    |
Lag  | Delta-Wye | 1.2.3    | 1.3.2    |  90.8 deg     |  3    | (Swap)
Lag  | Delta-Wye | 1.2.3    | 2.1.3    | 210.5 deg     |  7    | (Swap)
Lag  | Delta-Wye | 1.2.3    | 2.3.1    | 270.0 deg     |  9    |
Lag  | Delta-Wye | 1.2.3    | 3.1.2    | 150.0 deg     |  5    |
Lag  | Delta-Wye | 1.2.3    | 3.2.1    | 330.6 deg     | 11    | (Swap)
Lag  | Delta-Wye | 1.3.2    | 1.2.3    |  30.5 deg     |  1    | (Swap)
Lag  | Delta-Wye | 1.3.2    | 1.3.2    | 330.0 deg     | 11    | (Swap)
Lag  | Delta-Wye | 1.3.2    | 2.1.3    | 210.0 deg     |  7    | (Swap)
Lag  | Delta-Wye | 1.3.2    | 2.3.1    | 150.6 deg     |  5    | (Swap)
Lag  | Delta-Wye | 1.3.2    | 3.1.2    | 270.8 deg     |  9    | (Swap)
Lag  | Delta-Wye | 1.3.2    | 3.2.1    |  90.0 deg     |  3    | (Swap)
Lag  | Delta-Wye | 2.1.3    | 1.2.3    | 150.6 deg     |  5    | (Swap)
Lag  | Delta-Wye | 2.1.3    | 1.3.2    |  90.0 deg     |  3    | (Swap)
Lag  | Delta-Wye | 2.1.3    | 2.1.3    | 330.0 deg     | 11    | (Swap)
Lag  | Delta-Wye | 2.1.3    | 2.3.1    | 270.8 deg     |  9    | (Swap)
Lag  | Delta-Wye | 2.1.3    | 3.1.2    |  30.5 deg     |  1    | (Swap)
Lag  | Delta-Wye | 2.1.3    | 3.2.1    | 210.0 deg     |  7    | (Swap)
Lag  | Delta-Wye | 2.3.1    | 1.2.3    | 150.0 deg     |  5    | 
Lag  | Delta-Wye | 2.3.1    | 1.3.2    | 210.5 deg     |  7    | (Swap)
Lag  | Delta-Wye | 2.3.1    | 2.1.3    | 330.6 deg     | 11    | (Swap)
Lag  | Delta-Wye | 2.3.1    | 2.3.1    |  30.0 deg     |  1    |
Lag  | Delta-Wye | 2.3.1    | 3.1.2    | 270.0 deg     |  9    |
Lag  | Delta-Wye | 2.3.1    | 3.2.1    |  90.8 deg     |  3    | (Swap)
Lag  | Delta-Wye | 3.1.2    | 1.2.3    | 270.0 deg     |  9    |
Lag  | Delta-Wye | 3.1.2    | 1.3.2    | 330.6 deg     | 11    | (Swap)
Lag  | Delta-Wye | 3.1.2    | 2.1.3    |  90.8 deg     |  3    | (Swap)
Lag  | Delta-Wye | 3.1.2    | 2.3.1    | 150.0 deg     |  5    |
Lag  | Delta-Wye | 3.1.2    | 3.1.2    |  30.0 deg     |  1    |
Lag  | Delta-Wye | 3.1.2    | 3.2.1    | 210.5 deg     |  7    | (Swap)
Lag  | Delta-Wye | 3.2.1    | 1.2.3    | 270.8 deg     |  9    | (Swap)
Lag  | Delta-Wye | 3.2.1    | 1.3.2    | 210.0 deg     |  7    | (Swap)
Lag  | Delta-Wye | 3.2.1    | 2.1.3    |  90.0 deg     |  3    | (Swap)
Lag  | Delta-Wye | 3.2.1    | 2.3.1    |  30.5 deg     |  1    | (Swap)
Lag  | Delta-Wye | 3.2.1    | 3.1.2    | 150.6 deg     |  5    | (Swap)
Lag  | Delta-Wye | 3.2.1    | 3.2.1    | 330.0 deg     | 11    | (Swap)
Lag  | Wye-Wye   | 1.2.3    | 1.2.3    |   0.2 deg     |  0    |
Lag  | Wye-Wye   | 1.2.3    | 1.3.2    |  61.1 deg     |  2    | (Swap)
Lag  | Wye-Wye   | 1.2.3    | 2.1.3    | 180.7 deg     |  6    | (Swap)
Lag  | Wye-Wye   | 1.2.3    | 2.3.1    | 240.2 deg     |  8    |
Lag  | Wye-Wye   | 1.2.3    | 3.1.2    | 120.3 deg     |  4    |
Lag  | Wye-Wye   | 1.2.3    | 3.2.1    | 300.9 deg     | 10    | (Swap)
Lag  | Wye-Wye   | 1.3.2    | 1.2.3    |  61.1 deg     |  2    | (Swap)
Lag  | Wye-Wye   | 1.3.2    | 1.3.2    |   0.2 deg     |  0    | (Swap)
Lag  | Wye-Wye   | 1.3.2    | 2.1.3    | 240.2 deg     |  8    | (Swap)
Lag  | Wye-Wye   | 1.3.2    | 2.3.1    | 180.7 deg     |  6    | (Swap)
Lag  | Wye-Wye   | 1.3.2    | 3.1.2    | 300.9 deg     | 10    | (Swap)
Lag  | Wye-Wye   | 1.3.2    | 3.2.1    | 120.3 deg     |  4    | (Swap)
Lag  | Wye-Wye   | 2.1.3    | 1.2.3    | 180.7 deg     |  6    | (Swap)
Lag  | Wye-Wye   | 2.1.3    | 1.3.2    | 120.3 deg     |  4    | (Swap)
Lag  | Wye-Wye   | 2.1.3    | 2.1.3    |   0.2 deg     |  0    | (Swap)
Lag  | Wye-Wye   | 2.1.3    | 2.3.1    | 300.9 deg     | 10    | (Swap)
Lag  | Wye-Wye   | 2.1.3    | 3.1.2    |  61.1 deg     |  2    | (Swap)
Lag  | Wye-Wye   | 2.1.3    | 3.2.1    | 240.2 deg     |  8    | (Swap)
Lag  | Wye-Wye   | 2.3.1    | 1.2.3    | 120.3 deg     |  4    |
Lag  | Wye-Wye   | 2.3.1    | 1.3.2    | 180.7 deg     |  6    | (Swap)
Lag  | Wye-Wye   | 2.3.1    | 2.1.3    | 300.9 deg     | 10    | (Swap)
Lag  | Wye-Wye   | 2.3.1    | 2.3.1    |   0.2 deg     |  0    |
Lag  | Wye-Wye   | 2.3.1    | 3.1.2    | 240.2 deg     |  8    |
Lag  | Wye-Wye   | 2.3.1    | 3.2.1    |  61.1 deg     |  2    | (Swap)
Lag  | Wye-Wye   | 3.1.2    | 1.2.3    | 240.2 deg     |  8    |
Lag  | Wye-Wye   | 3.1.2    | 1.3.2    | 300.9 deg     | 10    | (Swap)
Lag  | Wye-Wye   | 3.1.2    | 2.1.3    |  61.1 deg     |  2    | (Swap)
Lag  | Wye-Wye   | 3.1.2    | 2.3.1    | 120.3 deg     |  4    |
Lag  | Wye-Wye   | 3.1.2    | 3.1.2    |   0.2 deg     |  0    |
Lag  | Wye-Wye   | 3.1.2    | 3.2.1    | 180.7 deg     |  6    | (Swap)
Lag  | Wye-Wye   | 3.2.1    | 1.2.3    | 300.9 deg     | 10    | (Swap)
Lag  | Wye-Wye   | 3.2.1    | 1.3.2    | 240.2 deg     |  8    | (Swap)
Lag  | Wye-Wye   | 3.2.1    | 2.1.3    | 120.3 deg     |  4    | (Swap)
Lag  | Wye-Wye   | 3.2.1    | 2.3.1    |  61.1 deg     |  2    | (Swap)
Lag  | Wye-Wye   | 3.2.1    | 3.1.2    | 180.7 deg     |  6    | (Swap)
Lag  | Wye-Wye   | 3.2.1    | 3.2.1    |   0.2 deg     |  0    | (Swap)
Lag  | Wye-Delta | 1.2.3    | 1.2.3    |  74.9 deg     |  2    |
Lag  | Wye-Delta | 1.2.3    | 1.3.2    | 135.0 deg     |  4    | (Swap)
Lag  | Wye-Delta | 1.2.3    | 2.1.3    | 254.9 deg     |  8    | (Swap)
Lag  | Wye-Delta | 1.2.3    | 2.3.1    | 315.0 deg     | 10    |
Lag  | Wye-Delta | 1.2.3    | 3.1.2    | 195.0 deg     |  6    |
Lag  | Wye-Delta | 1.2.3    | 3.2.1    |  15.0 deg     |  0    | (Swap)
Lag  | Wye-Delta | 1.3.2    | 1.2.3    |  74.9 deg     |  2    | (Swap)
Lag  | Wye-Delta | 1.3.2    | 1.3.2    |  15.0 deg     |  0    | (Swap)
Lag  | Wye-Delta | 1.3.2    | 2.1.3    | 254.9 deg     |  8    | (Swap)
Lag  | Wye-Delta | 1.3.2    | 2.3.1    | 195.0 deg     |  6    | (Swap)
Lag  | Wye-Delta | 1.3.2    | 3.1.2    | 315.0 deg     | 10    | (Swap)
Lag  | Wye-Delta | 1.3.2    | 3.2.1    | 135.0 deg     |  4    | (Swap)
Lag  | Wye-Delta | 2.1.3    | 1.2.3    | 195.0 deg     |  6    | (Swap)
Lag  | Wye-Delta | 2.1.3    | 1.3.2    | 135.0 deg     |  4    | (Swap)
Lag  | Wye-Delta | 2.1.3    | 2.1.3    |  15.0 deg     |  0    | (Swap)
Lag  | Wye-Delta | 2.1.3    | 2.3.1    | 315.0 deg     | 10    | (Swap)
Lag  | Wye-Delta | 2.1.3    | 3.1.2    |  74.9 deg     |  2    | (Swap)
Lag  | Wye-Delta | 2.1.3    | 3.2.1    | 254.9 deg     |  8    | (Swap)
Lag  | Wye-Delta | 2.3.1    | 1.2.3    | 195.0 deg     |  6    |
Lag  | Wye-Delta | 2.3.1    | 1.3.2    | 254.9 deg     |  8    | (Swap)
Lag  | Wye-Delta | 2.3.1    | 2.1.3    |  15.0 deg     |  0    | (Swap)
Lag  | Wye-Delta | 2.3.1    | 2.3.1    |  74.9 deg     |  2    |
Lag  | Wye-Delta | 2.3.1    | 3.1.2    | 315.0 deg     | 10    |
Lag  | Wye-Delta | 2.3.1    | 3.2.1    | 135.0 deg     |  4    | (Swap)
Lag  | Wye-Delta | 3.1.2    | 1.2.3    | 315.0 deg     | 10    |
Lag  | Wye-Delta | 3.1.2    | 1.3.2    |  15.0 deg     |  0    | (Swap)
Lag  | Wye-Delta | 3.1.2    | 2.1.3    | 135.0 deg     |  4    | (Swap)
Lag  | Wye-Delta | 3.1.2    | 2.3.1    | 195.0 deg     |  6    |
Lag  | Wye-Delta | 3.1.2    | 3.1.2    |  74.9 deg     |  2    |
Lag  | Wye-Delta | 3.1.2    | 3.2.1    | 254.9 deg     |  8    | (Swap)
Lag  | Wye-Delta | 3.2.1    | 1.2.3    | 315.0 deg     | 10    | (Swap)
Lag  | Wye-Delta | 3.2.1    | 1.3.2    | 254.9 deg     |  8    | (Swap)
Lag  | Wye-Delta | 3.2.1    | 2.1.3    | 135.0 deg     |  4    | (Swap)
Lag  | Wye-Delta | 3.2.1    | 2.3.1    |  74.9 deg     |  2    | (Swap)
Lag  | Wye-Delta | 3.2.1    | 3.1.2    | 195.0 deg     |  6    | (Swap)
Lag  | Wye-Delta | 3.2.1    | 3.2.1    |  15.0 deg     |  0    | (Swap)
Lag  | Delta-Delta | 1.2.3    | 1.2.3    |  44.9 deg     |  1    |
Lag  | Delta-Delta | 1.2.3    | 1.3.2    | 105.0 deg     |  3    | (Swap)
Lag  | Delta-Delta | 1.2.3    | 2.1.3    | 224.9 deg     |  7    | (Swap)
Lag  | Delta-Delta | 1.2.3    | 2.3.1    | 285.0 deg     |  9    |
Lag  | Delta-Delta | 1.2.3    | 3.1.2    | 165.0 deg     |  5    |
Lag  | Delta-Delta | 1.2.3    | 3.2.1    | 345.0 deg     | 11    | (Swap)
Lag  | Delta-Delta | 1.3.2    | 1.2.3    | 105.0 deg     |  3    | (Swap)
Lag  | Delta-Delta | 1.3.2    | 1.3.2    |  44.9 deg     |  1    | (Swap)
Lag  | Delta-Delta | 1.3.2    | 2.1.3    | 285.0 deg     |  9    | (Swap)
Lag  | Delta-Delta | 1.3.2    | 2.3.1    | 224.9 deg     |  7    | (Swap)
Lag  | Delta-Delta | 1.3.2    | 3.1.2    | 345.0 deg     | 11    | (Swap)
Lag  | Delta-Delta | 1.3.2    | 3.2.1    | 165.0 deg     |  5    | (Swap)
Lag  | Delta-Delta | 2.1.3    | 1.2.3    | 224.9 deg     |  7    | (Swap)
Lag  | Delta-Delta | 2.1.3    | 1.3.2    | 165.0 deg     |  5    | (Swap)
Lag  | Delta-Delta | 2.1.3    | 2.1.3    |  44.9 deg     |  1    | (Swap)
Lag  | Delta-Delta | 2.1.3    | 2.3.1    | 345.0 deg     | 11    | (Swap)
Lag  | Delta-Delta | 2.1.3    | 3.1.2    | 105.0 deg     |  3    | (Swap)
Lag  | Delta-Delta | 2.1.3    | 3.2.1    | 285.0 deg     |  9    | (Swap)
Lag  | Delta-Delta | 2.3.1    | 1.2.3    | 165.0 deg     |  5    |
Lag  | Delta-Delta | 2.3.1    | 1.3.2    | 224.9 deg     |  7    | (Swap)
Lag  | Delta-Delta | 2.3.1    | 2.1.3    | 345.0 deg     | 11    | (Swap)
Lag  | Delta-Delta | 2.3.1    | 2.3.1    |  44.9 deg     |  1    |
Lag  | Delta-Delta | 2.3.1    | 3.1.2    | 285.0 deg     |  9    |
Lag  | Delta-Delta | 2.3.1    | 3.2.1    | 105.0 deg     |  3    | (Swap)
Lag  | Delta-Delta | 3.1.2    | 1.2.3    | 285.0 deg     |  9    |
Lag  | Delta-Delta | 3.1.2    | 1.3.2    | 345.0 deg     | 11    | (Swap)
Lag  | Delta-Delta | 3.1.2    | 2.1.3    | 105.0 deg     |  3    | (Swap)
Lag  | Delta-Delta | 3.1.2    | 2.3.1    | 165.0 deg     |  5    |
Lag  | Delta-Delta | 3.1.2    | 3.1.2    |  44.9 deg     |  1    |
Lag  | Delta-Delta | 3.1.2    | 3.2.1    | 224.9 deg     |  7    | (Swap)
Lag  | Delta-Delta | 3.2.1    | 1.2.3    | 345.0 deg     | 11    | (Swap)
Lag  | Delta-Delta | 3.2.1    | 1.3.2    | 285.0 deg     |  9    | (Swap)
Lag  | Delta-Delta | 3.2.1    | 2.1.3    | 165.0 deg     |  5    | (Swap)
Lag  | Delta-Delta | 3.2.1    | 2.3.1    | 105.0 deg     |  3    | (Swap)
Lag  | Delta-Delta | 3.2.1    | 3.1.2    | 224.9 deg     |  7    | (Swap)
Lag  | Delta-Delta | 3.2.1    | 3.2.1    |  44.9 deg     |  1    | (Swap)
