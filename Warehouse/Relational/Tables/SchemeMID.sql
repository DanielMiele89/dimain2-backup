CREATE TABLE [Relational].[SchemeMID] (
    [OutletID]    INT          NOT NULL,
    [MID]         VARCHAR (50) NOT NULL,
    [PartnerID]   INT          NOT NULL,
    [AddedDate]   DATE         CONSTRAINT [DF_Relational_SchemeMID] DEFAULT (getdate()) NOT NULL,
    [RemovedDate] DATE         NULL,
    [IsOnline]    BIT          NULL,
    [StartDate]   DATE         CONSTRAINT [DF_Relational_SchemeMID_StartDate] DEFAULT (getdate()) NULL,
    [EndDate]     DATE         NULL,
    CONSTRAINT [PK_Relational_SchemeMID] PRIMARY KEY CLUSTERED ([OutletID] ASC),
    CONSTRAINT [UQ_Relational_SchemeMID_MID] UNIQUE NONCLUSTERED ([MID] ASC)
);

