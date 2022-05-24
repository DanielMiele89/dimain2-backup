CREATE TABLE [Relational].[MOT3Week2_SFDLog] (
    [ID]           INT  IDENTITY (1, 1) NOT NULL,
    [FanID]        INT  NOT NULL,
    [SFD_PullDate] DATE NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

