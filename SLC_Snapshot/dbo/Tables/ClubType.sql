CREATE TABLE [dbo].[ClubType] (
    [ID]                    INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Name]                  NVARCHAR (50) NOT NULL,
    [ClubGroupID]           INT           NOT NULL,
    [PDFReportDisplayOrder] NVARCHAR (50) NOT NULL,
    CONSTRAINT [PK_ClubType] PRIMARY KEY CLUSTERED ([ID] ASC)
);

