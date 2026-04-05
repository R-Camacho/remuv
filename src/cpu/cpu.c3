module remuv::cpu;

struct Cpu
{
    ulong[32] registers;
    ulong pc;
    char[] mem;
}
