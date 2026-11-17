-- RWA-1106: void location attributes that repeat an active attribute with the same location, type and value,
-- where the type limits how often it may occur (e.g. FOSA ID, max 1). Initializer's locations domain fails
-- validation on these. The lowest id is kept. Attributes with different values are left alone.
UPDATE location_attribute la
  JOIN location_attribute_type t ON t.location_attribute_type_id = la.attribute_type_id
  JOIN (SELECT location_id, attribute_type_id, value_reference, MIN(location_attribute_id) AS keep_id
          FROM location_attribute
         WHERE voided = 0
         GROUP BY location_id, attribute_type_id, value_reference
        HAVING COUNT(*) > 1) k
    ON k.location_id = la.location_id AND k.attribute_type_id = la.attribute_type_id
   AND k.value_reference = la.value_reference
   SET la.voided = 1, la.voided_by = (SELECT user_id FROM users WHERE system_id = 'admin'), la.date_voided = NOW(),
       la.void_reason = 'RWA-1106: duplicate of an attribute with the same value'
 WHERE la.voided = 0 AND t.max_occurs IS NOT NULL AND la.location_attribute_id <> k.keep_id;
