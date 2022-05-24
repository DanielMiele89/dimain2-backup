CREATE TABLE [InsightArchive].[Warba_branding_error] (
    [ID]         INT             IDENTITY (1, 1) NOT NULL,
    [Narrative]  NVARCHAR (4000) NULL,
    [MID]        NVARCHAR (4000) NULL,
    [MCC]        NVARCHAR (4000) NULL,
    [MCCDesc]    NVARCHAR (4000) NULL,
    [Brand_Name] NVARCHAR (4000) NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

