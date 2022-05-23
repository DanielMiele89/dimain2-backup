CREATE TYPE [Reporting].[PartnerBreakdown] AS TABLE (
    [PartnerID]    INT             NULL,
    [PartnerName]  VARCHAR (50)    NULL,
    [MonthDate]    DATE            NULL,
    [Spend]        DECIMAL (18, 2) NULL,
    [Cashback]     DECIMAL (18, 2) NULL,
    [Transactions] INT             NULL,
    [Spenders]     INT             NULL);

