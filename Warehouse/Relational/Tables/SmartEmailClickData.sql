CREATE TABLE [Relational].[SmartEmailClickData] (
    [ID]             INT            IDENTITY (1, 1) NOT NULL,
    [FANID]          INT            NULL,
    [Campaign_Id]    VARCHAR (38)   NULL,
    [Date_Click_Url] DATETIME       NULL,
    [Url_Name]       VARCHAR (255)  NULL,
    [Url]            VARCHAR (2000) NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);




GO
GRANT SELECT
    ON OBJECT::[Relational].[SmartEmailClickData] TO [crtimport]
    AS [dbo];


GO
GRANT INSERT
    ON OBJECT::[Relational].[SmartEmailClickData] TO [crtimport]
    AS [dbo];

