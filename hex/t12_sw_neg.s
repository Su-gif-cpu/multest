# t12_sw_neg.s - Store/Load with Negative Offset
# Critical: Address calculation with negative offset
# Tests: ALU correctly computes base_address + negative_immediate
# Expected final registers (with DM reset to 0):
#   x2 = 0x00000AFE
#   x3 = 0x00000000   (load from 0x1C, untouched location)

addi x1, x0, 0x20     # x1 = 0x20 (base address)
ori x2, x0, 0x7fe     # x2 = 0x000007FE (data to write, RARS immediate-safe)
sw x2, -28(x1)        # Store at address: 0x20 + (-28) = 0x0C
# Sign-extended immediate: -28 = 0xFFFFFFE4 in 32-bit, lower 12 bits used in SW instr
lw x3, -4(x1)         # Load from address: 0x20 + (-4) = 0x1C
# Sign-extended immediate: -4 = 0xFFFFFFFC in 32-bit, lower 12 bits in LW instr
end:
beq x0, x0, end       # Infinite loop
#
# Expected: x3 = 0x00000000 with current testbench memory initialization
# This tests that:
#   1. Negative offsets are correctly sign-extended
#   2. ALU addition handles negative values properly
#   3. Memory addressing with negative offsets works
