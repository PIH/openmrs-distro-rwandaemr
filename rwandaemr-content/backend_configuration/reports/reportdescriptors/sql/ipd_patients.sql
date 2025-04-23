SELECT
    v.patient_id AS Patient_ID,
    (SELECT pi.identifier
     FROM patient_identifier pi
     WHERE pi.patient_id = v.patient_id
       AND pi.identifier_type = 8
       AND pi.voided = 0
       AND pi.preferred = 1
     LIMIT 1) AS Identifier,
    (SELECT CONCAT(pn.family_name, " ", pn.given_name)
     FROM person_name pn
     WHERE pn.person_id = v.patient_id
       AND pn.voided = 0
     LIMIT 1) AS Names,
    (SELECT ad.admission_date
     FROM moh_bill_admission ad
     JOIN moh_bill_insurance_policy ip
       ON ad.insurance_policy_id = ip.insurance_policy_id
     WHERE ip.owner = v.patient_id
     ORDER BY ad.admission_date DESC
     LIMIT 1) AS Billing_admission_date,
    (SELECT dp.name
     FROM moh_bill_admission ad
     JOIN moh_bill_insurance_policy ip
       ON ad.insurance_policy_id = ip.insurance_policy_id
     JOIN moh_bill_global_bill gb
       ON ad.admission_id = gb.admission_id
     JOIN moh_bill_consommation co
       ON gb.global_bill_id = co.global_bill_id
     JOIN moh_bill_department dp
       ON co.department_id = dp.department_id
     WHERE ip.owner = v.patient_id
     ORDER BY ad.admission_date DESC
     LIMIT 1) AS Billing_Department,
    (SELECT CONCAT(e.encounter_datetime, "@",
                   (SELECT name
                    FROM concept_name cn
                    WHERE cn.concept_id = o.value_coded
                    LIMIT 1))
     FROM encounter e
     JOIN obs o ON e.encounter_id = o.encounter_id
     WHERE e.form_id = 352
       AND e.voided = 0
       AND o.concept_id = 124057
       AND e.patient_id = v.patient_id
     ORDER BY e.encounter_datetime DESC
     LIMIT 1) AS 'admission_date@Department',
    (SELECT o.value_numeric
     FROM encounter e
     JOIN obs o ON e.encounter_id = o.encounter_id
     WHERE e.form_id = 352
       AND e.voided = 0
       AND o.concept_id = 1324
       AND e.patient_id = v.patient_id
     ORDER BY e.encounter_datetime DESC
     LIMIT 1) AS 'Ward Number',
    (SELECT o.value_numeric
     FROM encounter e
     JOIN obs o ON e.encounter_id = o.encounter_id
     WHERE e.form_id = 352
       AND e.voided = 0
       AND o.concept_id = 165190
       AND e.patient_id = v.patient_id
     ORDER BY e.encounter_datetime DESC
     LIMIT 1) AS 'Bed Number'
FROM visit v
WHERE v.date_stopped IS NULL
  AND v.visit_id IN (
      SELECT visit_id
      FROM encounter
      WHERE form_id IN (447, 409, 308, 369, 364, 352, 101)
        AND DATEDIFF(NOW(), date_created) <= 2
  )
  AND v.date_stopped IS NULL;
