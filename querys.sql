select CONCAT('["',Name,'" , "',lower(Platformname), '"]') from task_group;

select CONCAT('["'tg.Name, '","', JSON_UNQUOTE(json_extract(si.ConnectionString,'$.mainBucket')),'","',et.Name, '/',tg.Platformname,'"], ')
from 
task_group tg,
server_info si,
policy_base_retention pbr,
ecomm_type et
where
tg.Id = pbr.TaskGroupId
AND si.Id = pbr.ArchiveId
AND et.Id = tg.EcommTypeId
AND JSON_VALID(ConnectionString)
AND json_extract(ConnectionString, '$mainBucket') IS NOT NULL;
