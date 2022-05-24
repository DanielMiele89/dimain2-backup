CREATE TABLE [MI].[CampaignWaves_Total_DO_NOT_USE] (
    [ID]                INT            IDENTITY (1, 1) NOT NULL,
    [ClientServicesRef] VARCHAR (40)   NOT NULL,
    [StartDate]         DATE           NULL,
    [EndDate]           DATE           NULL,
    [TargetedVolume]    INT            NULL,
    [ControlVolume]     INT            NULL,
    [Base]              INT            NULL,
    [MarketableBase]    INT            NULL,
    [Inserted]          SMALLDATETIME  NULL,
    [InsertedBy]        NVARCHAR (128) NULL,
    [Updated]           SMALLDATETIME  NULL,
    [UpdatedBy]         NVARCHAR (128) NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC),
    CONSTRAINT [UN3] UNIQUE NONCLUSTERED ([ClientServicesRef] ASC, [StartDate] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IND_C]
    ON [MI].[CampaignWaves_Total_DO_NOT_USE]([ClientServicesRef] ASC);


GO
CREATE TRIGGER [MI].TrgAfterUpdate11 ON Warehouse.MI.CampaignWaves_Total
AFTER UPDATE
AS
    UPDATE Warehouse.MI.CampaignWaves_Total
    SET Updated = GETDATE(), UpdatedBy=SYSTEM_USER
    WHERE ID IN (SELECT DISTINCT ID FROM Inserted)
GO
CREATE TRIGGER [MI].TrgAfterInsert11 ON Warehouse.MI.CampaignWaves_Total
AFTER INSERT
AS
    UPDATE Warehouse.MI.CampaignWaves_Total
    SET Updated = GETDATE(), UpdatedBy=SYSTEM_USER,Inserted = GETDATE(), InsertedBy=SYSTEM_USER
    WHERE ID IN (SELECT DISTINCT ID FROM Inserted)