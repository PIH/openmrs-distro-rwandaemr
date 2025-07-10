SELECT 
    t.indicator,
    t.indicator_name,
    CASE 
        WHEN t.indicator = 'ANC1' THEN (SELECT COUNT(DISTINCT person_id)
            FROM obs
            WHERE concept_id IN (SELECT concept_id FROM concept WHERE uuid = 'bbe69d90-984d-40b4-9ab5-7fe758a58aaf')
            AND value_numeric = 1
            AND obs_datetime BETWEEN @startDate AND DATE_ADD(@endDate, INTERVAL 1 DAY)
            AND encounter_id IN (
                SELECT encounter_id
                FROM encounter e
                WHERE form_id = (
                    SELECT form_id
                    FROM form
                    WHERE uuid = '867408ee-3b46-46ee-951f-aa521c47ec0f'
                )
            ))
        WHEN t.indicator = 'ANC2' THEN (SELECT COUNT(DISTINCT o.person_id)
            FROM obs o
            JOIN person p ON o.person_id = p.person_id
            WHERE concept_id IN (SELECT concept_id FROM concept WHERE uuid = 'bbe69d90-984d-40b4-9ab5-7fe758a58aaf')
            AND value_numeric = 1
            AND obs_datetime BETWEEN @startDate AND DATE_ADD(@endDate, INTERVAL 1 DAY)
            AND encounter_id IN (
                SELECT encounter_id
                FROM encounter e
                WHERE form_id = (
                    SELECT form_id
                    FROM form
                    WHERE uuid = '867408ee-3b46-46ee-951f-aa521c47ec0f'
                )
            )
            AND TIMESTAMPDIFF(YEAR, p.birthdate, o.obs_datetime) < 14)
        WHEN t.indicator = 'ANC3' THEN (SELECT COUNT(DISTINCT o.person_id)
            FROM obs o
            JOIN person p ON o.person_id = p.person_id
            WHERE concept_id IN (SELECT concept_id FROM concept WHERE uuid = 'bbe69d90-984d-40b4-9ab5-7fe758a58aaf')
            AND value_numeric = 1
            AND obs_datetime BETWEEN @startDate AND DATE_ADD(@endDate, INTERVAL 1 DAY)
            AND encounter_id IN (
                SELECT encounter_id
                FROM encounter e
                WHERE form_id = (
                    SELECT form_id
                    FROM form
                    WHERE uuid = '867408ee-3b46-46ee-951f-aa521c47ec0f'
                )
            )
            AND TIMESTAMPDIFF(YEAR, p.birthdate, o.obs_datetime) BETWEEN 14 AND 17)
        WHEN t.indicator = 'ANC4' THEN (SELECT COUNT(DISTINCT o.person_id)
            FROM obs o
            JOIN person p ON o.person_id = p.person_id
            WHERE concept_id IN (SELECT concept_id FROM concept WHERE uuid = 'bbe69d90-984d-40b4-9ab5-7fe758a58aaf')
            AND value_numeric = 1
            AND obs_datetime BETWEEN @startDate AND DATE_ADD(@endDate, INTERVAL 1 DAY)
            AND encounter_id IN (
                SELECT encounter_id
                FROM encounter e
                WHERE form_id = (
                    SELECT form_id
                    FROM form
                    WHERE uuid = '867408ee-3b46-46ee-951f-aa521c47ec0f'
                )
            )
            AND TIMESTAMPDIFF(YEAR, p.birthdate, o.obs_datetime) BETWEEN 18 AND 19)
        WHEN t.indicator = 'ANC5' THEN (SELECT COUNT(DISTINCT person_id)
            FROM obs
            WHERE concept_id IN (SELECT concept_id FROM concept WHERE uuid = 'd616d705-6c11-4b7f-96ec-a8c7994a07bc')
            AND value_numeric <= 12
            AND encounter_id IN (
                SELECT encounter_id
                FROM obs
                WHERE concept_id IN (SELECT concept_id FROM concept WHERE uuid = 'bbe69d90-984d-40b4-9ab5-7fe758a58aaf')
                AND value_numeric = 1
                AND encounter_id IN (
                    SELECT encounter_id
                    FROM encounter
                    WHERE form_id = (
                        SELECT form_id
                        FROM form
                        WHERE uuid = '2a9c2299-2e93-4698-a4dd-75ac3a23f508'
                    )
                )
                AND obs_datetime BETWEEN @startDate AND DATE_ADD(@endDate, INTERVAL 1 DAY)
            ))
        WHEN t.indicator = 'ANC6' THEN (SELECT COUNT(DISTINCT o.person_id)
            FROM obs o
            JOIN encounter e ON o.encounter_id = e.encounter_id
            WHERE o.encounter_id IN (
                SELECT encounter_id
                FROM encounter
                WHERE form_id = (
                    SELECT form_id
                    FROM form
                    WHERE uuid = '2a9c2299-2e93-4698-a4dd-75ac3a23f508'
                )
            )
            AND o.concept_id IN (SELECT concept_id FROM concept WHERE uuid = '974d7f4b-4648-4bb5-8d32-397d27038a51')
            AND o.value_numeric = 30
            AND EXISTS (
                SELECT 1
                FROM obs o2
                WHERE o2.encounter_id = o.encounter_id
                AND o2.concept_id IN (SELECT concept_id FROM concept WHERE uuid = 'bbe69d90-984d-40b4-9ab5-7fe758a58aaf')
                AND o2.value_numeric = 4
            )
            AND o.obs_datetime BETWEEN @startDate AND DATE_ADD(@endDate, INTERVAL 1 DAY))
        WHEN t.indicator = 'ANC7' THEN (SELECT COUNT(DISTINCT person_id)
            FROM obs
            WHERE concept_id IN (SELECT concept_id FROM concept WHERE uuid = 'bbe69d90-984d-40b4-9ab5-7fe758a58aaf')
            AND value_numeric = 8
            AND obs_datetime BETWEEN @startDate AND DATE_ADD(@endDate, INTERVAL 1 DAY))
        WHEN t.indicator = 'ANC8' THEN (SELECT COUNT(DISTINCT o.person_id)
            FROM obs o
            JOIN concept c ON o.concept_id = c.concept_id
            WHERE c.uuid IN (
                '042d3875-0e29-4d16-bc5b-8c8a40060c92',
                '49bed4cd-cad1-4a05-bbca-69e00fc92d2a',
                'c83a2371-ce82-4d15-bf0e-9bd8a528e509',
                '778553cf-55f8-4173-91de-08616142f17f',
                '1e154024-518d-449c-8f40-6d3965ef120d',
                'f3429526-d600-4247-b5e1-557dc7c178dc',
                'f8dbde0c-9915-4942-9d26-047790ce9863',
                '891ca104-be06-4997-87cb-a40ac5a8422d',
                '69f193b7-9f8e-4b7d-be2c-3f82994eb44d',
                'e8f52434-9728-4502-b58e-2eb51256d50a'
            )
            AND o.value_coded IN (SELECT concept_id FROM concept WHERE uuid = '3cd6f600-26fe-102b-80cb-0017a47871b2')
            AND o.obs_datetime BETWEEN @startDate AND DATE_ADD(@endDate, INTERVAL 1 DAY)
            AND o.encounter_id IN (
                SELECT encounter_id
                FROM encounter
                WHERE form_id = (
                    SELECT form_id
                    FROM form
                    WHERE uuid = '2a9c2299-2e93-4698-a4dd-75ac3a23f508'
                )
            ))
        WHEN t.indicator = 'ANC10' THEN (SELECT COUNT(DISTINCT person_id)
            FROM obs
            WHERE concept_id IN (SELECT concept_id FROM concept WHERE uuid = '1ee10434-7442-4c6a-9de7-fa06e3f61145')
            AND obs_datetime BETWEEN @startDate AND DATE_ADD(@endDate, INTERVAL 1 DAY)
            AND encounter_id IN (
                SELECT encounter_id
                FROM encounter
                WHERE form_id = (
                    SELECT form_id
                    FROM form
                    WHERE uuid = '2a9c2299-2e93-4698-a4dd-75ac3a23f508'
                )
            ))
        WHEN t.indicator = 'ANC11' THEN (SELECT COUNT(DISTINCT o.person_id)
            FROM obs o
            JOIN concept c ON o.concept_id = c.concept_id
            WHERE o.obs_datetime BETWEEN @startDate AND DATE_ADD(@endDate, INTERVAL 1 DAY)
            AND o.encounter_id IN (
                SELECT encounter_id
                FROM encounter
                WHERE form_id = (
                    SELECT form_id
                    FROM form
                    WHERE uuid = '2a9c2299-2e93-4698-a4dd-75ac3a23f508'
                )
            )
            AND c.uuid IN (
                '2344ec1b-1727-4350-849d-8c878dd4d3d7',
                '5c95c913-2d15-4640-8ded-0a6a6aaaff01',
                '10cb2549-1b78-4483-9d30-01807b8e61e8',
                '23e213d6-e7f9-4881-b0e3-950f8ae6de7c'
            ))
        WHEN t.indicator = 'ANC12' THEN (SELECT COUNT(DISTINCT person_id)
            FROM obs
            WHERE obs_datetime BETWEEN @startDate AND DATE_ADD(@endDate, INTERVAL 1 DAY)
            AND encounter_id IN (
                SELECT encounter_id
                FROM encounter
                WHERE form_id IN (
                    SELECT form_id
                    FROM form
                    WHERE uuid IN (
                        '2a9c2299-2e93-4698-a4dd-75ac3a23f508',
                        '867408ee-3b46-46ee-951f-aa521c47ec0f'
                    )
                )
            )
            AND concept_id IN (SELECT concept_id FROM concept WHERE uuid = '10cb2549-1b78-4483-9d30-01807b8e61e8'))
        WHEN t.indicator = 'ANC13' THEN (SELECT COUNT(DISTINCT person_id)
            FROM obs
            WHERE concept_id IN (SELECT concept_id FROM concept WHERE uuid = '830919a3-dfda-4356-a7a0-80ea2e3cf35b')
            AND value_coded IN (SELECT concept_id FROM concept WHERE uuid = '0bd8cc98-0aec-4fa4-89b2-68a0748a1c0e')
            AND encounter_id IN (
                SELECT encounter_id
                FROM obs
                WHERE concept_id IN (SELECT concept_id FROM concept WHERE uuid = 'bbe69d90-984d-40b4-9ab5-7fe758a58aaf')
                AND value_numeric = 1
                AND encounter_id IN (
                    SELECT encounter_id
                    FROM encounter
                    WHERE form_id IN (
                        SELECT form_id
                        FROM form
                        WHERE uuid IN (
                            '2a9c2299-2e93-4698-a4dd-75ac3a23f508',
                            '867408ee-3b46-46ee-951f-aa521c47ec0f'
                        )
                    )
                )
            )
            AND obs_datetime BETWEEN @startDate AND DATE_ADD(@endDate, INTERVAL 1 DAY))
        WHEN t.indicator = 'ANC14' THEN (SELECT COUNT(DISTINCT person_id)
            FROM obs
            WHERE concept_id IN (SELECT concept_id FROM concept WHERE uuid = '830919a3-dfda-4356-a7a0-80ea2e3cf35b')
            AND value_coded IN (SELECT concept_id FROM concept WHERE uuid = '1594849e-f8db-43ec-9294-645ac0ec6e7d')
            AND encounter_id IN (
                SELECT encounter_id
                FROM obs
                WHERE concept_id IN (SELECT concept_id FROM concept WHERE uuid = 'bbe69d90-984d-40b4-9ab5-7fe758a58aaf')
                AND value_numeric = 1
                AND encounter_id IN (
                    SELECT encounter_id
                    FROM encounter
                    WHERE form_id IN (
                        SELECT form_id
                        FROM form
                        WHERE uuid IN (
                            '2a9c2299-2e93-4698-a4dd-75ac3a23f508',
                            '867408ee-3b46-46ee-951f-aa521c47ec0f'
                        )
                    )
                )
            )
            AND obs_datetime BETWEEN @startDate AND DATE_ADD(@endDate, INTERVAL 1 DAY))
        WHEN t.indicator = 'ANC15' THEN (SELECT COUNT(DISTINCT o1.person_id)
            FROM obs o1
            JOIN obs o2 ON o1.person_id = o2.person_id
            WHERE o1.concept_id IN (SELECT concept_id FROM concept WHERE uuid = '4326b04b-3158-417a-bb8d-ad022295b0f4')
            AND o1.obs_datetime BETWEEN @startDate AND DATE_ADD(@endDate, INTERVAL 1 DAY)
            AND o1.encounter_id IN (
                SELECT encounter_id
                FROM encounter
                WHERE form_id IN (
                    SELECT form_id
                    FROM form
                    WHERE uuid IN (
                        '2a9c2299-2e93-4698-a4dd-75ac3a23f508',
                        '867408ee-3b46-46ee-951f-aa521c47ec0f'
                    )
                )
            )
            AND o2.concept_id IN (SELECT concept_id FROM concept WHERE uuid = 'bbe69d90-984d-40b4-9ab5-7fe758a58aaf')
            AND o2.value_numeric = 1)
        WHEN t.indicator = 'ANC16' THEN (SELECT COUNT(DISTINCT o1.person_id)
            FROM obs o1
            JOIN obs o2 ON o1.person_id = o2.person_id
            WHERE o1.concept_id IN (SELECT concept_id FROM concept WHERE uuid = '4326b04b-3158-417a-bb8d-ad022295b0f4')
            AND o1.value_numeric < 21
            AND o1.obs_datetime BETWEEN @startDate AND DATE_ADD(@endDate, INTERVAL 1 DAY)
            AND o1.encounter_id IN (
                SELECT encounter_id
                FROM encounter
                WHERE form_id IN (
                    SELECT form_id
                    FROM form
                    WHERE uuid IN (
                        '2a9c2299-2e93-4698-a4dd-75ac3a23f508',
                        '867408ee-3b46-46ee-951f-aa521c47ec0f'
                    )
                )
            )
            AND o2.concept_id IN (SELECT concept_id FROM concept WHERE uuid = 'bbe69d90-984d-40b4-9ab5-7fe758a58aaf')
            AND o2.value_numeric = 1)
        WHEN t.indicator = 'ANC17' THEN (SELECT COUNT(DISTINCT e.patient_id)
            FROM encounter e
            JOIN obs o ON e.encounter_id = o.encounter_id
            JOIN orders ord ON e.patient_id = ord.patient_id
            WHERE e.encounter_type = 'a703372d-28b7-4831-9817-ee385c8c47d8'
            AND EXISTS (
                SELECT 1
                FROM obs o2
                WHERE o2.encounter_id = o.encounter_id
                AND o2.concept_id IN (SELECT concept_id FROM concept WHERE uuid = 'bbe69d90-984d-40b4-9ab5-7fe758a58aaf')
                AND o2.value_numeric = 1
            )
            AND ord.concept_id IN (SELECT concept_id FROM concept WHERE uuid = '3ccc7158-26fe-102b-80cb-0017a47871b2')
            AND DATE(e.encounter_datetime) = DATE(ord.date_activated)
            AND e.encounter_datetime BETWEEN @startDate AND DATE_ADD(@endDate, INTERVAL 1 DAY))
        WHEN t.indicator = 'ANC18' THEN (SELECT COUNT(DISTINCT o.patient_id)
            FROM orders o
            JOIN encounter e ON o.patient_id = e.patient_id
            JOIN obs ob ON o.patient_id = ob.person_id
            WHERE o.concept_id IN (SELECT concept_id FROM concept WHERE uuid = '3ccc7158-26fe-102b-80cb-0017a47871b2')
            AND e.encounter_type = 'a703372d-28b7-4831-9817-ee385c8c47d8'
            AND DATE(o.date_activated) = DATE(e.encounter_datetime)
            AND ob.concept_id IN (SELECT concept_id FROM concept WHERE uuid = '3ccc7158-26fe-102b-80cb-0017a47871b2')
            AND ob.value_numeric < 9.9
            AND o.date_activated BETWEEN @startDate AND DATE_ADD(@endDate, INTERVAL 1 DAY))
        WHEN t.indicator = 'ANC19' THEN (SELECT COUNT(DISTINCT enc.patient_id)
            FROM orders ord
            LEFT JOIN encounter enc ON enc.patient_id = ord.patient_id
            WHERE ord.concept_id IN (SELECT concept_id FROM concept WHERE uuid = '3cdb36f2-26fe-102b-80cb-0017a47871b2')
            AND ord.voided = 0
            AND DATE(ord.date_created) = DATE(enc.date_created)
            AND enc.form_id IN (
                SELECT form_id
                FROM form
                WHERE uuid IN (
                    '2a9c2299-2e93-4698-a4dd-75ac3a23f508',
                    '867408ee-3b46-46ee-951f-aa521c47ec0f'
                )
            )
            AND enc.voided = 0
            AND DATE(enc.date_created) >= DATE(@startDate)
            AND DATE(enc.date_created) <= DATE(@endDate))
        WHEN t.indicator = 'ANC20' THEN (SELECT COUNT(DISTINCT person_id)
            FROM obs o
            WHERE o.concept_id IN (SELECT concept_id FROM concept WHERE uuid = '3cdb36f2-26fe-102b-80cb-0017a47871b2')
            AND o.obs_datetime BETWEEN @startDate AND DATE_ADD(@endDate, INTERVAL 1 DAY)
            AND o.value_coded = 703
            AND o.person_id IN (
                SELECT enc.patient_id
                FROM orders ord
                LEFT JOIN encounter enc ON enc.patient_id = ord.patient_id
                WHERE ord.concept_id IN (SELECT concept_id FROM concept WHERE uuid = '3cdb36f2-26fe-102b-80cb-0017a47871b2')
                AND ord.voided = 0
                AND DATE(ord.date_created) = DATE(enc.date_created)
                AND enc.form_id IN (
                    SELECT form_id
                    FROM form
                    WHERE uuid IN (
                        '2a9c2299-2e93-4698-a4dd-75ac3a23f508',
                        '867408ee-3b46-46ee-951f-aa521c47ec0f'
                    )
                )
                AND enc.voided = 0
            ))
        WHEN t.indicator = 'ANC21' THEN (SELECT COUNT(DISTINCT o1.person_id)
            FROM obs o1
            JOIN concept c ON o1.concept_id = c.concept_id
            JOIN obs o2 ON o1.person_id = o2.person_id
            WHERE c.uuid IN (
                'f0b20606-a261-4da4-8fb4-22a8c6d46b5d',
                'ee891321-3066-41c4-8fb4-22a8c6d46b5d',
                'b209fbaa-e240-472f-bb57-0efd2586c0ad',
                '76f7ba1f-b3d5-4bfa-a75f-d9ab2b7e59f8',
                '57c934dd-a086-4e73-a9b8-3b9c1abef1b1'
            )
            AND o1.obs_datetime BETWEEN @startDate AND DATE_ADD(@endDate, INTERVAL 1 DAY)
            AND o1.encounter_id IN (
                SELECT encounter_id
                FROM encounter
                WHERE form_id IN (
                    SELECT form_id
                    FROM form
                    WHERE uuid IN (
                        '2a9c2299-2e93-4698-a4dd-75ac3a23f508',
                        '867408ee-3b46-46ee-951f-aa521c47ec0f'
                    )
                )
            )
            AND o2.concept_id IN (SELECT concept_id FROM concept WHERE uuid = 'bbe69d90-984d-40b4-9ab5-7fe758a58aaf')
            AND o2.value_numeric = 1)
        WHEN t.indicator = 'ANC22' THEN (SELECT COUNT(DISTINCT enc.patient_id)
            FROM orders ord
            LEFT JOIN encounter enc ON enc.patient_id = ord.patient_id
            WHERE ord.concept_id IN (SELECT concept_id FROM concept WHERE uuid = '0831b054-2b80-4365-8c35-cfa681651b6b')
            AND ord.voided = 0
            AND DATE(ord.date_created) = DATE(enc.date_created)
            AND enc.form_id IN (
                SELECT form_id
                FROM form
                WHERE uuid IN (
                    '2a9c2299-2e93-4698-a4dd-75ac3a23f508',
                    '867408ee-3b46-46ee-951f-aa521c47ec0f'
                )
            )
            AND enc.voided = 0
            AND DATE(enc.date_created) >= DATE(@startDate)
            AND DATE(enc.date_created) <= DATE(@endDate))
        WHEN t.indicator = 'ANC23' THEN (SELECT COUNT(DISTINCT person_id)
            FROM obs o
            WHERE o.concept_id IN (SELECT concept_id FROM concept WHERE uuid = '0831b054-2b80-4365-8c35-cfa681651b6b')
            AND o.obs_datetime BETWEEN @startDate AND DATE_ADD(@endDate, INTERVAL 1 DAY)
            AND o.value_coded = 703
            AND o.person_id IN (
                SELECT enc.patient_id
                FROM orders ord
                LEFT JOIN encounter enc ON enc.patient_id = ord.patient_id
                WHERE ord.concept_id IN (SELECT concept_id FROM concept WHERE uuid = '0831b054-2b80-4365-8c35-cfa681651b6b')
                AND ord.voided = 0
                AND DATE(ord.date_created) = DATE(enc.date_created)
                AND enc.form_id IN (
                    SELECT form_id
                    FROM form
                    WHERE uuid IN (
                        '2a9c2299-2e93-4698-a4dd-75ac3a23f508',
                        '867408ee-3b46-46ee-951f-aa521c47ec0f'
                    )
                )
                AND enc.voided = 0
            ))
        WHEN t.indicator = 'ANC30' THEN (SELECT COUNT(DISTINCT o.person_id)
            FROM obs o
            JOIN encounter e ON o.encounter_id = e.encounter_id
            WHERE o.concept_id = 6547
            AND o.value_coded IN (SELECT concept_id FROM concept WHERE uuid = '3cd6f600-26fe-102b-80cb-0017a47871b2')
            AND e.encounter_type = 'a703372d-28b7-4831-9817-ee385c8c47d8'
            AND e.encounter_datetime BETWEEN @startDate AND DATE_ADD(@endDate, INTERVAL 1 DAY)
            AND EXISTS (
                SELECT 1
                FROM obs o2
                WHERE o2.encounter_id = e.encounter_id
                AND o2.concept_id IN (SELECT concept_id FROM concept WHERE uuid = 'bbe69d90-984d-40b4-9ab5-7fe758a58aaf')
                AND o2.value_numeric = 4
            ))
        WHEN t.indicator = 'ANC31' THEN (SELECT COUNT(DISTINCT o.person_id)
            FROM obs o
            JOIN encounter e ON o.encounter_id = e.encounter_id
            WHERE o.concept_id = 6547
            AND o.value_coded IN (SELECT concept_id FROM concept WHERE uuid = '3cd6f600-26fe-102b-80cb-0017a47871b2')
            AND e.encounter_type = 'a703372d-28b7-4831-9817-ee385c8c47d8'
            AND e.encounter_datetime BETWEEN @startDate AND DATE_ADD(@endDate, INTERVAL 1 DAY)
            AND EXISTS (
                SELECT 1
                FROM obs o2
                WHERE o2.encounter_id = e.encounter_id
                AND o2.concept_id IN (SELECT concept_id FROM concept WHERE uuid = 'bbe69d90-984d-40b4-9ab5-7fe758a58aaf')
                AND o2.value_numeric = 1
            ))
    END AS count
