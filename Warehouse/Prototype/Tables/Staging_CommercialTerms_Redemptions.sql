CREATE TABLE [Prototype].[Staging_CommercialTerms_Redemptions] (
    [ID]                   INT          IDENTITY (1, 1) NOT NULL,
    [Retailer]             VARCHAR (50) NULL,
    [StartDate]            DATE         NULL,
    [EndDate]              DATE         NULL,
    [FaceValue]            MONEY        NULL,
    [CustomerCost]         MONEY        NULL,
    [BettermentPercentage] FLOAT (53)   NULL,
    [RewardCost]           MONEY        NULL,
    [Income_beforePostage] MONEY        NULL,
    [OrderType]            VARCHAR (50) NULL,
    [LoadType]             VARCHAR (50) NULL,
    [Invoiced]             VARCHAR (50) NULL,
    [RAG]                  VARCHAR (50) NULL
);

