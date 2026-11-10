-- ============================================================================
-- Lab Results Report — reporting module SQL dataset.
-- Parameters@ @startDate, @endDate, @location, @concept
--
-- @concept filters "Exam Ordered" (ods.concept_id) by exact match only —
-- orders are returned only when ods.concept_id = @concept.
-- Leaving @concept NULL disables the filter entirely.
--
-- A manual-test mirror of this file (with @startDate/@endDate/@location/
-- @concept replaced by literal NULL so it can be run directly in the mysql
-- CLI) lives alongside it as lab_results_reports_manual_test.sql.
-- ============================================================================

SELECT
    pi.identifier                                                           AS 'Identifier',
    pn.family_name                                                          AS 'Family Name',
    pn.given_name                                                           AS 'Given Name',
    TIMESTAMPDIFF(YEAR, p.birthdate, ods.date_activated)                   AS 'Age',
    p.gender                                                                AS 'Gender',
    l.name                                                                  AS 'Patient Location',
    rl.name                                                                 AS 'Result Done At',
    DATE_FORMAT(ods.date_activated,  '%Y-%m-%d %H@%i')                           AS 'Order Date',
    ods.accession_number                                                    AS 'Sample Code',
    (
        SELECT ob.value_text
        FROM obs ob
        WHERE ob.order_id = ods.order_id
          AND ob.voided   = 0
          AND ob.value_text LIKE 'ORD-%'
        ORDER BY ob.obs_id
        LIMIT 1
    )                                                                       AS 'Order Number',

DATE_FORMAT(specimen.specimen_received_datetime, '%Y-%m-%d %H@%i')        AS 'Specimen Received Date',

    DATE_FORMAT(o.date_created,      '%Y-%m-%d %H@%i')                     AS 'Date of Result',

    CASE
        WHEN specimen.specimen_received_datetime IS NULL OR o.date_created IS NULL THEN NULL
        WHEN o.date_created < specimen.specimen_received_datetime THEN NULL
        ELSE CONCAT_WS(
            ' ',
            IF(
                FLOOR(TIMESTAMPDIFF(MINUTE, specimen.specimen_received_datetime, o.date_created) / 1440) > 0,
                CONCAT(FLOOR(TIMESTAMPDIFF(MINUTE, specimen.specimen_received_datetime, o.date_created) / 1440), 'd'),
                NULL
            ),
            CONCAT(FLOOR(MOD(TIMESTAMPDIFF(MINUTE, specimen.specimen_received_datetime, o.date_created), 1440) / 60), 'h'),
            CONCAT(MOD(TIMESTAMPDIFF(MINUTE, specimen.specimen_received_datetime, o.date_created), 60), 'm')
        )
    END                                                                     AS 'Time Spent',

    CASE
        WHEN ods.date_activated IS NULL OR o.date_created IS NULL THEN NULL
        WHEN o.date_created < ods.date_activated THEN NULL
        ELSE CONCAT_WS(
            ' ',
            IF(
                FLOOR(TIMESTAMPDIFF(MINUTE, ods.date_activated, o.date_created) / 1440) > 0,
                CONCAT(FLOOR(TIMESTAMPDIFF(MINUTE, ods.date_activated, o.date_created) / 1440), 'd'),
                NULL
            ),
            CONCAT(FLOOR(MOD(TIMESTAMPDIFF(MINUTE, ods.date_activated, o.date_created), 1440) / 60), 'h'),
            CONCAT(MOD(TIMESTAMPDIFF(MINUTE, ods.date_activated, o.date_created), 60), 'm')
        )
    END                                                                     AS 'order_to_result_time',

    cn_order.name                                                          AS 'Exam Ordered',
    COALESCE(cn_component.name, cn_order.name)                             AS 'Test Name',
    CASE
        WHEN o.obs_id IS NULL THEN 'Pending'
        ELSE CONCAT_WS(
            ', ',
            cn_result.name,
            IF(o.value_numeric IS NOT NULL, CAST(o.value_numeric AS CHAR), NULL),
            o.value_text
        )
    END                                                                     AS 'Result',
    COALESCE(
        CONCAT(prov_name.given_name, ' ', prov_name.family_name),
        '(No Provider)'
    )                                                                       AS 'Ordered By',
    COALESCE(
        CONCAT(result_user_name.given_name, ' ', result_user_name.family_name),
        '(Unknown User)'
    )                                                                       AS 'Result Entered By'

FROM orders ods


LEFT JOIN obs o
    ON  o.order_id = ods.order_id
    AND o.voided   = 0
    AND (
          o.value_numeric IS NOT NULL
       OR o.value_coded   IS NOT NULL
       OR (o.value_text IS NOT NULL AND o.value_text NOT LIKE 'ORD-%')
        )


LEFT JOIN patient_identifier pi
    ON  pi.patient_id = ods.patient_id
    AND pi.voided     = 0
    AND pi.patient_identifier_id = (
        SELECT MIN(pi2.patient_identifier_id)
        FROM patient_identifier pi2
        WHERE pi2.patient_id = ods.patient_id
          AND pi2.voided     = 0
    )


