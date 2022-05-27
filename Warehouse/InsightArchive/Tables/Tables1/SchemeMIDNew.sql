CREATE TABLE [InsightArchive].[SchemeMIDNew] (
    [ID]            INT          IDENTITY (1, 1) NOT NULL,
    [OutletID]      INT          NOT NULL,
    [MID]           VARCHAR (50) NOT NULL,
    [PartnerID]     INT          NOT NULL,
    [AddedDate]     DATE         CONSTRAINT [DF_InsightArchive_SchemeMIDNew] DEFAULT (getdate()) NOT NULL,
    [RemovedDate]   DATE         NULL,
    [IsOnline]      BIT          NULL,
    [StartDate]     DATE         CONSTRAINT [DF_InsightArchive_SchemeMIDNew_StartDate] DEFAULT (getdate()) NULL,
    [EndDate]       DATE         NULL,
    [TranStartDate] DATE         NULL,
    [TranEndDate]   DATE         NULL,
    CONSTRAINT [PK_InsightArchive_SchemeMIDNew] PRIMARY KEY CLUSTERED ([ID] ASC)
);

