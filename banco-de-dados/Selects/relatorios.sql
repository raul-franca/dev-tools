# totais de acompanhante sim, nao e null
select COUNT(*) AS Total,
       SUM(CASE WHEN b.acompanhante IS true THEN 1 ELSE 0 END) AS sim,
       SUM(CASE WHEN b.acompanhante IS false THEN 1 ELSE 0 END) AS não,
       SUM(CASE WHEN b.acompanhante IS NULL THEN 1 ELSE 0 END) AS nulo
from beneficiarios_staging b;

# Totais benefícios por status
select sb.nome as "Status", count(*)
    from beneficiarios_staging as b
         join status_beneficio sb on sb.id = b.status_beneficio_id
    group by sb.nome;

# Totais benefícios por período e status
select sb.id,sb.nome as "Status", count(*)
    from beneficiarios_staging as b
         join status_beneficio sb on sb.id = b.status_beneficio_id
    where b.created_at between '2025-01-01' and '2026-02-28'
    group by sb.nome;


# Totais benefícios por cidade 6000 = Não Informado
select count(*) from beneficiarios_staging where cidade_id = 6000; -- total: 4.771

select
    sb.nome, i.status_txt, count(*)
from beneficiarios_staging as b
         join status_beneficio sb on sb.id = b.status_beneficio_id
         join tipos_deficiencia d on b.tipo_deficiencia_id
         left join stg_inter i on i.cpf = b.cpf
group by sb.nome, i.status_txt;

select sb.nome as "Status", count(*)
        from beneficiarios_staging as b
        join status_beneficio sb on sb.id = b.status_beneficio_id
    where b.created_at between '2025-01-01' and '2026-02-28'
group by sb.nome;




select * from stg_inter;

select count(*) from stg_site; -- total: 12.533

select count(*) from stg_inter; -- total: 9.492
SELECT
    SUM(sim + nao + nulo) AS soma  -- 9.491
FROM (
         SELECT
             SUM(CASE WHEN acomp_txt LIKE '%S%' THEN 1 ELSE 0 END) AS sim,
             SUM(CASE WHEN acomp_txt LIKE '%N%' THEN 1 ELSE 0 END) AS nao,
             SUM(CASE WHEN acomp_txt IS NULL THEN 1 ELSE 0 END) AS nulo
         FROM stg_inter
     ) x;
SELECT
    SUM(CASE WHEN acomp_txt LIKE '%S%' THEN 1 ELSE 0 END) AS sim,
    SUM(CASE WHEN acomp_txt LIKE '%N%' THEN 1 ELSE 0 END) AS nao,
    SUM(CASE WHEN acomp_txt IS NULL THEN 1 ELSE 0 END) AS nulo
FROM stg_inter;

