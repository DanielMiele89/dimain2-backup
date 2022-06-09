CREATE TABLE [dbo].[OnlineRegistrationSource] (
    [ID]          INT            NOT NULL,
    [Description] NVARCHAR (255) NULL,
    CONSTRAINT [PK_OnlineRegistrationSource] PRIMARY KEY CLUSTERED ([ID] ASC) WITH (FILLFACTOR = 80)
);

