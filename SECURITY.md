# Security Policy

Nivora handles sensitive personal health information. This document describes how to report security concerns and the limits of the repository's current security posture.

## Reporting a vulnerability

Please do not publish secrets, private health data, exploit details, or a working proof of concept in a public issue. Report a suspected vulnerability privately to the repository maintainers through the contact method configured in the GitHub repository. Include the affected component, the commit or release where it was observed, reproduction steps, and the potential impact. Remove real health data from logs and examples.

If the repository does not expose a private security contact, open a minimal issue asking the maintainer to provide one without including sensitive technical details. The maintainer should then move the discussion to a private channel.

## Scope

The most security-sensitive areas are:

- backup encryption and restore validation;
- local database access and migration behavior;
- biometric authentication and lifecycle masking;
- Android and iOS platform permissions;
- notification content and scheduling; and
- PDF export, sharing, and file-picker integration.

## Current security posture

The reviewed source stores application records locally in Drift and SQLite. The Android release manifest disables Android cloud backup. Backup V2 derives a key with PBKDF2 and uses AES-256-GCM with an authentication tag. The operational database itself is standard SQLite and is not SQLCipher-encrypted. Device sandboxing and operating-system storage protection are therefore part of the at-rest protection model.

No security audit, regulatory certification, HIPAA compliance, GDPR compliance, or clinical validation is claimed. Physical-device testing is still required for biometric prompts, app-switcher masking, notifications, file import, and platform-specific storage behavior.

## Safe handling when contributing

Do not commit API keys, signing credentials, keystores, exported backups, real health records, device identifiers, or diagnostic logs containing personal data. Use synthetic fixtures in tests and redact issue reports before submission.

Changes to backup formats, database migrations, authentication, permissions, or data deletion should include focused tests and a documentation update. Review the release-readiness documents before treating a feature as validated on a physical device.
