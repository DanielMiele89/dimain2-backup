CREATE TABLE [MI].[CampaignDetailsWave] (
    [ID]                         INT            IDENTITY (1, 1) NOT NULL,
    [ClientServicesRef]          VARCHAR (40)   NOT NULL,
    [StartDate]                  DATE           NULL,
    [CampaignName]               VARCHAR (500)  NOT NULL,
    [CampaignType]               VARCHAR (500)  NOT NULL,
    [MinStartDate]               DATE           NULL,
    [MaxEndDate]                 DATE           NULL,
    [TargetedAcquire]            INT            NULL,
    [TargetedGrow]               INT            NULL,
    [TargetedRetain]             INT            NULL,
    [MinCashback]                NUMERIC (7, 4) NULL,
    [MaxCashBack]                NUMERIC (7, 4) NULL,
    [AvgCashback]                NUMERIC (7, 4) NULL,
    [TargetedVolume]             INT            NULL,
    [ControlVolume]              INT            NULL,
    [Base]                       INT            NULL,
    [MarketableBase]             INT            NULL,
    [WeeksAfterPreviousCampaign] INT            NULL,
    [SpendTreshhold]             INT            NULL,
    [SpendTreshhold_Min]         SMALLMONEY     NULL,
    [SpendTreshhold_Max]         SMALLMONEY     NULL,
    [SpendTreshhold_Avg]         SMALLMONEY     NULL,
    [QualifyingMids]             INT            NULL,
    [AwardingMIDs]               VARCHAR (500)  NULL,
    [Inserted]                   SMALLDATETIME  NULL,
    [InsertedBy]                 NVARCHAR (128) NULL,
    [Updated]                    SMALLDATETIME  NULL,
    [UpdatedBy]                  NVARCHAR (128) NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC),
    CONSTRAINT [UN_CampaignDetailsWave] UNIQUE NONCLUSTERED ([ClientServicesRef] ASC, [StartDate] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IND1]
    ON [MI].[CampaignDetailsWave]([ClientServicesRef] ASC);


GO
CREATE TRIGGER [MI].[TrgAfterInsert_Wave] ON [Warehouse].[MI].[CampaignDetailsWave]
AFTER INSERT
AS
    UPDATE Warehouse.MI.CampaignDetailsWave
    SET Updated = GETDATE(), UpdatedBy=SYSTEM_USER,Inserted = GETDATE(), InsertedBy=SYSTEM_USER
    WHERE ID IN (SELECT DISTINCT ID FROM Inserted)
GO

CREATE TRIGGER [MI].[TrgAfterUpdate_Wave] ON Warehouse.MI.CampaignDetailsWave
AFTER UPDATE
AS
    UPDATE Warehouse.MI.CampaignDetailsWave
    SET Updated = GETDATE(), UpdatedBy=SYSTEM_USER
    WHERE ID IN (SELECT DISTINCT ID FROM Inserted)