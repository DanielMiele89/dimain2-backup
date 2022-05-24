﻿CREATE TABLE [Derived].[Redemptions] (
    [ID]               INT            IDENTITY (1, 1) NOT NULL,
    [FanID]            INT            NOT NULL,
    [RedemptionType]   VARCHAR (8)    NULL,
    [RedemptionAmount] SMALLMONEY     NULL,
    [RedemptionDate]   DATETIME2 (7)  NULL,
    [Cancelled]        BIT            NOT NULL,
    [FileID]           INT            NOT NULL,
    [FileName]         NVARCHAR (100) NULL,
    [LoadDate]         DATETIME2 (7)  NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_FanID]
    ON [Derived].[Redemptions]([FanID] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_RedemptionDate]
    ON [Derived].[Redemptions]([RedemptionDate] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_FileFanDate]
    ON [Derived].[Redemptions]([FileID] ASC, [FanID] ASC, [RedemptionDate] ASC);

