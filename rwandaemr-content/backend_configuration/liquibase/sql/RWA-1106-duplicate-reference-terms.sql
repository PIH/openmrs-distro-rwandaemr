-- RWA-1106: some (source, code) pairs exist as several identical reference terms, from repeated OCL imports.
-- The ocl domain then fails ("Found multiple reference terms with the code ... in concept source ...").
-- Merge each group onto the unretired term with the lowest id (or the lowest id if all are retired):
-- repoint concept, drug and term-to-term maps, delete maps that became exact repeats (keeping the lowest id),
-- then delete the extra terms.
CREATE TEMPORARY TABLE rwa1106_term_keep AS
SELECT t.concept_reference_term_id AS dup_id, k.keep_id
  FROM concept_reference_term t
  JOIN (SELECT concept_source_id, code,
               COALESCE(MIN(CASE WHEN retired = 0 THEN concept_reference_term_id END),
                        MIN(concept_reference_term_id)) AS keep_id
          FROM concept_reference_term
         GROUP BY concept_source_id, code
        HAVING COUNT(*) > 1) k
    ON k.concept_source_id = t.concept_source_id AND k.code = t.code
 WHERE t.concept_reference_term_id <> k.keep_id;

UPDATE concept_reference_map m JOIN rwa1106_term_keep x ON x.dup_id = m.concept_reference_term_id
   SET m.concept_reference_term_id = x.keep_id;
UPDATE drug_reference_map m JOIN rwa1106_term_keep x ON x.dup_id = m.term_id
   SET m.term_id = x.keep_id;
UPDATE concept_reference_term_map m JOIN rwa1106_term_keep x ON x.dup_id = m.term_a_id
   SET m.term_a_id = x.keep_id;
UPDATE concept_reference_term_map m JOIN rwa1106_term_keep x ON x.dup_id = m.term_b_id
   SET m.term_b_id = x.keep_id;

DELETE m FROM concept_reference_map m
  JOIN (SELECT concept_id, concept_reference_term_id, concept_map_type_id, MIN(concept_map_id) AS keep_id
          FROM concept_reference_map
         GROUP BY concept_id, concept_reference_term_id, concept_map_type_id
        HAVING COUNT(*) > 1) d
    ON d.concept_id = m.concept_id AND d.concept_reference_term_id = m.concept_reference_term_id
   AND d.concept_map_type_id = m.concept_map_type_id
 WHERE m.concept_map_id <> d.keep_id;

DELETE m FROM drug_reference_map m
  JOIN (SELECT drug_id, term_id, concept_map_type, MIN(drug_reference_map_id) AS keep_id
          FROM drug_reference_map
         GROUP BY drug_id, term_id, concept_map_type
        HAVING COUNT(*) > 1) d
    ON d.drug_id = m.drug_id AND d.term_id = m.term_id AND d.concept_map_type = m.concept_map_type
 WHERE m.drug_reference_map_id <> d.keep_id;

DELETE m FROM concept_reference_term_map m
  JOIN (SELECT term_a_id, term_b_id, a_is_to_b_id, MIN(concept_reference_term_map_id) AS keep_id
          FROM concept_reference_term_map
         GROUP BY term_a_id, term_b_id, a_is_to_b_id
        HAVING COUNT(*) > 1) d
    ON d.term_a_id = m.term_a_id AND d.term_b_id = m.term_b_id AND d.a_is_to_b_id = m.a_is_to_b_id
 WHERE m.concept_reference_term_map_id <> d.keep_id;

DELETE t FROM concept_reference_term t JOIN rwa1106_term_keep x ON x.dup_id = t.concept_reference_term_id;

DROP TEMPORARY TABLE rwa1106_term_keep;
