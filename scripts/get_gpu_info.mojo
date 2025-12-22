from gpu.host.device_context import DeviceContext
from gpu.host.info import _accelerator_arch

fn main():
    # Materialize the comptime default device info (works on Apple Silicon)
    print(_accelerator_arch())
    info = materialize[DeviceContext.default_device_info]()

    print("Detected GPU:", info.name)
    print("Arch:", info.arch_name)
    print("Vendor:", info.vendor)
    print("API:", info.api)
    print("SM count (GPU cores):", info.sm_count)
    print("Compute (Metal version):", info.compute)
