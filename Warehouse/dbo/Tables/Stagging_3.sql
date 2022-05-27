CREATE TABLE [dbo].[Stagging_3] (
    [Excel Source.MID]       FLOAT (53)     NULL,
    [Partner]                NVARCHAR (255) NULL,
    [SplitDesc]              NVARCHAR (255) NULL,
    [StatusTypeDesc]         NVARCHAR (255) NULL,
    [NvarMID]                NVARCHAR (50)  NULL,
    [Copy of StatusTypeDesc] VARCHAR (50)   NULL,
    [Copy of Partner]        VARCHAR (50)   NULL,
    [String SplitDesc]       VARCHAR (50)   NULL,
    [Lookup.MID]             VARCHAR (50)   NULL,
    [PartnerID]              INT            NULL,
    [OutletID]               INT            NULL,
    [AddedDate]              DATE           NULL,
    [RemovedDate]            DATE           NULL,
    [IsOnline]               BIT            NULL,
    [StartDate]              DATE           NULL,
    [EndDate]                DATE           NULL
);

