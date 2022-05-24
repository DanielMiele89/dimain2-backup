CREATE TABLE [MI].[ReportMID_Staging_Part1] (
    [id]             INT           IDENTITY (1, 1) NOT NULL,
    [MID]            VARCHAR (50)  NULL,
    [OutletID]       INT           NULL,
    [Partner]        NVARCHAR (50) NULL,
    [SplitDesc]      NVARCHAR (50) NULL,
    [StatusTypeDesc] NVARCHAR (50) NULL,
    [StatusID]       TINYINT       NULL,
    [PartnerID]      INT           NULL,
    [MIDINT]         INT           NULL
);

