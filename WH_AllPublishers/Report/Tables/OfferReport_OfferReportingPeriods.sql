CREATE TABLE [Report].[OfferReport_OfferReportingPeriods] (
    [OfferReportingPeriodsID]       INT           IDENTITY (1, 1) NOT NULL,
    [PublisherID]                   INT           NOT NULL,
    [RetailerID]                    INT           NOT NULL,
    [PartnerID]                     INT           NOT NULL,
    [IronOfferID]                   INT           NOT NULL,
    [OfferID]                       INT           NOT NULL,
    [SegmentID]                     SMALLINT      NULL,
    [OfferTypeID]                   SMALLINT      NULL,
    [CashbackRate]                  REAL          NULL,
    [SpendStretch]                  SMALLMONEY    NULL,
    [SpendStretchRate]              REAL          NULL,
    [StartDate]                     DATETIME2 (7) NOT NULL,
    [EndDate]                       DATETIME2 (7) NOT NULL,
    [ControlGroupID_OutOfProgramme] INT           NULL,
    [ControlGroupID_InProgramme]    INT           NULL,
    [IronOfferCyclesID]             INT           NULL,
    [OriginalTableSource]           VARCHAR (50)  NULL,
    PRIMARY KEY CLUSTERED ([OfferReportingPeriodsID] ASC) WITH (FILLFACTOR = 80)
);


GO
CREATE NONCLUSTERED INDEX [IX_ControlGroupID_OutOfProgramme]
    ON [Report].[OfferReport_OfferReportingPeriods]([ControlGroupID_OutOfProgramme] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_ControlGroupID_InProgramme]
    ON [Report].[OfferReport_OfferReportingPeriods]([ControlGroupID_InProgramme] ASC) WITH (FILLFACTOR = 80);

