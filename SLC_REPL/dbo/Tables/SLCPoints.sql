CREATE TABLE [dbo].[SLCPoints] (
    [ID]          SMALLINT       NOT NULL,
    [CategoryID]  INT            NOT NULL,
    [Description] NVARCHAR (100) NOT NULL,
    [Points]      SMALLINT       NOT NULL,
    [Status]      TINYINT        NOT NULL,
    [ClubAPI]     BIT            NOT NULL,
    CONSTRAINT [PK_SLCPoints] PRIMARY KEY CLUSTERED ([ID] ASC)
);

