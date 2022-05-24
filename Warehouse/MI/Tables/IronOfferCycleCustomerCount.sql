CREATE TABLE [MI].[IronOfferCycleCustomerCount] (
    [ID]            INT      IDENTITY (1, 1) NOT NULL,
    [IronOfferID]   INT      NOT NULL,
    [StartDate]     DATETIME NOT NULL,
    [EndDate]       DATETIME NOT NULL,
    [CustomerCount] INT      NOT NULL,
    CONSTRAINT [PK_MI_IronOfferCycleCustomerCount] PRIMARY KEY CLUSTERED ([ID] ASC)
);

