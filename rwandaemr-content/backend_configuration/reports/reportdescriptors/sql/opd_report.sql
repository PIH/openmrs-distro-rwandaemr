SELECT distinct
    person.person_id as PatientID, encounter.encounter_datetime, person_name.given_name, person_name.family_name, birthdate,
    floor(datediff(NOW(),birthdate)/365.25)as age, gender,
    treatment.value_text as treatment, case_status.case_status, concat(provider.given_name," ", provider.family_name) as provider,
    country,state_province as province,county_district as district, city_village as sector, address3 as cell, address1 as umudugudu,
    floor(datediff(encounter.encounter_datetime, birthdate)/365.25)as age_at_encounter, visit_type.concept_name as visit_type,
(SELECT concept_name as diagnosis
from obs
left join
(select      c.concept_id , cn.name as concept_name
from        concept c
left join   concept_name cn on c.concept_id = cn.concept_id
where       cn.concept_name_id = (
select    cn.concept_name_id
from      concept_name cn
where     cn.voided = 0
and       cn.concept_id = c.concept_id
order by  if(cn.concept_name_type = 'FULLY_SPECIFIED', 0, 1), if(cn.locale = 'en', 0, 1), cn.locale_preferred
limit 1
)
) diagnosis_name on diagnosis_name.concept_id=obs.value_coded
where obs.concept_id in (SELECT concept_id from concept where uuid="2dce81f9-3874-4247-b441-6369ca0725c2")
and obs.voided=0
and obs.obs_group_id is null
and value_coded is not null
and obs.encounter_id=encounter.encounter_id
order by diagnosis
LIMIT 0,1
) as primary_diagnosis,



(SELECT concept_name as diagnosis
from obs
left join
(select      c.concept_id , cn.name as concept_name
from        concept c
left join   concept_name cn on c.concept_id = cn.concept_id
where       cn.concept_name_id = (
select    cn.concept_name_id
from      concept_name cn
where     cn.voided = 0
and       cn.concept_id = c.concept_id
order by  if(cn.concept_name_type = 'FULLY_SPECIFIED', 0, 1), if(cn.locale = 'en', 0, 1), cn.locale_preferred
limit 1
)
) diagnosis_name on diagnosis_name.concept_id=obs.value_coded
where obs.concept_id in (SELECT concept_id from concept where uuid="afb8006f-e7c4-45bd-82bd-16f6e4b4b51d")
and obs.voided=0
and obs.obs_group_id is null
and value_coded is not null
and obs.encounter_id=encounter.encounter_id
order by diagnosis
LIMIT 0,1
) as secondary_diagnosis,


(SELECT concept_name as diagnosis
from obs
left join
(select      c.concept_id , cn.name as concept_name
from        concept c
left join   concept_name cn on c.concept_id = cn.concept_id
where       cn.concept_name_id = (
select    cn.concept_name_id
from      concept_name cn
where     cn.voided = 0
and       cn.concept_id = c.concept_id
order by  if(cn.concept_name_type = 'FULLY_SPECIFIED', 0, 1), if(cn.locale = 'en', 0, 1), cn.locale_preferred
limit 1
)
) diagnosis_name on diagnosis_name.concept_id=obs.value_coded
where obs.concept_id in (SELECT concept_id from concept where uuid="08dd5ecf-b381-47ea-a0f1-cd91a65505f7")
and obs.voided=0
and obs.obs_group_id is null
and value_coded is not null
and obs.encounter_id=encounter.encounter_id
order by diagnosis
LIMIT 0,1
) as Presumptive_diagnosis,


(
SELECT
if(a.is_admitted=0,"OPD","IPD") as admission_service
FROM moh_bill_admission a,moh_bill_insurance_policy ip where a.admission_date>= DATE_ADD(encounter.encounter_datetime, INTERVAL -1 DAY) and a.admission_date<= DATE_ADD(encounter.encounter_datetime, INTERVAL 1 DAY) and a.insurance_policy_id=ip.insurance_policy_id and a.voided=0 and ip.owner=encounter.patient_id order by a.admission_date limit 1
) as admission_service,

