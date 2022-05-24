CREATE TABLE [MI].[ReportMIDMissMatch] (
    [MID]                    VARCHAR (50)   NULL,
    [Partner]                NVARCHAR (255) NULL,
    [SplitDesc]              NVARCHAR (255) NULL,
    [StatusTypeDesc]         NVARCHAR (255) NULL,
    [NvarMID]                NVARCHAR (50)  NULL,
    [Copy of StatusTypeDesc] VARCHAR (50)   NULL,
    [Copy of Partner]        VARCHAR (50)   NULL,
    [String SplitDesc]       VARCHAR (50)   NULL,
    [PartnerID]              INT            NULL,
    [faildate]               DATETIME       CONSTRAINT [faildate] DEFAULT (getdate()) NULL,
    [Stage]                  VARCHAR (50)   NULL
);

