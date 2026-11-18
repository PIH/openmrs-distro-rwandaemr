-- RWA-1127: on a new database, core creates its four default relationship types with core's UUIDs, and
-- relationshipTypes.csv defines the same types under other UUIDs, so Initializer can't save them. Delete core's
-- rows where nothing uses them, and let Initializer create the types from relationshipTypes.csv.
DELETE FROM relationship_type
 WHERE uuid IN ('8d919b58-c2cc-11de-8d13-0010c6dffd0f', '8d91a01c-c2cc-11de-8d13-0010c6dffd0f',
                '8d91a210-c2cc-11de-8d13-0010c6dffd0f', '8d91a3dc-c2cc-11de-8d13-0010c6dffd0f')
   AND NOT EXISTS (SELECT 1 FROM relationship r WHERE r.relationship = relationship_type.relationship_type_id);
