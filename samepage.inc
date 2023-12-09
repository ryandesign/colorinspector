; SPDX-FileCopyrightText: © 2023 Ryan Carsten Schmidt <https://github.com/ryandesign>
; SPDX-License-Identifier: MIT

;warn if branch crosses page boundary
.macro samepage inst, addr
    inst addr
    .assert >addr = >*, warning, "branch crosses page boundary"
.endmacro
