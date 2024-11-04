pub const capi = @cImport({
    @cInclude("SEGGER_RTT.h");
});

void seggerRttInit() void {
    capi.SEGGER_RTT_Init();
}
