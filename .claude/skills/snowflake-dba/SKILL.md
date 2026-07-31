---
name: snowflake-dba
description: This skill provides general guidance and best practices to guide AI agents in performing Snowflake DBA tasks effectively and efficiently. It covers a range of topics including database design, performance optimization, security management, and troubleshooting.
---

# Snowflake DBA Skill

## Purpose
The Snowflake DBA skill is designed to equip AI agents with the knowledge and best practices necessary to perform database administration tasks in Snowflake effectively. This skill covers a wide range of topics including database design, performance optimization, security management, and troubleshooting.

## Role Hierarchy Guidance
To reduce administrative burden and improve permission transparency, keep account-level role hierarchies minimal or avoid them entirely.

Complex role hierarchies can obscure effective permissions and make audits, troubleshooting, and least-privilege enforcement harder. Prefer a flatter role model at the account-role level, and grant most object access through database roles with direct grants.

When designing access patterns:
- Keep account-role inheritance as flat as practical.
- Avoid deep chains of role-to-role grants.
- Grant permissions directly via database roles whenever possible.
- Use account roles primarily for aggregation and assignment boundaries, not deep inheritance trees.

Exceptions
- All roles will be granted to the DB_OWNER role so that users with the DB_OWNER role can easily see all permissions and access patterns in the account. This is a best practice for transparency and ease of management.
