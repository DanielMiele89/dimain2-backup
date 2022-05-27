CREATE TABLE [Report].[OfferReport_Metrics_CustGroup] (
    [ID]                INT   IDENTITY (1, 1) NOT NULL,
    [GroupID]           INT   NOT NULL,
    [StartDate]         DATE  NOT NULL,
    [EndDate]           DATE  NOT NULL,
    [Sales]             MONEY NULL,
    [Trans]             INT   NULL,
    [AllTransThreshold] INT   NULL,
    [Spenders]          INT   NULL,
    [Channel]           BIT   NULL,
    [Threshold]         BIT   NULL,
    [Exposed]           BIT   NULL,
    [PartnerID]         INT   NOT NULL,
    [offerStartDate]    DATE  NOT NULL,
    [offerEndDate]      DATE  NOT NULL,
    [isWarehouse]       BIT   NULL
);

