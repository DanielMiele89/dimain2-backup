CREATE TABLE [Relational].[HeadroomTargetingModel_MembersCounts] (
    [HeadroomID]                INT              NULL,
    [Headroom Targeting Group]  VARCHAR (22)     NOT NULL,
    [CustomerCount]             INT              NULL,
    [Customer_Pct]              NUMERIC (21, 13) NULL,
    [Customer_Pct_EligibleOnly] NUMERIC (21, 13) NULL,
    [CustomerBase_1M]           INT              NULL,
    [SumPct]                    REAL             NULL,
    [SumCategorySpend]          REAL             NULL,
    [MeanPct]                   REAL             NULL,
    [MeanCatSpend]              REAL             NULL
);

