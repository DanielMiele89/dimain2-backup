CREATE TABLE [Staging].[PublisherOfferTracker_Import] (
    [ID]                      INT            IDENTITY (1, 1) NOT NULL,
    [RetailerName]            NVARCHAR (255) NULL,
    [PartnerID]               NVARCHAR (255) NULL,
    [OfferCode]               NVARCHAR (255) NULL,
    [StartDate]               NVARCHAR (255) NULL,
    [EndDate]                 NVARCHAR (255) NULL,
    [TargetAudience]          NVARCHAR (255) NULL,
    [Definition]              NVARCHAR (255) NULL,
    [CashbackOffer]           NVARCHAR (255) NULL,
    [SpendStretch]            NVARCHAR (255) NULL,
    [Status]                  NVARCHAR (255) NULL,
    [Channel]                 NVARCHAR (255) NULL,
    [BudgetAndEnrollmentCaps] NVARCHAR (255) NULL,
    [Publishers]              NVARCHAR (255) NULL,
    [Notes]                   NVARCHAR (255) NULL
);

