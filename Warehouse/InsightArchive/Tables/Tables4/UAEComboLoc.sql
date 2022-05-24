CREATE TABLE [InsightArchive].[UAEComboLoc] (
    [ID]              INT          IDENTITY (1, 1) NOT NULL,
    [MID]             VARCHAR (50) NOT NULL,
    [Narrative]       VARCHAR (50) NOT NULL,
    [MCC]             VARCHAR (4)  NOT NULL,
    [City]            VARCHAR (50) NOT NULL,
    [MerchantAddress] VARCHAR (50) NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

