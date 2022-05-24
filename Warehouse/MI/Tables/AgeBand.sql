CREATE TABLE [MI].[AgeBand] (
    [AgeBandID] TINYINT      NOT NULL,
    [BandDesc]  VARCHAR (50) NULL,
    [MinAge]    TINYINT      NULL,
    [maxAge]    TINYINT      NULL,
    [StartDate] DATE         NULL,
    [EndDate]   DATE         NULL,
    CONSTRAINT [PK_MI_AgeBand] PRIMARY KEY CLUSTERED ([AgeBandID] ASC)
);

