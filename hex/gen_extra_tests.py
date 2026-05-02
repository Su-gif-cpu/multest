#!/usr/bin/env python3
"""Generate t17-t29 .hex for multicycle RISC-V tests (RV32I subset)."""


def _u12(imm):
    return int(imm) % (1 << 12)


def enc_i(op, rd, funct3, rs1, imm):
    imm12 = _u12(imm)
    return (imm12 << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | op


def enc_r(op, rd, funct3, rs1, rs2, funct7):
    return (funct7 << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | op


def enc_s(op, funct3, rs1, rs2, imm):
    imm = _u12(imm)
    return ((imm >> 5) << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | ((imm & 0x1F) << 7) | op


def enc_b(op, funct3, rs1, rs2, imm):
    imm = int(imm) % (1 << 13)
    b12 = (imm >> 12) & 1
    b10_5 = (imm >> 5) & 0x3F
    b4_1 = (imm >> 1) & 0xF
    b11 = (imm >> 11) & 1
    return (
        (b12 << 31)
        | (b10_5 << 25)
        | (rs2 << 20)
        | (rs1 << 15)
        | (funct3 << 12)
        | (b4_1 << 8)
        | (b11 << 7)
        | op
    )


def enc_j(op, rd, imm):
    imm = int(imm) % (1 << 21)
    b20 = (imm >> 20) & 1
    b10_1 = (imm >> 1) & 0x3FF
    b11 = (imm >> 11) & 1
    b19_12 = (imm >> 12) & 0xFF
    return (
        (b20 << 31)
        | (b10_1 << 21)
        | (b11 << 20)
        | (b19_12 << 12)
        | (rd << 7)
        | op
    )


def addi(rd, rs1, imm):
    return enc_i(0x13, rd, 0, rs1, imm)


def ori(rd, rs1, imm):
    return enc_i(0x13, rd, 6, rs1, imm)


def lw(rd, rs1, imm):
    return enc_i(0x03, rd, 2, rs1, imm)


def jalr(rd, rs1, imm):
    return enc_i(0x67, rd, 0, rs1, imm)


def add(rd, rs1, rs2):
    return enc_r(0x33, rd, 0, rs1, rs2, 0)


def sub(rd, rs1, rs2):
    return enc_r(0x33, rd, 0, rs1, rs2, 0x20)


def AND(rd, rs1, rs2):
    return enc_r(0x33, rd, 7, rs1, rs2, 0)


def XOR(rd, rs1, rs2):
    return enc_r(0x33, rd, 4, rs1, rs2, 0)


def sll(rd, rs1, rs2):
    return enc_r(0x33, rd, 1, rs1, rs2, 0)


def srl(rd, rs1, rs2):
    return enc_r(0x33, rd, 5, rs1, rs2, 0)


def sra(rd, rs1, rs2):
    return enc_r(0x33, rd, 5, rs1, rs2, 0x20)


def sw(rs2, rs1, imm):
    return enc_s(0x23, 2, rs1, rs2, imm)


def beq(rs1, rs2, imm):
    return enc_b(0x63, 0, rs1, rs2, imm)


def bne(rs1, rs2, imm):
    return enc_b(0x63, 1, rs1, rs2, imm)


def jal(rd, imm):
    return enc_j(0x6F, rd, imm)


END = jal(0, 0)  # infinite loop at same PC offset 0

PROGRAMS = {
    "t17_addi_bounds": [
        addi(1, 0, 0x800),  # -2048
        addi(2, 0, 0x7FF),  # +2047
        add(20, 1, 2),  # 0xFFFFF7FF
        END,
    ],
    "t18_ori_and": [
        ori(1, 0, 0x7FF),
        ori(2, 0, 0xFFF),  # -1
        AND(20, 1, 2),
        END,
    ],
    "t19_xor_sign": [
        addi(1, 0, 0xFFF),  # -1
        addi(2, 0, 1),
        XOR(20, 1, 2),  # 0xFFFFFFFE
        END,
    ],
    "t20_sub_self": [
        addi(1, 0, 0x55),
        sub(20, 1, 1),
        END,
    ],
    "t21_srl_rs0": [
        addi(1, 0, 0x7B),
        srl(20, 1, 0),  # shift amt from x0 low 5 bits = 0
        END,
    ],
    "t22_sll31": [
        addi(1, 0, 1),
        addi(2, 0, 31),
        sll(20, 1, 2),
        END,
    ],
    "t23_beq_always": [
        beq(0, 0, 8),
        addi(20, 0, 1),
        addi(20, 0, 0x42),
        END,
    ],
    "t24_jal_jalr_ret": [
        jal(5, 8),
        addi(21, 0, 0xAA),
        addi(20, 0, 0x33),
        jalr(0, 5, 0),
        END,
    ],
    "t25_sw_overwrite": [
        addi(1, 0, 0x20),
        ori(2, 0, 0x111),
        sw(2, 1, 0),
        ori(3, 0, 0x222),
        sw(3, 1, 0),
        lw(20, 1, 0),
        END,
    ],
    "t26_alu_chain": [
        addi(1, 0, 1),
        add(2, 1, 1),
        add(3, 2, 2),
        add(4, 3, 3),
        add(20, 4, 4),  # 16
        END,
    ],
    "t27_sra_neg1": [
        addi(1, 0, 0xFFF),
        addi(2, 0, 1),
        sra(20, 1, 2),  # -1 >> 1 = -1
        END,
    ],
    "t28_bne_taken": [
        addi(1, 0, 1),
        addi(2, 0, 2),
        bne(1, 2, 8),
        addi(20, 0, 0xFF),
        addi(20, 0, 0x56),
        END,
    ],
    "t29_or_combine": [
        addi(1, 0, 0x0F0),
        ori(20, 1, 0x00F),  # 0xF0 | 0x00F = 0xFF
        END,
    ],
    # --- t30-t39: extra stress (offsets / jalr.imm / DM min imm / chains) ---
    "t30_sw_lw_min_offset": [
        addi(1, 0, 0x7FF),  # 2047
        addi(1, 1, 1),  # x1 = 2048 (addi imm cannot be 2048 in one insn)
        ori(2, 0, 0x3EF),
        sw(2, 1, 0x800),  # offset -2048
        lw(20, 1, 0x800),
        END,
    ],
    # jal x5,+12 -> L2; x5=PC+4=0x2004; L1 addi x20; jal x0,+12 -> end; L2: addi x10,x5,4; jalr x0,x10,-4
    "t31_jalr_imm": [
        jal(5, 12),
        addi(20, 0, 0xCC),
        jal(0, 12),
        addi(10, 5, 4),
        jalr(0, 10, -4),
        END,
    ],
    # 0x7FFFFFFF + 1 == 0x80000000 (wrap, no trap in RV32I)
    "t32_add_maxint_wrap": [
        addi(1, 0, 1),
        addi(2, 0, 31),
        sll(3, 1, 2),
        addi(4, 0, 0xFFF),
        XOR(5, 4, 3),  # 0x7FFFFFFF
        add(20, 5, 1),
        END,
    ],
    # 0x40000000 sra 31 == 0 (MSB 0)
    "t33_sra_pos_msb": [
        addi(1, 0, 1),
        addi(2, 0, 30),
        sll(3, 1, 2),
        addi(4, 0, 31),
        sra(20, 3, 4),
        END,
    ],
    # lw x0 then use x0 as rs1: x21 must be 5
    "t34_lw_x0_rs": [
        addi(1, 0, 0x20),
        ori(2, 0, 0x077),
        sw(2, 1, 0),
        lw(0, 1, 0),
        addi(21, 0, 5),
        END,
    ],
    # sw/lw/sw/lw then relocate word: final lw x20 == 0x101
    "t35_mem_chain_offsets": [
        addi(1, 0, 0x40),
        ori(2, 0, 0x101),
        sw(2, 1, 0),
        lw(3, 1, 0),
        ori(4, 0, 0x202),
        sw(4, 1, 4),
        lw(5, 1, 4),
        sw(3, 1, 0xFF8),  # -8
        lw(20, 1, 0xFF8),
        END,
    ],
    # bne loop 0..10, x20==10
    "t36_bne_loop10": [
        addi(20, 0, 0),
        addi(2, 0, 10),
        addi(20, 20, 1),  # L0
        bne(20, 2, -4),
        END,
    ],
    # two beq not taken (unequal regs) then success
    "t37_beq_fallthrough2": [
        addi(1, 0, 1),
        addi(2, 0, 2),
        beq(1, 2, 8),
        beq(2, 1, 8),
        addi(20, 0, 0x3D),
        END,
    ],
    # 0 - 0x80000000 == 0x80000000
    "t38_sub_from_zero": [
        addi(1, 0, 1),
        addi(2, 0, 31),
        sll(3, 1, 2),
        sub(20, 0, 3),
        END,
    ],
}


def main():
    import pathlib

    root = pathlib.Path(__file__).resolve().parent
    for stem, words in PROGRAMS.items():
        path = root / f"{stem}.hex"
        path.write_text("\n".join(f"{w:08x}" for w in words) + "\n", encoding="ascii")
        print("wrote", path.name, len(words), "words")


if __name__ == "__main__":
    main()
