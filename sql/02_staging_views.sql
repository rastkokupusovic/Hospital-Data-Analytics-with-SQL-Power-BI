create view stg_encounters as
select distinct
    id,
    patient,
    start,
    stop,
    encounterclass,
    payer,
    payer_coverage,
    total_claim_cost,
    extract(year from start) as year,
    extract(month from start) as month,
    stop - start as duration
from encounters
where start is not null
and stop is not null
and patient is not null
and encounterclass is not null
and total_claim_cost >= 0;


create view stg_patients as
select
    id,
    first,
    last
from patients;


create view stg_procedures as
select
    code,
    base_cost
from procedures;


create view stg_payers as
select
    id,
    name
from payers;