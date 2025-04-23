Scripts
=====================

# Encounter Types

```sql
select t.uuid as 'UUID',
       if(t.retired, 'TRUE', null) as 'Void/Retire',
       t.name as 'Name',
       t.description as 'Description'
from encounter_type t
order by t.name
;
```

# Identifier Types

```sql
select t.uuid as 'UUID',
        t.name as 'Name',
        t.description as 'Description',
        if(t.required, 'TRUE', 'FALSE') as 'Required',
        t.format as 'Format',
        t.format_description as 'Format description',
        t.validator as 'Validator',
        t.location_behavior as 'Location behavior',
        t.uniqueness_behavior as 'Uniqueness behavior',
        if(t.retired, 'TRUE', null) as 'Void/Retire'
from patient_identifier_type t
order by t.name
;
```

# Locations

```sql
select l.uuid as 'UUID',
        if(l.retired, 'TRUE', null) as 'Void/Retire',
        l.name as 'Name',
        p.name as 'Parent',
        l.description as 'Description'
from location l
         left join location p on l.parent_location = p.location_id
order by l.name
;
```

# Person Attribute Types
```sql
select  t.uuid as 'UUID',
        if(t.retired, 'TRUE', null) as 'Void/Retire',
        t.name as 'Name',
        t.description as 'Description',
        t.format as 'Format',
        t.foreign_uuid as 'Foreign uuid',
        if(t.searchable, 'TRUE', 'FALSE') as 'Searchable'
from person_attribute_type t
order by t.name
;
```

# Programs

```sql
select  p.uuid as 'UUID',
        if(p.retired, 'TRUE', null) as 'Void/Retire',
        p.name as 'Name',
        p.description as 'Description',
        c.uuid as 'Program concept',
        outcomes_concept.uuid as 'Outcomes concept'
from program p
left join concept c on p.concept_id = c.concept_id
left join concept outcomes_concept on p.outcomes_concept_id = outcomes_concept.concept_id
order by p.name
;
```

# Relationship Types
```sql
select  t.uuid as 'UUID',
        if(t.retired, 'TRUE', null) as 'Void/Retire',
        t.a_is_to_b as 'A is to B',
        t.b_is_to_a as 'B is to A',
        t.description as 'Description'
from relationship_type t
order by t.a_is_to_b, t.b_is_to_a
;
```

# Visit Types

```sql
select t.uuid as 'UUID',
       if(t.retired, 'TRUE', null) as 'Void/Retire',
       t.name as 'Name',
       t.description as 'Description'
from visit_type t
order by t.name
;
```