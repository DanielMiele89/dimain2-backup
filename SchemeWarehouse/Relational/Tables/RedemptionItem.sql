CREATE TABLE [Relational].[RedemptionItem] (
    [RedemptionItemID]      INT           NOT NULL,
    [Donation]              BIT           NOT NULL,
    [RedemptionDescription] VARCHAR (100) NOT NULL,
    PRIMARY KEY CLUSTERED ([RedemptionItemID] ASC)
);

