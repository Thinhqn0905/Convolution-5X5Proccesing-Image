$ErrorActionPreference = 'Stop'

Push-Location "$PSScriptRoot\..\tb"
try {
    iverilog -g2012 -Wall -o ..\sim\sim.vvp ..\src\top_convolution.sv ..\src\line_buffer_4.sv ..\src\kernel_loader.sv ..\src\mac_array_25x3.sv ..\src\pipeline_stage.sv tb_convolution.sv
    if ($LASTEXITCODE -ne 0) {
        throw "iverilog compile failed"
    }

    vvp ..\sim\sim.vvp
    if ($LASTEXITCODE -ne 0) {
        throw "vvp simulation failed"
    }

    Write-Host "Simulation completed. VCD: ..\sim\dump.vcd"
} finally {
    Pop-Location
}
