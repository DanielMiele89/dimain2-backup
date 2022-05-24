CREATE TABLE [Stratification].[CBPCardUsageUplift_Results_byCohort] (
    [MonthID]                INT          NOT NULL,
    [Label]                  VARCHAR (50) NOT NULL,
    [ActivatedCardholders]   INT          NULL,
    [ActivatedSales]         MONEY        NULL,
    [ActivatedTrans]         INT          NULL,
    [ActivatedSpenders]      INT          NULL,
    [PostActivationSales]    MONEY        NULL,
    [PostActivationTrans]    INT          NULL,
    [PostActivationSpenders] INT          NULL,
    [ControlCardholders]     INT          NULL,
    [ControlSales]           MONEY        NULL,
    [ControlTrans]           INT          NULL,
    [ControlSpenders]        INT          NULL,
    [Adj_FactorSPC]          FLOAT (53)   NULL,
    [Adj_FactorRR]           FLOAT (53)   NULL,
    [Adj_FactorTPC]          FLOAT (53)   NULL,
    [IncrementalSales]       FLOAT (53)   NULL,
    [IncrementalSpenders]    FLOAT (53)   NULL,
    [IncrementalTrans]       FLOAT (53)   NULL
);

