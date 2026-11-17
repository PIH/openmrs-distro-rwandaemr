-- RWA-1106: concept "Preliminary" (b3fa7102-0135-40bb-b3c3-633450598623) is mapped to PIH 6249 and PIH PRELIMINARY
-- both NARROWER-THAN (2010) and SAME-AS (an OCL import, 2026-09-30). PIH_IMBEMR.zip defines SAME-AS, and
-- re-importing it fails ("Cannot map a reference term multiple times to the same concept").
-- Delete the NARROWER-THAN maps where a SAME-AS map to the same term exists, change the rest to SAME-AS,
-- then delete any maps to the same term that this leaves repeated (keeping the lowest id).
DELETE m FROM concept_reference_map m
  JOIN concept c ON c.concept_id = m.concept_id
  JOIN concept_map_type t ON t.concept_map_type_id = m.concept_map_type_id
  JOIN concept_reference_term rt ON rt.concept_reference_term_id = m.concept_reference_term_id
  JOIN concept_reference_source s ON s.concept_source_id = rt.concept_source_id
  JOIN (SELECT DISTINCT m2.concept_id, m2.concept_reference_term_id
          FROM concept_reference_map m2
          JOIN concept_map_type t2 ON t2.concept_map_type_id = m2.concept_map_type_id
         WHERE t2.name = 'SAME-AS') same
    ON same.concept_id = m.concept_id AND same.concept_reference_term_id = m.concept_reference_term_id
 WHERE c.uuid = 'b3fa7102-0135-40bb-b3c3-633450598623' AND t.name = 'NARROWER-THAN'
   AND s.name = 'PIH' AND rt.code IN ('6249', 'PRELIMINARY');

UPDATE concept_reference_map m
  JOIN concept c ON c.concept_id = m.concept_id
  JOIN concept_map_type t ON t.concept_map_type_id = m.concept_map_type_id
  JOIN concept_reference_term rt ON rt.concept_reference_term_id = m.concept_reference_term_id
  JOIN concept_reference_source s ON s.concept_source_id = rt.concept_source_id
   SET m.concept_map_type_id = (SELECT concept_map_type_id FROM concept_map_type WHERE name = 'SAME-AS'),
       m.changed_by = (SELECT user_id FROM users WHERE system_id = 'admin'), m.date_changed = NOW()
 WHERE c.uuid = 'b3fa7102-0135-40bb-b3c3-633450598623' AND t.name = 'NARROWER-THAN'
   AND s.name = 'PIH' AND rt.code IN ('6249', 'PRELIMINARY');

DELETE m FROM concept_reference_map m
  JOIN concept c ON c.concept_id = m.concept_id
  JOIN (SELECT concept_id, concept_reference_term_id, MIN(concept_map_id) AS keep_id
          FROM concept_reference_map
         GROUP BY concept_id, concept_reference_term_id
        HAVING COUNT(*) > 1) d
    ON d.concept_id = m.concept_id AND d.concept_reference_term_id = m.concept_reference_term_id
 WHERE c.uuid = 'b3fa7102-0135-40bb-b3c3-633450598623' AND m.concept_map_id <> d.keep_id;
