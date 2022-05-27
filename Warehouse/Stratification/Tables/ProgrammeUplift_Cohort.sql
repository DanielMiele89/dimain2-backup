CREATE TABLE [Stratification].[ProgrammeUplift_Cohort] (
    [MonthID]                       INT           NOT NULL,
    [PartnerName]                   VARCHAR (100) NULL,
    [Cohort]                        VARCHAR (50)  NOT NULL,
    [ActivatedCardholders]          INT           NULL,
    [ActivatedSales]                MONEY         NULL,
    [ActivatedTrans]                INT           NULL,
    [ActivatedSpenders]             INT           NULL,
    [PostActivationSales]           MONEY         NULL,
    [PostActivationSpenders]        INT           NULL,
    [PostActivationTransactions]    INT           NULL,
    [Commission]                    MONEY         NULL,
    [ControlCardholders]            INT           NULL,
    [ControlSales]                  MONEY         NULL,
    [ControlTrans]                  INT           NULL,
    [ControlSpenders]               INT           NULL,
    [CumulativePostActivationSales] INT           NULL,
    [CumulativeCommission]          INT           NULL,
    [Adj_FactorSPC]                 FLOAT (53)    NULL,
    [IncrementalSales]              INT           NULL,
    [CumulativeIncrementalSales]    INT           NULL
);

