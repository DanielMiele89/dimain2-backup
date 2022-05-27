CREATE TABLE [MI].[CampaignDetailsCSR_SuperSegment] (
    [ID]                         INT            IDENTITY (1, 1) NOT NULL,
    [ClientServicesRef]          VARCHAR (40)   NOT NULL,
    [SegmentID]                  INT            NULL,
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
    CONSTRAINT [UN_CampaignDetailsCSR_SuperSegment] UNIQUE NONCLUSTERED ([ClientServicesRef] ASC, [SegmentID] ASC)
);




GO
CREATE NONCLUSTERED INDEX [IND1]
    ON [MI].[CampaignDetailsCSR_SuperSegment]([ClientServicesRef] ASC);


GO



GO


CREATE TRIGGER [MI].[TrgAfterUpdate_CSR_SuperSegment] ON [Warehouse].[MI].[CampaignDetailsCSR_SuperSegment]
AFTER UPDATE
AS
    UPDATE Warehouse.MI.CampaignDetailsCSR_SuperSegment
    SET Updated = GETDATE(), UpdatedBy=SYSTEM_USER
    WHERE ID IN (SELECT DISTINCT ID FROM Inserted)
GO


CREATE TRIGGER [MI].[TrgAfterInsert_CSR_SuperSegment] ON [Warehouse].[MI].[CampaignDetailsCSR_SuperSegment]
AFTER INSERT
AS
    UPDATE Warehouse.MI.CampaignDetailsCSR_SuperSegment
    SET Updated = GETDATE(), UpdatedBy=SYSTEM_USER,Inserted = GETDATE(), InsertedBy=SYSTEM_USER
    WHERE ID IN (SELECT DISTINCT ID FROM Inserted)