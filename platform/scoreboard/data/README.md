# Hash Database

This directory contains `hashes.db` - a SQLite database for hash lookup fallback (Hop 9).

## Schema

```sql
CREATE TABLE hashes (
    hash TEXT PRIMARY KEY,
    algorithm TEXT NOT NULL,
    plaintext TEXT NOT NULL
);

CREATE INDEX idx_hash ON hashes(hash);
```

## Sample Population

```sql
-- MD5 examples
INSERT INTO hashes VALUES ('5f4dcc3b5aa765d61d8327deb882cf99', 'MD5', 'password');
INSERT INTO hashes VALUES ('098f6bcd4621d373cade4e832627b4f6', 'MD5', 'test');

-- SHA1 examples
INSERT INTO hashes VALUES ('5baa61e4c9b93f3f0682250b6cf8331b7ee68fd8', 'SHA1', 'password');

-- SHA256 examples
INSERT INTO hashes VALUES ('5e884898da28047151d0e56f8dc6292773603d0d6aabbdd62a11ef721d1542d8', 'SHA256', 'password');
```

The hash for Hop 9 (VAULT) must be present in this database to ensure the lab is self-contained.

Players are encouraged to try online lookup first (CrackStation, hashes.org), but this local fallback ensures offline functionality.
