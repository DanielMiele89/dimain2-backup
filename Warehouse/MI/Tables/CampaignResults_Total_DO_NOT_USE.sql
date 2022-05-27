CREATE TABLE [MI].[CampaignResults_Total_DO_NOT_USE] (
    [ClientServicesRef]                VARCHAR (40)   NOT NULL,
    [ControlGroup]                     VARCHAR (100)  NULL,
    [CustomerUniverse]                 VARCHAR (100)  NULL,
    [AggregationLevel]                 VARCHAR (100)  NULL,
    [Sales]                            MONEY          NULL,
    [Transactions]                     INT            NULL,
    [Spenders]                         INT            NULL,
    [IncrementalSales]                 FLOAT (53)     NULL,
    [IncrementalMargin]                FLOAT (53)     NULL,
    [IncrementalTransactions]          FLOAT (53)     NULL,
    [IncrementalSpenders]              FLOAT (53)     NULL,
    [MainDriver]                       VARCHAR (3)    NULL,
    [PValueSPC]                        FLOAT (53)     NULL,
    [SignificantUpliftSPC]             VARCHAR (40)   NULL,
    [PValueRR]                         FLOAT (53)     NULL,
    [SignificantUpliftRR]              VARCHAR (40)   NULL,
    [PValueSPS]                        FLOAT (53)     NULL,
    [SignificantUpliftSPS]             VARCHAR (40)   NULL,
    [OutletHaloSales]                  MONEY          NULL,
    [IncrementalOutletHaloSales]       FLOAT (53)     NULL,
    [PValueOutletHaloSales]            FLOAT (53)     NULL,
    [SignificantUpliftOutletHaloSales] VARCHAR (40)   NULL,
    [QualyfingSales]                   MONEY          NULL,
    [IncrementalQualyfingSales]        FLOAT (53)     NULL,
    [PValueQualyfingSales]             FLOAT (53)     NULL,
    [SignificantUpliftQualyfingSales]  VARCHAR (40)   NULL,
    [Cashback]                         MONEY          NULL,
    [OutletHaloCashback]               MONEY          NULL,
    [QualyfingCashback]                MONEY          NULL,
    [Commission]                       MONEY          NULL,
    [CampaignCost]                     MONEY          NULL,
    [OutletHaloCost]                   MONEY          NULL,
    [RewardOverride]                   MONEY          NULL,
    [IncrementalOverride]              MONEY          NULL,
    [Inserted]                         SMALLDATETIME  NULL,
    [InsertedBy]                       NVARCHAR (128) NULL,
    [Updated]                          SMALLDATETIME  NULL,
    [UpdatedBy]                        NVARCHAR (128) NULL,
    PRIMARY KEY CLUSTERED ([ClientServicesRef] ASC)
);




GO


GO
CREATE TRIGGER [MI].[NewTrgAfterUpdate4] ON [Warehouse].[MI].[CampaignResults_Total] 
AFTER UPDATE
AS
    UPDATE Warehouse.MI.CampaignResults_Total 
    SET Updated = GETDATE(), UpdatedBy=SYSTEM_USER
    WHERE ClientServicesRef IN (SELECT DISTINCT ClientServicesRef FROM Inserted)
GO

CREATE TRIGGER [MI].[NewTrgAfterInsert4] ON [Warehouse].[MI].[CampaignResults_Total] 
AFTER INSERT
AS
    UPDATE Warehouse.MI.CampaignResults_Total 
    SET Updated = GETDATE(), UpdatedBy=SYSTEM_USER,Inserted = GETDATE(), InsertedBy=SYSTEM_USER
    WHERE ClientServicesRef IN (SELECT DISTINCT ClientServicesRef FROM Inserted)