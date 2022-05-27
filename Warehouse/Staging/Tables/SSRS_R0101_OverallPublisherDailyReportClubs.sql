CREATE TABLE [Staging].[SSRS_R0101_OverallPublisherDailyReportClubs] (
    [ID]          INT  IDENTITY (1, 1) NOT NULL,
    [ClubID]      INT  NOT NULL,
    [StartDate]   DATE NOT NULL,
    [IsCollinson] BIT  NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

