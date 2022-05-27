CREATE TABLE [MI].[USPAgeBandHayden] (
    [ID]            INT          IDENTITY (1, 1) NOT NULL,
    [StatsDate]     DATE         NOT NULL,
    [AgeBandID]     TINYINT      NOT NULL,
    [CustomerCount] INT          NOT NULL,
    [PublisherName] VARCHAR (50) DEFAULT ('~') NOT NULL,
    CONSTRAINT [PK_MI_USPAgeBandHayden] PRIMARY KEY CLUSTERED ([ID] ASC)
);

