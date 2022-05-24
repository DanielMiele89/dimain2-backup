CREATE TABLE [Prototype].[RetailerHeaderStage] (
    [ID]         INT           IDENTITY (1, 1) NOT NULL,
    [RetailerID] INT           NOT NULL,
    [Header]     VARCHAR (MAX) NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

