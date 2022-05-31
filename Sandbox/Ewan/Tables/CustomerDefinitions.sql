CREATE TABLE [Ewan].[CustomerDefinitions] (
    [CycleID]                   INT           NULL,
    [CycleEndDate]              DATE          NULL,
    [FanID]                     INT           NULL,
    [SourceUID]                 VARCHAR (20)  NULL,
    [CINID]                     INT           NULL,
    [IsActiveSchemeMember]      INT           NULL,
    [ActivatedDate]             DATE          NULL,
    [CurrentAccount]            VARCHAR (18)  NULL,
    [NomineeStatus]             VARCHAR (22)  NULL,
    [CreditCardHolder]          INT           NULL,
    [ProductHoldingGroupNumber] INT           NULL,
    [ProductHoldingGroupName]   VARCHAR (100) NULL,
    [MarketableID]              INT           NULL,
    [IsMarketable]              INT           NULL,
    [OperationalSegmentLabel]   VARCHAR (3)   NULL,
    [OperationalSubSegmentID]   VARCHAR (3)   NULL,
    [OperationalSubSegmentName] VARCHAR (50)  NULL
);


GO
CREATE NONCLUSTERED INDEX [inx_cycle]
    ON [Ewan].[CustomerDefinitions]([CycleID] ASC);


GO
CREATE NONCLUSTERED INDEX [inx_customer_identy]
    ON [Ewan].[CustomerDefinitions]([FanID] ASC);


GO
CREATE NONCLUSTERED INDEX [inx_PHsegments]
    ON [Ewan].[CustomerDefinitions]([ProductHoldingGroupNumber] ASC);


GO
CREATE NONCLUSTERED INDEX [inx_active]
    ON [Ewan].[CustomerDefinitions]([IsActiveSchemeMember] ASC);


GO
CREATE NONCLUSTERED INDEX [inx_marketing]
    ON [Ewan].[CustomerDefinitions]([IsMarketable] ASC);

