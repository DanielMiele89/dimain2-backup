CREATE TABLE [MI].[Staging_BPSiteListing] (
    [ID]             VARCHAR (20) NOT NULL,
    [PostCode]       VARCHAR (20) NOT NULL,
    [Classification] VARCHAR (20) NOT NULL,
    CONSTRAINT [PK_MI_Staging_BPSiteListing] PRIMARY KEY CLUSTERED ([ID] ASC)
);

