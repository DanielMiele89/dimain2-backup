CREATE TYPE [msqta].[QueryOptionGroupType] AS TABLE (
    [GroupID]                BIGINT         NOT NULL,
    [QueryID]                BIGINT         NOT NULL,
    [DatabaseName]           [sysname]      NOT NULL,
    [QueryOptions]           NVARCHAR (MAX) NOT NULL,
    [IsVerified]             BIT            NOT NULL,
    [IsDeployed]             BIT            NOT NULL,
    [ValidationCompleteDate] DATETIME2 (7)  NULL);