FROM (
    SELECT 'ANC1' AS indicator, 'ANC New Registrations / CPN Nouvelles inscrites' AS indicator_name
    UNION ALL SELECT 'ANC2', 'ANC New Registrations Under 14 Years / CPN Grossesses chez les femmes de moins de 14 ans'
    UNION ALL SELECT 'ANC3', 'ANC New Registrations Aged 14-17 Years / CPN Grossesses chez les femmes de 15-17 ans'
    UNION ALL SELECT 'ANC4', 'ANC New Registrations Aged 18-19 Years / CPN Grossesses chez les femmes âgées 18-19 ans'
    UNION ALL SELECT 'ANC5', 'ANC First Standard Contacts (Within 12 Weeks) / CPN Première contact standard (endeans 12 semaines)'
    UNION ALL SELECT 'ANC6', 'ANC 4 Contacts Standards / CPN femmes ayant fait 4 contacts standard'
    UNION ALL SELECT 'ANC7', 'ANC 8 Contacts / CPN femmes ayant fait 8 contacts'
    UNION ALL SELECT 'ANC8', 'ANC Risk Pregnancy Detected / CPN grossesses à haut risques dépistées'
    UNION ALL SELECT 'ANC10', 'ANC TT 1 Given / CPN VAT1'
    UNION ALL SELECT 'ANC11', 'ANC TT 2 to 5 Given / CPN VAT 2 à 5'
    UNION ALL SELECT 'ANC12', 'ANC TT New Registrations Fully Vaccinated / CPN VAT Nouvelles inscrites complètement vaccinées'
    UNION ALL SELECT 'ANC13', 'ANC New Registrations Who Received Full Course of Iron and Folic Acid Supplements (90 Tablets) / CPN nouvelles inscrites qui ont reçu 90 Comprimés de Fer et Acide Folique'
    UNION ALL SELECT 'ANC14', 'ANC Insecticide Treated Bed Nets Distributed / CPN Moustiquaires Imprégnées d\'Insecticide distribuées'
    UNION ALL SELECT 'ANC15', 'ANC New Registrations Screened for Malnutrition (MUAC) / CPN nouvelles inscrites dépistées pour la malnutrition (MUAC)'
    UNION ALL SELECT 'ANC16', 'ANC New Registrations Screened Who Were Malnourished (MUAC < 21 cm) / CPN nouvelles inscrites chez lesquelles la malnutrition est détectée (MUAC < 21 cm)'
    UNION ALL SELECT 'ANC17', 'ANC New Registrations Tested for Anemia / CPN nouvelles inscrites testées pour l’anémie'
    UNION ALL SELECT 'ANC18', 'ANC New Registrations with Anemia (Moderate and Severe Hgb 7gr-9.9gr/dl and <7gm/dl)'
    UNION ALL SELECT 'ANC19', 'ANC New Registrations Syphilis Tested / CPN nouvelles inscrites testés pour la syphilis'
    UNION ALL SELECT 'ANC20', 'ANC New Registrations Syphilis Tested Positive / CPN nouvelles inscrites testées positives pour la syphilis'
    UNION ALL SELECT 'ANC21', 'ANC New Registrations Received Ultrasound Scan / CPN nouvelles inscrites qui ont reçu ultrasound scan'
    UNION ALL SELECT 'ANC22', 'Number of Pregnant Women Screened for HBV'
    UNION ALL SELECT 'ANC23', 'Number of Pregnant Women with HBV Infection Defined by HBsAg-Positive Serological Status'
    UNION ALL SELECT 'ANC30', 'Women Accompanied by Their Partners During Antenatal Consultation ANC Fourth Visit'
    UNION ALL SELECT 'ANC31', 'Women Accompanied by Their Partners During Antenatal Consultation ANC First Visit'
) t
ORDER BY t.indicator;