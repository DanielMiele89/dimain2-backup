CREATE TABLE [Relational].[ironoffercycles] (
    [ironoffercyclesid]       INT IDENTITY (1, 1) NOT NULL,
    [ironofferid]             INT NOT NULL,
    [offercyclesid]           INT NOT NULL,
    [controlgroupid]          INT NOT NULL,
    [OfferReportingPeriodsID] INT NULL,
    PRIMARY KEY CLUSTERED ([ironoffercyclesid] ASC)
);

