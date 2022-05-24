CREATE TABLE [MI].[ReportMID] (
    [OutletID]     INT          NULL,
    [MID]          VARCHAR (50) NULL,
    [PartnerID]    INT          NOT NULL,
    [StatusTypeID] INT          NULL,
    [StartDate]    DATE         NULL,
    [EndDate]      DATE         NULL,
    [ID]           INT          IDENTITY (1, 1) NOT NULL,
    [SplitID]      INT          NULL,
    [AddedType]    INT          NULL,
    CONSTRAINT [PK_MI_ReportMID] PRIMARY KEY CLUSTERED ([ID] ASC)
);

