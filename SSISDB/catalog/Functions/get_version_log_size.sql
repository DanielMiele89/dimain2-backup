﻿CREATE FUNCTION [catalog].[get_version_log_size]()
RETURNS bigint
AS 
BEGIN
    DECLARE @value bigint
    SELECT @value = internal.get_space_used('internal.object_versions')
    RETURN @value
END

GO
GRANT EXECUTE
    ON OBJECT::[catalog].[get_version_log_size] TO [ssis_admin]
    AS [dbo];

