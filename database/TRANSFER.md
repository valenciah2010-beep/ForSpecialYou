# Database Transfer Guide

This project uses a MySQL database named `care_portal`.

## 1. Export From The Old Computer

On the old computer, run:

```bash
/usr/local/mysql/bin/mysqldump -h 127.0.0.1 -P 3306 -u root -p --databases care_portal --routines --triggers --single-transaction > ~/Desktop/care_portal_backup.sql
```

When prompted, enter the old computer's MySQL password.

Copy `~/Desktop/care_portal_backup.sql` to the new computer. A good destination is:

```text
/Users/valenciahuang/Desktop/DemoProject/database/care_portal_backup.sql
```

## 2. Start MySQL On The New Computer

On the new computer, run:

```bash
sudo /usr/local/mysql/support-files/mysql.server start
```

## 3. Import On The New Computer

From this project folder, run:

```bash
/usr/local/mysql/bin/mysql -h 127.0.0.1 -P 3306 -u root -p < database/care_portal_backup.sql
```

When prompted, enter the new computer's MySQL password.

## 4. Verify The Import

Run:

```bash
/usr/local/mysql/bin/mysql -h 127.0.0.1 -P 3306 -u root -p -e "USE care_portal; SELECT id, username, email, role, created_at FROM users ORDER BY created_at DESC LIMIT 10;"
```

## 5. Run The App

Backend:

```bash
npm run server
```

Frontend:

```bash
npm run dev
```