(
SELECT
 group_concat(i.name)
FROM moh_bill_admission a,moh_bill_insurance_policy ip,moh_bill_insurance i where a.admission_date>= DATE_ADD(encounter.encounter_datetime, INTERVAL -1 DAY) and a.admission_date<= DATE_ADD(encounter.encounter_datetime, INTERVAL 1 DAY) and a.insurance_policy_id=ip.insurance_policy_id and a.voided=0 and ip.owner=encounter.patient_id and ip.insurance_id=i.insurance_id  order by a.admission_date
) as Insurance,

(SELECT concept_name as dptm
from obs
left join
(select      c.concept_id , cn.name as concept_name
from        concept c
left join   concept_name cn on c.concept_id = cn.concept_id
where       cn.concept_name_id = (
select    cn.concept_name_id
from      concept_name cn
where     cn.voided = 0
and       cn.concept_id = c.concept_id
order by  if(cn.concept_name_type = 'FULLY_SPECIFIED', 0, 1), if(cn.locale = 'en', 0, 1), cn.locale_preferred
limit 1
)
) diagnosis_name on diagnosis_name.concept_id=obs.value_coded
where obs.concept_id=@department
and obs.voided=0
and obs.obs_group_id is null
and value_coded is not null
and obs.encounter_id=encounter.encounter_id
order by dptm
LIMIT 0,1
) as Department



from encounter
LEFT JOIN (SELECT * from person_name where voided=0) person_name on person_name.person_id=encounter.patient_id
LEFT JOIN person on person.person_id=encounter.patient_id
LEFT JOIN
(SELECT encounter_id, given_name, family_name from encounter_provider
LEFT JOIN provider on provider.provider_id=encounter_provider.provider_id
LEFT JOIN person_name on person_name.person_id=provider.person_id
WHERE person_name.voided=0
) provider on encounter.encounter_id=provider.encounter_id
LEFT JOIN (SELECT * from person_address where voided=0) person_address on person_address.person_id=person.person_id
LEFT JOIN (SELECT value_text, encounter_id from obs where concept_id=2881 and voided=0) treatment on treatment.encounter_id=encounter.encounter_id
LEFT JOIN
(SELECT concept_name as case_status, encounter_id
from obs
left join
(select      c.concept_id , cn.name as concept_name
from        concept c
left join   concept_name cn on c.concept_id = cn.concept_id
where       cn.concept_name_id = (
select    cn.concept_name_id
from      concept_name cn
where     cn.voided = 0
and       cn.concept_id = c.concept_id
order by  if(cn.concept_name_type = 'FULLY_SPECIFIED', 0, 1), if(cn.locale = 'en', 0, 1), cn.locale_preferred
limit 1
)
) case_status on case_status.concept_id=obs.value_coded
where obs.concept_id in (SELECT concept_id from concept where uuid="14183f94-59b2-4b62-bad7-2c788a21a422")
and obs.voided=0
) case_status on case_status.encounter_id=encounter.encounter_id
LEFT JOIN (SELECT obs_datetime, person_id, concept_name
from obs
left join
(select      c.concept_id , cn.name as concept_name
from        concept c
left join   concept_name cn on c.concept_id = cn.concept_id
where       cn.concept_name_id = (
select    cn.concept_name_id
from      concept_name cn
where     cn.voided = 0
and       cn.concept_id = c.concept_id
order by  if(cn.concept_name_type = 'FULLY_SPECIFIED', 0, 1), if(cn.locale = 'en', 0, 1), cn.locale_preferred
limit 1
)
) visit_type on visit_type.concept_id=obs.value_coded
where obs.concept_id in (SELECT concept_id from concept where uuid="2cda28df-2fe7-42e0-bb2f-376c9f803537")
and obs.voided=0
) visit_type on date(visit_type.obs_datetime)=encounter.encounter_datetime and visit_type.person_id=encounter.patient_id
WHERE encounter.form_id in (SELECT form_id from form where uuid in
 ("f46f025b-e68b-48d4-ae41-c2b271d4a80e")
)
and encounter.encounter_datetime>= @startDate
and encounter.encounter_datetime< DATE_ADD(@endDate, INTERVAL 1 DAY)
;