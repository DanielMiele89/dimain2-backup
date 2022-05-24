CREATE TABLE [InsightArchive].[UAE_CreditComboData] (
    [ID]              INT          IDENTITY (1, 1) NOT NULL,
    [MID]             VARCHAR (50) NOT NULL,
    [Narrative]       VARCHAR (50) NOT NULL,
    [ComboCity]       VARCHAR (50) NOT NULL,
    [LocationCountry] VARCHAR (3)  NOT NULL,
    [LocAlt]          VARCHAR (2)  NULL,
    [LocShort]        VARCHAR (2)  NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

