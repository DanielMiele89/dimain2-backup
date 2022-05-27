CREATE TABLE [InsightArchive].[SchemeMID] (
    [OutletID]    INT          NOT NULL,
    [MID]         VARCHAR (50) NOT NULL,
    [PartnerID]   INT          NOT NULL,
    [AddedDate]   DATE         CONSTRAINT [DF_InsightArchive_SchemeMID] DEFAULT (getdate()) NOT NULL,
    [RemovedDate] DATE         NULL,
    [IsOnline]    BIT          NULL,
    [StartDate]   DATE         CONSTRAINT [DF_InsightArchive_SchemeMID_StartDate] DEFAULT (getdate()) NULL,
    [EndDate]     DATE         NULL
);

