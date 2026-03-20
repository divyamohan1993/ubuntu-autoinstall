# Security Policy

## Default credentials

This repository ships with **intentionally public default credentials**:

- **Username:** `dmj`
- **Password:** `dmj`

The password hash in `autoinstall.yaml` is SHA-512 but the plaintext is documented in the file.

**You MUST change the password immediately after installation:**

```bash
sudo passwd dmj
```

A login banner will remind you on every login until you remove it.

## What this setup does to your system

This autoinstall configuration makes the following security-relevant changes:

1. **Enables SSH with password authentication** — change password and consider switching to key-based auth
2. **Sets `kernel.apparmor_restrict_unprivileged_userns = 0`** — required for Edge/Chromium sandbox and container runtimes, but relaxes a kernel hardening measure
3. **Creates a custom AppArmor profile for Edge** — grants `userns` permission to the Edge binary
4. **Adds user to docker group** — effectively grants root-equivalent access to the `dmj` user via Docker
5. **Sets `vm.overcommit_memory = 1`** (in ml-performance config) — allows overcommitting memory, which is overridden to `0` by the performance config

All changes are fully documented in the [README](README.md#system-settings-changed).

## Reporting a vulnerability

If you find a security issue in these scripts, please open a [GitHub Issue](https://github.com/divyamohan1993/ubuntu-autoinstall/issues).

This is a personal configuration tool, not production infrastructure. There is no formal security response process.

## Recommendations for production use

If you adapt this for production or shared systems:

1. Generate a unique password hash: `openssl passwd -6 'strong-random-password'`
2. Disable SSH password auth → use key-based authentication only
3. Remove the user from the docker group → use `sudo` for Docker
4. Review all sysctl settings against your security requirements
5. Consider re-enabling `kernel.apparmor_restrict_unprivileged_userns = 1` if you don't use Edge
