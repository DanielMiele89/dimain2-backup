CREATE TABLE [MI].[ReportMissingMIDlog] (
    [id]         INT          IDENTITY (1, 1) NOT NULL,
    [PartnerID]  INT          NOT NULL,
    [Splitid]    INT          NULL,
    [OutletID]   INT          NULL,
    [MID]        VARCHAR (50) NULL,
    [AssignedTo] INT          NULL,
    [logDate]    DATE         NULL
);

