﻿CREATE TYPE [catalog].[Package_Table_Type] AS TABLE (
    [name]         NVARCHAR (260)  NOT NULL,
    [package_data] VARBINARY (MAX) NULL);




GO
GRANT EXECUTE
    ON TYPE::[catalog].[Package_Table_Type] TO PUBLIC;

