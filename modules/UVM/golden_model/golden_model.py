from dataclasses import dataclass
from typing import List
import copy


# ------------------------------------------------------------
# One PE in the systolic array
# ------------------------------------------------------------
@dataclass
class PE:
    weight: int = 0
    weight_valid: bool = False
    act_reg: int = 0
    psum_reg: int = 0


# ------------------------------------------------------------
# Main golden model
# ------------------------------------------------------------
class TPUGoldenModel:
    def __init__(self, N=4, act_width=16, wt_width=16, psum_width=32):
        self.N = N
        self.act_width = act_width
        self.wt_width = wt_width
        self.psum_width = psum_width
        self.reset()

    # --------------------------------------------------------
    # Reset everything
    # --------------------------------------------------------
    def reset(self):
        # Create N x N array of PEs
        self.array = [[PE() for _ in range(self.N)] for _ in range(self.N)]

        # Skew buffer: row r has delay of r cycles
        # row 0 -> no delay
        # row 1 -> 1 stage
        # row 2 -> 2 stages
        # ...
        self.skew_buffer = []
        for row in range(self.N):
            self.skew_buffer.append([0] * row)

        self.cycle = 0
        self.last_output = [0] * self.N

    # --------------------------------------------------------
    # Helper: wrap integer to signed fixed width
    # --------------------------------------------------------
    def wrap_signed(self, value, bits):
        mask = (1 << bits) - 1
        value = value & mask
        if value >= (1 << (bits - 1)):
            value -= (1 << bits)
        return value

    # --------------------------------------------------------
    # Load one weight into PE[row][col]
    # --------------------------------------------------------
    def load_weight(self, row, col, value):
        value = self.wrap_signed(value, self.wt_width)
        self.array[row][col].weight = value
        self.array[row][col].weight_valid = True

    # --------------------------------------------------------
    # Load all weights row by row
    #
    # Example for N=2:
    # [w00, w01,
    #  w10, w11]
    # --------------------------------------------------------
    def load_weights_row_major(self, flat_weights: List[int]):
        if len(flat_weights) != self.N * self.N:
            raise ValueError(f"Expected {self.N * self.N} weights")

        idx = 0
        for r in range(self.N):
            for c in range(self.N):
                self.load_weight(r, c, flat_weights[idx])
                idx += 1

    # --------------------------------------------------------
    # Apply skew buffer to one activation vector
    #
    # Input:
    #   act_in[row] enters from left side before skew
    #
    # Output:
    #   delayed activation vector after skew buffer
    # --------------------------------------------------------
    def apply_skew_buffer(self, act_in: List[int]) -> List[int]:
        if len(act_in) != self.N:
            raise ValueError(f"Expected {self.N} activation values")

        act_in = [self.wrap_signed(x, self.act_width) for x in act_in]

        skewed = [0] * self.N

        for row in range(self.N):
            if row == 0:
                # No delay for row 0
                skewed[row] = act_in[row]
            else:
                # Output is last value currently in the delay line
                skewed[row] = self.skew_buffer[row][-1]

        # Update delay lines
        for row in range(1, self.N):
            old_line = self.skew_buffer[row][:]
            self.skew_buffer[row][0] = act_in[row]
            for i in range(1, len(self.skew_buffer[row])):
                self.skew_buffer[row][i] = old_line[i - 1]

        return skewed

    # --------------------------------------------------------
    # Advance one cycle
    #
    # act_vector:
    #   one activation entering from the left for each row
    #
    # Returns:
    #   bottom-row outputs for this cycle
    # --------------------------------------------------------
    def step(self, act_vector: List[int]) -> List[int]:
        if len(act_vector) != self.N:
            raise ValueError(f"Expected act_vector of length {self.N}")

        self.cycle += 1

        # 1. Apply skew buffer first
        skewed_input = self.apply_skew_buffer(act_vector)

        # 2. Copy old state
        old_array = copy.deepcopy(self.array)

        # 3. Prepare next-state storage
        next_act = [[0] * self.N for _ in range(self.N)]
        next_psum = [[0] * self.N for _ in range(self.N)]

        # 4. Compute next state for every PE
        for r in range(self.N):
            for c in range(self.N):
                pe = old_array[r][c]

                # Activation comes from left
                if c == 0:
                    act_in = skewed_input[r]
                else:
                    act_in = old_array[r][c - 1].act_reg

                # Psum comes from top
                if r == 0:
                    psum_in = 0
                else:
                    psum_in = old_array[r - 1][c].psum_reg

                # Forward activation
                next_act[r][c] = self.wrap_signed(act_in, self.act_width)

                # Compute psum
                if pe.weight_valid:
                    product = act_in * pe.weight
                    product = self.wrap_signed(
                        product, self.act_width + self.wt_width
                    )
                    next_psum[r][c] = self.wrap_signed(
                        psum_in + product, self.psum_width
                    )
                else:
                    # If no weight yet, pass psum through
                    next_psum[r][c] = self.wrap_signed(psum_in, self.psum_width)

        # 5. Commit next state
        for r in range(self.N):
            for c in range(self.N):
                self.array[r][c].act_reg = next_act[r][c]
                self.array[r][c].psum_reg = next_psum[r][c]

        # 6. Output = bottom row psums
        self.last_output = [
            self.wrap_signed(self.array[self.N - 1][c].psum_reg, self.psum_width)
            for c in range(self.N)
        ]

        return self.last_output[:]

    # --------------------------------------------------------
    # Run many cycles
    # --------------------------------------------------------
    def run(self, act_stream: List[List[int]]) -> List[List[int]]:
        outputs = []
        for vec in act_stream:
            out = self.step(vec)
            outputs.append(out)
        return outputs

    # --------------------------------------------------------
    # Print current PE weights
    # --------------------------------------------------------
    def print_weights(self):
        print("Weights in array:")
        for r in range(self.N):
            row = []
            for c in range(self.N):
                row.append(self.array[r][c].weight)
            print(row)

    # --------------------------------------------------------
    # Print current PE psums
    # --------------------------------------------------------
    def print_psums(self):
        print("Current psum registers:")
        for r in range(self.N):
            row = []
            for c in range(self.N):
                row.append(self.array[r][c].psum_reg)
            print(row)


if __name__ == "__main__":
    gm = TPUGoldenModel(N=2)

    # Load weights:
    # [1 2]
    # [3 4]
    gm.load_weights_row_major([
        1, 2,
        3, 4
    ])

    gm.print_weights()

    # Feed one activation vector per cycle
    act_stream = [
        [10, 20],
        [30, 40],
        [0,  0],
        [0,  0],
        [0,  0],
    ]

    outputs = gm.run(act_stream)

    print("\nCycle-by-cycle outputs:")
    for i, out in enumerate(outputs, start=1):
        print(f"Cycle {i}: {out}")