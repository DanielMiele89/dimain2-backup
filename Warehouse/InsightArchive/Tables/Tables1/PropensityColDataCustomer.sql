CREATE TABLE [InsightArchive].[PropensityColDataCustomer] (
    [ID]        INT          IDENTITY (1, 1) NOT NULL,
    [FanID]     INT          NOT NULL,
    [DataLabel] VARCHAR (50) NOT NULL,
    [ColData]   INT          NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

