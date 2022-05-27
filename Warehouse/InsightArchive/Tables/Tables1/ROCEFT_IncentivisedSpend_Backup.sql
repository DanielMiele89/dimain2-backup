CREATE TABLE [InsightArchive].[ROCEFT_IncentivisedSpend_Backup] (
    [CycleIDRef]      INT           NULL,
    [BrandId]         INT           NULL,
    [Segment]         VARCHAR (200) NULL,
    [Shopper_Segment] VARCHAR (50)  NULL,
    [Incentivised]    VARCHAR (50)  NULL,
    [Spend]           MONEY         NULL,
    [Transactions]    INT           NULL,
    [Spenders]        INT           NULL,
    [Cardholders]     INT           NULL,
    [RR]              FLOAT (53)    NULL,
    [SPC]             FLOAT (53)    NULL,
    [SPS]             FLOAT (53)    NULL,
    [ATV]             FLOAT (53)    NULL,
    [ATF]             FLOAT (53)    NULL,
    [TPC]             FLOAT (53)    NULL
);

