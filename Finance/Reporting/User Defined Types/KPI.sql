CREATE TYPE [Reporting].[KPI] AS TABLE (
    [Ordinal]    INT             NOT NULL,
    [KPI]        VARCHAR (200)   NOT NULL,
    [KPIValue]   DECIMAL (18, 2) NOT NULL,
    [Formatting] VARCHAR (10)    NOT NULL,
    [StartDate]  DATE            NOT NULL,
    [EndDate]    DATE            NOT NULL);

