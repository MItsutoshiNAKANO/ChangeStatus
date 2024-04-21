MERGE INTO tickets
USING (SELECT
    ? AS id, ? AS subject, ? AS reporter, ? AS address, ? AS status,
    ? AS description, ? AS creator, ? AS updater
) AS tmp
ON tickets.id = tmp.id
WHEN MATCHED THEN
    UPDATE SET
        tickets.subject = COALESCE(tmp.subject, tickets.subject),
        tickets.reporter = COALESCE(tmp.reporter, tickets.reporter),
        tickets.address = COALESCE(tmp.address, tickets.address),
        tickets.status = COALESCE(tmp.status, tickets.status),
        tickets.description = COALESCE(tmp.description, tickets.description),
        tickets.updater = COALESCE(tmp.updater, tickets.updater),
        tickets.update_at = CURRENT_TIMESTAMP
WHEN NOT MATCHED THEN
    INSERT (
        id, subject, reporter, address, status,
        description, creator, updater
    ) VALUES (
        tmp.id, tmp.subject, tmp.reporter, tmp.address, tmp.status,
        tmp.description, tmp.creator, tmp.updater)
;
