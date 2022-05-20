CREATE TABLE [dbo].[Redeem] (
    [ID]                    INT            IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [SupplierID]            INT            NOT NULL,
    [Description]           NVARCHAR (100) NOT NULL,
    [Status]                TINYINT        NOT NULL,
    [Price]                 MONEY          NOT NULL,
    [LimitedAvailability]   BIT            NOT NULL,
    [Privatedescription]    NVARCHAR (100) NOT NULL,
    [FulfillmentTypeId]     INT            NOT NULL,
    [CurrentStockLevel]     INT            NULL,
    [WarningStockThreshold] INT            NULL,
    [StartDate]             DATETIME       NULL,
    [EndDate]               DATETIME       NULL,
    [MemberImport]          BIT            NOT NULL,
    [CashbackPercent]       FLOAT (53)     NULL,
    [ValidityDays]          SMALLINT       NOT NULL,
    [EmailTemplate]         NVARCHAR (120) NULL,
    [IsElectronic]          AS             (case when [FulfillmentTypeId]=(1) OR [FulfillmentTypeId]=(4) OR [FulfillmentTypeId]=(5) OR [FulfillmentTypeId]=(6) then CONVERT([bit],(0),(0)) else CONVERT([bit],(1),(0)) end),
    CONSTRAINT [PK_Redeem] PRIMARY KEY CLUSTERED ([ID] ASC)
);

