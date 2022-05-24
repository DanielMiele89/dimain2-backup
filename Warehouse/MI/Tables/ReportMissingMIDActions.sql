CREATE TABLE [MI].[ReportMissingMIDActions] (
    [ID]        INT IDENTITY (1, 1) NOT NULL,
    [PartnerID] INT NOT NULL,
    [SplitID]   INT NOT NULL,
    [Record]    INT NOT NULL,
    [AssignTo]  INT NOT NULL
);

