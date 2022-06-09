CREATE TABLE [dbo].[CBP_Credit_ProductTypeRates] (
    [CreditProductTypeID] INT        NOT NULL,
    [StartDate]           DATETIME   NULL,
    [EndDate]             DATETIME   NULL,
    [BaseRewardPercent]   FLOAT (53) NOT NULL
);

