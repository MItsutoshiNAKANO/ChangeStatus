CREATE TABLE tickets (
    id INTEGER,
    subject VARCHAR(997) NOT NULL,
    affiliation VARCHAR(126),
    pronunciation_for_affiliation VARCHAR(126),
    abbreviation_for_affiliation VARCHAR(126),
    reporter VARCHAR(126) NOT NULL,
    pronunciation_for_reporter VARCHAR(126),
    address VARCHAR(126) NOT NULL,
    pronunciation_for_address VARCHAR(126),
    found_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    report_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_modified_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    closed_at TIMESTAMP,
    status VARCHAR(126) NOT NULL,
    description VARCHAR(10485760) NOT NULL,
    results VARCHAR(10485760),
    creator VARCHAR(126) NOT NULL,
    updater VARCHAR(126) NOT NULL,
    create_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    update_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
);

CREATE ROLE apache PASSWORD 'vagrant' LOGIN;
GRANT SELECT, INSERT, UPDATE ON tickets TO apache;
