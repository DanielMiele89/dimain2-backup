CREATE TABLE [Report].[OfferReport_Aggregate] (
    [ID]                  INT          IDENTITY (1, 1) NOT NULL,
    [OfferID]             INT          NULL,
    [OfferName]           VARCHAR (50) NULL,
    [ControlGroupTypeID]  INT          NOT NULL,
    [StartDate]           DATE         NOT NULL,
    [EndDate]             DATE         NOT NULL,
    [PartnerID]           INT          NOT NULL,
    [Channel]             BIT          NULL,
    [Threshold]           BIT          NULL,
    [Cardholders]         INT          NULL,
    [ControlGroupSize]    INT          NULL,
    [Sales]               MONEY        NULL,
    [IncSales]            REAL         NULL,
    [Transactions]        INT          NULL,
    [IncTrans]            REAL         NULL,
    [Spenders]            INT          NULL,
    [IncSpenders]         REAL         NULL,
    [MonthlyDate]         DATE         NULL,
    [isCampaign]          BIT          NULL,
    [AllTransThreshold]   INT          NULL,
    [Sales_C]             MONEY        NULL,
    [Trans_C]             INT          NULL,
    [Spenders_C]          INT          NULL,
    [Sales_E]             MONEY        NULL,
    [Trans_E]             MONEY        NULL,
    [Spenders_E]          MONEY        NULL,
    [AllTransThreshold_E] INT          NULL,
    [AllTransThreshold_C] INT          NULL,
    [PreAdjSpenders_C]    INT          NULL,
    [PreAdjTrans_C]       INT          NULL,
    [Investment]          MONEY        NULL,
    CONSTRAINT [PK_AggregateID] PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [NCI_OfferReportAggregate_Query]
    ON [Report].[OfferReport_Aggregate]([OfferID] ASC, [StartDate] ASC, [EndDate] ASC, [ControlGroupTypeID] ASC);