LEFT JOIN person_name pn
    ON  pn.person_id    = ods.patient_id
    AND pn.voided       = 0
    AND pn.person_name_id = (
        SELECT MIN(pn2.person_name_id)
        FROM person_name pn2
        WHERE pn2.person_id = ods.patient_id
          AND pn2.voided    = 0
    )


LEFT JOIN person p
    ON  p.person_id = ods.patient_id
    AND p.voided    = 0

LEFT JOIN person_attribute pa
    ON  pa.person_id               = ods.patient_id
    AND pa.person_attribute_type_id = (
        SELECT person_attribute_type_id
        FROM person_attribute_type
        WHERE name LIKE '%Health%Facility%'
           OR name LIKE '%healthcenter%'
           OR name LIKE '%Location%'
        ORDER BY person_attribute_type_id ASC
        LIMIT 1
    )
    AND pa.voided                  = 0
LEFT JOIN location l
    ON  l.location_id = pa.value

LEFT JOIN location rl
    ON  rl.location_id = o.location_id


-- Computed once here (instead of repeating the correlated subquery in the
-- SELECT list) so both 'Specimen Received Date' and 'Time Spent' can
-- reference the same value.
LEFT JOIN LATERAL (
    SELECT sr.obs_datetime AS specimen_received_datetime
    FROM obs sr
    JOIN obs onum
        ON  onum.encounter_id = sr.encounter_id
        AND onum.voided       = 0
        AND onum.value_text LIKE 'ORD-%'
        AND onum.order_id     = ods.order_id
    WHERE sr.concept_id = 167080
      AND sr.voided     = 0
    LIMIT 1
) specimen ON TRUE


-- Order-level concept name (the panel or single test as ordered).
-- Used as a fallback Test Name for pending orders that have no obs yet.
LEFT JOIN concept_name cn_order
    ON  cn_order.concept_id = ods.concept_id
    AND cn_order.voided     = 0
    AND cn_order.concept_name_id = (
        SELECT MIN(cn2.concept_name_id)
        FROM concept_name cn2
        WHERE cn2.concept_id = ods.concept_id
          AND cn2.voided     = 0
    )


-- Component-level concept name (the specific item this obs measured, e.g.
-- Hemoglobin within a CBC panel). This is what makes each panel component
-- show up as its own row with its own correct name.
LEFT JOIN concept_name cn_component
    ON  cn_component.concept_id = o.concept_id
    AND cn_component.voided     = 0
    AND cn_component.concept_name_id = (
        SELECT MIN(cn2.concept_name_id)
        FROM concept_name cn2
        WHERE cn2.concept_id = o.concept_id
          AND cn2.voided     = 0
    )


-- Coded-answer concept name (e.g. "Positive"/"Negative"), used inside the
-- Result column, not the Test Name column.
LEFT JOIN concept_name cn_result
    ON  cn_result.concept_id = o.value_coded
    AND cn_result.voided     = 0
    AND cn_result.concept_name_id = (
        SELECT MIN(cn2.concept_name_id)
        FROM concept_name cn2
        WHERE cn2.concept_id = o.value_coded
          AND cn2.voided     = 0
    )

LEFT JOIN provider prov
    ON  prov.provider_id = ods.orderer
    AND prov.retired     = 0
LEFT JOIN person_name prov_name
    ON  prov_name.person_id    = prov.person_id
    AND prov_name.voided       = 0
    AND prov_name.person_name_id = (
        SELECT MIN(pn3.person_name_id)
        FROM person_name pn3
        WHERE pn3.person_id = prov.person_id
          AND pn3.voided    = 0
    )


LEFT JOIN users result_user
    ON  result_user.user_id = o.creator
LEFT JOIN person_name result_user_name
    ON  result_user_name.person_id    = result_user.person_id
    AND result_user_name.voided       = 0
    AND result_user_name.person_name_id = (
        SELECT MIN(run2.person_name_id)
        FROM person_name run2
        WHERE run2.person_id = result_user.person_id
          AND run2.voided    = 0
    )

WHERE ods.order_type_id = (
        SELECT order_type_id
        FROM order_type
        WHERE name LIKE '%Lab%' OR name LIKE '%Test%'
        ORDER BY order_type_id ASC
        LIMIT 1
    )
  AND COALESCE(o.obs_datetime, ods.date_activated) >= COALESCE(@startDate, DATE_SUB(CURDATE(), INTERVAL 12 MONTH))
  AND COALESCE(o.obs_datetime, ods.date_activated) <  DATE_ADD(COALESCE(@endDate, CURDATE()), INTERVAL 1 DAY)
  AND ods.voided        = 0
  AND (@location IS NULL OR o.location_id  = @location)
  AND (@concept IS NULL OR ods.concept_id = @concept)

ORDER BY
    ods.date_activated DESC,
    o.obs_datetime     DESC
;
