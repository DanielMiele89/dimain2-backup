CREATE TABLE [MI].[TescoMIDCheck] (
    [ID]          INT            IDENTITY (1, 1) NOT NULL,
    [MID]         VARCHAR (50)   NOT NULL,
    [DateEntered] DATE           CONSTRAINT [DF_MI_TescoMIDCheck_DateEntered] DEFAULT (getdate()) NOT NULL,
    [ResolveDate] DATE           NULL,
    [Resolution]  VARCHAR (2000) CONSTRAINT [DF_MI_TescoMIDCheck_Resolution] DEFAULT ('') NOT NULL,
    CONSTRAINT [PK_MI_TescoMIDCheck] PRIMARY KEY CLUSTERED ([ID] ASC),
    CONSTRAINT [UQ_MI_TescoMIDCheck_MID] UNIQUE NONCLUSTERED ([MID] ASC)
);

