

with source as (

    select * from "capstone"."main_silver"."stg_tickets"

),

dim_agents as (

    select distinct
        agent as agent_id,
        agent_team,
        agent_role

    from source
    where agent is not null

)

select * from dim_agents