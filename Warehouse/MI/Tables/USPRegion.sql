CREATE TABLE [MI].[USPRegion] (
    [ID]            INT          IDENTITY (1, 1) NOT NULL,
    [StatsDate]     DATE         NOT NULL,
    [Region]        VARCHAR (50) NOT NULL,
    [CustomerCount] INT          NOT NULL,
    CONSTRAINT [PK_MI_USPRegion] PRIMARY KEY CLUSTERED ([ID] ASC)
);

