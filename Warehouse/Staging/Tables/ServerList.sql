CREATE TABLE [Staging].[ServerList] (
    [ID]         TINYINT      IDENTITY (1, 1) NOT NULL,
    [ServerID]   VARCHAR (50) NOT NULL,
    [ServerName] VARCHAR (50) NOT NULL,
    CONSTRAINT [PK_Staging_ServerList] PRIMARY KEY CLUSTERED ([ID] ASC)
);

