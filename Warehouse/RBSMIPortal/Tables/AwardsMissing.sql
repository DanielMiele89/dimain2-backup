CREATE TABLE [RBSMIPortal].[AwardsMissing] (
    [ID]      INT IDENTITY (1, 1) NOT NULL,
    [MatchID] INT NULL,
    [FileID]  INT NOT NULL,
    [RowNum]  INT NOT NULL,
    CONSTRAINT [PK_RBSMIPortal_AwardsMissing] PRIMARY KEY CLUSTERED ([ID] ASC)
);

