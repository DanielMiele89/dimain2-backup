﻿CREATE TABLE [Relational].[RBSG_StatementDM_20171215_NWFiles] (
    [File] VARCHAR (9)  NOT NULL,
    [CIN]  VARCHAR (20) NULL
);




GO
DENY SELECT
    ON OBJECT::[Relational].[RBSG_StatementDM_20171215_NWFiles] TO [New_PIIRemoved]
    AS [dbo];

