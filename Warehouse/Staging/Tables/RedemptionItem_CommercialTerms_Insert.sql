CREATE TABLE [Staging].[RedemptionItem_CommercialTerms_Insert] (
    [ID]                   INT            IDENTITY (1, 1) NOT NULL,
    [PartnerID]            INT            NULL,
    [PartnerName]          NVARCHAR (50)  NULL,
    [RedeemID]             INT            NOT NULL,
    [OfferDescription]     NVARCHAR (100) NULL,
    [StartDate]            DATE           NULL,
    [EndDate]              DATETIME       NULL,
    [CustomerCost]         MONEY          NULL,
    [FaceValue]            MONEY          NULL,
    [BettermentPercantage] FLOAT (53)     NULL,
    [RewardCost]           MONEY          NULL,
    [IncomeBeforePostage]  MONEY          NULL,
    [OrderType]            NVARCHAR (20)  NULL,
    [LoadType]             NVARCHAR (20)  NULL,
    [Invoiced]             NVARCHAR (20)  NULL,
    [EAYB]                 NVARCHAR (10)  NULL,
    [Supplier]             NVARCHAR (20)  NULL,
    [DiscountPercentage]   FLOAT (53)     NULL,
    [Notes]                NVARCHAR (255) NULL
);

