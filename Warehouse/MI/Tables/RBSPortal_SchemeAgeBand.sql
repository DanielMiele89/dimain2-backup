CREATE TABLE [MI].[RBSPortal_SchemeAgeBand] (
    [AgeBandID] TINYINT      NOT NULL,
    [BandDesc]  VARCHAR (50) NULL,
    [MinAge]    TINYINT      NULL,
    [maxAge]    TINYINT      NULL,
    [StartDate] DATE         NULL,
    [EndDate]   DATE         NULL,
    CONSTRAINT [PK_MI_RBSPortal_SchemeAgeBand] PRIMARY KEY CLUSTERED ([AgeBandID] ASC)
);

