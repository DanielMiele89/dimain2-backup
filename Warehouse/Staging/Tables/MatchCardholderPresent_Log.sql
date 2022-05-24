CREATE TABLE [Staging].[MatchCardholderPresent_Log] (
    [LogID]     INT           IDENTITY (1, 1) NOT NULL,
    [StartTime] SMALLDATETIME NOT NULL,
    [EndTime]   SMALLDATETIME NOT NULL,
    PRIMARY KEY CLUSTERED ([LogID] ASC)
);

