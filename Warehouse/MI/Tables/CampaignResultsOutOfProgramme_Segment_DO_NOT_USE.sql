CREATE TABLE [MI].[CampaignResultsOutOfProgramme_Segment_DO_NOT_USE] (
    [SegmentID]                        INT            NOT NULL,
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
    CONSTRAINT [pk_Segment3] PRIMARY KEY CLUSTERED ([ClientServicesRef] ASC, [SegmentID] ASC)
);




GO


GO
CREATE TRIGGER [MI].[OOPTrgAfterUpdate5] ON [Warehouse].[MI].[CampaignResultsOutOfProgramme_Segment]
AFTER UPDATE
AS
    UPDATE Warehouse.MI.CampaignResultsOutOfProgramme_Segment 
    SET Updated = GETDATE(), UpdatedBy=SYSTEM_USER
    WHERE EXISTS (SELECT 1 FROM Inserted i where i.ClientServicesRef=Warehouse.MI.CampaignResultsOutOfProgramme_Segment.ClientServicesRef and i.SegmentID=Warehouse.MI.CampaignResultsOutOfProgramme_Segment.SegmentID)
GO

CREATE TRIGGER [MI].[OOPTrgAfterInsert5] ON [Warehouse].[MI].[CampaignResultsOutOfProgramme_Segment]
AFTER INSERT
AS
    UPDATE Warehouse.MI.CampaignResultsOutOfProgramme_Segment
    SET Updated = GETDATE(), UpdatedBy=SYSTEM_USER,Inserted = GETDATE(), InsertedBy=SYSTEM_USER
    WHERE EXISTS (SELECT 1 FROM Inserted i where i.ClientServicesRef=Warehouse.MI.CampaignResultsOutOfProgramme_Segment.ClientServicesRef and i.SegmentID=Warehouse.MI.CampaignResultsOutOfProgramme_Segment.SegmentID)