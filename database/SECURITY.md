# Database security, backup and recovery

Written for the KISII_LIBRARY database (workbook sub-teams D8 and D9).

## 1. Who can do what (least privilege)

Nobody should connect with `root` except the person who administers the database. Each part of the system gets its own user, and each user gets only what it needs.

| User | Used by | Can do | Cannot do |
|---|---|---|---|
| `root` | You, as administrator | Everything | (do not use it in the app) |
| `library_app` | The backend | Read, add, change and delete rows | Create, alter or drop tables, read other databases |
| `library_readonly` | Reports and AI features | Read rows and views | Add, change or delete anything |
| `library_backup` | The backup script | Read everything it needs to copy | Change anything |

Create them once with `database/migrations/008_app_users.sql`. The passwords are typed into the MySQL client and are never saved in the file.

## 2. Secrets (passwords and keys)

- **Never commit a password, key or `.env` file to GitHub.** Anything pushed to GitHub stays in its history, even if you delete it later.
- The `.gitignore` in this repository already ignores `.env`, `*.cnf`, `*.pem`, `*.key` and the `backups/` folder.
- Keep the backend's database settings in a `.env` file on your computer (host, user, password, database). Commit only a `.env.example` with the names and no real values.
- Use a different strong password for each database user. Do not reuse your root password.
- If a password is ever pushed by accident, **change it straight away**. Deleting the file is not enough.

## 3. Encrypted connections (SSL/TLS)

- On your own computer, the database and the app talk inside the same machine, so encryption is not needed.
- **On a hosted database, always require encryption.** Create each user with `REQUIRE SSL` and connect with `--ssl-mode=REQUIRED`, or use the host's connection string, which usually has it switched on.
- To see whether your current connection is encrypted, run `SHOW STATUS LIKE 'Ssl_cipher';` in the MySQL client. A value means encrypted. An empty value means not encrypted.
- Always serve the API itself over HTTPS. Hosts such as Render and Railway provide this.

## 4. Backups

A backup is a copy of the whole database in one file. If something is deleted or the computer is lost, a backup brings it back.

**Take a backup**

```
bash database/backup/backup.sh
```

- It asks for the `library_backup` password and saves `backups/KISII_LIBRARY_<date>_<time>.sql`.
- The dump is written to a temporary file and only kept if it is complete, so a failed backup can never leave an empty file behind.
- It keeps the newest 7 backups and removes older ones.
- You type the password once, and it stays hidden.

**To avoid typing the password every time (optional):** create a file outside the repository, in your home folder:

```
cat > ~/.library_backup.cnf << 'EOT'
[client]
user=library_backup
password=PUT_THE_PASSWORD_HERE
EOT
```

The script uses it automatically. Never put this file inside the project folder.

**When to back up**

- Before every change to the database (a new migration, a big import).
- At least once a week while the project is active.
- Also export the sample database for GitHub, as before: `mysqldump -u root -p KISII_LIBRARY --result-file=database/KISII_LIBRARY.sql`. That export holds only made-up sample data, so it is safe to share. Real backups in `backups/` are not.

## 5. Recovery (getting the data back)

**Always practise first.** Prove that a backup really works before you need it:

```
bash database/backup/restore.sh --verify backups/KISII_LIBRARY_<date>_<time>.sql
```

It restores the backup into a temporary database, compares tables and rows with the live one, prints PASS or FAIL, and deletes the temporary copy. Your live database is not touched. (It will say FAIL if you changed data after the backup was taken. That is expected.)

**If you lose data**

1. Stop anything that writes to the database (the backend).
2. Pick the newest good backup in `backups/`.
3. Practise on a copy first: `bash database/backup/restore.sh backups/FILE.sql KISII_LIBRARY_PRACTICE`
4. Restore for real: `bash database/backup/restore.sh backups/FILE.sql`. It asks you to type YES, because it replaces the current tables.
5. Check the counts it prints, then start the backend again.

The restore script refuses empty or cut-off files, so a broken backup cannot overwrite a working database.

**What you can lose:** everything added after the last backup. Back up more often if the data changes often.

## 6. Who changed what

The change log (`audit_log`, migration 009) records who changed loans, fines and payments, and when. It does not record private details such as phone numbers. See `database/MONITORING.md`. The backend user `library_app` can in principle edit that log, because it has rights on the whole database. For stronger protection, grant it rights table by table and leave `audit_log` out.

## 7. Quick checklist

- [ ] `008_app_users.sql` run, and the backend uses `library_app` (not `root`)
- [ ] No passwords in any file in the repository
- [ ] `.env` and `backups/` are ignored by Git
- [ ] A backup was taken and `--verify` printed PASS
- [ ] The hosted database requires SSL
- [ ] Monitoring is on (see `MONITORING.md`)
