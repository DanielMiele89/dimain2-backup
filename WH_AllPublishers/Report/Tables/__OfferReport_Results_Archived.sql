CREATE TABLE [Report].[__OfferReport_Results_Archived] (
    [ID]                         INT        IDENTITY (1, 1) NOT NULL,
    [OfferID]                    INT        NULL,
    [IronOfferID]                INT        NULL,
    [OfferReportingPeriodsID]    INT        NULL,
    [ControlGroupID]             INT        NOT NULL,
    [IsInPromgrammeControlGroup] BIT        NOT NULL,
    [StartDate]                  DATE       NULL,
    [EndDate]                    DATE       NULL,
    [Channel]                    BIT        NULL,
    [Threshold]                  BIT        NULL,
    [Cardholders_E]              INT        NULL,
    [Sales_E]                    MONEY      NULL,
    [Spenders_E]                 INT        NULL,
    [Transactions_E]             INT        NULL,
    [IncentivisedSales]          MONEY      NULL,
    [IncentivisedTrans]          INT        NULL,
    [Cardholders_C]              INT        NULL,
    [Spenders_C]                 INT        NULL,
    [Transactions_C]             INT        NULL,
    [RR_C]                       REAL       NULL,
    [SPC_C]                      REAL       NULL,
    [TPC_C]                      REAL       NULL,
    [ATV_C]                      REAL       NULL,
    [ATF_C]                      REAL       NULL,
    [SPS_C]                      REAL       NULL,
    [AdjFactor_RR]               FLOAT (53) NULL,
    [IncSales]                   REAL       NULL,
    [IncTransactions]            REAL       NULL,
    [MonthlyReportingDate]       DATE       NULL,
    [isPartial]                  BIT        NULL,
    [offerStartDate]             DATE       NULL,
    [offerEndDate]               DATE       NULL,
    [PartnerID]                  INT        NULL,
    [CluReportD]                 INT        NULL,
    [IncentivisedSpenders]       INT        NULL,
    [AllTransThreshold]          INT        NULL,
    [Sales_C]                    MONEY      NULL,
    [PreAdjTrans]                INT        NULL,
    [PreAdjSpenders]             INT        NULL,
    [AllTransThreshold_E]        INT        NULL,
    [AllTransThreshold_C]        INT        NULL,
    CONSTRAINT [PK_ResultID] PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [NCI_ConChanThresh]
    ON [Report].[__OfferReport_Results_Archived]([ControlGroupID] ASC, [Channel] ASC, [Threshold] ASC)
    INCLUDE([IronOfferID], [OfferReportingPeriodsID], [StartDate], [EndDate], [RR_C], [SPS_C], [AdjFactor_RR], [isPartial]);


GO
CREATE NONCLUSTERED INDEX [NCI_IronConDate]
    ON [Report].[__OfferReport_Results_Archived]([IronOfferID] ASC, [ControlGroupID] ASC, [StartDate] ASC, [EndDate] ASC);

