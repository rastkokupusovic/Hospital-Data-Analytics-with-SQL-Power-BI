    select distinct(count(*)),count(*) from encounters;
    select *from encounters
    where start>stop;
    select *from encounters
    where start is null or stop is null or patient is null or encounterclass is null or total_claim_cost is null;
    select *from patients
    where id not in (
        select encounters.patient from encounters
        );
    select *from encounters
    where total_claim_cost < 0;
    select * from encounters
where patient not in (select id from patients);