CREATE TABLE [Rory].[SolusOffer_Travel] (
    [FanID]                  INT           NULL,
    [ClubID]                 INT           NULL,
    [CustomerSegment]        NVARCHAR (50) NULL,
    [CashbackAvailable]      FLOAT (53)    NULL,
    [CashbackPending]        FLOAT (53)    NULL,
    [LifetimeValue]          FLOAT (53)    NULL,
    [EmailAddress]           NVARCHAR (50) NULL,
    [PartialPostCode]        NVARCHAR (50) NULL,
    [Marketable]             BIT           NULL,
    [EmailSendID]            INT           NULL,
    [BurnHeroOfferID]        INT           NULL,
    [EarnHeroOfferID]        INT           NULL,
    [EarnHeroOfferStartDate] DATETIME2 (7) NULL,
    [EarnHeroOfferEndDate]   DATETIME2 (7) NULL
);

