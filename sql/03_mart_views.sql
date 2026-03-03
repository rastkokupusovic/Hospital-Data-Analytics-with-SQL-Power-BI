/* ============================================================
   MART LAYER
   Business-ready views built from staging tables
   ============================================================ */



-- ============================================================
-- OBJECTIVE 1: ENCOUNTERS OVERVIEW
-- ============================================================

create  or replace view mart_total_num_patients as
    select distinct  count(*) from patients;

create or replace view mart_total_num_encounters as
                  select  count(*) from stg_encounters;
-- a. How many total encounters occurred each year?

create or replace view mart_encounters_per_year as

with prvi as (

    select distinct *
    from stg_encounters

),

drugi as (

    select

        extract(year from start) as year,

        count(*) as total_encounters

    from prvi

    group by extract(year from start)

)

select *
from drugi;




-- b. For each year, what percentage of all encounters belonged to each encounter class?

create or replace view mart_encounter_class_percentage as

with prvi as (

    select distinct *
    from stg_encounters

),

drugi as (

    select

        extract(year from start) as year,

        round(
            100.0 *
            (count(*) filter (where encounterclass='ambulatory'))::decimal
            /
            count(*)::decimal,
            2
        ) as ambulatory_pct,

        round(
            100.0 *
            (count(*) filter (where encounterclass='outpatient'))::decimal
            /
            count(*)::decimal,
            2
        ) as outpatient_pct,

        round(
            100.0 *
            (count(*) filter (where encounterclass='wellness'))::decimal
            /
            count(*)::decimal,
            2
        ) as wellness_pct,

        round(
            100.0 *
            (count(*) filter (where encounterclass='urgentcare'))::decimal
            /
            count(*)::decimal,
            2
        ) as urgentcare_pct,

        round(
            100.0 *
            (count(*) filter (where encounterclass='emergency'))::decimal
            /
            count(*)::decimal,
            2
        ) as emergency_pct,

        round(
            100.0 *
            (count(*) filter (where encounterclass='inpatient'))::decimal
            /
            count(*)::decimal,
            2
        ) as inpatient_pct

    from prvi

    group by  extract(year from start)

)

select *
from drugi;




-- c. What percentage of encounters were over 24 hours versus under 24 hours?

create or replace view mart_encounter_duration_percentage as

with prvi as (

    select

        *,

        stop - start as razlika

    from stg_encounters

),

drugi as (

    select

        extract(days from razlika) as dani

    from prvi

)

select

    round(
        100.0 *
        (count(*) filter (where dani>=1))::decimal
        /
        count(*),
        2
    ) as over_24h_pct,

    round(
        100.0 *
        (count(*) filter (where dani=0))::decimal
        /
        count(*),
        2
    ) as under_24h_pct

from drugi;




-- ============================================================
-- OBJECTIVE 2: COST & COVERAGE INSIGHTS
-- ============================================================



-- a. How many encounters had zero payer coverage, and what percentage of total encounters does this represent?

create or replace view mart_zero_payer_coverage as

select

    count(*) filter (where payer_coverage=0)
    as number_of_zero,

    round(
        100.0 *
        (count(*) filter (where payer_coverage=0))::decimal
        /
        count(*)::decimal,
        2
    ) as pct_zero_number

from stg_encounters;




-- b. What are the top 10 most frequent procedures performed and the average base cost for each?

create or replace view mart_top_procedures as

with prvi as (

    select

        code,

        count(*) as number,

        avg(base_cost) as avg_base_cost

    from stg_procedures

    group by code

),

drugi as (

    select

        *,

        dense_rank()
        over(order by number desc) as rank

    from prvi

)

select *
from drugi

where rank between 1 and 10;




-- d. What is the average total claim cost for encounters, broken down by payer?

create or replace view mart_avg_claim_cost_by_payer as

with prvi as (

    select

        payer,

        round(avg(total_claim_cost)::numeric,2) as avg_claim_cost

    from stg_encounters

    group by payer

)

select

    pr.payer,

    pa.name,

    pr.avg_claim_cost

from prvi pr

join stg_payers pa

on pr.payer = pa.id;




-- ============================================================
-- OBJECTIVE 3: PATIENT BEHAVIOR ANALYSIS
-- ============================================================



-- a. How many unique patients were admitted each quarter over time?

drop view if exists mart_patients_per_quarter;

create view mart_patients_per_quarter as

with prvi as (

    select

        *,

        extract(year from start) as godina,

        case
            when extract(month from start) in (1,2,3)
            then 'First quarter'

            when extract(month from start) in (4,5,6)
            then 'Second quarter'

            when extract(month from start) in (7,8,9)
            then 'Third quarter'

            else 'Fourth quarter'

        end as quarter

    from stg_encounters

)

select

    godina,

    quarter,

    count(distinct patient) as unique_patients

from prvi

group by godina, quarter

order by godina, quarter;



-- b. How many patients were readmitted within 30 days of a previous encounter?
drop view if exists mart_readmitted_patients;
create or replace view mart_readmitted_patients2 as

 with prvi as (
    select patient,start,LEAD(start) over(partition by  patient order by start) as sledeci_put
    from encounters
   ),
    drugi as (
    select patient,extract(days from sledeci_put - start ) as razlika from prvi
     where sledeci_put is not null)
    select count(distinct patient) as readmitted_within_30_days from drugi
    where razlika<=30;




-- c. Which patients had the most readmissions?

create or replace view mart_readmissions_per_patient as

with prvi as (

    select
       distinct e.patient,
        e.start,
        lead(e.start) over(partition by e.patient order by e.start) as sledeci_put,
        p.first || ' ' || p.last as full_name
    from stg_encounters e
    join stg_patients p on e.patient = p.id

),

drugi as (

      select *
    from prvi
    where sledeci_put - start <= interval '30 days'

)

select
    patient,
    full_name,
    count(*) as num_readmissions

from drugi

group by patient, full_name

order by num_readmissions desc;




