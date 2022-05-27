CREATE TABLE [MI].[RetailerMetricChanneltypes] (
    [ID]          SMALLINT     IDENTITY (1, 1) NOT NULL,
    [ProgramID]   INT          NOT NULL,
    [ChannelID]   INT          NOT NULL,
    [Description] VARCHAR (20) NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

