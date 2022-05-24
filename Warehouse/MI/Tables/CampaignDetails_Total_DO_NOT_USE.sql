CREATE TABLE [MI].[CampaignDetails_Total_DO_NOT_USE] (
    [ID]                         INT            IDENTITY (1, 1) NOT NULL,
    [ClientServicesRef]          VARCHAR (40)   NOT NULL,
    [PartnerID]                  INT            NOT NULL,
    [CampaignName]               VARCHAR (500)  NOT NULL,
    [CampaignType]               VARCHAR (500)  NOT NULL,
    [StartDate]                  DATE           NULL,
    [EndDate]                    DATE           NULL,
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
    [ABTesting]                  INT            NULL,
    [Inserted]                   SMALLDATETIME  NULL,
    [InsertedBy]                 NVARCHAR (128) NULL,
    [Updated]                    SMALLDATETIME  NULL,
    [UpdatedBy]                  NVARCHAR (128) NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC),
    UNIQUE NONCLUSTERED ([ClientServicesRef] ASC)
);


GO
CREATE TRIGGER [MI].TrgAfterInsert ON Warehouse.MI.CampaignDetails_Total
AFTER INSERT
AS
    UPDATE Warehouse.MI.CampaignDetails_Total
    SET Updated = GETDATE(), UpdatedBy=SYSTEM_USER,Inserted = GETDATE(), InsertedBy=SYSTEM_USER
    WHERE ID IN (SELECT DISTINCT ID FROM Inserted)
GO
CREATE TRIGGER [MI].TrgAfterUpdate ON Warehouse.MI.CampaignDetails_Total
AFTER UPDATE
AS
    UPDATE Warehouse.MI.CampaignDetails_Total
    SET Updated = GETDATE(), UpdatedBy=SYSTEM_USER
    WHERE ID IN (SELECT DISTINCT ID FROM Inserted)