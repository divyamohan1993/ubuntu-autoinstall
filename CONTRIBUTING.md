# Contributing

Thanks for your interest in contributing to this Ubuntu autoinstall configuration.

## How to contribute

1. **Fork** this repository
2. **Create a branch** for your change: `git checkout -b my-change`
3. **Make your changes** and test them if possible
4. **Submit a Pull Request** with a clear description

## What to contribute

- Bug fixes (broken package names, typos, script errors)
- New on-demand categories for `on-demand-install.sh`
- Support for newer Ubuntu versions (26.04 LTS, etc.)
- Documentation improvements
- Sysctl tuning improvements with benchmarks

## Guidelines

- Keep the base install lean — new packages belong in `on-demand-install.sh` unless they're essential for a development environment
- Test your changes on a fresh Ubuntu install if possible
- Update `README.md` if you add/remove packages or change system settings
- Update `CHANGELOG.md` with your changes

## Testing

The easiest way to test is in a VM:

```bash
# Using QEMU/KVM
qemu-img create -f qcow2 test-disk.qcow2 250G
qemu-system-x86_64 -m 4G -smp 2 -enable-kvm \
  -drive file=test-disk.qcow2,format=qcow2 \
  -cdrom ubuntu-24.04-live-server-amd64.iso \
  -boot d -nic user
```

## Reporting issues

Open a [GitHub Issue](https://github.com/divyamohan1993/ubuntu-autoinstall/issues) with:
- What you expected to happen
- What actually happened
- Output from `/var/log/post-install.log` if relevant
