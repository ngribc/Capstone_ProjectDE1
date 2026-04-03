
  
    
    

    create  table
      "capstone"."main_gold"."dim_products__dbt_tmp"
  
    as (
      

with source as (

    select * from "capstone"."main_silver"."stg_tickets"

),

dim_products as (

    select distinct
        product_id,
        product_name,
        purchase_date

    from source
    where product_id is not null

)

select * from dim_products
    );
  
  