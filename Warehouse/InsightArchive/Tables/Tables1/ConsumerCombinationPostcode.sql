CREATE TABLE [InsightArchive].[ConsumerCombinationPostcode] (
    [ID]                    INT          IDENTITY (1, 1) NOT NULL,
    [ConsumerCombinationID] INT          NOT NULL,
    [PostCode]              VARCHAR (50) NULL,
    [Valid_UK_Postcode]     VARCHAR (1)  NOT NULL,
    [Country]               VARCHAR (3)  NOT NULL,
    [usethis]               BIT          DEFAULT ((0)) NULL,
    [LastTrandate]          DATE         NULL,
    [TranCount]             INT          NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

